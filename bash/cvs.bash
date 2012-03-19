#!/bin/bash

function cvsExcludedFiles ()
{
    t4RcValue CVS_EXCLUSION
}

function cvsQuery ()
{
    local proceed="yes"
    local -r s_space="-s"
    local -r l_space="--space"
    local -r s_cr="-c"
    local -r l_cr="--cr"
    local -r usage="usage: cvsQuery [${s_space}|${l_space}] [${s_cr}|${l_cr}] <re> [files...])"

    while [ ${#} -gt 0 ] ; do
    case "${1}" in
    ${s_cr}|${l_cr})
        local sep="${1}"
    ;;
    ${s_space}|${l_space})
        local sep="${1}"
    ;;
    -?|--help)
        echo -e "${usage}"
        proceed=""
    ;;
    --) break ;;
    -*)
        echo "Invalid argument '${1}'"
        echo -e "${usage}"
        proceed=""
    ;;
    *) break ;;
    esac

    shift
    done

    if [ "${proceed}" ] ; then
        local -r re="${1}"
        shift
        local -a files=()
        local -r -a results=( $(cvs -qn up "${@}" | awk "/^${re} /{print \$NF}") )
        local -r -a excluded=($(cvsExcludedFiles))
        local -i result_loop=${#results[@]}
        while [ ${result_loop} -ne 0 ] ; do
            result_loop=$((--result_loop))
            local result="${results[${result_loop}]}"
            local -i found=0

            local -i exclusion_loop=${#excluded[@]}
            while [ ${exclusion_loop} -ne 0 ] ; do
                exclusion_loop=$((--exclusion_loop))
                local exclusion="${excluded[${exclusion_loop}]}"
                if [ "${result}" == "${exclusion}" ] ; then
                    found=1
                    break
                fi
            done

            if [ 0 -eq ${found} ] ; then
                files=(${files[@]} ${result})
            fi
        done

        listArray ${sep} "${files[@]}"
    fi
}

function cvsModified ()
{
    cvsQuery 'M' "${@}"
}

function cvsAdded ()
{
    cvsQuery 'A' "${@}"
}

function cvsRemoved ()
{
    cvsQuery 'R' "${@}"
}

function cvsNeedsCheckin ()
{
    cvsQuery '[AMR]' "${@}"
}

function getComment ()
{
    local -r mFlag="-m"
    while [ ${#} -gt 0 ] ; do
        local arg="${1}"
        case "${arg}" in
        "${mFlag}")
            if [ ${#} -gt 1 ] ; then
                local c="${2}"
                shift
            fi
        ;;
        esac

        shift
    done

    if [ -n "${c}" ] ; then
        comment=(${mFlag} "${c}")
    fi
}

function cvsCheckin ()
{
    local -a comment=()
    getComment "${@}"
    cvsNotUnderCvs
    local -a args=()
    [ ${#} -gt 0 ] && args=($(IsReadableFile "${@}"))
    cvs ci "${comment[@]}" "${args[@]}"
}

function cvsChanges ()
{
    local proceed="yes"
    local s_prompt="-p"
    local l_prompt="--prompt"
    local s_trace="-t"
    local l_trace="--trace"
    local usage="usage: cvsChanges [${s_prompt}|${l_prompt}] [${s_trace}|${l_trace}]"

    while [ ${#} -gt 0 ] ; do
    case "${1}" in
    ${s_trace}|${l_trace})
        local prompt="${s_trace}"
    ;;
    ${s_prompt}|${l_prompt})
        local prompt="${s_prompt}"
    ;;
    -?|--help)
        echo -e "${usage}"
        proceed=""
    ;;
    --) break ;;
    -*)
        echo "Invalid argument '${1}'"
        echo -e "${usage}"
        proceed=""
    ;;
    *) break ;;
    esac

    shift
    done

    if [ "${proceed}" ] ; then
        cvsModified "${@}" | xargs ${prompt} -n1 cvsdiff
    fi
}

function cvsUnderCvs ()
{
    cvs stat "${@}" 2>&1 |
    sed -n -e '/Status: Unknown/d' -e 's@File: \(.*\)[[:space:]]\+Status:.*@\1@p'
}

function cvsNotUnderCvs ()
{
    local -a args=()
    [ ${#} -gt 0 ] && args=($(IsReadableFile "${@}"))
    local -ra files=($(cvsQuery --space '?' "${args[@]}"))
    listArray --cr '--pre=? ' "${files[@]}"
}

function cvsFindSticky ()
{
    find "${@}" -type d -name CVS                                                                       |
        sed -e 's@^\./@@' -e 's@/CVS$@@'                                                                |
        tr \\012 \\000                                                                                  |
        xargs --null -iXX cvs -q status -l XX                                                           |
        GREP_OPTIONS="" egrep -B 4 -e '^[[:space:]]*Sticky Tag:[[:space:]]+[^[:space:]]+[[:space:]]\('
}

. file.bash

