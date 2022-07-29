#!/bin/bash
#SBATCH --job-name=GdN-FCC_sfc_qe71MOD
#SBATCH --time=00-00:20:00
#SBATCH --output=/nfs/home/trewicedwa/logs/GdN-FCC_sfc_qe71MOD.out
#SBATCH --error=/nfs/home/trewicedwa/logs/GdN-FCC_sfc_qe71MOD.err
#SBATCH --partition=parallel
#SBATCH --ntasks=64
#SBATCH --cpus-per-task=1
#SBATCH --tasks-per-node=32
#SBATCH --mem-per-cpu=1G
#SBATCH --nodes=2
#SBATCH --constraint="AMD"

module load intel/2022a
module load QuantumESPRESSO/7.1

mpirun -np 64 pw.x -npool 4 -in /nfs/home/trewicedwa/qe/GdN-FCC_sfc.in > /nfs/home/trewicedwa/qe/GdN-FCC_sfcMOD.out
