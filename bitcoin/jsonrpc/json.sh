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
