model=M06ani
log_dir=${model}_log
mkdir -p ${log_dir}
mv *.o ${log_dir}
python3 parse_line_search.py > ${log_dir}/info_ls
python3 parse_line_search_batch.py > ${log_dir}/info_ls_batch
cp src_rec_eq/event_filtered_ctrlgrp.lst ${log_dir}
cp src_rec_noise/sources_batch.dat ${log_dir}
cp src_rec_noise/sources_ctrlgrp.dat ${log_dir}

cp event_kernel_$model/slurm_postprocess.sh ${log_dir}
cp event_kernel_$model/slurm_update_model_by_perturbation.sh ${log_dir}
cp event_kernel_$model/lbfgs_paths ${log_dir}
cp event_kernel_$model/line_search_derivative ${log_dir}
cp event_kernel_$model/max_update_val ${log_dir}
