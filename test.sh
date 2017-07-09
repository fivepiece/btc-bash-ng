#!/bin/bash -x

echo "" > tests.log
set -x
shopt -s expand_aliases
source ./activate.sh
set_network_versions bitcoin
set +x
b=0
readarray tests < <(find . -type f -name test_*.sh -printf "${btcb_home}/%P\n")
for testsh in ${tests[@]}; do
    set -x
    source ${testsh} 2>&1 | grep -v "read -N2 byte\|printf %b '\\\x[0-F][0-F]\|read -N2 hexchunk" >> tests.log
    # this used to check "$?".  the best solution for this uglyness is something like a 100mb output limit on travis-ci :)
    if (( ${PIPESTATUS[0]} != 0 )); then
        set +x
        echo "${testsh} failed" 1>&2
        tail -1000 tests.log
        return 1
    fi
    set +x
done

set +x
b="$?"
return "$b"
