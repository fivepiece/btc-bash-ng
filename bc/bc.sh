#!/bin/bash

_bc="${BC_PROG}"
export BC_LINE_LENGTH=0

BC_ENV_ARGS='-q -l' ${_bc} \
    ./config.bc \
    ./base/conversion.bc ./base/helpers.bc \
    ./logic/bitwise_logic.bc ./logic/shift_rot.bc \
    ./math/math_mod.bc ./math/extended_euclidean.bc ./math/tonelli_shanks.bc ./math/root_mod.bc \
    ./ec_math/endomorphism.bc ./ec_math/ec_point.bc ./ec_math/ec_math.bc ./ec_math/jacobian.bc \
    ./ecdsa/ecdsa.bc \
    ./ec_math/curves/koblitz.bc ./activate.bc
