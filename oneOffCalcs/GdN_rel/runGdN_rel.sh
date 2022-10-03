#!/bin/bash
#SBATCH --job-name=GdN_rel
#SBATCH --time=10-00:00:00
#SBATCH --output=/nfs/scratch/trewicedwa/GdN_rel/log_GdN_rel.out
#SBATCH --error=/nfs/scratch/trewicedwa/GdN_rel/log_GdN_rel.err
#SBATCH --partition=parallel
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --tasks-per-node=1
#SBATCH --mem-per-cpu=1G
#SBATCH --nodes=1

# mkdir "/nfs/scratch/trewicedwa/GdN_rel/"
cd "/nfs/scratch/trewicedwa/GdN_rel/"
cp /nfs/home/trewicedwa/orbitalMagnetism/oneOffCalcs/GdN_rel/* ./
# mkdir out


thing_one="false"
thing_two="true"
thing_three="false"


module load intel/2022a
module load QuantumESPRESSO/7.1

AWKSTR='{
printf "%s\t\tRT: %02d:%02d:%07.4f\n",
$3, ($1-$2)/3600, ($1-$2)%3600/60, ($1-$2)%60
}'


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


START=$(date +%s.%N)

if [ "$thing_one" = true ]; then
ST=$(date +%s.%N)
# Run pw to obtain the ground state
# mpirun -np 64 pw.x -npool 4 -in GdN_vc-relax.pw.in > GdN_vc-relax.pw.out
# echo "$(date +%s.%N) $ST GdN_vc-relax.pw" | awk "$AWKSTR" ; ST=$(date +%s.%N)
# Run pw to obtain the Bloch states on a uniform k-point grid
# !!! use the lattice output from vc-relax as input to scf and wannier90
mpirun -np 64 pw.x -npool 4 -in GdN_rel_scf.pw.in > GdN_rel_scf.pw.out
echo "$(date +%s.%N) $ST GdN_rel_scf.pw" | awk "$AWKSTR" ; ST=$(date +%s.%N)
mkdir out_B
cp -R out/* out_B/
mpirun -np 64 pw.x -npool 4 -in GdN_rel_nscf.pw.in > GdN_rel_nscf.pw.out
echo "$(date +%s.%N) $ST GdN_rel_nscf.pw" | awk "$AWKSTR" ; ST=$(date +%s.%N)

#mpirun -np 64 pw.x -npool 4 -in GdN_Brel_scf.pw.in > GdN_Brel_scf.pw.out
#echo "$(date +%s.%N) $ST GdN_Brel_scf.pw" | awk "$AWKSTR" ; ST=$(date +%s.%N)
mpirun -np 64 pw.x -npool 4 -in GdN_Brel_bands.pw.in > GdN_Brel_bands.pw.out
echo "$(date +%s.%N) $ST GdN_Brel_bands.pw" | awk "$AWKSTR"
fi


if [ "$thing_two" = true ]; then
ST=$(date +%s.%N)
# # !!! run this section on a single CPU - it'll take a while, but at least will finish
# # BANDS CALCULATIONS in qauntum espresso
# bands.x < GdN_Brel.bands.in >  GdN_Brel.bands.out
# echo "$(date +%s.%N) $ST GdN_Brel.bands" | awk "$AWKSTR" ; ST=$(date +%s.%N)
# # Run wannier90 to generate a list of the required overlaps (written into the Fe.nnkp file).
# # !!!! mpi not available for wannier90.x
wannier90.x -pp GdN_rel > GdN_rel_1.wannier90.out
echo "$(date +%s.%N) $ST GdN_rel_1.wannier90" | awk "$AWKSTR" ; ST=$(date +%s.%N)
# Run pw2wannier90 to compute:
# – The overlaps <h_{unk}|u_{mk+bi}> (written in the Fe.mmn file)
# – The projections for the starting guess (written in the Fe.amn file)
# – The matrix elements <h_{unk+b1}|H_k|u_{mk+b2i}> (written in the Fe.uHu file)
# !!!! pools not implemented for pw2wannier90.x
# !!!! there may not be more processors than bands created in GdN_rel.win
# !!!! mpi version doesn't support output to .uHu file
# mpirun -np 25 "pw2wannier90.x" -in GdN_rel.pw2wan.in > GdN_rel.pw2wan.out
# mpirun -np 25 "pw2wannier90.x" -in GdN_rel_dw.pw2wan.in > GdN_rel_dw.pw2wan.out
pw2wannier90.x < GdN_rel.pw2wan.in > GdN_rel.pw2wan.out
echo "$(date +%s.%N) $ST GdN_rel.pw2wan" | awk "$AWKSTR" ; ST=$(date +%s.%N)
# Run wannier90 to compute the MLWFs.
# !!!! mpi not available for wannier90.x
wannier90.x GdN_rel > GdN_rel_2.wannier90.out
echo "$(date +%s.%N) $ST GdN_rel_2.wannier90" | awk "$AWKSTR" ; ST=$(date +%s.%N)
fi


if [ "$thing_three" = true ]; then
ST=$(date +%s.%N)
# !!! run this one on multiple cores again
# Run postw90 to compute the orbital magnetization
mpirun -np 64 postw90.x GdN_rel
echo "$(date +%s.%N) $ST postw90.x-GdN_rel" | awk "$AWKSTR" ; ST=$(date +%s.%N)
fi

echo "$(date +%s.%N) $START \nSCRIPT_FINISHED!" | awk "$AWKSTR"

