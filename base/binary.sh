#!/bin/bash

# outputs any input as bytes separated by newlines
# useful for setting arrays
# printf '%s' STR | bin2bytes : " byte byte..."
# bin2bytes <<<"STR" : " byte byte... 0a"
# bin2bytes FILE : " byte byte..."
alias bin2bytes='od -t x1 -An -v -w1'

# outputs any input in hex
# prtinf '%s' STR | bin2hexstr : "HEX..."
# bin2hex <<<"STR" : "HEX...0x0A"
# bin2hex FILE : "HEX..."
alias bin2hex="hexdump -v -e '\"\" 1/1 \"%02X\" \"\"'"

# removed newlines and tabs from hex input and turns to upper case
# a newline is redirected to stderr so it's not added to the output
alias cleanhex="tr -d ' \n\t' | tr [:lower:] [:upper:]; echo 1>&2"

# print the raw value of hexstr
# echo HEX | hex2bin : BIN
# hex2bin HEX : BIN
hex2bin()
{
    # if $1 is empty, read from stdin
    # TODO find a way to expand '<<<"$1"' somehow to re-use the loop
    if [[ -z "$1" ]]; then

        while read -N2 byte; do
           printf '%b' "\\x${byte}"
        done
    else
        while read -N2 byte; do
           printf '%b' "\\x${byte}"
        done <<<"$1"
    fi
}

# get n bytes from urandom
randhex()
{
    bin2hex -n"$1" /dev/urandom
    echo
}
