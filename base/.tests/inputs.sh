#!/bin/bash

# prints "SAMPLESAMPLESAM..." of specified length
# $1 : sample to output, will become uppercase (for use with hex)
# $2 : length
input_mkbitmap()
{
    local -u sample="$1" smp bmp
    local -i len="$2"

    printf -v bmp "%0${len}d" '0'
    printf -v smp "%0${#sample}d" '0'

    bmp="${bmp//${smp}/${sample}}"

    local -i rem="$((len % ${#sample}))"
    if (( rem != 0 )); then
        local -u brem srem
        printf -v brem "%0${rem}d" '0'
        srem="${sample:0:${#brem}}"
        bmp="${bmp:0:$((len-rem))}${srem}"
    fi  
    
    printf '%s\n' "${bmp}"
}

# "walks" a pattern across a range
# $1 : pattern
# $2 : range, will become bitmap of specified length
# $3 : length
input_walk_pattern()
{
    local -u patt="$1" range
    read range < <( input_mkbitmap "$2" "$3" )

    for ((i=0; i<=$((${#range}-${#patt})); i++)); do

        printf "${range:0:$i}${patt}${range:$((${#patt}+i))}\n"
    done
}
