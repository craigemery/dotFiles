#!/bin/bash

function clip ()
{
    local -rA clip_numbers=([cow]=0 [chick]=1 [goat]=2 [smb_warning]=3 [pizza_time]=4 [interuder_detected]=5 [darkside2]=6 [mario_die]=7 [yay_16]=8)
    local -r num="${clip_numbers[$1]}"
    if [[ "${num}" ]] ; then
        curl 'http://10.20.30.17/axis-cgi/playclip.cgi?clip='"${num}"
    fi
}

complete -W "cow chick goat smb_warning pizza_time interuder_detected darkside2 mario_die yay_16" clip

function __aa ()
{
    . aa.bash
}
