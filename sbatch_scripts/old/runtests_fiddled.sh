#!/bin/bash
#SBATCH --job-name=QE_fiddled_71_runtests
#SBATCH --time=00-02:00:00
#SBATCH --output=logs/qe-71_runtests.out
#SBATCH --error=logs/qe-71_runtests.err
#SBATCH --partition=parallel
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --tasks-per-node=1
#SBATCH --mem-per-cpu=2GB
#SBATCH --nodes=1
#SBATCH --constraint="AMD"

module load intel/2022.00

cd "qe-7.1_fiddled/test-suite"
make run-tests > testoutput.txt
