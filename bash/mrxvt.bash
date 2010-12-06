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

function newTab ()
{
   if [[ ${#} -gt 0 ]] ; then
      _mrxvtCmd "NewTab ${@}"
   else
      _mrxvtCmd "NewTab"
   fi
}

function newTabDo ()
{
    if [[ "${MRXVT_TABTITLE}" ]] ; then
        newTab "${@}"
    else
        "${@}"
    fi
}

