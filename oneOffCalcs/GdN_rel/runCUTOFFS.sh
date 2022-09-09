#!/bin/bash
#SBATCH --job-name=CUTOFFS
#SBATCH --time=00-10:00:00
#SBATCH --output=/nfs/scratch/trewicedwa/GdN_rel/log_cutoffs.out
#SBATCH --error=/nfs/scratch/trewicedwa/GdN_rel/log_cutoffs.err
#SBATCH --partition=parallel
#SBATCH --ntasks=64
#SBATCH --cpus-per-task=1
#SBATCH --tasks-per-node=64
#SBATCH --mem-per-cpu=1G
#SBATCH --nodes=1



TEMPLATE="cutoffs_template.pw.in"

OUTDIR="./out_cutoffs/"
PSEUDO_DIR="/nfs/home/trewicedwa/orbitalMagnetism/pseudo/"

A=4.999
GD4F=8.4
GD5D=6.6
# expect ecutrho and ecutwfc to be 769 and 118 respectivly

cd "/nfs/scratch/trewicedwa/GdN_rel/"
cp /nfs/home/trewicedwa/orbitalMagnetism/oneOffCalcs/GdN_rel/* ./
mkdir $OUTDIR



AWKSTR='{
    printf "\tRT: %02d:%02d:%07.4f\n",
        ($1-$2)/3600, ($1-$2)%3600/60, ($1-$2)%60
    }'


module load intel/2022a
module load QuantumESPRESSO/7.1


START=$(date +%s.%N)
for ECUTWFC in $(seq 50 10 140) ; do
    for RHOFACTOR in 4000 ; do  # Just pretend we have decimals
        for K in 14 ; do
            ECUTRHO=$((ECUTWFC*RHOFACTOR/1000))
            PREF="cutoff_${ECUTRHO}_${ECUTWFC}_${K}"
            ST=$(date +%s.%N) ; echo -n $PREF

            sed -e "s+%outdir%+$OUTDIR+g; s+%pseudo_dir%+$PSEUDO_DIR+g;" \
                -e "s/%prefix%/$PREF/g; s/%ecutwfc%/$ECUTWFC/g;" \
                -e "s/%ecutrho%/$ECUTRHO/g; s/%A%/$A/g;" \
                $TEMPLATE > "$PREF.pw.in"

            echo -e "K_POINTS automatic\n$K $K $K 0 0 0" >> "$PREF.pw.in"
            echo -e "HUBBARD ortho-atomic\nU Gd-4F $GD4F\nU Gd-5D $GD5D\n" \
                >> "$PREF.pw.in"

            mpirun -np 64 pw.x -npool 4 -in "$PREF.pw.in" > "$PREF.pw.out"

            echo "$(date +%s.%N) $ST" | awk "$AWKSTR" ; ST=$(date +%s.%N)
        done
    done
done

echo "$(date +%s.%N) $START \nSCRIPT_FINISHED!" | awk "$AWKSTR"

