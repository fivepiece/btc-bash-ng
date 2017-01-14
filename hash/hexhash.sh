#!/bin/bash

# simple functions to convert hex to binary then hash it.
# openssl currently a dependency for ripemd160

sha224()
{
    local -u digest
    if [[ -z "$1" ]]; then
        read -N56 digest < <( hex2bin </proc/self/fd/0 | sha224sum -b )
    else
        read -N56 digest < <( hex2bin "$1" | sha224sum -b )
    fi
    printf '%s\n' "${digest}"
}

sha256()
{
    local -u digest
    if [[ -z "$1" ]]; then
        read -N64 digest < <( hex2bin </proc/self/fd/0 | sha256sum -b )
    else
        read -N64 digest < <( hex2bin "$1" | sha256sum -b )
    fi
    printf '%s\n' "${digest}"
}

sha384()
{
    local -u digest
    if [[ -z "$1" ]]; then
        read -N96 digest < <( hex2bin </proc/self/fd/0 | sha384sum -b )
    else
        read -N96 digest < <( hex2bin "$1" | sha384sum -b )
    fi
    printf '%s\n' "${digest}"
}

sha512()
{
    local -u digest
    if [[ -z "$1" ]]; then
        read -N128 digest < <( hex2bin </proc/self/fd/0 | sha512sum -b )
    else
        read -N128 digest < <( hex2bin "$1" | sha512sum -b )
    fi
    printf '%s\n' "${digest}"
}

# TODO rmd160sum in coreutils?
ripemd160()
{
    local -u digest
    if [[ -z "$1" ]]; then
        read -N40 digest < <( hex2bin </proc/self/fd/0 | openssl rmd160 )
    else
        read -N40 digest < <( hex2bin "$1" | openssl -rmd160 )
    fi
    printf '%s\n' "${digest}"
}

hash256()
{
    local -u digest
    if [[ -z "$1" ]]; then
        read -N64 digest < <( sha256 </proc/self/fd/0 | sha256 )
    else
        read -N64 digest < <( sha256 "$1" | sha256 )
    fi
    printf '%s\n' "${digest}"
}

hash160()
{
    local -u digest
    if [[ -z "$1" ]]; then
        read -N40 digest < <( sha256 </proc/self/fd/0 | ripemd160 )
    else
        read -N40 digest < <( sha256 "$1" | ripemd160 )
    fi
    printf '%s\n' "${digest}"
}
