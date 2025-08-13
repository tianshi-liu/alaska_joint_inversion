#!/usr/bin/bash

## job name and output file
#SBATCH --job-name specfem_mesher
#SBATCH --output %j.o

###########################################################
# USER PARAMETERS

## 40 CPUs ( 10*4 ), walltime 5 hour
#SBATCH --nodes=10
#SBATCH --ntasks=400
#SBATCH --time=00:60:00

###########################################################

cd $SLURM_SUBMIT_DIR
NPROC=400
current_dir=`pwd`
model_dir=M56.ls
BB_dir=/bb/l/liuqy/liutia97
is_pst=false
inherit_windows=true
if ${inherit_windows}; then
prev_model_dir=M56
fi
#srfile=sources_ls_set1.dat
#eid=20220108-08h16m42s-Yakutat-M5.2-37.8km
eid=TA.N30M
mesh_dir=model_M56
#band_code=T025_T050,T040_T080,T060_T120
#nevt=`cat src_rec_sub/${srfile} | wc -l`
go_forward=true
go_preprocess_measurement=true
go_adjoint=false
go_combine_kernels=false
go_smooth_kernels=false
go_delete_solver=true
go_delete_measurement=true
save_seismograms=false
NSTEP=13440
DT=0.07
T0=-40.0
SIGMA_H=30000.0
SIGMA_V=10000.0
SRC_REC_DIR=src_rec_noise
DATA_DIR=data_sac_noise
################ FORWARD PART #############################
echo ${model_dir}
echo ${eid}
if ${go_forward}; then
#for evtnum in `seq 1 1 $nevt`;do
#evtfile=`cat src_rec_sub/${srfile} | sed -n "${evtnum}p"`
## prepare forward run for each master station
#eid=AK.GAMB
for comp in X Y Z; do
BASE_DIR=${BB_dir}/solver/${model_dir}/${eid}_${comp}
if [ -d ${BASE_DIR} ]; then
  rm -rf ${BASE_DIR}
fi
mkdir -p ${BASE_DIR}/OUTPUT_FILES
mkdir -p ${BASE_DIR}/DATA
mkdir -p ${BASE_DIR}/DATABASES_MPI
mkdir -p ${BASE_DIR}/bin
cp ${mesh_dir}/OUTPUT_FILES/* ${BASE_DIR}/OUTPUT_FILES
cp ${SRC_REC_DIR}/${eid}/FORCESOLUTION_${comp} ${BASE_DIR}/DATA/FORCESOLUTION
cp ${SRC_REC_DIR}/${eid}/STATIONS_cartesian ${BASE_DIR}/DATA/STATIONS
cp ${SRC_REC_DIR}/butterworth_stf.dat ${BASE_DIR}/DATA/butterworth_stf.dat
cp specfem/DATA/Par_file_initmesh ${BASE_DIR}/DATA/Par_file
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
sed -i "/^USE_FORCE_POINT_SOURCE /c\USE_FORCE_POINT_SOURCE          = .true." ${BASE_DIR}/DATA/Par_file
# use external source time function
sed -i "/^USE_RICKER_TIME_FUNCTION /c\USE_RICKER_TIME_FUNCTION        = .false." ${BASE_DIR}/DATA/Par_file
sed -i "/^USE_EXTERNAL_SOURCE_FILE /c\USE_EXTERNAL_SOURCE_FILE        = .true." ${BASE_DIR}/DATA/Par_file
#cp change_simulation_type.pl ${BASE_DIR}
ln -sf $PWD/specfem/DATABASES_MPI/*_Database ${BASE_DIR}/DATABASES_MPI
ln -sf $PWD/${mesh_dir}/DATABASES_MPI/*.bin ${BASE_DIR}/DATABASES_MPI
#ln -sf $PWD/specfem/bin/xspecfem3D ${BASE_DIR}/bin
ln -sf $HOME/specfem3d_pml_1order/bin/xspecfem3D ${BASE_DIR}/bin
cd ${BASE_DIR}
cp DATA/FORCESOLUTION OUTPUT_FILES/
cp DATA/STATIONS OUTPUT_FILES/
cp DATA/Par_file OUTPUT_FILES/
#./change_simulation_type.pl -f
## start solver
module load intel openmpi
#NPROC=400
echo
echo "  running solver for ${eid}_${comp} on $NPROC processors..."
echo
mpirun -np $NPROC ./bin/xspecfem3D
if [[ $? -ne 0 ]]; then
  echo "ERROR EXIT KILL ALL DEPENDENTS: FORWARD"
  exit 1
fi
echo
echo "  solver done for ${eid}_${comp}"
echo
cd ${current_dir}
done
fi
############## ROTATION, MEASUREMENT #################
if ${go_preprocess_measurement}; then

echo 
echo "  measurement ..."
echo
module load intel openmpi
if [ -d measure_adj_${model_dir}/${eid} ]; then
  rm -rf measure_adj_${model_dir}/${eid}
fi
for comp in Z R T; do
#BASE_DIR=${BB_dir}/solver/${model_dir}/${eid}_${comp}
for band in T025_T050 T018_T036 T012_T025; do
#for band in T025_T050; do
  echo "  - measurement for ${comp}.${band}"
  if [ ! -f ${SRC_REC_DIR}/${eid}/MEASUREMENT.WINDOWS.${comp}.${band} ]; then
    echo "    window does not exist, skipping"
    continue
  fi
  mkdir -p measure_adj_${model_dir}/${eid}/${comp}.${band}
  if ${inherit_windows}; then
    cp measure_adj_${prev_model_dir}/${eid}/${comp}.${band}/MEASUREMENT.WINDOWS.FILTERED measure_adj_${model_dir}/${eid}/${comp}.${band}/MEASUREMENT.WINDOWS 
  else
    cp ${SRC_REC_DIR}/${eid}/MEASUREMENT.WINDOWS.${comp}.${band} measure_adj_${model_dir}/${eid}/${comp}.${band}/MEASUREMENT.WINDOWS
  fi
  if ${is_pst}; then
    cp ${SRC_REC_DIR}/MEASUREMENT.PAR_pst.${comp}.${band} measure_adj_${model_dir}/${eid}/${comp}.${band}/MEASUREMENT.PAR
  else
    cp ${SRC_REC_DIR}/MEASUREMENT.PAR_iter.${comp}.${band} measure_adj_${model_dir}/${eid}/${comp}.${band}/MEASUREMENT.PAR
  fi
  cp ${SRC_REC_DIR}/${eid}/FORCESOLUTION_X measure_adj_${model_dir}/${eid}/${comp}.${band}/FORCESOLUTION
  cp ${SRC_REC_DIR}/${eid}/STATIONS_cartesian measure_adj_${model_dir}/${eid}/${comp}.${band}/STATIONS
  ln -sf ~/adjoint_preprocess_measure/program_preprocess_measure measure_adj_${model_dir}/${eid}/${comp}.${band}
  cd measure_adj_${model_dir}/${eid}/${comp}.${band}
  ln -sf ${current_dir}/${DATA_DIR}/${eid} DAT
  ln -sf ${BB_dir}/solver/${model_dir}/${eid}_X/OUTPUT_FILES SYN_X
  ln -sf ${BB_dir}/solver/${model_dir}/${eid}_Y/OUTPUT_FILES SYN_Y
  ln -sf ${BB_dir}/solver/${model_dir}/${eid}_Z/OUTPUT_FILES SYN_Z
  mkdir LOG
  mkdir OUTPUT_FILES
  mkdir SEM_X
  mkdir SEM_Y
  mkdir SEM_Z
  mpirun -np $NPROC ./program_preprocess_measure
  if [[ $? -ne 0 ]]; then 
    echo "ERROR EXIT KILL ALL DEPENDENTS: MEASURE"
    exit 1
  fi
  
  nmeas=`cat window_chi | awk '{if (($2 > 0) || ($4 >0) ) print $1}' | wc -l` 
  echo $nmeas > MEASUREMENT.WINDOWS.FILTERED
  cat window_chi | awk '{if (($2 > 0) || ($4 >0) ) print $1}' | while read rec; do
    grep -A1 $rec MEASUREMENT.WINDOWS >> MEASUREMENT.WINDOWS.FILTERED
  done
  cd ${current_dir}
done
done

echo "  sum over component and band with weights ..."
cp ${SRC_REC_DIR}/weights measure_adj_${model_dir}/${eid}
cp ${SRC_REC_DIR}/${eid}/STATIONS_cartesian measure_adj_${model_dir}/${eid}/STATIONS
cd measure_adj_${model_dir}/${eid}
mkdir SEM_X
mkdir SEM_Y
mkdir SEM_Z
ln -sf ~/adjoint_preprocess_measure/program_sum_adjoint_sources_weight_noise .
mpirun -np $NPROC ./program_sum_adjoint_sources_weight_noise ${T0} ${DT} ${NSTEP}
if [[ $? -ne 0 ]]; then 
  echo "ERROR EXIT KILL ALL DEPENDENTS: SUM"
  exit 1
fi
cd ${current_dir}
#mkdir -p data/${eid}_${comp}
#mv ${BASE_DIR}/OUTPUT_FILES/*.semd data/${eid}_${comp}
#rm -rf ${BASE_DIR}
#done
#done
#rm -rf solver/${model_dir}
fi

################## adjoint simulation ################
if ${go_adjoint}; then
cd ${current_dir}
for comp in X Y Z; do
BASE_DIR=${BB_dir}/solver/${model_dir}/${eid}_${comp}
sed -i "/^SIMULATION_TYPE /c\SIMULATION_TYPE                 = 3" ${BASE_DIR}/DATA/Par_file
sed -i "/^ANISOTROPIC_KL /c\ANISOTROPIC_KL                  = .false." ${BASE_DIR}/DATA/Par_file
sed -i "/^SAVE_TRANSVERSE_KL /c\SAVE_TRANSVERSE_KL              = .false." ${BASE_DIR}/DATA/Par_file
if [ -d ${BASE_DIR}/SEM ]; then
  rm -rf ${BASE_DIR}/SEM
fi
mv ${current_dir}/measure_adj_${model_dir}/${eid}/SEM_${comp} ${BASE_DIR}/SEM
cd ${BASE_DIR}

cp DATA/STATIONS DATA/STATIONS_ADJOINT
## start solver
module load intel openmpi
#NPROC=400
echo
echo "  running solver (adjoint) for ${eid}_${comp} on $NPROC processors..."
echo
mpirun -np $NPROC ./bin/xspecfem3D
if [[ $? -ne 0 ]]; then 
  echo "ERROR EXIT KILL ALL DEPENDENTS: ADJOINT"
  exit 1
fi
echo
echo "  solver (adjoint) done for ${eid}_${comp}"
echo
cd ${current_dir}
done
fi

#################### move kernels ##################
if ${go_combine_kernels}; then
echo
echo "  combine kernels..."
echo
cd ${current_dir}
module load intel openmpi
#model=Msub
#ipart=1
sumkern_dir=event_kernel_${model_dir}/${eid}
rm -rf ${sumkern_dir}
mkdir -p ${sumkern_dir}
mkdir -p ${sumkern_dir}/bin
mkdir -p ${sumkern_dir}/OUTPUT_SUM
ln -sf ${HOME}/specfem3d_pml_1order/bin/xcombine_sem ${sumkern_dir}/bin
ln -sf ${current_dir}/specfem/DATA ${sumkern_dir}
ln -sf ${current_dir}/specfem/DATABASES_MPI ${sumkern_dir}
cd ${sumkern_dir}
echo ${BB_dir}/solver/${model_dir}/${eid}_X/DATABASES_MPI > dir_list
echo ${BB_dir}/solver/${model_dir}/${eid}_Y/DATABASES_MPI >> dir_list
echo ${BB_dir}/solver/${model_dir}/${eid}_Z/DATABASES_MPI >> dir_list

#NPROC=400
mpirun -np $NPROC ./bin/xcombine_sem alpha_kernel,beta_kernel dir_list OUTPUT_SUM
if [[ $? -ne 0 ]]; then 
  echo "ERROR EXIT KILL ALL DEPENDENTS: COMBINE"
  exit 1
fi
cd ${current_dir}
fi

################### smooth kernels ####################
if ${go_smooth_kernels}; then
echo
echo "  smooth kernels..."
echo
cd ${current_dir}
module load intel openmpi
sumkern_dir=event_kernel_${model_dir}/${eid}
mkdir -p ${sumkern_dir}/bin
ln -sf ${HOME}/specfem3d_pml_1order/bin/xsmooth_sem_sph_pde ${sumkern_dir}/bin
#mkdir -p ${sumkern_dir}/OUTPUT_SUM
ln -sf ${current_dir}/specfem/DATA ${sumkern_dir}
ln -sf ${current_dir}/specfem/DATABASES_MPI ${sumkern_dir}
mkdir -p ${sumkern_dir}/OUTPUT_FILES
cp ${mesh_dir}/OUTPUT_FILES/* ${sumkern_dir}/OUTPUT_FILES

cd ${sumkern_dir}
#mpirun -np $NPROC ./bin/xsmooth_sem_sph_pde 30000 10000 alphav_kernel OUTPUT_SUM OUTPUT_SUM FALSE
#mpirun -np $NPROC ./bin/xsmooth_sem_sph_pde 30000 10000 alphah_kernel OUTPUT_SUM OUTPUT_SUM FALSE
#mpirun -np $NPROC ./bin/xsmooth_sem_sph_pde ${SIGMA_H} ${SIGMA_V} vbulk_kernel OUTPUT_SUM OUTPUT_SUM FALSE
mpirun -np $NPROC ./bin/xsmooth_sem_sph_pde ${SIGMA_H} ${SIGMA_V} alpha_kernel OUTPUT_SUM OUTPUT_SUM FALSE
if [[ $? -ne 0 ]]; then 
  echo "ERROR EXIT KILL ALL DEPENDENTS: SMOOTH P KERNEL"
  exit 1
fi
mpirun -np $NPROC ./bin/xsmooth_sem_sph_pde ${SIGMA_H} ${SIGMA_V} beta_kernel OUTPUT_SUM OUTPUT_SUM FALSE
if [[ $? -ne 0 ]]; then 
  echo "ERROR EXIT KILL ALL DEPENDENTS: SMOOTH S KERNEL"
  exit 1
fi
#mpirun -np $NPROC ./bin/xsmooth_sem_sph_pde ${SIGMA_H} ${SIGMA_V} betah_kernel OUTPUT_SUM OUTPUT_SUM FALSE
#mpirun -np $NPROC ./bin/xsmooth_sem_sph_pde ${SIGMA_H} ${SIGMA_V} Gc_kernel OUTPUT_SUM OUTPUT_SUM FALSE
#mpirun -np $NPROC ./bin/xsmooth_sem_sph_pde ${SIGMA_H} ${SIGMA_V} Gs_kernel OUTPUT_SUM OUTPUT_SUM FALSE
#mpirun -np $NPROC ./bin/xsmooth_sem_sph_pde 30000 10000 rhop_kernel OUTPUT_SUM OUTPUT_SUM FALSE
cd ${current_dir}
fi

echo `date` >> eid_completed
echo $eid >> eid_completed

################### delete files ##########################
if ${save_seismograms}; then
cd ${current_dir}
for comp in X Y Z; do
mkdir -p save_seismograms/${model_dir}
if [ -d save_seismograms/${model_dir}/${eid}_${comp} ]; then
  rm -rf save_seismograms/${model_dir}/${eid}_${comp}
fi
mv ${BB_dir}/solver/${model_dir}/${eid}_${comp}/OUTPUT_FILES save_seismograms/${model_dir}/${eid}_${comp}
done
fi


if ${go_delete_solver}; then
cd ${current_dir}
BASE_DIR=${BB_dir}/solver/${model_dir}/${eid}_*
rm -rf ${BASE_DIR}
fi

if ${go_delete_measurement}; then
cd ${current_dir}
for comp in R T Z; do
for band in T025_T050 T018_T036 T012_T025; do
#for band in T025_T050; do
rm -rf ${current_dir}/measure_adj_${model_dir}/${eid}/${comp}.${band}/OUTPUT_FILES/ ${current_dir}/measure_adj_${model_dir}/${eid}/${comp}.${band}/SEM*/
done
done
if [ -d ${current_dir}/measure_adj_${model_dir}/${eid}/SEM_Z ]; then
  rm -rf ${current_dir}/measure_adj_${model_dir}/${eid}/SEM_*/
fi
fi
