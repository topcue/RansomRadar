param(
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$Paths = @(
    (Join-Path $RepoRoot "monitor\IOMonitor\IRPCollectionDrv\.vs"),
    (Join-Path $RepoRoot "monitor\IOMonitor\IRPCollectionDrv\filter\x64"),
    (Join-Path $RepoRoot "monitor\IOMonitor\IRPCollectionDrv\filter\ARM64"),
    (Join-Path $RepoRoot "monitor\IOMonitor\IRPCollectionDrv\user\x64"),
    (Join-Path $RepoRoot "monitor\IOMonitor\IRPCollectionDrv\user\ARM64")
)

$found = $false
foreach ($path in $Paths) {
    if (-not (Test-Path -LiteralPath $path)) {
        Write-Output "Already clean: $path"
        continue
    }

    $found = $true
    if ($WhatIf) {
        Write-Output "Would remove: $path"
        continue
    }

    Remove-Item -LiteralPath $path -Recurse -Force
    Write-Output "Removed: $path"
}

if (-not $found) {
    Write-Output "IRP driver outputs are clean."
}
