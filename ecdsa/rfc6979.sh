#!/bin/bash

# https://tools.ietf.org/html/rfc6979#section-3.2
rfc6979 ()
{
    local -u key="$1" msg="$2"
    local hashfunc="$3" hlen="$4"
    local vlen="$(( 8 * $(int_ceil "${hlen}/8") ))"

    # keys shorter than the keysize are right padded with 0x00's
    if (( ${#key} < ${hlen} ))
    then
        read key < <( left_pad "${key}" "${hlen}" )
    fi

    local -u h1 v k t foundk
    # 3.2.a
    read h1 < <( "${hashfunc}" "${msg}" )
#    echo
#    echo "# key : ${key}"
#    echo "# sighash : ${h1}"

    # 3.2.b
    # read v < <( printf "%0*d" "${hmacVDecLen}" 0 )
    # v="${v//0/01}"
    read v < <( input_mkbitmap '01' "${vlen}" )
#    echo "# 3.2.b, v : ${v}"

    # 3.2.c
    # read k < <( printf "%0*d" "${hmacVDecLen}" 0 )
    # k="${k//0/00}"
    read k < <( input_mkbitmap '00' "${vlen}" )
#    echo "# 3.2.c, k : ${k}"

    # 3.2.d
    read k < <( hmac "${k}" "${v}00${key}${h1}" "${hashfunc}" )
    # 3.2.e
    read v < <( hmac "${k}" "${v}" "${hashfunc}" )

#    echo "# 3.2.d, k : ${k}"
#    echo "# 3.2.e, v : ${v}"

    # 3.2.f
    read k < <( hmac "${k}" "${v}01${key}${h1}" "${hashfunc}" )
    # 3.2.g
    read v < <( hmac "${k}" "${v}" "${hashfunc}" )

#    echo "# 3.2.f, k : ${k}"
#    echo "# 3.2.g, v : ${v}"

    # 3.2.h
    while :
    do
#        echo "start 3.2.h"
        # 3.2.h.1
        t=""

        # 3.2.h.2
        while (( ${#t} < ${hlen} ))
        do
#            echo "start 3.2.h.2"
            read v < <( hmac "${k}" "${v}" "${hashfunc}" )
            t="${t}${v}"
#            echo "# 3.2.h.2, v : ${v}"
#            echo "# 3.2.h.2, t : ${t}"
#            echo "end   3.2.h.2"
        done

        # 3.2.h.3
        read foundk < <( \
            bc_clean ${bc_env[config]} ${bc_env[koblitz]} ${bc_env[activate]} <<<"\
            (1 < ${t}) && (${t} < curve_n);" 2>/dev/null )
#         echo "# foundk = ${foundk}"

        if (( "${foundk}" == 1 ))
        then
            echo "${t}"
            return
        fi

        read k < <( hmac "${k}" "${v}00" "${hashfunc}" )
#        echo "# 3.2.h.3, k : ${k}"
#        echo "end   3.2.h"
#       read v < <( hmac "${k}" "${v}" )   # TODO is this needed?
    done
}

rfc6979_secp256k1_sha256_k()
{
    rfc6979 "$1" "$2" 'sha256' '64'
}
