#!/bin/bash

hmac_blocklen()
{
    case "$1" in
        sha224|sha256)
            echo '80'
            ;;
        sha384|sha512)
            echo '100'
            ;;
    esac
}

# https://www.ietf.org/rfc/rfc2104.txt
hmac()
{
    local -u key="$1" text="$2"
    local -l hashfunc="$3" blocklen
    read blocklen < <( hmac_blocklen "${hashfunc}" )

    # keys larger than the blocksize are hashed
    if (( ${#key} > $((16#${blocklen})) ))
    then
        read key < <( "${hashfunc}" "${key}" )
    fi

    local -u knw
    # number of null words to consider at the start of the key.
    # the key "1" will become "100..00", and the key "00..001"
    # will be treated as '0x01'
    #
    knw="${key%%${key/*(0)/}}"

    local -au pads
    # steps (1) (2) (5)
    # pads[0] = key
    # pads[1] = opad
    # pads[2] = ipad
    #
    readarray -t pads < <( bc <<<"hmac(${#knw}, ${key}, set_hmac_${hashfunc}());" )

    # step (3)
    #text="${pads[2]}${text}"

    # steps (3) (4)
    read text < <( "${hashfunc}" "${pads[1]}${text}" )

    # step (6)
    #text="${pads[1]}${text}"

    # steps (6) (7)
    #read text < <( "${hashfunc}" "${pads[1]}${text}" )

    ${hashfunc} "${pads[0]}${text}"
}

hmac_sha256()
{
    hmac "$1" "$2" 'sha256'
}
