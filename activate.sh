#!/bin/bash

decho ()
{
    if [[ ${__debug_btcbash} == 1 ]]; then
        echo -e "$@" 1>&2;
    fi
}

btcb_home="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && echo $PWD )"

if [[ -r "${btcb_home}/config/paths.sh" ]]; then
    source "${btcb_home}/config/paths.sh"
else
    source "${btcb_home}/config/paths.sh.example"
fi

source "${btcb_home}/bc/bc_env.sh"

btcb_env=( \
    base/binary.sh base/string.sh base/number.sh base/int_convert.sh base/pattern.sh \
    hash/logic.sh hash/hexhash.sh hash/hmac.sh hash/merkle_tree.sh \
    encode/base58check.sh \
    ecdsa/rfc6979.sh ecdsa/ecdsa_ifc.sh ecdsa/contract_hash.sh \
    schnorr/schnorr_ifc.sh )

for shenv in ${btcb_env[@]}; do
    source "${btcb_home}/${shenv}"
done

source "${btcb_home}/bitcoin/activate_bitcoin.sh"
