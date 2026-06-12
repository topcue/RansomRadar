param(
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$TargetDir = Join-Path $RepoRoot "monitor\IOMonitor\minifilter_helper\target"

if (-not (Test-Path -LiteralPath $TargetDir)) {
    Write-Output "Already clean: $TargetDir"
    return
}

if ($WhatIf) {
    Write-Output "Would remove: $TargetDir"
    return
}

Remove-Item -LiteralPath $TargetDir -Recurse -Force
Write-Output "Removed: $TargetDir"
