#!/bin/bash

hmac() { # https://www.ietf.org/rfc/rfc2104.txt

    local -u key="$1" text
    #key="${1^^}"
    #text="${2^^}"

    # keys larger than the blocksize are hashed
    if (( ${#key} > $((16#${hashBlockLen})) ))
    then
        read key < <( "${hashfun}" "${key}" )
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
    readarray -t pads < <( bc <<<"set_hmac_pads(${hashBlockLen}); hmac(${#knw}, ${key}, ${hashBlockLen});" )

    # step (3)
    #text="${pads[2]}${text}"

    # steps (3) (4)
    read text < <( "${hashfun}" "${pads[2]}${2}" )

    # step (6)
    #text="${pads[1]}${text}"

    # steps (6) (7)
    #read text < <( "${hashfun}" "${pads[1]}${text}" )

    ${hashfun} "${pads[1]}${text}"
    #printf '%s\n' "${text}"
}
