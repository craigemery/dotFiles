#!/bin/bash

function clip ()
{
    local -rA clip_numbers=([cow]=0 [pig]=1 [goat]=2 [smb_warning]=3 [pizza_time]=4 [intruder_detected]=5 [chick]=6 [mario_die]=7 [yay_16]=8 [sacrebleu]=9)
    local -r num="${clip_numbers[$1]}"
    if [[ "${num}" ]] ; then
        curl 'http://10.20.30.17/axis-cgi/playclip.cgi?clip='"${num}"
    fi
}

complete -W "cow pig goat smb_warning pizza_time intruder_detected chick mario_die yay_16 sacrebleu" clip

function __aa ()
{
    . aa.bash
}
