#!/bin/bash

test_bip173_vectors()
{
    valid_bech32=( \
        'A12UEL5L' \
        'a12uel5l' \
        'an83characterlonghumanreadablepartthatcontainsthenumber1andtheexcludedcharactersbio1tt5tgs' \
        'abcdef1qpzry9x8gf2tvdw0s3jn54khce6mua7lmqqqxw' \
        '11qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqc8247j' \
        'split1checkupstagehandshakeupstreamerranterredcaperred2y9e3w' \
        '?1ezyfcl' )

    invalid_bech32=( \
        "$( printf '%b%s' '\x20' '1nwldj5' )" \
        "$( printf '%b%s' '\x7f' '1axkwrx' )" \
        "$( printf '%b%s' '\x80' '1eym55h' )" \
        'an84characterslonghumanreadablepartthatcontainsthenumber1andtheexcludedcharactersbio1569pvx' \
        'pzry9x0s0muk' \
        '1pzry9x0s0muk' \
        'x1b4n0q5v' \
        'li1dgmt3' \
        "$( printf '%s%b' 'de1lg7wt' '\xff' )" \
        'A1G7SGD8' \
        '10a06t8' \
        '1qzzfhee' )

    valid_segwit=( \
        'BC1QW508D6QEJXTDG4Y5R3ZARVARY0C5XW7KV8F3T4:0014751e76e8199196d454941c45d1b3a323f1433bd6' \
        'tb1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3q0sl5k7:00201863143c14c5166804bd19203356da136c985678cd4d27a1b8c6329604903262' \
        'bc1pw508d6qejxtdg4y5r3zarvary0c5xw7kw508d6qejxtdg4y5r3zarvary0c5xw7k7grplx:5128751e76e8199196d454941c45d1b3a323f1433bd6751e76e8199196d454941c45d1b3a323f1433bd6' \
        'BC1SW50QA3JX3S:6002751e' \
        'bc1zw508d6qejxtdg4y5r3zarvaryvg6kdaj:5210751e76e8199196d454941c45d1b3a323' \
        'tb1qqqqqp399et2xygdj5xreqhjjvcmzhxw4aywxecjdzew6hylgvsesrxh6hy:0020000000c4a5cad46221b2a187905e5266362b99d5e91c6ce24d165dab93e86433' )

    invalid_segwit=( \
        'tc1qw508d6qejxtdg4y5r3zarvary0c5xw7kg3g4ty' \
        'bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t5' \
        'BC13W508D6QEJXTDG4Y5R3ZARVARY0C5XW7KN40WF2' \
        'bc1rw5uspcuh' \
        'bc10w508d6qejxtdg4y5r3zarvary0c5xw7kw508d6qejxtdg4y5r3zarvary0c5xw7kw5rljs90' \
        'BC1QR508D6QEJXTDG4Y5R3ZARVARYV98GJ9P' \
        'tb1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3q0sL5k7' \
        'bc1zw508d6qejxtdg4y5r3zarvaryvqyzf3du' \
        'tb1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3pjxtptv' \
        'bc1gmk9yu' )
}

test_bech32_valid_bech32 ()
{
    for vbech32 in ${valid_bech32[@]}; do
        if ! bech32_decode "${vbech32}"; then
            return 1
        fi
    done
}

test_bech32_invalid_bech32 ()
{
    for ibech32 in ${invalid_bech32[@]}; do
        if bech32_decode "${ibech32}"; then
            return 1
        fi
    done
}

test_bech32_valid_segwit ()
{
    local addr script decoded
    for pair in ${valid_segwit[@]}; do
        addr="${pair%:*}"
        script="${pair#*:}"
        if ! segwit_decode "${addr}"; then
            return 1
        fi
        decoded="$( segwit_decode "${addr}" )"
        if [[ "${script}" != "${decoded,,}" ]]; then
            return 1
        fi
    done
}

test_bech32_invalid_segwit ()
{
    for isegwit in ${invalid_segwit[@]}; do
        if segwit_decode "${isegwit}"; then
            return 1
        fi
    done
}

test_bech32 ()
{
    test_bip173_vectors

    test_bech32_valid_bech32 || return 1
    test_bech32_invalid_bech32 || return 1
    test_bech32_valid_segwit || return 1
    test_bech32_invalid_segwit || return 1
}
test_bech32 || false
