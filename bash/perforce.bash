#!/bin/bash
# Various help functions for using Perforce fromthe command-line

function __wp4 ()
{
    local -a RESULT=()
    local -r cmd="${1}"
    shift
    _PwaAllArgs "${@}"
    PWD=$(_PwaPWD) "${cmd}" "${RESULT[@]}"
}

function wp4merge ()
{
    __wp4 p4merge "${@}"
}

function wp4 ()
{
    __wp4 p4 "${@}"
}

function __upper ()
{
   echo "${@}" | tr '[a-z]' '[A-Z]'
}

function p4Change ()
{
   local -r s_pendingUC="-P"
   local -r l_pendingUC="--PENDING"
   local -r s_pending="-p"
   local -r l_pending="--pending"
   local -r s_info="-i"
   local -r l_info="--info"
   local -r s_client="-C"
   local -r l_client="--client"
   local -r s_changes="-c"
   local -r l_changes="--changes"
   local -r s_diff="-d"
   local -r l_diff="--diff"
   local -r s_new="-n"
   local -r l_new="--new"
   local client=$(__upper "${USER}")
   local user=${USER}
   local -r usage="usage: p4Change [${s_pending}|${l_pending}|${s_pendingUC}|${l_pendingUC}] [${s_info}|${l_info}] [${s_changes}|${l_changes}] [${s_client}|${l_client}] [${s_diff}|${l_diff}] [${s_new}|${l_new}] [<change level>]"
   local -r pending=${l_pending}
   local -r pending_brief=${l_pendingUC}
   local -r info=${l_info}
   local -r changes=${l_changes}
   local -r diff=${l_diff}
   local -r new=${l_new}
   local cmd=""
   local change=""

   while [[ ${#} -gt 0 ]] ; do
      case "${1}" in
      ${s_pending}|${l_pending})
         cmd=${pending}
      ;;

      ${s_pendingUC}|${l_pendingUC})
         cmd=${pending_brief}
      ;;

      ${s_info}|${l_info})
         cmd=${info}
      ;;

      ${s_changes}|${l_changes})
         cmd=${changes}
      ;;

      ${s_diff}|${l_diff})
         cmd=${diff}
      ;;

      ${s_new}|${l_new})
         cmd=${new}
      ;;

      ${s_client}|${l_client})
         shift
         client="${1}"
      ;;

      ${l_client}=*)
         client="${1#${l_client}=}"
      ;;

     #${l_pre}=*)
     #   local pre="${1#${l_pre}=}"
     #;;
     #${s_pre})
     #   if [[ ${#} -gt 1 ]] ; then
     #      shift
     #      local pre="${1}"
     #   else
     #      echo "Invalid argument '${1}'"
     #      echo -e "${usage}"
     #      return 0
     #   fi
     #;;

      -?|--help)
         echo -e "${usage}"
         return 0
      ;;

      --) break ;;

      -*)
         echo "Invalid argument '${1}'"
         echo -e "${usage}"
         return 0
      ;;

      *) break ;;
      esac

      shift
   done

   case ${cmd} in
   ${info}|${changes}|${diff})
      if [[ ${#} -gt 0 ]] ; then
         change="${1}"
         shift
      else
         echo "${cmd} argument requires a change level"
         return -1
      fi
   ;;
   esac

   case ${cmd} in
   ${pending})
      p4 changes -c "${client}" -u "${user}" -s pending
   ;;

   ${pending_brief})
      p4 changes -c "${client}" -u "${user}" -s pending | sed -n -e 's@^Change \([0-9][0-9]*\)[^0-9].*@\1@p'
   ;;

   ${info})
      p4 change -o ${change}
   ;;

   ${changes})
      p4 change -o ${change} | sed -n -e 's@^[ 	]*\(//.*[^ 	]\)[ 	][ 	]*# edit[ 	]*$@\1@p' -e 's@^[ 	]*\(//.*[^ 	]\)[ 	][ 	]*# integrate[ 	]*$@\1@p'
   ;;

   ${diff})
      local spec=""
      local line=""
      local -a to_diff=()
      set -- $(p4 fstat $(p4 change -o ${change} | sed -n -e 's@^[ 	]*\(//.*[^ 	]\)[ 	][ 	]*# edit[ 	]*$@\1@p' -e 's@^[ 	]*\(//.*[^ 	]\)[ 	][ 	]*# integrate[ 	]*$@\1@p') | sed -n -e 's@^\.\.\.[ 	]*depotFile[ 	]*@@p' -e 's@^\.\.\.[ 	]*headType[ 	]*@@p')
      while [[ ${#} -gt 0 ]] ; do
         if [[ "${1}" = "text" ]] ; then
            to_diff=(${to_diff[@]} ${spec})
         else
            spec="${1}"
         fi
         shift
      done
      p4 diff ${to_diff[@]}
   ;;

   ${new})
      local -i -r pid=${$}
      local -r tmp1=/tmp/p4.new.1.${pid}
      local -r tmp2=/tmp/p4.new.2.${pid}
      p4 change -o | tee "${tmp1}" > "${tmp2}"
      if [[ "${EDITOR}" ]] ; then
         "${EDITOR}" "${tmp1}"
      else
         vi "${tmp1}"
      fi
      if [[ "${tmp1}" -nt "${tmp2}" ]] ; then
         p4 change -i < "${tmp1}"
      else
         echo "No changes made"
      fi
      rm -f "${tmp1}" "${tmp2}"
   ;;
   esac
}

function __p4Change ()
{
    if [[ -z "${__p4Change_dbg}" ]] ; then
        local -r __p4Change_dbg=null
    fi

    local -r s_pendingUC="-P"
    local -r l_pendingUC="--PENDING"
    local -r s_pending="-p"
    local -r l_pending="--pending"
    local -r s_info="-i"
    local -r l_info="--info"
    local -r s_changes="-c"
    local -r l_changes="--changes"
    local -r s_diff="-d"
    local -r l_diff="--diff"
    local -r s_new="-n"
    local -r l_new="--new"

    local -r command="${1}"
    local -r current_word="${2}"
    local -r previous_word="${3}"
    # something following a -V
    case "${previous_word}" in
    ${s_info}|${l_info}|${s_changes}|${l_changes}|${s_diff}|${l_diff})
        local -a valid=($(p4Change ${l_pendingUC}))
        COMPREPLY=()
        local ch
        for ch in ${valid[@]} ; do
            echo "Does ch='${ch}' =~ ${current_word}*?" > /dev/${__p4Change_dbg}
            case "${ch}" in
            ${current_word}*)
                echo yes > /dev/${__p4Change_dbg}
                COMPREPLY=(${COMPREPLY[@]} ${ch})
            ;;
            esac
        done
    ;;

    *)
        COMPREPLY=("${s_pendingUC}" "${l_pendingUC}" "${s_pending}" "${l_pending}" "${s_info}" "${l_info}" "${s_changes}" "${l_changes}" "${s_diff}" "${l_diff}" "${s_new}" "${l_new}")
        if [[ "${current_word}" ]] ; then
            local -a valid=${COMPREPLY[@]}
            COMPREPLY=()
            local x
            for x in ${valid[@]} ; do
                echo "Does x='${x}' =~ ${current_word}*?" > /dev/${__p4Change_dbg}
                case "${x}" in
                ${current_word}*)
                    echo yes > /dev/${__p4Change_dbg}
                    COMPREPLY=(${COMPREPLY[@]} ${x})
                ;;
                esac
            done
        fi
    ;;

    esac
}

if [[ -z "${NO_COMPLETE}" ]] ; then
    complete -F __p4Change p4Change
fi

function p4NewClient()
{
    local -r name="${1}"
    shift
    if [[ ${#} -eq 0 ]] ; then
        set -- cbgperforce01.eu.qualcomm.com:1667 qctcbgp4p01.eu.qualcomm.com:1667
    fi
    py -c 'from p4 import *
import os
import sys
name=sys.argv[1]
print "Client name", name
for port in sys.argv[2:]:
    try:
        p=P4()
        p.parse_forms()
        p.port=port
        p.connect()
        print "Connected to perforce host", p.port
        cl=p.fetch_client(name)
        cl["Root"]=os.getcwd()
        cl["View"]=[]
        cl["Options"]=cl["Options"].replace("normdir", "rmdir")
        print "Creating\n\t"+"\n\t".join(["%s: %s" % (k, v) for (k, v) in cl.items()])
        print "\n".join(p.save_client(cl))
        p.disconnect()
        p = None
    except:
        from traceback import print_exc
        print_exc()' "${name}" "${@}"
}

function p4DeleteClient()
{
    while true ; do
        echo "Inspecting arg ${1}"
        case "${1}" in
        -f|--force) local -r force="f" ;;
        -*) echo "Unknown arg ${1}" ; return 1 ;;
        *) break ;;
        esac
        shift
    done
    local -r name="${1}"
    shift
    if [[ ${#} -eq 0 ]] ; then
        set -- cbgperforce01.eu.qualcomm.com:1667 qctcbgp4p01.eu.qualcomm.com:1667
    fi
    py -c 'from p4 import *
import os
import sys
name=sys.argv[1]
print "Client name", name
for port in sys.argv[2:]:
    try:
        p=P4()
        p.parse_forms()
        p.port=port
        p.connect()
        print "Connected to perforce host", p.port
        cl=p.fetch_client(name)
        print "Deleting\n\t"+"\n\t".join(["%s: %s" % (k, v) for (k, v) in cl.items()])
        print "\n".join(p.run_client("-d'${force}'", name))
        p.disconnect()
        p = None
    except:
        from traceback import print_exc
        print_exc()' "${name}" "${@}"
}

function p4Client()
{
    local -r name="${1}"
    shift
    if [[ ${#} -eq 0 ]] ; then
        set -- cbgperforce01.eu.qualcomm.com:1667 qctcbgp4p01.eu.qualcomm.com:1667
    fi
    py -c 'from p4 import *
import os
import sys
name=sys.argv[1]
print "Client name", name
for port in sys.argv[2:]:
    try:
        p=P4()
        p.parse_forms()
        p.port=port
        p.connect()
        print "Connected to perforce host", p.port
        cl=p.fetch_client(name)
        print "\t"+"\n\t".join(["%s: %s" % (k, v) for (k, v) in cl.items()])
        p.disconnect()
        p = None
    except:
        from traceback import print_exc
        print_exc()' "${name}" "${@}"
}

function p4Login()
{
    local -r name="${1}"
    shift
    if [[ ${#} -eq 0 ]] ; then
        set -- cbgperforce01.eu.qualcomm.com:1667 qctcbgp4p01.eu.qualcomm.com:1667
    fi
    py -c 'from p4 import *
from getpass import getpass
import os
import sys
sys.path.append(os.path.join(os.environ["QP_TOOLS_1"], "lib", "pythonbuild"))
import password
name=sys.argv[1]
for port in sys.argv[1:]:
    try:
        p=P4()
        p.parse_forms()
        p.port=port
        p.connect()
        pw = password.get_password(p.port, "login")
        if pw:
            p.login(str(pw))
        p.disconnect()
        p = None
    except:
        from traceback import print_exc
        print_exc()' "${@}"
}

function p4Opened()
{
    py -c 'from p4 import *
import os
print "Opened"
try:
    p=P4()
    p.parse_forms()
    p.connect()
    print "Connected to perforce host"
    l=3+len(p.client)
    print "\n".join([o["clientFile"][l:] for o in p.run_opened()])
    p.disconnect()
    p = None
except:
    from traceback import print_exc
    print_exc()' "${@}"
}

function p4Integ ()
{
    local -r src="${1}"
    shift
    local -r dest="${1}"
    shift
    local -r client="${1}"
    shift
    local -r cl="${1}"
    shift
    local -x PWD=$(_PwaPWD)
    local prod
    local p
    for p in "${@}" ; do
        prod="//trigenix/comps/${p}"
        trace p4 -c "${client}" integ -dir "${prod}/${src}/...@${cl},${cl}" "${prod}/${dest}/..."
        trace p4 -c "${client}" resolve -am "${prod}/${dest}/..."
    done
}

function p4Get ()
{
    py -c 'import sys, os.path, re, stat
from p4 import P4
p4=P4()
p4.parse_forms()
p4.connect()
r=re.compile("^(.*)(\.[^\.]+)(#.*)$")
for path in sys.argv[1:]:
    fname=os.path.basename(path)
    m=r.search(fname)
    if m:
        (b, s, r) = m.groups()
        fname = b + r + s
    if os.path.exists(fname):
        print "File \"%s\" already exists, not fetching \"%s\"" % (fname, path)
    else:
        print "Fetching \"%s\" as \"%s\"" % (path, fname)
        print p4.run_print("-o", fname, path)
        os.chmod(fname, stat.S_IWRITE)
    p4.disconnect()' "${@}"
}

function _perforce ()
{
    . perforce.bash
}

# vim:sw=4
