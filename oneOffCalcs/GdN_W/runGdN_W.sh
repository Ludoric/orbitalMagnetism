#!/bin/bash
#SBATCH --job-name=GdN_W
#SBATCH --time=04-00:00:00
#SBATCH --output=/nfs/scratch/trewicedwa/GdN_W/log.out
#SBATCH --error=/nfs/scratch/trewicedwa/GdN_W/log.err
#SBATCH --partition=parallel
#SBATCH --ntasks=64
#SBATCH --cpus-per-task=1
#SBATCH --tasks-per-node=64
#SBATCH --mem-per-cpu=800M
#SBATCH --nodes=1

thing_four='true'

# mkdir "/nfs/scratch/trewicedwa/GdN_W/"
# mkdir "/nfs/scratch/trewicedwa/GdN_W/out"
cd "/nfs/scratch/trewicedwa/GdN_W/"
cp /nfs/home/trewicedwa/orbitalMagnetism/oneOffCalcs/GdN_W/* ./

BINLOC="/nfs/home/trewicedwa/qe-7.0/bin"
AWKSTR='{
    printf "%s\t\tRT: %02d:%02d:%07.4f\n",
        $3, ($1-$2)/3600, ($1-$2)%3600/60, ($1-$2)%60
    }'


module load intel/2021b

START=$(date +%s.%N)
ST=$(date +%s.%N)

if [ "$thing_one" = true ]; then
# # Run pw to obtain the ground state
# mpirun -np 64 "$BINLOC/pw.x" -npool 4 -in GdN_vc-relax.pw.in > GdN_vc-relax.pw.out
# echo "$(date +%s.%N) $ST GdN_vc-relax.pw" | awk "$AWKSTR" ; ST=$(date +%s.%N)
# Run pw to obtain the Bloch states on a uniform k-point grid
# !!! use the lattice output from vc-relax as input to scf and wannier90
mpirun -np 64 "$BINLOC/pw.x" -npool 4 -in GdN_W_scf.pw.in > GdN_W_scf.pw.out
echo "$(date +%s.%N) $ST GdN_W_scf.pw" | awk "$AWKSTR" ; ST=$(date +%s.%N)
mpirun -np 64 "$BINLOC/pw.x" -npool 4 -in GdN_W_nscf.pw.in > GdN_W_nscf.pw.out
echo "$(date +%s.%N) $ST GdN_W_nscf.pw" | awk "$AWKSTR" ; ST=$(date +%s.%N)
mpirun -np 64 "$BINLOC/pw.x" -npool 4 -in GdN_B_scf.pw.in > GdN_B_scf.pw.out
echo "$(date +%s.%N) $ST GdN_B_scf.pw" | awk "$AWKSTR" ; ST=$(date +%s.%N)
mpirun -np 64 "$BINLOC/pw.x" -npool 4 -in GdN_B_bands.pw.in > GdN_B_bands.pw.out
echo "$(date +%s.%N) $ST GdN_B_bands.pw" | awk "$AWKSTR" ; ST=$(date +%s.%N)
fi

if [ "$thing_two" = true ]; then
# Run wannier90 to generate a list of the required overlaps (written into the Fe.nnkp file).
# !!!! mpi not available for wannier90.x
$BINLOC/wannier90.x -pp GdN_W_up > GdN_W_up_1.wannier90.out
echo "$(date +%s.%N) $ST GdN_W_up_1.wannier90" | awk "$AWKSTR" ; ST=$(date +%s.%N)
$BINLOC/wannier90.x -pp GdN_W_dw > GdN_W_dw_1.wannier90.out
echo "$(date +%s.%N) $ST GdN_W_dw_1.wannier90" | awk "$AWKSTR" ; ST=$(date +%s.%N)
# Run pw2wannier90 to compute:
# – The overlaps <h_{unk}|u_{mk+bi}> (written in the Fe.mmn file)
# – The projections for the starting guess (written in the Fe.amn file)
# – The matrix elements <h_{unk+b1}|H_k|u_{mk+b2i}> (written in the Fe.uHu file)
# !!!! pools not implemented for pw2wannier90.x
# !!!! there may not be more processors than bands created in GdN_W.win
# !!!! mpi version doesn't support output to .uHu file
mpirun -np 26 "$BINLOC/pw2wannier90.x" -in GdN_W_up.pw2wan.in > GdN_W_up.pw2wan.out
# $BINLOC/pw2wannier90.x < GdN_W_up.pw2wan.in > GdN_W_up.pw2wan.out
echo "$(date +%s.%N) $ST GdN_W_up.pw2wan" | awk "$AWKSTR" ; ST=$(date +%s.%N)
mpirun -np 26 "$BINLOC/pw2wannier90.x" -in GdN_W_dw.pw2wan.in > GdN_W_dw.pw2wan.out
# BINLOC/pw2wannier90.x < GdN_W_dw.pw2wan.in > GdN_W_dw.pw2wan.out
echo "$(date +%s.%N) $ST GdN_W_dw.pw2wan" | awk "$AWKSTR" ; ST=$(date +%s.%N)
fi


if [ "$thing_three" = true ]; then
# !!! run this section on a single CPU - it'll take a while, but at least will finish
# BANDS CALCULATIONS in qauntum espresso
$BINLOC/bands.x < GdN_B_S1.bands.in >  GdN_B_S1.bands.out
echo "$(date +%s.%N) $ST GdN_B_S1.bands" | awk "$AWKSTR" ; ST=$(date +%s.%N)
$BINLOC/bands.x < GdN_B_S2.bands.in >  GdN_B_S2.bands.out
echo "$(date +%s.%N) $ST GdN_B_S2.bands" | awk "$AWKSTR" ; ST=$(date +%s.%N)
# Run wannier90 to compute the MLWFs.
# !!!! mpi not available for wannier90.x
$BINLOC/wannier90.x GdN_W_up > GdN_W_up_2.wannier90.out
echo "$(date +%s.%N) $ST GdN_W_up_2.wannier90" | awk "$AWKSTR" ; ST=$(date +%s.%N)
$BINLOC/wannier90.x GdN_W_dw > GdN_W_dw_2.wannier90.out
echo "$(date +%s.%N) $ST GdN_W_dw_2.wannier90" | awk "$AWKSTR" ; ST=$(date +%s.%N)
fi


if [ "$thing_four" = true ]; then
ST=$(date +%s.%N)
# !!! run this one on multiple cores again
# Run postw90 to compute the orbital magnetization
mpirun -np 64 $BINLOC/postw90.x GdN_W_up
echo "$(date +%s.%N) $ST postw90.x-GdN_W_up" | awk "$AWKSTR" ; ST=$(date +%s.%N)
mpirun -np 64 $BINLOC/postw90.x GdN_W_dw
echo "$(date +%s.%N) $ST postw90.x-GdN_W_dw" | awk "$AWKSTR"
fi

echo "$(date +%s.%N) $START \nSCRIPT_FINISHED!" | awk "$AWKSTR"
