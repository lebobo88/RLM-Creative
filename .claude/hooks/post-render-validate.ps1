# =============================================================================
# post-render-validate.ps1 - PostToolUse hook for RLM-Creative
#
# CONTRACT
#   Triggered after any Bash tool invocation that calls ffmpeg or ffprobe.
#
#   Environment variables consumed:
#     CLAUDE_HOOK_AGENT_NAME    - slug of the calling agent
#     CLAUDE_AGENT_NAME         - fallback
#     CLAUDE_HOOK_TOOL_NAME     - name of the tool that was called
#     CLAUDE_HOOK_TOOL_OUTPUT   - stdout+stderr captured from the Bash call
#     CLAUDE_HOOK_TOOL_EXIT_CODE - integer exit code from the Bash call
#
#   Behavior:
#     1. Inspects CLAUDE_HOOK_TOOL_OUTPUT for a media output path.
#     2. Attempts to parse ffmpeg/ffprobe timing for duration_ms.
#     3. Appends one JSON-lines event to RLM/progress/events.jsonl.
#        The rlm-bridge TheEights adapter tails this file for episodic memory.
#     4. Prints one-line summary to stdout.
#     5. ALWAYS exits 0 - this hook never blocks.
#
#   events.jsonl schema:
#     {"ts":"<iso>","agent":"<slug>","tool":"<name>","output_path":"<path>",
#      "duration_ms":<int|null>,"exit_code":<int>}
#
#   Idempotent: yes (append-only).  No third-party modules.
# =============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ISOTimestamp {
    [datetime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
}

# ---------- resolve caller context -------------------------------------------

$agentName = $env:CLAUDE_HOOK_AGENT_NAME
if (-not $agentName) { $agentName = $env:CLAUDE_AGENT_NAME }
if (-not $agentName) { $agentName = 'unknown' }
$agentSlug = $agentName.ToLower().Trim()

$toolName = if ($env:CLAUDE_HOOK_TOOL_NAME) { $env:CLAUDE_HOOK_TOOL_NAME } else { 'Bash' }

$rawExitCode = $env:CLAUDE_HOOK_TOOL_EXIT_CODE
$exitCodeInt = 0
if ($rawExitCode -match '^\-?\d+$') { $exitCodeInt = [int]$rawExitCode }

$toolOutput = if ($env:CLAUDE_HOOK_TOOL_OUTPUT) { $env:CLAUDE_HOOK_TOOL_OUTPUT } else { '' }

# ---------- extract output path ----------------------------------------------

$outputPath = ''
$mediaExtPattern = '\.(mp4|mov|wav|flac|png|jpg|jpeg|mkv|webm|aac|mp3)(?=[''"\s]|$)'

if ($toolOutput -match "(?im)\bto\s+['""]([^'""]+\.(mp4|mov|wav|flac|png|jpg|jpeg|mkv|webm|aac|mp3))['""]") {
    $outputPath = $Matches[1]
} elseif ($toolOutput -match "(?im)\[out\]\s+([^\r\n]+$mediaExtPattern)") {
    $outputPath = $Matches[1].Trim()
} elseif ($toolOutput -match "(?im)((?:[A-Za-z]:\\|/)[^\r\n]*$mediaExtPattern)") {
    $outputPath = $Matches[1].Trim()
}

# ---------- extract duration -------------------------------------------------

$durationMs = $null
$timeMatches = [regex]::Matches($toolOutput, 'time=(\d{2}):(\d{2}):(\d{2})\.(\d{2})')
if ($timeMatches.Count -gt 0) {
    $last = $timeMatches[$timeMatches.Count - 1]
    $h  = [int]$last.Groups[1].Value
    $m  = [int]$last.Groups[2].Value
    $s  = [int]$last.Groups[3].Value
    $cs = [int]$last.Groups[4].Value
    $durationMs = ($h * 3600 + $m * 60 + $s) * 1000 + $cs * 10
}

# ---------- build event JSON -------------------------------------------------

$ts = Get-ISOTimestamp
$durationJson = if ($null -ne $durationMs) { $durationMs.ToString() } else { 'null' }
$safeOutputPath = $outputPath.Replace('\', '\\').Replace('"', '\"')
$safeAgent      = $agentSlug.Replace('"', '\"')
$safeTool       = $toolName.Replace('"', '\"')

$eventLine = '{"ts":"' + $ts + '","agent":"' + $safeAgent + '","tool":"' + $safeTool +
             '","output_path":"' + $safeOutputPath + '","duration_ms":' + $durationJson +
             ',"exit_code":' + $exitCodeInt + '}'

# ---------- append to events.jsonl -------------------------------------------

$projectRoot = $env:HYDRA_RLM_CREATIVE_ROOT
if (-not $projectRoot) { $projectRoot = $PSScriptRoot | Split-Path | Split-Path }

$eventsDir  = Join-Path $projectRoot 'RLM\progress'
$eventsFile = Join-Path $eventsDir   'events.jsonl'

if (-not (Test-Path $eventsDir)) {
    New-Item -ItemType Directory -Path $eventsDir -Force | Out-Null
}

$sw = $null
try {
    $sw = [System.IO.StreamWriter]::new($eventsFile, $true, [System.Text.Encoding]::UTF8)
    $sw.WriteLine($eventLine)
} finally {
    if ($sw) { $sw.Close() }
}

# ---------- stdout summary ---------------------------------------------------

$summary = "$(Get-ISOTimestamp) | post-render | agent=$agentSlug | exit=$exitCodeInt"
if ($outputPath) { $summary += " | out=$outputPath" }
if ($null -ne $durationMs) { $summary += " | duration_ms=$durationMs" }
Write-Output $summary

exit 0
