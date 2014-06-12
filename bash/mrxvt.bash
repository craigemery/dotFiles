#!/bin/bash

function _mrxvtCmd ()
{
   local -r fifo="/tmp/.mrxvt-${PPID}"
   if [[ -p "${fifo}" ]] ; then
      echo "${@}" >> "${fifo}"
   else
      echo "${fifo} not a pipe"
   fi
}

function mrxvtTab ()
{
   if [[ ${#} -gt 0 ]] ; then
      _mrxvtCmd "NewTab ${@}"
   else
      _mrxvtCmd "NewTab"
   fi
}

function mrxvtTabDo ()
{
    if [[ "${MRXVT_TABTITLE}" ]] ; then
        mrxvtTab "${@}"
    else
        "${@}"
    fi
}

unset newTab
unset newTabDo

function __mrxvt ()
{
    . mrxvt.bash
}
