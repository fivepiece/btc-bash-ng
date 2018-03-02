#!/bin/bash

btcb_bit_home="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && echo $PWD )"

btcb_bit_env=( \
    script/globals/opcodes.sh script/globals/scripts.sh \
    script/script_num.sh script/keys.sh script/scriptpubkey.sh \
    transaction.sh parse.sh  \
    bips/bip32.sh \
    jsonrpc/json.sh )

set_network_versions() {

    case "$1" in

        bitcoin)
            privkeyVer="80"
            p2pkhVer="00"
            p2shVer="05"
            xpubVer="0488B21E"
            xprvVer="0488ADE4"
            clientname="mainnet"
            p2wpkhVer="bc1qw"
            p2wshVer="bc1qr"
            ;;

        testnet|regtest|mastcoin)
            privkeyVer="EF"
            p2pkhVer="6F"
            p2shVer="C4"
            xpubVer="043587CF"
            xprvVer="04358394"
            clientname="$1"
            case "$1" in
                testnet)
                    p2wpkhVer="tb1qw"
                    p2wshVer="tb1qr"
                    ;;
                regtest)
                    p2wpkhVer="bcrt1qw"
                    p2wshVer="bcrt1qr"
                    ;;
            esac
	esac
    p2wpkhPref="0016"
    p2wshPref="0020"
}

for shenv in ${btcb_bit_env[@]}; do
    . "${btcb_bit_home}/${shenv}"
done

__debug_btcbash=1
set_network_versions 'regtest'
