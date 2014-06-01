#!/bin/sh
# Run all experiments for demonstrating boundary conditions
# in a 1D wave equation

dir=~/vc/deqbook/doc/src/wave/src-wave/wave1D
experiments_dir=mov-wavebc
rm -rf $experiments_dir
mkdir $experiments_dir
cd $experiments_dir
rm -rf plug* gaussian* periodic* moving_end*

name=moving_end_Nx100_C1
mkdir $name
cd $name
python $dir/wave1D_dn.py moving_end C=1 Nx=100 T=3
cd ..

name=plug_Nx100_C1
mkdir $name
cd $name
python $dir/wave1D_dn.py plug C=1 Nx=100 T=4 loc=0.3 'ic="u"'
cd ..

name=gaussian_Nx50_C1_un0
mkdir $name
cd $name
python $dir/wave1D_dn.py gaussian C=1 Nx=50 T=4 loc=3 'ic="u"' 'bc_left="du/dn=0"'
cd ..

name=gaussian_Nx50_C1_u0
mkdir $name
cd $name
python $dir/wave1D_dn.py gaussian C=1 Nx=50 T=4 loc=3 'ic="u"' 'bc_left="u=0"'
cd ..

name=gaussian_Nx50_C1_V
mkdir $name
cd $name
python $dir/wave1D_dn.py gaussian C=1 Nx=50 T=4 loc=3 'ic="u_t"' 'bc_left="u=0"'
cd ..

name=gaussian_Nx50_C0.5_un0
mkdir $name
cd $name
python $dir/wave1D_dn.py gaussian C=0.5 Nx=50 T=4 loc=3 'ic="u"' 'bc_left="du/dn=0"'
cd ..

# Noisy plug
name=plug_Nx100_C0.5
mkdir $name
cd $name
python $dir/wave1D_dn.py plug C=0.5 Nx=200 T=2 loc=0.5 'ic="u"'
cd ..

dir=../../../../wave/exer-wave/periodic

name=periodic_Nx100_C1_l0
mkdir $name
cd $name
python $dir/periodic.py gaussian C=1 Nx=100 loc=0 T=4
cd ..

name=periodic_Nx100_C1_l0.3
mkdir $name
cd $name
python $dir/periodic.py gaussian C=1 Nx=100 loc=0.3 T=4
cd ..

# Perturb C in open boundary condition
cp $name/$dir/periodic.py periodic_error.py
dir=..
doconce replace 'C*(u_1[Nx] - u_1[Nx-1])' '0.8*C*(u_1[Nx] - u_1[Nx-1])' periodic_error.py

name=periodic_error_Nx100_C1_l0.3
mkdir $name
cd $name
python $dir/periodic_error.py gaussian C=1 Nx=100 loc=0.3 T=4
cd ..
