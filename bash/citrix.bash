#!/usr/bin/bash

function make_ssh_wrappers_citrix ()
{
    local -r cfg_file=${HOME}/.ssh/config
    if [[ -f "${cfg_file}" ]] ; then
        make_ssh_wrappers $(awk '/^Host /{h=$2};/Hostname .*\.xensource\.com/{print h};/Hostname .*\.local/{print h}' < ${cfg_file})
    fi
}

make_ssh_wrappers_citrix

function __site_vms ()
{
    #assume local -a RESULT=()
    local -r site="${1}"
    local -r cfg_file=${HOME}/.ssh/config
    if [[ -f "${cfg_file}" ]] ; then
        RESULT=($(awk 'BEGIN{site=""};/^#Site: '${site}'/{site=$2};/^Host/{if (site!=""){print $2};site=""}' < ${cfg_file}))
    else
        RESULT=()
    fi
}

function site_vms ()
{
    local -r site="${1}"
    local -a RESULT=()
    __site_vms ${site}
    listArray "${RESULT[@]}"
}

function __ssh_site_tabs ()
{
    local -r site="${1}"
    local -a RESULT=()
    __site_vms ${site}
    local host
    for host in ${RESULT[@]} ; do
        sleep 2
        trace Ssh ${host}
    done
}

function __all_sites ()
{
    #assume local -a RESULT=()
    local -r cfg_file=${HOME}/.ssh/config
    if [[ -f "${cfg_file}" ]] ; then
        RESULT=($(awk '/^#Site:/{print $2}' < ${cfg_file} | sort -u))
    else
        RESULT=()
    fi
}

function all_sites ()
{
    local -a RESULT=()
    __all_sites
    listArray "${RESULT[@]}"
}

function __make_site_tabs ()
{
    local -a RESULT=()
    __all_sites
    local site
    local -r cfg_file=${HOME}/.ssh/config
    if [[ -f "${cfg_file}" ]] ; then
        for site in $(awk '/^#Site:/{print $2}' < ${cfg_file} | sort -u) ; do
            eval "function Site_tabs_${site} { __ssh_site_tabs ${site}; }"
        done
    fi
}

__make_site_tabs

function __citrix ()
{
    . citrix.bash
}
