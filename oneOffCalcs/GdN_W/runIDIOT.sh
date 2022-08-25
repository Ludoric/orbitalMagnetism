#!/bin/bash
#SBATCH --job-name=IDIOT
#SBATCH --time=00-05:00:00
#SBATCH --output=/nfs/scratch/trewicedwa/GdN_W/log_IDIOT.out
#SBATCH --error=/nfs/scratch/trewicedwa/GdN_W/log_IDOT.err
#SBATCH --partition=quicktest
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --tasks-per-node=1
#SBATCH --mem-per-cpu=1G
#SBATCH --nodes=1


cd "/nfs/scratch/trewicedwa/GdN_W/"
cp /nfs/home/trewicedwa/orbitalMagnetism/oneOffCalcs/GdN_W/* ./

BINLOC="/nfs/home/trewicedwa/qe-7.0/bin"

module load intel/2021b

$BINLOC/bands.x < GdN_B_S1.bands.in >  GdN_B_S1.bands.out
$BINLOC/bands.x < GdN_B_S2.bands.in >  GdN_B_S2.bands.out

