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
model=ckbd_90
model_last=M56
main_dir=/scratch/l/liuqy/liutia97/alaska_joint_inversion
NPROC=`grep ^NPROC DATA/Par_file | grep -v -E '^[[:space:]]*#' | cut -d = -f 2`
ln -sf ~/specfem3d_pml_1order/bin/xcombine_sem_joint bin/
ln -sf ~/specfem3d_pml_1order/bin/xsubtract_kernel_normalize bin/

mkdir -p OUTPUT_SUM_${model}_joint
mkdir -p OUTPUT_SUM_${model_last}_joint
mkdir -p OUTPUT_SUM_joint
mpirun -np $NPROC ./bin/xcombine_sem_joint beta_kernel_smooth dir_list_noise,dir_list_eq meas_list_noise,meas_list_eq OUTPUT_SUM_${model}_joint
mpirun -np $NPROC ./bin/xcombine_sem_joint beta_kernel_smooth ${main_dir}/event_kernel_${model_last}/dir_list_noise,${main_dir}/event_kernel_${model_last}/dir_list_eq ${main_dir}/event_kernel_${model_last}/meas_list_noise,${main_dir}/event_kernel_${model_last}/meas_list_eq OUTPUT_SUM_${model_last}_joint
mpirun -np $NPROC ./bin/xsubtract_kernel_normalize OUTPUT_SUM_${model}_joint OUTPUT_SUM_${model_last}_joint beta_kernel_smooth OUTPUT_SUM_joint


mkdir -p OUTPUT_SUM_${model}_noise
mkdir -p OUTPUT_SUM_${model_last}_noise
mkdir -p OUTPUT_SUM_noise
mpirun -np $NPROC ./bin/xcombine_sem_joint beta_kernel_smooth dir_list_noise meas_list_noise OUTPUT_SUM_${model}_noise
mpirun -np $NPROC ./bin/xcombine_sem_joint beta_kernel_smooth ${main_dir}/event_kernel_${model_last}/dir_list_noise ${main_dir}/event_kernel_${model_last}/meas_list_noise OUTPUT_SUM_${model_last}_noise
mpirun -np $NPROC ./bin/xsubtract_kernel_normalize OUTPUT_SUM_${model}_noise OUTPUT_SUM_${model_last}_noise beta_kernel_smooth OUTPUT_SUM_noise

mkdir -p OUTPUT_SUM_${model}_eq
mkdir -p OUTPUT_SUM_${model_last}_eq
mkdir -p OUTPUT_SUM_eq
mpirun -np $NPROC ./bin/xcombine_sem_joint beta_kernel_smooth dir_list_eq meas_list_eq OUTPUT_SUM_${model}_eq
mpirun -np $NPROC ./bin/xcombine_sem_joint beta_kernel_smooth ${main_dir}/event_kernel_${model_last}/dir_list_eq ${main_dir}/event_kernel_${model_last}/meas_list_eq OUTPUT_SUM_${model_last}_eq
mpirun -np $NPROC ./bin/xsubtract_kernel_normalize OUTPUT_SUM_${model}_eq OUTPUT_SUM_${model_last}_eq beta_kernel_smooth OUTPUT_SUM_eq
