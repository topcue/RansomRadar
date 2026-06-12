$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$ConfigPath = Join-Path $RepoRoot "code\config.py"

if (-not (Test-Path -LiteralPath $ConfigPath)) {
    throw "config.py not found: $ConfigPath"
}

$escapedRepoRoot = $RepoRoot.Replace("\", "\\")
$content = Get-Content -Raw -LiteralPath $ConfigPath
$updatedContent = $content -replace "(?m)^PROJECT_PATH\s*=.*$", "PROJECT_PATH = '$escapedRepoRoot'"

if ($updatedContent -eq $content) {
    Write-Output "No change needed: $ConfigPath"
    return
}

Set-Content -NoNewline -LiteralPath $ConfigPath -Value $updatedContent
Write-Output "Updated PROJECT_PATH in: $ConfigPath"
Write-Output "PROJECT_PATH = '$escapedRepoRoot'"
