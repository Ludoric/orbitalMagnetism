#!/bin/bash
#SBATCH --job-name=CT_GdN-FCC_4
#SBATCH --time=00-02:00:00
#SBATCH --output=/nfs/scratch/trewicedwa/GdN_converg_test/logs/converg_test_GdN-FCC_4.out
#SBATCH --error=/nfs/scratch/trewicedwa/GdN_converg_test/logs/converg_test_GdN-FCC_4.err
#SBATCH --partition=parallel
#SBATCH --ntasks=64
#SBATCH --cpus-per-task=1
#SBATCH --tasks-per-node=32
#SBATCH --mem-per-cpu=1G
#SBATCH --nodes=2
#SBATCH --constraint="AMD"

module load intel/2022a
module load QuantumESPRESSO/7.1


SRC="/nfs/home/trewicedwa/"
SCRA="/nfs/scratch/trewicedwa/GdN_converg_test/"
INPUTF="${SRC}qe/blankSpaces_GdN-FCC.in"
OUTPUTF="${SCRA}converg_test_GdN-FFC_4.tsv"
TITLEPREF="CT-GdN-FCC-4"


echo -e "ecutwfc\tecutrho\tk\ttotalE\tfermiE\ttotalS\tname" > $OUTPUTF

for ECUTWFC in 80
do
    for RHOFACTOR in 4
    do
        for K in 14
        do
           ECUTRHO=`echo "$ECUTWFC $RHOFACTOR" | awk '{printf "%.4f", $1*$2}'`
           # seq 1.0 .01 1.1 # for example is easier

           R_TITLE="${TITLEPREF}_${ECUTWFC}_rho${ECUTRHO}_k${K}"
           CINPUTF="${SCRA}${R_TITLE}.in"
           COUTPUTF="${SCRA}${R_TITLE}.out"

           sed -e"s/%title%/$R_TITLE/g; s+%outdir%+${SCRA}out/+g;" \
               -e "s/%ecutrho%/$ECUTRHO/g; s/%ecutwfc%/$ECUTWFC/g;" \
               -e "s/%calculation%/scf/g" \
               -e "s/%k%/$K/g" $INPUTF > $CINPUTF

           mpirun -np 64 pw.x -npool 4 -in $CINPUTF > $COUTPUTF


           # and write the parameters desired to a table
           tE=($(tac $COUTPUTF | grep -m 1 '!    total energy'))
           fE=($(tac $COUTPUTF | grep -m 1 'the Fermi energy is'))
           tS=($(tac $COUTPUTF | grep -m 1 'total   stress'))
           echo -e "$ECUTWFC\t$ECUTRHO\t$K\t${tE[-2]}\t${fE[-2]}\t${tS[-1]}\t"\
               "${R_TITLE}.out" >> $OUTPUTF

        done
    done
done
