import matplotlib.pyplot as plt
import numpy as np
import os

e = 0.0000001

plt.figure(figsize=(12,12))
plt.rc('xtick', labelsize=30)
plt.rc('ytick', labelsize=30)

band = 'T025_T050'
#prefix = 'meas_noise'
source_fn = 'src_rec_noise/sources.dat'
#source_fn = 'src_rec_eq/event_filtered.lst'
model = 'M56'
chi_list = []
with open(source_fn, 'r') as f:
  lines = f.readlines()
for line in lines:
  line_segs = [_ for _ in line.strip().split(' ') if _ != '']
  source_name = line_segs[1] + '.' + line_segs[0]
  #source_name = line_segs[0]
  for comp in ['R', 'T', 'Z']:
    fn = f"measure_adj_{model}/{source_name}/{comp}.{band}/window_chi"
    try:
      A = np.loadtxt(fn,usecols=(1, 3))
      #A = np.loadtxt(fn,usecols=(2, 4))
      ind = (A[:,0] > e)
      chi_list += A[ind, 0].tolist()
      ind = np.logical_and((A[:,0] <= e), (A[:,1] > e))
      chi_list += A[ind, 1].tolist()
    except:
      pass

plt.hist(chi_list, range=(0.0,20.5), bins=40, color='r', linewidth=4.0, label=model ,density=True)
mean = np.mean(chi_list)
var = np.var(chi_list)
print(f"mean={mean}, var={var}")
plt.show()
