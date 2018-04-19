#!/bin/bash

# in : length of data in words
# out: length in compactsize
data_compsize () 
{ 
    local len size order

    if [[ "${1}" == "" ]]; then
        read len
    else
        len="${1}"
    fi

    read size < <( bc_bitcoin <<<"
        obase=A; ibase=A;
        size=(${len}/2);
        obase=16; ibase=16;
        compsize(size);" )

    if (( $((16#${size})) > 252 )); then
        order="${size:0:2}"
        read size < <( revchunks "${size:2}" )
    fi
    echo "${order}""${size}"
}

# in : length of data in words
# out: "<push operation> 0x"
data_wsize2pushop()
{
    bc_bitcoin <<<"wsize2pushop(${1^^});"
}

# in : length of data in decimal
# out: length of data in words
data_size2wsize()
{
    bc_clean <<<"
        size=${1};
        obase=16; ibase=16;
        size;"
}

# in : data to be pushed
# out: serialized push
data_pushdata()
{
    local -u data size
    local -a pushop
    data="${1}"

    if (( "${#data}" == 2 )); then

        local data16="$((16#${data}))"

        if [[ "${op_num[${data16}]}" != "" ]]; then

            echo "0x${op_num[${data16}]}"
            return
        fi

        if [[ "${data}" == '81' ]]; then

            echo "0x${op_num[-1]}"
            return
        fi
    fi

    read size < <( data_size2wsize "${#data}" ) 
    readarray -t pushop < <( data_wsize2pushop "${size}" )
    read pushop[1] < <( revchunks <<<"${pushop[1]}" )

    echo "${pushop[0]}${pushop[1]} 0x${data}"
}

# in : data separated by spaced, sorrounded by quotes
# out: serialized push
data_pushmany()
{
    local -a tmparr
    local -a data

    read -r -a data <<<"${1^^}"

    local -i j
    for (( i=0; i<"${#data[@]}"; i++ )); do

        read tmparr[${i}] < <( data_pushdata "${data[${i}]}" )
    done

    echo "${tmparr[@]}"
}

# in : bitcoin script in asm
# out: the script serialized in hex
script_serialize ()
{ 
    local -a script
    read -r -a script <<<"${@}"
    local pushdata serdata pushnum hextext ser=""

    for ((i=0; i<${#script[@]}; i++ )); do
        
        elem="${script[${i}]}"

        if [[ "${elem:0:2}" == "0x" ]]; then   # literal element: 0x7093, 0xAABB00 ...
            ser+="${elem/0x/}"
        elif [[ "${elem:0:1}" == "@" ]]; then  # hex data push: @AA10 -> 02AA10, @0A -> 5A, @81 -> 4F ...
            read pushdata < <( data_pushdata "${elem:1}" )
            read serdata < <( script_serialize "${pushdata}" )
            ser+="${serdata}"
        elif script_is_bignum "${elem}"; then  # bignum [-2^31+1, 2^31-1]: -100, 999,  1512, 0 ...
            read pushnum < <( script_ser_num "${elem}" )
            pushnum="${pushnum[*]// /}"
            ser+="${pushnum//0x/}"
        elif [[ "${elem:0:1}" == "%" ]]; then  # text %abcd -> 0x0461626364
            read hextext < <( bin2hex <<<"${elem:1}" )
            read pushdata < <( data_pushdata "${hextext:0:-2}" )
            read serdata < <( script_serialize "${pushdata}" )
            ser+="${serdata}"
        else                                   # opcode element (or INVALIDOPCODE)
            ser+="${opcodes[${elem}]:-FF}"
        fi
    done

    echo "${ser^^}"
}

# in : pubkey
# out: p2pk script in asm
spk_pay2pubkey()
{
    local -a tmpscript
    local pushop_pubkey

    tmpscript=( "${script_p2pkey[@]}" )
    read pushop_pubkey < <( data_pushdata "${1}" )

    tmpscript[0]="${pushop_pubkey}"

    echo "${tmpscript[@]}"
}

# in : base58 address
# out: p2pkh script in asm
spk_pay2pkhash()
{
    local -a tmpscript
    local pkhash

    tmpscript=( "${script_p2pkh[@]}" )
    read pkhash < <( key_addr2hash160 "${1}" )

    tmpscript[3]="0x${pkhash}"

    echo "${tmpscript[@]}"
}

# in 1: 'm' value of m-of-n script
# in 2: pubkeys separated by spaces, surrounded by quotes
# out : m-of-n bare multisig script in asm
spk_pay2mofn()
{
    local -a pubkeys tmpscript
    local -i m="${1}" n
    pubkeys=( ${2} )
    n="${#pubkeys[@]}"

    if (( "${m}" > "${n}" )); then
        # error, setting m=1
        m='1'
    fi

    tmpscript=( "${script_mofn[@]}" )

    tmpscript[0]="${m}"
    read tmpscript[1] < <( data_pushmany "${pubkeys[*]}" )
    tmpscript[2]="${n}"

    echo "${tmpscript[@]}"
}

# in : scriptpubkey in asm, surrounded by quotes
# out: p2sh script in asm
spk_pay2shash()
{
    local -a script tmpscript
    local -u scripthash

    script=( ${1} )
    read scripthash < <( script_serialize "${script[*]}" | hash160 )
    tmpscript=( "${script_p2sh[@]}" )

    tmpscript[2]="0x${scripthash}"

    echo "${tmpscript[@]}"
}

# in : base58 address
# out: p2wpkh script in asm
spk_pay2wpkhash()
{
    local -a tmpscript
    local -u pkhash

    tmpscript=( "${script_p2wpkh[@]}" )
    read pkhash < <( key_addr2hash160 "${1}" )

    tmpscript[2]="0x${pkhash}"

    echo "${tmpscript[@]}"
}

# in : scriptpubkey in asm, surrounded by quotes
# out: p2wsh script in asm
spk_pay2wshash()
{
    local -a script tmpscript
    local -u scripthash

    script=( ${1} )
    read scripthash < <( script_serialize "${script[*]}" | sha256 )
    tmpscript=( "${script_p2wsh[@]}" )

    tmpscript[2]="0x${scripthash}"

    echo "${tmpscript[@]}"
}

spk_pay2ced()
{
    local -a escrow_script="${2}" timeout_script="${3}" tmpscript
    local timeout="${1}"

    tmpscript=( "${script_ced[@]}" )
    read timeout < <( script_ser_num "${timeout}" )

    tmpscript[1]="${escrow_script}"
    tmpscript[3]="${timeout}"
    tmpscript[6]="${timeout_script}"

    echo "${tmpscript[@]}"
}

spk_pay2mshash()
{
    local -a keycode=( ${1} ) tmpscript=( ${script_p2wv1[@]} )
    local -u scriptroot serscript keycodehash path="$2"
    local -u scripthash position="$3" k leaf depth version="${4:-00000000}"

    decho "keycode : ${keycode[@]}"

    read serscript < <( script_serialize "0 ${keycode[@]}" )
    decho "serscript : ${serscript}"

    read keycodehash < <( sha256 "${serscript}" )
    decho "keycodehash : ${keycodehash}"

    depth="$(( ${#path}/64 ))"
    iter="${keycodehash}"
    decho "depth : ${depth}"
    decho "position : ${position}"
    read leaf < <( BC_ENV_ARGS='-q' bc_clean <<<"obase=2; ((2^${depth})+${position})" | rev )
    decho "leaf : ${leaf}"
    for (( i=0, j=${leaf:0:1}; i<$((${#leaf}-1)); ++i, j=${leaf:$i:1} )); do
        decho "\${leaf:$i:1} = ${leaf:$i:1}"
        if (( ${leaf:$i:1} == 0 )); then
            decho "iter < <( sha256 "${iter}\|${path:$((i*64)):64}" )"
            read iter < <( sha256 "${iter}${path:$((i*64)):64}" )
        else
            decho "iter < <( sha256 "${path:$((i*64)):64}\|${iter}" )"
            read iter < <( sha256 "${path:$((i*64)):64}${iter}" )
        fi
    done

    #leaf="$(( position % 2 ))"
    #decho "${path:0:$((leaf*64))}|${scripthash}|${path:$(((leaf)*64))}"
    #tree="${path:0:$((leaf*64))}${scripthash}${path:$(((leaf)*64))}"
    #iter="${tree:0:64}"
    #for (( i=64; i<${#tree}; i+=64 )); do
    #    echo "read iter < <( hash256 "${iter}\|${tree:$i:64}" )"
    #    read iter < <( hash256 "${iter}${tree:$i:64}" )
    #    echo "iter : ${iter}"
    #done
    tmpscript[2]="0x${iter:-${keycodehash}}"
    echo "${tmpscript[@]}"
}

spk_pay2wpkv0 ()
{
    echo "0x5121${1}"
}

#spk_pay2wmast()
#{
#    local -a mastroot tmpscript
#    local -u masthash
#
#    # script=( ${1} )
#    read mastroot < <( script_serialize "$1" )
#    read masthash < <( printf "${mastroot}" | hash256 )
#    tmpscript=( "${script_p2wmast[@]}" )
#
#    tmpscript[2]="0x${masthash}"
#
#    echo "${tmpscript[@]}"
#}
