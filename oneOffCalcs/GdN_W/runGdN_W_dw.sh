#!/bin/bash
#SBATCH --job-name=GdN_W_dw
#SBATCH --time=00-05:00:00
#SBATCH --output=/nfs/scratch/trewicedwa/GdN_W/log_dw.out
#SBATCH --error=/nfs/scratch/trewicedwa/GdN_W/log_dw.err
#SBATCH --partition=quicktest
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --tasks-per-node=1
#SBATCH --mem-per-cpu=8G
#SBATCH --nodes=1

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
# $BINLOC/bands.x < GdN_B_S2.bands.in >  GdN_B_S2.bands.out
# echo "$(date +%s.%N) $ST GdN_B_S2.bands" | awk "$AWKSTR" ; ST=$(date +%s.%N)
#
# $BINLOC/wannier90.x -pp GdN_W_dw > GdN_W_dw_1.wannier90.out
# echo "$(date +%s.%N) $ST GdN_W_dw_1.wannier90" | awk "$AWKSTR" ; ST=$(date +%s.%N)
#
# $BINLOC/pw2wannier90.x < GdN_W_dw.pw2wan.in > GdN_W_dw.pw2wan.out
# echo "$(date +%s.%N) $ST GdN_W_dw.pw2wan" | awk "$AWKSTR" ; ST=$(date +%s.%N)

$BINLOC/wannier90.x GdN_W_dw > GdN_W_dw_2.wannier90.out
echo "$(date +%s.%N) $ST GdN_W_dw_2.wannier90" | awk "$AWKSTR" ; ST=$(date +%s.%N)

echo "$(date +%s.%N) $START \nSCRIPT_FINISHED!" | awk "$AWKSTR"
