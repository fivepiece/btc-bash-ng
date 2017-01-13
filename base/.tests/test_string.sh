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
