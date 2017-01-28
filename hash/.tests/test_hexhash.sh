#!/bin/bash

source ./input_hexhash.sh

test_sha224()
{
    test_hashfunc sha224 "${btests_sha224[*]}" "${htests_sha224[*]}" "${ret_sha224[*]}"
    return $?
}

test_sha256()
{
    test_hashfunc sha256 "${btests_sha256[*]}" "${htests_sha256[*]}" "${ret_sha256[*]}"
    return $?
}

test_sha384()
{
    test_hashfunc sha384 "${btests_sha384[*]}" "${htests_sha384[*]}" "${ret_sha384[*]}"
    return $?
}

test_sha512()
{
    test_hashfunc sha512 "${btests_sha512[*]}" "${htests_sha512[*]}" "${ret_sha512[*]}"
    return $?
}

test_ripemd160()
{
    test_hashfunc ripemd160 "${btests_rmd160[*]}" "${htests_rmd160[*]}" "${ret_rmd160[*]}"
    return $?
}

test_hashfunc()
{
    local -i flag=0
    local hashfunc="$1" tval
    local -a bintests=( $2 ) hextests=( $3 ) retvals=( $4 )

    # hash binary
    local -i i
    for (( i=0; i<${#bintests[@]}; i++)); do
        read tval < <( printf "${bintests[$i]}" | bin2hex | ${hashfunc} )
        if [[ "${tval}" != "${retvals[$i]}" ]]; then
            printf '%s != %s\n%s != %s\n' "\${bintests[$i]}" "\${ret_${hashfunc}[$i]}" \
                "${tval}" "${retvals[$i]}"
            return 1
        fi
    done

    # hash hex
    for (( k=0 ; k<${#hextests[@]}; k++, i++ )); do
        read tval < <( printf "${hextests[$k]}" | ${hashfunc} )
        if [[ "${tval}" != "${retvals[$i]}" ]]; then
            printf '%s != %s\n%s != %s\n' "\${hextests[$k]}" "\${ret_${hashfunc}[$i]}" \
                "${tval}" "${retvals[$i]}"
            return 1
        fi
    done
}

test_hexhash()
{
    local -a tests=( test_sha224 test_sha256 test_sha384 test_sha512 test_ripemd160 )
    for testi in ${tests[@]}; do
        if ! ${testi}; then
            printf '%s\n' "error: ${testi//test_/}"
            return 1
        fi
    done
}
test_hexhash || return 1
#unset test1 test10_256 test2_1 test2_2b test4a test7_224 test7_512 test8_256 test9_1 test9_384 test10_1 test10_384 test2_2 test3 test4b test7_256 test8_1 test8_384 test9_224 test9_512 test10_224 test10_512 test2_2a test4 test7_1 test7_384 test8_224 test8_512 test9_256
