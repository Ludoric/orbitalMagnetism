#!/bin/bash

IN='*.pw.out'
OUT="fermi.tsv"
echo -e "5D\t4F\tTotalE\tFermiE\tTotalS" > $OUT
for F in $IN ; do
    readarray -d _ -t Farr <<< "${F//-/_}"
    tE=($(tac $F | grep -m 1 '!    total energy'))
    fE=($(tac $F | grep -m 1 'the Fermi energy is'))
    tS=($(tac $F | grep -m 1 'total   stress'))
    echo -e "${Farr[-4]}\t${Farr[-2]}\t${tE[-2]}\t${fE[-2]}\t${tS[-1]}" >> $OUT
done
