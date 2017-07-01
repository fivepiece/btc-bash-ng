#!/bin/bash

tx_mkout_serialize ()
{
    local amount="${1}" asmscript="${2}" nest="${3}"
    local -a meta=( $4 )
    local -u seramt serscript
    local scriptsize

    if [[ "${nest}" =~ "mast" ]]; then

        tx_mkout_p2wmast "${amount}" "${asmscript}" "${nest//mast/}" "${meta[0]}" "${meta[1]}"
        return
    fi
    
    if [[ "${nest}" =~ "p2wsh" ]]; then

        tx_mkout_p2wsh "${amount}" "${asmscript}" "${nest//p2wsh/}"
        return
    fi

    if [[ "${nest}" =~ "p2sh" ]]; then

        tx_mkout_p2sh "${amount}" "${asmscript}" ""
        return
    fi

    read seramt < <( dec2amount "${amount}" )
    read serscript < <( script_serialize "${asmscript}" )
    read scriptsize < <( data_compsize "${#serscript}" )
    echo "${seramt}${scriptsize}${serscript}"
}

tx_mkout_p2pkey ()
{
    local amount="${1}" pubkey="${2}"
    local nest="${3}" script

    read script < <( spk_pay2pubkey "${pubkey}" )
    tx_mkout_serialize "${amount}" "${script}" "${nest}"
}

tx_mkout_p2pkh ()
{
    local amount="${1}" addr="${2}"
    local nest="${3}" script

    read script < <( spk_pay2pkhash "${addr}" )
    tx_mkout_serialize "${amount}" "${script}" "${nest}"
}

tx_mkout_mofn ()
{
    local amount="${1}" pubkeys="${3}"
    local -i m="${2}"
    local nest="${3}" script

    read script < <( spk_pay2mofn "${m}" "${pubkeys}" )
    tx_mkout_serialize "${amount}" "${script}" "${nest}"
}

tx_mkout_p2wpkh ()
{
    local amount="${1}" addr="${2}"
    local nest="${3//p2wsh/}" script

    read script < <( spk_pay2wpkhash "${addr}" )
    tx_mkout_serialize "${amount}" "${script}" "${nest}"
}

tx_mkout_p2wsh ()
{
    local amount="${1}" asmscript="${2}"
    local nest="${3//p2wsh/}" script

    read script < <( spk_pay2wshash "${asmscript}" )
    tx_mkout_serialize "${amount}" "${script}" "${nest}"
}

tx_mkout_p2wmast ()
{
    local amount="${1}" asmscript="${2}"
    local nest="${3//mast/}" script path="$4" position="$5"

    read script < <( spk_pay2wmast "${asmscript}" "${path}" "${position}" )
    tx_mkout_serialize "${amount}" "${script}" "${nest}"
}

tx_mkout_p2sh ()
{
    local amount="${1}" asmscript="${2}"
    local script

    read script < <( spk_pay2shash "${asmscript}" )
    tx_mkout_serialize "${amount}" "${script}" ""
}

# in : previous txid, previous output index, sequence number to apply, script to use
tx_mkin_serialize ()
{
    local -u prevtx="${1}" serpidx serseq serscript
    local -i previdx="${2}" sequence="${3}"
    local asmscript="${4}" scriptsize

    read prevtx < <( revchunks "${prevtx}" )

    read serpidx < <( tx_ser_int "${previdx}" )

    read serseq < <( tx_ser_int "${sequence}" )

    read serscript < <( script_serialize "${asmscript}" )
    read scriptsize < <( data_compsize "${#serscript}" )

    echo -e "${prevtx}${serpidx}${scriptsize}${serscript}${serseq}"
}

tx_input_script ()
{
    local -u script

    script="${1:72}"
    script="${script::-8}"

    echo "${script}"
}

tx_bip141_iswitprog ()
{
    local -u scriptpk
    local pushcode pushop

    read scriptpk < <( tx_input_script "${1}" )

    case ${#scriptpk} in

        46|70)
            pushcode="${scriptpk:2:2}"
            pushop="${scriptpk:4:2}"
            ;;
        48|72)
            pushcode="${scriptpk:4:2}"
            pushop="${scriptpk:6:2}"
            ;;
        2)
            if [[ ${scriptpk} == "00" ]]; then
                echo 1
                return
            fi
            ;;&
        *)
            echo 0
            return
            ;;
    esac
    # spklen="${#scriptpk}"

    # if (( "${spklen}" != 46 )) && (( "${spklen}" != 70 )) && (( "${spklen}" != 2 )); then
    #if [[ ! ${spklen} =~ 46|48|70|72|2 ]]; then
    #
    #    echo "0"
    #    return
    #fi

    if [[ ! ${pushop} =~ 14|20 ]]; then
        echo 0
        return
    fi

    # if [[ ${scriptpk:2:2} =~ 00|51|52|53|54|55|56|57|58|59|5A|5B|5C|5D|5E|5F|60 ]] || [[ ${scriptpk} == "00" ]]; then
    if [[ ! ${pushcode} =~ 00|51|52|53|54|55|56|57|58|59|5A|5B|5C|5D|5E|5F|60 ]]; then

        echo "0"
        return
    fi

    echo 1
#    read pushcode < <( BC_ENV_ARGS='-q' bc <<<"${scriptpk:2:2}" )
#
#    if (( "${pushcode}" < 0 )) || (( "${pushcode}" > 16 )); then
#
#        echo "0"
#    fi
#
#    echo "1"
}

tx_bip141_serwitness()
{
    local -au stack=( $1 ) serstack
    local -u sersize bn elem stacksize

    for (( i=0; i<${#stack[@]}; i++ )); do
        read bn < <( script_is_opnum "${stack[$i]}" )
        if [[ ${bn} == "1" ]]; then
            if [[ ${stack[$i]} == "0" ]]; then
                serstack[$i]="00"
            else
                printf -v serstack[$i] '01%02X' ${stack[$i]}
                continue
            fi
        fi
        read bn < <( script_is_bignum "${stack[$i]}" )
        if [[ ${bn} == "1" ]]; then
            read serstack[$i] < <( script_serialize "${stack[$i]}" )
        else
            read elem < <( script_serialize "${stack[$i]}" )
            read sersize < <( data_compsize ${#elem} )
            serstack[$i]="${sersize}${elem}"
        fi
    done

    read stacksize < <( data_compsize $((${#serstack[@]}*2)) )
    printf '%s' ${stacksize} ${serstack[@]}
}

_tx_bip141_serwitness ()
{
    local -au stack serstack
    local -u sersize
    stack=( ${1} )

    read sersize < <( data_compsize "$(( ${#stack[@]}*2 ))" )

    for (( i=0; i<"${#stack[@]}"; i++ )); do

        if [[ ${stack[$i]} == "0" ]]; then
            serstack[$i]="00"
            continue
        fi
        read itemlen < <( data_compsize "${#stack[${i}]}" )
        serstack[${i}]="${itemlen}${stack[${i}]}"
    done

#    printf "%s\n" "${sersize}" ${serstack[@]}
    echo -n "${sersize}"
    for (( i=0; i<"${#serstack[@]}"; i++ )); do

        echo -n "${serstack[${i}]}"
    done
}

tx_build ()
{
    local -u version swmarker swflag vins vouts nlocktime
    local -au inputs outputs witness witsigs

    read version < <( tx_ser_int "${1}" )

    if [[ "${2,,}" != "" ]]; then

        swmarker="00"
        swflag="01"
    fi

    inputs=( ${3} )
    outputs=( ${4} )
    witsigs=( ${6} )

    read vins < <( data_compsize "$(( ${#inputs}*2 ))" )
    read vouts < <( data_compsize "$(( ${#outputs}*2 ))" )

    if [[ "${swflag}" == "01" ]]; then

        local -i j=0
        for (( i=0; i<"${#inputs[@]}"; i++ )); do

            read iswitness < <( tx_bip141_iswitprog "${inputs[${i}]}" )

            if (( "${iswitness}" )); then

                # 010100 - dummy witness
                witness[${i}]="${witsigs[${j}]:-010100}"
                j="$(( ${j}+1 ))"
            else
                witness[${i}]="00"
            fi
        done
    fi

    read nlocktime < <( tx_ser_int "${5}" )

    echo "${version}"
    if [[ "${swflag}" == "01" ]]; then

        echo "${swmarker}"
        echo "${swflag}"
    fi
    data_compsize "$(( (${#inputs[@]}*2) ))"
    printf "%s\n" ${inputs[@]}
    data_compsize "$(( ${#outputs[@]}*2 ))"
    printf "%s\n" ${outputs[@]}
    if [[ "${swflag}" == "01" ]]; then

        printf "%s\n" ${witness[@]}
    fi
    echo "${nlocktime}"
}
