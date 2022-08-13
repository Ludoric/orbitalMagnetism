#!/bin/bash
#SBATCH --job-name=relax_GdN-FCC
#SBATCH --time=00-00:20:00
#SBATCH --output=/nfs/scratch2/trewicedwa/GdN_relax_band/logs/relax_GdN-FCC.out
#SBATCH --error=/nfs/scratch2/trewicedwa/GdN_relax_band/logs/relax_GdN-FCC.err
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
SCRA="/nfs/scratch2/trewicedwa/GdN_relax_band/"
INPUTF="${SRC}qe/blankSpaces_GdN-FCC.in"
R_TITLE="relax_GdN-FCC"

CINPUTF="${SCRA}${R_TITLE}.in"
COUTPUTF="${SCRA}${R_TITLE}.out"

sed -e"s/%title%/$R_TITLE/g; s+%outdir%+${SCRA}out/+g; s/%ecutrho%/320/g;" \
    -e "s/%ecutwfc%/80/g; s/%k%/14/g; s/%calculation%/relax/g;" \
    $INPUTF > $CINPUTF

mpirun -np 64 pw.x -npool 4 -in $CINPUTF > $COUTPUTF
