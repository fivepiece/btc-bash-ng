#!/bin/bash

script_is_bignum ()
{
    if [[ ! ${1} =~ ^-?[0-9]+$ ]]; then
        return 1
    fi
    if (( ( ${1} > -(2**31) ) && ( ${1} < (2**31) )  )); then
        return 0
    else
        return 1
    fi
}

script_is_opnum ()
{
    if [[ ! ${1} =~ ^[0-9][1-6]?$ ]]; then
        return 1
    fi
    if (( ( ${1} >= -1 ) && ( ${1} <= 16 ) )); then
        return 0
    else
        return 1
    fi
}

script_ser_num ()
{
    local -u sernum

    if script_is_opnum "${1}"; then

        echo "0x${op_num[${1}]}"
        return
    fi

    read sernum < <( bc_bitcoin <<<"
        obase=A; ibase=A;
        n=${1};
        obase=16; ibase=16;
        ser_num(n);" )

    read sernum < <( revchunks "${sernum}" )
    data_pushdata "${sernum}"
}

tx_ser_int ()
{
    if (( "${1}" > (2**32)-1 )); then

        echo "error: tx_ser_int: int > 2^32-1" >&2
        return
    fi

    local -u serint

    read serint < <( bc_encode <<<"
        ibase=A;
        num=${1};
        ibase=16;
        left_pad(num, 8);" )
    read serint < <( revchunks "${serint}" )

    echo "${serint}"
}

tx_deser_int ()
{
    local -u int

    read int < <( revchunks "${1}" )
    bc_clean <<<"obase=A; ibase=16; ${int}"
}

num2compsize() {

    local -u size="${1}"

    read size < <( bc_bitcoin <<<"x=${size}; compsize(x);" )

    echo -n "${size:0:2}"
    revchunks <<<"${size:2}"
}

dec2amount() {

    local decimal revamount
    if [[ "${1}" == "" ]]
    then
        read decimal
    else
        decimal="${1}"
    fi

    read revamount < <( bc_encode <<<"
        ibase=A;
        bal=${decimal}*100000000;
        ibase=16;
        left_pad(bal/1,10);" )

    revchunks "${revamount}"
}

amount2dec() {

    local hexamount revamount
    if [[ "${1}" == "" ]]
    then
        read hexamount
    else
        hexamount="${1}"
    fi

    read revamount < <( revchunks "${hexamount}" )

    bc_clean <<<"
        scale=8;
        satoshi=100000000;
        ibase=16;
        print ${revamount}/satoshi, \"\\n\";"
}
