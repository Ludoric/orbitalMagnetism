#!/bin/bash
#SBATCH --job-name=GdN_TED
#SBATCH --time=00-05:00:00
#SBATCH --output=/nfs/scratch/trewicedwa/GdN_TED/log_GdN_TED.out
#SBATCH --error=/nfs/scratch/trewicedwa/GdN_TED/log_GdN_TED.err
#SBATCH --partition=quicktest
#SBATCH --ntasks=128
#SBATCH --cpus-per-task=1
#SBATCH --tasks-per-node=64
#SBATCH --mem-per-cpu=1G
#SBATCH --nodes=2

# mkdir "/nfs/scratch/trewicedwa/GdN_TED/"
# mkdir "/nfs/scratch/trewicedwa/GdN_TED/out"
cd "/nfs/scratch/trewicedwa/GdN_TED/"
cp /nfs/home/trewicedwa/orbitalMagnetism/oneOffCalcs/GdN_TED/* ./

# BINLOC="/nfs/home/trewicedwa/qe-7.0/bin"

# module load intel/2021b
module load intel/2022a
module load QuantumESPRESSO/7.1


# TODO:
# Currently need to get (matching) pseudopotentials of the right kind
# Right kind =
#   Fully relativisitic
#   PBEsol
#   PAW (not ultra-soft)
#   Includes the 4f electrons in the valence set
#   Preferably fully relativistic
# Try using pbe instead of pbesol, or setting everything to pbe?
#
# (output currently reports "Error in routine set_dft_from_name (4):\n\t conflicting values for igcx")



# Run pw to obtain the ground state
mpirun -np 64 pw.x -npool 8 -in GdN_vc-relax.pw.in > GdN_vc-relax.pw.out
# Run pw to obtain the Bloch states on a uniform k-point grid
# !!! use the lattice output from vc-relax as input to scf and wannier90
# mpirun -np 64 "$BINLOC/pw.x" -npool 4 -in GdN_TED_scf.pw.in > GdN_TED_scf.pw.out
# mpirun -np 64 "$BINLOC/pw.x" -npool 4 -in GdN_TED_nscf.pw.in > GdN_TED_nscf.pw.out
# mpirun -np 64 "$BINLOC/pw.x" -npool 4 -in GdN_TED_bands.pw.in > GdN_TED_bands.pw.out




# # !!! run this section on a single CPU - it'll take a while, but at least will finish
# # BANDS CALCULATIONS in qauntum espresso
# $BINLOC/bands.x < GdN_TED_S1.bands.in >  GdN_TED_S1.bands.out
# $BINLOC/bands.x < GdN_TED_S2.bands.in >  GdN_TED_S2.bands.out
# # Run wannier90 to generate a list of the required overlaps (written into the Fe.nnkp file).
# # !!!! mpi not available for wannier90.x
# $BINLOC/wannier90.x -pp GdN_TED_up > GdN_TED_dw_1.wannier90.out
# $BINLOC/wannier90.x -pp GdN_TED_dw > GdN_TED_dw_1.wannier90.out
# # Run pw2wannier90 to compute:
# # – The overlaps <h_{unk}|u_{mk+bi}> (written in the Fe.mmn file)
# # – The projections for the starting guess (written in the Fe.amn file)
# # – The matrix elements <h_{unk+b1}|H_k|u_{mk+b2i}> (written in the Fe.uHu file)
# # !!!! pools not implemented for pw2wannier90.x
# # !!!! there may not be more processors than bands created in GdN_TED.win
# # !!!! mpi version doesn't support output to .uHu file
# # mpirun -np 25 "$BINLOC/pw2wannier90.x" -in GdN_TED_up.pw2wan.in > GdN_TED_up.pw2wan.out
# # mpirun -np 25 "$BINLOC/pw2wannier90.x" -in GdN_TED_dw.pw2wan.in > GdN_TED_dw.pw2wan.out
# $BINLOC/pw2wannier90.x < GdN_TED_up.pw2wan.in > GdN_TED_up.pw2wan.out
# $BINLOC/pw2wannier90.x < GdN_TED_dw.pw2wan.in > GdN_TED_dw.pw2wan.out
# # Run wannier90 to compute the MLWFs.
# # !!!! mpi not available for wannier90.x
# $BINLOC/wannier90.x GdN_TED_up > GdN_TED_up_2.wannier90.out
# $BINLOC/wannier90.x GdN_TED_dw > GdN_TED_dw_2.wannier90.out


# # !!! run this one on multiple cores again
# # Run postw90 to compute the orbital magnetization
# mpirun -np 64 $BINLOC/postw90.x GdN_TED_up
# mpirun -np 64 $BINLOC/postw90.x GdN_TED_dw
