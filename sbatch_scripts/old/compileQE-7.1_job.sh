#!/bin/bash
#SBATCH --job-name=QE_build_71
#SBATCH --time=00-01:00:00
#SBATCH --output=logs/qe-71compile.out
#SBATCH --error=logs/qe-71compile.err
#SBATCH --partition=parallel
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --tasks-per-node=1
#SBATCH --mem-per-cpu=2GB
#SBATCH --nodes=1
#SBATCH --constraint="AMD"

module load intel/2022.00

cd qe-7.1/
make clean
./configure > configure.out
make all export MKL_DEBUG_CPU_TYPE=5 export MKL_CBWR=AUTO
