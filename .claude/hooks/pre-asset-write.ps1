# =============================================================================
# pre-asset-write.ps1 - PreToolUse hook for RLM-Creative
#
# CONTRACT
#   Triggered before any Write tool call whose target path matches:
#     *.mp4 | *.mov | *.wav | *.flac | *.png | *.jpg | *.jpeg
#
#   Environment variables consumed (injected by Claude Code / Hydra):
#     CLAUDE_HOOK_AGENT_NAME   - slug of the calling agent (preferred)
#     CLAUDE_AGENT_NAME        - fallback when the preferred var is absent
#     CLAUDE_HOOK_TOOL_INPUT   - JSON object containing "file_path" or "path"
#
#   Exit codes:
#     0 - allow the write to proceed
#     2 - block the write (Claude Code hard-refusal; Hydra logs as GATE_BLOCK)
#
#   Stdout  : one audit line per invocation
#             "<ISO-8601-utc> | agent=<slug> | path=<target> | decision=<key>"
#   Stderr  : human-readable refusal reason when blocking (exit 2 only)
#   Modules : none (no third-party dependencies)
#   Idempotent: yes - re-running for the same inputs produces the same result
# =============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ISOTimestamp {
    [datetime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
}

function Write-AuditLine {
    param(
        [string]$Agent,
        [string]$TargetPath,
        [string]$Decision
    )
    Write-Output "$(Get-ISOTimestamp) | agent=$Agent | path=$TargetPath | decision=$Decision"
}

# ---------- resolve calling agent --------------------------------------------

$agentName = $env:CLAUDE_HOOK_AGENT_NAME
if (-not $agentName) { $agentName = $env:CLAUDE_AGENT_NAME }
if (-not $agentName) { $agentName = 'unknown' }
$agentSlug = $agentName.ToLower().Trim()

# ---------- resolve target path from tool input JSON -------------------------

$targetPath = ''
if ($env:CLAUDE_HOOK_TOOL_INPUT) {
    try {
        $inp = $env:CLAUDE_HOOK_TOOL_INPUT | ConvertFrom-Json -ErrorAction Stop
        if ($inp.PSObject.Properties.Name -contains 'file_path') {
            $targetPath = [string]$inp.file_path
        } elseif ($inp.PSObject.Properties.Name -contains 'path') {
            $targetPath = [string]$inp.path
        }
    } catch {
        [Console]::Error.WriteLine("pre-asset-write WARNING: could not parse CLAUDE_HOOK_TOOL_INPUT - $_")
    }
}

if (-not $targetPath) {
    Write-AuditLine -Agent $agentSlug -TargetPath '(unknown)' -Decision 'ALLOW_NO_PATH'
    exit 0
}

$normPath = $targetPath.Replace('\', '/')

# ---------- media extension guard --------------------------------------------

$mediaExts = @('.mp4', '.mov', '.wav', '.flac', '.png', '.jpg', '.jpeg', '.glb', '.gltf', '.fbx', '.usd', '.blend')
$ext = [System.IO.Path]::GetExtension($normPath).ToLower()

if ($ext -notin $mediaExts) {
    Write-AuditLine -Agent $agentSlug -TargetPath $targetPath -Decision 'ALLOW_NOT_MEDIA'
    exit 0
}

# ---------- agent allow-list ------------------------------------------------

$allowedAgents = @(
    'helios',
    'video-synth',
    'audio-foley',
    'music-score',
    'dialogue-mix',
    'governance-c2pa',
    'blender-model',
    'blender-rig'
)

if ($agentSlug -notin $allowedAgents) {
    $refusal = @(
        "BLOCKED: agent '$agentSlug' is not authorised to write media/3D asset files.",
        "Only Helios and its sub-crew (video-synth, audio-foley, music-score,",
        "dialogue-mix, governance-c2pa, blender-model, blender-rig) may produce media & 3D assets.",
        "Route your request through Helios. See AGENTS.md for asset-write rules."
    ) -join ' '
    [Console]::Error.WriteLine($refusal)
    Write-AuditLine -Agent $agentSlug -TargetPath $targetPath -Decision 'BLOCK_AGENT_NOT_ALLOWED'
    exit 2
}

# ---------- approved-assets C2PA sidecar guard --------------------------------

$isApprovedAssets = $normPath -match '(?i)/RLM/approved-assets/'

if ($isApprovedAssets) {
    if ($agentSlug -ne 'governance-c2pa') {
        $sidecarPath = $targetPath + '.c2pa.json'
        $sidecarExists = Test-Path -LiteralPath $sidecarPath -ErrorAction SilentlyContinue

        if (-not $sidecarExists) {
            $refusal = @(
                "BLOCKED: '$targetPath' is under RLM/approved-assets/ but no",
                "'.c2pa.json' sidecar exists at '$sidecarPath'.",
                "Assets must be signed by governance-c2pa before promotion.",
                "Only governance-c2pa may write directly into approved-assets/."
            ) -join ' '
            [Console]::Error.WriteLine($refusal)
            Write-AuditLine -Agent $agentSlug -TargetPath $targetPath -Decision 'BLOCK_NO_C2PA_SIDECAR'
            exit 2
        }

        Write-AuditLine -Agent $agentSlug -TargetPath $targetPath -Decision 'ALLOW_PRESIGNED'
        exit 0
    }

    Write-AuditLine -Agent $agentSlug -TargetPath $targetPath -Decision 'ALLOW_GOVERNANCE_APPROVED'
    exit 0
}

Write-AuditLine -Agent $agentSlug -TargetPath $targetPath -Decision 'ALLOW'
exit 0
