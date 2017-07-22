#!/bin/bash

schnorr_hs_sign ()
{
    local -u m="$1" d="$2" a="$3" k r h

    read k < <( rfc6979_secp256k1_sha256_k "$d" "$m" )
    r="$( bc_ecmath <<<" \
        ecmul_api(${k}, curve_gx, curve_gy, curve_n, curve_p, r[]); \
        left_pad(r[0], curve_words);")"
    read h < <( sha256 "${m}${r}${a}" )
    printf '%s ' "$h"
    bc_ecschnorr <<<"ec_schnorr_sign(${h}, ${d}, ${k});"
}

schnorr_hs_verify ()
{
    local -u m="$1" p="$2" h="$3" s="$4" a="$5" q v

    q="$( bc_ecschnorr <<<"ec_schnorr_verify(${p}, ${h}, ${s});")"
    if [[ -z ${q/0//} ]]; then
        echo "false (q == 0)" 1>&2
        return 1
    fi
    read v < <( sha256 "${m}${q}${a}" )
    if [[ "$v" == "$h" ]]; then
        echo "true" 1>&2
    else
        echo "false (v != h)" 1>&2
    fi
}

schnorr_rs_sign ()
{
    local -u m="$1" d="$2" k q h

    read k < <( rfc6979_secp256k1_sha256_k "$d" "$m" )
    read k r < <( bc_ecschnorr <<<" \
        ecmul_api(${k}, curve_gx, curve_gy, curve_n, curve_p, r[]); \
        if ( ! is_residue( r[1], 2, curve_p )){ \
            print mod(-${k}, curve_n), \" \"; \
        } else { \
            print ${k}, \" \"; \
        }; \
        left_pad(r[0], curve_words);")
    read h < <( sha256 "${r}${m}" )
    printf '%s ' "${r}"
    bc_ecschnorr <<<"ec_schnorr_sign(${h}, ${d}, ${k});"
}

schnorr_rs_verify ()
{
    local -u m="$1" q="$2" r="$3" s="$4" h

    # if ! bc_ecmath <<<"( (${s} < curve_n) && (${r} < curve_n)"; then
    #     echo "invalid signature" 1>&2
    #     return 1
    # fi
    read h < <( sha256 "${r}${m}" )
    v="$(bc_ecschnorr <<<" \
        if ( (${s} >= curve_n) || \
             (${r} >= curve_p) || \
             ((${h} > 0) && (${h} >= curve_n))){ \
             print \"invalid (r,s,h)\\n\"; \
             halt; \
        }; \
        uncompresspoint_api(${q}, q[]); \
        valid = ec_schnorr_verify_api(q[0], q[1], curve_gx, curve_gy, ${h}, ${s}, curve_n, curve_p, v[]); \
        if ( valid && is_residue(v[1], 2, curve_p) ){ \
            left_pad(v[0], curve_words); \
        } else { 0; };")"
    if [[ "${v}" == "${r}" ]]; then
        echo "true" 1>&2
    else
        echo "false (v != r)" 1>&2
    fi
}

schnorr_rs_recover ()
{
    local -u m="$1" r="$2" s="$3" h

    read h < <( sha256 "${r}${m}" )
    bc_ecschnorr <<<" \
        if ( (${s} >= curve_n)   || \
             (${h} >= curve_n)){ \
             print \"invalid (r,s)\\n\"; \
             halt; \
        }; \
        r[0] = ${r};
        gety_api(${r}, r_yvals[]); \
        if ( ! is_residue(r_yvals[0], 2, curve_p) ){ \
            r[1] = r_yvals[0]; \
        } else { \
            r[1] = r_yvals[1]; \
        }; \
        if ( ! ispoint(r[0], r[1]) ){ \
            print \"invalid R\"; \
            halt; \
        }; \
        ecmul_api(${s}, curve_gx, curve_gy, curve_n, curve_p, sg[]); \
        ecadd_api(r[0], r[1], sg[0], sg[1], curve_p, rs[]); \
        ecmul_api(-invmod(${h}, curve_n), rs[0], rs[1], curve_n, curve_p, q[]); \
        compresspoint(q[0], q[1]);"
}
