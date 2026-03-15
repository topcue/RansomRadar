param(
    [string]$Project = "C:\Users\user\workspace\RansomRadar",
    [string]$Sample = "benign_test_01"
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false

function Assert-PathExists {
    param([string]$PathToCheck, [string]$Message)
    if (-not (Test-Path $PathToCheck)) {
        throw $Message
    }
}

function Show-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "============================================================"
    Write-Host $Title
    Write-Host "============================================================"
}

Set-Location $Project

# Optional: activate venv if script exists
$ActivateScript = Join-Path $Project "scripts\activate_venv.ps1"
if (Test-Path $ActivateScript) {
    . $ActivateScript
}

$RawRoot      = Join-Path $Project "dataset\raw"
$RawBenign    = Join-Path $RawRoot "benign"
$RawRansom    = Join-Path $RawRoot "ransomware"

$HpcRoot      = Join-Path $Project "dataset\hpcdata"
$HpcBenign    = Join-Path $HpcRoot "benign"
$HpcRansom    = Join-Path $HpcRoot "ransomware"

$Feature1s    = Join-Path $Project "features\1s\benign"
$Feature100ms = Join-Path $Project "features\100ms\benign"

$PmuOut       = Join-Path $Project "pmu_test\wpa_out"
$TestDir      = Join-Path $Project "tmp_benign_io"

$Profile      = Join-Path $Project "monitor\record_guest_test.wprp"
$ParseProfile = Join-Path $Project "helper\parse.wpaProfile"
$Step0Log     = Join-Path $Project "step0_run_test.log"
$Step1Log     = Join-Path $Project "step1_run_test.log"

$Etl          = Join-Path $RawBenign "$Sample.etl"
$HpcCsv       = Join-Path $HpcBenign "$Sample.csv"
$HpcStart     = Join-Path $HpcBenign "${Sample}_starttime.txt"
$Feature1sCsv = Join-Path $Feature1s "$Sample.csv"
$Feature100Csv= Join-Path $Feature100ms "$Sample.csv"

Show-Section "0. Basic checks"

Assert-PathExists $Profile "Missing profile: $Profile"
Assert-PathExists $ParseProfile "Missing parse profile: $ParseProfile"
Assert-PathExists (Join-Path $Project "code\step0_preprocess.py") "Missing step0_preprocess.py"
Assert-PathExists (Join-Path $Project "code\step1_extract_feature.py") "Missing step1_extract_feature.py"

python --version
Get-Item $Profile
Get-Item $ParseProfile

Show-Section "1. Create required directories"

New-Item -ItemType Directory -Force $RawBenign    | Out-Null
New-Item -ItemType Directory -Force $RawRansom    | Out-Null
New-Item -ItemType Directory -Force $HpcBenign    | Out-Null
New-Item -ItemType Directory -Force $HpcRansom    | Out-Null
New-Item -ItemType Directory -Force $Feature1s    | Out-Null
New-Item -ItemType Directory -Force $Feature100ms | Out-Null
New-Item -ItemType Directory -Force $PmuOut       | Out-Null
New-Item -ItemType Directory -Force $TestDir      | Out-Null

Show-Section "2. Clean previous outputs"

Remove-Item "$PmuOut\*"         -Force -ErrorAction SilentlyContinue
Remove-Item $Etl                -Force -ErrorAction SilentlyContinue
Remove-Item $HpcCsv             -Force -ErrorAction SilentlyContinue
Remove-Item $HpcStart           -Force -ErrorAction SilentlyContinue
Remove-Item $Feature1sCsv       -Force -ErrorAction SilentlyContinue
Remove-Item $Feature100Csv      -Force -ErrorAction SilentlyContinue
Remove-Item $Step0Log           -Force -ErrorAction SilentlyContinue
Remove-Item "$TestDir\*"        -Force -ErrorAction SilentlyContinue

Show-Section "3. Collect ETL with guest adaptation PMU profile"

wpr -cancel | Out-Host
wpr -start $Profile -filemode

Write-Host ""
Write-Host "[PMU collection started]"
Write-Host "You have 30 seconds to perform benign activity."
Write-Host "Examples: Explorer navigation, file open/copy, launching apps."
Write-Host ""

$job = Start-Job -ScriptBlock {
    param($Dir)
    1..300 | ForEach-Object {
        $p = Join-Path $Dir ("file_{0:D4}.txt" -f $_)
        "hello $_ $(Get-Date -Format o)" | Set-Content -Path $p
        Start-Sleep -Milliseconds 30
    }
} -ArgumentList $TestDir

for ($sec = 30; $sec -ge 1; $sec--) {
    Write-Host ("Stopping in {0} second(s)..." -f $sec)
    Start-Sleep -Seconds 1
}

Receive-Job $job -ErrorAction SilentlyContinue | Out-Null
Remove-Job $job -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "[Stopping WPR and saving ETL]"
wpr -stop $Etl

Assert-PathExists $Etl "ETL was not created."

Get-Item $Etl | Format-List FullName, Length, LastWriteTime

Show-Section "4. Manual export sanity check"

wpaexporter.exe /tti -i $Etl -profile $ParseProfile -outputfolder $PmuOut

$ManualCsv = Join-Path $PmuOut "PMC_Summary_Table_test.csv"
Assert-PathExists $ManualCsv "Manual exported CSV was not created."

Get-Item $ManualCsv | Format-List FullName, Length, LastWriteTime

python -c "import pandas as pd; df=pd.read_csv(r'$ManualCsv', low_memory=False); print(df['Counter'].value_counts())"

Show-Section "5. Run step0"

# python .\code\step0_preprocess.py 2>&1 | Tee-Object -FilePath $Step0Log
cmd /c "python .\code\step0_preprocess.py 1> `"$Step0Log`" 2>&1"
Get-Content $Step0Log -Tail 50

Assert-PathExists $HpcCsv   "step0 did not create HPC CSV: $HpcCsv"
Assert-PathExists $HpcStart "step0 did not create starttime file: $HpcStart"

Get-Item $HpcCsv   | Format-List FullName, Length, LastWriteTime
Get-Item $HpcStart | Format-List FullName, Length, LastWriteTime

Write-Host ""
Write-Host "[step0 log tail]"
Get-Content $Step0Log -Tail 50

Show-Section "6. Remove raw-side starttime helper file if present"

$RawStart = Join-Path $RawBenign "${Sample}_starttime.txt"
Remove-Item $RawStart -Force -ErrorAction SilentlyContinue

Show-Section "7. Run step1 compatibility test (1s / 100ms)"

# python -c "import sys; sys.path.append(r'.\code'); from step1_extract_feature import calculate_1s_feature, calculate_100ms_feature; calculate_1s_feature(r'$HpcCsv', r'$Feature1sCsv'); calculate_100ms_feature(r'$HpcCsv', r'$Feature100Csv')"

Remove-Item $Step1Log -Force -ErrorAction SilentlyContinue
cmd /c "python .\code\step1_extract_feature.py 1> `"$Step1Log`" 2>&1"

Write-Host "[step1 log tail]"
Get-Content $Step1Log -Tail 100

Assert-PathExists $Feature1sCsv   "1s feature CSV was not created."
Assert-PathExists $Feature100Csv  "100ms feature CSV was not created."

Show-Section "8. Show feature outputs"

Write-Host "[1s feature]"
Get-Item $Feature1sCsv | Format-List FullName, Length, LastWriteTime
Get-Content $Feature1sCsv -TotalCount 10

Write-Host ""
Write-Host "[100ms feature]"
Get-Item $Feature100Csv | Format-List FullName, Length, LastWriteTime
Get-Content $Feature100Csv -TotalCount 10

Show-Section "9. Final notes"

Write-Host "This script is for guest adaptation testing, not exact Intel-profile reproduction."
Write-Host "If 1s feature is empty but 100ms feature has rows, that usually means LLCReference is still missing/zero."