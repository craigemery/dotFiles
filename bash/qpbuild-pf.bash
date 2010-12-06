function toUpper ()
{
   echo "${@}" | tr '[a-z]' '[A-Z]'
}

function toolFromArch ()
{
   case "${1}" in
   X86) echo vc6 ;;
   THUMB) echo ads ;;
   esac
}

function dbgFromStyle ()
{
   case "${1}" in
   DBG) echo info ;;
   REL) echo silent ;;
   esac
}

function modFromArch ()
{
   case "${1}" in
   X86) echo dll ;;
   THUMB) echo mod ;;
   esac
}

function QPBPF ()
{
   local -r arch="${1}"
   local -r style="${2}"
   local -r port="${3}"

   local -r ARCH=$(toUpper ${arch})
   local -r tool=$(toolFromArch ${ARCH})
   local -r mod=$(modFromArch ${ARCH})
   local -r TOOL=$(toUpper ${tool})
   local -r STYLE=$(toUpper ${style})
   local -r dbg=$(dbgFromStyle ${STYLE})
   QPB -n -P PLAYERFRAMEWORK -b 5.2.x -V 312-${ARCH}-${TOOL}-${STYLE}-WDEV-PROTEST
   if [[ ${?} -eq 0 ]] ; then
      local -r tp=trigplayer/trigplayer.${mod}
      local -r d=devicefs
      local -r t=${d}/${tp}
      local -r w=widget_dev
      local -r src=playerframework/SHIP-${style}-${arch}-312-${tool}-${dbg}-${w}-pt/${t}
      cp -va ${src} playertest/SHIP-${tool}-${dbg}-312-dbg-${arch}-${w}/${t}
      cp -va ${src} player/SHIP-${style}-${arch}-312-${tool}-${dbg}-${w}/${t}
      cp -va ${src} trigbuilder/extensions-dbg/${tp}

      if [[ "${port}" ]] ; then
         py "$(_Pwa ~/dist/python/btilif.py)" ${port} upmod trigplayer ${PWD}/playertest/SHIP-${tool}-${dbg}-312-dbg-${arch}-${w}/${d} ${PWD%/*/*}/HEAD/supportutils/sig
      fi
   fi
}
