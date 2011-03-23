#!/bin/bash

function t3RcValue ()
{
    local -r n1="${1}"
    local -r rc="${HOME}/.t3rc"
    if [ -r "${rc}" ] ; then
        sed -ne "s@^${n1}=@@p" < "${rc}"
    fi
}

function t3RcOrDefault ()
{
    local -r n2="${1}"
    local -r default="${2}"
    local -r value=$(t3RcValue "${n2}")

    if [ -n "${value}" ] ; then
        echo "${value}"
    else
        echo "${default}"
    fi
}

function AESALL ()
{
    cdt3
    AES
    cd -
    Ipcrm msg -a
    rm -f /tmp/queue-*-[0-9]* >&-
}

function t2MakeTitle ()
{
    if [ "${*}" ] ; then
        local -r target="${@}"
    else
        local -r target='"all"'
    fi

    local platform=$(t3DeduceTargetPlatform "${@}")

    case "${*}" in
    *TARGET_PLATFORM*)  titles both "make ${target} (cwd = $(npwd))" ;;
    *)                  titles both "make ${target} (TARGET_PLATFORM=${platform} && cwd = $(npwd))" ;;
    esac
}

function t3MakeTitle ()
{
    if [ "${*}" ] ; then
        local -r target="${@}"
    else
        local -r target='"all"'
    fi

    local -r profile="PROFILE="$(t3DeduceProfile "${@}")
    local -r subsystem="SUBSYSTEM="$(t3DeduceSubsystem "${@}")
    local -r buildos="BUILDOS="$(t3DeduceBuildOs "${@}")
    local -r buildarch="BUILDARCH="$(t3DeduceBuildArch "${@}")
    local -r ui="UI="$(t3DeduceUI "${@}")
    titles both "make ${target} (${profile} ${subsystem} ${buildos} ${buildarch} ${ui} && cwd = $(npwd))" >&2
}

function t3Deduce ()
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

function t3DefaultBuildChain ()
{
    t3RcOrDefault BUILDCHAIN GCC
}

function t3DefaultSET ()
{
    t3RcOrDefault SET identity
}

function t3DefaultTargetPlatform ()
{
    uname | tr '[A-Z]' '[a-z]'
}

function t3DeduceTargetPlatform ()
{
    t3Deduce TARGET_PLATFORM "${TARGET_PLATOFORM}" t3DefaultTargetPlatform "${@}"
}

function t3DefaultProfile ()
{
    t3RcOrDefault PROFILE d
}

function t3DeduceProfile ()
{
    t3Deduce PROFILE "${PROFILE}" t3DefaultProfile "${@}"
}

function t3DefaultUI ()
{
    t3RcOrDefault UI RouterTestUI1
}

function t3DeduceUI ()
{
    t3Deduce UI "${UI}" t3DefaultUI "${@}"
}

function t3DefaultSubsystem ()
{
    t3RcOrDefault SUBSYSTEM whole
}

function t3DeduceBuildChain ()
{
    t3Deduce BUILDCHAIN "${BUILDCHAIN}" t3DefaultBuildChain "${@}"
}

function t3WhatBuildChain ()
{
    local desc="${1}"
    [ -z "${desc}" ] && desc="currently "
    echo "BUILDCHAIN ${desc}equals '${BUILDCHAIN}'"
}

function t3ChBuildChain ()
{
    local -r l_list="--list"
    local -r s_current="-c"
    local -r l_current="--current"
    local -r usage="usage: t3ChBuildChain [${s_list}|${l_list}] [${s_current}|${l_current}] [<buildchain>]"

    while [ ${#} -gt 0 ] ; do
        case "${1}" in
            ${s_current}|${l_current})
            t3WhatBuildChain
            return
        ;;
        ${s_list}|${l_list})
            echo -e "GCC\nADS\nSDT\nHYBRID"
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

    removeT3DirsFromEnv
    if [ ${#} -lt 1 ] ; then
        export BUILDCHAIN="$(t3DefaultBuildChain)"
        t3WhatBuildChain "now "
        appendT3DirsToEnv
    else
        case ${1} in
        ""|GCC|ADS|SDT|HYBRID)
            export BUILDCHAIN="${1}"
            t3WhatBuildChain "now "
            appendT3DirsToEnv
        ;;
        *)
            echo "Invalid buildchain ${1}" >&2
        ;;
        esac
    fi
}

[ -z "${NO_COMPLETE}" ] && complete -W "GCC ADS SDT HYBRID" t3ChBuildChain

function t3DeduceSET ()
{
    t3Deduce SET "${SET}" t3DefaultSET "${@}"
}

function t3DeduceSubsystem ()
{
    t3Deduce SUBSYSTEM "${SUBSYSTEM}" t3DefaultSubsystem "${@}"
}

function t3DefaultBuildOs ()
{
    local -r dbo=$(uname -s | tr -d .-)
    t3RcOrDefault BUILDOS ${dbo}
}

function t3DeduceBuildOs ()
{
    t3Deduce BUILDOS "${BUILDOS}" t3DefaultBuildOs "${@}"
}

function t3DefaultBuildArch ()
{
    local -r dba=$(uname -m | sed -e 's@^i[3456]@x@')
    t3RcOrDefault BUILDARCH ${dba}
}

function t3DeduceBuildArch ()
{
    t3Deduce BUILDARCH "${BUILDARCH}" t3DefaultBuildArch "${@}"
}

function makeTitle ()
{
    t3MakeTitle "${@}"
}

function m ()
{
    local -r start=$(secondsSinceEpoch)
    makeTitle "${@}"
    export RETFILE=/tmp/dm.${$}
    trap "rm -f ${RETFILE}" EXIT INT
    (
        date +%D\ %H:%M.%S
        echo "PROFILE="$(t3DeduceProfile "${@}")
        echo "SUBSYSTEM="$(t3DeduceSubsystem "${@}")
        echo "BUILDARCH="$(t3DeduceBuildArch "${@}")
        echo "BUILDOS="$(t3DeduceBuildOs "${@}")
        echo "BUILDCHAIN="$(t3DeduceBuildChain "${@}")
        echo "UI="$(t3DeduceUI "${@}")
        echo "SET="$(t3DeduceSET "${@}")
        make ${*} 2>&1 | tr -d '\015'
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

function t2DMfile ()
{
# I want there to be one dm output file **per target**
    echo ".${USER}.$(t3DeduceTargetPlatform).make.out"
}

function t3DMfile ()
{
# I want there to be one dm output file **per target**
    echo ".${USER}.$(t3DeduceProfile).$(t3DeduceBuildOs).$(t3DeduceBuildArch).make.out"
}

function thisDMfile ()
{
  t3DMfile
}

#function thisDMfile ()
#{
#  # get the tty (without /dev/ in it)
#  local tty=$(tty | sed -e 's@^/dev/@@' -e 's@/@@g')
#
#  # I want there to be one dm output file **per tty**
#  echo ".${USER}.make.out.${tty}"
#}

function t3WhatTarget ()
{
    local desc="${1}"
    [ -z "${desc}" ] && desc="currently "
    echo "TARGET_PLATFORM ${desc}equals '${TARGET_PLATFORM}'"
}

function t3ChTarget ()
{
    local -r s_list="-l"
    local -r l_list="--list"
    local -r s_current="-c"
    local -r l_current="--current"
    local -r usage="usage: t3ChTarget [${s_list}|${l_list}] [${s_current}|${l_current}] [<target>]"

    while [ ${#} -gt 0 ] ; do
        case "${1}" in
            ${s_current}|${l_current})
            t3WhatTarget
            return
        ;;
        ${s_list}|${l_list})
            echo -e "linux\nipaq_linux\nipaq_ecos"
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
        export TARGET_PLATFORM="$(t3DefaultTargetPlatform)"
        t3WhatTarget "now "
    else
        case ${1} in
            ""|linux|ipaq_linux|ipaq_ecos)
            export TARGET_PLATFORM="${1}"
            t3WhatTarget "now "
        ;;
        *)
            echo "Invalid target ${1}" >&2
        ;;
        esac
    fi
}

function t3BuildRoot ()
{
    echo "${T3_HOME}/build"
}

function t3ThisBuildDir ()
{
    echo "$(t3BuildRoot)/$(t3DeduceBuildArch)/$(t3DeduceBuildOs)/$(t3DeduceBuildChain)/$(t3DeduceProfile)"
}

function t3ThisTestDir ()
{
    echo "$(t3ThisBuildDir)/test"
}

function t3ThisDistDir ()
{
    echo "$(t3ThisBuildDir)/dist"
}

function t3ThisResDir ()
{
    echo "$(t3BuildRoot)/data/${UI}"
}

function t3RemoveKinkResDirFromEnv ()
{
    unset KINKRESOURCEDIR
}

function t3AddKinkResDirToEnv ()
{
    local -r dir=${T3_HOME}/kink/Test
    [[ -d "${dir}" ]] && export KINKRESOURCEDIR=${dir}
}

function t3RemoveResDirFromEnv ()
{
    unset TRIG_RESOURCE_ROOT
    removeFromPath $(t3HomeOfUIs)/${UI}/systemtest
    removeFromPath "$(t3ThisBuildDir)/dist/${UI}"
}

function t3AddResDirToEnv ()
{
    export TRIG_RESOURCE_ROOT=$(t3ThisResDir)
    appendToPath $(t3HomeOfUIs)/${UI}/systemtest
    appendToPath "$(t3ThisBuildDir)/dist/${UI}"
}

function removeT3DirsFromEnv ()
{
    local -r buildDir="$(t3ThisBuildDir)"
    removeFromPath "${buildDir}/test"
    removeFromPath "${buildDir}/dist"
    removeFromPath "${T3_HOME}/tools/bin"
    t3RemoveResDirFromEnv
    t3RemoveKinkResDirFromEnv
}

function appendT3DirsToEnv ()
{
    local -r buildDir="$(t3ThisBuildDir)"
    appendToPath "${buildDir}/test"
    appendToPath "${buildDir}/dist"
    appendToPath "${T3_HOME}/tools/bin"
    t3AddResDirToEnv
    t3AddKinkResDirToEnv
}

function t3WhatProfile ()
{
    local desc="${1}"
    [ -z "${desc}" ] && desc="currently "
    echo "PROFILE ${desc}equals '${PROFILE}'"
}

function t3NameFromProfile ()
{
    case "${1}" in
        d)              echo "debug" ;;
        os)             echo "systest" ;;
        op)             echo "profiling" ;;
        do)             echo "chatty" ;;
        dos)            echo "stripped" ;;
        o)              echo "release" ;;
    esac
}

function t3ProfileFromName ()
{
    case "${1}" in
        debug)          echo "d" ;;
        systest)        echo "os" ;;
        profiling)      echo "op" ;;
        chatty)         echo "do" ;;
        stripped)       echo "dos" ;;
        release)        echo "o" ;;
    esac
}

function t3ChProfile ()
{
    local -r s_list="-l"
    local -r l_list="--list"
    local -r s_current="-c"
    local -r l_current="--current"
    local -r s_old="-o"
    local -r l_old="--old"
    local -r usage="usage: t3ChProfile [${s_list}|${l_list}] [${s_current}|${l_current}] [${s_old}|${l_old}] [<profile>]"
    local val

    while [ ${#} -gt 0 ] ; do
        case "${1}" in
            ${s_current}|${l_current})
            t3WhatProfile
            return
        ;;
        ${s_old}|${l_old})
            val="${OLDPROFILE}"
        ;;
        ${s_list}|${l_list})
            echo -e "debug\nrelease\nchatty\nprofiling\nsystest\nstripped"
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

    [ -z "${val}" -a ${#} -gt 0 ] && val="${1}"

    removeT3DirsFromEnv

    case "${val}" in
        "")
            val=normal
        ;;

        O|d|do|do|dop|dops|dos|dp|ds|o|op|ops|os|p|ps|s|m|mO|dm|dmo|dmo|dmop|dmops|dmos|dmp|dms|mo|mop|mops|mos|mp|mps|ms)
        ;;

        ""|debug|release|chatty|profiling|systest|stripped)
            val=$(t3ProfileFromName "${val}")
        ;;

        *)
            echo "Invalid profile ${1}" >&2
            return 1
        ;;
    esac

    export OLDPROFILE="${PROFILE}"
    export PROFILE=${val}
    t3WhatProfile "now "
    appendT3DirsToEnv
}

[ -z "${NO_COMPLETE}" ] && complete -W "debug release chatty profiling systest stripped p po pd ps pod pos pods o od os ods d ds" t3ChProfile

function t3WhatBuildOs ()
{
    local desc="${1}"
    [ -z "${desc}" ] && desc="currently "
    echo "BUILDOS ${desc}equals '${BUILDOS}'"
}

function t3ChBuildOs ()
{
    local -r s_list="-l"
    local -r l_list="--list"
    local -r s_current="-c"
    local -r l_current="--current"
    local -r usage="usage: t3ChBuildOs [${s_list}|${l_list}] [${s_current}|${l_current}] [<buildos>]"

    while [ ${#} -gt 0 ] ; do
        case "${1}" in
            ${s_current}|${l_current})
            t3WhatBuildOs
            return
        ;;
        ${s_list}|${l_list})
            echo -e "Linux\nOSE\nSysol2\nWin32\nWCE300\nCYGWIN_NT50"
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

    removeT3DirsFromEnv
    if [ ${#} -lt 1 ] ; then
        export BUILDOS="$(t3DefaultBuildOs)"
        t3WhatBuildOs "now "
        appendT3DirsToEnv
    else
        case ${1} in
        ""|Linux|OSE|Sysol2|Win32|WCE300|CYGWINNT_50)
            export BUILDOS="${1}"
            t3WhatBuildOs "now "
            appendT3DirsToEnv
        ;;
        *)
            echo "Invalid buildos ${1}" >&2
        ;;
        esac
    fi
}

[ -z "${NO_COMPLETE}" ] && complete -W "Linux OSE Sysol2 Win32 WCE300 CYGWINNT_50" t3ChBuildOs

function t3WhatBuildArch ()
{
    local desc="${1}"
    [ -z "${desc}" ] && desc="currently "
    echo "BUILDARCH ${desc}equals '${BUILDARCH}'"
}

function t3BuildChainSanity ()
{
    case "${BUILDARCH}" in
    THUMB|ARM) [ "${BUILDCHAIN}" = "GCC" ] && t3ChBuildChain ADS ;;
    x86)
        case "${BUILDCHAIN}" in
        ADS|SDT) t3ChBuildChain GCC ;;
        esac
    ;;
    esac
}

function t3ChBuildArch ()
{
    local s_list="-l"
    local l_list="--list"
    local s_current="-c"
    local l_current="--current"
    local usage="usage: t3ChBuildArch [${s_list}|${l_list}] [${s_current}|${l_current}] [<buildarch>]"

    while [ ${#} -gt 0 ] ; do
        case "${1}" in
            ${s_current}|${l_current})
            t3WhatBuildArch
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

    removeT3DirsFromEnv
    if [ ${#} -lt 1 ] ; then
        export BUILDARCH="$(t3DefaultBuildArch)"
        t3WhatBuildArch "now "
        appendT3DirsToEnv
        t3BuildChainSanity
    else
        case ${1} in
        ""|x86|ARM|THUMB)
            export BUILDARCH="${1}"
            t3WhatBuildArch "now "
            appendT3DirsToEnv
            t3BuildChainSanity
        ;;
        *)
            echo "Invalid buildarch ${1}" >&2
        ;;
        esac
    fi
}

[ -z "${NO_COMPLETE}" ] && complete -W "x86 ARM THUMB" t3ChBuildArch

function t3BuildDebug ()
{
    t3ChProfile debug
    t3ChBuildOs
    t3ChBuildArch
}

function t3BuildDebugArm ()
{
    t3ChProfile debug
    t3ChBuildOs OSE
    t3ChBuildArch ARM
}

function t3BuildDebugThumb ()
{
    t3ChProfile debug
    t3ChBuildOs OSE
    t3ChBuildArch THUMB
}

function t3BuildChatty ()
{
    t3ChProfile chatty
    t3ChBuildOs
    t3ChBuildArch
}

function t3BuildChattyArm ()
{
    t3ChProfile chatty
    t3ChBuildOs OSE
    t3ChBuildArch ARM
}

function t3BuildChattyThumb ()
{
    t3ChProfile chatty
    t3ChBuildOs OSE
    t3ChBuildArch THUMB
}

function t3BuildRelease ()
{
    t3ChProfile release
    t3ChBuildOs
    t3ChBuildArch
}

function t3BuildReleaseArm ()
{
    t3ChProfile release
    t3ChBuildOs OSE
    t3ChBuildArch ARM
}

function t3BuildReleaseThumb ()
{
    t3ChProfile release
    t3ChBuildOs OSE
    t3ChBuildArch THUMB
}

function t3BuildSystest ()
{
    t3ChProfile systest
    t3ChBuildOs
    t3ChBuildArch
}

function t3BuildSystestArm ()
{
    t3ChProfile systest
    t3ChBuildOs OSE
    t3ChBuildArch ARM
}

function t3BuildSystestThumb ()
{
    t3ChProfile systest
    t3ChBuildOs OSE
    t3ChBuildArch THUMB
}

function t3BuildProfiling ()
{
    t3ChProfile profiling
    t3ChBuildOs
    t3ChBuildArch
}

function t3BuildProfilingArm ()
{
    t3ChProfile profiling
    t3ChBuildOs OSE
    t3ChBuildArch ARM
}

function t3BuildProfilingThumb ()
{
    t3ChProfile profiling
    t3ChBuildOs OSE
    t3ChBuildArch THUMB
}

function t3BuildStripped ()
{
    t3ChProfile stripped
    t3ChBuildOs
    t3ChBuildArch
}

function t3BuildStrippedArm ()
{
    t3ChProfile stripped
    t3ChBuildOs OSE
    t3ChBuildArch ARM
}

function t3BuildStrippedThumb ()
{
    t3ChProfile stripped
    t3ChBuildOs OSE
    t3ChBuildArch THUMB
}

function t3BuildReleaseSysol2 ()
{
    t3ChProfile release
    t3ChBuildOs Sysol2
    t3ChBuildChain SDT
    t3ChBuildArch THUMB
}

function t3HomeOfUIs ()
{
    echo "${T3_HOME}/content"
}

function t3MainSETfile ()
{
    echo "3g_main.xsl"
}

function t3ValidSETList ()
{
    local s
    local -a list=()
    local -r msf="$(t3MainSETfile)"
    for s in $(/bin/ls -1 $(t3HomeOfUIs)/${UI}/set/*/${msf} 2>&-) ; do
        s=${s%/${msf}}
        s=${s##*/}
        list=(${list[@]} ${s})
    done
    echo ${list[@]}
}

function t3WhatSET ()
{
    local desc="${1}"
    [ -z "${desc}" ] && desc="currently "
    echo "SET ${desc}equals '${SET}'"
}

function t3ChSET ()
{
    local -r s_list="-l"
    local -r l_list="--list"
    local -r s_current="-c"
    local -r l_current="--current"
    local -r usage="usage: t3ChSET [${s_list}|${l_list}] [${s_current}|${l_current}] [<SET>]"

    while [ ${#} -gt 0 ] ; do
        case "${1}" in
            ${s_current}|${l_current})
            t3WhatSET
            return
        ;;
        ${s_list}|${l_list})
            t3ValidSETList
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
        export SET="$(t3DefaultSET)"
        t3WhatSET "now "
    else
        if [ -f $(t3HomeOfUIs)/${UI}/set/${1}/$(t3MainSETfile) ] ; then
            export SET="${1}"
            t3WhatSET "now "
        else
            echo "Invalid SET ${1}" >&2
        fi
    fi
}

function t3CompleteSET ()
{
#   echo '${COMP_CWORD} = '"'${COMP_CWORD}'" > /dev/pts/3
    if [ ${COMP_CWORD} -eq 1 ] ; then
        local word="${2}"
        local rep=0
        local -a reply
        local -a valid=($(t3ValidSETList))
#       echo '${valid} = '"'${valid[@]}'" > /dev/pts/3
        if [ -n "${word}" ] ; then
            local ui=
            for ui in ${valid[@]} ; do
#               echo "Does ui='${ui}' =~ ${word}*?" > /dev/pts/3
                case "${ui}" in
                ${word}*)
#                   echo yes > /dev/pts/3
                    reply[${rep}]=${ui}
                    rep=$((++rep))
                ;;
                esac
            done
        else
            reply=(${valid[@]})
        fi

        COMPREPLY=(${reply[@]})
    else
        COMPREPLY=()
    fi
}

[ -z "${NO_COMPLETE}" ] && complete -F t3CompleteSET t3ChSET

function t3MainUIfile ()
{
    echo "3g_main.xml"
}

function t3ValidUIList ()
{
    local ui
    local -a list=()
    for ui in $(/bin/ls -1 $(t3HomeOfUIs)/*/$(t3MainUIfile) 2>&-) ; do
        ui=${ui%/$(t3MainUIfile)}
        ui=${ui##*/}
        list=(${list[@]} ${ui})
    done
    echo ${list[@]}
}

function t3WhatUI ()
{
    local desc="${1}"
    [ -z "${desc}" ] && desc="currently "
    echo "UI ${desc}equals '${UI}'"
}

function t3ChUI ()
{
    local -r s_list="-l"
    local -r l_list="--list"
    local -r s_current="-c"
    local -r l_current="--current"
    local -r usage="usage: t3ChUI [${s_list}|${l_list}] [${s_current}|${l_current}] [<UI>]"

    while [ ${#} -gt 0 ] ; do
        case "${1}" in
            ${s_current}|${l_current})
            t3WhatUI
            return
        ;;
        ${s_list}|${l_list})
            t3ValidUIList
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
        t3RemoveResDirFromEnv
        export UI="$(t3DefaultUI)"
        t3AddResDirToEnv
        t3WhatUI "now "
    else
        if [ -f $(t3HomeOfUIs)/${1}/$(t3MainUIfile) ] ; then
            t3RemoveResDirFromEnv
            export UI="${1}"
            t3AddResDirToEnv
            t3WhatUI "now "
        else
            echo "Invalid UI ${1}" >&2
        fi
    fi
}

function t3CompleteUI ()
{
#   echo '${COMP_CWORD} = '"'${COMP_CWORD}'" > /dev/pts/3
    if [ ${COMP_CWORD} -eq 1 ] ; then
        local word="${2}"
        local rep=0
        local -a reply
        local -a valid=($(t3ValidUIList))
#       echo '${valid} = '"'${valid[@]}'" > /dev/pts/3
        if [ -n "${word}" ] ; then
            local ui=
            for ui in ${valid[@]} ; do
#               echo "Does ui='${ui}' =~ ${word}*?" > /dev/pts/3
                case "${ui}" in
                ${word}*)
#                   echo yes > /dev/pts/3
                    reply[${rep}]=${ui}
                    rep=$((++rep))
                ;;
                esac
            done
        else
            reply=(${valid[@]})
        fi

        COMPREPLY=(${reply[@]})
    else
        COMPREPLY=()
    fi
}

[ -z "${NO_COMPLETE}" ] && complete -F t3CompleteUI t3ChUI

function t3DefaultSamsungHome ()
{
    t3RcOrDefault SAMSUNG_HOME ''
}

function t3Values ()
{
    t3WhatProfile
    t3WhatBuildArch
    t3WhatBuildOs
    t3WhatBuildChain
    t3WhatPlatform
    t3WhatUI
    t3WhatSET
    [ -z "${SAMSUNG_HOME}" ] || t3WhatSamsungHome
}

function t3Defaults ()
{
    [ -z "${PROFILE}" ] && export PROFILE=$(t3DefaultProfile)
    [ -z "${BUILDARCH}" ] && export BUILDARCH=$(t3DefaultBuildArch)
    [ -z "${BUILDOS}" ] && export BUILDOS=$(t3DefaultBuildOs)
    [ -z "${BUILDCHAIN}" ] && export BUILDCHAIN=$(t3DefaultBuildChain)
    [ -z "${BUILDPLATFORM}" ] && export BUILDPLATFORM=$(t3DefaultPlatform)
    [ -z "${UI}" ] && export UI=$(t3DefaultUI)
    [ -z "${SET}" ] && export SET=$(t3DefaultSET)
    local -r dsh=$(t3DefaultSamsungHome)
    [ -z "${SAMSUNG_HOME}" -a -n "${dsh}" -a -d "${dsh}" ] && export SAMSUNG_HOME=${dsh}
}

function cdsh ()
{
    if [ -n "${SAMSUNG_HOME}" ] ; then
        cd "${SAMSUNG_HOME}"
    fi
}

function cdt3 ()
{
    if [ -n "${T3_HOME}" ] ; then
        cd "${T3_HOME}"
    fi

#PROMPT_COMMAND='echo -n "$(titles both ${USER}@${HOSTNAME%%.*}:$(tty | sed -e s/\\/dev\\/pts\\///):PROFILE=$(t3DeduceProfile):BUILDOS=$(t3DeduceBuildOs):BUILDARCH=$(t3DeduceBuildArch):UI=$(t3DeduceUI):$(npwd))"'
    if [ ${#} -gt 0 ] ; then
        if [ -z "${T3XTERMTITLE}" ] ; then
            export T3XTERMTITLE='T3=${T3_HOME/${HOME}/~}:$(t3DeduceProfile):$(t3DeduceBuildOs):$(t3DeduceBuildArch):$(t3DeduceUI)'
            xtermTitle "${XTERM_TITLE}:${T3XTERMTITLE}"
        fi
    fi
}

function cht3 ()
{
    if [ -n "${T3_HOME}" ] ; then
        removeT3DirsFromEnv
    fi
    export T3_HOME="${1}"
    trigenixDefaults
    appendT3DirsToEnv
}

function t3DefaultHome ()
{
    t3RcOrDefault T3_HOME ${HOME}/dev/t3
}

function t3GetRepos ()
{
    local -x CVSHOST="vulpix.3glab.com"
    local -x CVSREPOS="/data/projects/clientdist"
    local -x CVSROOT=":ext:${USER}@${CVSHOST}:${CVSREPOS}"

    local -x dir="${1}"
    echo -n "Performing CVS checkout of t3 in ${dir}"
    pushd "${dir%/*}" > /dev/null 2>&1
    cvs -Q co -d "${dir##*/}" t3 2>&-
    local -i ret=${?}
    popd > /dev/null 2>&1
    if [ 0 -ne ${ret} ] ; then
        echo -e "\nCVS checkout failed"
        if [ -d "${dir}" ] ; then
            echo -n "Deleting partially checked-out directory"
            rm -fr "${dir##*/}"
            echo ", done."
        fi
        return ${ret}
    fi

    pushd "${dir}" > /dev/null 2>&1
    echo -ne ", done.\nGenerating tags file in ${dir}"
    CTAGS=$(cat ./tools/data/.ctags) ctags -R
    echo -ne ", done.\nGenerating dependency files in ${dir}"
    make depend >&/dev/null 2>&1

    echo -ne ", done\nPerforming CVS update in ${dir}"
    cvs -Q up 2>&-
    ret=${?}
    popd > /dev/null 2>&1
    if [ 0 -ne ${ret} ] ; then
        echo -ne "\nCVS update failed\nDeleting partially updated directory"
        rm -fr "${dir}"
        echo ", done."
        return ${ret}
    fi

    echo ", done."

    return ${ret}
}

function t3mksb ()
{
    if [ -d "${1}" ] ; then
        echo "Directory ${1} alreay exists!"
        return -1
    fi

    case "${1}" in
    /*) t3GetRepos "${1}" ;;
    *) t3GetRepos "${PWD}/${1}" ;;
    esac

    local -i ret=${?}
    if [ -d "${1}" ] ; then
        case "${1}" in
        /*) cht3 "${1}" ;;
        *) cht3 "${PWD}/${1}" ;;
        esac
        cdt3
        gvim
    fi
}

function t3WhatSamsungHome ()
{
    local desc="${1}"
    [ -z "${desc}" ] && desc="currently "
    echo "SAMSUNG_HOME ${desc}equals '${SAMSUNG_HOME}'"
}

function t3ChSamsungHome ()
{
    if [ -n "${1}" ] ; then
        if [ "${SAMSUNG_HOME}" == "${1}" ] ; then
            t3WhatSamsungHome "already "
        elif [ -d "${1}/sys2/driv/master/srce" ] ; then
            export SAMSUNG_HOME="${1}"
            t3WhatSamsungHome "now "
        fi
    else
        echo "Invalid directory for Samsung HOME" >&2
        return -1
    fi
}

[ -z "${NO_COMPLETE}" ] && complete -d t3ChSamsungHome

function t3DefaultPlatform ()
{
    t3RcOrDefault BUILDPLATFORM X11
}

function t3WhatPlatform ()
{
    local desc="${1}"
    [ -z "${desc}" ] && desc="currently "
    echo "BUILDPLATFORM ${desc}equals '${BUILDPLATFORM}'"
}

function t3ChPlatform ()
{
    local -r s_list="-l"
    local -r l_list="--list"
    local -r s_current="-c"
    local -r l_current="--current"
    local -r usage="usage: t3ChPlatform [${s_list}|${l_list}] [${s_current}|${l_current}] [<PLATFORM>]"

    while [ ${#} -gt 0 ] ; do
        case "${1}" in
            ${s_current}|${l_current})
            t3WhatPlatform
            return
        ;;
        ${s_list}|${l_list})
            echo -e "COGENT\nMAVERICK\nX11\nSHARK\nS500\nBSI"
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
        export BUILDPLATFORM="$(t3DefaultPlatform)"
        t3WhatPlatform "now "
    else
        case ${1} in
        ""|COGENT|MAVERICK|X11|SHARK|S500|BSI)
            export BUILDPLATFORM="${1}"
            t3WhatPlatform "now "
        ;;
        *)
            echo "Invalid platform ${1}" >&2
        ;;
        esac
    fi
}

[ -z "${NO_COMPLETE}" ] && complete -W "COGENT MAVERICK X11 SHARK S500 BSI" t3ChPlatform

if [ -z "${T3_HOME}" ] ; then
    cht3 $(t3DefaultHome)
else
    cht3 "${T3_HOME}"
fi

. ads.profile
