#!/bin/bash

core_gen_kchain () 
{ 
    local addr privkey
    local -u pubkey
    rm ./addrs.list ./pubkeys.list ./privkeys.list
    while read -r line; do
        if [[ ! "${line}" =~ "addr" ]]; then
            continue
        fi
        addr="${line#*addr=}"
        addr="${addr% *}"
        read pubkey < <( core_addr2pubkey "${addr}" )
        read privkey < <( core_addr2privkey "${addr}" )
        echo "${addr}" >> addrs.list
        echo "${pubkey}" >> pubkeys.list
        echo "${privkey}" >> privkeys.list
    done < "./corewallet.txt"
}

core_dump_wallet () 
{ 
    "${clientname}"-cli dumpwallet "${PWD}/corewallet.txt"
}

core_get_inputs () 
{ 
    "${clientname}"-cli listunspent > inputs.json
}

core_json_rhs () 
{ 
    local rhs
    rhs="${1//[ ^\",]/}"
    echo -n "${rhs#*:}"
}

inputs_get_balance () 
{ 
    local balance total="0"
    while read -r line; do
        if [[ ! "${line}" =~ "amount" ]]; then
            continue
        fi
        read balance < <( core_json_rhs "${line}" )
        read total < <( bc_clean <<<"
							scale=8
                            total=${total}+${balance}; \
                            total;" )
    done < "./inputs.json"
    echo "${total}"
}

inputs_reduce_balance () 
{ 
    bc_clean <<< "scale=8; ${1} - ${2};"
}

core_addr2privkey () 
{ 
    "${clientname}"-cli dumpprivkey "${1}"
}

core_addr2pubkey () 
{ 
    local -a retjson
    readarray retjson < <( "${clientname}"-cli validateaddress "${1}" )
    while read -r line; do
        if [[ ! "${line}" =~ "pubkey" ]]; then
            continue
        fi
        core_json_rhs "${line^^}"
    done <<< "${retjson[@]}"
}

declare -a kc_addrs kc_pubks kc_prvks
declare -i kc_ptr

kchain_populate ()
{
    mapfile -t kc_addrs <"./addrs.list"
    mapfile -t kc_pubks <"./pubkeys.list"
    mapfile -t kc_prvks <"./privkeys.list"
    kc_pointer=0

    if (( "${#kc_addrs[@]}" != "${#kc_pubks[@]}" )) || \
        (( "${#kc_pubks[@]}" != "${#kc_prvks[@]}" )); then

        unset kc_addrs kc_pubks kc_prvks kc_pointer
        echo "Error in keystore: list size mismatch"
    fi
}

kchain_get_address ()
{
    echo "${kc_addrs[${kc_ptr}]}"
    kc_ptr="$(( ${kc_ptr} + 1 ))"
}

kchain_get_pubkey ()
{
    echo "${kc_pubks[${kc_ptr}]}"
    kc_ptr="$(( ${kc_ptr} + 1 ))"
}

kchain_get_privkey ()
{
    echo "${kc_prvks[${kc_ptr}]}"
    kc_ptr="$(( ${kc_ptr} + 1 ))"
}
