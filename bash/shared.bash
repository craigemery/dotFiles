#!/bin/bash

. python.bash

function fileBiggerThanScreen ()
{
    local file="${1}"
    local rows
    local bigrows
    local columns
    local lines

    if [[ -f "${file}" ]] ; then
        local -r -i rows=$(tput lines)
        local -r -i columns=$(tput cols)
        local -r -i bigrows=$(( ${rows} + 1 ))
        local -r -i lines=$((0 + $(head -${bigrows} < "${file}" | fold -${columns} | wc -l) ))

        [[ ${lines} -gt ${rows} ]] && return 0 || return 1
    fi
}

function start ()
{
    local cmd=$(_Pwas "${@}" 2>&-)
    if [[ -z "${cmd}" ]] ; then
        cmd="${@}"
    fi
    cmd /c 'start '"${cmd}"
}

function Man ()
{
    __nt man man "${@}"
}

function Ssh ()
{
    __nt -p ssh ssh "${@}"
}

function Vim ()
{
    __nt vim vim "${@}"
}

function Xdu ()
{
    __nt -p xdu ${HOME}/dist/bin/xdiskusage
}

function __nt () {
    local pauseAfter=""
    local arg
    while [[ ${#} -gt 0 ]] ; do
        case "${1}" in
        -p) pauseAfter="${HOME}/dist/shell/pauseAfter" ;;
        -*) ;;
        *) break ;;
        esac
        shift
    done
    local -x -r name="${1}"
    shift
    local -x -r command="${1}"
    shift
    case "${TERM}" in
    xterm*) ( xterm -title "${name} ${*}" -geometry 86x50 -e bash -c '${command} '"${*}"'' & <&- >&- ) ;;
    screen*) screen bash -ic "titles both '${name} ${*}' ; exec ${pauseAfter} ${command} ${*}" ;;
    rxvt*) newTabDo ${pauseAfter} ${command} "${@}" ;;
    *) ${command} "${@}" ;;
    esac
}

function __shared ()
{
    . shared.bash
}

alias 'hgrep=history | egrep --colour=auto -e'

# vim:sw=4:ts=4
