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
model_dir=M56
#BB_dir=${current_dir}
BB_dir=/bb/l/liuqy/liutia97
is_pst=false
inherit_windows=true
if ${inherit_windows}; then
prev_model_dir=M56
fi
#srfile=sources_ls_set1.dat
#eid=20220108-08h16m42s-Yakutat-M5.2-37.8km
eid=20170511-14h36m30s-OldHarbor-M5.4-10.1km
mesh_dir=model_M56
#band_code=T025_T050,T040_T080,T060_T120
#nevt=`cat src_rec_sub/${srfile} | wc -l`
go_forward=true
go_preprocess_measurement=true
go_adjoint=false
go_move_kernels=false
go_smooth_kernels=false
go_delete_solver=true
go_delete_measurement=true
save_seismograms=false
NSTEP=13440
DT=0.07
T0=-40.0
SIGMA_H=30000.0
SIGMA_V=10000.0
SRC_REC_DIR=src_rec_eq
DATA_DIR=data_sac_eq
################ FORWARD PART #############################
echo ${model_dir}
echo ${eid}
if ${go_forward}; then
#for evtnum in `seq 1 1 $nevt`;do
#evtfile=`cat src_rec_sub/${srfile} | sed -n "${evtnum}p"`
## prepare forward run for each master station
#eid=AK.GAMB
#for comp in X Y Z; do
BASE_DIR=${BB_dir}/solver/${model_dir}/${eid}
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
cp ${SRC_REC_DIR}/butterworth_heaviside_stf.dat ${BASE_DIR}/DATA/butterworth_heaviside_stf.dat
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
sed -i "/^USE_FORCE_POINT_SOURCE /c\USE_FORCE_POINT_SOURCE          = .false." ${BASE_DIR}/DATA/Par_file
# use external source time function
sed -i "/^USE_RICKER_TIME_FUNCTION /c\USE_RICKER_TIME_FUNCTION        = .false." ${BASE_DIR}/DATA/Par_file
sed -i "/^USE_EXTERNAL_SOURCE_FILE /c\USE_EXTERNAL_SOURCE_FILE        = .true." ${BASE_DIR}/DATA/Par_file
#cp change_simulation_type.pl ${BASE_DIR}
ln -sf $PWD/specfem/DATABASES_MPI/*_Database ${BASE_DIR}/DATABASES_MPI
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
cd ${current_dir}

############## ROTATION, MEASUREMENT #################
module load intel openmpi python/3.6.8
source ~/.virtualenvs/noisepy/bin/activate
echo 
echo "  rotate from XYZ to RTZ ..."
echo

BASE_DIR=${BB_dir}/solver/${model_dir}/${eid}
mkdir -p ${BASE_DIR}/OUTPUT_FILES_sph
mpiexec -n $NPROC python3 rotate_seismogram.py --fn_matrix="${SRC_REC_DIR}/$eid/rotate_nu_rtz_xyz" --rotate="XYZ->RTZ" --from_dir="${BASE_DIR}/OUTPUT_FILES" --to_dir="${BASE_DIR}/OUTPUT_FILES_sph" --from_template='${nt}.${sta}.BX${comp}.semd' --to_template='${nt}.${sta}.BX${comp}.semd'


echo 
echo "  measurement ..."
echo
if [ -d measure_adj_${model_dir}/${eid} ]; then
  rm -rf measure_adj_${model_dir}/${eid}
fi
for comp in R T Z; do
case $comp in
  R)
    char_comp=R00
  ;;
  T)
    char_comp=0T0
  ;;
  Z)
    char_comp=00Z
  ;;
esac
for band in T025_T050 T040_T080 T060_T120; do
  echo "  - measurement for ${comp}.${band}"
  if [ ! -f ${SRC_REC_DIR}/${eid}/MEASUREMENT.WINDOWS_PAIR.${comp}.${band} ]; then
    echo "    window does not exist, skipping"
    continue
  fi
  mkdir -p measure_adj_${model_dir}/${eid}/${comp}.${band}
  cat ${SRC_REC_DIR}/${eid}/MEASUREMENT.WINDOWS_SNR_FILTERED.${comp}.${band} | awk '{print $1}' > measure_adj_${model_dir}/${eid}/${comp}.${band}/STATIONS_NAMES
  if ${is_pst}; then
    cp ${SRC_REC_DIR}/MEASUREMENT.PAR_pst.${comp}.${band} measure_adj_${model_dir}/${eid}/${comp}.${band}/MEASUREMENT.PAR
  else
    cp ${SRC_REC_DIR}/MEASUREMENT.PAR_iter.${comp}.${band} measure_adj_${model_dir}/${eid}/${comp}.${band}/MEASUREMENT.PAR
  fi
  if ${inherit_windows}; then
    #cp measure_adj_${prev_model_dir}/${eid}/${comp}.${band}/MEASUREMENT.WINDOWS.FILTERED measure_adj_${model_dir}/${eid}/${comp}.${band}/MEASUREMENT.WINDOWS
    cat /dev/null > measure_adj_${model_dir}/${eid}/${comp}.${band}/MEASUREMENT.WINDOWS
    if ${is_pst}; then
      paste measure_adj_${prev_model_dir}/${eid}/${comp}.${band}/MEASUREMENT.WINDOWS measure_adj_${prev_model_dir}/${eid}/${comp}.${band}/window_chi | awk '{if ($9 > 0) {print $1, $2, $3, $4, $5, $6, 7} else if ($11 >0){print $1, $2, $3, $4, $5, $6, 5}}' >> measure_adj_${model_dir}/${eid}/${comp}.${band}/MEASUREMENT.WINDOWS
    else
      paste measure_adj_${prev_model_dir}/${eid}/${comp}.${band}/MEASUREMENT.WINDOWS measure_adj_${prev_model_dir}/${eid}/${comp}.${band}/window_chi | awk '{if ($9 > 0) {print $1, $2, $3, $4, $5, $6} else if ($11 >0){print $1, $2, $3, $4, $5, $6}}' >> measure_adj_${model_dir}/${eid}/${comp}.${band}/MEASUREMENT.WINDOWS
    fi
  else
    cat ${SRC_REC_DIR}/${eid}/MEASUREMENT.WINDOWS_PAIR.${comp}.${band} | awk '{print $1, $2, $3, $4, $5, $6}' > measure_adj_${model_dir}/${eid}/${comp}.${band}/MEASUREMENT.WINDOWS
  fi
  ln -sf ~/adjoint_preprocess_measure/program_preprocess_measure_DD measure_adj_${model_dir}/${eid}/${comp}.${band}
  ### replace when using real data
  #ln -sf ${current_dir}/solver/point_spread_init/${eid}/OUTPUT_FILES_sph measure_adj_${model_dir}/${eid}/${comp}.${band}/DAT
  ln -sf ${current_dir}/${DATA_DIR}/${eid} measure_adj_${model_dir}/${eid}/${comp}.${band}/DAT
  ################################
  ln -sf ${BASE_DIR}/OUTPUT_FILES_sph measure_adj_${model_dir}/${eid}/${comp}.${band}/SYN
  cd measure_adj_${model_dir}/${eid}/${comp}.${band}
  mkdir -p LOG
  mkdir -p OUTPUT_FILES
  mkdir -p SEM
  mpirun -np $NPROC ./program_preprocess_measure_DD
  ### delete OUTPUT_FILES for real data
  #rm -rf OUTPUT_FILES
  #cat /dev/null > MEASUREMENT.WINDOWS.FILTERED
  #paste MEASUREMENT.WINDOWS window_chi | awk '{if (($9 > 0) || ($11 >0) ) print $1, $2, $3, $4, $5, $6}' >> MEASUREMENT.WINDOWS.FILTERED
  #paste MEASUREMENT.WINDOWS window_chi | awk '{if ($9 > 0) {print $1, $2, $3, $4, $5, $6, 7} else if ($11 >0){print $1, $2, $3, $4, $5, $6, 5}}' >> MEASUREMENT.WINDOWS.FILTERED
  mkdir -p SEM_cart
  #####################################
  cd ${current_dir}
  mpiexec -n $NPROC python3 rotate_seismogram.py --fn_matrix="${SRC_REC_DIR}/$eid/rotate_nu_rtz_xyz" --rotate="XYZ<-${char_comp}" --from_dir="measure_adj_${model_dir}/${eid}/${comp}.${band}/SEM" --to_dir="measure_adj_${model_dir}/${eid}/${comp}.${band}/SEM_cart" --from_template='${nt}.${sta}.BX${comp}.adj' --to_template='${nt}.${sta}.BX${comp}.adj'
  echo "  - measurement for ${comp}.${band} finish"
done
done
deactivate

echo "  sum over component and band with weights ..."
cp ${SRC_REC_DIR}/weights measure_adj_${model_dir}/${eid}
cp ${BASE_DIR}/DATA/STATIONS measure_adj_${model_dir}/${eid}
cd measure_adj_${model_dir}/${eid}
mkdir SEM
ln -sf ~/adjoint_preprocess_measure/program_sum_adjoint_sources_weight .
mpirun -np $NPROC ./program_sum_adjoint_sources_weight ${T0} ${DT} ${NSTEP}
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
BASE_DIR=${BB_dir}/solver/${model_dir}/${eid}
sed -i "/^SIMULATION_TYPE /c\SIMULATION_TYPE                 = 3" ${BASE_DIR}/DATA/Par_file
sed -i "/^ANISOTROPIC_KL /c\ANISOTROPIC_KL                  = .false." ${BASE_DIR}/DATA/Par_file
sed -i "/^SAVE_TRANSVERSE_KL /c\SAVE_TRANSVERSE_KL              = .false." ${BASE_DIR}/DATA/Par_file
if [ -d ${BASE_DIR}/SEM ]; then
  rm -rf ${BASE_DIR}/SEM
fi
mv ${current_dir}/measure_adj_${model_dir}/${eid}/SEM ${BASE_DIR}/SEM
cd ${BASE_DIR}

cp DATA/STATIONS DATA/STATIONS_ADJOINT
## start solver
module load intel openmpi
#NPROC=400
echo
echo "  running solver (adjoint) for ${eid} on $NPROC processors..."
echo
mpirun -np $NPROC ./bin/xspecfem3D
echo
echo "  solver (adjoint) done for ${eid}"
echo
cd ${current_dir}
fi

#################### move kernels ##################
if ${go_move_kernels}; then
echo
echo "  move kernels..."
echo
BASE_DIR=${BB_dir}/solver/${model_dir}/${eid}
cd ${current_dir}
module load intel openmpi
#model=Msub
#ipart=1
sumkern_dir=event_kernel_${model_dir}/${eid}
rm -rf ${sumkern_dir}
#mkdir -p ${sumkern_dir}/DATABASES_MPI
#mkdir -p ${sumkern_dir}/bin
mkdir -p ${sumkern_dir}/OUTPUT_SUM
#ln -sf ~/specfem3d_pml_1order/bin/xcombine_sem ${sumkern_dir}/bin
#ln -sf ${current_dir}/specfem/DATA ${sumkern_dir}
#ln -sf ${current_dir}/specfem/DATABASES_MPI ${sumkern_dir}
#cd ${sumkern_dir}
#echo ${current_dir}/solver/${model_dir}/${eid}_X/DATABASES_MPI > dir_list
#echo ${current_dir}/solver/${model_dir}/${eid}_Y/DATABASES_MPI >> dir_list
#echo ${current_dir}/solver/${model_dir}/${eid}_Z/DATABASES_MPI >> dir_list

#NPROC=400
#mpirun -np $NPROC ./bin/xcombine_sem vbulk_kernel,betav_kernel,betah_kernel,Gc_kernel,Gs_kernel dir_list OUTPUT_SUM
#mv ${BASE_DIR}/DATABASES_MPI/proc*_vbulk_kernel.bin ${sumkern_dir}/OUTPUT_SUM
mv ${BASE_DIR}/DATABASES_MPI/proc*_alpha_kernel.bin ${sumkern_dir}/OUTPUT_SUM
mv ${BASE_DIR}/DATABASES_MPI/proc*_beta_kernel.bin ${sumkern_dir}/OUTPUT_SUM
#mv ${BASE_DIR}/DATABASES_MPI/proc*_betah_kernel.bin ${sumkern_dir}/OUTPUT_SUM
#mv ${BASE_DIR}/DATABASES_MPI/proc*_Gc_kernel.bin ${sumkern_dir}/OUTPUT_SUM
#mv ${BASE_DIR}/DATABASES_MPI/proc*_Gs_kernel.bin ${sumkern_dir}/OUTPUT_SUM
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
mpirun -np $NPROC ./bin/xsmooth_sem_sph_pde ${SIGMA_H} ${SIGMA_V} beta_kernel OUTPUT_SUM OUTPUT_SUM FALSE
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
mkdir -p save_seismograms/${model_dir}
if [ -d save_seismograms/${model_dir}/${eid} ]; then
  rm -rf save_seismograms/${model_dir}/${eid}
fi
mv ${BB_dir}/solver/${model_dir}/${eid}/OUTPUT_FILES_sph save_seismograms/${model_dir}/${eid}
fi

if ${go_delete_solver}; then
cd ${current_dir}
BASE_DIR=${BB_dir}/solver/${model_dir}/${eid}
rm -rf ${BASE_DIR}
fi

if ${go_delete_measurement}; then
cd ${current_dir}
for comp in R T Z; do
for band in T025_T050 T040_T080 T060_T120; do
rm -rf ${current_dir}/measure_adj_${model_dir}/${eid}/${comp}.${band}/OUTPUT_FILES/ ${current_dir}/measure_adj_${model_dir}/${eid}/${comp}.${band}/SEM*/
done
done
if [ -d ${current_dir}/measure_adj_${model_dir}/${eid}/SEM ]; then
  rm -rf ${current_dir}/measure_adj_${model_dir}/${eid}/SEM
fi
fi
