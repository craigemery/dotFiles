#!/bin/bash

[[ -z "${T5_SRC_HOME}" ]] && export T5_SRC_HOME=$(cygpath -wa ~/.t5_src_home)
export VIMINIT="so ~/.viminit.unix"
export GNUDE_1_2=c:\\gnude1.2
export BREW_SDK_2_1_0=c:\\Program\ Files\\BREW\ SDK\ v2.1.0
export ADS_1_2=c:\\Apps\\ADS12
export XERCES_2_3_0=c:\\xerces-c-src_2_3_0
export PMAKE_2=/cygdrive/c/devel/consulting/cm-tools/src/pythonmake2
export CVS_CL_TOOL=c:\\util\\bin\\cvs.exe

. convertBrewVars.bash

function t5RcValue ()
{
    local -r n1="${1}"
    local -r rc="${HOME}/.t5rc"
    if [ -r "${rc}" ] ; then
        sed -ne "s@^${n1}=@@p" < "${rc}"
    fi
}

function t5RcOrDefault ()
{
    local -r n2="${1}"
    local -r default="${2}"
    local -r value=$(t5RcValue "${n2}")

    if [ -n "${value}" ] ; then
        echo "${value}"
    else
        echo "${default}"
    fi
}

function t5MakeTitle ()
{
    case "${1}" in
    -m*)
        local -r message="${1#-m} "
        shift
        ;;
    *)
        local -r message=""
        ;;
    esac
    local cmd=${1}
    shift
    if [ "${*}" ] ; then
        local -r target="${@}"
    else
        local -r target='"all"'
    fi

    case "${cmd}" in
    qpgraph|qpbuild|pmake|pbuild)
        titles both "${message}${cmd} ${target} (cwd = $(npwd))" >&2
    ;;

    *)
        local -r buildarch="T5BUILDARCH="$(t5DeduceBuildArch "${@}")
        titles both "${message}${cmd} ${target} (${buildarch} && cwd = $(npwd))" >&2
    ;;
    esac
}

function t5Deduce ()
{
    local -r n3="${1}"
    shift
    local -r current="${1}"
    shift
    local -r dd="${1}"
    shift
    local val=""
    for arg in "${@}" ; do
        case "${arg}" in
        ${n3}=*) val="${arg#${n3}=}" ;;
        esac
    done

    if [ -z "${val}" ] ; then
        if [ -z "${current}" ] ; then
            ${dd}
        else
            echo "${current}"
        fi
    else
        echo "${val}"
    fi
}

function t5DefaultBuildChain ()
{
    t5RcOrDefault T5BUILDCHAIN ADS
}

function t5DeduceBuildChain ()
{
    t5Deduce T5BUILDCHAIN "${T5BUILDCHAIN}" t5DefaultBuildChain "${@}"
}

function t5WhatBuildChain ()
{
    local desc="${1}"
    [ -z "${desc}" ] && desc="currently "
    echo "T5BUILDCHAIN ${desc}equals '${T5BUILDCHAIN}'"
}

function t5ChBuildChain ()
{
    local -r l_list="--list"
    local -r s_current="-c"
    local -r l_current="--current"
    local -r usage="usage: t5ChBuildChain [${s_list}|${l_list}] [${s_current}|${l_current}] [<buildchain>]"

    while [ ${#} -gt 0 ] ; do
        case "${1}" in
            ${s_current}|${l_current})
            t5WhatBuildChain
            return
        ;;
        ${s_list}|${l_list})
            echo -e "GCC\nADS\nEVC"
            return
        ;;
        -?|--help)
            echo -e "${usage}"
            return
        ;;
        --) break ;;
        -*)
            echo "Invalid argument '${1}'"
            echo -e "${usage}"
            return
        ;;
        *) break ;;
        esac

        shift
    done

    t5RemoveDirsFromEnv
    if [ ${#} -lt 1 ] ; then
        export T5BUILDCHAIN="$(t5DefaultBuildChain)"
        t5WhatBuildChain "now "
        t5AppendDirsToEnv
    else
        case ${1} in
        ""|GCC|ADS|EVC)
            export T5BUILDCHAIN="${1}"
            t5WhatBuildChain "now "
            t5AppendDirsToEnv
        ;;
        *)
            echo "Invalid buildchain ${1}" >&2
        ;;
        esac
    fi
}

[ -z "${NO_COMPLETE}" ] && complete -W "GCC ADS EVC" t5ChBuildChain

function t5DefaultBuildArch ()
{
    t5RcOrDefault T5BUILDARCH THUMB
}

function t5DeduceBuildArch ()
{
    t5Deduce T5BUILDARCH "${T5BUILDARCH}" t5DefaultBuildArch "${@}"
}

function m ()
{
    local -r start=$(secondsSinceEpoch)
    t5MakeTitle make "${@}"
    export RETFILE=/tmp/dm.${$}
    trap "rm -f ${RETFILE}" EXIT INT
    (
        date +%D\ %H:%M.%S
        echo "T5BUILDARCH="$(t5DeduceBuildArch "${@}")
        echo "T5BUILDCHAIN="$(t5DeduceBuildChain "${@}")
        make ${*} 2>&1
        declare -r -i ret=${?}
        echo ${ret} > ${RETFILE}
        date +%D\ %H:%M.%S
        echo "make returned ${ret} (and took $(elapsed ${start}))"
    ) |
    if [ "${mf}" ] ; then
        tee ${mf}
    else
        cat
    fi | fmo
    return $(cat ${RETFILE})
}

function t5DMfile ()
{
# I want there to be one dm output file **per target**
    #echo ".${USER}.qpbuild.out"
    echo "errors.err"
}

function t5ThisDMfile ()
{
  t5DMfile
}

function t5RemoveDirsFromEnv ()
{
    removeFromPath "${BASH_T5_SRC_HOME}/tools/bin"
}

function t5AppendDirsToEnv ()
{
    appendToPath "${BASH_T5_SRC_HOME}/tools/bin"
}

function t5WhatBuildArch ()
{
    local desc="${1}"
    [ -z "${desc}" ] && desc="currently "
    echo "T5BUILDARCH ${desc}equals '${T5BUILDARCH}'"
}

function t5BuildChainSanity ()
{
    case "${T5BUILDARCH}" in
    THUMB|ARM) [ "${T5BUILDCHAIN}" = "GCC" ] && t5ChBuildChain ADS ;;
    x86)
        case "${T5BUILDCHAIN}" in
        ADS|SDT) t5ChBuildChain GCC ;;
        esac
    ;;
    esac
}

function t5ChBuildArch ()
{
    local s_list="-l"
    local l_list="--list"
    local s_current="-c"
    local l_current="--current"
    local usage="usage: t5ChBuildArch [${s_list}|${l_list}] [${s_current}|${l_current}] [<buildarch>]"

    while [ ${#} -gt 0 ] ; do
        case "${1}" in
            ${s_current}|${l_current})
            t5WhatBuildArch
            return
        ;;
            ${s_list}|${l_list})
            echo -e "x86\nARM\nTHUMB"
            return
        ;;
        -?|--help)
            echo -e "${usage}"
            return
        ;;
        --) break ;;
        -*)
            echo "Invalid argument '${1}'"
            echo -e "${usage}"
            return
        ;;
        *) break ;;
        esac

        shift
    done

    t5RemoveDirsFromEnv
    if [ ${#} -lt 1 ] ; then
        export T5BUILDARCH="$(t5DefaultBuildArch)"
        t5WhatBuildArch "now "
        t5AppendDirsToEnv
        t5BuildChainSanity
    else
        case ${1} in
        ""|x86|ARM|THUMB)
            export T5BUILDARCH="${1}"
            t5WhatBuildArch "now "
            t5AppendDirsToEnv
            t5BuildChainSanity
        ;;
        *)
            echo "Invalid buildarch ${1}" >&2
        ;;
        esac
    fi
}

[ -z "${NO_COMPLETE}" ] && complete -W "x86 ARM THUMB" t5ChBuildArch

function t5Values ()
{
    t5WhatBuildArch
    t5WhatBuildChain
}

function trigenixDefaults ()
{
    [ -z "${T5BUILDARCH}" ] && export T5BUILDARCH=$(t5DefaultBuildArch)
    [ -z "${T5BUILDCHAIN}" ] && export T5BUILDCHAIN=$(t5DefaultBuildChain)
}

function SB ()
{
    local T5=""
    t5GetT5
    case "${1}" in
    "") local h="${BASH_T5_SRC_HOME}" ;;
    "dom") local h="${T5}/${1}" ;;
    *.x)
        local -r d="${T5}/${1}/dev"
        if [[ -d "${d}" ]] ; then
            local h="${d}"
            shift
        fi ;;
    *)
        local -r d="${T5}/${1}/rel"
        if [[ -d "${d}" ]] ; then
            local h="${d}"
            shift
        fi ;;
    esac
    if [ -n "${h}" ] ; then
        cd "${h}"
    fi

#PROMPT_COMMAND='echo -n "$(titles both ${USER}@${HOSTNAME%%.*}:$(tty | sed -e s/\\/dev\\/pts\\///):T5BUILDARCH=$(t5DeduceBuildArch):$(npwd))"'
    if [ ${#} -gt 0 ] ; then
        if [ -z "${T5XTERMTITLE}" ] ; then
            export T5XTERMTITLE='T5=${BASH_T5_SRC_HOME/${HOME}/~}:$(t5DeduceBuildArch)'
            xtermTitle "${XTERM_TITLE}:${T5XTERMTITLE}"
        fi
    fi
}

function HEAD
{
    SB "${@}"
}

alias H=HEAD

function T531
{
    SB 5.3.2 "${@}"
}

function T600
{
    SB 6.0.3 "${@}"
}

function T200
{
    SB 2.0.3 "${@}"
}

#function cht5 ()
#{
    #export BASH_T5_SRC_HOME=$(_Pu "${T5_SRC_HOME}")
    #if [ -n "${T5_SRC_HOME}" ] ; then
        #t5RemoveDirsFromEnv
    #fi
    #export T5_SRC_HOME="${1}"
    #export BASH_T5_SRC_HOME=$(_Pu "${T5_SRC_HOME}")
    #trigenixDefaults
    #t5AppendDirsToEnv
#}

function cht5 ()
{
    if [[ -z "${1}" ]] ; then
        export BASH_T5_SRC_HOME=${PWD}
        export T5_SRC_HOME=$(_Pwa "${BASH_T5_SRC_HOME}")
    elif [[ -d "${1}" ]] ; then
        export T5_SRC_HOME=$(_Pwa "${1}")
        export BASH_T5_SRC_HOME=$(_Pu "${T5_SRC_HOME}")
    fi
}

function defaultT5 ()
{
    t5RcOrDefault T5_SRC_HOME C:\\devel\\HEAD
}

if [ -z "${T5_SRC_HOME}" ] ; then
    cht5 $(defaultT5)
else
    cht5 "${T5_SRC_HOME}"
fi

. ads.profile

function t5GetT5 ()
{
    case "${BASH_T5_SRC_HOME}" in
    */HEAD) T5="${BASH_T5_SRC_HOME%/*}" ;;
    */rel) T5="${BASH_T5_SRC_HOME%/*/*}" ;;
    */dev) T5="${BASH_T5_SRC_HOME%/*/*}" ;;
    *) T5="${BASH_T5_SRC_HOME}" ;;
    esac
}

function t5FindVariety ()
{
    if [[ -z "${__cheyenne_dbg}" ]] ; then
        local -r __cheyenne_dbg=null
    fi
    local -r pattern="${1}"
    local -r product="${2}"
    if [[ ${#} -gt 2 ]] ; then
        local -r branch="${3}"
    else
        local -r branch="HEAD"
    fi
    local T5=""
    t5GetT5
    local -r prod_dir="${T5}/${branch}/${product}"
    local -r dev_dir="${T5}/${branch}/dev/${product}"
    local -r rel_dir="${T5}/${branch}/rel/${product}"
    echo "finding varieties in ${prod_dir} ${dev_dir} ${rel_dir}}" > /dev/${__cheyenne_dbg}
    local -r -a files=($(ls "${prod_dir}"/*-{product,component}.xml "${dev_dir}"/*-{product,component}.xml "${rel_dir}"/*-{product,component}.xml 2>&-))
    local -r -i filecount=${#files[@]}
    if [[ ${filecount} -eq 1 ]] ; then
       echo "found a product file ${files[0]}" > /dev/${__cheyenne_dbg}
       sed -n -e 's@^[[:space:]]*<VARIETY[[:space:]]*name[[:space:]]*=[[:space:]]*"\('"${pattern}"'\)">[[:space:]]*$@\1@p' < "${files[0]}" -e 's@^[[:space:]]*<VARIETY[[:space:]]*name[[:space:]]*=[[:space:]]*"\('"${pattern}"'\)"[[:space:]]*doc[[:space:]]*=[[:space:]]*"[^"]*"[[:space:]]*>[[:space:]]*$@\1@p' < "${files[0]}" | tee /dev/${__cheyenne_dbg}
    fi
}

function t5MatchVariety ()
{
    local -r spec="${1}"
    shift
    t5FindVariety "${spec}"'[^"]*' "${@}"
}

function t5MatchVarietyArgs ()
{
    local var
    for var in $(t5MatchVariety "${@}") ; do
        echo -e -V ${var}
    done
}

function doProtest ()
{
   python -u protestserver.py -x BrewList "${@}"
}

function doPtBatch ()
{
   doProtest auto "${@}"
}

function doPtScript ()
{
   doProtest --env=BrewIP --script="${@}"
}

function stashLogs ()
{
    # CAUTION!: Using %.% in a source file may lead to corrupted source files when
    # they're subject to SCCS keyword expansion!
    local -r stash_dir="${BASH_T5_SRC_HOME}/protestruns/$(date '+%Y%m%d%H%M%S')"
    mkdir "${stash_dir}"
    local -r trace_file=/cygdrive/c/BTIL_UtilTrace.txt
    if [[ -f ${trace_file} ]] ; then
        mv ${trace_file} "${stash_dir}/BTIL"
    fi
    local -r qpbuild_file=".${USER}.qpbuild.out"
    if [[ -f "${qpbuild_file}" ]] ; then
        mv "${qpbuild_file}" "${stash_dir}/PROTEST"
    fi
    local -r client_log_file="${HOME}/Desktop/run.log"
    if [[ -f "${client_log_file}" ]] ; then
        mv "${client_log_file}" "${stash_dir}/CLIENT"
    fi
    echo "log files stashed in ${stash_dir}"
}

function stashAndViewLogFiles () 
{ 
    local stash_dir=$(stashLogs)
    local yn
    read -t 10 -p "view stashed log files in ${stash_dir}? " yn
    if [[ ${?} -eq 1 ]] ; then
        echo ""
    fi
    if [[ -n "${yn}" ]] ; then
        v -O protestruns\\${stash_dir##*/}\\*
    fi
}

function t5NewTags ()
{
    local d=${BASH_T5_SRC_HOME}
    local td="${d}/.t"
    [[ -d "${td}" ]] && rm -fr "${td}"
    local verbose=""
    while true ; do
        case "${1}" in
        -v|--verbose) verbose="-v" ; shift ;;
        *)  if [[ -d "${1}" ]] ; then
                local -r d=$(realpath "${1}")
            else
                break
            fi ;;
        esac
    done
    local -r -a have_own=("trigbuilder" "parcelforce" "trigcompilation" "playerframework" "trigenixcpputils" "playertest" "protestserver")
    local -r -a have_own_include_build=("playerframework_iface")
    local -r -a all_exclude=("build" "SHIP-*" "mvrm.*")
    local -r -a just_SHIP_exclude=("SHIP-*" "mvrm.*")
    local -r -a exclude=("doxygen" "parcelforce" "mshop*")
    local dir
    local -r lf="--linkfile=${td}/list"
    for dir in ${have_own[@]} ; do
        __retag ${verbose} ${lf} "${d}/${dir}" ${all_exclude[@]}
    done
    for dir in ${have_own_include_build[@]} ; do
        __retag ${verbose} ${lf} "${d}/${dir}" ${just_SHIP_exclude[@]}
    done
    __retag ${verbose} ${lf} "${d}" ${have_own[@]} ${have_own_include_build[@]} ${all_exclude[@]} ${exclude[@]}
}

. tags.bash

# vim:sw=4:ts=4
