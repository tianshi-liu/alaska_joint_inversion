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
ln -sf ~/specfem3d_subsample/bin/xselect_control_group bin/
NPROC=`grep ^NPROC DATA/Par_file | grep -v -E '^[[:space:]]*#' | cut -d = -f 2`
mpirun -np $NPROC ./bin/xselect_control_group alpha_kernel_smooth,beta_kernel_smooth OUTPUT_SUM 5 22.5
