#!/bin/bash

function rpmWhich ()
{
  local list=""
  local colour=""
  local error=""
  local query=""

  while [[ "TRUE" ]] ; do
    case "${1}" in
    -l|--list		) list="1" ; shift ;;
    -L|--long-list	) list="l" ; shift ;;
    -c|--colour|--color	) colour="--color=yes" ; shift ;;
    -q|--query		) query=1 ; shift ;;
    -*			) error="Illegal argument: ${1}" ; shift ;;
    *			) break ;;
    esac
  done

  if [[ "${error}" ]] ; then
    echo "${error}"
  else
    local f=`which_file ${1}`

    if [[ "${f}" ]] ; then
      case "${func}" in
      ${BASH_FUNC_FILE}|${SHARED_BASH_FUNC_FILE})
      ;;
      *)
	local p=`rpm -qf ${f}`
	if [[ ! -z "${list}" ]] ; then
	  local temp=/tmp/rpmWhich.${$}
	  rpm -ql ${p} | xargs -n999 \ls "-AFd${list}" ${colour} > ${temp}
	  if fileBiggerThanScreen ${temp} ; then
	    less -R ${temp}
	  else
	    cat ${temp}
	  fi
	  rm -f ${temp}
	elif [[ "${query}" ]] ; then
	  rpm -qi ${p}
	else
	  echo ${p}
	fi
      ;;
      esac
    fi
  fi
}

function rpmgrep ()
{
  rpmfind --apropos ${1} | gawk '/ftp:\/\/.*'${1}'/{print $NF}'
}

function rpmfetch ()
{
  for rpm in `rpmgrep ${1}` ; do
    yesNo curl -O ${rpm}
  done
}
