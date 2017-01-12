#!/bin/bash

alias bc_clean='BC_ENV_ARGS='\''-q'\'' BC_LINE_LENGTH=0 bc'

# [x]   = x - {x} ,
# r < 0 ? : --[x]
int_floor()
{
    local int
    read int < <( bc_clean <<<"x=$1; scale=0; r=(x-(x/1)); x-r-(r < 0);" )

    printf '%s\n' "${int%\.*}"
}

# [x]    = x + (1 -{x}) ,
# r <= 0 ? : --[x]
int_ceil()
{
    local int
    read int < <( bc_clean <<<"x=$1; scale=0; r=(x-(x/1)); x+(1-r)-(r <= 0);" )

    printf '%s\n' "${int%\.*}"
}
