#!/usr/bin/bash
. hg.bash

function make_ssh_wrappers_citrix ()
{
    local -r cfg_file=${HOME}/.ssh/config
    if [[ -f "${cfg_file}" ]] ; then
        make_ssh_wrappers $(awk '/^Host /{h=$2;gsub(/\*$/,"",$2);};/Hostname .*\.xensource\.com/{print h};/Hostname .*\.citrix\.com/{print h};/Hostname .*\.local/{print h}' < ${cfg_file})
    fi
}

make_ssh_wrappers_citrix

function __site_vms ()
{
    #assume local -a RESULT=()
    local -r site="${1}"
    local -r cfg_file=${HOME}/.ssh/config
    if [[ -f "${cfg_file}" ]] ; then
        RESULT=($(awk 'BEGIN{site=""};/^#Site: '${site}'/{site=$2};/^Host/{if (site!=""){gsub(/\*$/,"",$2);print $2};site=""}' < ${cfg_file} | sort))
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

function xbrdp ()
{
    local -r pa=xb-pa-win
    local -r cam=xb-cam-win
    local -r rdm=xb-rdm-win
    local -r ma=xb-ma-win
    local -r van=xb-van-win
    local -r blr=xb-blr-win
    while [[ ${#} -gt 0 ]] ; do
        local arg="${1}"
        shift
        local host="${arg}"
        case ${host} in
        xb-*) ;;
        *) host=xb-${host} ;;
        esac
        case ${host} in
        ${pa}*) host=${host}.eng.hq ;;
        ${cam}*) host=${host}.uk ;;
        #${rdm}*) host=${host}.eng.hq ;;
        #${ma}*) host=${host}.eng.hq ;;
        #${van}*) host=${host}.eng.hq ;;
        #${blr}*) host=${host}.eng.hq ;;
        esac
        case ${host} in
        *.xensource.com) ;;
        *) host=${host}.xensource.com ;;
        esac
        case ${host} in
        *[0-9]*) __nt -P rdp:${arg} mstsc /admin /v:${host} ; sleep 3 ;;
        esac
    done
}

function make_source ()
{
    local -ir build=${1} ; shift
    local -r branch=${1} ; shift
    curl -F "class=jobform;product=carbon;branch=${branch};site=pa;job=sources;action=xe-phase-3-build;number=${build};cmd=request;submit=Start" "http://xenbuilder.uk.xensource.com/builds?q_view=details&amp;q_product=carbon&amp;q_branch=${branch};q_number=${build}"
}

function release_build () {
    local -i -r build_number=${1}
    local -r branch=${2}
    local -r kind=${3}
    /usr/groups/build/${branch}/${build_number}/xe-phase-1/do-release.sh -k ${kind}
    #~/xenbuilder-scripts.hg/do-release.sh
}

function wait_for_build_phase()
{
    local -i -r build_number=${1}
    local -r branch=${2}
    local -i -r phase=${3}
    local -r link=/usr/groups/build/${branch}/xe-phase-${phase}-latest
    while [[ $(readlink ${link}) -ne ${build_number} ]] ; do
        echo $(TZ=Europe/London date) : ${link} = $(readlink ${link}) not ${build_number}
        sleep 60
    done
}

function release_build_when_ready () {
    local -i -r build_number=${1}
    local -r branch=${2}
    local -r kind=${3}
    wait_for_build_phase ${build_number} ${branch} 3 && release_build ${build_number} ${branch} ${kind}
}

function check_page ()
{
    local -r dest=/tmp/check_page/$$
    [[ -d ${dest} ]] || mkdir -p ${dest}
    pushd ${dest}
    wget -r -nd --delete-after "${@}" 2>&1 | awk '/^--.*--  http:\/\/.*/{url=$NF};/HTTP request sent, awaiting response/{if ($NF != "OK"){printf "%s %s %s\n", url, $(NF-1), $NF} }'
    popd
    rm -fr ${dest}
}

function check_release ()
{
    check_page "http://coltrane.eng.hq.xensource.com/release/${*}"
}

function mvrm ()
{
    local r path="${1}"
    if [[ -e "${path}" ]] ; then
        case "${path}" in
        */?*) ;;
        */) path=${PWD}/${path%/};;
        *) path=${PWD}/${path} ;;
        esac
        local -r dir=${path%/*}
        local -r delme="${dir}/.delme"
        local -r delit="${delme}/$$"
        if [[ ! -d "${delme}" ]] ; then
            mkdir "${delme}"
        fi
        if [[ -d "${delme}" ]] ; then
            trace mv "${path}" "${delit}" && trace rm -fr "${delit}"
            rmdir "${delme}" 2>&-
        fi
    fi
}

function __citrix ()
{
    . citrix.bash
}
