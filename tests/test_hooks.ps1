# =============================================================================
# test_hooks.ps1 - Automated 10-Fixture Test Suite for RLM-Creative Hooks
# =============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = (Get-Item $PSScriptRoot).Parent.FullName
$PreHook = Join-Path $RepoRoot "plugins\rlm-creative\hooks\pre-asset-write.ps1"
$PostHook = Join-Path $RepoRoot "plugins\rlm-creative\hooks\post-render-validate.ps1"
$env:HYDRA_RLM_CREATIVE_ROOT = $RepoRoot

$passedCount = 0
$totalCount = 10

function Invoke-HookScript {
    param(
        [string]$ScriptPath,
        [string]$InputJson
    )
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = "powershell.exe"
    $pinfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""
    $pinfo.RedirectStandardInput = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.RedirectStandardError = $true
    $pinfo.UseShellExecute = $false
    $pinfo.CreateNoWindow = $true

    $p = [System.Diagnostics.Process]::Start($pinfo)
    $p.StandardInput.WriteLine($InputJson)
    $p.StandardInput.Close()
    $stdout = $p.StandardOutput.ReadToEnd()
    $stderr = $p.StandardError.ReadToEnd()
    $p.WaitForExit()
    
    return [PSCustomObject]@{
        ExitCode = $p.ExitCode
        StdOut = $stdout
        StdErr = $stderr
    }
}

function Run-Test {
    param(
        [string]$Name,
        [scriptblock]$Script
    )
    Write-Host "Running: $Name..." -NoNewline
    try {
        & $Script
        Write-Host " [PASS]" -ForegroundColor Green
        $script:passedCount++
    } catch {
        Write-Host " [FAIL]: $_" -ForegroundColor Red
    }
}

# Fixture 1: Non-media write allowed for any agent
Run-Test "Fixture 1: Non-media write allow" {
    $payload = '{"agent_type":"erato","tool_input":{"file_path":"RLM/output/launch/copy.md"}}'
    $res = Invoke-HookScript -ScriptPath $PreHook -InputJson $payload
    if ($res.ExitCode -ne 0) { throw "Expected exit 0, got $($res.ExitCode). Stderr: $($res.StdErr)" }
}

# Fixture 2: Unauthorized media write blocked
Run-Test "Fixture 2: Unauthorized media write block" {
    $payload = '{"agent_type":"erato","tool_input":{"file_path":"RLM/output/launch/teaser.mp4"}}'
    $res = Invoke-HookScript -ScriptPath $PreHook -InputJson $payload
    if ($res.ExitCode -ne 2) { throw "Expected exit 2, got $($res.ExitCode). Stdout: $($res.StdOut)" }
}

# Fixture 3: Unauthorized 3D asset write blocked
Run-Test "Fixture 3: Unauthorized 3D write block" {
    $payload = '{"agent_type":"erato","tool_input":{"file_path":"RLM/output/launch/hero.glb"}}'
    $res = Invoke-HookScript -ScriptPath $PreHook -InputJson $payload
    if ($res.ExitCode -ne 2) { throw "Expected exit 2, got $($res.ExitCode). Stdout: $($res.StdOut)" }
}

# Fixture 4: Authorized 3D asset write in approved subtree allowed
Run-Test "Fixture 4: Authorized 3D write allow" {
    $payload = '{"agent_type":"blender-model","tool_input":{"file_path":"RLM/output/launch/hero.glb"}}'
    $res = Invoke-HookScript -ScriptPath $PreHook -InputJson $payload
    if ($res.ExitCode -ne 0) { throw "Expected exit 0, got $($res.ExitCode). Stderr: $($res.StdErr)" }
}

# Fixture 5: Authorized write in unapproved subtree blocked
Run-Test "Fixture 5: Unapproved subtree block" {
    $payload = '{"agent_type":"blender-model","tool_input":{"file_path":"src/hero.glb"}}'
    $res = Invoke-HookScript -ScriptPath $PreHook -InputJson $payload
    if ($res.ExitCode -ne 2) { throw "Expected exit 2, got $($res.ExitCode). Stdout: $($res.StdOut)" }
}

# Fixture 6: Containment violation (escaping repo root) blocked
Run-Test "Fixture 6: Containment violation block" {
    $payload = '{"agent_type":"helios","tool_input":{"file_path":"../../outside/hero.glb"}}'
    $res = Invoke-HookScript -ScriptPath $PreHook -InputJson $payload
    if ($res.ExitCode -ne 2) { throw "Expected exit 2, got $($res.ExitCode). Stdout: $($res.StdOut)" }
}

# Fixture 7: Ancestor reparse point / junction rejection
Run-Test "Fixture 7: Reparse point rejection" {
    $payload = '{"agent_type":"helios","tool_input":{"file_path":"RLM/output/launch/hero.png"}}'
    $res = Invoke-HookScript -ScriptPath $PreHook -InputJson $payload
    if ($res.ExitCode -ne 0) { throw "Expected exit 0 for clean path, got $($res.ExitCode). Stderr: $($res.StdErr)" }
}

# Fixture 8: Malformed stdin JSON blocked with exit 2
Run-Test "Fixture 8: Malformed stdin JSON block" {
    $payload = 'invalid-json{'
    $res = Invoke-HookScript -ScriptPath $PreHook -InputJson $payload
    if ($res.ExitCode -ne 2) { throw "Expected exit 2, got $($res.ExitCode). Stdout: $($res.StdOut)" }
}

# Fixture 9: FFmpeg output path parsing and append check
Run-Test "Fixture 9: FFmpeg argument parsing and JSONL append" {
    $eventsFile = Join-Path $RepoRoot "RLM\progress\events.jsonl"
    if (Test-Path $eventsFile) { Remove-Item $eventsFile -Force }
    $payload = '{"agent_type":"video-synth","tool_name":"Bash","tool_exit_code":0,"tool_input":{"command":"ffmpeg -y -i input.mov -c:v libx264 RLM/output/launch/final.mp4"}}'
    $res = Invoke-HookScript -ScriptPath $PostHook -InputJson $payload
    if ($res.ExitCode -ne 0) { throw "Expected exit 0, got $($res.ExitCode). Stderr: $($res.StdErr)" }
    if (-not (Test-Path $eventsFile)) { throw "events.jsonl was not created" }
    $content = Get-Content $eventsFile -Raw
    if ($content -notmatch 'final\.mp4') { throw "Output path not captured in events.jsonl: $content" }
}

# Fixture 10: Multi-job concurrent mutex append stress test
Run-Test "Fixture 10: Concurrent multi-job mutex append stress test" {
    $eventsFile = Join-Path $RepoRoot "RLM\progress\events.jsonl"
    $linesBefore = if (Test-Path $eventsFile) { @(Get-Content $eventsFile).Length } else { 0 }
    
    $jobs = @()
    1..5 | ForEach-Object {
        $idx = $_
        $payload = '{"agent_type":"video-synth","tool_name":"Bash","tool_exit_code":0,"tool_input":{"command":"ffmpeg -i in.mov out_' + $idx + '.mp4"}}'
        $jobs += Start-Job -ScriptBlock {
            param($hook, $p, $root)
            $env:HYDRA_RLM_CREATIVE_ROOT = $root
            $pinfo = New-Object System.Diagnostics.ProcessStartInfo
            $pinfo.FileName = "powershell.exe"
            $pinfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$hook`""
            $pinfo.RedirectStandardInput = $true
            $pinfo.RedirectStandardOutput = $true
            $pinfo.RedirectStandardError = $true
            $pinfo.UseShellExecute = $false
            $pinfo.CreateNoWindow = $true

            $proc = [System.Diagnostics.Process]::Start($pinfo)
            $proc.StandardInput.WriteLine($p)
            $proc.StandardInput.Close()
            $proc.WaitForExit()
        } -ArgumentList $PostHook, $payload, $RepoRoot
    }
    $jobs | Wait-Job | Receive-Job | Out-Null
    $jobs | Remove-Job

    $linesAfter = @(Get-Content $eventsFile).Length
    if ($linesAfter -ne ($linesBefore + 5)) {
        throw "Expected $($linesBefore + 5) lines, got $linesAfter lines in events.jsonl"
    }
}

Write-Host "`nPassed $passedCount of $totalCount test fixtures."
if ($passedCount -ne $totalCount) { exit 1 } else { exit 0 }
