#!/bin/bash
#SBATCH --job-name=GdN_M
#SBATCH --time=00-12:00:00
#SBATCH --output=/nfs/scratch/trewicedwa/GdN_M/log_GdN_M.out
#SBATCH --error=/nfs/scratch/trewicedwa/GdN_M/log_GdN_M.err
#SBATCH --partition=parallel
#SBATCH --ntasks=64
#SBATCH --cpus-per-task=1
#SBATCH --tasks-per-node=32
#SBATCH --mem-per-cpu=1G
#SBATCH --nodes=2
#SBATCH --constraint="AMD"

mkdir '/nfs/scratch/trewicedwa/GdN_M/'
mkdir '/nfs/scratch/trewicedwa/GdN_M/out'
cd '/nfs/scratch/trewicedwa/GdN_M/'
cp '/nfs/home/trewicedwa/orbitalMagnetism/oneOffCalcs/GdN_M/*' ./

BINLOC="/nfs/home/trewicedwa/qe-7.0/bin"

module load intel/2021b



# Run pw to obtain the ground state
mpirun -np 64 '$BINLOC/pw.x' -npool 4 -in Gd_M_vc-relax.pw.in > Gd_M_vc-relax.pw.out
# Run pw to obtain the Bloch states on a uniform k-point grid
mpirun -np 64 '$BINLOC/pw.x' -npool 4 -in Gd_M_nscf.pw.in > Gd_M_nscf.pw.out
# Run wannier90 to generate a list of the required overlaps (written into the Fe.nnkp file).
mpirun -np 64 '$BINLOC/wannier90.x -pp GdN_M' -npool 4
# Run pw2wannier90 to compute:
# – The overlaps <h_{unk}|u_{mk+bi}> (written in the Fe.mmn file)
# – The projections for the starting guess (written in the Fe.amn file)
# – The matrix elements <h_{unk+b1}|H_k|u_{mk+b2i}> (written in the Fe.uHu file)
$BINLOC/pw2wannier90.x < GdN_M.pw2wan.in > GdN_M.pw2wan.out
# mpirun -np 64 pw2wannier90.x -npool 4 -in Fe.pw2wan > pw2wan.out
# Run wannier90 to compute the MLWFs.
mpirun -np 64 'wannier90.x GdN_M' -npool 4
# # Run postw90 to compute the orbital magnetization.
# # postw90.x Fe # (serial execution)
mpirun -np 64 'postw90.x GdN_M' -npool 4
