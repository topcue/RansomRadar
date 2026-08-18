# Host reproduction report

Date: 2026-08-18

## Scope

Rebuilt the original PARSER, Rust helper, and IRP minifilter; then ran the
provided feature CSVs and models through `step2_encryption_detection.py`,
`step3_temporal_correlation_detection.py`, and `step4_final_result.py`.

Baseline provided-feature result:

- benign false-positive rate: 0.48% (5/1031)
- ransomware recall: 97.26% (142/146)

## Added benign host capture

The `ransomware-behavior` workload `benign_01_dotnet_build.ps1` was collected
with WPR PMC sampling and the IRP minifilter, then processed through the
original `step0_preprocess.py` and `step1_extract_feature.py` flow as
`benign_dotnet_smoke`.

- HPC sampling duration: 11.14 seconds
- IRP logging duration: 22.53 seconds
- generated `dotnet.exe` rows: 12 one-second features and 12 LSTM windows
- encryption predictions for `dotnet.exe`: 0 positive rows
- temporal-correlation predictions for `dotnet.exe`: 0 positive rows
- final benign false-positive rate with the added sample: 0.47% (5/1073)
- ransomware recall unchanged: 97.26% (142/146)

The raw ETL/HPC/IRP files are intentionally excluded through `dataset/`; the
three derived benign feature CSVs are versioned under `features/`.

## Compatibility fix

On this UTC+9 host, the original PARSER emits an ETL start time exactly 3600
seconds later than the IRP FILETIME clock because its source contains an old
UTC+8 offset. `step0_preprocess.py` now accepts
`--starttime-offset-seconds`; this capture used `-3600`, leaving a 0.08-second
IRP/HPC start difference.
