#!/usr/bin/env bash

function mac_app ()
{
    RESULT="/Applications/${1}.app/Contents/MacOS"
}

function mac_app_exists
{
    local -i ret=1
    mac_app "${@}"
    if [[ -e "${RESULT}" ]] ; then
        ret=0
    fi
    return ${ret}
}

function ___mac_app_bin_name ()
{
    local -r bn=$(awk 'BEGIN{ns=0};
                  /CFBundleExecutable/{ns=1};
                  /<string>.*<\/string>/{if(ns==1){gsub("[[:space:]]*</?string>","");print $0;ns=0;}}' < "${RESULT%/*}/Info.plist")
    bin_name="${RESULT}/${bn}"
}

function mac_app_bin ()
{
    mac_app "${1}"
    local bin_name
    ___mac_app_bin_name
    RESULT="${bin_name}"
}

function __versioned_mac_app ()
{
    local -r app_name="${1}"
    shift
    local version=""
    local -x RESULT
    while [[ ${#} -gt 0 ]] ; do
        local arg="${1}"
        case "${arg}" in
        -v)
            shift # consume '-v'
            local v="${1}"
            shift # consume version
            if mac_app_exists "${app_name}${v}" ; then
                version=${v}
            fi
        ;;

        --version=*)
            shift # consume '--version=*'
            local v="${arg#--version=}"
            shift # consume version
            if mac_app_exists "${app_name}${v}" ; then
                version=${v}
            fi
        ;;

        --) shift ; break ;;

        *) break ;;
        esac
    done
    mac_app "${app_name}${version}"
    local -x bin_name
    ___mac_app_bin_name
    local -x pid_file=$(mktemp /tmp/vma.$$.XXXX)
    ( "${bin_name}" "${@}" <&- >&- 2>&- &
      echo $! > ${pid_file} )
    local -i MAC_PID=-1
    if [[ -f "${pid_file}" ]] ; then
        MAC_PID=$(cat "${pid_file}")
        rm -f "${pid_file}"
    fi
}

function __pidof ()
{
    #asume local -i RESULT
    RESULT=-1
    [[ "${1}" ]] && local -r app_name="${1}" || return
    local -r -a pids=( $(killall -sm "${app_name}"'$' 2>&- | sed -ne 's@^kill -TERM \([[:digit:]]\{1,\}\)$@\1@p') )
    case ${#pids[@]} in
    0) RESULT=-1 ;;
    1) RESULT=${pids[0]} ;;
    *) RESULT=-2 ;;
    esac
    [[ ${RESULT} -ge 0 ]] && return 0 || return -1
}

function pidof ()
{
    local -i RESULT
    __pidof "${1}" && echo ${RESULT}
}

function while_app_exists ()
{
    if [[ "${1}" ]] ; then
        local -r app_name="${1}"
        shift
        [[ "${1}" ]] && local -r -i period=${1} || local -r -i period=1
    fi
    local -i RESULT
    while __pidof "${app_name}" ; do
        sleep ${period}
    done
}

function __app_versions ()
{
    local -r app="${1}"
    #assume local RESULT=()
    RESULT=()
    local ver
    local max=""
    local -r head="/Applications/${app}"
    local -r tail=".app/Contents/MacOS"
    for ver in ${head}*${tail} ; do
        ver=${ver#${head}}
        ver=${ver%${tail}}
        RESULT[${#RESULT[@]}]="${ver}"
    done
}

function __max_app_version ()
{
    __app_versions "${1}"
    arrayMax "${RESULT[@]}"
}

function vlc ()
{
    if [[ ${#} -gt 1 && "${1}" == "-v" ]] ; then
        local -a -r ver=("${1}" "${2}")
        shift
        shift
    else
        local RESULT
        __max_app_version VLC
        local -a -r ver=(-v "${RESULT}")
    fi
    __versioned_mac_app VLC "${ver[@]}" "${@}"
}

function __make_vlc_aliases ()
{
    local RESULT=()
    __app_versions VLC
    local ver=""
    for ver in "${RESULT[@]}" ; do
        [[ "${ver}" ]] && eval "alias 'vlc_"${ver}"=vlc -v "${ver}"'"
    done
}
__make_vlc_aliases

function tb3 ()
{
    __versioned_mac_app Thunderbird -v 3.0 "${@}"
}

alias tb=tb3

function gmail ()
{
    tb3 -no-remote -profile ~/Library/Thunderbird/Profiles/Personal
}

function __chmod ()
{
    local file
    for file in "${@}" ; do
        if [[ -f "${file}" && ! -O "${file}" ]] ; then
            trace sudo chown "${USER}" "${file}"
        fi
    done
    chmod "${@}"
}

function notunes ()
{
    local RESULT
    mac_app_bin iTunes
    if [[ -f "${RESULT}" ]] ; then
        [[ "${1}" ]] && local -r desire="${1}" || local -r desire=toggle

        case ${desire} in
        off)
            [[ ! -x "${RESULT}" ]] && return
            echo "Disabling iTunes" >&2
            __chmod -x "${RESULT}"
        ;;
        on)
            [[ -x "${RESULT}" ]] && return
            echo "Re-enabling iTunes" >&2
            __chmod +x "${RESULT}"
        ;;
        toggle)
            if [[ -x "${RESULT}" ]] ; then
                echo "Disabling iTunes" >&2
                __chmod -x "${RESULT}"
            else
                echo "Re-enabling iTunes" >&2
                __chmod +x "${RESULT}"
            fi
        ;;
        *) echo "Invalid desire '${desire}'" >&2 ; return -1 ;;
        esac
    fi
}

function iTunes ()
{
    local RESULT
    mac_app_bin iTunes
    if [[ -f "${RESULT}" && -x "${RESULT}" ]] ; then
        ( "${RESULT}" & ) 0> /dev/null 1> /dev/null 2> /dev/null
    fi
}

function find ()
{
    if [[ ! -d "${1}" ]] ; then
        set -- . "${@}"
    fi
    /usr/bin/find "${@}"
}

if [[ "${PS1}" && "${TERM}" != "dumb" ]] ; then
    export PS1="\\[\\e]0;\\u@\\h:\\w\\a$(termcap fg blue)\\]\\t\[$(termcap reset)\] \\$ "
fi

. firefox.bash

function __macos ()
{
   . macos.bash
}

# vim:sw=4:ts=4
