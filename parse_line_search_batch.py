import os
evt_dir = 'event_kernel_M07ani'
meas_lists_ctrlgrp = ['meas_list_noise', 'meas_list_eq']
#meas_lists_ctrlgrp = ['meas_list_noise', 'meas_list_eq']
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
  print(f"{n_meas} measurements in {fn_meas}")
  
#f_val = open(os.path.join(evt_dir,'max_update_val'),'r')
#values = f_val.readlines()
#g_max = float(values[0].strip())
#f_val = open(os.path.join(evt_dir,'line_search_derivative'),'r')
#values = f_val.readlines()
#p = float(values[0].strip())
print(f"Initial misfit: {chi_mean}")
#print(f"Slope of line search function: {p/g_max}")
#print(f"Maximum perturbation with step length 1: {g_max}")
