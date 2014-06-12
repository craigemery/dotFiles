#!/bin/bash

#. python.bash

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

        [[ ${lines} -ge ${rows} ]] && return 0 || return 1
    fi
}

function orphan ()
{
    ( "${@}" & ) > /dev/null < /dev/null 2> /dev/null
}

function orphan_eval ()
{
    orphan eval "${@}"
}

function start ()
{
    local cmd=$(_Pwas "${@}" 2>&-)
    if [[ -z "${cmd}" ]] ; then
        cmd="${@}"
    fi
    cmd /c 'start '"${cmd}"
}

function HgST ()
{
    __nt "Hg status" hgST
}

function Man ()
{
    __nt -/ "man $*" man "${@}"
}

function Ssh ()
{
    __nt -/ -p "ssh ${*}" ssh "${@}"
}

function Vim ()
{
    __nt vim vim "${@}"
}

function Xdu ()
{
    __nt -p xdu ${HOME}/dist/bin/xdiskusage
}

function Sudo ()
{
    __nt sudo sudo "${@}"
}

function Xenhg ()
{
    __nt xenhg sudo su - xenhg
}

function __term_type ()
{
    #assume local RESULT
    case "${TERM}" in
    xterm*) RESULT=xterm ;;
    screen*) if [[ "$TMUX" ]] ; then RESULT=tmux ; else RESULT=screen ; fi ;;
    rxvt*) RESULT=rxvt ;;
    *) RESULT="" ;;
    esac
}

function __nt () {
    local runner=""
    local pd="."
    local arg
    while [[ ${#} -gt 0 ]] ; do
        case "${1}" in
        -p) runner="${HOME}/dist/shell/pauseAfter" ;;
        -P) runner="${HOME}/dist/shell/pauseOnError" ;;
        -w) runner="watch" ;;
        -/) pd="/" ;;
        -*) ;;
        *) break ;;
        esac
        shift
    done
    local -x -r name="${1}"
    shift
    local -x -r command="${1}"
    shift
    pushd "${pd}" > /dev/null
    local RESULT
    __term_type
    case "${RESULT}" in
    xterm) ( xterm -title "${name}" -geometry 86x50 -e bash -c '${command} '"${*}"'' & <&- >&- ) ;;
    screen) screen -t "${name}" bash -ic ". ~/.dotFiles/bash/bootstrap.bash ; titles both '${name}' ; exec ${runner} ${command} ${*}" ;;
    rxvt) mrxvtTabDo ${runner} ${command} "${@}" ;;
    tmux)
        case "${command}" in
            vim) tmux split-window -h "${runner} ${command} -X ${*}" ;;
            hgST) tmux split-window -h "${runner} ${command} ${*}" ;;
            *) tmux new-window -n "${name}" "${runner} ${command} ${*}" ;;
        esac
    ;;
    *) ${command} "${@}" ;;
    esac
    unset RESULT
    popd > /dev/null
}

function __shared ()
{
    . shared.bash
}

alias 'hgrep=history | egrep --colour=auto -e'

# vim:sw=4:ts=4
