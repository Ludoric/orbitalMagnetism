#!/bin/bash
#SBATCH --job-name=relax+U_GdN-FCC
#SBATCH --time=00-08:00:00
#SBATCH --output=/nfs/scratch2/trewicedwa/GdN_hubbard/logs/hubbard1.out
#SBATCH --error=/nfs/scratch2/trewicedwa/GdN_hubbard/logs/hubbard1.err
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
SCRATCH="/nfs/scratch2/trewicedwa/GdN_hubbard"


PWTEMPLATE="${SRC}/templates/BS2_GdN-FCC.pw.in"
BANDSTEMPLATE="${SRC}/templates/BS_bands.bands.in"
DOSTEMPLATE="${SRC}/templates/BS.dos.in"


PREFIX='hubbard'
HUBBARD="HUBBARD (ortho-atomic)\nU Gd-4f "
ECUTRHO=320
ECUTWFC=80

R_CALCULATION='relax'
R_NBND=16
R_K_FILE="${SRC}/templates/relax_k_BS.txt"
R_K=14
OCCUPATIONS='smearing'
NOSYM='false'

B_CALCULATION='bands'
B_NBND=25
B_K_FILE="${SRC}/templates/kpoints.txt" # actually, are you sure about that????

D_CALCULATION='nscf'
D_NBND=25
D_K_FILE="${SRC}/templates/relax_k_BS.txt"
D_K=21
D_OCCUPATIONS='tetrahedra'
D_NOSYM='true'


DO_PW_RELAX=0
DO_PW_BANDS=0
DO_BANDS=0
DO_PW_DOS=1
DO_DOS=1


for HU_GD_4F in $(seq -1.0 0.25 15.0)
do
    echo -e "Gd-4f: ${HU_GD_4F}" # NEW CALCULATION
    TITLE="H_Gd4f_${HU_GD_4F}_GdN-FCC"

    if [$DO_PW_RELAX] ; then
        RPWIOPUT="${SCRATCH}/${R_CALCULATION}${TITLE}.pw"
        echo -e "\tPW:relax   \t${RPWIOPUT}" # NEW CALCULATION
        sed -e "s/%title%/$TITLE/g; s+%outdir%+${SCRATCH}/out/+g;" \
            -e "s+%pseudo_dir%+${SRC}/pseudo/+g; s/%prefix%/${PREFIX}/g;" \
            -e "s/%ecutrho%/${ECUTRHO}/g; s/%ecutwfc%/${ECUTWFC}/g;" \
            -e "s/%nbnd%/${R_NBND}/g; s/%calculation%/${R_CALCULATION}/g;" \
            -e "s/%occupations%/${OCCUPATIONS}/g; s/%nosym%/${NOSYM}/g;" \
            $PWTEMPLATE > $RPWIOPUT'.in'

        sed -e "s/%k%/${R_K}/g" $R_K_FILE >> $RPWIOPUT'.in'
        echo -e "${HUBBARD}${HU_GD_4F}\n" >> $RPWIOPUT'.in'

        mpirun -np 64 pw.x -npool 4 -in $RPWIOPUT'.in' > $RPWIOPUT'.out'
    fi

    if [$DO_PW_BANDS] ; then
        BPWIOPUT="${SCRATCH}/${B_CALCULATION}${TITLE}.pw"
        echo -e "\tPW:band    \t${BPWIOPUT}" # NEW CALCULATION
        sed -e "s/%title%/$TITLE/g; s+%outdir%+${SCRATCH}/out/+g;" \
            -e "s+%pseudo_dir%+${SRC}/pseudo/+g; s/%prefix%/${PREFIX}/g;" \
            -e "s/%ecutrho%/${ECUTRHO}/g; s/%ecutwfc%/${ECUTWFC}/g;" \
            -e "s/%nbnd%/${B_NBND}/g; s/%calculation%/${B_CALCULATION}/g;" \
            -e "s/%occupations%/${OCCUPATIONS}/g; s/%nosym%/${NOSYM}/g;" \
            $PWTEMPLATE > $BPWIOPUT'.in'

        cat $B_K_FILE >> $BPWIOPUT'.in'
        echo -e "${HUBBARD}${HU_GD_4F}\n" >> $BPWIOPUT'.in'

        mpirun -np 64 pw.x -npool 4 -in $BPWIOPUT'.in' > $BPWIOPUT'.out'
    fi

    if [$DO_BANDS] ; then
        for SPIN in 1 2
        do
            BANDSIOPUT="${SCRATCH}/${TITLE}-S${SPIN}.bands"
            echo -e "\tBANDS:S${SPIN}   \t${BANDSIOPUT}" # NEW CALCULATION

            sed -e "s/%prefix%/$PREFIX/g; s+%outdir%+$SCRATCH/out/+g;" \
                -e "s+%filband%+${BANDSIOPUT}+g; s/%spin_component%/$SPIN/g;" \
                $BANDSTEMPLATE > $BANDSIOPUT'.in'

            # mpirun -np 64 bands.x -npoop 4 -in  $BANDSIOPUT'.in' > $BANDSIOPUT'.out'
            # running bands.x with mpi seems to cause segfaults. I think this bug is tracked?
            bands.x < $BANDSIOPUT'.in' > $BANDSIOPUT'.out'
        done
    fi

    if [$DO_PW_DOS] ; then
        DPWIOPUT="${SCRATCH}/${D_CALCULATION}${TITLE}.pw"
        echo -e "\tPW:nscf:DOS \t${RPWIOPUT}" # NEW CALCULATION
        sed -e "s/%title%/$TITLE/g; s+%outdir%+${SCRATCH}/out/+g;" \
            -e "s+%pseudo_dir%+${SRC}/pseudo/+g; s/%prefix%/${PREFIX}/g;" \
            -e "s/%ecutrho%/${ECUTRHO}/g; s/%ecutwfc%/${ECUTWFC}/g;" \
            -e "s/%nbnd%/${D_NBND}/g; s/%calculation%/${D_CALCULATION}/g;" \
            -e "s/%occupations%/${D_OCCUPATIONS}/g; s/%nosym%/${D_NOSYM}/g;" \
            $PWTEMPLATE > $DPWIOPUT'.in'

        sed -e "s/%k%/${D_K}/g" $D_K_FILE >> $DPWIOPUT'.in'
        echo -e "${HUBBARD}${HU_GD_4F}\n" >> $DPWIOPUT'.in'

        mpirun -np 64 pw.x -npool 4 -in $DPWIOPUT'.in' > $DPWIOPUT'.out'
    fi

    if [$DO_DOS] ; then
        DOSIOPUT="${SCRATCH}/${TITLE}.dos"
        echo -e "\tDOS:       \t${DOSIOPUT}" # NEW CALCULATION
        sed -e "s/%prefix%/$PREFIX/g; s+%outdir%+$SCRATCH/out/+g;" \
            -e "s+%fildos%+${BANDSIOPUT}+g;" \
            $DOSTEMPLATE > $DOSIOPUT'.in'

        # I haven't tried this with mpi
        dos.x < $DOSIOPUT'.in' > $DOSIOPUT'.out'
    fi

done
