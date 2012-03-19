#!/usr/bin/bash

function lintdiff ()
{
   local -r prod="${1}"
   shift
   if [[ -z "${1}" ]] ; then
      local -r branch="HEAD"
      local -r branch_part2=""
      local -r buildmachine="cbgvmbld11"
      local -r abdir="ab/cbgvmbld11_PLAYERTEST_main"
   fi
   local f
   for f in ${prod}/build/lint/*/summary.csv ; do
      true
   done
   if [[ ! -f "${f}" ]] ; then
      echo "No summary file found"
      return
   fi
   local -r mine="${f}"
   echo "My summary file = ${mine}"
   f=""
   for f in //${buildmachine}/E/${abdir}/${branch}/*/${branch_part2}${prod}/build/lint/*/summary.csv ; do
      true
   done
   if [[ ! -f "${f}" ]] ; then
      echo "No summary file found"
      return
   fi
   local -r autobuild="${f}"
   echo "Autobuild machine summary file = ${mine}"
   vimdiff -R -c 'se swapfile!' "${mine}" "${autobuild}"
}

function _mvrm1 ()
{
    # assume local -a RESULT
    if [[ "${1}" = "-d" ]] ; then
        shift
        local -r action=diag
    elif [[ "${1}" = "-s" ]] ; then
        shift
        local -r action=""
    else
        local -r action=trace
    fi
    local -a moved_files=()
    local moved=""
    local -a args=()
    local -r temp_dir=$(mktemp -d)
    local arg=""
    local dir_flag=""
    local parent=""
    for arg in "${@}" ; do
        if [[ -e "${arg}" ]] ; then
            if [[ -d "${arg}" ]] ; then
                dir_flag="-d"
            else
                dir_flag=""
            fi
            parent="${arg%/*}"
            moved=$(mktemp ${dir_flag} -p "${parent}" mvrm.XXXXXXXXXX)
            rm -fr "${moved}"
            ${action} mv "${arg}" "${moved}"
            moved_files=( "${moved_files[@]}" "${moved}" )
        else
            args=( "${args[@]}" "${arg}" )
        fi
    done
    RESULT=("${args[@]}" "${moved_files[@]}")
}

function _mvrm2 ()
{
   # assume local -a RESULT
   if [[ ${#RESULT[@]} -gt 0 ]] ; then
      titles both "rm -fr ${RESULT[@]}" >&2
      trace rm -fr "${RESULT[@]}"
   fi
}

function _mvrm ()
{
   local -a RESULT
   _mvrm1 "${@}"
   _mvrm2
}

function _prewash ()
{
   # assume local -a RESULT
   if [[ "${1}" = "-s" ]] ; then
      shift
      local -r silent="-s"
   else
      local -r silent=""
   fi
   local prod
   local d
   local -a list=()
   local -i dcount=0
   for prod in "${@}" ; do
      if test -d "${prod}" ; then
         for d in "${prod}"/build "${prod}"/SHIP-* ; do
            if test -d "${d}" ; then
               list=("${list[@]}" "${d}")
            fi
         done
      fi
   done
   if test 0 -lt ${#list[@]} ; then
      _mvrm1 "${silent}" -fr "${list[@]}"
   fi
}

function _rince ()
{
   # assume _mvrm1 has been called
   _mvrm2
}

function _wash ()
{
   _prewash "${@}"
   _rince
}

function wash ()
{
   local -a RESULT
   _wash "${@}"
}

function _addHEAD ()
{
   # assume local -a RESULT
   local d
   local -r head=~tb/HEAD
   for d in "${@}" ; do
      if [[ ${#RESULT[@]} -eq 0 ]] ; then
         RESULT=(${head}/${d})
      else
         RESULT=("${RESULT[@]}" ${head}/${d})
      fi
   done
}

function _washHEAD ()
{
   local -a RESULT=()
   _addHEAD "${@}"
   local -r -a r=("${RESULT[@]}")
   RESULT=()
   _wash "${r[@]}"
}

function _prewashHEAD ()
{
   # assume local -a RESULT=()
   _addHEAD "${@}"
   local -r -a r=("${RESULT[@]}")
   RESULT=()
   _prewash "${r[@]}"
}

function val_from_kv_pairs ()
{
   if [[ ${#} -lt 2 ]] ; then
      echo "${0} needs a key and a list of key/value pairs" >&2
      return -1
   fi
   local -r k="${1}"
   shift
   local kv
   for kv in "${@}" ; do
      case "${kv}" in
      ${k}=*) RESULT="${kv#${k}=}" ; return 0 ;;
      esac
   done
   return -1
}

function _var_default ()
{
   # assume local RESULT=""
   local -r variant="${1}"
   local -r if_no_default="${2}"
   if [[ ${#variants[@]} -gt 0 ]] ; then
      if val_from_kv_pairs "${variant}" "${variants[@]}" ; then
         return 0
      fi
   fi
   echo "${if_no_default}"
   return 0
}

function variant_default ()
{
   local RESULT=""
   case "${1}" in
   btilstyle) _var_default "${1}" "rel" ;;
   doc) _var_default "${1}" "nodoc" ;;
   py) _var_default "${1}" "2.3" ;;
   qa) _var_default "${1}" "noqa" ;;
   style) _var_default "${1}" "dbg" ;;
   targetos) _var_default "${1}" "win32" ;;
   esac
   echo "${RESULT}"
}

function expand_variants ()
{
    local var
    local val
    local ret=""
    for var in "${@}" ; do
        val=$(variant_default "${var}")
        if [[ "${ret}" ]] ; then
            ret="${ret}-${val}"
        else
            ret="${val}"
        fi
    done
    echo "${ret}"
}

function _vars ()
{
   local -a ret=()
   local var
   local val
   local v
   for var in "${@}" ; do
      case "${var}" in
      *=*)
         if [[ ${#ret[@]} -eq 0 ]] ; then
            ret=(-v "${var}")
         else
            ret=("${ret[@]}" -v "${var}")
         fi ;;
      *)
         v=$(variant_default ${var})
         if [[ ${#ret[@]} -eq 0 ]] ; then
            ret=(-v "${var}=${v}")
         else
            ret=("${ret[@]}" -v "${var}=${v}")
         fi ;;
      esac
   done
   echo "${ret[@]}"
}

function _pmHEAD ()
{
   local -r prod="${1}"
   shift
   trace pm -C${BASH_T5_SRC_HOME}/${prod} -V "${@}" all distrib
}

function pm_wxpythonutils ()
{
   _pmHEAD wxpythonutils
}

function pm_trigcompilation ()
{
   _pmHEAD trigcompilation
}

function pm_pythonutils ()
{
   _pmHEAD pythonutils $(_vars targetos)
}

function pm_parcelforce ()
{
   _pmHEAD parcelforce $(_vars py doc)
}

function pm_AC ()
{
   trace pm -C${BASH_T5_SRC_HOME}/trigbuilder -V $(_vars btilstyle doc py qa style targetos) all "${@}"
}

function pm_AC_and_subs ()
{
   pm_wxpythonutils && pm_trigcompilation && pm_pythonutils && pm_parcelforce && pm_AC
}

function wash_AC ()
{
   _washHEAD trigbuilder
}

function wash_AC_and_subs ()
{
   _washHEAD wxpythonutils trigcompilation pythonutils trigbuilder
}

function AC ()
{
   local -x CleanDevices=""
   local Wash=""
   local Build=""
   local -x Test="run"
   local -x Debug=""
   local -x Debugger=""
   local -r me="${0}"
   local arg
   local -a args=()
   local variant=""
   local -x -a variants=()
   local -x Cover=""
   while [[ ${#} -gt 0 ]] ; do
      arg="${1}"
      shift
      case "${arg}" in
      -w)
         if [[ -z "${Wash}" ]] ; then
            Wash="me"
         else
            echo "Cannot specify more than one 'Wash'" >&2
            return -1
         fi ;;
      -W)
         if [[ -z "${Wash}" ]] ; then
            Wash="all"
         else
            echo "Cannot specify more than one 'Wash'" >&2
            return -1
         fi ;;
      -b)
         if [[ -z "${Build}" ]] ; then
            if [[ "${Wash}" = "all" ]] ; then
               Build="all"
            else
               Build="me"
            fi
         else
            echo "Cannot specify more than one 'build'" >&2
            return -1
         fi ;;
      -B)
         if [[ -z "${Build}" ]] ; then
            Build="all"
         else
            echo "Cannot specify more than one 'build'" >&2
            return -1
         fi ;;
      -t) Test="test" ;;
      -c) Cover="-cover" ;;
      -d=*) Debug="${arg/-d=}" ;;
      -d) Debug="3glab" ;;
      -D) Debugger="y" ;;
      -C|--clean-devices) CleanDevices="y" ;;
      --help|-h|-\?) echo "usage: ${me} [-v <variant=value>] [-w|-W] [-b|-B] [-t] [-d|-d=<password>] [-D] [--help|-h|-?] [<arguments>]" ; return 0 ;;
      -v)
         if [[ ${#} -gt 0 ]] ; then # this arg needs an payload
             variant="${1}"
             shift
             variants=("${variants}" "${variant}")
         else
             echo "-v needs an argument" >&2
             return -1
         fi ;;
      -*) echo "${arg}: unknown argument" >&2 ; return -1 ;;
      *)
         if [[ -f "${arg}" ]] ; then
            arg=$(_Pwa "${arg}")
         fi
         args=("${args[@]}" "${arg}") ;;
      esac
   done
   set -- "${args[@]}"
   if [[ "${Wash}" = "all" ]] ; then
      wash_AC_and_subs
      Build="all"
   elif [[ "${Wash}" = "me" ]] ; then
      wash_AC
      Build="me"
   fi
   if [[ "${Debugger}" ]] ; then
      local -r -x runner="winpdb"
   else
      local -r -x runner="py"
   fi
   [[ ${?} -eq 0 ]] || return ${?}
   if [[ "${Build}" = "all" ]] ; then
      pm_AC_and_subs
   elif [[ "${Build}" = "me" ]] ; then
      pm_AC
   fi
   local -r myallvariants=$(expand_variants py style)
   [[ ${?} -eq 0 ]] || return ${?}
   if [[ -d ${BASH_T5_SRC_HOME}/trigbuilder ]] ; then
      (
         cd ${BASH_T5_SRC_HOME}/trigbuilder;
         if [[ "${CleanDevices}" && -d "devices" ]] ; then
            trace rm -fr devices
         fi
         if [[ "${Debug}" ]] ; then
            msg Setting AppCreator debug password to ${Debug}
            export AC_DBG_PASSWD="${Debug}"
         fi
         #trace ${runner} runtb-dbg.py "--swf=$(_Pwa ~/Desktop/me.swf)" "${@}"
         trace ${runner} ${Test}tb${Cover}-${myallvariants}.py "${@}"
      )
   fi
}

function pm_TC ()
{
   _pmHEAD tc $(_vars style)
}

function pm_TC_and_subs ()
{
   pm_parcelforce && pm_trigcompilation && pm_pythonutils && pm_TC
}

function wash_TC ()
{
   _washHEAD tc
}

function wash_TC_and_subs ()
{
   _washHEAD parcelforce trigcompilation pythonutils tc
}

function run_TC ()
{
   #set -x
   local -r style=$(variant_default style)
   local zip_in=${BASH_T5_SRC_HOME}/tc/SHIP-${style}
   local -x -a args=("${@}")
   (
      pushd "${zip_in}"
      run_dir=.run.${$}
      trace rm -fr ${zip_in}/${run_dir}
      mkdir ${run_dir}
      pushd ${run_dir}
      unzip ..\\tc.zip
      popd
      popd
      ${zip_in}/${run_dir}/tc/tc.exe "${args[@]}"
      trace rm -fr ${zip_in}/${run_dir}
   )
   #set +x
}

function test_TC ()
{
   #set -x
   local -r style=$(variant_default style)
   local zip_in=${BASH_T5_SRC_HOME}/tc/SHIP-${style}
   local -x -a args=("${@}")
   (
      pushd "${zip_in}"
      run_dir=.run.${$}
      trace rm -fr ${zip_in}/${run_dir}
      mkdir ${run_dir}
      pushd ${run_dir}
      unzip ..\\tc.zip
      popd
      popd
      ${zip_in}/${run_dir}/tc/tc.exe "${args[@]}"
      trace rm -fr ${zip_in}/${run_dir}
   )
   #set +x
}

function TC ()
{
   local -r me="${0}"
   local Wash=""
   local Build=""
   local -x Test=""
   local -x Run=""
   local -x Debug=""
   local arg
   local -a args=()
   while [[ ${#} -gt 0 ]] ; do
      arg="${1}"
      case "${arg}" in
      -w)
         if [[ -z "${Wash}" ]] ; then
            Wash="me"
         else
            echo "Cannot specify more than one 'Wash'" >&2
            return -1
         fi ;;
      -W)
         if [[ -z "${Wash}" ]] ; then
            Wash="all"
         else
            echo "Cannot specify more than one 'Wash'" >&2
            return -1
         fi ;;
      -b)
         if [[ -z "${Build}" ]] ; then
            if [[ "${Wash}" = "all" ]] ; then
               Build="all"
            else
               Build="me"
            fi
         else
            echo "Cannot specify more than one 'build'" >&2
            return -1
         fi ;;
      -B)
         if [[ -z "${Build}" ]] ; then
            Build="all"
         else
            echo "Cannot specify more than one 'build'" >&2
            return -1
         fi ;;
      -t) Test="y" ;;
      -r) Run="y" ;;
      -d=*) Debug="${arg/-d=}" ;;
      -d) Debug="3glab" ;;
      --help|-h|-\?) echo "usage: ${me} [-w|-W] [-b|-B] [-t] [-d|-d=<password>] [--help|-h|-?] [<arguments>]" ; return 0 ;;
      -*) echo "${arg}: unknown argument" >&2 ; return -1 ;;
      *)
         if [[ -f "${arg}" ]] ; then
            arg=$(_Pwa "${arg}")
         fi
         args=("${args[@]}" "${arg}") ;;
      esac
      shift
   done
   set -- "${args[@]}"
   if [[ "${Wash}" = "all" ]] ; then
      wash_TC_and_subs
      Build="all"
   elif [[ "${Wash}" = "me" ]] ; then
      wash_TC
      Build="me"
   fi
   [[ ${?} -eq 0 ]] || return ${?}
   if [[ "${Build}" = "all" ]] ; then
      pm_TC_and_subs
   elif [[ "${Build}" = "me" ]] ; then
      pm_TC
   fi
   [[ ${?} -eq 0 ]] || return ${?}
   if [[ -d ${BASH_T5_SRC_HOME}/tc ]] ; then
      (
         cd ${BASH_T5_SRC_HOME}/tc;
         if [[ "${Debug}" ]] ; then
            msg Setting TC debug password to ${Debug}
            export TC_DBG_PASSWD="${Debug}"
         fi
         if [[ "${Test}" = "y" ]] ; then
              trace test_TC "${@}"
         elif [[ "${Run}" = "y" ]] ; then
              trace run_TC "${@}"
         fi
      )
   fi
}

function __barona ()
{
   . barona.bash
}
