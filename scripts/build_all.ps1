param(
    [ValidateSet("Debug", "Release")][string]$Configuration = "Debug",
    [ValidateSet("x64", "ARM64")][string]$Platform = "x64",
    [switch]$SkipPythonEnvironment
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

& (Join-Path $ScriptDir "check_prerequisites.ps1")
if (-not $SkipPythonEnvironment) { & (Join-Path $ScriptDir "setup_venv.ps1") }
& (Join-Path $ScriptDir "update_config.ps1")
& (Join-Path $ScriptDir "build_parser.ps1")
& (Join-Path $ScriptDir "build_irp_driver.ps1") -Configuration $Configuration -Platform $Platform

Write-Output "RansomRadar build completed successfully."
