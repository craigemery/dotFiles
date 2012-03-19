#!/bin/bash

function t4BrewCompleteDeploy ()
{
    if [[ "${3}" == "--esn" ]] ; then
        COMPREPLY=()
        local -i idx
        local sig
        for sig in signatures/0x* ; do
            COMPREPLY[${#COMPREPLY[@]}]="${sig#signatures/}"
        done
    fi
}

[[ -z "${NO_COMPLETE}" ]] && complete -F t4BrewCompleteDeploy deploy
