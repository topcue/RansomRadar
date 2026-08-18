param(
    [string]$SetupAssetsRoot = (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "setup_env\base"),
    [switch]$InstallMissing,
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Checks = @(& (Join-Path $ScriptDir "check_prerequisites.ps1") -PassThru)
$Missing = @($Checks | Where-Object { -not $_.Ready })

if ($Missing.Count -eq 0) {
    Write-Output "No prerequisite installation is needed."
} elseif (-not $InstallMissing) {
    Write-Output "Missing prerequisites were found. Re-run from elevated PowerShell with -InstallMissing."
    exit 2
} else {
    $Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = [Security.Principal.WindowsPrincipal]::new($Identity)
    if (-not $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "-InstallMissing requires an elevated PowerShell session."
    }
    if (-not (Test-Path -LiteralPath $SetupAssetsRoot)) { throw "Setup assets not found: $SetupAssetsRoot" }

    $MissingNames = @($Missing.Component)
    if ($MissingNames -contains "Required HPC counters") {
        throw "The CPU/OS does not expose every required HPC counter; software installation cannot fix this."
    }

    $Installers = @()
    if ($MissingNames -contains "Python 3.12") {
        $Installers += @{ Path = "python-3.12.10\Install-Python-3.12.10.ps1"; Args = @("-InstallAllUsers") }
    }
    if ($MissingNames -contains "Visual Studio x64 MSBuild" -or
        $MissingNames -contains "Windows SDK 26100" -or
        $MissingNames -contains ".NET Framework 4.7.2 refs") {
        $Installers += @{ Path = "visual-studio-2022-community\Install-VisualStudio2022Community.ps1"; Args = @("-Quiet") }
    }
    if ($MissingNames -contains "WPR" -or $MissingNames -contains "WPAExporter") {
        $Installers += @{ Path = "windows-adk-10.1.26100.2454\Install-WindowsADK.ps1"; Args = @() }
    }
    if ($MissingNames -contains "WDK driver toolset") {
        $Installers += @{ Path = "windows-wdk-10.0.26100\Install-WindowsWDK.ps1"; Args = @("-Quiet") }
    }
    if ($MissingNames -contains "Rust nightly MSVC") {
        $Installers += @{ Path = "rust-nightly-msvc\Install-RustNightlyMSVC.ps1"; Args = @() }
    }
    foreach ($Installer in $Installers) {
        $Path = Join-Path $SetupAssetsRoot $Installer.Path
        if (-not (Test-Path -LiteralPath $Path)) { throw "Installer script not found: $Path" }
        Write-Output "Running: $Path"
        $InstallerArgs = [object[]]$Installer.Args
        & $Path @InstallerArgs
    }
    Write-Output "Installation finished. Reboot if Windows requests it, then run this script again without -InstallMissing."
    if (-not $SkipBuild) { Write-Output "Build deferred until prerequisites are re-checked after installation." }
    return
}

if (-not $SkipBuild) { & (Join-Path $ScriptDir "build_all.ps1") }
