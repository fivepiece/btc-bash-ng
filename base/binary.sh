#!/bin/bash


# printf '%s' STR | bin2bytes : " BYTE BYTE..."
# bin2bytes <<<"STR" : " BYTE BYTE... 0x0A"
# bin2bytes FILE : " BYTE BYTE..."
#alias bin2bytes="od -t x1 -An -v -w1"

# prtinf '%s' STR | bin2hexstr : "HEX..."
# bin2hex <<<"STR" : "HEX...0x0A"
# bin2hex FILE : "HEX..."
#alias bin2hexstr="hexdump -v -e '\"\" 1/1 \"%02X\" \"\"'"

# echo HEX | hex2bin : BIN
# hex2bin HEX : BIN
hex2bin-2() {

    if [[ -z "$1" ]]; then

        while read -N2 byte; do
           printf '%b' "\\x${byte}"
        done
    else
        while read -N2 byte; do
           printf '%b' "\\x${byte}"
        done <<<"$1"
    fi
}

revbytes () 
{ 
    local -u hexstr
    local -i chunk
    if [[ "${1}" == "" ]]; then
        read hexstr
        chunk=2
    else
        hexstr="${1}"
        chunk="${2:-2}"
    fi

    if (( ${#hexstr} % ${chunk} == 1 )); then
        hexstr="0${hexstr}"
    fi
    local -a revstr
    for ((i=$(( ${#hexstr}-${chunk} )); i>=0; i-- )); do
        revstr+=( ${hexstr:$(( i*${chunk} )):${chunk}} )
    done
    revstr=${revstr[@]//$'\n'/}
    #revstr=${revstr^^}
    printf "${revstr// /}"
}
