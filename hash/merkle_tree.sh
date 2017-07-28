#!/bin/bash

revbytes_list ()
{
    local -a listrev=( $@ )
    for (( i=0; i<${#listrev[@]}; i++ )); do
        revchunks "${listrev[$i]}"
    done
}

merkle_root ()
{
    local -au list=( $@ )
    local tlist=( ${list[@]} ) nlist=()

    while (( ${#tlist[@]} != 1 )); do
        if (( ${#tlist[@]} % 2 == 1 )); then
            tlist+=( ${tlist[-1]} )
        fi
        nlist=()
        for (( i=0, j=0; i<${#tlist[@]}; i+=2, j++ )); do
            read nlist[$j] < <( hash256 "${tlist[$i]}${tlist[$((i+1))]}" )
        done
        tlist=( ${nlist[@]} )
    done
    echo ${tlist[@]}
}

core_merkle_root ()
{
    local -au revlist
    readarray -t revlist < <( revbytes_list $@ )
    merkle_root ${revlist[@]} | revchunks
}
