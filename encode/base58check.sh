#!/bin/bash

declare -A _b58Dec
_b58Dec=( \
    [A]=09 [B]=10 [C]=11 [D]=12 [E]=13 [F]=14 [G]=15 [H]=16 \
    [J]=17 [K]=18 [L]=19 [M]=20 [N]=21 [P]=22 [Q]=23 [R]=24 \
    [S]=25 [T]=26 [U]=27 [V]=28 [W]=29 [X]=30 [Y]=31 [Z]=32 \
    [a]=33 [b]=34 [c]=35 [d]=36 [e]=37 [f]=38 [g]=39 [h]=40 \
    [i]=41 [j]=42 [k]=43 [m]=44 [n]=45 [o]=46 [p]=47 [q]=48 \
    [1]=00 [r]=49 [2]=1 [s]=50 [3]=2 [t]=51 [4]=3 [u]=52 [5]=4 \
    [v]=53 [6]=5 [w]=54 [7]=6 [x]=55 [8]=7 [y]=56 [9]=8 [z]=57)

declare -a _b58Enc
_b58Enc=(\
    1 2 3 4 5 6 7 8 9 A B C D E F G H J K \
    L M N P Q R S T U V W X Y Z a b c d e \
    f g h i j k m n o p q r s t u v w x y z)

base58enc()
{
    local -u hexstr
    local b58out zeroprefix
    if [[ "${1}" == "" ]]
    then
        read hexstr
    else
        hexstr="${1}"
    fi

    zeroprefix="${hexstr%%${hexstr/*(00)/}}"
    zeroprefix="${zeroprefix//00/1}"
    printf "%s%s" "${zeroprefix}"

    read b58out < <( bc_clean <<<" \
        obase = 58; \
        ibase = 16; \
        ${hexstr};" )
    # echo "${b58out}"
    for b58 in ${b58out}; do
        printf '%s' "${_b58Enc[$((10#${b58}))]}"
    done
    echo
}

base58dec()
{
	local b58str oneprefix
	if [[ "${1}" == "" ]]
	then
		read b58str
	else
		b58str="${1}"
	fi

    local -a b58arr_bc
    b58arr_bc[0]="c[0]=${#b58str};"
    for (( i=$(( ${#b58str}-1)), j=1; i >= 0; i--, j++ ))
    do
        b58arr_bc[${j}]="c[${j}]=${_b58Dec[${b58str:${i}:1}]}; "
    done

    oneprefix="${b58str%%[^1]*}"
    oneprefix="${oneprefix//1/00}"
    printf "%s" "${oneprefix}"

	local -u hexstr
    bc_encode <<<" \
        ibase=A;
        ${b58arr_bc[@]} \
        hex = base_restore(58, c[]); \
        ibase=16; \
        if (wordlen(hex) % 2) { print 0; }; \
        hex;"
}
