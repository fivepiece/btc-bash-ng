#!/bin/bash

decho ()
{
    if [[ ${__debug_btcbash} == 1 ]]; then
        echo -e "$@" 1>&2;
    fi
}

tx_deser_version ()
{
    if (( ${#1} != 8 )); then

        echo -1 # bad version
        return
    fi
    tx_deser_int "${1}"
}

tx_compsize_len ()
{
    local -u byte="$1"
    if [[ ${byte} < FD ]]; then echo 2 && return; fi
    if [[ ${byte} < FE ]]; then echo "$(( 4+2 ))" && return; fi
    if [[ ${byte} < FF ]]; then echo "$(( 8+2 ))" && return; fi

    echo "$(( 16+2 ))" && return
}

tx_deser_compsize ()
{
    local -u revcsize
    if [[ "${1:0:2}" < FD ]]; then

        echo "$(( 2*$((16#${1})) ))"
        return
    fi
    read revcsize < <( revchunks "${1:2}" )

    bc_clean <<<"ibase=16; ${revcsize}*2"
}

tx_parse ()
{
    if [[ "${1}" == "" ]]
    then
        local -u tx
        read tx
        tx_parse "${tx}"
        return
    fi

    local -u version tmpbytes tmpval swmarker swflag wit_size
    local -i ptr=0 segwit_tx=0 num_inputs num_outputs
    local -au txid_index in_script_size in_script in_seq
    local -au out_amount out_script_size out_script
    local -au num_wits tmpwits in_wits

    version="${1:0:8}"
    ptr=8
    tmpbytes="${1:${ptr}:2}"

    decho "version : ${version}\nptr : ${ptr}"
    if [[ "${tmpbytes}" == "00" ]]; then

        swmarker="00"
        swflag="${1:10:2}"

        if [[ "${swflag}" == "01" ]]; then

            ptr="$(( ${ptr}+4 ))" 
            tmpbytes="${1:${ptr}:2}"

            if [[ "${tmpbytes}" == "00" ]] || [[ "$2" == 'fnosw' ]]; then

                ptr="$(( ${ptr}-4 ))"
                segwit_tx=0
                swmarker=
                swflag=
            fi
            segwit_tx=1
        else
            segwit_tx=0
            swmarker=
            swflag=
        fi
    fi
    decho "segwit_tx : ${segwit_tx}\nswmarker : ${swmarker}\nswflag : ${swflag}\nptr : ${ptr}"

    read tmpval < <( tx_compsize_len "${1:${ptr}:2}" )
    read num_inputs < <( tx_deser_compsize "${1:${ptr}:${tmpval}}" )
    ptr="$(( ${ptr}+${tmpval} ))"
    decho "num_inputs : $(( ${num_inputs}/2 ))\nptr : ${ptr}"

    for (( i=0; i<$(( ${num_inputs}/2 )); i++ )); do

        if [[ "${1:${ptr}:1}" == "" ]]; then

            if (( ${segwit_tx} == 1 )); then

                segwit_tx=0
                ptr=8
                read tmpval < <( tx_compsize_len "${1:${ptr}:2}" )
                read num_inputs < <( tx_deser_compsize "${1:${ptr}:${tmpval}}" )
                ptr="$(( ${ptr}+${tmpval} ))"
                i=0
                decho "-------------------------------------------------"
                decho "num_inputs : $(( ${num_inputs}/2 ))\nptr : ${ptr}"
                continue
            else
                decho "PARSE_TX FAILED"
                return
            fi
        fi

        txid_index[$i]="${1:${ptr}:72}"
        ptr="$(( ${ptr}+72 ))"
        decho "txid_index[$i] : ${txid_index[$i]}\nptr : ${ptr}"

        read tmpval < <( tx_compsize_len "${1:${ptr}:2}" )
        in_script_size[$i]="${1:${ptr}:${tmpval}}"
        ptr="$(( ${ptr}+${tmpval} ))"
        decho "in_script_size[$i] : ${in_script_size[$i]}\nptr : ${ptr}"

        read tmpval < <( tx_deser_compsize "${in_script_size[$i]}" )
        in_script[$i]="${1:${ptr}:${tmpval}}"
        ptr="$(( ${ptr}+${tmpval} ))"
        decho "in_script[$i] : ${in_script[$i]}\nptr : ${ptr}"

        in_seq[$i]="${1:${ptr}:8}"
        ptr="$(( ${ptr}+8 ))"
        decho "in_seq[$i] : ${in_seq[$i]}\nptr : ${ptr}"
    done

    read tmpval < <( tx_compsize_len "${1:${ptr}:2}" )
    read num_outputs < <( tx_deser_compsize "${1:${ptr}:${tmpval}}" )
    ptr="$(( ${ptr}+${tmpval} ))"
    decho "num_outputs : $(( ${num_outputs}/2 ))\nptr : ${ptr}"

    for (( i=0; i<$(( ${num_outputs}/2 )); i++ )); do

        if [[ "${1:${ptr}:1}" == "" ]]; then

            decho "PARSE_TX FAILED"
            return
        fi

        out_amount="${1:${ptr}:16}"
        ptr="$(( ${ptr}+16 ))"
        decho "out_amount : ${out_amount}\nptr : ${ptr}"

        read tmpval < <( tx_compsize_len "${1:${ptr}:2}" )
        out_script_size[$i]="${1:${ptr}:${tmpval}}"
        ptr="$(( ${ptr}+${tmpval} ))"
        decho "out_script_size[$i] : ${out_script_size[$i]}\nptr : ${ptr}"

        read tmpval < <( tx_deser_compsize "${out_script_size[$i]}" )
        out_script[$i]="${1:${ptr}:${tmpval}}"
        ptr="$(( ${ptr}+${tmpval} ))"
        decho "out_script[$i] : ${out_script[$i]}\nptr : ${ptr}"
    done

    if (( ${segwit_tx} == 1 )); then

        if [[ "${1:${ptr}:1}" == "" ]]; then

            decho "PARSE_TX FAILED"
            return
        fi

        for (( i=0; i<$(( ${num_inputs}/2 )); i++ )); do

            read tmpval < <( tx_compsize_len "${1:${ptr}:2}" )
            read num_wits[$i] < <( tx_deser_compsize "${1:${ptr}:${tmpval}}" )
            ptr="$(( ${ptr}+${tmpval} ))"
            decho "num_wits[$i] : $(( ${num_wits[$i]}/2 ))\nptr : ${ptr}"

            wit_size=""
            tmpwits=()

            for (( j=0; j<$(( ${num_wits[$i]}/2 )); j++ )); do

                read tmpval < <( tx_compsize_len "${1:${ptr}:2}" )
                wit_size="${1:${ptr}:${tmpval}}"
                ptr="$(( ${ptr}+${tmpval} ))"
                decho "wit_size : ${wit_size}\nptr : ${ptr}"

                read tmpval < <( tx_deser_compsize "${wit_size}" )
                tmpwits[$j]="${wit_size}${1:${ptr}:${tmpval}}"
                ptr="$(( ${ptr}+${tmpval} ))"
                decho "tmpwits[$j] : ${tmpwits[$j]}\nptr : ${ptr}"
            done

            in_wits[$i]="${tmpwits[@]}"
            decho "in_wits[$i] : ${in_wits[$i]}"
        done
    fi

    nlocktime="${1:${ptr}:8}"
    decho "nlocktime : ${nlocktime}"
    ptr="$(( ${ptr}+8 ))"
    
    if [[ "${1:${ptr}:1}" != "" ]]; then

        decho "PARSE_TX FAILED"
        return
    fi
}
