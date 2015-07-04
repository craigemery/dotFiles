#!/bin/bash

function prependTo ()
{
    local -r var_name="${1}" ; shift
    local remove=""
    if [[ "${1}" = -m ]] ; then
        shift
        remove=y
    fi
    while [[ $# -gt 0 ]] ; do
        local -a list="${!var_name}"
        if [[ -z "${list}" ]] ; then
            # echo "Prepending '${1}' to empty \$${var_name}"
            eval "export ${var_name}=${1}"
            continue
        fi
        if [[ "${remove}" ]] ; then
            removeFrom "${var_name}" "${1}"
        fi
        case "${list}" in
        ${1}|*:${1}|${1}:*|*:${1}:*) ;;
        *)
            eval "export ${var_name}=${1}:\${${var_name}}"
            # echo "Prepending '${1}' to \$${var_name} (was ${list}, now ${!var_name})"
        ;;
        esac
        shift
    done
}

function appendTo ()
{
    local -r var_name="${1}" ; shift
    local remove=""
    if [[ "${1}" = -m ]] ; then
        shift
        remove=y
    fi
    while [[ $# -gt 0 ]] ; do
        local -a list="${!var_name}"
        if [[ -z "${list}" ]] ; then
            # echo "Appending '${1}' to empty \$${var_name}"
            eval "export ${var_name}=${1}"
            continue
        fi
        if [[ "${remove}" ]] ; then
            removeFrom "${var_name}" "${1}"
        fi
        case "${list}" in
        ${1}|*:${1}|${1}:*|*:${1}:*) ;;
        *)
            eval "export ${var_name}=\${${var_name}}:${1}"
            # echo "Appending '${1}' to \$${var_name} (was ${list}, now ${!var_name})"
        ;;
        esac
        shift
    done
}

function removeFrom ()
{
    local -r var_name="${1}" ; shift
    local -a list="${!var_name}"
    local -r del_me="${1}" ; shift
    local cs_list="${!var_name}"
    local new_cs_list
    local el

    local -i inf_limit=99

    while [[ "${cs_list}" && ${inf_limit} -gt 0 ]] ; do
        inf_limit=$((inf_limit - 1))

        el=${cs_list##*:}
        cs_list=${cs_list%:*}

        if [[ "${el}" == "${cs_list}" ]] ; then
            cs_list=""
        fi

        if [[ "${del_me}" != "${el}" ]] ; then
            if [[ "${new_cs_list}" ]] ; then
                new_cs_list="${el}:${new_cs_list}"
            else
                new_cs_list="${el}"
            fi
        # else
            # echo "Removing '${el}' from \$${var_name}"
        fi
    done

    eval "export ${var_name}=\"${new_cs_list}\""
}

function prependToPath ()
{
    prependTo PATH "${@}"
}

function appendToPath ()
{
    appendTo PATH "${@}"
}

function removeFromPath ()
{
    removeFrom PATH "${@}"
}

function prependToLibpath ()
{
    prependTo LD_LIBRARY_PATH "${@}"
}

function appendToLibpath ()
{
    appendTo LD_LIBRARY_PATH "${@}"
}

function removeFromLibpath ()
{
    removeFrom LD_LIBRARY_PATH "${@}"
}

function prependToManpath ()
{
    prependTo MANPATH "${@}"
}

function appendToManpath ()
{
    appendTo MANPATH "${@}"
}

function removeFromManpath ()
{
    removeFrom MANPATH "${@}"
}

# function prependToPath ()
# {
    # if [[ "${1}" = -m ]] ; then
        # shift
        # removeFromPath "${1}"
    # fi
    # case ":${PATH}:" in
    # *:${1}|${1}:*|*:${1}:*) ;;
    # *)
        # # echo "Prepending '${1}' to PATH"
        # export PATH=${1}:${PATH}
    # ;;
    # esac
# }

# function appendToPath ()
# {
    # if [[ "${1}" = -m ]] ; then
        # shift
        # removeFromPath "${1}"
    # fi
    # case ":${PATH}:" in
    # *:${1}|${1}:*|*:${1}:*) ;;
    # *)
        # # echo "Appending '${1}' to PATH"
        # export PATH=${PATH}:${1}
    # ;;
    # esac
# }

# function removeFromPath ()
# {
    # local -r del_me="${1}"
    # shift
    # local cs_list="${PATH}"
    # local new_cs_list
    # local el

    # local -i inf_limit=99

    # while [[ "${cs_list}" && ${inf_limit} -gt 0 ]] ; do
        # inf_limit=$((inf_limit - 1))

        # el=${cs_list##*:}
        # cs_list=${cs_list%:*}

        # if [[ "${el}" == "${cs_list}" ]] ; then
            # cs_list=""
        # fi

        # if [[ "${del_me}" != "${el}" ]] ; then
            # if [[ "${new_cs_list}" ]] ; then
                # new_cs_list="${el}:${new_cs_list}"
            # else
                # new_cs_list="${el}"
            # fi
        # fi
    # done

    # export PATH="${new_cs_list}"
# }

# function prependToLibpath ()
# {
    # case ":${LD_LIBRARY_PATH}:" in
    # *:${1}|${1}:*|*:${1}:*) ;;
    # *) export LD_LIBRARY_PATH=${1}:${LD_LIBRARY_PATH} ;;
    # esac
# }

# function appendToLibpath ()
# {
    # case ":${LD_LIBRARY_PATH}:" in
    # *:${1}|${1}:*|*:${1}:*) ;;
    # *) export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${1} ;;
    # esac
# }

# function removeFromLibpath ()
# {
    # local -r del_me="${1}"
    # shift
    # local cs_list="${LD_LIBRARY_PATH}"
    # local new_cs_list
    # local el

    # local -i inf_limit=99

    # while [[ "${cs_list}" && ${inf_limit} -gt 0 ]] ; do
        # inf_limit=$((inf_limit - 1))

        # el=${cs_list##*:}
        # cs_list=${cs_list%:*}

        # if [[ "${el}" == "${cs_list}" ]] ; then
            # cs_list=""
        # fi

        # if [[ "${del_me}" != "${el}" ]] ; then
            # if [[ "${new_cs_list}" ]] ; then
                # new_cs_list="${el}:${new_cs_list}"
            # else
                # new_cs_list="${el}"
            # fi
        # fi
    # done

    # export LD_LIBRARY_PATH="${new_cs_list}"
# }

# function prependToManpath ()
# {
    # case ":${MANPATH}:" in
    # *:${1}|${1}:*|*:${1}:*) ;;
    # *) export MANPATH=${1}:${MANPATH} ;;
    # esac
# }

# function appendToManpath ()
# {
    # case ":${MANPATH}:" in
    # *:${1}|${1}:*|*:${1}:*) ;;
    # *) export MANPATH=${MANPATH}:${1} ;;
    # esac
# }

# function removeFromManpath ()
# {
    # local arg="${1}"
    # local dir
    # local newPath

    # for dir in $(echo ${MANPATH} | tr : ' ') ; do
        # if [[ "${arg}" != "${dir}" ]] ; then
            # [[ -z "${newPath}" ]] || newPath="${newPath}:"
            # newPath="${newPath}${dir}"
        # fi
    # done

    # export MANPATH="${newPath}"
# }

function appendToList ()
{
    local dir="${1}"
    shift
    local list="${@}"
    local d
    local unfound=true

    for d in $(echo "${list}" | tr : \\012) ; do
        if [[ "${d}" == "${dir}" ]] ; then
            unfound=false
            break
        fi
    done

    if ${unfound} ; then
        echo "${list}:${dir}"
    fi
}

function prependToList ()
{
    local dir="${1}"
    shift
    local list="${@}"
    local d
    local unfound=true

    for d in $(echo "${list}" | tr : \\012) ; do
        if [[ "${d}" == "${dir}" ]] ; then
            unfound=false
            break
        fi
    done

    if ${unfound} ; then
        echo "${dir}:${list}"
    fi
}

function listArray ()
{
    local -r s_sep="-S"
    local -r l_sep="--sep"
    local -r s_space="-s"
    local -r l_space="--space"
    local -r s_comma="-C"
    local -r l_comma="--comma"
    local -r s_cr="-c"
    local -r l_cr="--cr"
    local -r s_pre="-p"
    local -r l_pre="--pre"
    local -r usage="usage: listArray [${s_space}|${l_space}] [${s_cr}|${l_cr}] [${s_comma}|${l_comma}] (<array>))"
    local -r comma=", "
    local -r cr="\\n"
    local -r space=" "
    local sep="${cr}"

    while [[ ${#} -gt 0 ]] ; do
    case "${1}" in
    --) shift ; break ;;

    ${l_sep}=*)
        sep="${1#${l_sep}=}"
    ;;
    ${s_sep}|${l_sep})
        shift
        sep="${1}"
    ;;
    ${s_comma}|${l_comma})
        sep="${comma}"
    ;;
    ${s_cr}|${l_cr})
        sep="${cr}"
    ;;
    ${l_pre}=*)
        local pre="${1#${l_pre}=}"
    ;;
    ${s_pre})
        if [[ ${#} -gt 1 ]] ; then
            shift
            local pre="${1}"
        else
            echo "Invalid argument '${1}'"
            echo -e "${usage}"
            return 0
        fi
    ;;
    ${s_space}|${l_space})
        sep="${space}"
    ;;
    -?|--help)
        echo -e "${usage}"
        return 0
    ;;
    --) break ;;
    -*)
        echo "Invalid argument '${1}'"
        echo -e "${usage}"
        return 0
    ;;
    *) break ;;
    esac

    shift
    done

    local -a array=("${@}")
    local -i loop=${#array[@]}
    local -i idx=0
    while [[ ${loop} -ne 0 ]] ; do
        loop=$((loop - 1))
        [[ ${idx} -gt 0 ]] && echo -ne "${sep}"
        echo -ne "${pre}${array[${idx}]}"
        idx=$((idx + 1))
    done

    [[ ${idx} -gt 0 ]] && echo ''
}

function prependDistToEnv ()
{
    local dist="${1}"

    if [[ -d "${dist}/bin" ]] ; then
        removeFromPath "${dist}/bin"
        prependToPath "${dist}/bin"
    fi

    if [[ -d "${dist}/shell" ]] ; then
        removeFromPath "${dist}/shell"
        prependToPath "${dist}/shell"
    fi

    if [[ -d "${dist}/perl" ]] ; then
        removeFromPath "${dist}/perl"
        prependToPath "${dist}/perl"
    fi

    if [[ -d "${dist}/man" ]] ; then
        removeFromManpath "${dist}/man"
        prependToManpath "${dist}/man"
    fi

    if [[ -d "${dist}/lib" ]] ; then
        removeFromLibpath "${dist}/lib"
        prependToLibpath "${dist}/lib"
    fi
}

function libs ()
{
    echo ${LD_LIBRARY_PATH} | tr : \\012
}


function mans ()
{
    echo ${MANPATH} | tr : \\012
}


function paths ()
{
    echo ${PATH} | tr : \\012
}

function __P ()
{
   cygpath "${@}"
}

function _Pw ()
{
   __P -w "${@}"
}

function _Pwa ()
{
   _Pw -a "${@}"
}

function _Pwas ()
{
   #_Pw -as "${@}"
   local -r no_s=$(_Pwa "${@}")
   case "${no_s}" in
   *\ *) _Pwa -s "${@}" ;;
   *) echo "${no_s}" ;;
   esac
}

function _Pws ()
{
   _Pw -s "${@}"
}

function _Pm ()
{
   __P -m "${@}"
}

function _Pma ()
{
   _Pm -a "${@}"
}

function _Pu ()
{
   __P -u "${@}"
}

function _Pua ()
{
   _Pu -a "${@}"
}

function _PwaAllArgs ()
{
    # assume local -a RESULT=()
    local a
    for a in "${@}"; do
        case "${a}" in
        *\\...)
            if [[ -e "${a%\\...}" ]]; then
                a="$(_Pwa "${a%\\...}")"\\...
            fi ;;
        //*) ;;
        *\ *)
            if [[ -e "${a}" ]]; then
                a="$(_Pwas "${a}")"
            fi ;;
        *)
            if [[ -e "${a}" ]]; then
                a="$(_Pwa "${a}")"
            fi ;;
        esac
        RESULT[${#RESULT[@]}]=${a}
    done
}

function _PwaPWD ()
{
    _Pwa "${PWD}"
}

function _PwasPWD ()
{
   _Pwas "${PWD}"
}

if [[ $((${BASH_VERSINFO[0]%[a-z]} + 0)) -eq 2 ]] ; then
    if [[ $((${BASH_VERSINFO[1]%[a-z]} + 0)) -lt 5 ]] ; then
        export NO_COMPLETE=yes
    fi
fi

function arrayHas ()
{
    [[ "${1}" ]] || return 1
    local -r sought="${1}"
    shift
    while [[ ${#} -gt 0 ]] ; do
        if [[ "${sought}" == "${1}" ]] ; then
            return 0
        fi
        shift
    done
    return 1
}

function arrayMax ()
{
    #assume local RESULT=""
    local max=""
    local val
    for val in "${@}" ; do
        [[ "${val}" > "${max}" ]] && max="${val}"
    done
    RESULT="${max}"
}

function arrayMin ()
{
    #assume local RESULT=""
    local min=""
    local val
    for val in "${@}" ; do
        [[ "${val}" < "${min}" ]] && min="${val}"
    done
    RESULT="${min}"
}

me="${BASH_ARGV[0]}"
medir="${me%/*}"
appendToPath ${medir}
unset medir
unset me

function __lists ()
{
   . lists.bash
}

