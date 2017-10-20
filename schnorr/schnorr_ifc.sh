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
    local -u m="$1" d="$2" k="$4" q h recoverable="${3:-0}"

    if [[ -z "$k" ]]; then
        read k < <( rfc6979_secp256k1_sha256_k "$d" "$m" )
    fi
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

schnorr_rs_sign_recoverable ()
{
    schnorr_rs_sign "$1" "$2" "1" "$4"
}

schnorr_rs_verify ()
{
    local -u m="$1" q="$2" r="$3" s="$4" h

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

schnorr_swap_sign ()
{
    local -u m="$1" d="$2" t="$3" c r r_t k q h

    read k < <( rfc6979_secp256k1_sha256_k "$d" "$m" )
    read k q c r r_t < <( bc_ecschnorr <<<" \
        ecmul_api(${k}, curve_gx, curve_gy, curve_n, curve_p, r[]); \
        ecmul_api(${t}, curve_gx, curve_gy, curve_n, curve_p, c[]); \
        if ( ! is_residue( r[1], 2, curve_p )){ \
            print mod(-${k}, curve_n), \" \"; \
            r[1] = mod(-r[1], curve_p); \
            tweak = mod(-${k}+${t}, curve_n); \
        } else { \
            print ${k}, \" \"; \
            tweak = mod(${k}+${t}, curve_n); \
        }; \
        ecmul_api(tweak, curve_gx, curve_gy, curve_n, curve_p, r_t[]); \
        ecmul_api(${d}, curve_gx, curve_gy, curve_n, curve_p, q[]); \
        print \"0\", compresspoint_api(q[0], q[1]), \" \"; \
        print \"0\", compresspoint_api(c[0], c[1]), \" \"; \
        print \"0\", compresspoint_api(r[0], r[1]), \" \"; \
        print \"0\", compresspoint_api(r_t[0], r_t[1]), \" \";")
    read h < <( sha256 "${q}${r_t}${m}" )
    echo "h : ${h}" 1>&2
    printf '%s ' "${c}" "${r}"
    bc_ecschnorr <<<"\
        mod(ec_schnorr_sign(${h}, ${d}, ${k}+${t}) - ${t}, curve_n); \
        print \"s : \", ec_schnorr_sign(${h}, ${d}, ${k}+${t}), \"\n\";"
}

schnorr_swap_verify ()
{
    local -u m="$1" q="$2" c="$3" r="$4" s="$5" r_c h

    read r_t < <( bc_ecschnorr <<<"ecadd(${c}, ${r});" )
    read h < <( sha256 "${q}${r_t}${m}" )
    echo "h : ${h}" 1>&2
    v="$(bc_ecschnorr <<<" \
        if ( (${s} >= curve_n) || \
             ((${h} > 0) && (${h} >= curve_n))){ \
             print \"invalid (r,s,h)\\n\"; \
             halt; \
        }; \
        uncompresspoint_api(${q}, q[]); \
        valid = ec_schnorr_verify_api(q[0], q[1], curve_gx, curve_gy, ${h}, ${s}, curve_n, curve_p, v[]); \
        compresspoint(v[0], v[1]);")"
    echo "r : ${r}" 1>&2
    echo "v : ${v}" 1>&2
    if [[ "${v}" == "${r}" ]]; then
        echo "true" 1>&2
    else
        echo "false (v != r)" 1>&2
    fi
}

schnorr_swap_deny ()
{
    local -u m="$1" q="$2" r1="$4" s1="$5" s2="$6" r2="$7" t c r_t h
}
