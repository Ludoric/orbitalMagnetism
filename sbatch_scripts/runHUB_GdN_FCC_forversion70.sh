#!/bin/bash
#SBATCH --job-name=HBx2_GdN-FCC
#SBATCH --time=00-18:00:00
#SBATCH --output=/nfs/scratch2/trewicedwa/GdN_HU1_v70/logs/GdN_HU1_v70.out
#SBATCH --error=/nfs/scratch2/trewicedwa/GdN_HU1_v70/logs/GdN_HU1_v70.err
#SBATCH --partition=parallel
#SBATCH --ntasks=64
#SBATCH --cpus-per-task=1
#SBATCH --tasks-per-node=32
#SBATCH --mem-per-cpu=1G
#SBATCH --nodes=2
#SBATCH --constraint="AMD"

# SRC=$(dirname $(dirname $(realpath ${BASH_SOURCE})))
SRC="/nfs/home/trewicedwa/orbitalMagnetism"
SCRATCH="/nfs/scratch2/trewicedwa/GdN_HU1_v70"
BINLOC="/nfs/home/trewicedwa/qe-7.0/bin"

DO_PW_RELAX=true
DO_PW_BANDS=true
DO_BANDS=true
DO_PW_DOS=false
DO_DOS=false

# set this to true, or nothing will happen when you run it for real
DO_COMPUTE_ANYTHING=false


PWTEMPLATE="${SRC}/templates/BS2_GdN-FCC_forversion70.pw.in"
BANDSTEMPLATE="${SRC}/templates/BS_bands.bands.in"
DOSTEMPLATE="${SRC}/templates/BS.dos.in"

# Prefix should change between cells, the title can change runs of pw.x
# (the title is only of interest to the operator)
PREPREFIX='HB1_v70'
ECUTRHO=320
ECUTWFC=80

R_CALCULATION='vc-relax'
R_K_FILE="${SRC}/templates/relax_k_BS.txt"
R_K=14
NBND=26
OCCUPATIONS='smearing'
NOSYM='false'
HU_GD_5D='1e-5'

B_CALCULATION='bands'
B_K_FILE="${SRC}/templates/kpoints.txt"

D_CALCULATION='nscf'
D_K_FILE="${SRC}/templates/relax_k_BS.txt"
D_K=17
D_OCCUPATIONS='tetrahedra'
D_NOSYM='false'



AWKSTRING='{
    printf "\t\tRT: %02d:%02d:%07.4f\n",
        ($1-$2)/3600, ($1-$2)%3600/60, ($1-$2)%60
    }'

 # apparently this is the "correct/safe" way to do if statements
 #     safety is unnecessary here, but good habits and all that
if [ "$DO_COMPUTE_ANYTHING" = true ]; then
    module load intel/2021b
fi

for HU_GD_4F in $(seq 1.0 0.5 15.0); do
    # The value for prefix must reflect the values looped through
    PREFIX="${PREPREFIX}_Gd4f${HU_GD_4F}"
    TITLE=$PREFIX
    echo -e "Gd-4f: ${HU_GD_4F}" # NEW CELL

    if [ "$DO_PW_RELAX" = true ]; then
        START=$(date +%s.%N)
        RPWIOPUT="${SCRATCH}/${R_CALCULATION}${TITLE}.pw"
        echo -e "\tPW:relax   \t${RPWIOPUT}" # NEW CALCULATION
        sed -e "s/%title%/$TITLE/g; s+%outdir%+${SCRATCH}/out/+g;" \
            -e "s+%pseudo_dir%+${SRC}/pseudo/+g; s/%prefix%/${PREFIX}/g;" \
            -e "s/%ecutrho%/${ECUTRHO}/g; s/%ecutwfc%/${ECUTWFC}/g;" \
            -e "s/%nbnd%/${NBND}/g; s/%calculation%/${R_CALCULATION}/g;" \
            -e "s/%occupations%/${OCCUPATIONS}/g; s/%nosym%/${NOSYM}/g;" \
            $PWTEMPLATE > $RPWIOPUT'.in'

        sed -e "s/%k%/${R_K}/g" $R_K_FILE >> $RPWIOPUT'.in'
        sed -e "s/%Gd-4f%/${HU_GD_4F}/g" \
            -e "s/%Gd-5d%/${HU_GD_5D}/g" \
            $HUBBARD_FILE >> $RPWIOPUT'.in'
        echo "" >> $RPWIOPUT'.in'

        if [ "$DO_COMPUTE_ANYTHING" = true ]; then
            mpirun -np 64 $BINLOC/pw.x -npool 4 -in $RPWIOPUT'.in' > $RPWIOPUT'.out'
        fi
        END=$(date +%s.%N)
        echo "$END $START" | awk "$AWKSTRING"
    fi

    if [ "$DO_PW_BANDS" = true ]; then
        START=$(date +%s.%N)
        BPWIOPUT="${SCRATCH}/${B_CALCULATION}${TITLE}.pw"
        echo -e "\tPW:band    \t${BPWIOPUT}" # NEW CALCULATION
        sed -e "s/%title%/$TITLE/g; s+%outdir%+${SCRATCH}/out/+g;" \
            -e "s+%pseudo_dir%+${SRC}/pseudo/+g; s/%prefix%/${PREFIX}/g;" \
            -e "s/%ecutrho%/${ECUTRHO}/g; s/%ecutwfc%/${ECUTWFC}/g;" \
            -e "s/%nbnd%/${NBND}/g; s/%calculation%/${B_CALCULATION}/g;" \
            -e "s/%occupations%/${OCCUPATIONS}/g; s/%nosym%/${NOSYM}/g;" \
            $PWTEMPLATE > $BPWIOPUT'.in'

        cat $B_K_FILE >> $BPWIOPUT'.in'
        sed -e "s/%Gd-4f%/${HU_GD_4F}/g" \
            -e "s/%Gd-5d%/${HU_GD_5D}/g" \
            $HUBBARD_FILE >> $BPWIOPUT'.in'
            echo "" >> $RPWIOPUT'.in'

        if [ "$DO_COMPUTE_ANYTHING" = true ]; then
            mpirun -np 64 $BINLOC/pw.x -npool 4 -in $BPWIOPUT'.in' > $BPWIOPUT'.out'
        fi
        END=$(date +%s.%N)
        echo "$END $START" | awk "$AWKSTRING"
    fi

    if [ "$DO_BANDS" = true ]; then
        for SPIN in 1 2
        do
            START=$(date +%s.%N)
            BANDSIOPUT="${SCRATCH}/${TITLE}-S${SPIN}.bands"
            echo -e "\tBANDS:S${SPIN}   \t${BANDSIOPUT}" # NEW CALCULATION

            sed -e "s/%prefix%/$PREFIX/g; s+%outdir%+$SCRATCH/out/+g;" \
                -e "s+%filband%+${BANDSIOPUT}+g; s/%spin_component%/$SPIN/g;" \
                $BANDSTEMPLATE > $BANDSIOPUT'.in'

            if [ "$DO_COMPUTE_ANYTHING" = true ]; then
                # mpirun -np 64 bands.x -npoop 4 -in  $BANDSIOPUT'.in' \
                #     > $BANDSIOPUT'.out'
                # running bands.x with mpi seems to cause segfaults.
                #I think this bug is tracked?
                $BINLOC/bands.x < $BANDSIOPUT'.in' > $BANDSIOPUT'.out'
            fi
            END=$(date +%s.%N)
            echo "$END $START" | awk "$AWKSTRING"
        done
    fi

    if [ "$DO_PW_DOS" = true ]; then
        START=$(date +%s.%N)
        DPWIOPUT="${SCRATCH}/${D_CALCULATION}${TITLE}.pw"
        echo -e "\tPW:nscf:DOS \t${DPWIOPUT}" # NEW CALCULATION
        sed -e "s/%title%/$TITLE/g; s+%outdir%+${SCRATCH}/out/+g;" \
            -e "s+%pseudo_dir%+${SRC}/pseudo/+g; s/%prefix%/${PREFIX}/g;" \
            -e "s/%ecutrho%/${ECUTRHO}/g; s/%ecutwfc%/${ECUTWFC}/g;" \
            -e "s/%nbnd%/${NBND}/g; s/%calculation%/${D_CALCULATION}/g;" \
            -e "s/%occupations%/${D_OCCUPATIONS}/g; s/%nosym%/${D_NOSYM}/g;" \
            $PWTEMPLATE > $DPWIOPUT'.in'

        sed -e "s/%k%/${D_K}/g" $D_K_FILE >> $DPWIOPUT'.in'
        sed -e "s/%Gd-4f%/${HU_GD_4F}/g" \
            -e "s/%Gd-5d%/${HU_GD_5D}/g" \
            $HUBBARD_FILE >> $DPWIOPUT'.in'
            echo "" >> $RPWIOPUT'.in'

        if [ "$DO_COMPUTE_ANYTHING" = true ]; then
            mpirun -np 64 $BINLOC/pw.x -npool 4 -in $DPWIOPUT'.in' > $DPWIOPUT'.out'
        fi
        END=$(date +%s.%N)
        echo "$END $START" | awk "$AWKSTRING"
    fi

    if [ "$DO_DOS" = true ]; then
        START=$(date +%s.%N)
        DOSIOPUT="${SCRATCH}/${TITLE}.dos"
        echo -e "\tDOS:       \t${DOSIOPUT}" # NEW CALCULATION
        sed -e "s/%prefix%/$PREFIX/g; s+%outdir%+$SCRATCH/out/+g;" \
            -e "s+%fildos%+${DOSIOPUT}+g;" \
            $DOSTEMPLATE > $DOSIOPUT'.in'

        if [ "$DO_COMPUTE_ANYTHING" = true ]; then
            # I haven't tried this with mpi
            $BINLOC/dos.x < $DOSIOPUT'.in' > $DOSIOPUT'.out'
        fi
        END=$(date +%s.%N)
        echo "$END $START" | awk "$AWKSTRING"
    fi
done
echo -e "\nSCRIPT FINISHED! (you can stop waiting now)"
