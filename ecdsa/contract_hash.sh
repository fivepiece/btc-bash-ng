#!/bin/bash

contracthash_sign ()
{
    local -u d1="$1" c1="$2" z1="$3" k0 nnc1 tw1

    k0="$( rfc6979_secp256k1_sha256_k "${d1}" "${z1}" )"
    nnc1="$( key_priv2pub ${k0} )"
    tw1="$( sha256 "${nnc1}${c1}" )"

    bc_ecdsa ${bc_env[contract_hash]} <<<" \
        contracthash_sign_api(${k0}, ${tw1}, ${z1}, ${d1}, contract[]); \
        compresspoint(contract[0], contract[1]); \
        ecdsa_sig2der(contract[2], contract[3]);"
}

contracthash_verify ()
{
    local -u z1="$1" pub="$2" nnc1="$3" sig1="$4" c1="$5" tw1

    tw1="$( sha256 "${nnc1}${c1}" )"
    bc_ecdsa ${bc_env[contract_hash]} <<<" \
        contracthash_verify_api(${z1}, ${pub}, ${nnc1}, ${sig1}, ${tw1})"
}

contracthash_recoverk ()
{
    local -u z1="$1" nnc1="$2" sig1="$3" c1="$4" sig2="$5" c2="$6" tw1 tw2

    tw1="$( sha256 "${nnc1}${c1}" )"
    tw2="$( sha256 "${nnc1}${c2}" )"
    bc_ecdsa ${bc_env[contract_hash]} <<<" \
        contracthash_recover_k(${z1}, ${sig1}, ${tw1}, ${sig2}, ${tw2}, curve_n);"
}
