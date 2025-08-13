import matplotlib
matplotlib.use('TkAgg')
import os
import matplotlib.pyplot as plt
plt.figure(figsize=(15,15))
plt.rc('xtick', labelsize=35)
plt.rc('ytick', labelsize=35)
#plt.yscale('log')
iter_start = 1
iter_end = 5
misfit = []
for it in range(iter_start, iter_end + 1):
  evt_dir = f'event_kernel_M{it:02}ani'
  meas_lists_ctrlgrp = ['meas_list_noise', 'meas_list_eq']
  chi_mean = 0
  for fn_meas in meas_lists_ctrlgrp:
    n_meas = 0
    chi = 0.0
    f_src = open(os.path.join(evt_dir,fn_meas),'r')
    src_list = f_src.readlines()
    f_src.close()
    for meas_path in src_list:
      f_meas = open(os.path.join(meas_path.strip(),'sum_chi'),'r')
      meas = f_meas.readlines()
      f_meas.close()
      chi = chi + float(meas[0].strip())
      n_meas = n_meas + int(meas[1].strip())
    chi_mean += chi / n_meas
  misfit.append(chi_mean)
plt.plot(range(iter_start, iter_end + 1), misfit, 'ro-', label='total')

misfit = []
for it in range(iter_start, iter_end + 1):
  evt_dir = f'event_kernel_M{it:02}ani'
  meas_lists_ctrlgrp = ['meas_list_noise']
  chi_mean = 0
  for fn_meas in meas_lists_ctrlgrp:
    n_meas = 0
    chi = 0.0
    f_src = open(os.path.join(evt_dir,fn_meas),'r')
    src_list = f_src.readlines()
    f_src.close()
    for meas_path in src_list:
      f_meas = open(os.path.join(meas_path.strip(),'sum_chi'),'r')
      meas = f_meas.readlines()
      f_meas.close()
      chi = chi + float(meas[0].strip())
      n_meas = n_meas + int(meas[1].strip())
    chi_mean += chi / n_meas
  misfit.append(chi_mean)
plt.plot(range(iter_start, iter_end + 1), misfit, 'bo-', label='noise')

misfit = []
for it in range(iter_start, iter_end + 1):
  evt_dir = f'event_kernel_M{it:02}ani'
  meas_lists_ctrlgrp = ['meas_list_eq']
  chi_mean = 0
  for fn_meas in meas_lists_ctrlgrp:
    n_meas = 0
    chi = 0.0
    f_src = open(os.path.join(evt_dir,fn_meas),'r')
    src_list = f_src.readlines()
    f_src.close()
    for meas_path in src_list:
      f_meas = open(os.path.join(meas_path.strip(),'sum_chi'),'r')
      meas = f_meas.readlines()
      f_meas.close()
      chi = chi + float(meas[0].strip())
      n_meas = n_meas + int(meas[1].strip())
    chi_mean += chi / n_meas
  misfit.append(chi_mean)
plt.plot(range(iter_start, iter_end + 1), misfit, 'yo-', label='earthquake')
plt.legend()
plt.legend(prop={'size':28}, loc=1)
plt.xlabel('number of iteration', fontsize=35)
plt.ylabel(r'misfit $\Phi (s^2)$', fontsize=35)
plt.ylim([0.05, 0.3])
plt.xlim([0, 6])
plt.gca().set_xticks([1,2,3,4,5])
plt.gca().set_yticks([0.05, 0.1, 0.15, 0.2, 0.25])
plt.gca().get_yaxis().set_major_formatter(matplotlib.ticker.ScalarFormatter())
plt.text(-0.9, 0.3, '(a)', fontsize=43, horizontalalignment='left', verticalalignment='bottom')
#plt.show()
plt.savefig("misfit_ani.pdf", transparent=True, bbox_inches='tight', pad_inches=0.5)
