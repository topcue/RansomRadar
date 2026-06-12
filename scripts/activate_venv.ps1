$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$ActivateScript = Join-Path $RepoRoot "env\venv\Scripts\Activate.ps1"

if (-not (Test-Path -LiteralPath $ActivateScript)) {
    throw "Virtual environment not found: $ActivateScript. Run .\scripts\setup_venv.ps1 first."
}

. $ActivateScript
