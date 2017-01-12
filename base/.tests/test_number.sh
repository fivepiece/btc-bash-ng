#!/bin/bash

test_int_floor()
{
    local -A vectors=( [2]=2 [2.4]=2 [2.9]=2 [-2.7]=-3 [-2]=-2 )

    for int in ${!vectors[@]}; do
        if [[ "$(int_floor ${int})" != "${vectors[${int}]}" ]]; then
            printf '%s != %s\n%s != %s\n' "\$(int_floor ${int})" "\${vectors[${int}]}" \
                                          "$(int_floor ${int})" "${vectors[${int}]}"
            return 1
        fi
    done
}

test_int_ceil()
{
    local -A vectors=( [2]=2 [2.4]=3 [2.9]=3 [-2.7]=-2 [-2]=-2 )

    for int in ${!vectors[@]}; do
        if [[ "$(int_ceil ${int})" != "${vectors[${int}]}" ]]; then
            printf '%s != %s\n%s != %s\n' "\$(int_ceil ${int})" "\${vectors[${int}]}" \
                                          "$(int_ceil ${int})" "${vectors[${int}]}"
            return 1
        fi
    done
}

test_number()
{
    local -a tests=( "test_int_floor" "test_int_ceil" )
    for testi in ${tests[@]}; do
        if ! ${testi}; then
            printf '%s\n' "error: ${testi//test/}"
            return 1
        fi
    done
}
test_number || return 1
