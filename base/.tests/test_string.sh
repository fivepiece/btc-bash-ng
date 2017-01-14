#!/bin/bash

test_padhexstr()
{
    local zeros="$( input_mkbitmap 0 64 )"
    local ones="$( input_mkbitmap 1 64 )"

    local -u test_rpad test_lpad
    for i in {1..64}; do
        read test_rpad < <( rpadhexstr "$(input_mkbitmap 1 $i)" "$((64-i))" )
        if [[ "${test_rpad}" != "${ones:0:$i}${zeros:$i}" ]]; then
            printf '%s != %s\n%s != %s\n' '${test_rpad}' "\${ones:0:$i}\${zeros:$i}" \
                                          "${test_rpad}" "${ones:0:$i}${zeros:$i}"
            return 1
        fi
        read test_lpad < <( lpadhexstr "$(input_mkbitmap 1 $i)" "$((64-i))" )
        if [[ "${test_lpad}" != "${zeros:0:$((64-i))}${ones:$((64-i))}" ]]; then
            printf '%s !- %s\n%s != %s\n' '${test_lpad}' "\${zeros:0:$((64-i))}\${ones:$((64-i))}" \
                                          "${test_lpad}" "${zeros:0:$((64-i))}${ones:$((64-i))}"
            return 1
        fi
    done
}

test_revchunks()
{
    local -au hexpatt hexbmp hexrev
    hexpatt=( 10 101 10101 101011 01 010 01010 010100 )
    hexbmp=( 100 1100 11100 011100 001 0011 00011 100011 )

    for (( i=0; i<${#hexpatt[@]}; i++ )); do
        for try in $( input_walk_pattern "${hexpatt[$i]}" "${hexbmp[$i]}" 64 ); do
            read hexrev < <( revchunks "${try}" | revchunks )
            if [[ "${hexrev}" != "${try}" ]]; then
                printf '%s != %s\n%s != %s\n' '${hexrev}' '${try}' \
                                              "${hexrev}" "${try}"
                return 1
            fi
        done
    done
}

test_string()
{
    local -a tests=( "test_padhexstr" "test_revchunks" )
    for testi in ${tests[@]}; do
        if ! ${testi}; then
            printf '%s\n' "error: ${testi//test_/}"
            return 1
        fi
    done
}
test_string || return 1
