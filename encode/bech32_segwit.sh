#!/bin/bash
segwit_encode ()
{
    local spk="$1" ver push prog swhrp="${2:-${swHrp}}"
    local -a progarr
    ver="${spk:0:2}"
    push="${spk:2:2}"
    prog="${spk:4}"
    if (( ( $((16#${push} * 2)) ) != ${#prog} )); then
        echo "bad segwit program push" 1>&2
        return 1
    fi
    for ((i=0; i<${#prog}; i+=2)); do
        progarr+=( $((16#${prog:${i}:2})) )
    done
    bech32_swprog_encode "${swhrp}" "$((16#${ver}))" "${progarr[@]}"
}

segwit_decode ()
{
    local -l ver prog hrp="${1%1*}"
    local -a decarr
    if [[ "${hrp}" != bc ]] && [[ "${hrp}" != tb ]] && [[ "${hrp}" != bcrt ]]; then
        echo "invalid hrp" 1>&2
        return 1
    fi
    readarray -t decarr < <( bech32_swprog_decode "${hrp}" "${1}" )
    ver="${decarr[0]}"
    printf -v prog '%02X' ${decarr[1]}
    if [[ ! "${ver} ${prog}" =~ _ ]]; then
        script_serialize "${ver} @${prog}"
    else
        return 1
    fi
}
