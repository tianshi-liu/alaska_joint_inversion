#!/usr/bin/bash

## job name and output file
#SBATCH --job-name specfem_mesher
#SBATCH --output %j.o

###########################################################
# USER PARAMETERS

## 40 CPUs ( 10*4 ), walltime 5 hour
#SBATCH --nodes=10
#SBATCH --ntasks=400
#SBATCH --time=00:15:00

###########################################################

cd $SLURM_SUBMIT_DIR
NPROC=400
current_dir=`pwd`
model_dir=M56
eid=20230319-15h06m27s-AnchorPoint-M5.4-65.4km
mesh_dir=model_M56
NSTEP=13440
DT=0.07
T0=-40.0
SRC_REC_DIR=src_rec_eq
is_rotate=false
is_delete_database=false
################ FORWARD PART #############################
echo ${model_dir}
echo ${eid}
BASE_DIR=solver/${model_dir}/${eid}
if [ -d ${BASE_DIR} ]; then
  rm -rf ${BASE_DIR}
fi
mkdir -p ${BASE_DIR}/OUTPUT_FILES
mkdir -p ${BASE_DIR}/DATA
mkdir -p ${BASE_DIR}/DATABASES_MPI
mkdir -p ${BASE_DIR}/bin
cp ${mesh_dir}/OUTPUT_FILES/* ${BASE_DIR}/OUTPUT_FILES
cp ${SRC_REC_DIR}/${eid}/CMTSOLUTION_cart ${BASE_DIR}/DATA/CMTSOLUTION
cp ${SRC_REC_DIR}/${eid}/STATIONS_cart ${BASE_DIR}/DATA/STATIONS
cp ${SRC_REC_DIR}/butterworth_heaviside_stf_10s.dat ${BASE_DIR}/DATA/butterworth_heaviside_stf.dat
echo "DATA/butterworth_heaviside_stf.dat" >> ${BASE_DIR}/DATA/CMTSOLUTION
cp specfem_iso/DATA/Par_file_initmesh ${BASE_DIR}/DATA/Par_file
# keep consistent with mesher
sed -i "/^NPROC/c\NPROC                           = ${NPROC}" ${BASE_DIR}/DATA/Par_file
sed -i "/^NGNOD/c\NGNOD                           = 27" ${BASE_DIR}/DATA/Par_file
sed -i "/^MODEL/c\MODEL                           = gll" ${BASE_DIR}/DATA/Par_file
sed -i "/^ANISOTROPY/c\ANISOTROPY                      = .false." ${BASE_DIR}/DATA/Par_file
# set desired time step and dt
sed -i "/^NSTEP /c\NSTEP                           = ${NSTEP}" ${BASE_DIR}/DATA/Par_file
sed -i "/^DT /c\DT                              = ${DT}" ${BASE_DIR}/DATA/Par_file
# set simulation type to 1 (forward)
sed -i "/^SIMULATION_TYPE /c\SIMULATION_TYPE                 = 1" ${BASE_DIR}/DATA/Par_file
# CMT force
sed -i "/^USE_FORCE_POINT_SOURCE /c\USE_FORCE_POINT_SOURCE          = .false." ${BASE_DIR}/DATA/Par_file
# use Heaviside source time function
sed -i "/^USE_RICKER_TIME_FUNCTION /c\USE_RICKER_TIME_FUNCTION        = .false." ${BASE_DIR}/DATA/Par_file
#sed -i "/^USE_EXTERNAL_SOURCE_FILE /c\USE_EXTERNAL_SOURCE_FILE        = .false." ${BASE_DIR}/DATA/Par_file
sed -i "/^USE_EXTERNAL_SOURCE_FILE /c\USE_EXTERNAL_SOURCE_FILE        = .true." ${BASE_DIR}/DATA/Par_file
#cp change_simulation_type.pl ${BASE_DIR}
ln -sf $PWD/specfem_iso/DATABASES_MPI/*_Database ${BASE_DIR}/DATABASES_MPI
ln -sf $PWD/${mesh_dir}/DATABASES_MPI/*.bin ${BASE_DIR}/DATABASES_MPI
#ln -sf $PWD/specfem/bin/xspecfem3D ${BASE_DIR}/bin
ln -sf $HOME/specfem3d_pml_1order/bin/xspecfem3D ${BASE_DIR}/bin
cd ${BASE_DIR}
cp DATA/CMTSOLUTION OUTPUT_FILES/
cp DATA/STATIONS OUTPUT_FILES/
cp DATA/Par_file OUTPUT_FILES/
#./change_simulation_type.pl -f
## start solver
module load intel openmpi
#NPROC=400
echo
echo "  running solver for ${eid} on $NPROC processors..."
echo
mpirun -np $NPROC ./bin/xspecfem3D
echo
echo "  solver done for ${eid}"
echo

ln -sf $HOME/specfem3d_pml_1order/bin/xwrite_forward_wavefield_database bin/
mpirun -np $NPROC ./bin/xwrite_forward_wavefield_database
cd ${current_dir}

############## ROTATION  #################
if ${is_rotate}; then 
module load intel openmpi python/3.6.8
source ~/.virtualenvs/noisepy/bin/activate
echo 
echo "  rotate from XYZ to RTZ ..."
echo

BASE_DIR=solver/${model_dir}/${eid}
mkdir -p ${BASE_DIR}/OUTPUT_FILES_sph
mpiexec -n $NPROC python3 rotate_seismogram.py --fn_matrix="${SRC_REC_DIR}/$eid/rotate_nu_rtz_xyz" --rotate="XYZ->RTZ" --from_dir="${BASE_DIR}/OUTPUT_FILES" --to_dir="${BASE_DIR}/OUTPUT_FILES_sph" --from_template='${nt}.${sta}.BX${comp}.semd' --to_template='${nt}.${sta}.BX${comp}.semd'
deactivate
fi
################### delete files ##########################
if ${is_delete_database}; then
mkdir -p save_seismograms/${model_dir}
if [ -d save_seismograms/${model_dir}/${eid} ]; then
  rm -rf save_seismograms/${model_dir}/${eid}
fi
mv solver/${model_dir}/${eid}/OUTPUT_FILES_sph save_seismograms/${model_dir}/${eid}
cd ${current_dir}
BASE_DIR=solver/${model_dir}/${eid}
rm -rf ${BASE_DIR}
fi
