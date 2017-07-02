#!/bin/bash

btcb_bit_home="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && echo $PWD )"

btcb_bit_env=( \
    script/globals/opcodes.sh script/globals/scripts.sh \
    script/script_num.sh script/keys.sh script/scriptpubkey.sh \
    transaction.sh parse.sh )

set_network_versions() {

    case "$1" in

        bitcoin)
            export privkeyVer="80"
            export p2pkhVer="00"
            export p2shVer="05"
            export xpubVer="0488B21E"
            export xprvVer="0488ADE4"
            export clientname="bitcoin"
            ;;

        testnet|regtest|mastcoin)
            export privkeyVer="EF"
            export p2pkhVer="6F"
            export p2shVer="C4"
            export xpubVer="043587CF"
            export xprvVer="04358394"
            export clientname="$1"
            ;;
	esac
}

for shenv in ${btcb_bit_env[@]}; do
    . "${btcb_bit_home}/${shenv}"
done

export __debug_btcbash=1
set_network_versions 'regtest'
