#!/bin/bash

alias bin2bytes='od -t x1 -An -v -w1'
alias bin2hex="hexdump -v -e '\"\" 1/1 \"%02X\" \"\"'"
alias set_ifs='printf -v IFS "%b%b%b" "\\x20" "\\x09" "\\x0a"'
alias bc_clean="BC_ENV_ARGS='-q' BC_LINE_LENGTH=0 bc"
