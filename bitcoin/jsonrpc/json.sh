#!/bin/bash

mkjson_credit()
{
    local txid="$1" vout="$2" spk=( $3 ) amount="$4" rdm=( $5 ) nestrdm=( $6 )

    printf '{"txid":"%s",\n"vout":%d,\n"scriptPubKey":"%s",\n' \
        "${txid}" \
        "${vout}" \
        "$( script_serialize "${spk[*]}" )"

    if [[ ! -z ${rdm} ]]; then
        printf '"redeemScript":"%s",\n"amount":%s}\n' \
            "$( script_serialize "${rdm[*]}" )" \
            "${amount}"
    else
        printf '"amount":%s}\n' "${amount}"
    fi
}

core_listunspent ()
{
    local count="${1:-1}" min_sum="${2:-0.01}" minconf=1
    local -a in_addr=( ${3} )
    if [[ -n ${in_addr} ]]; then
        printf -v in_addr '"%s",' ${in_addr[@]}
        in_addr="${in_addr%,}"
    fi

    ${4:-${clientname}}-cli -named listunspent \
        minconf=${minconf} \
        ${in_addr+addresses="[${in_addr}]"} \
        query_options="{\"maximumCount\":${count},\"minimumSumAmount\":${min_sum}}"
}
