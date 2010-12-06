#!/bin/bash

function t4RcValue ()
{
    local -r n1="${1}"
    local -r rc="${HOME}/.t4rc"
    if [ -r "${rc}" ] ; then
        sed -ne "s@^${n1}=@@p" < "${rc}"
    fi
}

function t4RcOrDefault ()
{
    local -r n2="${1}"
    local -r default="${2}"
    local -r value=$(t4RcValue "${n2}")

    if [ -n "${value}" ] ; then
        echo "${value}"
    else
        echo "${default}"
    fi
}

function t4MakeTitle ()
{
    local cmd=${1}
    shift
    if [ "${*}" ] ; then
        local -r target="${@}"
    else
        local -r target='"all"'
    fi

    case "${cmd}" in
    pmake|pbuild)
        titles both "${cmd} ${target} (cwd = $(npwd))" >&2
    ;;

    *)
        local -r profile="T4PROFILE="$(t4DeduceProfile "${@}")
        local -r subsystem="T4SUBSYSTEM="$(t4DeduceSubsystem "${@}")
        local -r buildos="T4BUILDOS="$(t4DeduceBuildOs "${@}")
        local -r buildarch="T4BUILDARCH="$(t4DeduceBuildArch "${@}")
        titles both "${cmd} ${target} (${profile} ${subsystem} ${buildos} ${buildarch} && cwd = $(npwd))" >&2
    ;;
    esac
}

function t4Deduce ()
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

function t4DefaultBuildChain ()
{
    t4RcOrDefault T4BUILDCHAIN GCC
}

function t4DefaultProfile ()
{
    t4RcOrDefault T4PROFILE d
}

function t4DeduceProfile ()
{
    t4Deduce T4PROFILE "${T4PROFILE}" t4DefaultProfile "${@}"
}

function t4DefaultSubsystem ()
{
    t4RcOrDefault T4SUBSYSTEM whole
}

function t4DeduceBuildChain ()
{
    t4Deduce T4BUILDCHAIN "${T4BUILDCHAIN}" t4DefaultBuildChain "${@}"
}

function t4WhatBuildChain ()
{
    local desc="${1}"
    [ -z "${desc}" ] && desc="currently "
    echo "T4BUILDCHAIN ${desc}equals '${T4BUILDCHAIN}'"
}

function t4ChBuildChain ()
{
    local -r l_list="--list"
    local -r s_current="-c"
    local -r l_current="--current"
    local -r usage="usage: t4ChBuildChain [${s_list}|${l_list}] [${s_current}|${l_current}] [<buildchain>]"

    while [ ${#} -gt 0 ] ; do
        case "${1}" in
            ${s_current}|${l_current})
            t4WhatBuildChain
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

    t4RemoveDirsFromEnv
    if [ ${#} -lt 1 ] ; then
        export T4BUILDCHAIN="$(t4DefaultBuildChain)"
        t4WhatBuildChain "now "
        t4AppendDirsToEnv
    else
        case ${1} in
        ""|GCC|ADS|EVC)
            export T4BUILDCHAIN="${1}"
            t4WhatBuildChain "now "
            t4AppendDirsToEnv
        ;;
        *)
            echo "Invalid buildchain ${1}" >&2
        ;;
        esac
    fi
}

[ -z "${NO_COMPLETE}" ] && complete -W "GCC ADS EVC" t4ChBuildChain

function t4DeduceSubsystem ()
{
    t4Deduce T4SUBSYSTEM "${T4SUBSYSTEM}" t4DefaultSubsystem "${@}"
}

function t4DefaultBuildOs ()
{
    local -r dbo=$(uname -s | tr -d .-)
    t4RcOrDefault T4BUILDOS ${dbo}
}

function t4DeduceBuildOs ()
{
    t4Deduce T4BUILDOS "${T4BUILDOS}" t4DefaultBuildOs "${@}"
}

function t4DefaultBuildArch ()
{
    local -r dba=$(uname -m | sed -e 's@^i[3456]@x@')
    t4RcOrDefault T4BUILDARCH ${dba}
}

function t4DeduceBuildArch ()
{
    t4Deduce T4BUILDARCH "${T4BUILDARCH}" t4DefaultBuildArch "${@}"
}

function m ()
{
    local -r start=$(secondsSinceEpoch)
    t4MakeTitle make "${@}"
    export RETFILE=/tmp/dm.${$}
    trap "rm -f ${RETFILE}" EXIT INT
    (
        date +%D\ %H:%M.%S
        echo "T4PROFILE="$(t4DeduceProfile "${@}")
        echo "T4SUBSYSTEM="$(t4DeduceSubsystem "${@}")
        echo "T4BUILDARCH="$(t4DeduceBuildArch "${@}")
        echo "T4BUILDOS="$(t4DeduceBuildOs "${@}")
        echo "T4BUILDCHAIN="$(t4DeduceBuildChain "${@}")
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

function t4DMfile ()
{
# I want there to be one dm output file **per target**
    echo ".${USER}.$(t4DeduceProfile).$(t4DeduceBuildOs).$(t4DeduceBuildArch).make.out"
}

function t4ThisDMfile ()
{
  t4DMfile
}

function t4Home ()
{
    echo "${T4_HOME}/code/player/portable"
}

function t4BuildRoot ()
{
    echo "$(t4Home)/build"
}

function t4ThisBuildDir ()
{
    echo "$(t4BuildRoot)/$(t4DeduceBuildArch)/$(t4DeduceBuildOs)/$(t4DeduceBuildChain)/$(t4DeduceProfile)"
}

function t4ThisTestDir ()
{
    echo "$(t4ThisBuildDir)/test"
}

function t4ThisDistDir ()
{
    echo "$(t4ThisBuildDir)/dist"
}

function t4ThisResDir ()
{
    echo "$(t4BuildRoot)/data/${UI}"
}

function t4RemoveDirsFromEnv ()
{
    # local -r buildDir="$(t4ThisBuildDir)"
    removeFromPath "$(t4Home)/tools/bin"
    # removeFromPath "${buildDir}/test"
    # removeFromPath "${buildDir}/dist"
    # removeFromPath "$(t4Home)/build/exe"
    # removeFromPath "${T4_HOME}/code/common/tools"
}

function t4AppendDirsToEnv ()
{
    # local -r buildDir="$(t4ThisBuildDir)"
    appendToPath "$(t4Home)/tools/bin"
    # appendToPath "${buildDir}/test"
    # appendToPath "${buildDir}/dist"
    # appendToPath "$(t4Home)/build/exe"
    # appendToPath "${T4_HOME}/code/common/tools"
}

function t4WhatProfile ()
{
    local desc="${1}"
    [ -z "${desc}" ] && desc="currently "
    echo "T4PROFILE ${desc}equals '${T4PROFILE}'"
}

function nameFromProfile ()
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

function profileFromName ()
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

function t4ChProfile ()
{
    local -r s_list="-l"
    local -r l_list="--list"
    local -r s_current="-c"
    local -r l_current="--current"
    local -r s_old="-o"
    local -r l_old="--old"
    local -r usage="usage: t4ChProfile [${s_list}|${l_list}] [${s_current}|${l_current}] [${s_old}|${l_old}] [<profile>]"
    local val

    while [ ${#} -gt 0 ] ; do
        case "${1}" in
            ${s_current}|${l_current})
            t4WhatProfile
            return
        ;;
        ${s_old}|${l_old})
            val="${T4OLDPROFILE}"
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

    t4RemoveDirsFromEnv

    case "${val}" in
        "")
            val=normal
        ;;

        O|d|do|do|dop|dops|dos|dp|ds|o|op|ops|os|p|ps|s|m|mO|dm|dmo|dmo|dmop|dmops|dmos|dmp|dms|mo|mop|mops|mos|mp|mps|ms)
        ;;

        ""|debug|release|chatty|profiling|systest|stripped)
            val=$(profileFromName "${val}")
        ;;

        *)
            echo "Invalid profile ${1}" >&2
            return 1
        ;;
    esac

    export T4OLDPROFILE="${T4PROFILE}"
    export T4PROFILE=${val}
    t4WhatProfile "now "
    t4AppendDirsToEnv
}

[ -z "${NO_COMPLETE}" ] && complete -W "debug release chatty profiling systest stripped p po pd ps pod pos pods o od os ods d ds" t4ChProfile

function t4WhatBuildOs ()
{
    local desc="${1}"
    [ -z "${desc}" ] && desc="currently "
    echo "T4BUILDOS ${desc}equals '${T4BUILDOS}'"
}

function t4ChBuildOs ()
{
    local -r s_list="-l"
    local -r l_list="--list"
    local -r s_current="-c"
    local -r l_current="--current"
    local -r usage="usage: t4ChBuildOs [${s_list}|${l_list}] [${s_current}|${l_current}] [<buildos>]"

    while [ ${#} -gt 0 ] ; do
        case "${1}" in
            ${s_current}|${l_current})
            t4WhatBuildOs
            return
        ;;
        ${s_list}|${l_list})
            echo -e "Linux\nOSE\nWin32\nWCE300"
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

    t4RemoveDirsFromEnv
    if [ ${#} -lt 1 ] ; then
        export T4BUILDOS="$(t4DefaultBuildOs)"
        t4WhatBuildOs "now "
        t4AppendDirsToEnv
    else
        case ${1} in
        ""|Linux|OSE|Win32|WCE300)
            export T4BUILDOS="${1}"
            t4WhatBuildOs "now "
            t4AppendDirsToEnv
        ;;
        *)
            echo "Invalid buildos ${1}" >&2
        ;;
        esac
    fi
}

[ -z "${NO_COMPLETE}" ] && complete -W "Linux OSE Win32 WCE300" t4ChBuildOs

function t4WhatBuildArch ()
{
    local desc="${1}"
    [ -z "${desc}" ] && desc="currently "
    echo "T4BUILDARCH ${desc}equals '${T4BUILDARCH}'"
}

function t4BuildChainSanity ()
{
    case "${T4BUILDARCH}" in
    THUMB|ARM) [ "${T4BUILDCHAIN}" = "GCC" ] && t4ChBuildChain ADS ;;
    x86)
        case "${T4BUILDCHAIN}" in
        ADS|SDT) t4ChBuildChain GCC ;;
        esac
    ;;
    esac
}

function t4ChBuildArch ()
{
    local s_list="-l"
    local l_list="--list"
    local s_current="-c"
    local l_current="--current"
    local usage="usage: t4ChBuildArch [${s_list}|${l_list}] [${s_current}|${l_current}] [<buildarch>]"

    while [ ${#} -gt 0 ] ; do
        case "${1}" in
            ${s_current}|${l_current})
            t4WhatBuildArch
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

    t4RemoveDirsFromEnv
    if [ ${#} -lt 1 ] ; then
        export T4BUILDARCH="$(t4DefaultBuildArch)"
        t4WhatBuildArch "now "
        t4AppendDirsToEnv
        t4BuildChainSanity
    else
        case ${1} in
        ""|x86|ARM|THUMB)
            export T4BUILDARCH="${1}"
            t4WhatBuildArch "now "
            t4AppendDirsToEnv
            t4BuildChainSanity
        ;;
        *)
            echo "Invalid buildarch ${1}" >&2
        ;;
        esac
    fi
}

[ -z "${NO_COMPLETE}" ] && complete -W "x86 ARM THUMB" t4ChBuildArch

function t4BuildDebug ()
{
    t4ChProfile debug
    t4ChBuildOs
    t4ChBuildArch
}

function t4BuildDebugArm ()
{
    t4ChProfile debug
    t4ChBuildOs OSE
    t4ChBuildArch ARM
}

function t4BuildDebugThumb ()
{
    t4ChProfile debug
    t4ChBuildOs OSE
    t4ChBuildArch THUMB
}

function t4BuildChatty ()
{
    t4ChProfile chatty
    t4ChBuildOs
    t4ChBuildArch
}

function t4BuildChattyArm ()
{
    t4ChProfile chatty
    t4ChBuildOs OSE
    t4ChBuildArch ARM
}

function t4BuildChattyThumb ()
{
    t4ChProfile chatty
    t4ChBuildOs OSE
    t4ChBuildArch THUMB
}

function t4BuildRelease ()
{
    t4ChProfile release
    t4ChBuildOs
    t4ChBuildArch
}

function t4BuildReleaseArm ()
{
    t4ChProfile release
    t4ChBuildOs OSE
    t4ChBuildArch ARM
}

function t4BuildReleaseThumb ()
{
    t4ChProfile release
    t4ChBuildOs OSE
    t4ChBuildArch THUMB
}

function t4BuildSystest ()
{
    t4ChProfile systest
    t4ChBuildOs
    t4ChBuildArch
}

function t4BuildSystestArm ()
{
    t4ChProfile systest
    t4ChBuildOs OSE
    t4ChBuildArch ARM
}

function t4BuildSystestThumb ()
{
    t4ChProfile systest
    t4ChBuildOs OSE
    t4ChBuildArch THUMB
}

function t4BuildProfiling ()
{
    t4ChProfile profiling
    t4ChBuildOs
    t4ChBuildArch
}

function t4BuildProfilingArm ()
{
    t4ChProfile profiling
    t4ChBuildOs OSE
    t4ChBuildArch ARM
}

function t4BuildProfilingThumb ()
{
    t4ChProfile profiling
    t4ChBuildOs OSE
    t4ChBuildArch THUMB
}

function t4BuildStripped ()
{
    t4ChProfile stripped
    t4ChBuildOs
    t4ChBuildArch
}

function t4BuildStrippedArm ()
{
    t4ChProfile stripped
    t4ChBuildOs OSE
    t4ChBuildArch ARM
}

function t4BuildStrippedThumb ()
{
    t4ChProfile stripped
    t4ChBuildOs OSE
    t4ChBuildArch THUMB
}

function t4Values ()
{
    t4WhatProfile
    t4WhatBuildArch
    t4WhatBuildOs
    t4WhatBuildChain
    t4WhatPlatform
}

function trigenixDefaults ()
{
    [ -z "${T4PROFILE}" ] && export T4PROFILE=$(t4DefaultProfile)
    [ -z "${T4BUILDARCH}" ] && export T4BUILDARCH=$(t4DefaultBuildArch)
    [ -z "${T4BUILDOS}" ] && export T4BUILDOS=$(t4DefaultBuildOs)
    [ -z "${T4BUILDCHAIN}" ] && export T4BUILDCHAIN=$(t4DefaultBuildChain)
    [ -z "${T4BUILDPLATFORM}" ] && export T4BUILDPLATFORM=$(t4DefaultPlatform)
}

function cdt4 ()
{
    if [ -n "${T4_HOME}" ] ; then
        cd "${T4_HOME}/code/player/portable"
    fi

#PROMPT_COMMAND='echo -n "$(titles both ${USER}@${HOSTNAME%%.*}:$(tty | sed -e s/\\/dev\\/pts\\///):T4PROFILE=$(t4DeduceProfile):T4BUILDOS=$(t4DeduceBuildOs):T4BUILDARCH=$(t4DeduceBuildArch):$(npwd))"'
    if [ ${#} -gt 0 ] ; then
        if [ -z "${T4XTERMTITLE}" ] ; then
            export T4XTERMTITLE='T4=${T4_HOME/${HOME}/~}:$(t4DeduceProfile):$(t4DeduceBuildOs):$(t4DeduceBuildArch)'
            xtermTitle "${XTERM_TITLE}:${T4XTERMTITLE}"
        fi
    fi
}

function cht4 ()
{
    if [ -n "${T4_HOME}" ] ; then
        t4RemoveDirsFromEnv
    fi
    export T4_HOME="${1}"
    trigenixDefaults
    t4AppendDirsToEnv
}

function defaultT4 ()
{
    t4RcOrDefault T4_HOME ${HOME}/dev/t4
}

function gett4repos ()
{
    local -x CVSHOST="vulpix.3glab.com"
    local -x CVSREPOS="/data/product"
    local -x CVSROOT=":ext:${USER}@${CVSHOST}:${CVSREPOS}"
    local -x CVSMODULE="dinky"

    local -x dir="${1}"
    echo -n "Performing CVS checkout of ${CVSMODULE} in ${dir}"
    pushd "${dir%/*}" >&- 2>&-
    cvs -Q co -d "${dir##*/}" ${CVSMODULE} 2>&-
    local -i ret=${?}
    popd >&- 2>&-
    if [ 0 -ne ${ret} ] ; then
        echo -e "\nCVS checkout failed"
        if [ -d "${dir}" ] ; then
            echo -n "Deleting partially checked-out directory"
            rm -fr "${dir##*/}"
            echo ", done."
        fi
        return ${ret}
    fi

    pushd "${dir}" >&- 2>&-
    echo -ne ", done.\nGenerating tags file in ${dir}"
    CTAGS=$(cat ./tools/data/.ctags) ctags -R
    echo -ne ", done.\nGenerating dependency files in ${dir}"
    make depend >&/dev/null 2>&1

    echo -ne ", done\nPerforming CVS update in ${dir}"
    cvs -Q up 2>&-
    ret=${?}
    popd >&- 2>&-
    if [ 0 -ne ${ret} ] ; then
        echo -ne "\nCVS update failed\nDeleting partially updated directory"
        rm -fr "${dir}"
        echo ", done."
        return ${ret}
    fi

    echo ", done."

    return ${ret}
}

function mkt4sb ()
{
    if [ -d "${1}" ] ; then
        echo "Directory ${1} alreay exists!"
        return -1
    fi

    case "${1}" in
    /*) gett4repos "${1}" ;;
    *) gett4repos "${PWD}/${1}" ;;
    esac

    local -i ret=${?}
    if [ -d "${1}" ] ; then
        case "${1}" in
        /*) cht4 "${1}" ;;
        *) cht4 "${PWD}/${1}" ;;
        esac
        cdt4
        gvim
    fi
}

function t4DefaultPlatform ()
{
    t4RcOrDefault T4BUILDPLATFORM BP_X11
}

function t4CapabilityFile ()
{
    echo "capability.xml"
}

function t4HomeOfCapabilities ()
{
    echo "$(t4Home)/platform"
}

function t4ValidCapabilityList ()
{
    local cap
    local -a list=()
    for cap in $(/bin/ls -1 $(t4HomeOfCapabilities)/*/$(t4CapabilityFile) 2>&-) ; do
        cap=${cap%/$(t4CapabilityFile)}
        cap=${cap##*/}
        list=(${list[@]} ${cap})
    done
    echo ${list[@]}
}

function t4WhatPlatform ()
{
    local desc="${1}"
    [ -z "${desc}" ] && desc="currently "
    echo "T4BUILDPLATFORM ${desc}equals '${T4BUILDPLATFORM}'"
}

function t4ChPlatform ()
{
    local -r s_list="-l"
    local -r l_list="--list"
    local -r s_current="-c"
    local -r l_current="--current"
    local -r usage="usage: t4ChPlatform [${s_list}|${l_list}] [${s_current}|${l_current}] [<PLATFORM>]"

    while [ ${#} -gt 0 ] ; do
        case "${1}" in
            ${s_current}|${l_current})
            t4WhatPlatform
            return
        ;;
        ${s_list}|${l_list})
            t4ValidCapabilityList
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
        export T4BUILDPLATFORM="$(t4DefaultPlatform)"
        t4WhatPlatform "now "
    else
        if [ -f $(t4HomeOfCapabilities)/${1}/$(t4CapabilityFile) ] ; then
            export T4BUILDPLATFORM="${1}"
            t4WhatPlatform "now "
        else
            echo "Invalid platform ${1}" >&2
        fi
    fi
}

function t4CompletePlatform ()
{
#   echo '${COMP_CWORD} = '"'${COMP_CWORD}'" > /dev/pts/3
    if [ ${COMP_CWORD} -eq 1 ] ; then
        local word="${2}"
        local -i rep=0
        local -a reply
        local -a valid=($(t4ValidCapabilityList))
#       echo '${valid} = '"'${valid[@]}'" > /dev/pts/3
        if [ -n "${word}" ] ; then
            local cap=
            for cap in ${valid[@]} ; do
#               echo "Does cap='${cap}' =~ ${word}*?" > /dev/pts/3
                case "${cap}" in
                ${word}*)
#                   echo yes > /dev/pts/3
                    reply[${rep}]=${cap}
                    let rep=++rep
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

[ -z "${NO_COMPLETE}" ] && complete -F t4CompletePlatform t4ChPlatform

if [ -z "${T4_HOME}" ] ; then
    cht4 $(defaultT4)
else
    cht4 "${T4_HOME}"
fi

. ads.profile

function installOnRemovable ()
{
    local d=g
    local t=$(secondsSinceEpoch)

    if [ "${1}" = "--content" ] ; then
        local content="yes"
        shift
    fi

    if [ "${1}" ] ; then
        d="${1}"
    else
        echo "Assuming removable drive is $(_Pw /cygdrive/${d})"
    fi

    local drive=/cygdrive/${d}
    local touch=${drive}/craig
    touch ${touch}
    if [ ! -f ${touch} ]; then
        echo "No $(_Pw ${drive})"
        return 1
    fi
    rm ${touch}

    local dir=${drive}/Trigenix
    # echo -n "Deleting ${dir}"
    # rm -fr ${dir}
    # echo ", succeeded."

    if [ ! -d ${dir} ] ; then
        echo -n "Making directory ${dir}"
        mkdir -p ${dir}
        if [ ! -d ${dir} ] ; then
            echo ", failed."
            return 1
        fi
        echo ", succeeded."
    fi

    local exe=build/exe/player-$(t4DeducePmAllVariants).exe
    if [ -f ${exe} ] ; then
        local destExe=${dir}/${exe##*/}
        echo -n "Deleting ${destExe} first"
        rm -f ${destExe}
        echo ", succeeded."

        echo -n "Copying ${exe} to ${dir}"
        cp -p ${exe} ${dir}/
        if [ ! -f ${destExe} ] ; then
            echo ", failed."
            return 1
        fi
        echo ", succeeded."
    else
        echo "Couldn't find ${exe}"
    fi

    if [ -z "${content}" ] ; then
        echo "Skipping content"
    else
        local trigParent=${dir}/rootData
        if [ ! -d ${trigParent} ] ; then
            echo -n "Making directory ${trigParent}"
            mkdir -p ${trigParent}
            if [ ! -d ${trigParent} ] ; then
                echo ", failed."
                return 1
            fi
            echo ", succeeded."
        fi

        local trig=build/data/t4v1/test/trigs/1
        if [ -d ${trig} ] ; then
            local trigDest=${trigParent}/1

            if [ -d ${trigDest} ] ; then
                echo -n "Deleting ${trigDest} first"
                rm -fr ${trigDest}
                if [ -d ${trigDest} ] ; then
                    echo ", failed."
                    return 1
                fi
                echo ", succeeded."
            fi

            echo -n "Copying ${trig} to ${trigDest}"
            cp -pr ${trig} ${trigDest}
            if [ ! -d ${trigDest} ] ; then
                echo ", failed."
                return 1
            fi
            echo ", succeeded."
        else
            echo "Couldn't find ${trig}"
        fi
    fi
    echo "Everything took $(elapsed ${t})"
}

function t4MakeCab ()
{
#   set -x
    local -r start=$(secondsSinceEpoch)
    local -r trig_name=${1}
    local -r trig_id=${2}
    local inf_file=${3}
    local temp_dir=${4}
    if [ "${inf_file}" ] ; then
#       "We have a .inf file: '${inf_file}'"
        if [ -z "${temp_dir}" ] ; then
            case "${inf_file}" in
            */*)
#               "and it has a directory: '${inf_file%/*}', so we'll put the temp dir there"
                temp_dir=${inf_file%/*}
            ;;

            *)
#               "and it has NO directory, so we'll put the temp dir in '.'"
                temp_dir=.
            ;;

            esac
#           "We had a .inf file (but no temp dir) so we'll call the temp_dir after that: '${temp_dir}/${inf_file##*/}'"
            temp_dir=${temp_dir}/${inf_file##*/}
#           "And now we remove the .inf"
            temp_dir=${temp_dir%.*}
        fi
    else
#       "No .inf file"
        inf_file=${trig_name}.inf
        temp_dir=${trig_name}_temp
    fi
    export MYPLATFORM="$(uname -s)"
    date +%D\ %H:%M.%S
    (
        if [ "${MYPLATFORM}" = "CYGWIN_NT-5.0" ] ; then
                local -r trigs_home=build/data/t4v1
                local -r trig_dir=${trigs_home}/${trig_name}/trigs/${trig_id}
                if [ -d ${trig_dir} ] ; then
                    /cygdrive/c/Python23/python.exe tools/bin/makeCab.py --inffile ${inf_file} ${trig_dir} ${temp_dir}
                    local -r win_cmd=$(_Pu "C:\Windows CE Tools\wce300\Smartphone 2002\tools\CabwizSP.exe")
                    local -r win_inf_file=$(_Pw "${inf_file}")
                    local -r win_dest_dir=$(_Pma "${inf_file%/*}")
                    "${win_cmd}" "${win_inf_file}" /dest "${win_dest_dir}"
                else
                    echo "Cannot put a trig into a CAB if it doesn't exist" >&2
                    exit 1
                fi
        else
            echo "Can only build CAB files on Windows" >&2
            exit 1
        fi
    )
    declare -r -i ret=${?}
    date +%D\ %H:%M.%S
    echo "Building a CAB returned ${ret} (and took $(elapsed ${start}))"
    return ${ret}
}

function t4CompleteMakeCab ()
{
#   date +-----------------%n%D\ %H:%M.%S%n > /dev/tty0
#   echo '${COMP_CWORD} = '"'${COMP_CWORD}'" > /dev/tty0
    local word="${2}"
#   echo '${word} = '"'${word}'" > /dev//tty0
    local -a reply=()
    local -i replies=0
    local file
    local -r trigs_home=build/data/t4v1
    case ${COMP_CWORD} in
    1) # trig_name
        for file in ${trigs_home}/* ; do
            file=${file#${trigs_home}/}
#           echo '${file} = '"'${file}'" > /dev/tty0
            case ${file} in
            ${word}*)
                reply[${replies}]=${file}
                let replies=++replies
            ;;
            esac
        done
    ;;

    2) # trig_id
#       echo '${COMP_WORDS[1]} = '"'${COMP_WORDS[1]}'" > /dev/tty0
        local trigs_dir=${trigs_home}/${COMP_WORDS[1]}/trigs
        for file in ${trigs_dir}/* ; do
            file=${file#${trigs_dir}/}
#           echo '${file} = '"'${file}'" > /dev/tty0
            case ${file} in
            ${word}*)
                reply[${replies}]=${file}
                let replies=++replies
            ;;
            esac
        done
    ;;

    3) # .inf file
        local -i -r pre_replies=${replies}
        for file in "${word}*.inf" ; do
            if [ -f "${file}" ] ; then
                reply[${replies}]="${file}"
                let replies=++replies
            fi
        done
        for file in ${word}* ; do
            if [ -d "${file}" ] ; then
                reply[${replies}]="${file}/"
                let replies=++replies
            fi
        done
        if [ ${pre_replies} = ${replies} ] ; then
            reply=("${word}")
        fi
    ;;

    4) # temp_dir
        local -i -r pre_replies=${replies}
        for file in ${word}* ; do
            if [ -d "${file}" ] ; then
                reply[${replies}]="${file}/"
                let replies=++replies
            fi
        done
        if [ ${pre_replies} = ${replies} ] ; then
            reply=("${word}")
        fi
    ;;

    *)
    ;;
    esac
    COMPREPLY=(${reply[@]})
}

[ -z "${NO_COMPLETE}" ] && complete -o nospace -F t4CompleteMakeCab t4MakeCab

function t4FindVariety ()
{
    sed -ne 's@^[[:space:]]*<VARIETY[[:space:]]*name[[:space:]]*=[[:space:]]*"\('"${1}"'\)">[[:space:]]*$@\1@p' < "$(t4Home)/tonka-product.xml"
}

function t4MatchVariety ()
{
    local -r spec="${1}"
    shift
    t4FindVariety "${spec}"'[^"]*' "${@}"
}

function t4MatchVarietyArgs ()
{
    local var
    for var in $(t4MatchVariety "${@}") ; do
        echo -e -V ${var}
    done
}
