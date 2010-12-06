#!/bin/bash

function include ()
{
    [ -f "${1}" ] && . "${1}"
}

function IsReadableFile ()
{
    local -a ret=()
    for arg in "${@}" ; do
        [ -r "${arg}" -a -f "${arg}" ] && ret=("${arg}" "${ret[@]}")
    done
    listArray "${ret[@]}"
}

function IsReadable ()
{
    local -a ret=()
    for arg in "${@}" ; do
        [ -r "${arg}" ] && ret=("${arg}" "${ret[@]}")
    done
    listArray "${ret[@]}"
}

function NotReadable ()
{
    local -a ret=()
    for arg in "${@}" ; do
        [ ! -r "${arg}" ] && ret=("${arg}" "${ret[@]}")
    done
    listArray "${ret[@]}"
}

function IsWritable ()
{
    local -a ret=()
    for arg in "${@}" ; do
        [ -w "${arg}" ] && ret=("${arg}" "${ret[@]}")
    done
    listArray "${ret[@]}"
}

function NotWritable ()
{
    local -a ret=()
    for arg in "${@}" ; do
        [ ! -w "${arg}" ] && ret=("${arg}" "${ret[@]}")
    done
    listArray "${ret[@]}"
}

function IsExecutable ()
{
    local -a ret=()
    for arg in "${@}" ; do
        [ -x "${arg}" ] && ret=("${arg}" "${ret[@]}")
    done
    listArray "${ret[@]}"
}

function NotExecutable ()
{
    local -a ret=()
    for arg in "${@}" ; do
        [ ! -x "${arg}" ] && ret=("${arg}" "${ret[@]}")
    done
    listArray "${ret[@]}"
}

function IsDirectory ()
{
    local -a ret=()
    for arg in "${@}" ; do
        [ -d "${arg}" ] && ret=("${arg}" "${ret[@]}")
    done
    listArray "${ret[@]}"
}

function NotDirectory ()
{
    local -a ret=()
    for arg in "${@}" ; do
        [ ! -d "${arg}" ] && ret=("${arg}" "${ret[@]}")
    done
    listArray "${ret[@]}"
}

function IsLink ()
{
    local -a ret=()
    for arg in "${@}" ; do
        [ -L "${arg}" ] && ret=("${arg}" "${ret[@]}")
    done
    listArray "${ret[@]}"
}

function NotLink ()
{
    local -a ret=()
    for arg in "${@}" ; do
        [ ! -L "${arg}" ] && ret=("${arg}" "${ret[@]}")
    done
    listArray "${ret[@]}"
}

