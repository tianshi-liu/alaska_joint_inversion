#!/bin/bash
main_dir=`pwd`
model=M56
model_prev=M55
model_dir=model_M55
#model_dir_prev=model_M00
restart_lbfgs=false
step_len_prev=0.0215
max_paths_lbfgs=5
event_kernel_dir=event_kernel_${model}
event_kernel_dir_prev=event_kernel_${model_prev}
mkdir -p ${event_kernel_dir}/bin
ln -sf ${main_dir}/specfem/DATA ${event_kernel_dir}/DATA
ln -sf ${main_dir}/specfem/DATABASES_MPI ${event_kernel_dir}/DATABASES_MPI
mkdir -p ${event_kernel_dir}/OUTPUT_FILES/
cp ${main_dir}/specfem/OUTPUT_FILES/*.h ${event_kernel_dir}/OUTPUT_FILES
# set up dir_list meas_list file
cat /dev/null > ${event_kernel_dir}/dir_list_noise
cat /dev/null > ${event_kernel_dir}/meas_list_noise
cat /dev/null > ${event_kernel_dir}/dir_list_eq
cat /dev/null > ${event_kernel_dir}/meas_list_eq
#cat src_rec/sources_batch.dat | while read line; do
cat src_rec_eq/event_filtered.lst | while read line; do
  #src_code=`echo $line | awk '{printf "%s.%s", $2, $1}'`
  src_code=`echo $line`
  echo ${main_dir}/${event_kernel_dir}/${src_code}/OUTPUT_SUM >> ${event_kernel_dir}/dir_list_eq
  echo ${main_dir}/measure_adj_$model/${src_code} >> ${event_kernel_dir}/meas_list_eq
done
cat src_rec_noise/sources_batch.dat | while read line; do
#cat src_rec/event_filtered.lst | while read line; do
  src_code=`echo $line | awk '{printf "%s.%s", $2, $1}'`
  #src_code=`echo $line`
  echo ${main_dir}/${event_kernel_dir}/${src_code}/OUTPUT_SUM >> ${event_kernel_dir}/dir_list_noise
  echo ${main_dir}/measure_adj_$model/${src_code} >> ${event_kernel_dir}/meas_list_noise
done
mkdir -p ${event_kernel_dir}/OUTPUT_SUM
if ${restart_lbfgs}; then
  cat /dev/null > ${event_kernel_dir}/lbfgs_paths
  echo OUTPUT_SUM >> ${event_kernel_dir}/lbfgs_paths
  echo 0 >> ${event_kernel_dir}/lbfgs_paths
else
  cat /dev/null > ${event_kernel_dir}/dir_list_noise.ctrlgrp_prev
  cat /dev/null > ${event_kernel_dir}/meas_list_noise.ctrlgrp_prev
  cat /dev/null > ${event_kernel_dir}/dir_list_eq.ctrlgrp_prev
  cat /dev/null > ${event_kernel_dir}/meas_list_eq.ctrlgrp_prev
  cat ${event_kernel_dir_prev}/dir_list_eq.ctrlgrp | while read dir; do
    src_code=`echo $dir | awk -F/ '{print $(NF-1)}'`
    echo ${main_dir}/${event_kernel_dir}/${src_code}/OUTPUT_SUM >> ${event_kernel_dir}/dir_list_eq.ctrlgrp_prev
    echo ${main_dir}/measure_adj_$model/${src_code} >> ${event_kernel_dir}/meas_list_eq.ctrlgrp_prev
  done
  cat ${event_kernel_dir_prev}/dir_list_noise.ctrlgrp | while read dir; do
    src_code=`echo $dir | awk -F/ '{print $(NF-1)}'`
    echo ${main_dir}/${event_kernel_dir}/${src_code}/OUTPUT_SUM >> ${event_kernel_dir}/dir_list_noise.ctrlgrp_prev
    echo ${main_dir}/measure_adj_$model/${src_code} >> ${event_kernel_dir}/meas_list_noise.ctrlgrp_prev
  done
  mkdir -p ${event_kernel_dir}/OUTPUT_SUM_PREV
  cat /dev/null > ${event_kernel_dir}/lbfgs_paths
  echo OUTPUT_SUM >> ${event_kernel_dir}/lbfgs_paths
  n_paths=`head -n 2 ${event_kernel_dir_prev}/lbfgs_paths | tail -n 1`
  if (( n_paths == max_paths_lbfgs )); then # max number reached
    echo ${max_paths_lbfgs} >> ${event_kernel_dir}/lbfgs_paths
    n_line=$(( n_paths * 4 - 4))
  else
    echo $(( n_paths+1 )) >> ${event_kernel_dir}/lbfgs_paths
    n_line=$(( n_paths * 4 ))
  fi
  tail -n $n_line ${event_kernel_dir_prev}/lbfgs_paths >> ${event_kernel_dir}/lbfgs_paths
  echo ${main_dir}/${event_kernel_dir_prev}/OUTPUT_SUM >> ${event_kernel_dir}/lbfgs_paths
  echo ${main_dir}/${event_kernel_dir}/OUTPUT_SUM_PREV >> ${event_kernel_dir}/lbfgs_paths
  #echo ${main_dir}/${model_dir_prev}/DATABASES_MPI >> ${event_kernel_dir}/lbfgs_paths
  echo ${main_dir}/${event_kernel_dir_prev}/OUTPUT_SUM >> ${event_kernel_dir}/lbfgs_paths
  #echo ${main_dir}/${model_dir}/DATABASES_MPI >> ${event_kernel_dir}/lbfgs_paths
  max_val=`head -n 1 ${event_kernel_dir_prev}/max_update_val`
  echo "${step_len_prev} ${max_val}" | awk '{a = $1 / $2; print a}' >> ${event_kernel_dir}/lbfgs_paths
fi
cp event_kernel_postprocess/slurm_postprocess.sh ${event_kernel_dir}
sed -i "/^model=/c\model=${model}" ${event_kernel_dir}/slurm_postprocess.sh
sed -i "/^restart_lbfgs=/c\restart_lbfgs=${restart_lbfgs}" ${event_kernel_dir}/slurm_postprocess.sh
sed -i "/^SIGMA_H=/c\SIGMA_H=30000.0" ${event_kernel_dir}/slurm_postprocess.sh
sed -i "/^SIGMA_V=/c\SIGMA_V=10000.0" ${event_kernel_dir}/slurm_postprocess.sh
cp event_kernel_postprocess/slurm_update_model_by_perturbation.sh ${event_kernel_dir}
sed -i "/^old_model_dir=/c\old_model_dir=${main_dir}/${model_dir}/DATABASES_MPI" ${event_kernel_dir}/slurm_update_model_by_perturbation.sh
sed -i "/^model=/c\model=${model}" ${event_kernel_dir}/slurm_update_model_by_perturbation.sh
sed -i "/^main_dir=/c\main_dir=${main_dir}" ${event_kernel_dir}/slurm_update_model_by_perturbation.sh
