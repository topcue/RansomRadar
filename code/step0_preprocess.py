from config import RAW_ROOT_PATH, HPC_ROOT_path, PARSER_PATH, PARSER_PROFILE_PATH
import argparse
import os
import shutil
import subprocess


TICKS_PER_SECOND = 10_000_000


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--labels', default='ransomware,benign')
    parser.add_argument(
        '--starttime-offset-seconds',
        type=float,
        default=0.0,
        help='Add an offset to generated *_starttime.txt values; use -3600 for the UTC+8 parser shift on this UTC+9 host.',
    )
    parser.add_argument('--overwrite', action='store_true')
    return parser.parse_args()


def run_command(args):
    subprocess.run(args, check=True)


def apply_starttime_offset(path, offset_seconds):
    if offset_seconds == 0:
        return
    with open(path, 'r') as f:
        starttime = int(f.read().strip())
    with open(path, 'w') as f:
        f.write(str(starttime + int(round(offset_seconds * TICKS_PER_SECOND))))


def main():
    args = parse_args()
    labels = [label.strip() for label in args.labels.split(',') if label.strip()]
    for label in labels:
        raw_dir = f'{RAW_ROOT_PATH}\\{label}'
        if not os.path.isdir(raw_dir):
            print(f'skip missing raw directory: {raw_dir}')
            continue
        for file in os.listdir(raw_dir):
            if not file.lower().endswith('.etl'):
                continue
            sample = os.path.splitext(file)[0]
            hpc_dir = f'{HPC_ROOT_path}\\{label}'
            hpc_csv_path = f'{hpc_dir}\\{sample}.csv'
            hpc_temp_dir = f'{hpc_dir}\\{sample}'
            starttime_path = f'{hpc_dir}\\{sample}_starttime.txt'
            os.makedirs(hpc_dir, exist_ok=True)
            print(f'start process {file}')
            try:
                if args.overwrite or not os.path.exists(hpc_csv_path):
                    if os.path.exists(hpc_temp_dir):
                        shutil.rmtree(hpc_temp_dir)
                    run_command([
                        'wpaexporter.exe', '/tti', '-i', f'{raw_dir}\\{file}',
                        '-profile', PARSER_PROFILE_PATH, '-outputfolder', hpc_temp_dir,
                    ])
                    os.replace(f'{hpc_temp_dir}\\PMC_Summary_Table_test.csv', hpc_csv_path)
                    shutil.rmtree(hpc_temp_dir)
                if args.overwrite or not os.path.exists(starttime_path):
                    run_command([PARSER_PATH, f'{raw_dir}\\{file}', starttime_path])
                    apply_starttime_offset(starttime_path, args.starttime_offset_seconds)
            except Exception as exc:
                print(f'error process {raw_dir}\\{file}: {exc}')
                continue
            print(f'finish process {raw_dir}\\{file}')


if __name__ == '__main__':
    main()
