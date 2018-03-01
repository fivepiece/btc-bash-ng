#!/bin/bash

# https://tools.ietf.org/html/rfc6979#section-3.2
rfc6979 ()
{
    local -u key="$1" msg="$2"
    local hashfunc="$3" hlen="$4"
    local vlen="$(( 8 * $(int_ceil "${hlen}/8") ))"

    # keys shorter than the keysize are right padded with 0x00's
    if (( ${#key} < ${hlen} )); then
        read key < <( left_pad "${key}" "${hlen}" )
    fi

    local -u h1 v k t foundk
    # 3.2.a
    read h1 < <( "${hashfunc}" "${msg}" )
    decho "\n# key : ${key}"
    decho "# sighash : ${h1}"

    # 3.2.b
    read v < <( input_mkbitmap '01' "${vlen}" )
    decho "# 3.2.b, v : ${v}"

    # 3.2.c
    read k < <( input_mkbitmap '00' "${vlen}" )
    decho "# 3.2.c, k : ${k}"

    # 3.2.d
    read k < <( hmac "${k}" "${v}00${key}${h1}" "${hashfunc}" )
    # 3.2.e
    read v < <( hmac "${k}" "${v}" "${hashfunc}" )

    decho "# 3.2.d, k : ${k}"
    decho "# 3.2.e, v : ${v}"

    # 3.2.f
    read k < <( hmac "${k}" "${v}01${key}${h1}" "${hashfunc}" )
    # 3.2.g
    read v < <( hmac "${k}" "${v}" "${hashfunc}" )

    decho "# 3.2.f, k : ${k}"
    decho "# 3.2.g, v : ${v}"

    # 3.2.h
    while :; do
        decho "start 3.2.h"
        # 3.2.h.1
        t=""

        # 3.2.h.2
        while (( ${#t} < ${hlen} )); do
            decho "start 3.2.h.2"
            read v < <( hmac "${k}" "${v}" "${hashfunc}" )
            t="${t}${v}"
            decho "# 3.2.h.2, v : ${v}"
            decho "# 3.2.h.2, t : ${t}"
            decho "end   3.2.h.2"
        done

        # 3.2.h.3
        # lexicographical (avoid bc)
        if [[ "${curve_one}" < "${t}" ]] && [[ "${t}" < "${curve_n}" ]]; then
            echo "${t}"
            return
        fi

        read k < <( hmac "${k}" "${v}00" "${hashfunc}" )
        decho "# 3.2.h.3, k : ${k}"
        decho "end   3.2.h"
#       read v < <( hmac "${k}" "${v}" )   # TODO is this needed?
    done
}

rfc6979_secp256k1_sha256_k()
{
    rfc6979 "$1" "$2" 'sha256' '64'
}
