import argparse
from pathlib import Path
import numpy as np
from typing import Tuple, List

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


def stop_trial_success_converter(s: bytes) -> int:
    """
    Converter to translate :param s: containing a trial type into 1 or 0.
    :param s: Trial type. Trial type containing 'correct-stop' indicates successful 'no-go' trials.
    Trial type containing 'failed-stop' indicates unsuccessful 'no-go' trials.
    :return: 1 for successful go trials, 0 for failure go trials
    """
    if s.startswith(b'correct-stop'):
        return 1
    elif s.startswith(b'failed-stop'):
        return 0
    else:
        return -1


def go_no_go_trial_converter(s: bytes) -> int:
    """
    Converter to translate :param s: containing a trial type into 1 or 0.
    :param s: Trial type. Trial type containing 'correct-go' or 'failed-go' indicates 'ngo' trials.
    Trial type containing 'correct-stop' or 'failed-stop' indicates 'no-go' trials.
    :return: 1 for go trials, 0 for no-go trials
    """
    if s.endswith(b'-go'):
        return 1
    elif s.endswith(b'-stop'):
        return 0
    else:
        return -1


def tsv_data_read_for_rescorla_wagner(file: Path) -> List[Tuple]:
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
    events = []
    for d, g in zip(duration, trial_type):
        if g == 0 or g == 1:
            events.append((d, g))
    return events


def tsv_data_read_go_no_go(file: Path) -> List[Tuple]:
    """
    Read behavioral data out of events.tsv files.
    Return a list of tuples of (duration, go trial success or failure)
    """
    converters = {2: go_no_go_trial_converter}

    _, duration, trial_type = np.loadtxt(str(file),
                                         delimiter='\t',
                                         skiprows=1,
                                         converters=converters,
                                         unpack=True)
    events = []
    # Set the event value to one if the trial is a go-trial type following a no-go-trial type,
    # and set the event value to zero if the trial is a go-trial type following a go-trial type
    for i, (d, g) in enumerate(zip(duration, trial_type)):
        event_value = g
        if i == 0:
            event_value = 0
        elif trial_type[i] == 1 and trial_type[i-1] == 0:
            event_value = 1
        events.append((d, event_value))
    return events


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


def main(input_dir: str):
    files = sorted(Path(input_dir).glob('*_task-SST_acq-1_events.tsv'))

    for f in files:
        events = tsv_data_read_for_rescorla_wagner(f)
        write_for_rescorla_wagner(f, events)
        events = tsv_data_read_go_no_go(f)
        write_for_rescorla_wagner(f, events, is_go=False)


if __name__ == "__main__":
    description = f'Create multi-condition files for modeling SST task in {STUDY_ID} study using a Rescorla-Wagner learning model'

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
