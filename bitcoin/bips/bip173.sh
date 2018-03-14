#!/bin/bash

# bash implementation of https://github.com/sipa/bech32/blob/master/ref/python/segwit_addr.py
# enables https://github.com/bitcoin/bips/blob/master/bip-0173.mediawiki

_bech32_charset=( \
    'q' 'p' 'z' 'r' 'y' '9' 'x' '8' \
    'g' 'f' '2' 't' 'v' 'd' 'w' '0' \
    's' '3' 'j' 'n' '5' '4' 'k' 'h' \
    'c' 'e' '6' 'm' 'u' 'a' '7' 'l' )

declare -A _bech32_setchar
_bech32_setchar=( \
    [q]='0'  [p]='1'  [z]='2'  [r]='3'  [y]='4'  [9]='5'  [x]='6'  [8]='7'  \
    [g]='8'  [f]='9'  [2]='10' [t]='11' [v]='12' [d]='13' [w]='14' [0]='15' \
    [s]='16' [3]='17' [j]='18' [n]='19' [5]='20' [4]='21' [k]='22' [h]='23' \
    [c]='24' [e]='25' [6]='26' [m]='27' [u]='28' [a]='29' [7]='30' [l]='31' )

bech32_polymod ()
{
    local -a generator values=( $@ )
    local chk top i value
    generator=( 0x3b6a57b2 0x26508e6d 0x1ea119fa 0x3d4233dd 0x2a1462b3 )
    chk=1
    for value in ${values[@]}; do
        top=$(( ${chk} >> 25 ))
        chk=$(( ( ${chk} & 0x1ffffff) << 5 ^ ${value} ))
        for i in {0..4}; do
            if (( ( ${top} >> ${i} ) & 1 )); then
                chk=$(( ${chk} ^ ${generator[$i]} ))
            else
                chk=$(( ${chk} ^ 0 ))
            fi
        done
    done
    echo ${chk}
}

bech32_hrp_expand ()
{
    local -a ords
    for ((i=0; i<${#1}; i++)); do
        printf -v ords[$i] '%d\n' "'${1:${i}:1}" # http://mywiki.wooledge.org/BashFAQ/071 , ord()
    done
    for ord in ${ords[@]}; do
        echo -n "$(( ${ord} >> 5 )) "
    done
    echo -n "0 "
    for ord in ${ords[@]}; do
        echo -n "$(( ${ord} & 31 )) "
    done
    echo
}

bech32_verify_checksum ()
{
    local -a hrp_vals
    local checksum_ret
    readarray -t hrp_vals < <( bech32_hrp_expand "$1" )
    shift
    read checksum_ret < <( bech32_polymod ${hrp_vals[@]} ${@} )
    (( ${checksum_ret} == 1 ))
}

bech32_create_checksum ()
{
    local -a hrp_vals values
    local polymod
    readarray -t hrp_vals < <( bech32_hrp_expand "$1" )
    shift
    values=( ${hrp_vals[@]} ${@} )
    read polymod < <( bech32_polymod ${values[@]} 0 0 0 0 0 0 )
    polymod=$(( ${polymod} ^ 1 ))
    for i in {0..5}; do
        echo -n "$(( (${polymod} >> 5 * (5 - ${i})) & 31 )) "
    done
    echo
}

bech32_encode ()
{
    local val hrp="${1,,}"
    shift
    local -a checksum data=( ${@} )
    readarray -t checksum < <( bech32_create_checksum "${hrp}" ${data[@]} )
    echo -n "${hrp}1"
    for val in ${data[@]} ${checksum[@]}; do
        echo -n "${_bech32_charset[${val}]}"
    done
    echo
}

bech32_decode ()
{
    local i ord hrp="" pos enc bech="$1"
    local -a data
    for ((i=0; i<${#bech}; i++)); do
        printf -v ord '%d' "'${bech:${i}:1}"
        if (( ${ord} < 33 )) || (( ${ord} > 126 )); then
            echo 1 1>&2
            echo '_ _'
            return 1
        fi
    done
    if [[ ${bech,,} != ${bech} ]] && [[ ${bech^^} != ${bech} ]]; then
        echo 2 1>&2
        echo '_ _'
        return 1
    fi
    bech="${bech,,}"
    [[ ${bech} =~ 1 ]] && hrp="${bech%1*}"
    pos="${#hrp}"
    if (( ${pos} < 1 )) || (( (${pos} + 7) > ${#bech} )) || (( ${#bech} > 90 )); then
        echo 3 1>&2
        echo '_ _'
        return 1
    fi
    for ((i=(${#hrp}+1); i<${#bech}; i++)); do
        enc="${_bech32_setchar[${bech:${i}:1}]}"
        if [[ -z ${enc} ]]; then
            echo 4 1>&2
            echo '_ _'
            return 1
        else
            data+=( ${enc} )
        fi
    done
    if ! bech32_verify_checksum "${hrp}" ${data[@]}; then
        echo 5 1>&2
        echo '_ _'
        return 1
    fi
    echo "${hrp,,}"
    echo "${data[@]:0:$((${#data[@]} - 6))}"
}

bech32_convertbits ()
{
    local -a data=( ${1} ) ret
    local frombits="$2" tobits="$3" pad="${4:-true}"
    local acc=0 bits=0 maxv max_acc value

    maxv=$(( (1 << ${tobits}) - 1 ))
    max_acc=$(( (1 << (${frombits} + ${tobits} - 1)) - 1 ))
    for value in ${data[@]}; do
        if (( ${value} < 0 )) || (( ${value} >> ${frombits} )); then
            echo '_'
            return 1
        fi
        acc=$(( ( ( ${acc} << ${frombits} ) | ${value} ) & ${max_acc} ))
        bits=$(( ${bits} + ${frombits} ))
        while (( ${bits} >= ${tobits} )); do
            bits=$(( ${bits} - ${tobits} ))
            ret+=( $(( (${acc} >> ${bits}) & ${maxv} )) )
        done
    done
    if [[ ${pad} == true ]]; then
        if (( ${bits} > 0 )); then
            ret+=( $(( (${acc} << (${tobits} - ${bits})) & ${maxv} )) )
        fi
    elif (( ${bits} >= ${frombits} )) || (( ( (${acc} << (${tobits} - ${bits}) ) & ${maxv}) )); then
        echo '_'
        return 1
    fi
    echo ${ret[@]}
}

bech32_swprog_decode ()
{
    local hrp="${1,,}" addr="$2" hrpgot
    local -a data decoded tmp
    readarray -t tmp < <( bech32_decode "${addr}" )
    hrpgot=${tmp[0]}
    data=( ${tmp[1]} )
    if [[ ${hrpgot} != ${hrp} ]]; then
        echo '_ _'
        return 1
    fi
    read -r decoded < <( bech32_convertbits "${data[*]:1}" 5 8 false )
    decoded=( ${decoded[@]} )
    if [[ ${decoded} == _ ]] || (( ${#decoded[@]} < 2 )) || (( ${#decoded[@]} > 40 )); then
        echo 1 1>&2
        echo '_ _'
        return 1
    fi
    if (( ${data[0]} > 16 )); then
        echo 2 1>&2
        echo '_ _'
        return 1
    fi
    if (( ${data[0]} == 0 )) && (( ${#decoded[@]} != 20 )) && (( ${#decoded[@]} != 32 )); then
        echo 3 1>&2
        echo '_ _'
        return 1
    fi
    echo "${data[0]}"
    echo "${decoded[@]}"
}

bech32_swprog_encode ()
{
    local hrp="${1,,}" witver="$2" ret
    shift; shift
    local -a witprog=( ${@} ) ver_prog converted
    read -r converted < <( bech32_convertbits "${witprog[*]}" 8 5 )
    read -r ret < <( bech32_encode ${hrp} "${witver} ${converted[@]}" )
    if ! bech32_swprog_decode "${hrp}" "${ret}" 1>/dev/null; then
        return 1
    fi
    echo "${ret}"
}
