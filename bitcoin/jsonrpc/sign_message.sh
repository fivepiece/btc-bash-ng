#!/bin/bash

core_signmessage_sig2core ()
{
    hex2bin "${1^^}${2^^}${3^^}" | base64 -w0; echo
}

core_signmessage_core2sig ()
{
    local -u hexsig r s recovery="${2}"
    # decho "${1%===*}"
    read hexsig < <( echo -n "${1%===*}" | base64 -d -w0 | bin2hex )
    # decho "hexsig : ${hexsig}"
    echo "${hexsig:2:64}" "${hexsig:66}" "${recovery:+${hexsig:0:2}}"
}

# header = "Bitcoin Signed Message:\n"
# header_length = 0x18
# header_hex = 0x18426974636F696E205369676E6564204D6573736167653A0A
# body = text_length + text
# message = header + body
core_signmessage_sighash ()
{
    local -u text_hex size

    read text_hex < <( echo -n "$1" | bin2hex )
    read size < <( data_compsize "${#text_hex}" )
    # decho "z0 = 18426974636F696E205369676E6564204D6573736167653A0A${size}${text_hex}" 
    sha256 "18426974636F696E205369676E6564204D6573736167653A0A${size}${text_hex}"
}

core_signmessage_hex ()
{
    local -u d="$1" sighash k z
    local text="$2"

    read sighash < <( core_signmessage_sighash "${text}" )
    read k < <( rfc6979_secp256k1_sha256_k "${d}" "${sighash}" )
    read z < <( sha256 "${sighash}" )
    bc_ecdsa <<<"\
        ecdsa_sign_recoverable(${k}, ${z}, ${d}, ${3:-1}, sig[]); \
        sig[2]; left_pad(sig[0], 40); left_pad(sig[1], 40);"
}

core_signmessage ()
{
    local -u hexsig
    readarray -t hexsig < <( core_signmessage_hex "$1" "$2" "${3:-1}" )
    core_signmessage_sig2core ${hexsig[@]}
}

core_signmessage_recover_all_pubkeys ()
{
    local -u r s msg
    
    read r s < <( core_signmessage_core2sig "$1" )
    read msg < <( core_signmessage_sighash "$2" | sha256 )
    bc_ecdsa <<<"ecdsa_recover(${msg}, ${r}, ${s});"
} 

core_signmessage_recover_pubkey ()
{
    local -u r s recid z
    
    read r s recid < <( core_signmessage_core2sig "$1" 'recid' )
    read z < <( core_signmessage_sighash "$2" | sha256 )
    bc_ecdsa ${bc_env[bitwise_logic]} <<<"ecdsa_verify_recoverable_getpub(${z}, ${recid}${r}${s});"
} 

core_signmessage_verify ()
{
    local addr="$1" sig="$2" msg="$3" pubkey
    read pubkey < <( core_signmessage_recover_pubkey "${sig}" "${msg}" )
    if [[ "$(key_pub2addr ${pubkey})" != "${addr}" ]]; then
        echo 0
        return 1
    else
        # not needed since recovery and checking against the address is enough
        # local dersig="$( sig2der "${r}" "${s}" )"
        # verify "${z}" "${pubkey}" "${dersig}"
        ###
        echo 1
        return 0
    fi
}
