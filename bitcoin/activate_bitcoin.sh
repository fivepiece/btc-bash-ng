#!/bin/bash

btcb_bit_home="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && echo $PWD )"

btcb_bit_env=( \
    script/globals/opcodes.sh script/globals/scripts.sh \
    script/script_num.sh script/keys.sh script/scriptpubkey.sh \
    transaction.sh parse.sh  \
    bips/bip32.sh bips/bip173.sh \
    jsonrpc/json.sh jsonrpc/sign_message.sh )

set_network_versions() {

    case "$1" in

        bitcoin)
            privkeyVer="80"
            p2pkhVer="00"
            p2shVer="05"
            xpubVer="0488B21E"
            xprvVer="0488ADE4"
            swHrp="bc"
            clientname="mainnet"
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
                    swHrp="tb"
                    ;;
                regtest)
                    swHrp="bcrt"
                    ;;
            esac
	esac
    p2wpkhVer="0014"
    p2wshVer="0020"
}

for shenv in ${btcb_bit_env[@]}; do
    . "${btcb_bit_home}/${shenv}"
done

__debug_btcbash=1
set_network_versions 'regtest'
