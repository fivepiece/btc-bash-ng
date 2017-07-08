#!/bin/bash -x

set -x
shopt -s expand_aliases
source ./activate.sh
set_network_versions bitcoin

b=0
readarray tests < <(find . -type f -name test_*.sh -printf "${btcb_home}/%P\n")
for testsh in ${tests[@]}; do
    source ${testsh}
    if (( $? != 0 )); then
        echo "${testsh} failed" 1>&2
        set +x
        return 1
    fi
    # echo $?
done 2>tests.log

b="$?"
set +x
tail -200 tests.log
return "$b"
