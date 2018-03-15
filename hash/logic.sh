#!/bin/bash

_bitwise ()
{
    local num1="$1" num2="$2" max_len i rem

    if (( ${#num1} > ${#num2} )); then
        max_len="${#num1}"
        printf -v num2 "%0${max_len}s" "${num2}"
        num2="${num2// /0}"
    else
        max_len="${#num2}"
        printf -v num1 "%0${max_len}s" "${num1}";
        num1="${num1// /0}"
    fi

    rem=$(( ${max_len} % 16 ))
    for ((i=0; i<${max_len}-${rem}; i+=16 ))
    do
        printf "%016X" "$(( 0x${num1:${i}:16} ${3} 0x${num2:${i}:16} ))"
    done
    if (( ${rem} )); then
        printf "%0${rem}X" "$(( 0x${num1:${i}} ${3} 0x${num2:${i}} ))"
    fi
    echo
}

bwor ()
{
    _bitwise "$1" "$2" '|'
}

bwand ()
{
    _bitwise "$1" "$2" '&'
}

bwxor ()
{
    _bitwise "$1" "$2" '^'
}
