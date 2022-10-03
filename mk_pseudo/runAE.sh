#!/bin/bash 
#SBATCH --job-name=Gd.AE
#SBATCH --time=00-05:00:00
#SBATCH --output=log.out
#SBATCH --error=log.err
#SBATCH --partition=quicktest
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --tasks-per-node=1
#SBATCH --mem-per-cpu=1G
#SBATCH --nodes=1

module load intel/2022a
module load QuantumESPRESSO/7.1

# mpirun -np 64 ld1.x -npool 4 -in Gd.AE.in  > Gd.AE.out
mpirun -np 1 ld1.x -npool 1 -in Gd.rel-pbesol-spdfn-kjpaw_Etrewick.1.0.in > Gd.rel-ppgen.out

