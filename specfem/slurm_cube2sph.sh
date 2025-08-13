#!/usr/bin/bash

## job name and output file
#SBATCH --job-name specfem_mesher
#SBATCH --output %j.o

###########################################################
# USER PARAMETERS

## 40 CPUs ( 10*4 ), walltime 5 hour
#SBATCH --nodes=10
#SBATCH --ntasks=400
#SBATCH --time=00:25:00

###########################################################

cd $SLURM_SUBMIT_DIR
module load intel openmpi python/3.6.8 hdf5/1.8.21 netcdf/4.6.3

currentdir=`pwd`

specfem_dir="${HOME}/specfem3d_pml_1order"
NPROC=`grep ^NPROC DATA/Par_file | grep -v -E '^[[:space:]]*#' | cut -d = -f 2`

BASEMPIDIR=`grep ^LOCAL_PATH DATA/Par_file | cut -d = -f 2 `

# generate database for the undeformed mesh, with a default model
echo -e ".true.\n.false." > adepml_stage
cp $specfem_dir/bin/xgenerate_databases bin

echo "start to run database generation: `date`"
# runs database generation
if [ "$NPROC" -eq 1 ]; then
  # This is a serial simulation
  echo
  echo "  running database generation..."
  echo
  ./bin/xgenerate_databases
else
  # This is a MPI simulation
  echo
  echo "  running database generation on $NPROC processors..."
  echo
  mpirun -np $NPROC ./bin/xgenerate_databases
fi
# checks exit code
if [[ $? -ne 0 ]]; then exit 1; fi
echo "database generation done: `date`"

# start cube2sph transformation
echo -e ".false.\n.true." > adepml_stage

cp $specfem_dir/utils/cube2sph/bin/* bin/
cp -R DATABASES_MPI DATABASES_MPI_REF
#mpirun -np $NPROC ./bin/cube2sph_adepml

#./bin/cube2sph_force
#./bin/cube2sph_station
mpirun -np $NPROC ./bin/cube2sph_adepml DATABASES_MPI_REF DATABASES_MPI 62.5 -151.0 20.0
cp DATABASES_MPI_REF/proc*adepml_param.bin DATABASES_MPI
cp $specfem_dir/bin/xgenerate_databases bin/
#cp $specfem_dir/bin/xget_isotropic_vbulk bin/
#cp $specfem_dir/bin/xwrite_zero_array bin/
cp $specfem_dir/bin/xsmooth_sem_sph_pde bin/
cp $specfem_dir/bin/xcombine_vol_data_vtk bin/
#cp DATA/Par_file_gll DATA/Par_file
sed -i "/^MODEL/c\MODEL                           = gll" DATA/Par_file
cp DATA/Par_file OUTPUT_FILES
echo "start to run database generation: `date`"
# runs database generation on isotropic model, so that smoothing can run properly.
if [ "$NPROC" -eq 1 ]; then
  # This is a serial simulation
  echo
  echo "  running database generation..."
  echo
  ./bin/xgenerate_databases
else
  # This is a MPI simulation
  echo
  echo "  running database generation on $NPROC processors..."
  echo
  mpirun -np $NPROC ./bin/xgenerate_databases
fi
# checks exit code
if [[ $? -ne 0 ]]; then exit 1; fi
echo "database generation done: `date`"

#mpirun -np $NPROC ./bin/xget_isotropic_vbulk DATABASES_MPI vp vs DATABASES_MPI vbulk
#mpirun -np $NPROC ./bin/xwrite_zero_array DATABASES_MPI Gc_nondim,Gs_nondim
#mpirun -np $NPROC ./bin/xsmooth_sem_sph_pde 30000.0 10000.0 vbulk DATABASES_MPI DATABASES_MPI FALSE
mpirun -np $NPROC ./bin/xsmooth_sem_sph_pde 80000.0 40000.0 rho DATABASES_MPI DATABASES_MPI FALSE FALSE
mpirun -np $NPROC ./bin/xsmooth_sem_sph_pde 80000.0 40000.0 vp DATABASES_MPI DATABASES_MPI FALSE FALSE
mpirun -np $NPROC ./bin/xsmooth_sem_sph_pde 80000.0 40000.0 vs DATABASES_MPI DATABASES_MPI FALSE FALSE
cd DATABASES_MPI
#ls proc*vbulk.bin | 
#while read fn; do
#  prefix=`echo $fn | cut -d'.' -f1`
#  mv $fn ${prefix}_unsmooth.bin
#  cp ${prefix}_smooth.bin ${prefix}.bin
#done
ls proc*rho.bin |
while read fn; do
  prefix=`echo $fn | cut -d'.' -f1`
  mv $fn ${prefix}_unsmooth.bin
  cp ${prefix}_smooth.bin ${prefix}.bin
done
ls proc*vs.bin |
while read fn; do
  prefix=`echo $fn | cut -d'.' -f1`
  mv $fn ${prefix}_unsmooth.bin
  #cp ${prefix}_smooth.bin ${prefix}h.bin
  cp ${prefix}_smooth.bin ${prefix}.bin
done
ls proc*vp.bin |
while read fn; do
  prefix=`echo $fn | cut -d'.' -f1`
  mv $fn ${prefix}_unsmooth.bin
  #cp ${prefix}_smooth.bin ${prefix}h.bin
  cp ${prefix}_smooth.bin ${prefix}.bin
done
cd ..
echo "start to run database generation: `date`"
# runs database generation
#cp DATA/Par_file_gll_ani DATA/Par_file
#sed -i "/^ANISOTROPY/c\ANISOTROPY                           = .true." DATA/Par_file
cp DATA/Par_file OUTPUT_FILES
if [ "$NPROC" -eq 1 ]; then
  # This is a serial simulation
  echo
  echo "  running database generation..."
  echo
  ./bin/xgenerate_databases
else
  # This is a MPI simulation
  echo
  echo "  running database generation on $NPROC processors..."
  echo
  mpirun -np $NPROC ./bin/xgenerate_databases
fi
# checks exit code
if [[ $? -ne 0 ]]; then exit 1; fi
echo "database generation done: `date`"

echo
echo "    generate vtk file for vs... "
echo
#./bin/xcombine_vol_data_vtk 0 399 vsv DATABASES_MPI/ . 0
NPROC_MINUS_ONE=`echo "$NPROC-1" | bc`
./bin/xcombine_vol_data_vtk 0 ${NPROC_MINUS_ONE} vs DATABASES_MPI/ . 0


