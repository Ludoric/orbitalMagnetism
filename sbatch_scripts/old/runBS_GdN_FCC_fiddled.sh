#!/bin/bash
#SBATCH --job-name=fd_tst_2
#SBATCH --time=00-02:00:00
#SBATCH --output=/nfs/scratch/trewicedwa/GdN_converg_test/logs/converg_test_GdN-FCC_fd3.out
#SBATCH --error=/nfs/scratch/trewicedwa/GdN_converg_test/logs/converg_test_GdN-FCC_fd3.err
#SBATCH --partition=parallel
#SBATCH --ntasks=64
#SBATCH --cpus-per-task=1
#SBATCH --tasks-per-node=32
#SBATCH --mem-per-cpu=1G
#SBATCH --nodes=2
#SBATCH --constraint="AMD"

module load intel/2022.00

SRC="/nfs/home/trewicedwa/"
SCRA="/nfs/scratch/trewicedwa/GdN_converg_test/"
TMP_FLE=$SCRA"tmpfd.in"
INPUTF="${SRC}qe/blankSpaces_GdN-FCC.in" 
OUTPUTF="${SCRA}converg_test_GdN-FFC_fd3.txt"
TITLEPREF="CT-GdN-FCC-fd3"

for ECUTWFC in 45 50 55 60 65 70 75 80 85 90 95 100
do
    for RHOFACTOR in 4000 # Just pretend we have decimals
    do
        for K in 7
        do
           ECUTRHO=$((ECUTWFC*RHOFACTOR/1000))
           
           R_TITLE="${TITLEPREF}_${ECUTWFC}_rho${ECUTRHO}_k${K}"
           COUTPUTF="${SCRA}${R_TITLE}.out"
           
           sed -e"s/%title%/$R_TITLE/g; s+%outdir%+${SCRA}out/+g;" \
               -e "s/%ecutrho%/$ECUTRHO/g; s/%ecutwfc%/$ECUTWFC/g;" \
               -e "s/%k%/$K/g" $INPUTF > $TMP_FLE
           
           mpirun -np 64 "${SRC}qe-7.1_fiddled/bin/pw.x" -npool 4 \
	       -in $TMP_FLE > $COUTPUTF
           
           # deal with this bullshit later:
           echo $COUTPUTF >> $OUTPUTF
           echo "ecutwfc ${ECUTWFC} ecutrho ${ECUTRHO} k ${K}" >> $OUTPUTF
           tac $COUTPUTF | grep -m 1 '!    total energy' >> $OUTPUTF
           tac $COUTPUTF | grep -m 1 'the Fermi energy is' >> $OUTPUTF
           tac $COUTPUTF | grep -m 1 'total   stress' >> $OUTPUTF
           # printf '========%.0s' {1..10} >> $OUTPUTF
           echo -e "\n\n" >> $OUTPUTF

        done
    done
done
