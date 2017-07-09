#!/bin/bash -x

set -x
shopt -s expand_aliases
source ./activate.sh
set_network_versions bitcoin
set +x
b=0
readarray tests < <(find . -type f -name test_*.sh -printf "${btcb_home}/%P\n")
for testsh in ${tests[@]}; do
    set -x
    source ${testsh} 2>tests.log
    set +x
    echo $? 1>&2
    if (( $? != 0 )); then
        echo "${testsh} failed" 1>&2
        tail -200 tests.log
        return 1
    fi
done

b="$?"
return "$b"
