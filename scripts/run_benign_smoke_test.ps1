param(
    [string]$WorkloadSource = "C:\Users\topcue\workspace\ransomware-behavior\research\experiment\storage\benign\benign_01_dotnet_build.ps1"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$RunRoot = Join-Path $RepoRoot ".tmp\smoke-test"
$InputDir = Join-Path $RunRoot "input"
$OutputDir = Join-Path $RunRoot "output"
$WorkDir = Join-Path $RunRoot "work"
$CopiedWorkload = Join-Path $InputDir "benign_01_dotnet_build.ps1"
$WprProfile = Join-Path $RepoRoot "monitor\record.wprp"
$DriverLog = Join-Path $env:SystemRoot "Temp\RansomRadarIrp.irp.tsv"
$IrpLog = Join-Path $OutputDir "benign_01_dotnet_build.irp.tsv"
$EtlPath = Join-Path $OutputDir "benign_01_dotnet_build.etl"

if (-not (Test-Path -LiteralPath $WorkloadSource)) { throw "Benign workload not found: $WorkloadSource" }
if (-not (Get-Service -Name RansomRadarIrp -ErrorAction SilentlyContinue)) { throw "RansomRadarIrp is not installed." }

New-Item -ItemType Directory -Force -Path $InputDir, $OutputDir, $WorkDir | Out-Null
Copy-Item -LiteralPath $WorkloadSource -Destination $CopiedWorkload -Force

$WprStarted = $false
$Attached = $false
try {
    $DriverService = Get-Service -Name RansomRadarIrp
    if ($DriverService.Status -ne 'Running') {
        & fltmc.exe load RansomRadarIrp
        if ($LASTEXITCODE -ne 0) { throw "Failed to load RansomRadarIrp." }
    }
    & fltmc.exe attach RansomRadarIrp C:
    if ($LASTEXITCODE -ne 0) { throw "Failed to attach RansomRadarIrp to C:." }
    $Attached = $true
    if (Test-Path -LiteralPath $DriverLog) { Remove-Item -LiteralPath $DriverLog -Force }
    & wpr.exe -start "$WprProfile!PMC" -filemode
    if ($LASTEXITCODE -ne 0) { throw "WPR failed to start." }
    $WprStarted = $true

    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $CopiedWorkload -WorkRoot $WorkDir
    if ($LASTEXITCODE -ne 0) { throw "Benign workload failed with exit code $LASTEXITCODE." }
} finally {
    if ($WprStarted) { & wpr.exe -stop $EtlPath | Out-Host }
    if ($Attached) { & fltmc.exe detach RansomRadarIrp C: 2>$null }
}

if (-not (Test-Path -LiteralPath $EtlPath)) { throw "ETL output was not created: $EtlPath" }
if (-not (Test-Path -LiteralPath $DriverLog)) { throw "IRP output was not created: $DriverLog" }
Move-Item -LiteralPath $DriverLog -Destination $IrpLog -Force
Write-Output "Benign smoke test complete."
Write-Output "Copied workload: $CopiedWorkload"
Write-Output "HPC ETL: $EtlPath"
Write-Output "IRP log: $IrpLog"
