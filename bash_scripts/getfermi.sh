#!/bin/bash

IN='tooBig/hubbard2Out/*.pw.out'
OUT="tooBig/hubbard2Out/fermi.tsv"
echo -e "hubbardU\tTotalE\tFermiE\tTotalS" > $OUT
for F in $IN ; do
    readarray -d _ -t Farr <<< "$F"
    tE=($(tac $F | grep -m 1 '!    total energy'))
    fE=($(tac $F | grep -m 1 'the Fermi energy is'))
    tS=($(tac $F | grep -m 1 'total   stress'))
    echo -e "${Farr[-2]}\t${tE[-2]}\t${fE[-2]}\t${tS[-1]}" >> $OUT
done
