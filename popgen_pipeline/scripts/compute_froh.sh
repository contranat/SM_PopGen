#!/bin/bash

CHR=$1 #chromosome name
FILE=$2 #path to .hom files
LEN=$3 #chromosome length 

awk -v CHR="$CHR" -v L="$LEN" '
NR==1 { next }
$4==CHR { sum[$2] += ($8 - $7 + 1) }
END {
    for (id in sum)
        printf "%s\t%.6f\n", id, sum[id]/L
}' $FILE

