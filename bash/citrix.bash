#!/usr/bin/bash

. $(dirname $(readlink -f "${BASH_SOURCE[0]}"))/hg.bash
. $(dirname $(readlink -f "${BASH_SOURCE[0]}"))/dvcs.bash

appendTo CDPATH ~/src/closed
appendTo CDPATH ~/src/carbon

function make_ssh_wrappers_citrix ()
{
    local -r cfg_file=${HOME}/.ssh/config
    if [[ -f "${cfg_file}" ]] ; then
        #_un_make_ssh_wrappers "${made_ssh_wrappers_citrix[@]}"
        made_ssh_wrappers_citrix=($(awk '/^Host /{h=$2;gsub(/\*$/,"",$2);};/Hostname .*\.xensource\.com/{print h};/Hostname .*\.citrix\.com/{print h};/Hostname .*\.local/{print h}' < ${cfg_file}))
        make_ssh_wrappers "${made_ssh_wrappers_citrix[@]}"
    fi
}

declare -a made_ssh_wrappers_citrix=()
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

function release_build ()
{
    local -i -r build_number=${1}
    local -r branch=${2}
    local -r kind=${3}
    "/usr/groups/build/${branch}/${build_number}/xe-phase-1/do-release.sh" -k ${kind}
    #~/xenbuilder-scripts.hg/do-release.sh
}

function wait_for_build_phase()
{
    local -i -r build_number=${1}
    local -r branch=${2}
    local -r phase=${3}
    local -r link=/usr/groups/build/${branch}/${phase}-latest
    while [[ $(readlink ${link}) -ne ${build_number} ]] ; do
        echo $(TZ=Europe/London date) : ${link} = $(readlink ${link}) not ${build_number}
        sleep 60
    done
}

function wait_for_build_xe_phase ()
{
    local -i -r build_number=${1}
    local -r branch=${2}
    local -r phase=xe-phase-${3}
    wait_for_build_phase ${build_number} ${branch} ${phase}
}

function wait_for_build_hotfix ()
{
    local -i -r build_number=${1}
    local -r branch=${2}
    local -r phase=hotfix-${3}
    wait_for_build_phase ${build_number} ${branch} ${phase}
}

function release_build_when_ready () {
    local -i -r build_number=${1}
    local -r branch=${2}
    local -r kind=${3}
    wait_for_build_xe_phase ${build_number} ${branch} 3 && release_build ${build_number} ${branch} ${kind}
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
    local path
    local dir
    local delit
    local -a delthem=()
    while [[ $# -gt 0 ]] ; do
        path="${1}" ; shift
        if [[ -e "${path}" ]] ; then
            case "${path}" in
            */?*) ;;
            */) path=${PWD}/${path%/};;
            *) path=${PWD}/${path} ;;
            esac
            dir=${path%/*}
            delit="${dir}/.delete-me-$$"
            if [[ ! -d "${delit}" ]] ; then
                mkdir "${delit}"
            fi
            if [[ -d "${delit}" ]] ; then
                trace mv "${path}" "${delit}/"
                delthem[${#delthem[@]}]="${delit}"
            fi
        fi
    done
    if [[ ${#delthem[@]} -gt 0 ]] ; then
        trace rm -fr "${delthem[@]}"
    fi
}

function __C_findArgAfterSpecificArg ()
{
    if [[ -z "${__faasa_dbg}" ]] ; then
        local -r __faasa_dbg=null
    fi
    local arg=""
    local -r sought_arg="${1}"
    shift
    local -i previous_was_sought_arg=0
    echo "Looking for '${sought_arg}' in ${@}" > /dev/${__faasa_dbg}
    for arg in "${@}" ; do
        echo "Inspecting ${arg}" > /dev/${__faasa_dbg}
        if [[ ${previous_was_sought_arg} -eq 1 ]] ; then
            RESULT="${arg}"
            echo "Found ${RESULT} after '${sought_arg}' in ${@}" > /dev/${__faasa_dbg}
            return 0
        elif [[ "${arg}" = "${sought_arg}" ]] ; then
            echo "Found ${sought_arg}" > /dev/${__faasa_dbg}
            previous_was_sought_arg=1
        fi
    done
    return 1
}

function __C_cfu ()
{
    if [[ -z "${__dbg}" ]] ; then
        local -r __dbg=null
    fi
    local -r command="${1}"
    local -r current_word="${2}"
    local -r previous_word="${3}"
    # something following a -s
    if [[ "${previous_word}" = "-s" ]] ; then
        COMPREPLY=($(__))
    fi
}

function cfu_list ()
{
    local -r r=$1 ;
    local -r f=$2 ;
    python -uc "from cfu import CFU ; print '\n'.join((el.${f} for el in CFU().read_${r}()))" ;
}

function _xb_rw_sql ()
{
    psql -d xenbuilder -h xenbuilder -U build
}

function xb_rw_sql ()
{
    _xb_rw_sql "${@}" | cat
}

function _xb_ro_sql ()
{
    psql -d xenbuilder -h xenbuilder -U readbuild "${@}"
}

function xb_ro_sql ()
{
    _xb_ro_sql "${@}" | cat
}

function cfu_sql ()
{
    xb_ro_sql -P format=unaligned -P tuples_only -c "${@}"
}

function cfu_add_hotfix ()
{
    local -r hfx_cols="after_apply_guidance, name_description, name_label, patch_url, releasenotes, timestamp, url, uuid, version"
    if [[ $# -ne 9 ]] ; then
        echo "Usage: cfu_add_hotfix ${hfx_cols}" >&2
        return
    fi
    cfu_sql "INSERT INTO hotfixes (${hfx_cols}) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9);"
}

function cfu_list_hfxs ()
{
    cfu_sql "SELECT * FROM hotfixes;"
}

function cfu_list_hfx_uuids ()
{
    cfu_sql "SELECT uuid FROM hotfixes;" | sort
}

function cfu_list_serverversions ()
{
    cfu_sql "SELECT * FROM serverversions;" | sort -t \| -k 5
}

function cfu_list_serverversion_values ()
{
    cfu_sql "SELECT value FROM serverversions;" | sort
}

function ___C ()
{
    local RESULT=""
    COMPREPLY=()
    __C_findArgAfterSpecificArg -P "${COMP_WORDS[@]}"
    if [[ "${RESULT}" ]] ; then
        local -r product="${RESULT}"
        RESULT=""
        __C_findArgAfterSpecificArg -b "${COMP_WORDS[@]}"
        if [[ "${RESULT}" ]] ; then
            local -r branch="${RESULT}"
        else
            local -r branch=HEAD
        fi
        echo "Looking for matches of ${current_word} for branch ${branch} of product ${product}" >> /dev/${__dbg}
        COMPREPLY=($(t5MatchVariety "${current_word}" "${product}" "${branch}"))
    # something following a -P
    elif [[ "${previous_word}" = "-P" ]] ; then
        local -a RESULT
        t5QpbValidProductArray
        COMPREPLY=()
        local product
        local -r word=${COMP_WORDS[${COMP_CWORD}]}
        for product in "${RESULT[@]}" ; do
            case "${product}" in
            "${word}"*) COMPREPLY=(${COMPREPLY[@]} ${product}) ;;
            esac
        done
    # Last word in line?
#   elif [[ ${COMP_POINT} -eq ${#COMP_LINE} ]] ; then
#       local -a RESULT
#       t5QpbValidProductArray
#       COMPREPLY=()
#       local product
#       local -r word=${COMP_WORDS[${COMP_CWORD}]}
#       for product in "${RESULT[@]}" ; do
#           case "${product}" in
#           "${word}"*) COMPREPLY=(${COMPREPLY[@]} ${product}) ;;
#           esac
#       done
    else
        COMPREPLY=()
    fi
}

function __citrix ()
{
    . citrix.bash
}
