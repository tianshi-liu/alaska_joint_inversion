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
model=M01
#model_prev=M01
main_dir=/scratch/l/liuqy/liutia97/alaska_joint_inversion
old_model_dir=/scratch/l/liuqy/liutia97/alaska_joint_inversion/specfem/DATABASES_MPI
new_model_dir=${main_dir}/model_${model}/DATABASES_MPI
cd $SLURM_SUBMIT_DIR
module load intel openmpi
mkdir -p ${new_model_dir}
cp ${old_model_dir}/*.bin ${new_model_dir}
ln -sf ~/specfem3d_pml_1order/bin/xscale_rho_with_vs bin/
ln -sf ~/specfem3d_pml_1order/bin/xupdate_model_by_perturbation bin/
NPROC=`grep ^NPROC DATA/Par_file | grep -v -E '^[[:space:]]*#' | cut -d = -f 2`
#mkdir -p OUTPUT_FILES/
#cp ${main_dir}/specfem/OUTPUT_FILES/*.h OUTPUT_FILES
mpirun -np $NPROC ./bin/xscale_rho_with_vs ${old_model_dir} vs vs OUTPUT_SUM dbeta_smooth dbeta_smooth drho_smooth

mpirun -np $NPROC ./bin/xupdate_model_by_perturbation dalpha_smooth,dbeta_smooth,drho_smooth vp,vs,rho TRUE,TRUE,TRUE ${old_model_dir} ${new_model_dir} OUTPUT_SUM 0.03

cd ${main_dir}/model_$model
ln -sf ${main_dir}/specfem/DATA .
mkdir -p bin OUTPUT_FILES
ln -sf ~/specfem3d_pml_1order/bin/xgenerate_databases bin/
cp ${main_dir}/specfem/OUTPUT_FILES/*.h OUTPUT_FILES
ln -sf ${main_dir}/specfem/DATABASES_MPI/proc*_Database DATABASES_MPI/
#cp ${main_dir}/specfem/DATABASES_MPI/proc*_rho.bin DATABASES_MPI/
echo -e ".false.\n.true." > adepml_stage
mpirun -np $NPROC ./bin/xgenerate_databases

