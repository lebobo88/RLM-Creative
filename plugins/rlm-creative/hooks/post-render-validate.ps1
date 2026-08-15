# =============================================================================
# post-render-validate.ps1 - PostToolUse hook for RLM-Creative
# =============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ISOTimestamp {
    [datetime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
}

function Test-HasProperty {
    param($Object, [string]$Name)
    if ($null -eq $Object) { return $false }
    return @($Object.PSObject.Properties | ForEach-Object { $_.Name }) -contains $Name
}

# ---------- parse hook event -------------------------------------------------

$rawHookInput = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($rawHookInput)) { exit 0 }

try {
    $hookEvent = $rawHookInput | ConvertFrom-Json -ErrorAction Stop
} catch {
    exit 0
}

$command = ''
if ((Test-HasProperty -Object $hookEvent -Name 'tool_input') -and $hookEvent.tool_input -and
    (Test-HasProperty -Object $hookEvent.tool_input -Name 'command')) {
    $command = [string]$hookEvent.tool_input.command
} elseif ((Test-HasProperty -Object $hookEvent -Name 'command') -and $hookEvent.command) {
    $command = [string]$hookEvent.command
}

if ($command -notmatch '(?i)\b(ffmpeg|ffprobe)(?:\.exe)?\b') { exit 0 }

$agentName = ''
foreach ($field in @('agent_type', 'agent_name')) {
    if ((Test-HasProperty -Object $hookEvent -Name $field) -and $hookEvent.$field) {
        $agentName = [string]$hookEvent.$field
        break
    }
}
if (-not $agentName) { $agentName = $env:CLAUDE_HOOK_AGENT_NAME }
if (-not $agentName) { $agentName = $env:CLAUDE_AGENT_NAME }
$agentSlug = if ($agentName) { ($agentName -split ':')[-1].ToLower().Trim() } else { 'unknown' }

$toolName = if ((Test-HasProperty -Object $hookEvent -Name 'tool_name') -and $hookEvent.tool_name) { [string]$hookEvent.tool_name } else { 'Bash' }

$exitCodeInt = 0
foreach ($field in @('tool_exit_code', 'exit_code')) {
    if ((Test-HasProperty -Object $hookEvent -Name $field) -and [string]$hookEvent.$field -match '^-?\d+$') {
        $exitCodeInt = [int]$hookEvent.$field
        break
    }
}

# ---------- ffmpeg argument state-machine tokenizer --------------------------

$tokens = @()
$pattern = '(?:"([^"]*)"|\x27([^\x27]*)\x27|(\S+))'
$tokenMatches = [regex]::Matches($command, $pattern)
foreach ($m in $tokenMatches) {
    if ($m.Groups[1].Success) { $tokens += $m.Groups[1].Value }
    elseif ($m.Groups[2].Success) { $tokens += $m.Groups[2].Value }
    else { $tokens += $m.Groups[3].Value }
}

$outputPath = 'unknown'
$paramFlags = @('-i', '-c', '-codec', '-c:v', '-c:a', '-b:v', '-b:a', '-vf', '-af',
                '-filter_complex', '-preset', '-crf', '-pix_fmt', '-r', '-s', '-t',
                '-ss', '-map', '-threads', '-y', '-n', '-f', '-v', '-loglevel')

$i = 0
$nonFlagArgs = @()
while ($i -lt $tokens.Count) {
    $tok = $tokens[$i]
    if ($tok.StartsWith('-')) {
        if ($paramFlags -contains $tok.ToLower()) {
            $i += 2  # skip flag and parameter
            continue
        }
        $i++
        continue
    }
    # ignore executable token
    if ($tok -notmatch '(?i)\b(ffmpeg|ffprobe)(?:\.exe)?$') {
        $nonFlagArgs += $tok
    }
    $i++
}

if ($nonFlagArgs.Count -gt 0) {
    $cand = $nonFlagArgs[-1]
    if ($cand -in @('-', 'NUL', '/dev/null')) {
        $outputPath = 'stream/null'
    } else {
        $outputPath = $cand
    }
}

# ---------- mutex-synchronized JSONL append ----------------------------------

$projectRoot = if ($env:HYDRA_RLM_CREATIVE_ROOT) {
    $env:HYDRA_RLM_CREATIVE_ROOT
} elseif ($env:CLAUDE_PLUGIN_ROOT) {
    Split-Path (Split-Path $env:CLAUDE_PLUGIN_ROOT -Parent) -Parent
} else {
    (Get-Item $PSScriptRoot).Parent.Parent.FullName
}

$eventsDir  = Join-Path $projectRoot 'RLM\progress'
$eventsFile = Join-Path $eventsDir   'events.jsonl'

if (-not (Test-Path $eventsDir)) {
    New-Item -ItemType Directory -Path $eventsDir -Force | Out-Null
}

$ts = Get-ISOTimestamp
$eventObj = @{
    ts = $ts
    agent = $agentSlug
    tool = $toolName
    exit_code = $exitCodeInt
    output_path = $outputPath.Replace('\', '/')
}
$eventJson = $eventObj | ConvertTo-Json -Compress

$mutexName = "Global\RLM_Creative_Events_Jsonl_Lock"
$mutex = New-Object System.Threading.Mutex($false, $mutexName)
$acquired = $false
try {
    $acquired = $mutex.WaitOne(5000)
    if ($acquired) {
        [System.IO.File]::AppendAllText($eventsFile, $eventJson + [Environment]::NewLine, [System.Text.Encoding]::UTF8)
    } else {
        [Console]::Error.WriteLine("WARN_MUTEX_TIMEOUT: Could not acquire lock for events.jsonl within 5s")
    }
} finally {
    if ($acquired) { $mutex.ReleaseMutex() }
    $mutex.Dispose()
}

Write-Output "$(Get-ISOTimestamp) | post-render | agent=$agentSlug | out=$outputPath | exit=$exitCodeInt"
exit 0
