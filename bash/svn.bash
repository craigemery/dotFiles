function _IsSvnDir ()
{
    if [[ -d "${1}" && -d "${1}/.svn" ]] ; then
        return 0
    else
        return 1
    fi
}

function __IsSvnDir ()
{
    #assume local -a RESULT=()
    while [[ ${#} -gt 0 ]] ; do
        _IsSvnDir "${1}" && RESULT=("${1}" "${RESULT[@]}")
        shift
    done
}

function IsSvnDir ()
{
    local -a RESULT=()
    __IsSvnDir "${@}"
    listArray "${RESULT[@]}"
}

function mvimdiff ()
{
    if [[ ${#} -eq 0 ]] ; then
        set -- $(SvnModified)
    fi
    while [[ ${#} -gt 0 ]] ; do
        mvim -R -c VCSVimDiff "${1}"
        shift
    done
}

function _SvnGetInfoPart ()
{
    local -r dir="${1}"
    if _IsSvnDir "${dir}" ; then
        #assume local RESULT
        local -r part="${2}"
        RESULT=$(svn info "${dir}" | sed -ne 's@^'"${part}"': @@p')
        return 0
    else
        return 1
    fi
}

function __SvnGetURL ()
{
    #assume local RESULT
    _SvnGetInfoPart "${1}" URL
    return ${?}
}

function SvnGetURL ()
{
    local RESULT
    while [[ ${#} -gt 0 ]] ; do
        __SvnGetURL "${1}" && echo "${RESULT}"
        shift
    done
}

function SvnGetRevision ()
{
    #assume local RESULT
    _SvnGetInfoPart "${1}" Revision
    return ${?}
}

function SvnSrc ()
{
    local -i ret=0
    local RESULT
    local url
    while [[ ${#} -gt 0 ]] ; do
        if __SvnGetURL "${1}" ; then
            url="${RESULT}"
            SvnGetRevision "${1}"
            echo "${url}@${RESULT}"
        else
            ret=1
        fi
        shift
    done
    return ${ret}
}

function SvnStatGrep ()
{
    local -r letter="${1}"
    shift
    if [[ ${#} -eq 0 ]] ; then
        set -- .
    fi
    local stat
    while [[ ${#} -gt 0 ]] ; do
        if [[ -d "${1}" ]] ; then
            stat=$(svn stat ${1})
            echo "${stat}" | sed -ne 's/'"${letter}"'.......\(.*[ 	].*\)$/"\1"/p'
            echo "${stat}" | sed -ne 's/'"${letter}"'.......\([^ ]*\)$/\1/p'
        fi
        shift
    done
}

function SvnUnknown ()
{
    SvnStatGrep '\?' "${@}"
}

function SvnModified ()
{
    SvnStatGrep 'M' "${@}"
}

function SvnChanged ()
{
    SvnStatGrep '[MA]' "${@}"
}

function SvnAdded ()
{
    SvnStatGrep 'A' "${@}"
}

function SvnClean ()
{
    local cmd=trace
    local files=""
    local directories=""
    local links=""
    local -a excludes=('-e' '\.sw.$')
    while [[ ${#} -gt 0 ]] ; do
        case "${1}" in
        -*|=*) # switches
            case "${1}" in
            -n|--dry-run) cmd=diag ;; # dry-run
            -d|--directories) directories=y ;;
            -f|--files) files=y ;;
            -l|--links) links=y ;;
            -a|--all) directories=y ; files=y ; links=y ;;
            -x|--exclude)
                excludes[${#excludes[@]}]="-e"
                excludes[${#excludes[@]}]=${2}
                shift
            ;;
            *) echo "Unknown switch '${1}'" ; return -1 ;;
            esac
        ;;
        *) break ;
        esac
        shift
    done
    if [[ ${#excludes[@]} -gt 0 ]] ; then
        set -- $(SvnUnknown "${@}" | egrep -v "${excludes[@]}")
    else
        set -- $(SvnUnknown "${@}")
    fi
    while [[ ${#} -gt 0 ]] ; do
        if [[ -f "${1}" && "${files}" ]] ; then
            ${cmd} rm "${1}"
        elif [[ -d "${1}" && "${directories}" ]] ; then
            ${cmd} rm -r "${1}"
        elif [[ -h "${1}" && "${links}" ]] ; then
            ${cmd} unlink "${1}"
        else
            echo "Don't know what to do with '${1}'" >&2
        fi
        shift
    done
}

function SvnBranch ()
{
    while [[ ${#} -gt 0 ]] ; do
        case "${1}" in
        -*|=*) # switches
            case "${1}" in
            *) ;;
            esac
        ;;
        *) break ;;
        esac
    done
    local -r required_branch="${1}"
    if [[ -z "${required_branch}" || -d "${required_branch}" ]] ; then
        echo "I needs at least a required branch name" >&2
        return 1
    fi
    shift
    # Not sure if this is a good idea, specify no directory, will branch cwd
    if [[ ${#} -eq 0 ]] ; then
        set -- .
    fi
    local url
    local revision
    local src
    local dest
    local dir
    while [[ ${#} -gt 0 ]] ; do
        dir="${1}"
        shift
        if ! _IsSvnDir "${dir}" ; then
            echo "${dir} is not an SVN directory" >&2
            continue
        fi
        local RESULT
        __SvnGetURL "${dir}"
        url="${RESULT}"
        SvnGetRevision "${dir}"
        revision="${RESULT}"
        local root
        case "${url}" in
        */tags/*)
            root="${url%%/tags/*}"
        ;;
        */branches/*)
            root="${url%%/branches/*}"
        ;;
        */trunk)
            root="${url%%/trunk}"
        ;;
        esac
        src="${url#${root}/}"
        if [[ "${src}" = "branches/${required_branch}" ]] ; then
            echo "Cannot branch ${url} onto itself!" >&2
            continue
        fi
        dest="${root}/branches/${required_branch}"
        diag svn copy "${root}/${src}@${revision}" "${dest}"
    done
}

function SvnEditsBy ()
{
    local -r u_s="-u"
    local -r u_l="--user"
    local -r u_c="${u_s} <user>|${u_l} <user>"
    local -r u_h="Show commits by user <user>"
    local -r l_s="-l"
    local -r l_l="--limit"
    local -r l_c="${l_s} <lines>|${l_l} <lines>"
    local -r l_h="Limit the size of svn log -v to <lines> lines"

    local -r h_s="-h"
    local -r h2_s="-?"
    local -r h_l="--help"
    local -r sep="\n\t\t"
    local -r more_help="${sep}${h_l} for more verbose help"
    local -r short_help="usage: ${FUNCNAME[0]} [${h_s}|${h2_s}|${h_l}] [${u_c}] [${l_c}]"
    local -r long_help="${short_help}${sep}${u_c}: ${u_h}${sep}${l_c}: ${l_h}"

    local user=""
    local -i limit=0
    while [[ ${#} -gt 0 ]] ; do
        case "${1}" in
        -*|=*) # switches
            case "${1}" in
            ${u_s}|${u_l}) user="${2}" ; shift ;;
            ${l_s}|${l_l}) limit=${2} ; shift ;;

            ${h_s}|${h2_s}) echo -e "${short_help}${more_help}" ; return ;;
            ${h_l}) echo -e "${long_help}" ; return ;;
            *) echo "Invalid switch '${1}'" >&2 ; return 1 ;; # bad switch
            esac
        ;;
        *) break ;;
        esac
        shift
    done

    svn log -v |
    if [[ ${limit} -gt 0 ]] ; then
        head -n ${limit}
    else
        cat
    fi | awk '/^r[0-9]* \| '"${user}"'/,/^-*$/{print}'
}

function SvnMyEdits ()
{
    SvnEditsBy -u 'craig\.emery@re5ult\.com' "${@}"
}

function SvnProp ()
{
    local -r action="${1}"
    shift
    case "${action}" in
    set|get) local -r prop="${1}" ; shift ;;
    list) ;;
    *) echo "Invalid prop action '${action}'" >&2 ; return 1 ;;
    esac
    local RESULT
    local d
    local f
    while [[ ${#} -gt 0 ]] ; do
        __realpath "${1}"
        d=${RESULT%/*}
        f=${RESULT##*/}
        pushd "${d}" > /dev/null
        msg "${d}"
        case "${action}" in
        set|get) trace svn prop${action} "${prop}" "${f}" .  ;;
        list) trace svn prop${action} "${f}" ;;
        esac
        popd > /dev/null
        shift
    done
}

function SvnPropSet ()
{
    SvnProp set "${@}"
}

function SvnPropGet ()
{
    SvnProp get "${@}"
}

function SvnIgnore ()
{
    SvnPropSet svn:ignore "${@}"
}

function __svn ()
{
   . svn.bash
}

# vim:sw=4:ts=4
