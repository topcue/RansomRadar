param(
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$Paths = @(
    (Join-Path $RepoRoot "helper\PARSER\PARSER\bin"),
    (Join-Path $RepoRoot "helper\PARSER\PARSER\obj"),
    (Join-Path $RepoRoot "helper\PARSER\packages")
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
    Write-Output "Parser outputs are clean."
}
