#!/bin/bash

# uncompressed pubkey -> compressed pubkey
compresspubkey ()
{
    local -u x="${1:2:$(((${#1}/2)-1))}" y="${1:$(((${#1}/2)+1)):${#1}}"
    compresspoint "${x}" "${y}"
}

# x and y coordinates -> compressed pubkey
compresspoint ()
{
    local -u x="$1" parity="${2:$((${#2}-1)):1}"
    parity="$((16#${parity}))"
    if (( ${parity}  % 2 )); then
        echo "03${x}"
    else
        echo "02${x}"
    fi
}

# compressed pubkey -> x and y coordinates
uncompresspoint ()
{
    bc_ecdsa <<<"uncompresspoint_api(${1^^}, pt[]); pt[0]; pt[1];"
}

# compressed pubkey -> uncompressed pubkey
uncompresspubkey ()
{
    bc_ecdsa <<<"uncompresspoint(${1^^});"
}

# (r, s) -> DER signature
sig2der ()
{
    bc_encode <<<"ecdsa_sig2der(${1^^}, ${2^^});"
}

# DER signature -> (r, s)
der2sig ()
{
    bc_encode <<<"ecdsa_der2sig(${1^^}, sig[]); print sig[0], \" \", sig[1], \"\\n\";"
}

# (d, z) -> (r, s)
# d : a private key
# z : a message to sign (for bitcoin, this means sha256(message)
sign_api ()
{
    local k m der="${3:-0}"
    read k < <( rfc6979_secp256k1_sha256_k "${1^^}" "${2^^}" )
    read m < <( sha256 "${2^^}" )
    bc_ecdsa <<<"
        ecdsa_sign(${k}, ${m}, ${1^^}, sig[]);
        if ( ${der} ){
            ecdsa_sig2der(sig[0], sig[1]);
        } else {
            print sig[0], \" \", sig[1], \"\\n\";
        }"
}

# same as the above, but returns a DER encoded signature
sign ()
{
    sign_api "$1" "$2" '1'
}

# (z, pubkey, [ (r,s) | DER signature ]) -> {1, 0}
# returns 1 on verification success or 0 on failure
# the 3rd parameter can be either a DER encoded signature
# or the 'r' value of the signature, in which case
# the 4th parameter should be the 's' value
verify ()
{
    local -u z1="$1" pubkey="$2" sig_r="$3" sig_s="$4"

    if [[ ${pubkey:0:2} == "04" ]]; then
        read pubkey < <( compresspubkey "${pubkey}" )
    fi
    if [[ "${sig_s}" == "" ]]; then
        # DER signature as the 3rd parameter
        bc_ecdsa <<<"ecdsa_verify_der(${z1}, ${pubkey}, ${sig_r});"
    else
        bc_ecdsa <<<"ecdsa_verify(${z1}, ${pubkey}, ${sig_r}, ${sig_s});"
    fi
}

# (z, [ (r,s) | DER signature ]) -> pubkeys
# returns recovered pubkeys off a message and signature
# the 2nd parameter can be either a DER encoded signature
# or the 'r' value of the signature, in which case
# the 3rd parameter should be the 's' value
recover ()
{
    local -u z1="$1" sig_r="$2" sig_s="$3"

    if [[ "${sig_s}" == "" ]]; then
        # DER signature as the 3rd parameter
        bc_ecdsa <<<"ecdsa_recover_der(${z1}, ${sig_r});"
    else
        bc_ecdsa <<<"ecdsa_recover(${z1}, ${sig_r}, ${sig_s});"
    fi
}
