#!/usr/bin/env bash

function __upper_all ()
{
    local -r varname="${1}"
    local word="${!varname}"
    [[ "${word}" ]] || return 0
    word=${word//a/A}
    word=${word//b/B}
    word=${word//c/C}
    word=${word//d/D}
    word=${word//e/E}
    word=${word//f/F}
    word=${word//g/G}
    word=${word//h/H}
    word=${word//i/I}
    word=${word//j/J}
    word=${word//k/K}
    word=${word//l/L}
    word=${word//m/M}
    word=${word//n/N}
    word=${word//o/O}
    word=${word//p/P}
    word=${word//q/Q}
    word=${word//r/R}
    word=${word//s/S}
    word=${word//t/T}
    word=${word//u/U}
    word=${word//v/V}
    word=${word//w/W}
    word=${word//x/X}
    word=${word//y/Y}
    word=${word//z/Z}
    eval "${varname}=${word}"
}

function __capitalise ()
{
    local varname=${1}
    local word=${!varname}
    shift
    [[ "${word}" ]] || return 0
    local first=${word:0:1}
    local rest=${word:1}
    __upper_all first
    eval "${varname}=${first}${rest}"
}

