#!/bin/bash -x

set -x
source ./activate.sh

b=0
readarray tests < <(find . -type f -name test_*.sh -printf "${btcb_home}/%P\n")
for testsh in ${tests[@]}; do
    source ${testsh} || (echo "${testsh} failed" 1>&2; return 1)
done

b="$?"
set +x
return "$b"
