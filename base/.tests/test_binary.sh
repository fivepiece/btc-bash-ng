#!/bin/bash

test_binary()
{
    local -u bytes_str=( $(printf '%02X' {0..255}) )

    local hex2bin2hex="printf "${bytes_str}" | hex2bin | bin2hex"
    local -u test_bin2hex
    read test_bin2hex < <( ${hex2bin2hex} )
    if [[ "${test_bin2hex}" != "${bytes_str}" ]]; then
        printf '%s != %s\n%s != %s\n' '${hex2bin2hex}' '${test_bin2hex}' \
                                    "$( ${hex2bin2hex} )" "${test_bin2hex}"
        return 1
    fi

    local -au bytes_arr test_bin2bytes
    readarray -t bytes_arr < <( printf '%02X\n' {0..255} )
    test_bin2bytes=( $(printf "${bytes_str}" | hex2bin | bin2bytes) )

    if (( ${#bytes_arr[@]} != ${#test_bin2bytes[@]} )); then
        printf '%s != %s\n%s != %s\n' '${#bytes_arr[@]}' '${#test_bin2bytes[@]}' \
                                      "${#bytes_arr[@]}" "${#test_bin2bytes[@]}"
        return 1
    fi

    for ((i=0; i<${#bytes_arr[@]}; i++)); do
        if [[ ${bytes_arr[$i]} != ${test_bin2bytes[$i]} ]]; then
            printf '%s != %s\n%s != %s\n' "\${bytes_arr[$i]}" "\${test_bin2bytes[$i]}" \
                                          "${bytes_arr[$i]}" "${test_bin2bytes[$i]}"
            return 1
        fi
    done
}
test_binary || return 1
