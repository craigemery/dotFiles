#!/bin/bash

. mrxvt.bash

function xtrace ()
{
   local -i fake=0
   if [[ "${1}" = "=f" ]] ; then
      shift
      fake=1
   fi
   titles both "${@}"
   trace "${@}"
   local -r -i ret=${?}
   titles both "${@} - complete"
   if [[ ${fake} -eq 1 ]] ; then
      fake_xterm_title
   fi
   return ${ret}
}

function xtrace_eval ()
{
   local -i fake=0
   if [[ "${1}" = "=f" ]] ; then
      shift
      fake=1
   fi
   titles both "${@}"
   trace_eval "${@}"
   local -r -i ret=${?}
   titles both "${@} - complete"
   if [[ ${fake} -eq 1 ]] ; then
      fake_xterm_title
   fi
   return ${ret}
}

function colourNameToNumber ()
{
  case "${1}" in
  black)    echo 0 ;;
  red)      echo 1 ;;
  green)    echo 2 ;;
  yellow)   echo 3 ;;
  blue)     echo 4 ;;
  magenta)  echo 5 ;;
  cyan)     echo 6 ;;
  white)    echo 7 ;;
  reset)    echo 9 ;;
  *) ;;
  esac
}

function titles ()
{
  local -r esc=""
  local -r bell="\\a"
  case "${TERM}" in
  *rxvt|cygwin*|screen*|xterm*)
    local cmd="${1}"
    shift
    case "${cmd}" in
    both) echo -ne "${esc}]0;${*}${bell}" ;;
    icon) echo -ne "${esc}]1;${*}${bell}" ;;
    window) echo -ne "${esc}]2;${*}${bell}" ;;
    esac
  ;;
  esac
}

function termcap ()
{
  local output=""
  while [ ${#} -gt 0 ] ; do
    case ${1} in
    fg) local colourNum=$(colourNameToNumber ${2})
        if [[ "${colourNum}" ]] ; then
          output="${output}$(tput setaf ${colourNum})"
        else
          echo "Unknown colour name '${2}'" >&2
          output="" ; set 1 ; shift
        fi
        shift
        ;;
    bg) local colourNum=$(colourNameToNumber ${2})
        if [[ "${colourNum}" ]] ; then
          output="${output}$(tput setab ${colourNum})"
        else
          echo "Unknown colour name '${2}'" >&2
          output="" ; set 1 ; shift
        fi
        shift
        ;;
    reverse|standout|inverse) output="${output}$(tput smso)" ;;
    noreverse|nostandout|noinverse) output="${output}$(tput rmso)" ;;
    ul|underline) output="${output}$(tput smul)" ;;
    noul|nounderline) output="${output}$(tput rmul)" ;;
    blink) output="${output}$(tput blink)" ;;
    bold) output="${output}$(tput bold)" ;;
    reset) output="${output}$(tput sgr0)" ;;
    icon_window|titles)
        if [[ "${2}" ]] ; then
          output="${output}$(titles both ${2})"
        else
          echo "What would you have me set the window title AND icon name to?" >&2
          output="" ; set 1 ; shift
        fi
        shift
        ;;
    icon)
        if [[ "${2}" ]] ; then
          output="${output}$(titles icon ${2})"
        else
          echo "What would you have me set the icon name to?" >&2
          output="" ; set 1 ; shift
        fi
        shift
        ;;
    window)
        if [[ "${2}" ]] ; then
          output="${output}$(titles window ${2})"
        else
          echo "What would you have me set the window title to?" >&2
          output="" ; set 1 ; shift
        fi
        shift
        ;;
    *)  echo "What does '${1}' mean?" >&2
        output="" ; set 1 ; shift ;;
    esac
    shift
  done

  echo -ne "${output}"
}

function colour ()
{
  termcap ${*}
}

function ldf ()
{
	/bin/df ${*} $(mount | awk '/^\/dev\//{print $3}')
}

function tput_test ()
{
  local on=""
  local off=""
  local on_args=${1}
  local message=${2}
  local off_args=${3}

  echo -e "on \c"
  echo ${on_args} | tr \; \\012 |
    while read on args ; do
      tput ${on} ${args}
    done
  echo -e "${message}\c"
  echo ${off_args} | tr \; \\012 |
    while read off args ; do
      tput ${off} ${args}
    done
  echo " off"
}

function rxvtTitle ()
{
    export RXVT_TITLE="${@}"
    case "${TERM}" in
        *rxvt)
           PROMPT_COMMAND='echo -n "$(titles both '${RXVT_TITLE}')"'
        ;;
    esac
}

function xtermTitle ()
{
    export XTERM_TITLE="${@}"
    case $TERM in
        screen*|xterm*)
            if [ ! -e /etc/sysconfig/bash-prompt-xterm ]; then
                PROMPT_COMMAND='echo -n "$(titles both '${XTERM_TITLE}')"'
            fi
        ;;
    esac
}

function fake_xterm_title ()
{
    local wd="${PWD}"
    case "${wd}" in
    ${HOME}*) wd="~${wd#${HOME}}" ;;
    esac
    titles both "${USER}@${HOSTNAME%%.*}:${wd}"
}

if [[ ${BASH_VERSINFO[0]} -gt 3 ]] ; then
function set_display ()
{
    if [[ "${DISPLAY}" =~ (localhost):([0-9]+)\.([0-9]) ]] ; then
        export DISPLAY=${BASH_REMATCH[1]}:${1}.${BASH_REMATCH[3]}
    fi
}
fi

function __xterm ()
{
   . xterm.bash
}
