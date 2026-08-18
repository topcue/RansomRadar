$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$EnvRoot = Join-Path $RepoRoot "env"
$VenvDir = Join-Path $EnvRoot "venv"
$RequirementsPath = Join-Path $RepoRoot "requirements.txt"

if (-not (Test-Path -LiteralPath $EnvRoot)) {
    New-Item -ItemType Directory -Path $EnvRoot | Out-Null
}

if (Test-Path -LiteralPath $VenvDir) {
    Write-Output "Existing venv found: $VenvDir"
} else {
    py -3.12 -m venv $VenvDir
    Write-Output "Venv created: $VenvDir"
}

$PythonExe = Join-Path $VenvDir "Scripts\python.exe"
& $PythonExe -m pip install --upgrade pip
& $PythonExe -m pip install -r $RequirementsPath
& $PythonExe -m pip check

Write-Output "Python environment ready: $VenvDir"
