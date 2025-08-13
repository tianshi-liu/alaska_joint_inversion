#!/bin/bash
### MODIFY EVERY ITERATION #
model=M56
model_prev=M55
is_restart=false
############################
slurm_script=slurm_fwd_meas_adj_eq.sh
max_jobs=5
src_file=src_rec_eq/event_filtered.lst
current_dir=`pwd`
cat /dev/null > job_ids
cat ${src_file} |
while read src_code; do
  #src_code=`echo $line | awk '{printf "%s.%s", $2, $1}'`
  #sta_code=`echo $line | awk '{printf "%s", $1}'`
  date
  echo ${src_code}
  # set up slurm script
  sed -i "/^#SBATCH --time=/c\#SBATCH --time=00:60:00" ${slurm_script}
  sed -i "/^NPROC=/c\NPROC=400" ${slurm_script}
  sed -i "/^model_dir=/c\model_dir=${model}" ${slurm_script}
  sed -i "/^prev_model_dir=/c\prev_model_dir=${model_prev}" ${slurm_script}
  if ${is_restart}; then
    sed -i "/^inherit_windows=/c\inherit_windows=false" ${slurm_script}
  else
    ## use this during inversion
    if grep -q "^${sta_code}" src_rec_eq/event_filtered_ctrlgrp.lst; then
    ## use this during point-spreading test
    #if grep -q "^${sta_code}" src_rec_eq/event_filtered.lst; then
      sed -i "/^inherit_windows=/c\inherit_windows=true" ${slurm_script}
    else
      sed -i "/^inherit_windows=/c\inherit_windows=false" ${slurm_script}
    fi
  fi
  sed -i "/^eid=/c\eid=${src_code}" ${slurm_script}
  ### MODIFY EVERY ITERATION #
  sed -i "/^mesh_dir=/c\mesh_dir=model_${model_prev}" ${slurm_script}
  #sed -i "/^mesh_dir=/c\mesh_dir=specfem" ${slurm_script}
  ############################
  #sed -i "/^band_code=/c\band_code=T025_T050,T018_T036,T012_T025" ${slurm_script}
  #sed -i "/^band_code=/c\band_code=T025_T050,T018_T036,T012_T025" ${slurm_script}
  sed -i "/^go_forward=/c\go_forward=true" ${slurm_script}
  sed -i "/^go_preprocess_measurement=/c\go_preprocess_measurement=true" ${slurm_script}
  sed -i "/^go_adjoint=/c\go_adjoint=true" ${slurm_script}
  sed -i "/^go_move_kernels=/c\go_move_kernels=true" ${slurm_script}
  sed -i "/^go_smooth_kernels=/c\go_smooth_kernels=true" ${slurm_script}
  sed -i "/^go_delete_solver=/c\go_delete_solver=true" ${slurm_script}
  sed -i "/^go_delete_measurement=/c\go_delete_measurement=true" ${slurm_script}
  sed -i "/^is_pst=/c\is_pst=false" ${slurm_script}
  sed -i "/^save_seismograms=/c\save_seismograms=false" ${slurm_script}  
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
