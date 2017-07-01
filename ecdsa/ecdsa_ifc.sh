#!/bin/bash

compresspoint ()
{
    bc_ecdsa <<<"compresspoint(${1^^},${2^^});"
}

uncompresspoint ()
{
    bc_ecdsa <<<"uncompresspoint(${1^^});"
}

sig2der ()
{
    bc_ecdsa <<<"ecdsa_sig2der(${1^^}, ${2^^});"
}

sign ()
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

sign_der ()
{
    sign "${1}" "${2}" '1'
}
