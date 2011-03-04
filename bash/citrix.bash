#!/usr/bin/bash

make_ssh_wrappers $(awk '/^Host /{h=$2};/Hostname .*\.xensource\.com/{print h};/Hostname .*\.local/{print h}' < ~/.ssh/config)

function __site_vms ()
{
    #assume local -a RESULT=()
    local -r site="${1}"
    RESULT=($(awk 'BEGIN{site=""};/^#Site: '${site}'/{site=$2};/^Host/{if (site!=""){print $2};site=""}' < ~/.ssh/config))
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
    RESULT=($(awk '/^#Site:/{print $2}' < ~/.ssh/config | sort -u))
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
    for site in $(awk '/^#Site:/{print $2}' < ~/.ssh/config | sort -u) ; do
        eval "function Site_tabs_${site} { __ssh_site_tabs ${site}; }"
    done
}

__make_site_tabs

function __citrix ()
{
    . citrix.bash
}
