#requires -Version 7
<#
.SYNOPSIS
  Reverse install-user-scope.ps1 for RLM-Creative. Reads the manifest and removes everything.
#>
[CmdletBinding()]
param(
  [string]$UserClaude = (Join-Path $env:USERPROFILE ".claude"),
  [switch]$KeepSettings
)

$ErrorActionPreference = "Stop"
$ManifestPath = Join-Path $UserClaude ".rlm-creative-installed.json"
$SettingsPath = Join-Path $UserClaude "settings.json"
$Sentinel = "rlm-creative"

function Write-RC($msg, $level = "info") {
  $prefix = "[rlm-creative.uninstall]"
  switch ($level) {
    "warn"  { Write-Host "$prefix $msg" -ForegroundColor Yellow }
    "error" { Write-Host "$prefix $msg" -ForegroundColor Red }
    "ok"    { Write-Host "$prefix $msg" -ForegroundColor Green }
    default { Write-Host "$prefix $msg" }
  }
}

if (-not (Test-Path $ManifestPath)) {
  Write-RC "no manifest at $ManifestPath — nothing to uninstall" "warn"
  exit 0
}

$manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json
Write-RC "removing $($manifest.items.Count) installed items…"

foreach ($item in $manifest.items) {
  $target = $item.target
  if (-not (Test-Path $target)) { Write-RC "already gone: $target" "warn"; continue }
  try {
    Remove-Item $target -Recurse -Force
    Write-RC "removed $($item.kind): $($item.name)"
  } catch {
    Write-RC "failed to remove $target : $_" "error"
  }
}

# Clean up helios-crew folder if empty
$heliosCrewDst = Join-Path $UserClaude "agents\helios-crew"
if ((Test-Path $heliosCrewDst) -and (Get-ChildItem $heliosCrewDst).Count -eq 0) {
  Remove-Item $heliosCrewDst -Force -ErrorAction SilentlyContinue
}

if (-not $KeepSettings -and (Test-Path $SettingsPath)) {
  $stamp = (Get-Date -Format "yyyyMMdd-HHmmss")
  Copy-Item $SettingsPath "$SettingsPath.rlm-creative.bak.$stamp" -Force
  $settings = Get-Content $SettingsPath -Raw | ConvertFrom-Json -AsHashtable
  $removed = 0
  if ($settings.ContainsKey("hooks")) {
    foreach ($eventName in @($settings["hooks"].Keys)) {
      $kept = @()
      foreach ($entry in $settings["hooks"][$eventName]) {
        if ($entry -is [hashtable] -and $entry['$installed_by'] -eq $Sentinel) {
          $removed += 1
        } else {
          $kept += $entry
        }
      }
      $settings["hooks"][$eventName] = $kept
    }
  }
  ($settings | ConvertTo-Json -Depth 12) | Set-Content $SettingsPath -Encoding utf8
  Write-RC "stripped $removed RLM-Creative hook entries" "ok"
}

Remove-Item $ManifestPath -Force
Write-RC "uninstalled RLM-Creative user-scope components." "ok"
