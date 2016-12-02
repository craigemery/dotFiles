#!/bin/bash

function cd ()
{
    if [[ $# -gt 0 ]] ; then
        pushd "${@}" > /dev/null;
    else
        pushd "${HOME}" > /dev/null;
    fi
}

function back ()
{
    popd > /dev/null;
}

alias 'b=back'

function cdl ()
{
    dirs -p;
}

function cdc ()
{
    cd;
    dirs -c;
}
