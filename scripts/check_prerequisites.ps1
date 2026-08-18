param([switch]$PassThru)

$ErrorActionPreference = "Stop"
$Checks = [System.Collections.Generic.List[object]]::new()

function Add-Check([string]$Name, [bool]$Ready, [string]$Detail) {
    $Checks.Add([pscustomobject]@{ Component = $Name; Ready = $Ready; Detail = $Detail })
}

$KitRoot = "${env:ProgramFiles(x86)}\Windows Kits\10"
$VsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$Wpr = Get-Command wpr.exe -ErrorAction SilentlyContinue
$WpaExporter = Get-Command WPAExporter.exe -ErrorAction SilentlyContinue
if (-not $WpaExporter) {
    $Candidate = Join-Path $KitRoot "Windows Performance Toolkit\WPAExporter.exe"
    if (Test-Path -LiteralPath $Candidate) { $WpaExporter = Get-Item $Candidate }
}

Add-Check "WPR" ($null -ne $Wpr) $(if ($Wpr) { $Wpr.Source } else { "Install Windows ADK Performance Toolkit" })
Add-Check "WPAExporter" ($null -ne $WpaExporter) $(if ($WpaExporter) { $WpaExporter.Source } else { "Install Windows ADK Performance Toolkit" })

$MSBuild = $null
if (Test-Path -LiteralPath $VsWhere) {
    $MSBuild = & $VsWhere -products * -requires Microsoft.Component.MSBuild -find "MSBuild\**\Bin\amd64\MSBuild.exe" | Select-Object -First 1
}
Add-Check "Visual Studio x64 MSBuild" ($null -ne $MSBuild) $(if ($MSBuild) { $MSBuild } else { "Install VS 2022 C++/.NET workloads" })

$DriverToolset = Get-ChildItem -Path "${env:ProgramFiles}\Microsoft Visual Studio\2022\*\MSBuild\Microsoft\VC" -Filter WindowsKernelModeDriver10.0 -Directory -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
Add-Check "WDK driver toolset" ($null -ne $DriverToolset) $(if ($DriverToolset) { $DriverToolset.FullName } else { "Install WDK 10.0.26100 after Visual Studio" })

$SdkInclude = Get-ChildItem -Path (Join-Path $KitRoot "Include") -Filter 10.0.26100.0 -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
Add-Check "Windows SDK 26100" ($null -ne $SdkInclude) $(if ($SdkInclude) { $SdkInclude.FullName } else { "Install Windows 11 SDK 26100" })

$Net472 = Test-Path -LiteralPath "${env:ProgramFiles(x86)}\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.7.2"
Add-Check ".NET Framework 4.7.2 refs" $Net472 $(if ($Net472) { "Installed" } else { "Install targeting pack through Visual Studio" })

$PyLauncher = Get-Command py.exe -ErrorAction SilentlyContinue
$Py = if ($PyLauncher) { & $PyLauncher.Source -3.12 -c "import sys; print(sys.executable)" 2>$null } else { $null }
$PyReady = ($null -ne $Py -and $LASTEXITCODE -eq 0)
Add-Check "Python 3.12" $PyReady $(if ($PyReady) { $Py } else { "Install Python 3.12" })

$Rust = Get-Command rustup.exe -ErrorAction SilentlyContinue
$Nightly = if ($Rust) { (& rustup toolchain list 2>$null | Select-String '^nightly.*msvc') } else { $null }
Add-Check "Rust nightly MSVC" ($null -ne $Nightly) $(if ($Nightly) { $Nightly.Line } else { "Install rustup nightly-x86_64-pc-windows-msvc" })

$RequiredCounters = @("BranchInstructionRetired", "BranchMispredictsRetired", "LLCReference", "LLCMisses", "InstructionsRetiredFixed")
$CounterOutput = if ($Wpr) { (& wpr.exe -pmcsources 2>$null | Out-String) } else { "" }
$MissingCounters = $RequiredCounters | Where-Object { $CounterOutput -notmatch [regex]::Escape($_) }
Add-Check "Required HPC counters" ($MissingCounters.Count -eq 0) $(if ($MissingCounters.Count -eq 0) { $RequiredCounters -join ", " } else { "Missing: $($MissingCounters -join ', ')" })

$Checks | Format-Table -AutoSize | Out-Host
$Failed = @($Checks | Where-Object { -not $_.Ready })
if ($PassThru) { return $Checks }
if ($Failed.Count -gt 0) { throw "$($Failed.Count) prerequisite check(s) failed." }
Write-Output "All prerequisites are ready."
