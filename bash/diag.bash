#!/bin/bash

function trace ()
{
    [[ -t 0 ]] && echo -n "$(tput bold 2> /dev/null)" >&2
    echo "$*" ; "$@";
    [[ -t 0 ]] && echo -n "$(tput sgr0 2> /dev/null)" >&2
}

function diag ()
{
    echo "#$*";
} 
