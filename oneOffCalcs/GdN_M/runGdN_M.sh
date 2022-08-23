#!/bin/bash
#SBATCH --job-name=GdN_M
#SBATCH --time=00-02:00:00
#SBATCH --output=/nfs/scratch/trewicedwa/GdN_M/log_GdN_M.out
#SBATCH --error=/nfs/scratch/trewicedwa/GdN_M/log_GdN_M.err
#SBATCH --partition=quicktest
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --tasks-per-node=1
#SBATCH --mem-per-cpu=2G
#SBATCH --nodes=1

# mkdir "/nfs/scratch/trewicedwa/GdN_M/"
# mkdir "/nfs/scratch/trewicedwa/GdN_M/out"
cd "/nfs/scratch/trewicedwa/GdN_M/"
cp /nfs/home/trewicedwa/orbitalMagnetism/oneOffCalcs/GdN_M/* ./

BINLOC="/nfs/home/trewicedwa/qe-7.0/bin"

module load intel/2021b



# Run pw to obtain the ground state
# mpirun -np 64 "$BINLOC/pw.x" -npool 4 -in GdN_vc-relax.pw.in | tee GdN_vc-relax.pw.out
# Run pw to obtain the Bloch states on a uniform k-point grid
# !!! use the lattice output from vc-relax as input to scf and wannier90
# mpirun -np 64 "$BINLOC/pw.x" -npool 4 -in GdN_M_scf.pw.in | tee GdN_M_scf.pw.out
# mpirun -np 64 "$BINLOC/pw.x" -npool 4 -in GdN_M_nscf.pw.in | tee GdN_M_nscf.pw.out
# mpirun -np 64 "$BINLOC/pw.x" -npool 4 -in GdN_M_bands.pw.in | tee GdN_M_bands.pw.out
# mpirun -np 64 "$BINLOC/pw.x" -npool 4 -in GdN_M_nscf.pw.in | tee GdN_M_nscf.pw.out



# # !!! run this section on a single CPU - it'll take a while, but at least will finish
# # BANDS CALCULATIONS in qauntum espresso
# # $BINLOC/bands.x < GdN_M_S1.bands.in | tee  GdN_M_S1.bands.out
# # $BINLOC/bands.x < GdN_M_S2.bands.in | tee  GdN_M_S2.bands.out
# # Run wannier90 to generate a list of the required overlaps (written into the Fe.nnkp file).
# # !!!! mpi not available for wannier90.x
# $BINLOC/wannier90.x -pp GdN_M_up | tee GdN_M_up_1.wannier90.out
# $BINLOC/wannier90.x -pp GdN_M_dw | tee GdN_M_dw_1.wannier90.out
# # Run pw2wannier90 to compute:
# # – The overlaps <h_{unk}|u_{mk+bi}| tee (written in the Fe.mmn file)
# # – The projections for the starting guess (written in the Fe.amn file)
# # – The matrix elements <h_{unk+b1}|H_k|u_{mk+b2i}| tee (written in the Fe.uHu file)
# # !!!! pools not implemented for pw2wannier90.x
# # !!!! there may not be more processors than bands created in GdN_M.win
# # !!!! mpi version doesn't support output to .uHu file
# # mpirun -np 25 "$BINLOC/pw2wannier90.x" -in GdN_M_up.pw2wan.in | tee GdN_M_up.pw2wan.out
# # mpirun -np 25 "$BINLOC/pw2wannier90.x" -in GdN_M_dw.pw2wan.in | tee GdN_M_dw.pw2wan.out
# $BINLOC/pw2wannier90.x < GdN_M_up.pw2wan.in | tee GdN_M_up.pw2wan.out
# $BINLOC/pw2wannier90.x < GdN_M_dw.pw2wan.in | tee GdN_M_dw.pw2wan.out
# # Run wannier90 to compute the MLWFs.
# # !!!! mpi not available for wannier90.x
$BINLOC/wannier90.x GdN_M_up | tee GdN_M_up_2.wannier90.out
$BINLOC/wannier90.x GdN_M_dw | tee GdN_M_dw_2.wannier90.out


# # !!! run this one on multiple cores again
# # Run postw90 to compute the orbital magnetization
# mpirun -np 64 $BINLOC/postw90.x GdN_M_up
# mpirun -np 64 $BINLOC/postw90.x GdN_M_dw
