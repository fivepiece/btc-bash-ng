#!/bin/bash

test_ecdsa_res ()
{
    # random key
    privkey=5A90F5357E326FC0A657BA4E620DDAFA4DC5508C39FC204BF952B1F667E62C16
    point_x=FB859A0B232B6F2CB1BD302E134F338A2378D67EEABB010B43A93177EF9605C3
    point_y=BCAF85BD92C1107BB2B27D5826A75099B7B43810D56FE46E964EE3F6BAD6B54E
    pubkey_c=02FB859A0B232B6F2CB1BD302E134F338A2378D67EEABB010B43A93177EF9605C3
    pubkey_u=04FB859A0B232B6F2CB1BD302E134F338A2378D67EEABB010B43A93177EF9605C3BCAF85BD92C1107BB2B27D5826A75099B7B43810D56FE46E964EE3F6BAD6B54E
    # bitcoin signed message format, "test message"
    test_msg=18426974636F696E205369676E6564204D6573736167653A0A0C74657374206D657373616765
    test_z=E4CD07AA6F940179E7CFF9EA7FA6C6C73AE15E523CEB51C7145589641A78403E
    test_z_hash=1226179DDF6383FBCF5102C9492538B7206C739AE79EB064408C2ABD67D39BED
    test_sig=3045022100E13708D5A664231302098BD99A363E66CA07752F6741191FBC47449CABE758B202201B0AD260DDD5205D4DDDB6DBA980C1D14621F0BA58D043785871822FBD4130B9
    test_sig_r=E13708D5A664231302098BD99A363E66CA07752F6741191FBC47449CABE758B2
    test_sig_s=1B0AD260DDD5205D4DDDB6DBA980C1D14621F0BA58D043785871822FBD4130B9

    # bitcoin signed message format, "wrap case"
    wrap_msg=18426974636F696E205369676E6564204D6573736167653A0A09777261702063617365
    wrap_z=2DF2A5BEE61D12C95A36A1F06D7BCAF488F7E3A3D65A634878F7A7D0CDCE7D78
    wrap_z_hash=91C4A9180B083F4AD073AD6CDFFDE562CCA995AB05CD07C73EA11A2EE93DC3B5
    wrap_sig_r=4
    wrap_sig_s=4
    wrap_sig=3006020104020104
    pubkeys_c=( \
        03C8C4EF223F205353341CD26A1751235224A76816D11D4C99C85E5E18EF04A125 \
        02C242044819C628E1DD9D4ACACF0A06EB493CE18A1F0C678173512C5C82096AB9 \
        02302600BECC7AC78E2AE9D175F930796288A0A1CDCA02C71604C253B3EF14B30A \
        03D1B0D67A892F0EA31B59491E4A7BD25191A2F413C5211D2EF6FA3CBBB5339214 )
    pubkeys_u=( \
        04C8C4EF223F205353341CD26A1751235224A76816D11D4C99C85E5E18EF04A1259C59CFA6D5B2E606DD6B93790003144B31A99B1FCD764675E2DA84E17692DCFB \
        04C242044819C628E1DD9D4ACACF0A06EB493CE18A1F0C678173512C5C82096AB9966340E278AC67244658827C25E5D93952BC35412B4E9252B661C198F66DB1A6 \
        04302600BECC7AC78E2AE9D175F930796288A0A1CDCA02C71604C253B3EF14B30A4B85479D08D530D348EEEC322F028779E5F04368CEDE44A8E3C20EB86925E954 \
        04D1B0D67A892F0EA31B59491E4A7BD25191A2F413C5211D2EF6FA3CBBB53392148717B73673801C6AAE84F057BC5CDE72FE838E6EA431A3EA0A2BD62405B99E4B )
}

test_ecdsa_compresspubkey ()
{
    [[ "${pubkey_c}" == "$(compresspubkey ${pubkey_u})" ]] || (return 1)
    for ((i=0; i<${#pubkeys_u[@]}; i++)); do
        [[ "${pubkeys_c[$i]}" == "$(compresspubkey ${pubkeys_u[$i]})" ]] || (return 1)
    done
}

test_ecdsa_uncompresspubkey ()
{
    [[ "${pubkey_u}" == "$(uncompresspubkey ${pubkey_c})" ]] || (return 1)
    for ((i=0; i<${#pubkeys_u[@]}; i++)); do
        [[ "${pubkeys_u[$i]}" == $(uncompresspubkey "${pubkeys_c[$i]}") ]] || (return 1)
    done
}

test_sig2der ()
{
    [[ "${test_sig}" == "$( sig2der "${test_sig_r}" "${test_sig_s}")" ]] && \
    [[ "${wrap_sig}" == "$( sig2der "${wrap_sig_r}" "${wrap_sig_s}")" ]]
}

test_der2sig ()
{
    [[ "${test_sig_r} ${test_sig_s}" == "$( der2sig "${test_sig}" )" ]] && \
    [[ "${wrap_sig_r} ${wrap_sig_s}" == "$( der2sig "${wrap_sig}" )" ]]
}

test_ecdsa_sign ()
{
    local -u sig="$(sign "${privkey}" "${test_z}")" z_hash="$( sha256 "${test_z}" )"
    [[ "${sig}" == "${test_sig}" ]] && \
    [[ "${z_hash}" == "${test_z_hash}" ]] && \
    (( "$( verify "${z_hash}" "${pubkey_c}" "${sig}")" == 1 )) && \
    (( "$( verify "${z_hash}" "${pubkey_u}" "${sig}")" == 1 ))
}

test_ecdsa_verify ()
{
    local -u z1_hash="$( sha256 "${test_z}" )" z2_hash="$( sha256 "${wrap_z}" )"
    (( $(verify "${z1_hash}" "${pubkey_c}" "${test_sig}") == 1 )) && \
    (( $(verify "${z1_hash}" "${pubkey_u}" "${test_sig}") == 1 )) && \
    (( $(verify "${z1_hash}" "${pubkey_c}" "${test_sig_r}" "${test_sig_s}") == 1 )) && \
    (( $(verify "${z1_hash}" "${pubkey_u}" "${test_sig_r}" "${test_sig_s}") == 1 )) || (return 1)
    for ((i=0; i<${#pubkeys_c[@]}; i++)); do
        (( $(verify "${z2_hash}" "${pubkeys_c[$i]}" "${wrap_sig}") == 1 )) || (return 1)
    done
}

test_ecdsa_recover ()
{
    local -au rec1 rec2
    readarray -t rec1 < <( recover "${test_z_hash}" "${test_sig}" )
    [[ "${rec1[1]}" == "${pubkey_c}" ]] || (return 1)
    readarray -t rec2 < <( recover "${wrap_z_hash}" "${wrap_sig_r}" "${wrap_sig_s}" )
    for ((i=0; i<${#pubkeys_c[@]}; i++)); do
        [[ "${rec2[$i]}" == "${pubkeys_c[$i]}" ]] || (return 1)
    done
}

test_ecdsa ()
{
    test_ecdsa_res

    test_ecdsa_compresspubkey && \
    test_ecdsa_uncompresspubkey && \
    test_sig2der && \
    test_der2sig && \
    test_ecdsa_sign && \
    test_ecdsa_verify && \
    test_ecdsa_recover
}
test_ecdsa || return 1
