import argparse
from pathlib import Path
import numpy as np
from typing import Tuple, List
import re

STUDY_ID = 'CC'
wave = '1'


def go_trial_success_converter(s: bytes) -> int:
    """
    Converter to translate :param s: containing a trial type into 1 or 0.
    :param s: Trial type. Trial type containing 'correct-go' indicates successful 'go' trials.
    Trial type containing 'failed-go' indicates unsuccessful 'go' trials.
    :return: 1 for successful go trials, 0 for failure go trials
    """
    if s.startswith(b'correct-go'):
        return 1
    elif s.startswith(b'failed-go'):
        return 0
    else:
        return -1


def tsv_data_read_for_latent_class(file: Path) -> Tuple[int, float, float]:
    """
    Read behavioral data out of events.tsv files.
    Return a list of tuples of (duration, go trial success or failure)
    """
    converters = {2: go_trial_success_converter}

    _, duration, trial_type = np.loadtxt(str(file),
                                         delimiter='\t',
                                         skiprows=1,
                                         converters=converters,
                                         unpack=True)
    num_failed_go = trial_type.size - np.count_nonzero(trial_type)
    successful_go_duration = np.ma.masked_where(trial_type != 1, duration)
    mean = successful_go_duration.mean()
    std_deviation = successful_go_duration.std()

    return num_failed_go, mean, std_deviation


def write_for_rescorla_wagner(file: Path, events: List[Tuple], is_go: bool = True):
    """
    Write a new file containing only the go-trial success or failure
    """
    trial_type = "_go"
    if not is_go:
        trial_type = "_stop"
    new_file = file.with_name(str(file.stem) + trial_type + str(file.suffix))
    with open(str(new_file), mode='w') as f:
        for e in events:
            f.write(f'{e[0]}\t{int(e[1])}\n')


def write_for_latent_class_analysis(file, subject_id: str, event: Tuple[int, float, float]):
    file.write(f'{subject_id}\t{event[0]}\t{event[1]}\t{event[2]}\n')


def main(input_dir: str):
    files = sorted(Path(input_dir).glob('*_task-SST_acq-1_events.tsv'))

    pattern = f'({STUDY_ID}' + '\\d{3})_ses-wave1_task-SST_acq-1_events.tsv'
    new_file_name = files[0].with_name('latent_class_analysis' + str(files[0].suffix))
    with open(str(new_file_name), mode='w') as outfile:
        for f in files:
            match = re.search(pattern, str(f.name))
            subject_id = ''
            if match:
                subject_id, = match.groups()
            events = tsv_data_read_for_latent_class(f)
            write_for_latent_class_analysis(outfile, subject_id, events)


if __name__ == "__main__":
    description = f'Create a file for modeling SST task in {STUDY_ID} study using latent class analysis'

    parser = argparse.ArgumentParser(description=description,
                                     add_help=True,
                                     formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument('-i', '--input', metavar='Input directory', action='store',
                        type=str, required=True,
                        help='absolute path to directory containing events.tsv files from the SST task.',
                        dest='input_dir'
                        )
    args = parser.parse_args()

    main(args.input_dir)
