#!/bin/bash

test_bits2int()
{
    local -au vector

    local -u tb2i vb2i
    for bits in {1,10,101,1011,10101}; do

        readarray -t vector < <( for i in {1..64}; do input_mkbitmap ${bits} $i; done )
        for vect in ${vector[@]}; do

            read tb2i < <( bits2int "${vect}" )
            read vb2i < <( bc_clean <<<"obase=2; ibase=16; ${tb2i};" )

            if [[ "${vb2i}" != "${vect}" ]]; then
                printf '%s != %s\n%s != %s\n' '${vb2i}' '${vect}' \
                                              "${vb2i}" "${vect}"
                return 1
            fi
        done
    done
}

test_int2octets()
{
    local -ua vectors
    local -u ti2o vi2o
    printf -v vectors[0] '%02X ' {0..255}
    printf -v vectors[1] '%s%02X ' '0100000000000000' {0..255}
    printf -v vectors[2] '%s%02X ' 'FF000000' {0..255}

    for i in {0..2}; do
        for v in ${vectors[$i]}; do
            read ti2o < <( int2octets ${v} 64 )
            read vi2o < <( bc_clean <<<"obase=16; ibase=16; ${ti2o};" )
            read vi2o < <( int2octets ${vi2o} 64 )
            if [[ "${ti2o}" != "${vi2o}" ]]; then
                printf '%s != %s\n%s != %s\n' '${ti2o}' '${vi2o}' \
                                              "${ti2o}" "${vi2o}"
                return 1
            fi
        done
    done
}

test_bits2octets()
{
    local -u tb2o vb2o
    local -u q=FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141

    for bits in {1,10,101,1011,10101}; do
        for i in {1..256}; do
            read tb2o < <( bits2octets "$(input_mkbitmap ${bits} $i)" "$q" )
            read vb2o < <( bc_clean <<<"obase=2; ibase=16; ${tb2o};" )
            read vb2o < <( bits2int "${vb2o}" )
            if (( $( bc_clean <<<"ibase=16; (${vb2o} != ${tb2o})") )); then
                printf '%s != %s\n%s != %s\n' '${vb2o}' '${tb2o}' \
                                              "${vb2o}" "${tb2o}"
                return 1
            fi
            if (( ${#tb2o} != ${#q} )); then
                printf '%s != %s\n%s != %s\n' '${#vb2o}' '${#tb2o}' \
                                              "${#vb2o}" "${#tb2o}"
                return 1
            fi
        done
    done
}

test_int_convert()
{
    local -a tests=( "test_bits2int" "test_int2octets" "test_bits2octets" )
    for testi in ${tests[@]}; do
        if ! ${testi}; then
            printf '%s\n' "error: ${testi//test_/}"
            return 1
        fi
    done
}
test_int_convert || return 1
