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
NPROC=`grep ^NPROC DATA/Par_file | grep -v -E '^[[:space:]]*#' | cut -d = -f 2`
mpirun -np $NPROC ./bin/xdiv_kernel_by_nmeas alpha_kernel_smooth,beta_kernel_smooth meas_list OUTPUT_SUM
mpirun -np $NPROC ./bin/xdiv_kernel_by_nmeas alpha_kernel_smooth_ctrlgrp,beta_kernel_smooth_ctrlgrp meas_list.ctrlgrp OUTPUT_SUM
