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
$ControlExe = Join-Path $RepoRoot "monitor\IOMonitor\IRPCollectionDrv\user\x64\Debug\minispy.exe"
$IrpLog = Join-Path $OutputDir "benign_01_dotnet_build.irp.txt"
$EtlPath = Join-Path $OutputDir "benign_01_dotnet_build.etl"

if (-not (Test-Path -LiteralPath $WorkloadSource)) { throw "Benign workload not found: $WorkloadSource" }
if (-not (Test-Path -LiteralPath $ControlExe)) { throw "IRP control executable not found: $ControlExe" }
if (-not (Get-Service -Name RansomRadarIrp -ErrorAction SilentlyContinue)) { throw "RansomRadarIrp is not installed." }

New-Item -ItemType Directory -Force -Path $InputDir, $OutputDir, $WorkDir | Out-Null
Copy-Item -LiteralPath $WorkloadSource -Destination $CopiedWorkload -Force

$Process = $null
$WprStarted = $false
try {
    & fltmc.exe load RansomRadarIrp 2>$null
    & wpr.exe -start "$WprProfile!PMC" -filemode
    if ($LASTEXITCODE -ne 0) { throw "WPR failed to start." }
    $WprStarted = $true

    $StartInfo = [Diagnostics.ProcessStartInfo]::new()
    $StartInfo.FileName = $ControlExe
    $StartInfo.Arguments = "/a C: /f `"$IrpLog`" /s"
    $StartInfo.UseShellExecute = $false
    $StartInfo.RedirectStandardInput = $true
    $StartInfo.RedirectStandardOutput = $true
    $StartInfo.RedirectStandardError = $true
    $StartInfo.CreateNoWindow = $true
    $Process = [Diagnostics.Process]::Start($StartInfo)
    Start-Sleep -Seconds 2
    if ($Process.HasExited) { throw "IRP control process exited before the workload: $($Process.StandardError.ReadToEnd())" }

    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $CopiedWorkload -WorkRoot $WorkDir
    if ($LASTEXITCODE -ne 0) { throw "Benign workload failed with exit code $LASTEXITCODE." }
} finally {
    if ($WprStarted) { & wpr.exe -stop $EtlPath | Out-Host }
    if ($Process -and -not $Process.HasExited) {
        $Process.StandardInput.Close()
        if (-not $Process.WaitForExit(15000)) { $Process.Kill() }
    }
}

if (-not (Test-Path -LiteralPath $EtlPath)) { throw "ETL output was not created: $EtlPath" }
if (-not (Test-Path -LiteralPath $IrpLog)) { throw "IRP output was not created: $IrpLog" }
Write-Output "Benign smoke test complete."
Write-Output "Copied workload: $CopiedWorkload"
Write-Output "HPC ETL: $EtlPath"
Write-Output "IRP log: $IrpLog"
