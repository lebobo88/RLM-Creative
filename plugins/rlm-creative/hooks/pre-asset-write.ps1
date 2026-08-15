# =============================================================================
# pre-asset-write.ps1 - PreToolUse hook for RLM-Creative
#
# CONTRACT
#   Triggered before every Write or Edit tool call. The hook parses the
#   event JSON that Claude Code sends on stdin and guards these assets:
#     *.mp4 | *.mov | *.wav | *.flac | *.png | *.jpg | *.jpeg |
#     *.glb | *.gltf | *.fbx | *.usd | *.blend
#
#   Exit codes:
#     0 - allow the write to proceed
#     2 - block the write (Claude Code hard-refusal; Hydra logs as GATE_BLOCK)
#
#   Stdout  : one audit line per invocation
#             "<ISO-8601-utc> | agent=<slug> | path=<target> | decision=<key>"
#   Stderr  : human-readable refusal reason when blocking (exit 2 only)
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

function Test-HasProperty {
    param($Object, [string]$Name)
    if ($null -eq $Object) { return $false }
    return @($Object.PSObject.Properties | ForEach-Object { $_.Name }) -contains $Name
}

# ---------- derive repo root -------------------------------------------------

$projectRoot = if ($env:HYDRA_RLM_CREATIVE_ROOT) {
    [System.IO.Path]::GetFullPath($env:HYDRA_RLM_CREATIVE_ROOT)
} elseif ($env:CLAUDE_PLUGIN_ROOT) {
    [System.IO.Path]::GetFullPath((Split-Path (Split-Path $env:CLAUDE_PLUGIN_ROOT -Parent) -Parent))
} else {
    [System.IO.Path]::GetFullPath((Get-Item $PSScriptRoot).Parent.Parent.FullName)
}

# Ensure trailing separator on project root for safe prefix comparison
$projectRootWithSep = if ($projectRoot.EndsWith([System.IO.Path]::DirectorySeparatorChar.ToString())) {
    $projectRoot
} else {
    $projectRoot + [System.IO.Path]::DirectorySeparatorChar
}

# ---------- parse hook event -------------------------------------------------

$rawHookInput = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($rawHookInput)) {
    [Console]::Error.WriteLine('BLOCKED: pre-asset-write received no hook event JSON on stdin.')
    Write-AuditLine -Agent 'unknown' -TargetPath '(unknown)' -Decision 'BLOCK_INVALID_HOOK_INPUT'
    exit 2
}

try {
    $hookEvent = $rawHookInput | ConvertFrom-Json -ErrorAction Stop
} catch {
    [Console]::Error.WriteLine("BLOCKED: pre-asset-write could not parse hook event JSON: $_")
    Write-AuditLine -Agent 'unknown' -TargetPath '(unknown)' -Decision 'BLOCK_INVALID_HOOK_INPUT'
    exit 2
}

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

$targetPath = ''
if ((Test-HasProperty -Object $hookEvent -Name 'tool_input') -and $hookEvent.tool_input) {
    foreach ($field in @('file_path', 'path')) {
        if ((Test-HasProperty -Object $hookEvent.tool_input -Name $field) -and $hookEvent.tool_input.$field) {
            $targetPath = [string]$hookEvent.tool_input.$field
            break
        }
    }
}
if (-not $targetPath) {
    foreach ($field in @('file_path', 'path')) {
        if ((Test-HasProperty -Object $hookEvent -Name $field) -and $hookEvent.$field) {
            $targetPath = [string]$hookEvent.$field
            break
        }
    }
}

if (-not $targetPath) {
    [Console]::Error.WriteLine('BLOCKED: pre-asset-write could not resolve file_path or path from the hook event.')
    Write-AuditLine -Agent $agentSlug -TargetPath '(unknown)' -Decision 'BLOCK_MISSING_TARGET_PATH'
    exit 2
}

# Resolve target path relative to project root
$resolvedRaw = if ([System.IO.Path]::IsPathRooted($targetPath)) {
    $targetPath
} else {
    Join-Path $projectRoot $targetPath
}
$canonical = [System.IO.Path]::GetFullPath($resolvedRaw)

# ---------- ancestor reparse point / junction check -------------------------

$curr = if (Test-Path $canonical) {
    (Get-Item $canonical -Force)
} else {
    $parent = Split-Path $canonical -Parent
    if ($parent -and (Test-Path $parent)) { (Get-Item $parent -Force) } else { $null }
}

while ($curr -ne $null -and $curr.FullName.Length -ge $projectRoot.Length) {
    if ($curr.Attributes.HasFlag([System.IO.FileAttributes]::ReparsePoint)) {
        [Console]::Error.WriteLine("BLOCK_REPARSE_POINT: Target or ancestor is a reparse point/junction: $($curr.FullName)")
        Write-AuditLine -Agent $agentSlug -TargetPath $targetPath -Decision 'BLOCK_REPARSE_POINT'
        exit 2
    }
    $curr = $curr.Parent
}

# Directory container check
if ((Test-Path $canonical) -and (Test-Path $canonical -PathType Container)) {
    Write-AuditLine -Agent $agentSlug -TargetPath $targetPath -Decision 'ALLOW_DIRECTORY'
    exit 0
}

# ---------- media extension guard --------------------------------------------

$mediaExts = @('.mp4', '.mov', '.wav', '.flac', '.png', '.jpg', '.jpeg', '.glb', '.gltf', '.fbx', '.usd', '.blend')
$ext = [System.IO.Path]::GetExtension($canonical).ToLower()

if ($ext -notin $mediaExts) {
    Write-AuditLine -Agent $agentSlug -TargetPath $targetPath -Decision 'ALLOW_NOT_MEDIA'
    exit 0
}

# ---------- containment check ------------------------------------------------

if (-not ($canonical.StartsWith($projectRootWithSep, [System.StringComparison]::OrdinalIgnoreCase) -or $canonical.Equals($projectRoot, [System.StringComparison]::OrdinalIgnoreCase))) {
    [Console]::Error.WriteLine("BLOCK_CONTAINMENT_VIOLATION: Path '$canonical' escapes repository root '$projectRoot'")
    Write-AuditLine -Agent $agentSlug -TargetPath $targetPath -Decision 'BLOCK_CONTAINMENT_VIOLATION'
    exit 2
}

# ---------- approved subtree check -------------------------------------------

$relToRoot = $canonical.Substring($projectRootWithSep.Length).Replace('\', '/')
$approvedSubtrees = @('RLM/output/', 'RLM/progress/', 'RLM/assets/')
$inApprovedSubtree = $false
foreach ($sub in $approvedSubtrees) {
    if ($relToRoot.StartsWith($sub, [System.StringComparison]::OrdinalIgnoreCase)) {
        $inApprovedSubtree = $true
        break
    }
}

if (-not $inApprovedSubtree) {
    [Console]::Error.WriteLine("BLOCK_UNAPPROVED_SUBTREE: Media assets must reside in approved subtrees (RLM/output/, RLM/progress/, RLM/assets/); attempted: '$relToRoot'")
    Write-AuditLine -Agent $agentSlug -TargetPath $targetPath -Decision 'BLOCK_UNAPPROVED_SUBTREE'
    exit 2
}

# ---------- agent allow-list ------------------------------------------------

$allowedAgents = @(
    'helios',
    'photo-cinema',
    'video-synth',
    'audio-foley',
    'music-score',
    'dialogue-mix',
    'blender-model',
    'blender-rig',
    'governance-c2pa'
)

if ($agentSlug -notin $allowedAgents) {
    $refusal = "BLOCKED: agent '$agentSlug' is not authorised to write media/3D files. Route through Helios sub-crew."
    [Console]::Error.WriteLine($refusal)
    Write-AuditLine -Agent $agentSlug -TargetPath $targetPath -Decision 'BLOCK_AGENT_NOT_ALLOWED'
    exit 2
}

# ---------- approved-assets C2PA sidecar guard --------------------------------

if ($relToRoot -match '(?i)^RLM/assets/approved/') {
    if ($agentSlug -ne 'governance-c2pa') {
        $sidecarPath = $canonical + '.c2pa.json'
        if (-not (Test-Path -LiteralPath $sidecarPath)) {
            [Console]::Error.WriteLine("BLOCKED: Asset in RLM/assets/approved/ requires .c2pa.json sidecar signed by governance-c2pa.")
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
