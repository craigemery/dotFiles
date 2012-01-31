#!/usr/bin/bash
# shell assistance with Python

function __py ()
{
    local -r ver="${1}"
    shift
    while [[ ${#} -gt 0 ]] ; do
        case "${1}" in
        =d) local -r debug="_d" ;;
        =C) local -r -x do_cd="y" ;;
        *) break ;;
        esac
        shift
    done
    local -a RESULT=();
    _PwaAllArgs "${@}"
    set -- "${RESULT[@]}"
    unset RESULT
    (
        if [[ "${do_cd}" && -d "${cygfile%/*}" ]] ; then
            cd "${cygfile%/*}"
        fi
        "/cygdrive/c/Python${ver}/python${debug}.exe" -u "${@}"
    )
}

function py23 ()
{
    __py 23 "${@}"
}

function pyd23 ()
{
    __py 23 =d "${@}"
}

function py24 ()
{
    __py 24 "${@}"
}

function pyd24 ()
{
    __py 24 =d "${@}"
}

function py25 ()
{
    __py 25 "${@}"
}

function pyd25 ()
{
    __py 25 =d "${@}"
}

function py26 ()
{
    __py 26 "${@}"
}

function pyd26 ()
{
    __py 26 =d "${@}"
}

function py27 ()
{
    __py 27 "${@}"
}

function pyd27 ()
{
    __py 27 =d "${@}"
}

function py30 ()
{
    __py 30 "${@}"
}

function pyd30 ()
{
    __py 30 =d "${@}"
}

function py ()
{
    py26 "${@}"
}

function pyd ()
{
    pyd26 "${@}"
}

function __cpy ()
{
    local -r ver="${1}"
    shift
    /usr/python/${ver}/bin/python -u "${@}"
}

function cpy252 ()
{
    __cpy 2.5.2 "${@}"
}

function cpy ()
{
    cpy252 "${@}"
}

function pcp ()
{
    cpy ~/dist/python/cp.py "${@}"
}

function __pydo ()
{
    local version=26
    # assume local -r me="${0}"
    local arg
    local -a args=()
    while [[ ${#} -gt 0 ]] ; do
        arg="${1}"
        shift
        case "${arg}" in
        -23|-24|-25|-26|-30) version="${arg/-}" ;;
        --help|-h|-\?) echo "usage: ${me} [-23|-24|-25|-26|-30] [<arguments>]" ; return 0 ;;
        *)
            if [[ -f "${arg}" ]] ; then
                arg=$(_Pwa "${arg}")
            fi
            args=("${args[@]}" "${arg}") ;;
        esac
    done
    set -- "${args[@]}"
    __py ${version} "${@}"
}

function pyro_ns ()
{
    local -r me="${0}"
    local version=26
    local arg
    local -a args=()
    while [[ ${#} -gt 0 ]] ; do
        arg="${1}"
        shift
        case "${arg}" in
        -23|-24|-25|-26|-30) version="${arg/-}" ;;
        --help|-h|-\?) echo "usage: ${me} [-23|-24|-25|-26|-30] [<arguments>]" ; return 0 ;;
        *)
            if [[ -f "${arg}" ]] ; then
                arg=$(_Pwa "${arg}")
            fi
            args=("${args[@]}" "${arg}") ;;
        esac
    done
    set -- "${args[@]}"
    __pydo -${version} -O -tt -c 'import Pyro.naming,sys; Pyro.naming.main(sys.argv[1:])' "${@}"
}

function pyro_es ()
{
    local -r me="${0}"
    local version=26
    local arg
    local -a args=()
    while [[ ${#} -gt 0 ]] ; do
        arg="${1}"
        shift
        case "${arg}" in
        -23|-24|-25|-26|-30) version="${arg/-}" ;;
        --help|-h|-\?) echo "usage: ${me} [-23|-24|-25|-26|-30] [<arguments>]" ; return 0 ;;
        *)
            if [[ -f "${arg}" ]] ; then
                arg=$(_Pwa "${arg}")
            fi
            args=("${args[@]}" "${arg}") ;;
        esac
    done
    set -- "${args[@]}"
    __pydo -${version} -O -tt -c 'from Pyro.EventService import Server; import sys; Server.start(sys.argv[1:])' "${@}"
}

function pyro_wxnsc ()
{
    local -r me="${0}"
    local version=26
    local arg
    local -a args=()
    while [[ ${#} -gt 0 ]] ; do
        arg="${1}"
        shift
        case "${arg}" in
        -23|-24|-25|-26|-30) version="${arg/-}" ;;
        --help|-h|-\?) echo "usage: ${me} [-23|-24|-25|-26|-30] [<arguments>]" ; return 0 ;;
        *)
            if [[ -f "${arg}" ]] ; then
                arg=$(_Pwa "${arg}")
            fi
            args=("${args[@]}" "${arg}") ;;
        esac
    done
    set -- "${args[@]}"
    local -r me="${0}"
    __pydo -${version}-O -tt -c 'import Pyro.wxnsc,sys; Pyro.wxnsc.main(sys.argv[1:])' "${@}"
}

function winpdb ()
{
   local WashSettings=""
   local WashBreakpoints=""
   local -r me="${0}"
   local arg
   local -a args=()
   local version=26
   while [[ ${#} -gt 0 ]] ; do
      arg="${1}"
      case "${arg}" in
      -wb) WashBreakpoints="y" ;;
      -ws) WashSettings="y" ;;
      -W) WashBreakpoints="y"
          WashSettings="y" ;;
      -23|-24|-25|-26|-30) version="${arg/-}" ;;
      --help|-h|-\?) echo "usage: ${me} [-23|-24|-25|-26|-30] [-W] [-wb] [-ws] [<arguments>]" ; return 0 ;;
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
   if [[ "${WashBreakpoints}" ]] ; then
      trace rm -fr ~/tmp/rpdb2_breakpoints
   fi
   if [[ "${WashSettings}" ]] ; then
      trace rm -fr ~/tmp/winpdb_settings.cfg
   fi
   local -x WINPDB_ACTIVE="yes"
   __py ${version} -c 'import winpdb;winpdb.main()' "${@}"
}

function __python ()
{
   . python.bash
}

unset winpdb
unset pyro_wxnsc
unset pyro_es
unset pyro_ns
unset __pydo
unset pcp
unset cpy
unset cpy252
unset __cpy
unset pyd
unset py
unset pyd30
unset py30
unset pyd27
unset py27
unset pyd26
unset py26
unset pyd25
unset py25
unset pyd24
unset py24
unset pyd23
unset py23
unset __py

# vim:sw=4
