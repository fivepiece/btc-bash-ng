#!/bin/bash

bc_home="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && echo $PWD )"
# bc_prog="$HOME/software/deps/bc-1.07.1/bc/bc"

export BC_LINE_LENGTH=0
bc_flags="-q"
unset bc_env
declare -A bc_env=(
    [config]="${bc_home}/config.bc"
    [conversion]="${bc_home}/base/conversion.bc"
    [helpers]="${bc_home}/base/helpers.bc"
    [bitcoin]="${bc_home}/bitcoin/bitcoin_funcs.bc"
    [bitwise_logic]="${bc_home}/logic/bitwise_logic.bc"
    [shift_rot]="${bc_home}/logic/shift_rot.bc"
    [hmac_conf]="${bc_home}/hash/hmac_conf.bc"
    [hmac]="${bc_home}/hash/hmac.bc"
    [math_mod]="${bc_home}/math/math_mod.bc"
    [extended_euclidean]="${bc_home}/math/extended_euclidean.bc"
    [tonelli_shanks]="${bc_home}/math/tonelli_shanks.bc"
    [root_mod]="${bc_home}/math/root_mod.bc"
    [endomorphism]="${bc_home}/ec_math/endomorphism.bc"
    [ec_point]="${bc_home}/ec_math/ec_point.bc"
    [ec_math]="${bc_home}/ec_math/ec_math.bc"
    [jacobian]="${bc_home}/ec_math/jacobian.bc"
    [ecdsa]="${bc_home}/ecdsa/ecdsa.bc"
    [contract_hash]="${bc_home}/ecdsa/contract_hash.bc"
    [koblitz]="${bc_home}/ec_math/curves/koblitz.bc"
    [ec_schnorr]="${bc_home}/schnorr/ec_schnorr.bc"
    [activate]="${bc_home}/activate.bc" )

unset BC_ENV_ARGS;
export BC_ENV_ARGS="${bc_flags} ${bc_env[config]} ${bc_env[conversion]} ${bc_env[helpers]} ${bc_env[bitwise_logic]} ${bc_env[shift_rot]} ${bc_env[hmac_conf]} ${bc_env[hmac]} ${bc_env[math_mod]} ${bc_env[extended_euclidean]} ${bc_env[tonelli_shanks]} ${bc_env[root_mod]} ${bc_env[endomorphism]} ${bc_env[ec_point]} ${bc_env[ec_math]} ${bc_env[jacobian]} ${bc_env[ecdsa]} ${bc_env[ec_schnorr]} ${bc_env[koblitz]} ${bc_env[activate]}"

alias bc="${bc_prog}"
alias bc_clean="BC_ENV_ARGS='-q' bc"
alias bc_encode="bc_clean ${bc_env[config]} ${bc_env[conversion]} ${bc_env[helpers]}"
alias bc_bitcoin="bc_encode ${bc_env[bitcoin]}"
alias bc_hmac="bc_encode ${bc_env[bitwise_logic]} ${bc_env[hmac_conf]} ${bc_env[hmac]} ${bc_env[koblitz]} ${bc_env[activate]}"

# alias _bc_math="bc_encode ${bc_env[math_mod]} ${bc_env[tonelli_shanks]} ${bc_env[root_mod]}"
# bc_math ()
# {
#     _bc_math "${bc_env[koblitz]}" "${bc_env[activate]}"
# }

alias _bc_ecpoint="bc_encode ${bc_env[math_mod]} ${bc_env[tonelli_shanks]} ${bc_env[root_mod]} ${bc_env[endomorphism]} ${bc_env[ec_point]}"
bc_ecpoint ()
{
    _bc_ecpoint "${bc_env[koblitz]}" "${bc_env[activate]}"
}
alias _bc_ecmath="_bc_ecpoint ${bc_env[ec_math]}"

bc_ecmath ()
{
    _bc_ecmath "${bc_env[koblitz]}" "${bc_env[activate]}"
}

alias bc_ecdsa="_bc_ecmath ${bc_env[ecdsa]} ${bc_env[koblitz]} ${bc_env[activate]}"
alias bc_ecschnorr="_bc_ecmath ${bc_env[ec_schnorr]} ${bc_env[koblitz]} ${bc_env[activate]}"
