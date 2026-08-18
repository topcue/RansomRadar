param(
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Debug",

    [ValidateSet("x64", "ARM64")]
    [string]$Platform = "x64",

    [switch]$SkipPackageVerification
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$SolutionPath = Join-Path $RepoRoot "monitor\IOMonitor\IRPCollectionDrv\minispy.sln"
$VsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"

if (-not (Test-Path -LiteralPath $SolutionPath)) {
    throw "IRPCollectionDrv solution not found: $SolutionPath"
}

if (-not (Test-Path -LiteralPath $VsWhere)) {
    throw "vswhere.exe not found. Install Visual Studio 2022 first."
}

$MSBuild = & $VsWhere `
    -products * `
    -requires Microsoft.Component.MSBuild `
    -find "MSBuild\**\Bin\amd64\MSBuild.exe" |
    Select-Object -First 1

if (-not $MSBuild) {
    $MSBuild = & $VsWhere `
    -products * `
    -requires Microsoft.Component.MSBuild `
    -find "MSBuild\**\Bin\MSBuild.exe" |
    Select-Object -First 1
}

if (-not $MSBuild) {
    throw "MSBuild.exe not found. Install Visual Studio 2022 with MSBuild."
}

& (Join-Path $ScriptDir "build_minifilter_helper.ps1")

Write-Output "Building IRPCollection driver..."
Write-Output "MSBuild: $MSBuild"
Write-Output "Solution: $SolutionPath"
Write-Output "Configuration: $Configuration"
Write-Output "Platform: $Platform"
Write-Output "SkipPackageVerification: $($SkipPackageVerification.IsPresent)"

$BuildArgs = @(
    $SolutionPath,
    "/t:Build",
    "/p:Configuration=$Configuration",
    "/p:Platform=$Platform",
    "/m"
)

if ($SkipPackageVerification) {
    $BuildArgs += "/p:SkipPackageVerification=true"
}

$BuildOutput = & $MSBuild @BuildArgs 2>&1
$BuildExitCode = $LASTEXITCODE
$BuildOutput | Write-Output

if ($BuildExitCode -ne 0) {
    throw "IRPCollection driver build failed with exit code $BuildExitCode."
}

$BuildErrors = $BuildOutput | Where-Object {
    $_ -match ":\s*error\s*:|error\s+MSB\d+"
}

if ($BuildErrors) {
    throw "IRPCollection driver build reported errors. See the MSBuild output above."
}

$DriverSys = Join-Path $RepoRoot "monitor\IOMonitor\IRPCollectionDrv\filter\$Platform\$Configuration\minispy.sys"
$UserExe = Join-Path $RepoRoot "monitor\IOMonitor\IRPCollectionDrv\user\$Platform\$Configuration\minispy.exe"

if (-not (Test-Path -LiteralPath $DriverSys)) {
    throw "Driver sys file was not created: $DriverSys"
}

if (-not (Test-Path -LiteralPath $UserExe)) {
    throw "User-mode tool was not created: $UserExe"
}

Write-Output "Driver built: $DriverSys"
Write-Output "User tool built: $UserExe"
