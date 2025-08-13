#!/usr/bin/bash

## job name and output file
#SBATCH --job-name combine_kernels
#SBATCH --output %j.o

###########################################################
# USER PARAMETERS

## 40 CPUs ( 10*4 ), walltime 5 hour
#SBATCH --nodes=10
#SBATCH --ntasks=400
#SBATCH --time=0:15:00

###########################################################

cd $SLURM_SUBMIT_DIR
module load intel openmpi
model=M01
main_dir=/scratch/l/liuqy/liutia97/alaska_joint_inversion
restart_lbfgs=true
SIGMA_H=80000.0
SIGMA_V=40000.0
NPROC=`grep ^NPROC DATA/Par_file | grep -v -E '^[[:space:]]*#' | cut -d = -f 2`
echo "Selecting control group:"
echo
ln -sf ~/specfem3d_pml_1order/bin/xselect_control_group_joint bin/
mpirun -np $NPROC ./bin/xselect_control_group_joint alpha_kernel_smooth,,beta_kernel_smooth dir_list_noise,dir_list_eq meas_list_noise,meas_list_eq OUTPUT_SUM 5 15
#cat /dev/null > meas_list
#cat dir_list | 
#while read dir; do
#  src_code=`echo $dir | awk -F/ '{print $(NF-1)}'`
#  echo ${main_dir}/measure_adj_$model/${src_code} >> meas_list
#done
echo
echo "Preparing list files on control group:"
echo
cat /dev/null > meas_list_eq.ctrlgrp
cat /dev/null > meas_list_eq_ls.ctrlgrp
cat /dev/null > event_filtered_ctrlgrp.lst
cat dir_list_eq.ctrlgrp |
while read dir; do
  src_code=`echo $dir | awk -F/ '{print $(NF-1)}'`
  echo ${main_dir}/measure_adj_${model}/${src_code} >> meas_list_eq.ctrlgrp
  echo ${main_dir}/measure_adj_${model}.ls/${src_code} >> meas_list_eq_ls.ctrlgrp
  #sta=`echo ${src_code} | awk -F. '{print $2}'`
  #grep $sta ${main_dir}/src_rec/sources.dat >> sources_ctrlgrp.dat
  grep ${src_code} ${main_dir}/src_rec_eq/event_filtered.lst >> event_filtered_ctrlgrp.lst
done
cp event_filtered_ctrlgrp.lst ${main_dir}/src_rec_eq
cat /dev/null > meas_list_noise.ctrlgrp
cat /dev/null > meas_list_noise_ls.ctrlgrp
cat /dev/null > sources_ctrlgrp.dat
cat dir_list_noise.ctrlgrp |
while read dir; do
  src_code=`echo $dir | awk -F/ '{print $(NF-1)}'`
  echo ${main_dir}/measure_adj_${model}/${src_code} >> meas_list_noise.ctrlgrp
  echo ${main_dir}/measure_adj_${model}.ls/${src_code} >> meas_list_noise_ls.ctrlgrp
  sta=`echo ${src_code} | awk -F. '{print $2}'`
  grep $sta ${main_dir}/src_rec_noise/sources.dat >> sources_ctrlgrp.dat
  #grep ${src_code} ${main_dir}/src_rec/event_filtered.lst >> event_filtered_ctrlgrp.lst
done
cp sources_ctrlgrp.dat ${main_dir}/src_rec_noise
#echo
#echo "Dividing kernels by number of measurements:"
#echo
#ln -sf ~/specfem3d_pml_1order/bin/xdiv_kernel_by_nmeas bin/
#mpirun -np $NPROC ./bin/xdiv_kernel_by_nmeas vbulk_kernel_smooth,betav_kernel_smooth,betah_kernel_smooth meas_list OUTPUT_SUM
#mpirun -np $NPROC ./bin/xdiv_kernel_by_nmeas vbulk_kernel_smooth_ctrlgrp,betav_kernel_smooth_ctrlgrp,betah_kernel_smooth_ctrlgrp meas_list.ctrlgrp OUTPUT_SUM
if ${restart_lbfgs}; then
  echo "L-BFGS restarted"
else
  echo
  echo "Summing kernels on previous control group:"
  echo
  ln -sf ~/specfem3d_pml_1order/bin/xcombine_sem_joint bin/
  mpirun -np $NPROC ./bin/xcombine_sem_joint alpha_kernel_smooth,beta_kernel_smooth dir_list_noise.ctrlgrp_prev,dir_list_eq.ctrlgrp_prev meas_list_noise.ctrlgrp_prev,meas_list_eq.ctrlgrp_prev OUTPUT_SUM_PREV
  rename _smooth.bin _smooth_ctrlgrp.bin OUTPUT_SUM_PREV/*_smooth.bin
  #echo
  #echo "Dividing kernels by number of measurements:"
  #echo
  #mpirun -np $NPROC ./bin/xdiv_kernel_by_nmeas vbulk_kernel_smooth_ctrlgrp,betav_kernel_smooth_ctrlgrp,betah_kernel_smooth_ctrlgrp meas_list.ctrlgrp_prev OUTPUT_SUM_PREV
fi
echo 
echo "Computing L-BFGS direction:"
echo
ln -sf ~/specfem3d_pml_1order/bin/xwrite_lbfgs_direction_smooth bin/
mpirun -np $NPROC ./bin/xwrite_lbfgs_direction_smooth alpha_kernel_smooth,beta_kernel_smooth alpha_kernel_smooth_ctrlgrp,beta_kernel_smooth_ctrlgrp, dalpha,dbeta dalpha,dbeta OUTPUT_SUM lbfgs_paths
echo
echo "Smoothing L-BFGS update direction:"
echo
ln -sf ~/specfem3d_pml_1order/bin/xsmooth_sem_sph_pde bin/
#mpirun -np $NPROC ./bin/xsmooth_sem_sph_pde ${SIGMA_H} ${SIGMA_V} dbulk OUTPUT_SUM OUTPUT_SUM FALSE
mpirun -np $NPROC ./bin/xsmooth_sem_sph_pde ${SIGMA_H} ${SIGMA_V} dalpha OUTPUT_SUM OUTPUT_SUM FALSE
mpirun -np $NPROC ./bin/xsmooth_sem_sph_pde ${SIGMA_H} ${SIGMA_V} dbeta OUTPUT_SUM OUTPUT_SUM FALSE
#mpirun -np $NPROC ./bin/xsmooth_sem_sph_pde 21213.26 7071.086 dGc_nondim OUTPUT_SUM OUTPUT_SUM FALSE
#mpirun -np $NPROC ./bin/xsmooth_sem_sph_pde 21213.26 7071.086 dGs_nondim OUTPUT_SUM OUTPUT_SUM FALSE
echo 
echo 
echo 
echo "getting maximum absolute value for smoothed L-BFGS update direction:"
echo
ln -sf ~/specfem3d_pml_1order/bin/xget_max_absolute_value bin/
mpirun -np $NPROC ./bin/xget_max_absolute_value OUTPUT_SUM dalphav_smooth,dalphah_smooth,dbetav_smooth,dbetah_smooth max_update_val
