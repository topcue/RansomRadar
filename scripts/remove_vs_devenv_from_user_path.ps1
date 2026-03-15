$ErrorActionPreference = "Stop"

$VsDevenvDir = "C:\Program Files\Microsoft Visual Studio\2022\Professional\Common7\IDE"
$UserPath = [System.Environment]::GetEnvironmentVariable("Path", "User")

if (-not $UserPath) {
    Write-Host "[*] User PATH is empty."
    exit 0
}

$Entries = $UserPath -split ';' | Where-Object { $_ -and $_ -ne $VsDevenvDir }
$NewPath = $Entries -join ';'

[System.Environment]::SetEnvironmentVariable("Path", $NewPath, "User")
Write-Host "[+] Removed from User PATH:"
Write-Host "    $VsDevenvDir"

# Also update current session
$SessionEntries = $env:Path -split ';' | Where-Object { $_ -and $_ -ne $VsDevenvDir }
$env:Path = $SessionEntries -join ';'
Write-Host "[+] Removed from current session PATH."