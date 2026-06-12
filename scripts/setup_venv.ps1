$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$EnvRoot = Join-Path $RepoRoot "env"
$VenvDir = Join-Path $EnvRoot "venv"

if (-not (Test-Path -LiteralPath $EnvRoot)) {
    New-Item -ItemType Directory -Path $EnvRoot | Out-Null
}

if (Test-Path -LiteralPath $VenvDir) {
    Write-Output "Existing venv found: $VenvDir"
    Write-Output "Remove it manually first if you want a clean rebuild."
    return
}

py -3.12 -m venv $VenvDir

$PythonExe = Join-Path $VenvDir "Scripts\python.exe"
& $PythonExe -m pip install --upgrade pip

Write-Output "Venv created: $VenvDir"
