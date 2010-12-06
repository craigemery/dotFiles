#! /bin/bash

function reTag ()
{
    findSources -0 -cnewer tags | xargs -0 -n99 ~/dist/python/autoTag.py
}

function newtag ()
{
   local -a excludes=()
   local -r ex=--exclude
   local dir
   for dir in "${@}" ; do
      if test ${#excludes[@]} -eq 0 ; then
         excludes=(${ex}="${dir}")
      else
         excludes=("${excludes[@]}" ${ex}="${dir}")
      fi
   done

   local -r temp=$(mktemp -p /tmp "${PWD##*/}.tags.XXXXX")
   if [[ -f "${temp}" ]] ; then
      ctags "${excludes[@]}" -Rf "${temp}" && mv "${temp}" tags
      rm -f "${temp}" 2>&1
   else
      echo "Couldn't make temporary file"'!' >&2
   fi
}

function stringNotInFile ()
{
    local -r s="${1}"
    local -r f="${2}"
    if [[ -f "${f}" ]] ; then
        local -r -a words=($(cat "${f}"))
        local w
        for w in "${words[@]}" ; do
            if [[ "${w}" == "${s}" ]] ; then
                return 1
            fi
        done
        return 0
    else
        return 0
    fi
}

function linktag ()
{
    local -r tagfile="${1}"
    local -r linkfile="${2}"
    if [[ ! -f "${linkfile}" ]] ; then
        local -r linkdir="${linkfile%/*}"
        if [[ ! -d "${linkdir}" ]] ; then
            mkdir -p "${linkdir}"
        fi
    fi
    if stringNotInFile "${tagfile}" "${linkfile}" ; then
        echo "${tagfile}" >> "${linkfile}"
    fi
}

function __retag()
{
    local -r lf_flag="--linkfile="
    while [[ ${#} -gt 0 ]] ; do
        case "${1}" in
        -v) local -r verbose="yes" ;;
        ${lf_flag}*) local -r linkfile="${1#${lf_flag}}" ;;
        *) break ;;
        esac
        shift
    done
    local -r d="${1}"
    shift
    if [[ -d "${d}" ]] ; then
        pushd "${d}" >&-
        #[[ "${verbose}" ]] && echo "Newtags in $(npwd)"
        if [[ "${verbose}" ]] ; then
            if [[ ${#} -gt 0 ]] ; then
                local -r ex=" (excluding ${@})"
            fi
            echo "Newtags in $(npwd)${ex}"
        fi
        newtag "${@}"
        #[[ -f tags ]] && linktag "${PWD}/tags" "${linkfile}"
        popd >&-
    fi
}

#vim:sw=4
