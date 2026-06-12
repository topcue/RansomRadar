$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$SolutionPath = Join-Path $RepoRoot "helper\PARSER\PARSER.sln"
$ParserExe = Join-Path $RepoRoot "helper\PARSER\PARSER\bin\Release\PARSER.exe"
$VsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"

if (-not (Test-Path -LiteralPath $SolutionPath)) {
    throw "PARSER solution not found: $SolutionPath"
}

if (-not (Test-Path -LiteralPath $VsWhere)) {
    throw "vswhere.exe not found. Install Visual Studio 2022 first."
}

$MSBuild = & $VsWhere `
    -products * `
    -requires Microsoft.Component.MSBuild `
    -find "MSBuild\**\Bin\MSBuild.exe" |
    Select-Object -First 1

if (-not $MSBuild) {
    throw "MSBuild.exe not found. Install Visual Studio 2022 with MSBuild."
}

Write-Output "Building PARSER..."
Write-Output "MSBuild: $MSBuild"
Write-Output "Solution: $SolutionPath"

& $MSBuild $SolutionPath /t:Restore,Build /p:Configuration=Release /m

if (-not (Test-Path -LiteralPath $ParserExe)) {
    throw "PARSER.exe was not created: $ParserExe"
}

Write-Output "PARSER built: $ParserExe"
