#!/bin/bash

opad_128="$( input_mkbitmap '5C' '128' )"
ipad_128="$( input_mkbitmap '36' '128' )"
opad_256="$( input_mkbitmap '5C' '256' )"
ipad_256="$( input_mkbitmap '36' '256' )"

hmac_blocklen()
{
    case "$1" in
        sha224|sha256)
            printf '%s ' '128' "${opad_128}" "${ipad_128}"
            ;;
        sha384|sha512)
            printf '%s ' '256' "${opad_256}" "${ipad_256}"
            ;;
    esac
}

# https://www.ietf.org/rfc/rfc2104.txt
hmac()
{
    local -u key="$1" text="$2" opad ipad
    local -l hashfunc="$3" blocklen
    read -ers blocklen opad ipad < <( hmac_blocklen "${hashfunc}" )

    # keys larger than the blocksize are hashed
    if (( ${#key} > ${blocklen} ))
    then
        read key < <( "${hashfunc}" "${key}" )
    fi

    # (1)
    key="$( right_pad "${key}" "${blocklen}" )"
    # (2)
    ipad="$( bwxor "${key}" "${ipad}" )"
    # steps (3) (4)
    read text < <( "${hashfunc}" "${ipad}${text}" )
    # (5)
    opad="$( bwxor "${key}" "${opad}" )"
    # steps (6) (7)
    ${hashfunc} "${opad}${text}"
}

hmac_sha256()
{
    hmac "$1" "$2" 'sha256'
}

hmac_sha512()
{
    hmac "$1" "$2" 'sha512'
}
