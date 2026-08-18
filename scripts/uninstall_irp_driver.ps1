$ErrorActionPreference = "Stop"
$ServiceName = "RansomRadarIrp"
$InstalledDriver = Join-Path $env:SystemRoot "System32\drivers\RansomRadarIrp.sys"

$Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = [Security.Principal.WindowsPrincipal]::new($Identity)
if (-not $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Run this script from an elevated PowerShell session."
}

& fltmc.exe unload $ServiceName 2>$null
& sc.exe delete $ServiceName 2>$null
if (Test-Path -LiteralPath $InstalledDriver) {
    Remove-Item -LiteralPath $InstalledDriver -Force
}
Write-Output "Removed service and driver file: $ServiceName"
