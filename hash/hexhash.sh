#!/bin/bash

# simple functions to convert hex to binary then hash it.
# openssl currently a dependency for ripemd160
# TODO faster

sha224()
{
    local -u digest
    if [[ -z "$1" ]]; then
        read -r -N56 digest < <( sha224sum -b <(hex2bin </dev/stdin) )
    else
        read -r -N56 digest < <( sha224sum -b <(hex2bin "$1") )
    fi
    printf '%s\n' "${digest}"
}

sha256()
{
    local -u digest
    if [[ -z "$1" ]]; then
        read -r -N64 digest < <( sha256sum -b <(hex2bin </dev/stdin) )
    else
        read -r -N64 digest < <( sha256sum -b <(hex2bin "$1") )
    fi
    printf '%s\n' "${digest}"
}

sha384()
{
    local -u digest
    if [[ -z "$1" ]]; then
        read -r -N96 digest < <( sha384sum -b <(hex2bin </dev/stdin) )
    else
        read -r -N96 digest < <( sha384sum -b <(hex2bin "$1") )
    fi
    printf '%s\n' "${digest}"
}

sha512()
{
    local -u digest
    if [[ -z "$1" ]]; then
        read -r -N128 digest < <( sha512sum -b <(hex2bin </dev/stdin) )
    else
        read -r -N128 digest < <( sha512sum -b <(hex2bin "$1") )
    fi
    printf '%s\n' "${digest}"
}

# TODO rmd160sum in coreutils?
ripemd160()
{
    local -u digest
    if [[ -z "$1" ]]; then
        read -r -N40 digest < <( openssl rmd160 -r <(hex2bin </dev/stdin) )
    else
        read -r -N40 digest < <( openssl rmd160 -r <(hex2bin "$1") )
    fi
    printf '%s\n' "${digest}"
}

hash256()
{
    if [[ -z "$1" ]]; then
        sha256 < <(sha256 </dev/stdin)
    else
        sha256 < <(sha256 "$1")
    fi
}

hash160()
{
    if [[ -z "$1" ]]; then
        ripemd160 < <(sha256 </dev/stdin)
    else
        ripemd160 < <(sha256 "$1")
    fi
}
