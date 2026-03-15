$ErrorActionPreference = "Stop"

$VsDevenvDir = "C:\Program Files\Microsoft Visual Studio\2022\Professional\Common7\IDE"
$UserPath = [System.Environment]::GetEnvironmentVariable("Path", "User")

if (-not $UserPath) {
    $UserPath = ""
}

$Entries = $UserPath -split ';' | Where-Object { $_ -ne "" }

if ($Entries -contains $VsDevenvDir) {
    Write-Host "[*] devenv path is already in User PATH."
} else {
    $NewPath = (($Entries + $VsDevenvDir) | Select-Object -Unique) -join ';'
    [System.Environment]::SetEnvironmentVariable("Path", $NewPath, "User")
    Write-Host "[+] Added to User PATH:"
    Write-Host "    $VsDevenvDir"
}

# Also update current session
if (-not (($env:Path -split ';') -contains $VsDevenvDir)) {
    $env:Path += ";$VsDevenvDir"
    Write-Host "[+] Added to current session PATH."
}

Write-Host "[*] You may need to open a new terminal for all apps to see the updated PATH."