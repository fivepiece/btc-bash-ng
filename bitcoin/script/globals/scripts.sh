#!/bin/bash

# abstract scripts and opcodes

# normal scripts

script_p2pkey=( "push_pubkey" "CHECKSIG" )
script_p2pkh=( "DUP" "HASH160" "0x14" "pubkeyhash" "EQUALVERIFY" "CHECKSIG" )
script_mofn=( "m" "push_pubkeys" "n" "CHECKMULTISIG" )
script_p2sh=( "HASH160" "0x14" "scripthash" "EQUAL" )

# segwit scripts

script_p2wpkh=( "0x00" "0x14" "pubkeyhash" )
script_p2wsh=( "0x00" "0x20" "scripthash" )
# script_p2wmast=( "0x51" "0x20" "masthash" ) # TODO port MAST

# bip112 scripts

script_ced=( "IF" "escrow_script" "ELSE" "countdown" "CHECKSEQUENCEVERIFY" "DROP" "timeout_script" "ENDIF" )
script_revc=( "HASH160" "revokehash" "EQUAL" "IF" "pubkey" "ELSE" "countdown" "CHECKSEQUENCEVERIFY" "DROP" "pubkey" "ENDIF" "CHECKSIG" )
script_htlc=( "HASH160" "DUP" "rhash" "EQUAL" "IF" "countdown" "CHECKSEQUENCEVERIFY" "2DROP" "pubkey" "ELSE" "crhash" "EQUAL" "NOTIF" "deadline" "CHECKLOCKTIMEVERIFY" "DROP" "ENDIF" "pubkey" "ENDIF" "CHECKSIG" )
