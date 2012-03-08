#!/bin/bash

###############################
# commands for invoking qpbuild
###############################

function t5QpbDefaultProduct ()
{
    t5RcOrDefault DEFAULT_PRODUCT PLAYERTEST
}

function t5QpbValidProductArray ()
{
    if [[ -z "${T5_SRC_HOME}" ]] ; then
        echo 'You *must* have $T5_SRC_HOME set' >&2
        return 1
    fi
    local T5
    t5GetT5
    local -r product_file="${T5}/HEAD/compspec/components-mapping.xml"
    if [[ ! -f "${product_file}" ]] ; then
        echo 'You *must* have a *valid* $T5_SRC_HOME set' >&2
        return 1
    fi

    RESULT=( $(sed -n -e 's@^[[:space:]]*<PRODUCT[[:space:]]\+name[[:space:]]*=[[:space:]]*"\([^"]\+\)">[[:space:]]*$@\1@p' < "${product_file}") )
}

function t5QpbIsValidProduct ()
{
    local -a RESULT
    local -r test="${1}"
    t5QpbValidProductArray || return ${?}
    local product
    for product in "${RESULT[@]}" ; do
        [[ "${test}" == "${product}" ]] && return 0
    done
    return 1
}

function t5QpbIsInvalidProduct ()
{
    t5QpbIsValidProduct "${1}" || return 0
    return 1
}

function t5QpbFindArgAfterSpecificArg ()
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

# [[ -z "${NO_COMPLETE}" ]] && complete -W "$(t5ChPmStyle --list-sep=' ' --list)" t5ChPmStyle

# timing and colouring
function qpb ()
{
    local -r start=$(secondsSinceEpoch)
    local -a args=("${@}")
    if FindAndDelFlags --DISABLE_TESTS -D ; then
        local -xr PT_DISABLE_TESTS=1
    fi
    case "${args[0]}" in
    co|checkout) ;;
    *)
        if [[ -z "${T5_SRC_HOME}" ]] ; then
            echo 'You *must* have $T5_SRC_HOME set' >&2
            return 1
        fi

        local -i idx=${#args[@]}
        let idx=--idx
        local RESULT=""
      # If there is no -P <something>
        #if ! t5QpbFindArgAfterSpecificArg -P "${args[@]}" ; then
          # and the last argument is NOT a valid product
            #if t5QpbIsInvalidProduct ${args[${idx}]} ; then
              # then add the default product to the command
                #local -r product="$(t5QpbDefaultProduct)"
                #echo "Using default product '${product}'" >&2
                #args=("${args[@]}" "${product}")
            #fi
        #fi
    ;;
    esac
    export RETFILE=/tmp/qpb.${$}
    trap "rm -f ${RETFILE}" EXIT INT
    (
        date +%D\ %H:%M.%S
        t5MakeTitle qpbuild "${args[@]}"
        local T5=""
        t5GetT5
        cd "${T5}"
        local py23=/cygdrive/c/Python23
        export PYTHON_2_3=$(_Pw ${py23})
        export CYGWIN_1_5_12=$(_Pw /)
        #export AB_SERVER_IFACE=${T5_SRC_HOME}\\abiface\\SHIP-dbg
        appendToPath "${OMNI_4_0_5}\\bin\\x86_win32"
        ${py23}/python.exe -u ${QP_TOOLS_1}\\lib\\pythonbuild\\pbuild.py "${args[@]}" 2>&1
        declare -r -i ret=${?}
        echo ${ret} > ${RETFILE}
        date +%D\ %H:%M.%S
        echo "qpbuild returned ${ret} (and took $(elapsed ${start}))"
    ) |
    if [[ "${mf}" ]] ; then
        tee "${mf}"
    else
        cat
    fi | fmo
    declare -r -i ret=$(cat ${RETFILE})
    if [[ ${ret} -eq 0 ]] ; then
        t5MakeTitle -mPASSED qpbuild "${args[@]}"
    else
        t5MakeTitle -mFAILED qpbuild "${args[@]}"
    fi
    unset RETFILE
    return ${ret}
}

function getPBV()
{
    local RESULT=""
    local -a args=("${@}")
    if t5QpbFindArgAfterSpecificArg -V "${args[@]}" ; then
        variant="${RESULT}"
    else
        variant="ALL"
    fi
    if t5QpbFindArgAfterSpecificArg -b "${args[@]}" ; then
        branch=$(echo "${RESULT}" | tr '[a-z]' '[A-Z]')
    else
        branch=HEAD
    fi
    if t5QpbFindArgAfterSpecificArg -P "${args[@]}" ; then
        product="${RESULT}"
    else
        local -i idx=${#args[@]}
        let idx=--idx
        if t5QpbIsInvalidProduct ${args[${idx}]} ; then
            product="${args[${idx}]}"
        else
            product="$(t5QpbDefaultProduct)"
            echo "Using default product '${product}'" >&2
        fi
    fi
}

function getMF ()
{
    local product=""
    local branch=""
    local variant=""
    getPBV "${@}"
    mf="${PWD}/.${product}-${branch}-${variant}.${1}.out"
}

# timing, colouring and recording
function dqpb ()
{
    local mf=""
    getMF "${@}"
    # tput cup $(tput lines)
    qpb "${@}"
    return ${?}
}

# last recorded
function dqpbo ()
{
    local mf=""
    local -a args=("${@}")
    getMF "${args[@]}"
    if [[ -f "${mf}" ]] ; then
        if FindFlags -t --tail ; then
            less +F "${mf}"
        else
            if fileBiggerThanScreen "${mf}" ; then
                fmo < "${mf}" 2>&1 | less +G
            else
                fmo < "${mf}" 2>&1
            fi
        fi
    fi
}

# Functions for building all varieties that match a string / re
function qpbmatch ()
{
    local spec="${1}"
    local product="${2}"
    if [[ -z "${product}" ]] ; then
        product="$(t5QpbDefaultProduct)"
        echo "Using default product '${product}'" >&2
    fi
    local variety_args=$(t5MatchVarietyArgs "${spec}" ${product})
    if [[ "${variety_args}" ]] ; then
        echo qpb build --verbose ${variety_args} ${product}
        qpb build --verbose ${variety_args} ${product}
    else
        echo "No varieties match '${spec}'" >&2
    fi
}
function dqpbmatch ()
{
    local spec="${1}"
    local product="${2}"
    if [[ -z "${product}" ]] ; then
        product="$(t5QpbDefaultProduct)"
        echo "Using default product '${product}'" >&2
    fi
    local variety_args=$(t5MatchVarietyArgs "${spec}" ${product})
    if [[ "${variety_args}" ]] ; then
        echo dqpb build --verbose ${variety_args} ${product}
        dqpb build --verbose ${variety_args} ${product}
    else
        echo "No varieties match '${spec}'" >&2
    fi
}

function t5CompleteQpbuild ()
{
    if [[ -z "${__qpbuild_dbg}" ]] ; then
        local -r __qpbuild_dbg=null
    fi
    local -r command="${1}"
    local -r current_word="${2}"
    local -r previous_word="${3}"
    # something following a -V
    if [[ "${previous_word}" = "-V" ]] ; then
        local RESULT=""
        COMPREPLY=()
        t5QpbFindArgAfterSpecificArg -P "${COMP_WORDS[@]}"
        if [[ "${RESULT}" ]] ; then
            local -r product="${RESULT}"
            RESULT=""
            t5QpbFindArgAfterSpecificArg -b "${COMP_WORDS[@]}"
            if [[ "${RESULT}" ]] ; then
                local -r branch="${RESULT}"
            else
                local -r branch=HEAD
            fi
            echo "Looking for matches of ${current_word} for branch ${branch} of product ${product}" >> /dev/${__qpbuild_dbg}
            COMPREPLY=($(t5MatchVariety "${current_word}" "${product}" "${branch}"))
        else
            echo "no product found in ${COMP_LINE}" >> /dev/${__qpbuild_dbg}
        fi
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

# Given a list of flags, iterate through ${args[@]} and if any of the flags
# in the list are found, elide them from ${args[@]} and return 0 (bash-speak for
# true)
# if none of the flags are found, return 1 (bash-speak for false)
function FindAndDelFlags ()
{
    if [[ -z "${__fdf_dbg}" ]] ; then
        local -r __fdf_dbg=null
    fi
    [[ "${__fdf_dbg}" = "null" ]] || echo "-> args = ${args[@]}" >> /dev/${__fdf_dbg}
    [[ "${__fdf_dbg}" = "null" ]] || echo "-> "'${@}'" = ${@}" >> /dev/${__fdf_dbg}
    local -i ret=1 # failed
    local arg=""
    local flag=""
    local -a new_args=()
    local found=""
    for arg in "${args[@]}" ; do
        [[ "${__fdf_dbg}" = "null" ]] || echo "Inspecting arg '${arg}'" >> /dev/${__fdf_dbg}
        found=""
        for flag in "${@}" ; do
#           [[ "${__fdf_dbg}" = "null" ]] || echo "Comparing against flag '${flag}'" >> /dev/${__fdf_dbg}
            case "${arg}" in
            ${flag})
                [[ "${__fdf_dbg}" = "null" ]] || echo "Found flag '${flag}'" >> /dev/${__fdf_dbg}
                ret=0 # found one
                found=yes
                match="${arg}"
                break ;;
            esac
        done
        if [[ -z "${found}" ]] ; then
#           [[ "${__fdf_dbg}" = "null" ]] || echo "Found flag '${flag}'" >> /dev/${__fdf_dbg}
#       else
#           [[ "${__fdf_dbg}" = "null" ]] || echo "Did not find any flags in '${@}'" >> /dev/${__fdf_dbg}
            if [[ ${#new_args[@]} -eq 0 ]] ; then
                new_args=("${arg}")
#               [[ "${__fdf_dbg}" = "null" ]] || echo '${new_args[@]} = '"'${new_args[@]}'" >> /dev/${__fdf_dbg}
            else
                new_args=("${new_args[@]}" "${arg}")
#               [[ "${__fdf_dbg}" = "null" ]] || echo '${new_args[@]} now = '"'${new_args[@]}'" >> /dev/${__fdf_dbg}
            fi
        fi
    done
    args=("${new_args[@]}")
    [[ "${__fdf_dbg}" = "null" ]] || echo "<- args = ${args[@]}" >> /dev/${__fdf_dbg}
    return ${ret}
}

function FindFlags ()
{
    if [[ -z "${__ff_dbg}" ]] ; then
        local -r __ff_dbg=null
    fi
    [[ "${__ff_dbg}" = "null" ]] || echo "-> args = ${args[@]}" >> /dev/${__ff_dbg}
    [[ "${__ff_dbg}" = "null" ]] || echo "-> "'${@}'" = ${@}" >> /dev/${__ff_dbg}
    local arg=""
    local flag=""
    for arg in "${args[@]}" ; do
        [[ "${__ff_dbg}" = "null" ]] || echo "Inspecting arg '${arg}'" >> /dev/${__ff_dbg}
        for flag in "${@}" ; do
#           [[ "${__ff_dbg}" = "null" ]] || echo "Comparing against flag '${flag}'" >> /dev/${__ff_dbg}
            if [[ "${arg}" = "${flag}" ]] ; then
                [[ "${__ff_dbg}" = "null" ]] || echo "Found flag '${flag}'" >> /dev/${__ff_dbg}
                return 0
                break
            fi
        done
    done
    return 1
}

function qpg ()
{
    export QPG_RETFILE=/tmp/qpg.${$}
    (
        if [[ -z "${__qpg_dbg}" ]] ; then
            local -r __qpg_dbg=null
        fi
        local -r __fdf_dbg=${__qpg_dbg}
        local -r __ff_dbg=${__qpg_dbg}
        local -r oldwd="${PWD}"
        local -r winoldwd=$(_PwasPWD)
        local -a args=("${@}")
        t5MakeTitle qpgraph "${args[@]}"
        local T5
        t5GetT5
        cd "${T5}"
        local py23=/cygdrive/c/Python23
        export PYTHON_2_3=$(_Pw ${py23})
        #export AB_SERVER_IFACE="$(_Pwa ${BASH_T5_SRC_HOME}\\abiface\\SHIP-dbg)"
        if FindAndDelFlags --keep-dot-file -K ; then
            local -r keepDotFile=yes
        else
            local -r keepDotFile=""
        fi
#       echo '${args[@]} = '"'${args[@]}'" >> /dev/${__qpg_dbg}
        local RESULT=""
        if t5QpbFindArgAfterSpecificArg -V "${args[@]}" ; then
            local -r variant="${RESULT}"
        else
            local -r variant="ALL"
        fi
        if t5QpbFindArgAfterSpecificArg -b "${args[@]}" ; then
            local -r branch=$(echo "${RESULT}" | tr '[a-z]' '[A-Z]')
        else
            local -r branch=HEAD
        fi
        if t5QpbFindArgAfterSpecificArg -P "${args[@]}" ; then
            local -r product="${RESULT}"
        else
            local -i idx=${#args[@]}
            let idx=--idx
            if t5QpbIsInvalidProduct ${args[${idx}]} ; then
                local -r product="${}"
            else
                local -r product="$(t5QpbDefaultProduct)"
                echo "Using default product '${product}'" >&2
                set -- "${args[@]}" "${product}"
            fi
        fi
        if FindFlags -a --ascii ; then
            local -r ascii="yes"
        else
            local -r ascii=""
        fi
        local -r base=${product}-${branch}-${variant}
        local -r txtFile=${base}.txt
        local -r dotFile=${base}.dot
        local -r pngFile=${base}.png
        if [[ "${ascii}" ]] ; then
            local -r output=${oldwd}/${txtFile}
        else
            local -r output=${oldwd}/${dotFile}
        fi
        ${py23}/python.exe -u ${QP_TOOLS_1%}\\lib\\pythonbuild\\graph.py "${args[@]}" > ${output}
        declare -i ret=${?}
        sed -i -e '/^Found AB Server Components\./d' -e '/The Product name .*as definded in .* does not match/d' -e '/the name .* as defined in/d' -e '/Using p4python connection to Perforce/d' ${output}
        if [[ ${ret} -eq 0 ]] ; then
            if [[ "${ascii}" ]] ; then
                if fileBiggerThanScreen "${output}" ; then
                    less +G1G ${output}
                else
                    cat ${output}
                fi
            else
                dot -Tpng -o${winoldwd}\\${pngFile} ${winoldwd}\\${dotFile}
                ret=${?}
                [[ -f ${oldwd}/${pngFile} ]] && chmod a+x ${oldwd}/${pngFile}
                [[ -z "${keepDotFile}" ]] && rm -f ${output}
            fi
        fi
        echo ${ret} > ${QPG_RETFILE}
    )
    declare -r -i ret=$(cat ${QPG_RETFILE})
    unset QPG_RETFILE
    return ${ret}
}

if [[ -z "${NO_COMPLETE}" ]] ; then
    complete -F t5CompleteQpbuild dqpb
    complete -F t5CompleteQpbuild qpb
    complete -F t5CompleteQpbuild qpBuild
    complete -F t5CompleteQpbuild dqpBuild
    complete -F t5CompleteQpbuild qpg
fi

function qpBuild
{
    qpb build --verbose "${@}"
}

function dqpBuild
{
    dqpb build --verbose "${@}"
}

function QP ()
{
    local -r -a args=("${@}")
    dqpb "${args[@]}" >&-
    local -i ret=${?}
    dqpbo "${args[@]}"
    return ${ret}
}

function QPB ()
{
    QP build --verbose "${@}"
    return ${?}
}

function QPO ()
{
    dqpbo "${@}"
    return ${?}
}

function QPBO ()
{
    QPO build "${@}"
    return ${?}
}

function QPCOO ()
{
    QPO co "${@}"
    return ${?}
}

function QPCO ()
{
    QP co --verbose "${@}" --resolve=am
    return ${?}
}

function QPCL ()
{
    QP clean "${@}"
    return ${?}
}

complete -F t5CompleteQpbuild QP
complete -F t5CompleteQpbuild QPO
complete -F t5CompleteQpbuild QPB
complete -F t5CompleteQpbuild QPCO
complete -F t5CompleteQpbuild QPCOO
complete -F t5CompleteQpbuild QPCL
complete -F t5CompleteQpbuild QPBO

function __qpbuild ()
{
    . qpbuild.bash
}
# vim:sw=4
