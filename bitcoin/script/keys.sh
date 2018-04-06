#!/bin/bash

key_addr2hash160 ()
{
    local -u pubhash
    read pubhash < <( base58dec "${1}" )
    echo "${pubhash:2:40}"
}

key_hash1602addr ()
{
    local -u checksum
    read checksum < <( hash256 "${p2pkhVer}${1}" )
    base58enc "${p2pkhVer}${1}${checksum:0:8}"
}

key_hash1602p2sh ()
{
    local -u checksum
    read checksum < <( hash256 "${p2shVer}${1}" )
    base58enc "${p2shVer}${1}${checksum:0:8}"
}

key_priv2pub ()
{ 
    bc_ecdsa <<< "ecmul("${1^^}");"
}

key_priv2wif()
{
    local -u privkey="${1^^}" keyhash

    if (( ${#1} < 64 )); then
        read privkey < <( left_pad "${privkey}" 64 )
    fi
    read keyhash < <( hash256 "${privkeyVer}${privkey}" )
    keyhash="${keyhash:0:8}"

    base58enc "${privkeyVer}${privkey}${keyhash}"
}

key_pub2addr ()
{
    local addr;
    local -u pubhash;
    read pubhash < <( hash160 "${1}" );
    read checksum < <( hash256 "${p2pkhVer}${pubhash}" )
    base58enc "${p2pkhVer}${pubhash}${checksum:0:8}"
}

key_wif2priv ()
{
    local -u privhex;
    read privhex < <( base58dec "${1}" )
    echo "${privhex:2:64}"
}

key_wif2pub ()
{
    local -u prihex pubkey;
    read privhex < <( base58dec "${1}" )
    if (( ${#privhex} == 74 )); then
        #uncompresspoint "$( key_priv2pub "${privhex:2:64}" )"
        uncompresspubkey "$( key_priv2pub "${privhex:2:64}" )"
    else
        key_priv2pub "${privhex:2:64}"
    fi
}
