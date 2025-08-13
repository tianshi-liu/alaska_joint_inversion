import matplotlib.pyplot as plt
import numpy as np
import os

e = 0.0000001

#source_fn = 'src_rec_noise/sources.dat'
source_fn = 'src_rec_eq/event_filtered.lst'

#band_list = [(12, 25), (18, 36), (25, 50)]
band_list = [(25, 50), (40, 80), (60, 120)]
for iband in range(len(band_list)):
  t1, t2 = band_list[iband]
  band = f'T{t1:>03}_T{t2:>03}'
#prefix = 'meas_noise'
#comps = ['Z','R','T']
  for comp in ['Z', 'R', 'T']:
    plt.figure(figsize=(12,12))
    plt.rc('xtick', labelsize=30)
    plt.rc('ytick', labelsize=30)

    model_new = 'M05ani'
    meas_list_new = []
    with open(source_fn, 'r') as f:
      lines = f.readlines()
    for line in lines:
      line_segs = [_ for _ in line.strip().split(' ') if _ != '']
      #source_name = line_segs[1] + '.' + line_segs[0]
      source_name = line_segs[0]
      fn = f"measure_adj_{model_new}/{source_name}/{comp}.{band}/window_chi"
      try:
        #A = np.loadtxt(fn,usecols=(1, 3, 5, 7))
        A = np.loadtxt(fn,usecols=(2, 4, 6, 8))
        ind = (A[:,0] > e)
        meas_list_new += A[ind, 2].tolist()
        ind = np.logical_and((A[:,0] <= e), (A[:,1] > e))
        meas_list_new += A[ind, 3].tolist()
      except:
        pass

    model = 'M01ani'
    meas_list = []
    with open(source_fn, 'r') as f:
      lines = f.readlines()
    for line in lines:
      line_segs = [_ for _ in line.strip().split(' ') if _ != '']
      #source_name = line_segs[1] + '.' + line_segs[0]
      source_name = line_segs[0]
      fn = f"measure_adj_{model}/{source_name}/{comp}.{band}/window_chi"
      try:
        #A = np.loadtxt(fn,usecols=(1, 3, 5, 7))
        A = np.loadtxt(fn,usecols=(2, 4, 6, 8))
        ind = (A[:,0] > e)
        meas_list += A[ind, 2].tolist()
        ind = np.logical_and((A[:,0] <= e), (A[:,1] > e))
        meas_list += A[ind, 3].tolist()
      except:
        pass
    mean = np.mean(meas_list)
    std = np.std(meas_list)
    mean_new = np.mean(meas_list_new)
    std_new = np.std(meas_list_new)
    plt.hist(meas_list_new, range=(-4.0*std,4.0*std), bins=13, color='g',label=model, density=True)
    plt.text(0.58, 0.99, f'{model_new}:{mean_new:.2f}'+r'$\pm$'+f'{std_new:.2f}s', fontsize=28,
         horizontalalignment='left',
         verticalalignment='top',
         transform = plt.gca().transAxes, color='g')
    plt.hist(meas_list, range=(-4.0*std,4.0*std), bins=13, histtype='step', edgecolor='r',linewidth=4.0, label=model, density=True)
    plt.text(0.58, 0.93, f'{model}:{mean:.2f}'+r'$\pm$'+f'{std:.2f}s', fontsize=28,
         horizontalalignment='left',
         verticalalignment='top',
         transform = plt.gca().transAxes, color='r')
    ax = plt.gca()
    ylim_bottom, ylim_top = ax.get_ylim()
    ax.set_ylim(ylim_bottom, ylim_top * 1.2)
    #plt.title(f"noise, {comp}-{comp}, {t1}-{t2}s", fontsize=30)
    plt.title(f"eq, {comp}, {t1}-{t2}s", fontsize=30)
    if (iband==2): plt.xlabel('time shift (s)', fontsize=30)
    if (comp=='Z'): plt.ylabel('normalized number of measurements', fontsize=30)
    #plt.savefig(os.path.join(f"{model_new}_log", f"histo_noise.{comp}.{band}.pdf"))
    plt.savefig(os.path.join(f"{model_new}_log", f"histo_eq.{comp}.{band}.pdf"))
    plt.clf()
