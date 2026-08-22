#requires -Version 7
<#
.SYNOPSIS
  Install RLM-Creative at Claude Code user scope (~/.claude/).

.DESCRIPTION
  Idempotent. Symlinks/copies .claude/{agents,skills,commands} from RLM-Creative
  into ~/.claude/. Merges hooks into ~/.claude/settings.json with an
  $installed_by sentinel so uninstall can revert cleanly.
  Writes a manifest at ~/.claude/.rlm-creative-installed.json.
#>
[CmdletBinding()]
param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
  [string]$UserClaude = (Join-Path $env:USERPROFILE ".claude"),
  [switch]$Force
)

$ErrorActionPreference = "Stop"
$RepoRoot = ($RepoRoot -replace '\\','/').TrimEnd('/')
$ManifestPath = Join-Path $UserClaude ".rlm-creative-installed.json"
$SettingsPath = Join-Path $UserClaude "settings.json"
$HooksJsonPath = Join-Path $RepoRoot "hooks.json"
$Sentinel = "rlm-creative"

function Write-RC($msg, $level = "info") {
  $prefix = "[rlm-creative.install]"
  switch ($level) {
    "warn"  { Write-Host "$prefix $msg" -ForegroundColor Yellow }
    "error" { Write-Host "$prefix $msg" -ForegroundColor Red }
    "ok"    { Write-Host "$prefix $msg" -ForegroundColor Green }
    default { Write-Host "$prefix $msg" }
  }
}

function Test-SymlinkCapability {
  $probeDir = Join-Path $env:TEMP "rlm-creative-symlink-probe"
  $probeTarget = Join-Path $probeDir "target.txt"
  $probeLink = Join-Path $probeDir "link.txt"
  try {
    New-Item -ItemType Directory -Path $probeDir -Force | Out-Null
    "ok" | Out-File -FilePath $probeTarget -Encoding utf8
    if (Test-Path $probeLink) { Remove-Item $probeLink -Force }
    New-Item -ItemType SymbolicLink -Path $probeLink -Target $probeTarget -ErrorAction Stop | Out-Null
    return $true
  } catch {
    return $false
  } finally {
    if (Test-Path $probeDir) { Remove-Item $probeDir -Recurse -Force -ErrorAction SilentlyContinue }
  }
}

function Install-Item([string]$Source, [string]$Target, [bool]$PreferSymlink) {
  if (Test-Path $Target) {
    if (-not $Force) {
      $existing = Get-Item $Target -Force
      if ($existing.Target -and ($existing.Target -replace '\\','/') -eq ($Source -replace '\\','/')) {
        return "already-linked"
      }
      throw "refusing to overwrite existing path: $Target (re-run with -Force to clobber)"
    }
    Remove-Item $Target -Recurse -Force
  }
  $parent = Split-Path -Parent $Target
  if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
  if ($PreferSymlink) {
    try {
      New-Item -ItemType SymbolicLink -Path $Target -Target $Source -ErrorAction Stop | Out-Null
      return "symlink"
    } catch {
      Write-RC "symlink failed for $Target — falling back to copy: $_" "warn"
    }
  }
  if ((Get-Item $Source).PSIsContainer) {
    Copy-Item -Path $Source -Destination $Target -Recurse -Force
  } else {
    Copy-Item -Path $Source -Destination $Target -Force
  }
  return "copy"
}

function Merge-Hooks {
  if (-not (Test-Path $HooksJsonPath)) {
    Write-RC "no hooks.json at $HooksJsonPath — skipping hook merge" "warn"
    return @()
  }
  $repoHooks = (Get-Content $HooksJsonPath -Raw | ConvertFrom-Json -AsHashtable).hooks

  # Backup settings
  if (Test-Path $SettingsPath) {
    $stamp = (Get-Date -Format "yyyyMMdd-HHmmss")
    $backup = "$SettingsPath.rlm-creative.bak.$stamp"
    Copy-Item $SettingsPath $backup -Force
    Write-RC "backed up settings.json -> $backup"
    $settings = Get-Content $SettingsPath -Raw | ConvertFrom-Json -AsHashtable
  } else {
    $settings = @{}
  }
  if (-not $settings.ContainsKey("hooks")) { $settings["hooks"] = @{} }

  $added = @()
  foreach ($eventName in $repoHooks.Keys) {
    if (-not $settings["hooks"].ContainsKey($eventName)) {
      $settings["hooks"][$eventName] = @()
    }
    foreach ($matcherBlock in $repoHooks[$eventName]) {
      $tagged = $matcherBlock.Clone()
      $tagged['$installed_by'] = $Sentinel
      
      # Expand relative script paths in commands to absolute RepoRoot paths
      if ($tagged.ContainsKey('hooks')) {
        $updatedHooks = @()
        foreach ($h in $tagged['hooks']) {
          $hClone = $h.Clone()
          if ($hClone.ContainsKey('command')) {
            $cmd = [string]$hClone['command']
            if ($cmd -match '\.claude[\\/]hooks') {
              $hClone['command'] = $cmd -replace '\.claude[\\/]hooks', "$RepoRoot/.claude/hooks"
            }
          }
          $updatedHooks += $hClone
        }
        $tagged['hooks'] = $updatedHooks
      }

      # Skip if an entry with this sentinel + matcher already present
      $exists = $false
      foreach ($existing in $settings["hooks"][$eventName]) {
        if ($existing -is [hashtable] -and $existing['$installed_by'] -eq $Sentinel) {
          $matchA = if ($existing.ContainsKey('matcher')) { $existing['matcher'] } else { '*' }
          $matchB = if ($tagged.ContainsKey('matcher')) { $tagged['matcher'] } else { '*' }
          if ($matchA -eq $matchB) {
            $exists = $true; break
          }
        }
      }
      if (-not $exists) {
        $settings["hooks"][$eventName] += $tagged
        $m = if ($tagged.ContainsKey('matcher')) { $tagged['matcher'] } else { '*' }
        $added += "${eventName}:${m}"
      }
    }
  }

  $json = $settings | ConvertTo-Json -Depth 12
  Set-Content -Path $SettingsPath -Value $json -Encoding utf8 -NoNewline:$false
  Write-RC "merged hooks: $($added.Count)" "ok"
  return $added
}

# ---- main ----

Write-RC "repo_root = $RepoRoot"
Write-RC "user .claude = $UserClaude"

if (-not (Test-Path $UserClaude)) {
  New-Item -ItemType Directory -Path $UserClaude -Force | Out-Null
}

$symlinkOk = Test-SymlinkCapability
if ($symlinkOk) {
  Write-RC "symlinks: enabled" "ok"
} else {
  Write-RC "symlinks: NOT permitted on this machine — using copy fallback" "warn"
}

$items = @()

# 1. Agents (Heads + Sub-Crew)
$agentsSrc = "$RepoRoot/.claude/agents"
$agentsDst = "$UserClaude/agents"
if (Test-Path $agentsSrc) {
  # Root crew heads
  foreach ($f in Get-ChildItem -Path $agentsSrc -File -Filter *.md -ErrorAction SilentlyContinue) {
    $target = Join-Path $agentsDst $f.Name
    $strategy = Install-Item -Source $f.FullName -Target $target -PreferSymlink:$symlinkOk
    Write-RC "$strategy agent: $($f.Name)"
    $items += @{ kind = "agent"; name = $f.BaseName; source = $f.FullName; target = $target; strategy = $strategy }
  }

  # Helios sub-crew directory and sub-agents
  $heliosCrewSrc = Join-Path $agentsSrc "helios-crew"
  if (Test-Path $heliosCrewSrc) {
    $heliosCrewDst = Join-Path $agentsDst "helios-crew"
    if (-not (Test-Path $heliosCrewDst)) { New-Item -ItemType Directory -Path $heliosCrewDst -Force | Out-Null }

    foreach ($f in Get-ChildItem -Path $heliosCrewSrc -File -Filter *.md -ErrorAction SilentlyContinue) {
      # Link inside helios-crew/
      $targetSub = Join-Path $heliosCrewDst $f.Name
      $strategySub = Install-Item -Source $f.FullName -Target $targetSub -PreferSymlink:$symlinkOk
      Write-RC "$strategySub helios-crew agent: $($f.Name)"
      $items += @{ kind = "agent-subcrew"; name = "helios-crew/$($f.BaseName)"; source = $f.FullName; target = $targetSub; strategy = $strategySub }

      # Also link flat in agents/ for direct slug lookup
      $targetFlat = Join-Path $agentsDst $f.Name
      $strategyFlat = Install-Item -Source $f.FullName -Target $targetFlat -PreferSymlink:$symlinkOk
      Write-RC "$strategyFlat flat agent alias: $($f.Name)"
      $items += @{ kind = "agent"; name = $f.BaseName; source = $f.FullName; target = $targetFlat; strategy = $strategyFlat }
    }
  }
}

# 2. Skills
$skillsSrc = "$RepoRoot/.claude/skills"
$skillsDst = "$UserClaude/skills"
if (Test-Path $skillsSrc) {
  foreach ($d in Get-ChildItem -Path $skillsSrc -Directory -ErrorAction SilentlyContinue) {
    $target = Join-Path $skillsDst $d.Name
    $strategy = Install-Item -Source $d.FullName -Target $target -PreferSymlink:$symlinkOk
    Write-RC "$strategy skill: $($d.Name)"
    $items += @{ kind = "skill"; name = $d.Name; source = $d.FullName; target = $target; strategy = $strategy }
  }
}

# 3. Commands
$commandsSrc = "$RepoRoot/.claude/commands"
$commandsDst = "$UserClaude/commands"
if (Test-Path $commandsSrc) {
  foreach ($f in Get-ChildItem -Path $commandsSrc -File -Filter *.md -ErrorAction SilentlyContinue) {
    $target = Join-Path $commandsDst $f.Name
    $strategy = Install-Item -Source $f.FullName -Target $target -PreferSymlink:$symlinkOk
    Write-RC "$strategy command: $($f.Name)"
    $items += @{ kind = "command"; name = $f.BaseName; source = $f.FullName; target = $target; strategy = $strategy }
  }
}

# 4. Merge Hooks
$hooksAdded = Merge-Hooks

# 5. Write manifest
$manifest = [pscustomobject]@{
  version          = "1.0.0"
  installed_at     = (Get-Date).ToString("o")
  repo_root        = $RepoRoot
  user_claude      = $UserClaude
  sentinel         = $Sentinel
  symlink_capable  = $symlinkOk
  items            = $items
  hooks_added      = $hooksAdded
}
$manifestJson = $manifest | ConvertTo-Json -Depth 8
Set-Content -Path $ManifestPath -Value $manifestJson -Encoding utf8
Write-RC "wrote manifest: $ManifestPath" "ok"

Write-RC "installation complete: $($items.Count) components installed at user scope." "ok"
