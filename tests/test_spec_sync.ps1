# =============================================================================
# test_spec_sync.ps1 - Cross-Repo Heading-Scoped Spec Consistency Test Suite
# =============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = (Get-Item $PSScriptRoot).Parent.FullName
$passedCount = 0
$totalCount = 4

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

# Test 1: 04-VISUAL-DIRECTION.md heading assertions
Run-Test "Test 1: 04-VISUAL-DIRECTION.md 3D contract under ## Visual Directives" {
    $file = Join-Path $RepoRoot "RLM\prompts\04-VISUAL-DIRECTION.md"
    $content = Get-Content $file -Raw
    if ($content -notmatch '(?m)^## Visual Directives[\s\S]*?### 3D Asset Creation Contract') {
        throw "Missing '### 3D Asset Creation Contract' under '## Visual Directives'"
    }
}

# Test 2: 06-PRODUCTION.md checklist assertions
Run-Test "Test 2: 06-PRODUCTION.md polygon budget checklist under ## Production Checklist" {
    $file = Join-Path $RepoRoot "RLM\prompts\06-PRODUCTION.md"
    $content = Get-Content $file -Raw
    if ($content -notmatch '(?m)^## Production Checklist[\s\S]*?3D meshes adhere to polygon budgets') {
        throw "Missing '3D meshes adhere to polygon budgets' under '## Production Checklist'"
    }
}

# Test 3: creative-constitution.md format assertions
Run-Test "Test 3: creative-constitution.md 3D models under ## Asset Formats" {
    $file = Join-Path $RepoRoot "RLM\specs\creative-constitution.md"
    $content = Get-Content $file -Raw
    if ($content -notmatch '(?m)^## Asset Formats[\s\S]*?### 3D Models and Rigs') {
        throw "Missing '### 3D Models and Rigs' under '## Asset Formats'"
    }
}

# Test 4: Plugin manifest and hooks JSON validity
Run-Test "Test 4: Plugin manifest and hooks JSON validity" {
    $pluginJson = Join-Path $RepoRoot "plugins\rlm-creative\.claude-plugin\plugin.json"
    $manifest = Get-Content $pluginJson -Raw | ConvertFrom-Json
    if ($manifest.name -ne "rlm-creative" -or $manifest.version -ne "1.0.0") {
        throw "Invalid plugin manifest: $($manifest | ConvertTo-Json -Compress)"
    }

    $hooksJson = Join-Path $RepoRoot "plugins\rlm-creative\hooks\hooks.json"
    $hooksCfg = Get-Content $hooksJson -Raw | ConvertFrom-Json
    if (-not $hooksCfg.hooks.PreToolUse -or -not $hooksCfg.hooks.PostToolUse) {
        throw "Hooks registration missing PreToolUse or PostToolUse"
    }
}

Write-Host "`nPassed $passedCount of $totalCount spec sync tests."
if ($passedCount -ne $totalCount) { exit 1 } else { exit 0 }
