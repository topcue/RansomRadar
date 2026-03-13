$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$EnvRoot = Join-Path $RepoRoot "env"
$VenvDir = Join-Path $EnvRoot "venv"

if (-not (Test-Path $EnvRoot)) {
    New-Item -ItemType Directory -Path $EnvRoot | Out-Null
}

if (Test-Path $VenvDir) {
    Write-Host "[*] Existing venv found: $VenvDir"
    Write-Host "[*] Remove it manually first if you want a clean rebuild."
    exit 0
}

py -3.12 -m venv $VenvDir

$PythonExe = Join-Path $VenvDir "Scripts\python.exe"
& $PythonExe -m pip install --upgrade pip

Write-Host "[+] Venv created with Python 3.12 at: $VenvDir"

# EOF
