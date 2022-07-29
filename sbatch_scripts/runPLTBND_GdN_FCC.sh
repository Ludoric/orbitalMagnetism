#!/bin/bash
#SBATCH --job-name=pltband_GdN-FCC
#SBATCH --time=00-00:20:00
#SBATCH --output=/nfs/scratch2/trewicedwa/GdN_relax_band/logs/pltband_GdN-FCC.out
#SBATCH --error=/nfs/scratch2/trewicedwa/GdN_relax_band/logs/pltband_GdN-FCC.err
#SBATCH --partition=parallel
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=4G
#SBATCH --constraint="AMD"

module load intel/2022a
module load QuantumESPRESSO/7.1

# SRC="/nfs/home/trewicedwa/"
SCRA="/nfs/scratch2/trewicedwa/GdN_relax_band/"

bands.x < "${SCRA}B-bands-up_GdN-FCC.in" > "${SCRA}B-bands-up_GdN-FCC.out"
bands.x < "${SCRA}B-bands-down_GdN-FCC.in" > "${SCRA}B-bands-down_GdN-FCC.out"
# plotband.x < "${SCRA}plotband_GdN-FCC.in" > "${SCRA}plotband_GdN-FCC.out"


