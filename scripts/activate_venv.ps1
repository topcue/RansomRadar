$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$ActivateScript = Join-Path $RepoRoot "env\venv\Scripts\Activate.ps1"

if (-not (Test-Path $ActivateScript)) {
    Write-Error "Virtual environment not found: $ActivateScript"
    Write-Error "Run .\scripts\create_venv.ps1 first."
    exit 1
}

. $ActivateScript

# EOf
