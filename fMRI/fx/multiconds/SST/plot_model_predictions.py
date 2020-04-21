import matplotlib.pyplot as plt
import numpy as np

# Plot model predictions from multilevel_model

size = 100
trial_number = np.arange(0, size)
correct_stop = np.ones_like(trial_number)
failed_go = np.ones_like(trial_number)
y_ref = 6.695e-01 - 1.711e-04 * trial_number
y_correct_stop = y_ref + 3.241e-01 * correct_stop + 2.330e-04 * trial_number * correct_stop
y_failed_go = y_ref + 4.395e-01 * failed_go - 1.683e-03 * trial_number * failed_go

# Multiply by 1000 to plot milliseconds, instead of seconds
y_ref *= 1000
y_correct_stop *= 1000
y_failed_go *= 1000

plt.style.use('ggplot')
fig, axs = plt.subplots(2, 1, figsize=(6, 12))
axs[0].plot(trial_number, y_ref, label='Reference condition')
axs[0].plot(trial_number, y_correct_stop, label='Correct stop')
axs[0].plot(trial_number, y_failed_go, label='Failed go')

axs[0].set_ylim(640, 1125)
axs[0].set_ylabel('Predicted RT (ms)')
axs[0].legend(title='Non-food')

# create plots for treatment condition, so add terms related to treatment or control condition
is_treatment = np.ones_like(trial_number)
y_ref = 6.695e-01 - 1.711e-04 * trial_number + 1.704e-02 * is_treatment + 2.367e-04 * trial_number * is_treatment
y_correct_stop = y_ref + 3.241e-01 * correct_stop + 2.330e-04 * trial_number * correct_stop - \
                 1.451e-02 * correct_stop * is_treatment - 2.603e-04 * trial_number * correct_stop * is_treatment
y_failed_go = y_ref + 4.395e-01 * failed_go - 1.683e-03 * trial_number * failed_go - \
              1.445e-02 * failed_go * is_treatment + 3.395e-05 * trial_number * failed_go * is_treatment

y_ref *= 1000
y_correct_stop *= 1000
y_failed_go *= 1000

axs[1].plot(trial_number, y_ref, label='Reference condition')
axs[1].plot(trial_number, y_correct_stop, label='Correct stop')
axs[1].plot(trial_number, y_failed_go, label='Failed go')

axs[1].set_ylim(640, 1125)
axs[1].set_xlabel('Trial number')
axs[1].set_ylabel('Predicted RT (ms)')
axs[1].legend(title='Food')

plt.show()

