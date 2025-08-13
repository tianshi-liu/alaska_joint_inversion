#!/bin/bash
### MODIFY EVERY ITERATION #
model=M07ani
############################
slurm_script=slurm_fwd_meas_adj_eq.sh
max_jobs=5
src_file=src_rec_eq/event_filtered_ctrlgrp1.lst
current_dir=`pwd`
cat /dev/null > job_ids
cat ${src_file} |
while read line; do
  src_code=`echo $line`
  date
  echo ${src_code}
  #rm -rf measure_adj_${model}/${src_code}
  #mkdir -p measure_adj_${model}/${src_code}
  # cp files to measure directory
  #cd measure_adj_${model}/${src_code}
  #for comp in Z R T; do
  #  for band in T025_T050 T018_T036 T012_T025; do
  #    cp measure_adj_3comp/MEASUREMENT.PAR.${comp}.${band} measure_adj_${model}/${src_code}
  #    cp src_rec/${src_code}/MEASUREMENT.WINDOWS.${comp}.${band} measure_adj_${model}/${src_code}
  #  done
  #done
  #cp src_rec/${src_code}/FORCESOLUTION_X measure_adj_${model}/${src_code}/FORCESOLUTION
  #cp src_rec/${src_code}/STATIONS_cartesian measure_adj_${model}/${src_code}/STATIONS
  #ln -sf ${current_dir}/data_sac/${src_code} measure_adj_${model}/${src_code}/DAT
  #cp ${current_dir}/measure_adj_3comp/get_window.py .
  #cp ${current_dir}/measure_adj_3comp/write_windows.sh .
  #cp ${current_dir}/src_rec_sub/cartesian/FORCESOLUTION_${src_code}_X FORCESOLUTION
  #cp ${current_dir}/src_rec_sub/cartesian/STATIONS_${src_code} STATIONS
  #ln -sf ${current_dir}/data_sac/${src_code} DAT
  #ln -sf ${current_dir}/dispersion/${src_code} dispersion
  ###############################
  #bash write_windows.sh
  #cd ../..
  # set up slurm script
  sed -i "/^#SBATCH --time=/c\#SBATCH --time=00:60:00" ${slurm_script}
  sed -i "/^NPROC=/c\NPROC=400" ${slurm_script}
  sed -i "/^model_dir=/c\model_dir=${model}.ls" ${slurm_script}
  sed -i "/^prev_model_dir=/c\prev_model_dir=${model}" ${slurm_script}
  sed -i "/^eid=/c\eid=${src_code}" ${slurm_script}
  sed -i "/^mesh_dir=/c\mesh_dir=model_${model}" ${slurm_script}
  #sed -i "/^band_code=/c\band_code=T025_T050,T018_T036,T012_T025" ${slurm_script}
  #sed -i "/^band_code=/c\band_code=T025_T050,T018_T036,T012_T025" ${slurm_script}
  sed -i "/^inherit_windows=/c\inherit_windows=true" ${slurm_script}
  sed -i "/^go_forward=/c\go_forward=true" ${slurm_script}
  sed -i "/^go_preprocess_measurement=/c\go_preprocess_measurement=true" ${slurm_script}
  sed -i "/^go_adjoint=/c\go_adjoint=false" ${slurm_script}
  sed -i "/^go_move_kernels=/c\go_move_kernels=false" ${slurm_script}
  sed -i "/^go_smooth_kernels=/c\go_smooth_kernels=false" ${slurm_script}
  sed -i "/^go_delete_solver=/c\go_delete_solver=true" ${slurm_script}
  sed -i "/^go_delete_measurement=/c\go_delete_measurement=true" ${slurm_script}
  
  njob=`cat job_ids | wc -l`
  # modify slurm script
  if (( njob < max_jobs )); then
    this_job_id=$(sbatch ${slurm_script})
    echo ${this_job_id} | awk '{print $4}' >> job_ids
  else    
    dependency_id=`tail -${max_jobs} job_ids | head -1`
    this_job_id=$(sbatch --dependency=afterok:${dependency_id} ${slurm_script})
    echo ${this_job_id} | awk '{print $4}' >> job_ids
  fi
  sleep 60
done
