param(
    [switch]$EnableTestSigning,
    [switch]$Replace
)

$ErrorActionPreference = "Stop"
$ServiceName = "RansomRadarIrp"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$BuildDir = Join-Path $RepoRoot "monitor\IOMonitor\IRPCollectionDrv\filter\x64\Debug"
$SourceDriver = Join-Path $BuildDir "minispy.sys"
$Certificate = Join-Path $BuildDir "minispy.cer"
$InstalledDriver = Join-Path $env:SystemRoot "System32\drivers\RansomRadarIrp.sys"

$Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = [Security.Principal.WindowsPrincipal]::new($Identity)
if (-not $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Run this script from an elevated PowerShell session."
}
if (-not (Test-Path -LiteralPath $SourceDriver)) { throw "Build the Debug x64 driver first: $SourceDriver" }
if (-not (Test-Path -LiteralPath $Certificate)) { throw "WDK test certificate not found: $Certificate" }

if ($EnableTestSigning) {
    & bcdedit.exe /set testsigning on
    if ($LASTEXITCODE -ne 0) { throw "Failed to enable Windows test-signing mode." }
    Write-Output "Test-signing mode was enabled. Reboot Windows, then run this script again without -EnableTestSigning."
    return
}

& sc.exe query $ServiceName *> $null
if ($LASTEXITCODE -eq 0) {
    if (-not $Replace) { throw "Service already exists: $ServiceName. Use -Replace after rebuilding." }
    & fltmc.exe unload $ServiceName 2>$null
    & sc.exe delete $ServiceName | Out-Null
    Start-Sleep -Seconds 1
}

Import-Certificate -FilePath $Certificate -CertStoreLocation Cert:\LocalMachine\Root | Out-Null
Import-Certificate -FilePath $Certificate -CertStoreLocation Cert:\LocalMachine\TrustedPublisher | Out-Null
Copy-Item -LiteralPath $SourceDriver -Destination $InstalledDriver -Force

& sc.exe create $ServiceName type= filesys start= demand binPath= "\SystemRoot\System32\drivers\RansomRadarIrp.sys" DisplayName= "RansomRadar IRP Monitor"
if ($LASTEXITCODE -ne 0) { throw "Failed to create service: $ServiceName" }

$ServiceKey = "HKLM:\SYSTEM\CurrentControlSet\Services\$ServiceName"
$InstancesKey = Join-Path $ServiceKey "Instances"
$InstanceKey = Join-Path $InstancesKey "RansomRadarIrp Instance"
New-Item -Path $InstanceKey -Force | Out-Null
New-ItemProperty -Path $InstancesKey -Name DefaultInstance -Value "RansomRadarIrp Instance" -PropertyType String -Force | Out-Null
New-ItemProperty -Path $InstanceKey -Name Altitude -Value "385100" -PropertyType String -Force | Out-Null
New-ItemProperty -Path $InstanceKey -Name Flags -Value 1 -PropertyType DWord -Force | Out-Null

& fltmc.exe load $ServiceName
if ($LASTEXITCODE -ne 0) { throw "Driver installation completed, but filter loading failed." }
Write-Output "Installed and loaded: $ServiceName ($InstalledDriver)"
