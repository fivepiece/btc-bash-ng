#!/bin/bash

# functions from
# https://tools.ietf.org/html/rfc6979#section-2.3

# 2.3.2
# convert a string of bits {1,0} to a positive integer of qlen/8 bytes
# or a simple base 2->16 conversion if $2 is not provided
# $1 : bit string
# $2 : length of q in bits
bits2int()
{
    local iseq="$1"
    local -i blen="${#iseq}"
    local -i qlen="${2:-${blen}}"
    local -u oint

    # do the first part of step (1) first
    if (( qlen < blen )); then
        iseq="${iseq:0:${qlen}}"
    fi

    # step (2)
    read oint < <( bc_clean <<<"obase=16; ibase=2; ${iseq};" )

    # second part of step (1)
    # use qlen/4 as oint is now made of words
    if (( ${#oint} < (qlen/4) )); then
        lpadhexstr "${oint}" "$(( (qlen/4)-${#oint} ))"
    else
        printf '%s\n' "${oint}"
    fi
}

# 2.3.3
# converts an integer to an word\octet string of some length of bits
# $1 : integer
# $2 : length of q in bits
int2octets()
{
    local -u iseq="$1" oseq
    local -i qlen="$2" rlen
    [[ -z "$2" ]] && return 1

    # TODO maybe better to lose the multipliers
    (( qlen*8 < ${#iseq}*4 )) && return 1

    read rlen < <( int_ceil "${qlen}/8" )
    (( rlen *= 8 ))

    # echo "rlen : ${rlen}"
    lpadhexstr "${iseq}" "$(( (rlen/4)-${#iseq} ))"
}

# 2.3.4
# converts a string of bits to an octet string
# $1 : bit string
# $2 : q in hex ( q is a large prime )
bits2octets()
{
    local b="$1" q="$2"
    local -i blen="${#b}" qlen="$(( ${#q}*4 ))"
    local -u z1 z2

    # 2.3.4.1
    read z1 < <( bits2int "$b" "${qlen}" )
    # 2.3.4.2
    read z2 < <( bc_clean <<<"
        obase=16;
        ibase=16;
        if ( (${z1}-${q})<0 ){
            ${z1};
        } else {
            ${z1}-${q};
        };"
    )

    # 2.3.4.3
    int2octets "${z2}" "${qlen}"
}
