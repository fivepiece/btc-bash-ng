#!/bin/bash

_bitwise ()
{
    local num1="$1" num2="$2" max_len

    if (( ${#num1} > ${#num2} )); then
        max_len="${#num1}"
        printf -v num2 "%0${max_len}s" "${num2}"
        num2="${num2// /0}"
    else
        max_len="${#num2}"
        printf -v num1 "%0${max_len}s" "${num1}";
        num1="${num1// /0}"
    fi

    for ((i=0; i<${max_len}; i+=16 ))
    do
        printf "%016X" "$(( 0x${num1:${i}:16} ${3} 0x${num2:${i}:16} ))"
    done
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
