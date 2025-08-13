import os
evt_dir = 'event_kernel_M07ani'
step_len_percent = 0.0123
c1 = 0.4
meas_lists_ctrlgrp = ['meas_list_noise.ctrlgrp', 'meas_list_eq.ctrlgrp']
chi_norm = 0.0
for fn_meas in meas_lists_ctrlgrp:
  f_src = open(os.path.join(evt_dir,fn_meas),'r')
  src_list = f_src.readlines()
  f_src.close()
  n_meas = 0
  chi = 0.0
  for meas_path in src_list:
    f_meas = open(os.path.join(meas_path.strip(),'sum_chi'),'r')
    meas = f_meas.readlines()
    f_meas.close()
    chi = chi + float(meas[0].strip())
    n_meas = n_meas + int(meas[1].strip())
  chi_norm += chi / n_meas
  print(f"Initially {n_meas} measurements in {fn_meas}")
print(f"Initial misfit: {chi_norm}")

meas_lists_ctrlgrp = ['meas_list_noise_ls.ctrlgrp', 'meas_list_eq_ls.ctrlgrp']
chi_norm_ls = 0.0
for fn_meas in meas_lists_ctrlgrp:
  f_src = open(os.path.join(evt_dir,fn_meas),'r')
  src_list = f_src.readlines()
  f_src.close()
  n_meas = 0
  chi = 0.0
  for meas_path in src_list:
    f_meas = open(os.path.join(meas_path.strip(),'sum_chi'),'r')
    meas = f_meas.readlines()
    f_meas.close()
    chi = chi + float(meas[0].strip())
    n_meas = n_meas + int(meas[1].strip())
  chi_norm_ls += chi / n_meas
  print(f"  {n_meas} measurements in {fn_meas}")
print(f"Line search with step length {step_len_percent}")
print(f"  misfit: {chi_norm_ls}")

f_val = open(os.path.join(evt_dir,'max_update_val'),'r')
values = f_val.readlines()
g_max = float(values[0].strip())
f_val = open(os.path.join(evt_dir,'line_search_derivative'),'r')
values = f_val.readlines()
p = float(values[0].strip())

slope_ls = p/g_max

if (chi_norm_ls <= chi_norm + c1 * slope_ls * step_len_percent):
  print(f"step length accepted")
elif (chi_norm_ls > chi_norm):
  print(f"misfit increased, step length should be halved")
  step_len_next = step_len_percent / 2.0
  print(f"try step length {step_len_next}")
else:
  print(f"misfit decreased, but not sufficiently decreased")
  step_len_next = - slope_ls * step_len_percent * step_len_percent / 2.0 / (chi_norm_ls - chi_norm - slope_ls * step_len_percent)
  print(f"try step length {step_len_next}")
