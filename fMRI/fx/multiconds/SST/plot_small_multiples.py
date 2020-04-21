import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path
import re

# input_dir is the location of the BIDS-formatted events files
input_dir = ''
files = sorted(Path(input_dir).glob(f'*_go.tsv'))

nrows = 13
ncols = 12
plt.style.use('ggplot')
fig, _axs = plt.subplots(nrows=nrows, ncols=ncols)
axs = _axs.flatten()

for i, f in enumerate(files):
    pattern = '(CC\\d{3})'
    match = re.search(pattern, str(f.name))
    if match:
        subject_id, = match.groups()

        y, _ = np.loadtxt(str(f),
                          delimiter='\t',
                          unpack=True)

        x = list(range(0, len(y)))

        axs[i].plot(x, y)
        axs[i].set_xlim(0, 50)
        axs[i].set_ylim(0, 1.0)
        axs[i].set_title(subject_id, fontsize=8, pad=1.0)
        axs[i].tick_params(labelbottom=False, labeltop=False, labelleft=False, labelright=False)
        if axs[i].is_last_row():
            axs[i].tick_params(labelbottom=True, labelsize=8)
        if axs[i].is_first_col():
            axs[i].tick_params(labelleft=True, labelsize=8)

for j in range(len(files), 12 * 13):
    axs[j].set_visible(False)
plt.show()
