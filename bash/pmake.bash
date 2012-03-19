#!/bin/bash

#######################################
# environment needed for invoking pmake
#######################################

# location of pmake itself
if [ -z "${PMAKE_2}" ] ; then
    export PMAKE_2=${HOME}/dev/consulting/cm-tools/HEAD/src/pythonmake2
fi

# needed for xmltuple
appendToLibpath ${T4_HOME}/code/resbuilder/3rdparty/linux

#############################
# commands for invoking pmake
#############################

function __pm_deduce_pmake_file ()
{
    local -x pmake_file=""
    case "${1}" in
    *.pamke)
        pmake_file="${1}"
        shift
    ;;

    *)
        local file
        for file in *.pmake ; do
            if [[ "${pmake_file}" || ! -f ${file} ]] ; then
                echo "You have not specified a pmake file to execute and there is more than one in your current directory" >&2
                if [[ -f ${file} ]] ; then
                    ls -lAF *.pmake >&2
                fi
                return 1
            else
                pmake_file=${file}
            fi
        done
        echo "Using discovered pmake file ${pmake_file}" >&2
    ;;
    esac
    echo "${pmake_file}"
}

## timing and colouring
#function pm ()
#{
    #local -x pmake_file=""
    #case "${1}" in
    #*.pamke)
        #pmake_file="${1}"
        #shift
    #;;

    #*)
        #local file
        #for file in *.pmake ; do
            #if [[ "${pmake_file}" || ! -f ${file} ]] ; then
                #echo "You have not specified a pmake file to execute and there is more than one in your current directory" >&2
                #ls -lAF *.pmake >&2
                #return 1
            #else
                #pmake_file=${file}
            #fi
        #done
        #echo "Using discovered pmake file ${pmake_file}" >&2
    #;;
    #esac
    #local -r start=$(secondsSinceEpoch)
    #t4MakeTitle pmake "${@}"
    #export RETFILE=/tmp/pm.${$}
    #export MYPLATFORM="$(uname -s)"
    #trap "rm -f ${RETFILE}" EXIT INT
    #(
        #date +%D\ %H:%M.%S
        #set CRAIG $(t4DeducePmArguments "${@}")
        #shift
        #if [ "${MYPLATFORM}" = "CYGWIN_NT-5.1" ] ; then
            #export SYMBIAN_6_1=c:\\Symbian\\6.1
            #export SYMBIAN_7_0=c:\\Symbian\\7.0s
            #export T4_HOME=$(_Pw ${T4_HOME})
            #export PMAKE_2=$(_Pw ${PMAKE_2})
            #py=/cygdrive/c/Python23
            #export PYTHON_2_3=$(_Pw ${py})
            #${py}/python.exe -c "import user; execfile('${pmake_file}')" "${@}" 2>&1
        #else
            #py=$(which python2.3)
            #export PYTHON_2_3=${py%/python2.3}
            #LD_LIBRARY_PATH=../../xmltuple/SHIP-all ${py} -c "import user; execfile('${pmake_file}')" "${@}" 2>&1
        #fi
        #declare -r -i ret=${?}
        #echo ${ret} > ${RETFILE}
        #date +%D\ %H:%M.%S
        #echo "pmake returned ${ret} (and took $(elapsed ${start}))"
    #) |
    #if [ "${mf}" ] ; then
        #if [ "${MYPLATFORM}" = "CYGWIN_NT-5.0" ] ; then
            #tr -d \\015 | tee ${mf}
        #else
            #tee ${mf}
        #fi
    #else
        #cat
    #fi | fmo
    #declare -r -i ret=$(cat ${RETFILE})
    #unset RETFILE
    #unset MYPLATFORM
    #return ${ret}
#}

# timing and colouring
function pm ()
{
    local -x cdto="."
    local -x wash=""
    local -a args=()
    local arg
    for arg in "${@}" ; do
        case "${arg}" in
        -R)
            if [[ ${#args[@]} -eq 0 ]] ; then
                args=(-V -v style=rel -r)
            else
                args=("${args[@]}" -V -v style=rel -r)
            fi
        ;;
        -r)
            if [[ ${#args[@]} -eq 0 ]] ; then
                args=(-v style=rel -r)
            else
                args=("${args[@]}" -v style=rel -r)
            fi
        ;;
        -C*) cdto="${arg#-C}" ;;
        -w|--wash) wash=yes ;;
        *)
            if [[ ${#args[@]} -eq 0 ]] ; then
                args=("${arg}")
            else
                args=("${args[@]}" "${arg}")
            fi
        ;;
        esac
    done
    set -- "${args[@]}"
    local -x pmake_file=""
    case "${1}" in
    *.pamke)
        pmake_file="${1}"
        shift
    ;;

    *)
        local file
        for file in ${cdto}/*.pmake ; do
            if [[ "${pmake_file}" || ! -f ${file} ]] ; then
                echo "You have not specified a pmake file to execute and there is more than one in your current directory" >&2
                ls -lAF *.pmake >&2
                return 1
            else
                pmake_file=${file#${cdto}/}
            fi
        done
        #echo "Using discovered pmake file ${pmake_file}" >&2
    ;;
    esac
    local -r start=$(secondsSinceEpoch)
    export RETFILE=/tmp/pm.${$}
    trap "rm -f ${RETFILE}" EXIT INT
    (
        [[ "${cdto}" != "." ]] && cd "${cdto}"
        if [[ "${wash}" ]] ; then
            mvrm -fr ./build ./SHIP-*
        fi
        t5MakeTitle pmake "${@}"
        date +%D\ %H:%M.%S
        py=/cygdrive/c/Python23
        export PYTHON_2_3=$(_Pw ${py})
        ${py}/python.exe -u -c "import user; execfile('${pmake_file}')" "${@}" 2>&1
        declare -r -i ret=${?}
        echo ${ret} > ${RETFILE}
        date +%D\ %H:%M.%S
        echo "pmake returned ${ret} (and took $(elapsed ${start}))"
    ) | tee "${cdto}/errors.err" |
    if [ "${mf}" ] ; then
        case "${mf}" in
        */*) ;;
        *) mf="${cdto}/${mf}" ;;
        esac
        tr -d \\015 | tee ${mf}
    else
        cat
    fi | fmo
    declare -r -i ret=$(cat ${RETFILE})
    if [[ ${ret} -eq 0 ]] ; then
        if [[ -d "${cdto}/build" ]] ; then
            mv "${cdto}/errors.err" "${cdto}/build/buildlog.txt"
        else
            rm "${cdto}/errors.err"
        fi
    fi
    unset RETFILE
    return ${ret}
}

# timing, colouring and recording
function dpm ()
{
    local mf=".${USER}.pmake.out"
    # tput cup $(tput lines)
    pm "${@}"
    return ${?}
}

# last recorded
function dpmo ()
{
    local mf=".${USER}.pmake.out"
    if [ -f ${mf} ] ; then
        if fileBiggerThanScreen ${mf} ; then
            fmo < ${mf} 2>&1 | less
        else
            fmo < ${mf} 2>&1
        fi
    fi
}

#################################################################
# Manage environment variables that we'll use when invoking pmake
#################################################################

#########################################################################################
# take the command-line arguments and fill in the unspecified values from the environment
#########################################################################################
function t4DeducePmArguments ()
{
    local debug_level=""
    local debug_via=""
    local style=""
    local targetos=""
    local testing=""
    local target=""
    local sdk=""
    local distrib_target=""
    local sync=""
    local trackmem=""
    local trackperf=""
    local actorset=""
    local customer=""
    local ccompiler=""
    local prev_arg=""
    local arg
    for arg in "${@}" ; do
        case "${arg}" in
        *=*)
            if [ "${prev_arg}" = "-v" ] ; then
                local variant="${arg%%=*}"
                local value="${arg#*=}"
                case "${variant}" in
                debug_level) debug_level=${value} ;;
                debug_via) debug_via=${value} ;;
                style) style=${value} ;;
                targetos) targetos=${value} ;;
                testing) testing=${value} ;;
                target) target=${value} ;;
                sdk) sdk=${value} ;;
                distrib_target) distrib_target=${value} ;;
                sync) sync=${value} ;;
                trackmem) trackmem=${value} ;;
                trackperf) trackperf=${value} ;;
                actorset) actorset=${value} ;;
                customer) customer=${value} ;;
                ccompiler) ccompiler=${value} ;;
                *) echo "Unknown variant name: ${variant}" >&2 ;;
                esac
            fi
        ;;
        -r) style=rel;;
        esac
        prev_arg="${arg}"
    done

    if [ -z "${debug_level}" ]  ; then
        debug_level=$(t4DeducePmDebugLevel "${@}")
        echo -n -v debug_level=${debug_level} ''
    fi

    if [ -z "${debug_via}" ]  ; then
        debug_via=$(t4DeducePmDebugVia "${@}")
        echo -n -v debug_via=${debug_via} ''
    fi

    if [ -z "${style}" ]  ; then
        style=$(t4DeducePmStyle "${@}")
        echo -n -v style=${style} ''
    fi

    if [ -z "${targetos}" ]  ; then
        targetos=$(t4DeducePmTargetOS "${@}")
        echo -n -v targetos=${targetos} ''
    fi

    if [ "${targetos}" = symbian ] ; then
        if [ "${target}" ] ; then
            echo -n -v target=${target} ''
        fi
        if [ "${sdk}" ] ; then
            echo -n -v sdk=${sdk} ''
        fi
    fi

    if [ -z "${testing}" ]  ; then
        testing=$(t4DeducePmTesting "${@}")
        echo -n -v testing=${testing} ''
    fi

    if [ -z "${sync}" ]  ; then
        sync=$(t4DeducePmSync "${@}")
        echo -n -v sync=${sync} ''
    fi

    if [ -z "${trackmem}" ]  ; then
        trackmem=$(t4DeducePmTrackMem "${@}")
        echo -n -v trackmem=${trackmem} ''
    fi

    if [ -z "${trackperf}" ]  ; then
        trackperf=$(t4DeducePmTrackPerf "${@}")
        echo -n -v trackperf=${trackperf} ''
    fi

    if [ -z "${actorset}" ]  ; then
        actorset=$(t4DeducePmActorSet "${@}")
        echo -n -v actorset=${actorset} ''
    fi

    echo "${@}"
}

######################################################################################################
# Deduce a variant's value from the command-line, the environment or a function that gives the default
######################################################################################################

function t4DeduceVariant ()
{
    local -r n3="${1}"
    shift
    local -r current="${1}"
    shift
    local -r dd="${1}"
    shift
    local val=""
    local prev_arg=""
    local arg
    for arg in "${@}" ; do
        case "${arg}" in
        ${n3}=*) [ "${prev_arg}" = "-v" ] && val="${arg#${n3}=}" ;;
        esac
        prev_arg="${arg}"
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

########################################################################################
# The style is whether it's debug or release and "maps" to optimised vs debugger symbols
########################################################################################

function t4DefaultPmStyle ()
{
    t4RcOrDefault T4PMSTYLE dbg
}

function t4DeducePmStyle ()
{
    t4DeduceVariant style "${T4PMSTYLE}" t4DefaultPmStyle "${@}"
}

function t4WhatPmStyle ()
{
    local desc="${1}"
    [ -z "${desc}" ] && desc="currently "
    echo "T4PMSTYLE ${desc}equals '${T4PMSTYLE}'"
}

function t4ChPmStyle ()
{
    local list_sep="\n"
    local -r s_list_sep="-s"
    local -r l_list_sep="--list-sep"
    local -r s_list="-l"
    local -r l_list="--list"
    local -r s_current="-c"
    local -r l_current="--current"
    local -r usage="usage: t4ChPmStyle [${s_list_sep}|${l_list_sep} <separator>] [${l_list_sep}=<separator>] [${s_list}|${l_list}] [${s_current}|${l_current}] [<style>]"
    local -r -a list=(dbg rel)
    local -i idx=0

    while [ ${#} -gt 0 ] ; do
        case "${1}" in
        ${s_current}|${l_current})
            t4WhatPmStyle
            return
        ;;
        ${s_list_sep}|${l_list_sep})
            shift
            list_sep="${1}"
        ;;
        ${l_list_sep}=*)
            list_sep="${1#${l_list_sep}=}"
        ;;
        ${s_list}|${l_list})
            while [[ ${idx} -lt ${#list[*]} ]] ; do
                if [[ ${idx} -gt 0 ]] ; then
                    echo -n -e "${list_sep}"
                fi
                echo -n "${list[${idx}]}"
                let idx=++idx
            done
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

    if [ ${#} -lt 1 ] ; then
        export T4PMSTYLE="$(t4DefaultPmStyle)"
        t4WhatPmStyle "now "
    else
        while [[ ${idx} -lt ${#list[*]} ]] ; do
            if [[ "${1}" == "${list[${idx}]}" ]] ; then
                export T4PMSTYLE="${1}"
                t4WhatPmStyle "now "
                return
            fi
            let idx=++idx
        done
        echo "Invalid value for pmake variant 'style': ${1}" >&2
    fi
}

[ -z "${NO_COMPLETE}" ] && complete -W "$(t4ChPmStyle --list-sep=' ' --list)" t4ChPmStyle

#######################################
# targetos is the OS we're building for
#######################################

function t4HostPmTargetOS ()
{
    case "$(uname -s)" in
    Linux) echo linux;;
    CYGWIN_NT-5.0) echo wce300;;
    esac
}

function t4DefaultPmTargetOS ()
{
    t4RcOrDefault T4PMTARGETOS $(t4HostPmTargetOS)
}

function t4DeducePmTargetOS ()
{
    t4DeduceVariant targetos "${T4PMTARGETOS}" t4DefaultPmTargetOS "${@}"
}

function t4WhatPmTargetOS ()
{
    local desc="${1}"
    [ -z "${desc}" ] && desc="currently "
    echo "T4PMTARGETOS ${desc}equals '${T4PMTARGETOS}'"
}

function t4ChPmTargetOS ()
{
    local list_sep="\n"
    local -r s_list_sep="-s"
    local -r l_list_sep="--list-sep"
    local -r s_list="-l"
    local -r l_list="--list"
    local -r s_current="-c"
    local -r l_current="--current"
    local -r usage="usage: t4ChPmTargetOS [${s_list_sep}|${l_list_sep} <separator>] [${l_list_sep}=<separator>] [${s_list}|${l_list}] [${s_current}|${l_current}] [<targetos>]"
    local -r -a list=(linux wce300 symbian)
    local -i idx=0

    while [ ${#} -gt 0 ] ; do
        case "${1}" in
            ${s_current}|${l_current})
            t4WhatPmTargetOS
            return
        ;;
        ${s_list_sep}|${l_list_sep})
            shift
            list_sep="${1}"
        ;;
        ${l_list_sep}=*)
            list_sep="${1#${l_list_sep}=}"
        ;;
        ${s_list}|${l_list})
            while [[ ${idx} -lt ${#list[*]} ]] ; do
                if [[ ${idx} -gt 0 ]] ; then
                    echo -n -e "${list_sep}"
                fi
                echo -n "${list[${idx}]}"
                let idx=++idx
            done
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

    if [ ${#} -lt 1 ] ; then
        export T4PMTARGETOS="$(t4DefaultPmTargetOS)"
        t4WhatPmTargetOS "now "
    else
        while [[ ${idx} -lt ${#list[*]} ]] ; do
            if [[ "${1}" == "${list[${idx}]}" ]] ; then
                export T4PMTARGETOS="${1}"
                t4WhatPmTargetOS "now "
                return
            fi
            let idx=++idx
        done
        echo "Invalid value for pmake variant 'targetos': ${1}" >&2
    fi
}

[ -z "${NO_COMPLETE}" ] && complete -W "$(t4ChPmTargetOS --list-sep=' ' --list)" t4ChPmTargetOS

##############################################################
# debug_level is the "verbosity" of diagnostic instrumentation
##############################################################

function t4DefaultPmDebugLevel ()
{
    t4RcOrDefault T4PMDEBUGLEVEL info
}

function t4DeducePmDebugLevel ()
{
    t4DeduceVariant debug_level "${T4PMDEBUGLEVEL}" t4DefaultPmDebugLevel "${@}"
}

function t4WhatPmDebugLevel ()
{
    local desc="${1}"
    [ -z "${desc}" ] && desc="currently "
    echo "T4PMDEBUGLEVEL ${desc}equals '${T4PMDEBUGLEVEL}'"
}

function t4ChPmDebugLevel ()
{
    local list_sep="\n"
    local -r s_list_sep="-s"
    local -r l_list_sep="--list-sep"
    local -r s_list="-l"
    local -r l_list="--list"
    local -r s_current="-c"
    local -r l_current="--current"
    local -r usage="usage: t4ChPmDebugLevel [${s_list_sep}|${l_list_sep} <separator>] [${l_list_sep}=<separator>] [${s_list}|${l_list}] [${s_current}|${l_current}] [<debug_level>]"
    local -r -a list=(silent error warn info verbose annoy)
    local -i idx=0

    while [ ${#} -gt 0 ] ; do
        case "${1}" in
            ${s_current}|${l_current})
            t4WhatPmDebugLevel
            return
        ;;
        ${s_list_sep}|${l_list_sep})
            shift
            list_sep="${1}"
        ;;
        ${l_list_sep}=*)
            list_sep="${1#${l_list_sep}=}"
        ;;
        ${s_list}|${l_list})
            while [[ ${idx} -lt ${#list[*]} ]] ; do
                if [[ ${idx} -gt 0 ]] ; then
                    echo -n -e "${list_sep}"
                fi
                echo -n "${list[${idx}]}"
                let idx=++idx
            done
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

    if [ ${#} -lt 1 ] ; then
        export T4PMDEBUGLEVEL="$(t4DefaultPmDebugLevel)"
        t4WhatPmDebugLevel "now "
    else
        while [[ ${idx} -lt ${#list[*]} ]] ; do
            if [[ "${1}" == "${list[${idx}]}" ]] ; then
                export T4PMDEBUGLEVEL="${1}"
                t4WhatPmDebugLevel "now "
                return
            fi
            let idx=++idx
        done
        echo "Invalid value for pmake variant 'debug_level': ${1}" >&2
    fi
}

[ -z "${NO_COMPLETE}" ] && complete -W "$(t4ChPmDebugLevel --list-sep=' ' --list)" t4ChPmDebugLevel


##############################################################
# debug_via is the "destination" of diagnostic instrumentation
##############################################################

function t4DefaultPmDebugVia ()
{
    t4RcOrDefault T4PMDEBUGVIA output
}

function t4DeducePmDebugVia ()
{
    t4DeduceVariant debug_via "${T4PMDEBUGVIA}" t4DefaultPmDebugVia "${@}"
}

function t4WhatPmDebugVia ()
{
    local desc="${1}"
    [ -z "${desc}" ] && desc="currently "
    echo "T4PMDEBUGVIA ${desc}equals '${T4PMDEBUGVIA}'"
}

function t4ChPmDebugVia ()
{
    local list_sep="\n"
    local -r s_list_sep="-s"
    local -r l_list_sep="--list-sep"
    local -r s_list="-l"
    local -r l_list="--list"
    local -r s_current="-c"
    local -r l_current="--current"
    local -r usage="usage: t4ChPmDebugVia [${s_list_sep}|${l_list_sep} <separator>] [${l_list_sep}=<separator>] [${s_list}|${l_list}] [${s_current}|${l_current}] [<debug_via>]"
    local -r -a list=(output file socket)
    local -i idx=0

    while [ ${#} -gt 0 ] ; do
        case "${1}" in
            ${s_current}|${l_current})
            t4WhatPmDebugVia
            return
        ;;
        ${s_list_sep}|${l_list_sep})
            shift
            list_sep="${1}"
        ;;
        ${l_list_sep}=*)
            list_sep="${1#${l_list_sep}=}"
        ;;
        ${s_list}|${l_list})
            while [[ ${idx} -lt ${#list[*]} ]] ; do
                if [[ ${idx} -gt 0 ]] ; then
                    echo -n -e "${list_sep}"
                fi
                echo -n "${list[${idx}]}"
                let idx=++idx
            done
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

    if [ ${#} -lt 1 ] ; then
        export T4PMDEBUGVIA="$(t4DefaultPmDebugVia)"
        t4WhatPmDebugVia "now "
    else
        while [[ ${idx} -lt ${#list[*]} ]] ; do
            if [[ "${1}" == "${list[${idx}]}" ]] ; then
                export T4PMDEBUGVIA="${1}"
                t4WhatPmDebugVia "now "
                return
            fi
            let idx=++idx
        done
        echo "Invalid value for pmake variant 'debug_via': ${1}" >&2
    fi
}

[ -z "${NO_COMPLETE}" ] && complete -W "$(t4ChPmDebugVia --list-sep=' ' --list)" t4ChPmDebugVia

#########################################
# testing is whether protest is on or off
#########################################

function t4DefaultPmTesting ()
{
    t4RcOrDefault T4PMTESTING notest
}

function t4DeducePmTesting ()
{
    t4DeduceVariant testing "${T4PMTESTING}" t4DefaultPmTesting "${@}"
}

function t4WhatPmTesting ()
{
    local desc="${1}"
    [ -z "${desc}" ] && desc="currently "
    echo "T4PMTESTING ${desc}equals '${T4PMTESTING}'"
}

function t4ChPmTesting ()
{
    local list_sep="\n"
    local -r s_list_sep="-s"
    local -r l_list_sep="--list-sep"
    local -r s_list="-l"
    local -r l_list="--list"
    local -r s_current="-c"
    local -r l_current="--current"
    local -r usage="usage: t4ChPmTesting [${s_list_sep}|${l_list_sep} <separator>] [${l_list_sep}=<separator>] [${s_list}|${l_list}] [${s_current}|${l_current}] [<testing>]"
    local -r -a list=(ntest ptest)
    local -i idx=0

    while [ ${#} -gt 0 ] ; do
        case "${1}" in
            ${s_current}|${l_current})
            t4WhatPmTesting
            return
        ;;
        ${s_list_sep}|${l_list_sep})
            shift
            list_sep="${1}"
        ;;
        ${l_list_sep}=*)
            list_sep="${1#${l_list_sep}=}"
        ;;
        ${s_list}|${l_list})
            while [[ ${idx} -lt ${#list[*]} ]] ; do
                if [[ ${idx} -gt 0 ]] ; then
                    echo -n -e "${list_sep}"
                fi
                echo -n "${list[${idx}]}"
                let idx=++idx
            done
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

    if [ ${#} -lt 1 ] ; then
        export T4PMTESTING="$(t4DefaultPmTesting)"
        t4WhatPmTesting "now "
    else
        while [[ ${idx} -lt ${#list[*]} ]] ; do
            if [[ "${1}" == "${list[${idx}]}" ]] ; then
                export T4PMTESTING="${1}"
                t4WhatPmTesting "now "
                return
            fi
            let idx=++idx
        done
        echo "Invalid value for pmake variant 'testing': ${1}" >&2
    fi
}

[ -z "${NO_COMPLETE}" ] && complete -W "$(t4ChPmTesting --list-sep=' ' --list)" t4ChPmTesting

#####################################################
# trackmem is whether MEASURE_MEMORY_USE is on or off
#####################################################

function t4DefaultPmTrackMem ()
{
    t4RcOrDefault T4PMTRACKMEM ntm
}

function t4DeducePmTrackMem ()
{
    t4DeduceVariant trackmem "${T4PMTRACKMEM}" t4DefaultPmTrackMem "${@}"
}

function t4WhatPmTrackMem ()
{
    local desc="${1}"
    [ -z "${desc}" ] && desc="currently "
    echo "T4PMTRACKMEM ${desc}equals '${T4PMTRACKMEM}'"
}

function t4ChPmTrackMem ()
{
    local list_sep="\n"
    local -r s_list_sep="-s"
    local -r l_list_sep="--list-sep"
    local -r s_list="-l"
    local -r l_list="--list"
    local -r s_current="-c"
    local -r l_current="--current"
    local -r usage="usage: t4ChPmTrackMem [${s_list_sep}|${l_list_sep} <separator>] [${l_list_sep}=<separator>] [${s_list}|${l_list}] [${s_current}|${l_current}] [<trackmem>]"
    local -r -a list=(ntm tm)
    local -i idx=0

    while [ ${#} -gt 0 ] ; do
        case "${1}" in
            ${s_current}|${l_current})
            t4WhatPmTrackMem
            return
        ;;
        ${s_list_sep}|${l_list_sep})
            shift
            list_sep="${1}"
        ;;
        ${l_list_sep}=*)
            list_sep="${1#${l_list_sep}=}"
        ;;
        ${s_list}|${l_list})
            while [[ ${idx} -lt ${#list[*]} ]] ; do
                if [[ ${idx} -gt 0 ]] ; then
                    echo -n -e "${list_sep}"
                fi
                echo -n "${list[${idx}]}"
                let idx=++idx
            done
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

    if [ ${#} -lt 1 ] ; then
        export T4PMTRACKMEM="$(t4DefaultPmTrackMem)"
        t4WhatPmTrackMem "now "
    else
        while [[ ${idx} -lt ${#list[*]} ]] ; do
            if [[ "${1}" == "${list[${idx}]}" ]] ; then
                export T4PMTRACKMEM="${1}"
                t4WhatPmTrackMem "now "
                return
            fi
            let idx=++idx
        done
        echo "Invalid value for pmake variant 'trackmem': ${1}" >&2
    fi
}

[ -z "${NO_COMPLETE}" ] && complete -W "$(t4ChPmTrackMem --list-sep=' ' --list)" t4ChPmTrackMem


#######################################################
# trackperf is whether MEASURE_PERFORMANCE is on or off
#######################################################

function t4DefaultPmTrackPerf ()
{
    t4RcOrDefault T4PMTRACKPERF ntp
}

function t4DeducePmTrackPerf ()
{
    t4DeduceVariant trackperf "${T4PMTRACKPERF}" t4DefaultPmTrackPerf "${@}"
}

function t4WhatPmTrackPerf ()
{
    local desc="${1}"
    [ -z "${desc}" ] && desc="currently "
    echo "T4PMTRACKPERF ${desc}equals '${T4PMTRACKPERF}'"
}

function t4ChPmTrackPerf ()
{
    local list_sep="\n"
    local -r s_list_sep="-s"
    local -r l_list_sep="--list-sep"
    local -r s_list="-l"
    local -r l_list="--list"
    local -r s_current="-c"
    local -r l_current="--current"
    local -r usage="usage: t4ChPmTrackPerf [${s_list_sep}|${l_list_sep} <separator>] [${l_list_sep}=<separator>] [${s_list}|${l_list}] [${s_current}|${l_current}] [<trackPerf>]"
    local -r -a list=(ntp tp)
    local -i idx=0

    while [ ${#} -gt 0 ] ; do
        case "${1}" in
            ${s_current}|${l_current})
            t4WhatPmTrackPerf
            return
        ;;
        ${s_list_sep}|${l_list_sep})
            shift
            list_sep="${1}"
        ;;
        ${l_list_sep}=*)
            list_sep="${1#${l_list_sep}=}"
        ;;
        ${s_list}|${l_list})
            while [[ ${idx} -lt ${#list[*]} ]] ; do
                if [[ ${idx} -gt 0 ]] ; then
                    echo -n -e "${list_sep}"
                fi
                echo -n "${list[${idx}]}"
                let idx=++idx
            done
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

    if [ ${#} -lt 1 ] ; then
        export T4PMTRACKPERF="$(t4DefaultPmTrackPerf)"
        t4WhatPmTrackPerf "now "
    else
        while [[ ${idx} -lt ${#list[*]} ]] ; do
            if [[ "${1}" == "${list[${idx}]}" ]] ; then
                export T4PMTRACKPERF="${1}"
                t4WhatPmTrackPerf "now "
                return
            fi
            let idx=++idx
        done
        echo "Invalid value for pmake variant 'trackperf': ${1}" >&2
    fi
}

[ -z "${NO_COMPLETE}" ] && complete -W "$(t4ChPmTrackPerf --list-sep=' ' --list)" t4ChPmTrackPerf

####################################################
# sync is what mechanism to syncronise with a server
####################################################

function t4DefaultPmSync ()
{
    t4RcOrDefault T4PMSYNC nosync
}

function t4DeducePmSync ()
{
    t4DeduceVariant sync "${T4PMSYNC}" t4DefaultPmSync "${@}"
}

function t4WhatPmSync ()
{
    local desc="${1}"
    [ -z "${desc}" ] && desc="currently "
    echo "T4PMSYNC ${desc}equals '${T4PMSYNC}'"
}

function t4ChPmSync ()
{
    local list_sep="\n"
    local -r s_list_sep="-s"
    local -r l_list_sep="--list-sep"
    local -r s_list="-l"
    local -r l_list="--list"
    local -r s_current="-c"
    local -r l_current="--current"
    local -r usage="usage: t4ChPmSync [${s_list_sep}|${l_list_sep} <separator>] [${l_list_sep}=<separator>] [${s_list}|${l_list}] [${s_current}|${l_current}] [<sync>]"
    local -r -a list=(nsync voxm)
    local -i idx=0

    while [ ${#} -gt 0 ] ; do
        case "${1}" in
            ${s_current}|${l_current})
            t4WhatPmSync
            return
        ;;
        ${s_list_sep}|${l_list_sep})
            shift
            list_sep="${1}"
        ;;
        ${l_list_sep}=*)
            list_sep="${1#${l_list_sep}=}"
        ;;
        ${s_list}|${l_list})
            while [[ ${idx} -lt ${#list[*]} ]] ; do
                if [[ ${idx} -gt 0 ]] ; then
                    echo -n -e "${list_sep}"
                fi
                echo -n "${list[${idx}]}"
                let idx=++idx
            done
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

    if [ ${#} -lt 1 ] ; then
        export T4PMSYNC="$(t4DefaultPmSync)"
        t4WhatPmSync "now "
    else
        while [[ ${idx} -lt ${#list[*]} ]] ; do
            if [[ "${1}" == "${list[${idx}]}" ]] ; then
                export T4PMSYNC="${1}"
                t4WhatPmSync "now "
                return
            fi
            let idx=++idx
        done
        echo "Invalid value for pmake variant 'sync': ${1}" >&2
    fi
}

[ -z "${NO_COMPLETE}" ] && complete -W "$(t4ChPmSync --list-sep=' ' --list)" t4ChPmSync

################################
# what set of actors to build in
################################

function t4DefaultPmActorSet ()
{
    t4RcOrDefault T4PMACTORSET full_actors
}

function t4DeducePmActorSet ()
{
    t4DeduceVariant sync "${T4PMACTORSET}" t4DefaultPmActorSet "${@}"
}

function t4WhatPmActorSet ()
{
    local desc="${1}"
    [ -z "${desc}" ] && desc="currently "
    echo "T4PMACTORSET ${desc}equals '${T4PMACTORSET}'"
}

function t4ChPmActorSet ()
{
    local list_sep="\n"
    local -r s_list_sep="-s"
    local -r l_list_sep="--list-sep"
    local -r s_list="-l"
    local -r l_list="--list"
    local -r s_current="-c"
    local -r l_current="--current"
    local -r usage="usage: t4ChPmActorSet [${s_list_sep}|${l_list_sep} <separator>] [${l_list_sep}=<separator>] [${s_list}|${l_list}] [${s_current}|${l_current}] [<actor set>]"
    local -r -a list=(full_actors med_actors lite_actors)
    local -i idx=0

    while [ ${#} -gt 0 ] ; do
        case "${1}" in
            ${s_current}|${l_current})
            t4WhatPmActorSet
            return
        ;;
        ${s_list_sep}|${l_list_sep})
            shift
            list_sep="${1}"
        ;;
        ${l_list_sep}=*)
            list_sep="${1#${l_list_sep}=}"
        ;;
        ${s_list}|${l_list})
            while [[ ${idx} -lt ${#list[*]} ]] ; do
                if [[ ${idx} -gt 0 ]] ; then
                    echo -n -e "${list_sep}"
                fi
                echo -n "${list[${idx}]}"
                let idx=++idx
            done
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

    if [ ${#} -lt 1 ] ; then
        export T4PMACTORSET="$(t4DefaultPmActorSet)"
        t4WhatPmActorSet "now "
    else
        while [[ ${idx} -lt ${#list[*]} ]] ; do
            if [[ "${1}" == "${list[${idx}]}" ]] ; then
                export T4PMACTORSET="${1}"
                t4WhatPmActorSet "now "
                return
            fi
            let idx=++idx
        done
        echo "Invalid value for pmake variant 'actorset': ${1}" >&2
    fi
}

[ -z "${NO_COMPLETE}" ] && complete -W "$(t4ChPmActorSet --list-sep=' ' --list)" t4ChPmActorSet

#########################################################
# The "host" is what kind os platform we're building *on*
#########################################################

function t4HostPmHost ()
{
    case "$(uname -s)" in
    Linux) echo unix;;
    CYGWIN_NT-5.0) echo win32;;
    esac
}

############################################################
# Use this to get the subdirectory where a binary will exist
############################################################

function t4DeducePmAllVariants ()
{
    local actorset=$(t4DeducePmActorSet "${@}")
    local debug_level=$(t4DeducePmDebugLevel "${@}")
    local debug_via=$(t4DeducePmDebugVia "${@}")
    local host=$(t4HostPmHost "${@}")
    local style=$(t4DeducePmStyle "${@}")
    local sync=
    local targetos=$(t4DeducePmTargetOS "${@}")
    if [ "${targetos}" == "symbian" ] ; then
        sync=-$(t4DeducePmSync "${@}")
    fi
    local testing=$(t4DeducePmTesting "${@}")
    local trackmem=$(t4DeducePmTrackMem "${@}")
    local trackperf=$(t4DeducePmTrackPerf "${@}")
    echo "${actorset}-${debug_level}-${debug_via}-${host}-${style}-${targetos}-${testing}-${trackmem}-${trackperf}"
}

function findPmakefiles ()
{
    local print="-print"
    if [ "${1}" == "-0" ] ; then
        local print="-print0"
        shift
    fi
    find "${@}" \( -name CVS -type d -prune \) -o \( -type f -name \*.pmake ${print} \)
}

function FIPmakefiles ()
{
    local dir=.
    local error=""
    local colour=""
    local listonly=""
    local wholeWords=""
    local -r wFlag="-w"
    local -r wLongFlag="--whole-words"
    local -r cFlag="-c"
    local -r cLongFlagUK="--colour"
    local -r cLongFlagUS="--color"

    while [ ${#} -gt 0 ] ; do
        case "${1}" in
        ${cFlag}|${cLongFlagUK}|${cLongFlagUS})
            colour="${cLongFlagUK}=always"
        ;;
        ${wFlag}|${wLongFlag})
            wholeWords="${wFlag}"
        ;;
        -l|--list)
            listonly="-l"
        ;;
        -*)
            echo "Invalid argument: ${1}" >&2
            echo -ne "usage:\tFIPmakefiles [${wFlag}|${wLongFlag}] [${cFlag}|${cLongFlagUK}|${cLongFlagUS}] [-l|--list] \c" >&2
            echo "[<directory>] <regular expression>" >&2
            error="yes"
            break
        ;;
        *)
            break
        ;;
        esac

        shift
    done

    if [ ${#} -gt 1 ] ; then
        dir=${1}
        shift
    fi

    if [ -z "${error}" ] ; then
        if [ "${listonly}" ] ; then
            colour=""
        fi

        if [ -z "${listonly}" ] ; then
            if doColour "${colour}" ; then
                colour="${cLongFlagUK}=always"
            fi
        fi

        findPmakefiles -0 "${dir}" | xargs -0 -n99 egrep ${wholeWords} ${colour} ${listonly} "${1}"
    fi
}
