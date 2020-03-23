import argparse
import json
import re
from os import PathLike
from pathlib import Path
from typing import Union, List, Tuple

import numpy as np
import scipy.io

GO_TRIAL = 1
NO_GO_TRIAL = 0

STUDY_ID = 'CC'


def image_name_converter(s: bytes) -> int:
    """
    Converter to translate :param s: containing an image name into 1 or 0.
    :param s: Image name. Image names that start with 'healthy', 'p3healthy', or 'bird' indicate 'go' trials.
    Image names that start with 'unhealthy', 'p2unhealthy', or 'flower', indicate 'no-go' trials.
    :return: 1 for go trials, 0 for no-go trials
    """
    if s.startswith(b'healthy') or s.startswith(b'p3healthy') or s.startswith(b'bird'):
        return 1
    else:
        return 0


def csv_data_read(file: Path) -> Tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    """
    Read behavioral data out of .csv files. The data is interpreted as follows:

    column 7 - trial number
    column 9 - start time of trial (milliseconds)
    column 10 - trial duration (milliseconds)
    column 13 - reaction time (milliseconds)
    column 23 - trial type. 0=NoGo, 1=Go
    """
    trial_number, start_time, duration, reaction_time, is_go_trial = np.loadtxt(str(file),
                                                                                delimiter=',',
                                                                                skiprows=1,
                                                                                usecols=(7, 9, 10, 13, 23),
                                                                                converters={23: image_name_converter},
                                                                                unpack=True)

    # Divide reaction time, duration, start time by 1000 to convert from millisecond to second.
    return trial_number, is_go_trial, reaction_time / 1000.0, duration / 1000.0, start_time / 1000.0


def create_masks(condition: np.ndarray, response: np.ndarray) -> List:
    """Create masks of conditions"""
    go_correct = np.logical_and(condition == GO_TRIAL, response > 0.0)
    go_incorrect = np.logical_and(condition == GO_TRIAL, response == 0.0)
    no_go_correct = np.logical_and(condition == NO_GO_TRIAL, response == 0.0)
    no_go_incorrect = np.logical_and(condition == NO_GO_TRIAL, response > 0.0)

    return list((go_correct, no_go_correct, no_go_incorrect, go_incorrect))


def create_trials(trial_number: np.ndarray, trial_start_time: np.ndarray, trial_duration: np.ndarray):
    # Output names (trial number or condition name (GoFail, GoSuccess, NoGoFail, NoGoSuccess)),
    # onsets (when the thing started),
    # durations (how long the thing lasted)
    names = np.asarray(trial_number, dtype=np.object)
    onsets = np.asarray(trial_start_time, dtype=np.object)
    durations = np.asarray(trial_duration, dtype=np.object)

    trials = {'names': names,
              'onsets': onsets,
              'durations': durations}
    return trials


def create_conditions(start_time: np.ndarray, duration: np.ndarray, masks: List):
    names = np.asarray(['CorrectGo', 'CorrectStop', 'FailedStop', 'Cue', 'FailedGo'], dtype=np.object)
    onsets = np.zeros((len(masks),), dtype=np.object)
    durations = np.zeros((len(masks),), dtype=np.object)
    # onsets and durations have to be reshaped from 1-d np arrays to Nx1 arrays so when written
    # by scipy.io.savemat, the correct cell array is created in matlab
    for i, mask in enumerate(masks):
        onsets[i] = start_time[mask].reshape(np.count_nonzero(mask), 1)
        durations[i] = duration[mask].reshape(np.count_nonzero(mask), 1)

    conditions = {'names': names,
                  'onsets': onsets,
                  'durations': durations}
    return conditions


def write_betaseries(input_dir: Union[PathLike, str], subject_id: str, wave: str, trials):
    path = Path(input_dir) / 'betaseries'
    path.mkdir(parents=True, exist_ok=True)
    file_name = f'{STUDY_ID}{subject_id}_{wave}_SST1.mat'

    scipy.io.savemat(str(path / file_name), trials)


def write_conditions(input_dir: Union[PathLike, str], subject_id: str, wave: str, trials):
    path = Path(input_dir) / 'conditions'
    path.mkdir(parents=True, exist_ok=True)
    file_name = f'{STUDY_ID}{subject_id}_{wave}_SST1.mat'

    scipy.io.savemat(str(path / file_name), trials)


def write_bids_events(input_dir: Union[PathLike, str], subject_id: str, wave: str, trials):
    # Write the events.tsv to BIDS only if the BIDS structure already exists
    subject_path = Path(input_dir) / f'sub-{STUDY_ID}{subject_id}'
    if subject_path.exists():
        path = Path(input_dir) / f'sub-{STUDY_ID}{subject_id}' / f'ses-wave{wave}'
        if wave == '1' or wave == '2':
            path = path / 'func'
        else:
            path = path / 'beh'

        path.mkdir(parents=True, exist_ok=True)
        file_name = Path(f'sub-{STUDY_ID}{subject_id}_ses-wave{wave}_task-SST_acq-1_events.tsv')

        np.savetxt(str(path / file_name),
                   trials,
                   delimiter='\t',
                   header='onset\tduration\ttrial_type',
                   comments='',
                   fmt=['%10.5f', '%10.5f', '%s'])

        file_name = Path(f'sub-{STUDY_ID}{subject_id}_ses-wave{wave}_task-SST_acq-1_events.json')
        write_events_description(path, file_name)


def write_text_events(input_dir: Union[PathLike, str], subject_id: str, wave: str, trials):
    path = Path(input_dir)
    file_name = Path(f'sub-{STUDY_ID}{subject_id}_ses-wave{wave}_task-SST_acq-1_events.tsv')

    np.savetxt(str(path / file_name),
               trials,
               delimiter='\t',
               header='onset\tduration\ttrial_type',
               comments='',
               fmt=['%10.5f', '%10.5f', '%s'])


def write_events_description(path: Path,
                             file_name: Path):
    desc = {
        "onset": {
            "LongName": "Onset",
            "Description": "Onset of the event measured from the beginning of the acquisition of "
                           "the first volume in the corresponding task imaging data file.",
            "Units": "s"
        },
        "duration": {
            "LongName": "Duration",
            "Description": "Duration of the event, measured from onset.",
            "Units": "s"
        },
        "trial_type": {
            "LongName": "Categorization of a response inhibition task",
            "Description": "Education level, self-rated by participant",
            "Levels": {
                "correct-go": "Go trial, correct response",
                "failed-go": "Go trial, incorrect or no response",
                "correct-stop": "No-go or stop trial, correct response",
                "failed-stop": "No-go or stop trial, incorrect response",
                "null": "Null trial where cue stimulus is presented for duration"
            }
        }
    }
    with open(str(path / file_name), 'w') as f:
        json.dump(desc, f, indent=4)


def main(input_dir: str, bids_dir: str = None):
    files = sorted(Path(input_dir).glob(f'{STUDY_ID}*stopsignal_fMRI_clean.csv'))
    pattern = f'{STUDY_ID}' + '(\\d{3})_stopsignal_fMRI_clean.csv'
    for f in files:
        match = re.search(pattern, str(f.name))
        if match:
            subject_id, = match.groups()
            wave_number = '1'

            # Read data out of .csv file
            trial_number, is_go_trial, reaction_time, trial_duration, trial_start_time = csv_data_read(f)

            # Create masks for the various conditions
            masks = create_masks(is_go_trial, reaction_time)

            trial_type = np.empty_like(trial_number, dtype=np.object)
            trial_type_names = ['correct-go', 'correct-stop', 'failed-stop', 'failed-go', 'null']
            for mask, name in zip(masks, trial_type_names):
                np.putmask(trial_type, mask, name)

            if bids_dir:
                write_bids_events(bids_dir, subject_id, wave_number,
                                  np.stack((trial_start_time, trial_duration, trial_type), axis=1))
            else:
                trials = create_trials(trial_number, trial_start_time, trial_duration)

                # Create paths and file names
                write_betaseries(input_dir, subject_id, wave_number, trials)

                conditions = create_conditions(trial_start_time, trial_duration, masks)
                write_conditions(input_dir, subject_id, wave_number, conditions)

                write_text_events(input_dir, subject_id, wave_number,
                                  np.stack((trial_start_time, trial_duration, trial_type), axis=1))


if __name__ == "__main__":
    description = f'Create multi-condition files for SST task in {STUDY_ID} study'

    parser = argparse.ArgumentParser(description=description,
                                     add_help=True,
                                     formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument('-i', '--input', metavar='Input directory', action='store',
                        type=str, required=True,
                        help='absolute path to directory containing behavioral output from the SST task.',
                        dest='input_dir'
                        )
    parser.add_argument('-b', '--bids', metavar='BIDS directory', action='store',
                        type=str, required=False, default=None,
                        help='absolute path to your top level bids folder.',
                        dest='bids_dir'
                        )
    args = parser.parse_args()

    main(args.input_dir, args.bids_dir)
