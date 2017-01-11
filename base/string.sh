#!/bin/bash

# we sometimes change IFS to fit our export format
# this alias sets IFS back to a sane value
alias set_ifs='printf -v IFS "%b%b%b" "\\x20" "\\x09" "\\x0a"'

# pad hexstr with n zero words on the right
# $1 : hexstr
# $2 : n
rpadhexstr()
{
    local -i n="$2"
    (( $n < 0 )) && return 1
    (( ${n:-0} == 0 )) && printf '%s\n' "$1" && return
    printf "%s%0${n}d\n" "$1"
}

# pad hexstr with n zero words on the left
# $1 : hexstr
# $2 : n
lpadhexstr()
{
    local -i n="$2"
    (( $n < 0 )) && return 1
    (( ${n:-0} == 0 )) && printf '%s\n' "$1" && return
    printf "%0${n}d%s\n" '0' "$1"
}

# reverse chunks of n words in hexstr
# the length of hexstr must be a multiple of the chunk
# setting a chunk size is only possible with $2 
# $1 : hexstr
# $2 : n
revchunks () 
{ 
    local -u hexstr
    local -i chunk

    # read either from stdin or from $1
    # set a default value of 2 to chunk if none is given
    if [[ -z $1 ]]; then
        read hexstr
        chunk=2
    else
        hexstr="$1"
        chunk="${2:-2}"
        (( ! chunk )) && return 1
    fi

    # check for nonsese values in chunk
    if (( chunk > ${#hexstr} )) || \
        (( chunk <= 0 ))   || \
        (( ${#hexstr} % chunk != 0 )); then
        return 1
    fi

    # read chunks from hexstr and assign
    # them to revstr in descending order
    local -a revstr
    local -i k="$(( ${#hexstr}/chunk ))"
    while read -N${chunk} hexchunk; do
        revstr[$((k--))]="${hexchunk}"
    done <<<"${hexstr}"

    # expand revstr to a string that looks like '00 11 22...'
    # with IFS unset, removal of ' ' is possible
    # set_ifs resets IFS back to a sane value
    IFS=""
    printf '%s%b' "${revstr[*]// /}" '\n'
    set_ifs
}
