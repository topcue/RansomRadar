$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$HelperDir = Join-Path $RepoRoot "monitor\IOMonitor\minifilter_helper"
$OutputLib = Join-Path $HelperDir "target\release\minifilter_helper.lib"
$CargoBin = Join-Path $env:USERPROFILE ".cargo\bin"

if (-not (Test-Path -LiteralPath $HelperDir)) {
    throw "minifilter_helper directory not found: $HelperDir"
}

if (Test-Path -LiteralPath $CargoBin) {
    $env:Path = "$CargoBin;$env:Path"
}

$cargo = Get-Command cargo -ErrorAction SilentlyContinue
if (-not $cargo) {
    throw "cargo not found. Install Rust nightly MSVC first."
}

Write-Output "Building minifilter_helper..."
Write-Output "Cargo: $($cargo.Source)"
Write-Output "Directory: $HelperDir"

Push-Location $HelperDir
try {
    cargo build --release
}
finally {
    Pop-Location
}

if (-not (Test-Path -LiteralPath $OutputLib)) {
    throw "minifilter_helper.lib was not created: $OutputLib"
}

Write-Output "minifilter_helper built: $OutputLib"
