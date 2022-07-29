#!/bin/bash
#SBATCH --job-name=band_GdN-FCC
#SBATCH --time=00-00:20:00
#SBATCH --output=/nfs/scratch2/trewicedwa/GdN_relax_band/logs/band_GdN-FCC.out
#SBATCH --error=/nfs/scratch2/trewicedwa/GdN_relax_band/logs/band_GdN-FCC.err
#SBATCH --partition=parallel
#SBATCH --ntasks=64
#SBATCH --cpus-per-task=1
#SBATCH --tasks-per-node=32
#SBATCH --mem-per-cpu=1G
#SBATCH --nodes=2
#SBATCH --constraint="AMD"


module load intel/2022a
module load QuantumESPRESSO/7.1

SRC="/nfs/home/trewicedwa/orbitalMagnetism"
# SRC=$(dirname $(dirname $(realpath ${BASH_SOURCE})))
SCRATCH="/nfs/scratch2/trewicedwa/GdN_relax_band"


PWTEMPLATE="${SRC}/templates/BS2_GdN-FCC.in"
BANDSTEMPLATE="${SRC}/templates/BS_bands.in"
R_TITLE='bands2_GdN-FCC'

PREFIX='relax_GdN-FCC'
ECUTRHO=320
ECUTWFC=80
CALCULATION='bands'
NBND=25



PWIOPUT="${SCRATCH}/${R_TITLE}.pw"

sed -e "s/%title%/$R_TITLE/g; s+%outdir%+${SCRATCH}/out/+g;" \
    -e "s+%pseudo_dir%+${SRC}/pseudo/+g; s/%prefix%/${PREFIX}/g;" \
    -e "s/%ecutrho%/${ECUTRHO}/g; s/%ecutwfc%/${ECUTWFC}/g;" \
    -e "s/%nbnd%/${NBND}/g; s/%calculation%/${CALCULATION}/g;" \
    $PWTEMPLATE > $PWIOPUT'.in'

cat "${SRC}/py_scripts/kpoints2.txt" >> $PWIOPUT'.in'

mpirun -np 64 pw.x -npool 4 -in $PWIOPUT'.in' > $PWIOPUT'.out'


for SPIN in 1 2
do
    BANDSIOPUT="${SCRATCH}/${R_TITLE}-S${SPIN}.bands"

    sed -e "s/%prefix%/$PREFIX/g; s+%outdir%+$SCRATCH/out/+g;" \
        -e "s+%filband%+${BANDSIOPUT}+g; s/%spin_component%/$SPIN/g;" \
        $BANDSTEMPLATE > $BANDSIOPUT'.in'

    bands.x < $BANDSIOPUT'.in' > $BANDSIOPUT'.out'
done
