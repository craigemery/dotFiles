#!/usr/bin/bash

function __ps ()
{
   local -r p=$(_Pm -p "${PATH}:/cygdrive/c/PSTOOLS_2_16_0")
   export PYTHONPATH=${trigsrchome}/protestserver/build/pyzip/${psdoc}-${style}/protest.zip\;${trigsrchome}/parcelforce/SHIP-2.3/trigparcel.zip\;${trigsrchome}/xmltuple/SHIP-all/pyxmltuple.zip\;${trigsrchome}/xmltuple/SHIP-all\;${trigsrchome}/trigcompilation/SHIP-all/trigcorecomp.zip\;${trigsrchome}/trigcompilation/SHIP-all/tcompilation.zip\;${trigsrchome}/pythonutils/SHIP-all/pythonutils.zip\;${trigsrchome}/trigenixversion/SHIP-all/trigenix_version.zip\;${trigsrchome}/parcelforce/SHIP-all\;${trigsrchome}/pybtil/SHIP-rel/host/py\;${trigsrchome}/pybtil/SHIP-rel/host/bin\;${trigsrchome}/pyprotest/SHIP-vc7-rel-x86/host/py\;${trigsrchome}/pyprotest/SHIP-vc7-rel-x86/host/bin\;${trigsrchome}/trigcompilation/SHIP-all/trigcomptools.zip\;
   export TRIGMLDEFS_DIR=${trigsrchome}/trigmldefs/SHIP-all
   export BTILDIR=c:/sb/2.0.0/1.0.2/btil/SHIP-vc6-3_x-rel-x86
   export PROTESTSERVER=${trigsrchome}/protestserver
   PATH="${p}" py -c "import protest ; protest.go()" "${@}"
}

function __pt ()
{
   local debug_level=info
   local -r debug_level_arg="--debug_level="
   local ccompiler=vc7
   local -r ccompiler_arg="--ccompiler="
   local psdoc=doc
   local -r psdoc_arg="--psdoc="
   local style=dbg
   local -r style_arg="--style="
   local cleanall=""
   local -r cleanall_arg="--cleanall"
   local cleanfs=""
   local -r cleanfs_arg="--cleanfs"
   local cleanres=""
   local -r cleanres_arg="--cleanres"
   local -a other=()
   local -r dpk=PT1
   local -r vm=brew
   local -r qa=lint
   local -r sdk=315
   local arg
   for arg in "${@}" ; do
      case "${arg}" in
      ${ccompiler_arg}*) ccompiler=${arg#${ccompiler_arg}};;
      ${style_arg}*) style=${arg#${style_arg}};;
      ${psdoc_arg}*) psdoc=${arg#${psdoc_arg}};;
      ${debug_level_arg}*) debug_level=${arg#${debug_level_arg}};;
      ${cleanall_arg}) cleanfs="yes" ; cleanres="yes";;
      ${cleanfs_arg}) cleanfs="yes";;
      ${cleanres_arg}) cleanres="yes";;
      *) other=("${other[@]}" "${arg}") ;;
      esac
   done
   local -x -r trigsrchome=$(_Pma "${T5_SRC_HOME}")
   pushd ${BASH_T5_SRC_HOME}/playertest >& /dev/null
   local -r -x DEVICEFS=$(_Pwa ${PWD}/SHIP-${ccompiler}-${dpk}-${vm}-${qa}-${sdk}-${style}-x86-IP/devicefs)
   echo DEVICEFS=${DEVICEFS}
   if [[ "${cleanfs}" ]] ; then
      local -a cleanfs=($(find ${DEVICEFS} -type f \! -iname \*.dll \! -iname \*.mif))
      if [[ ${#cleanfs[@]} -gt 0 ]] ; then
         mvrm -fr "${cleanfs[@]}"
      fi
   fi
   local -r ps=../protestserver
   local -r sim=SIMULATOR/3.1.4
   local -r batches=testscripts/batches.py
   local -r res=results/${sim}
   local -r ref=reference/${sim}
   #local -r dev=../devicepacks/Playertest1 
   local dev=""
   for d in 120x146 128X160 128x126 128x140 128x146 128x148 BenQ_Ulysses DevicePack1 DevicePack2 DevicePack3 DevicePack4 Miranda Motorola_v710 Playertest1 SXG75 ; do
      if [[ -z "${dev}" ]] ; then
         dev="../devicepacks/${d}"
      else
         dev="${dev};../devicepacks/${d}"
      fi
   done
   local -r ext=../testtrigmlextension/metadata\;testscripts/extensions/metadata
   if [[ "${cleanres}" ]] ; then
      mvrm -fr ${res}
   fi
   #trace ${ps}/SHIP-dbg/runps.bat -P ${ps} -b testscripts/batches.py -r results/${sim} -g reference/${sim} -i testcontent/ -d ${ps}/ReferenceDevicePacks/DevicePack1 --extensiondirs=../testtrigmlextension/metadata\;testscripts/extensions/metadata "${@}"
   #trace ${ps}/SHIP-dbg/runps.bat -P ${ps} -b ${batches} -r ${res} -g ${ref} -i testcontent/ -d ${dev} --extensiondirs=${ext} "${@}"
   trace __ps -P ${ps} -b ${batches} -r ${res} -g ${ref} -i testcontent/ -d ${dev} --extensiondirs=${ext} "${other[@]}"
   popd
}

function __ptArgs ()
{
   local arg
   for arg in "${@}" ; do
      case "${arg}" in
      -*) switches=("${arg}" "${switches[@]}") ;;
      *) other=("${other[@]}" "${arg}") ;;
      esac
   done
}

function ptBatch ()
{
   local -a switches=()
   local -a other=()
   __ptArgs "${@}"
   __pt "${switches[@]}" auto "${other[@]}"
}

function ptScript ()
{
   local -a switches=()
   local -a other=()
   __ptArgs "${@}"
   local -r script="${other[0]}"
   __pt --env=BrewIP "${switches[@]}" --script="${script}" auto
}

