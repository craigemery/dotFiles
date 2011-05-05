#! /bin/bash

. cvs.bash
. tags.bash
. strings.bash
. ssh.bash
. citrix.bash
. home.bash

# . java.bash
# . dir.bash
# . lists.bash
# . date-time.bash
# . cheyenne.bash
# . xterm.bash
# . rpm.bash
# . perforce.bash
# . protest.bash
# . barona.bash

function lr ()
{
# need to escape the ls command coz there's an alias that has --color=auto & it overrides the =yes
    \ls -lAFR --color=yes "${@}" | less -R
}

function ta ()
{
    E -c "tj ${@}"
}

export BASH_FUNC_FILE="${HOME}/.dotFiles/bash/functions.bash"

function sofun ()
{
    [ -f "${BASH_FUNC_FILE}" ] && source "${BASH_FUNC_FILE}" "${@}"
}

function efun ()
{
    [ -f "${BASH_FUNC_FILE}" ] && e "${BASH_FUNC_FILE}" "${@}"
}

function which_dir ()
{
    local dir
    local file

    for dir in $(echo ${PATH} | tr : ' ') ; do
        file="${dir}/${1}"
        if [ "${file}" -a -x ${dir}/${1} -a ! -d "${file}" ] ; then
            echo ${dir}
            break
        fi
    done
}

function which_tail ()
{
    local dir
    local file

    for dir in $(echo ${PATH} | tr : ' ') ; do
        for file in ${dir}/*${1} "" ; do
        if [ "${file}" -a -x "${file}" -a ! -d "${file}" ] ; then
            echo ${file}
        fi
        done
    done
}

function which_file ()
{
    local file=""
    local -a found_func=($(shopt -s extdebug ; declare -F "${1}"))
    if [ ${#found_func[@]} -gt 0 ] ; then
        file=${found_func[2]}
    fi

    if [ -z "${file}" ] ; then
        file=$(alias | sed -ne 's@^alias '"${1}"'=.*$@'"${1}"'@p')
        if [ "${file}" ] ; then
# okay it's an alias, let's look for it in a file
            for shell_file in ~/.dotFiles/bash/*.bash ; do
            if egrep -qe "^[ 	]*alias[ 	]*'?${1}[ 	=]" < ${shell_file} ; then
                echo ${shell_file}
                break
            fi
            done
        else
            local dir=$(which_dir ${1})
            if [ "${dir}" -a -x ${dir}/${1} ] ; then
                echo ${dir}/${1}
            fi
        fi
    else
        echo "${file}"
    fi
}

function fedit ()
{
    if [[ "${1}" == "=r" ]] ; then
        local -r remote="${1}"
        shift
    fi
    if [[ "${1}" == "--wp" ]] ; then
        local -r wpa=1
        shift
    fi
    local -r edit="${1}"
    local f=$(which_file "${2}")

    if [ "${f}" ] ; then
        case "${f}" in
        ${BASH_FUNC_FILE})
            [[ "${wpa}" ]] && f=$(_Pwa "${f}")
            ${edit} ${remote} "+/^function ${2} ()/|norm zt" "${f}"
        ;;
        ${BASH_ALIAS_FILE}|${SHARED_BASH_ALIAS_FILE})
            [[ "${wpa}" ]] && f=$(_Pwa "${f}")
            ${edit} ${remote} "+/^[ 	]*alias[ 	]*'\{0,1\}${2}[ 	=].*/|norm zt" ${f}
        ;;
        *)
            case "$(file ${f} 2>&-)" in
            *ELF*)	;;
            *) [[ "${wpa}" ]] && f=$(_Pwa "${f}")
               ${edit} ${remote} "+/${2}" "${f}" ;;
            esac
        ;;
        esac
    fi
}

function fvi ()
{
    fedit vim ${1}
}

function useGvim ()
{
# for now I'm turning this on permanently
    return 0
    if [ "${DISPLAY}" ] ; then
        return 0
    fi
}

function fe ()
{
    local remote=""
    if [[ "${1}" == "=r" ]] ; then
        remote="${1}"
        shift
    fi
    if useGvim ; then
        fedit ${remote} gvim ${1}
    else
        fvi ${1}
    fi
}

[ -z "${NO_COMPLETE}" ] && complete -c fe

function __deduce_vcs ()
{
    #assume local RESULT=""
    [[ "${1}" ]] && local -r dir="${1}" || local -r dir="."
    [[ -d "${dir}" ]] || return -1
    RESULT=""
    if [[ -d "${dir}/CVS" && -f "${dir}/CVS/Entries" ]] ; then
        RESULT="cvs"
    elif [[ -d "${dir}/.svn" ]] ; then
        RESULT="svn"
    elif [[ -d "${dir}/.git" ]] ; then
        RESULT="git"
    fi
    [[ "${RESULT}" ]] && return 0 || return -2
}

function deduce_vcs ()
{
    local RESULT=""
    __deduce_vcs "${1}"
    if [[ ${?} -ge 0 ]] ; then
        echo "${RESULT}"
    fi
    unset RESULT
}

function vcs_diff_cmd ()
{
    #assume local RESULT
    __deduce_vcs "${1}"
    if [[ ${?} -ge 0 ]] ; then
        local -r vcs="${RESULT}"
        case "${vcs}" in
        cvs) RESULT=(${vcs} -q diff) ;;
        svn) RESULT=(${vcs} diff) ;;
        git) RESULT=(${vcs} diff) ;;
        esac
    fi
}

function ediff ()
{
    local files=("${@}")
    [[ ${#} -lt 1 ]] && files=(-)
    useGvim && local -r cmd=V || local -r cmd=vim
    local -r vim_cmd='set ft=diff | set nomodified'
    if [[ -t 0 ]] ; then
        local RESULT
        vcs_diff_cmd
        local -a -r pre_cmd=("${RESULT[@]}")
        unset RESULT
        files=(-)
    else
        local -r pre_cmd=(cat)
    fi
    "${pre_cmd[@]}" | "${cmd}" -c "${vim_cmd}" "${files[@]}"
}

function fcd ()
{
    local d=$(which_dir ${1})

    if [ "${d}" -a -x ${d}/${1} ] ; then
        cd ${d}
    fi
}

function whichLib ()
{
    if [ "${1}" ] ; then
        local dir
        for dir in $(echo ${LD_LIBRARY_PATH} | tr : \\012) ; do
            if [ -f "${dir}/${1}" ] ; then
                echo "${dir}/${1}"
            fi
        done
    fi
}

#
# Csh compatability:
#
alias unsetenv=unset
function setenv ()
{
    if [ -z "${1}" ] ; then
        export
    else
        export $1="$2"
    fi
}

# "repeat" command.  Like:
#
#       repeat 10 echo foo
function repeat ()
{
    local -i count="${1}"
    shift
    while [ $((count--)) -gt 0 ] ; do
        eval "${@}"
    done
}

function printArgs ()
{
    local count=0
    while [[ ${#} -gt 0 ]] ; do
        local word="${1}"

        [[ ${count} -ne 0 ]] && echo -n ' '
        case "${word}" in
        *\ *)   echo -n "'${word}'" ;;
        -n)     echo -n '-' ; echo -n n ;;
        *)      echo -n ${word} ;;
        esac

        shift
        count=$((++count))
    done

    echo ''
}

function msg ()
{
    [[ -t 1 ]] && colour bold
    printArgs "${@}" >&2
    [[ -t 1 ]] && colour reset
}

function diag ()
{
    msg "#${@}"
}

function trace ()
{
    msg "${@}"
    "${@}"
    return ${?}
}

function trace_eval ()
{
    msg "${@}"
    eval "${@}"
    return ${?}
}

function yesNo ()
{
    echo -ne "${@}? "
    read i
    i=$(echo "${i}" | tr '[A-Z]' '[a-z]')
    case ${i} in
    y|yes) "${@}" ;;
    esac
}

function px ()
{
    #ps ${1}xwww
    #ps -${1}wwwo user,pid,ppid,%cpu,%mem,vsz,rss,tname,stat,start_time,bsdtime,args --sort user,pid
    ps -${1}lxwww
}

function pax ()
{
    #px au
    px A
}

function doColour ()
{
    # this is the callers own arg / switch to signifiy that
    # the user *asked* for colour
    local -r arg="${1}"
    [ "${arg}" ] && return 0 # enable color as requested
    if [ -t 1 ] ; then
        case "${TERM}" in
        # enable colour for terminals that we know how to do colour for
        *rxvt|cygwin|xterm*|linux) return 0 ;;
        # but *not* for terminals we *don't* know how to do color for!
        *) return 1 ;;
        esac
    fi
    # otherwise, *no* colour
    return 1
}

function px_grep ()
{
    local temp=/tmp/pxgrep.${$}
    local lines=0

    local -r px_flags="${1}"
    shift
    px "${px_flags}" > ${temp}
    lines=$(egrep "${@}" < ${temp} | wc -l)
    lines=$(( 0 + ${lines} ))
#echo '${lines} = '"'${lines}'"
    if [ ${lines} -gt 0 ] ; then
        head -1 < ${temp}
        tail +2 < ${temp} | egrep "${@}"
    fi |
    if doColour "" ; then
        egrep --colour=auto "${@}"
    else
        cat
    fi
    rm -f ${temp}
}

function pxgrep ()
{
    px_grep '' "${@}"
}

function paxgrep ()
{
    #px_grep 'au' ${1}
    px_grep 'A' "${@}"
}

function match ()
{
    echo ${PATH} | tr : \\012 | xargs -I XX bash -c 'ls -1d XX/*'${1}'* 2>&1' | egrep -ve ': No such file or directory'
}

function dm ()
{
    local mf="$(t5ThisDMfile)"
    # tput cup $(tput lines)
    m "${@}"
    return ${?}
}

function fmo ()
{
    while [ "TRUE" ] ; do
        case "${1}" in
        --nocolour)
            cat
            shift
        ;;
        *)
            local fmoDotpl=~/dist/perl/fmo.pl
            if [[ "${PERL_IS_WIN32}" ]] ; then
                fmoDotpl=$(_Pwas "${fmoDotpl}")
            fi
            tr -d \\015 | perl "${fmoDotpl}"
            break
        ;;
        esac
    done
}

function dmo ()
{
    local mf="$(t5ThisDMfile)"
    if [ -f ${mf} ] ; then
        if fileBiggerThanScreen ${mf} ; then
            fmo < ${mf} 2>&1 | less -R
        else
            fmo < ${mf} 2>&1
        fi
    fi
}

function pmo ()
{
    local mf="$(t5ThisDMfile)"
    if [ -f ${mf} ] ; then
        if fileBiggerThanScreen ${mf} ; then
            less ${mf}
        else
            cat ${mf}
        fi
    fi
}

function cmo ()
{
    local mf="$(t5ThisDMfile)"
    if [ -f ${mf} ] ; then
        fmo < ${mf} 2>&1
    fi
}

function replace_vim_reg_exp ()
{
    return
    #assume local RESULT
    while [[ "${RESULT}" =~ '.*\s.*' ]] ; do
        RESULT="${RESULT#\\s}"'[[:space:]]'"${RESULT%%\\s}"
    done
}

unset __findIn
function __FI ()
{
    local -r cmdName="${1}"
    shift
    local -r findCmdName="${1}"
    shift
    local error=""
    local colour=""
    local listonly=""
    local wholeWords=""
    local case=""
    local numbers=""
    local ignoreBinary=""
    local less=""
    local -i before=0
    local -i after=0
    local -r caseFlag="-i"
    local -r numbersFlag="-n"
    local -r wFlag="-w"
    local -r wLongFlag="--whole-words"
    local -r cFlag="-c"
    local -r cLongFlagUK="--colour"
    local -r cLongFlagUS="--color"
    local -r BFlag="-B"
    local -r BLongFlag="--before-context"
    local -r aFlag="-A"
    local -r aLongFlag="--after-context"
    local -r ignoreBinaryFlag="-I"
    local -r ignoreBinaryLongFlag="--binary-files=without-match"
    local -r xFlag="-x"
    local -a excludes=()
    local -r lFlag="-l"
    local -r lLongFlag="--list"
    local -r LFlag="-L"
    local -r LLongFlag="--less"
    local -r bFlag="-b"
    local -r bLongFlag="--binary"
    local binary_files_allowed=""
    local -a prune_dirs=()
    local -r pFlag="-p"
    local -r PFlag="-P"
    local -r vFlag="-v"
    local -r vLongFlag="--vim-regex"
    local useVimRegExp=""
    local pruneless=""

    while [[ ${#} -gt 0 ]] ; do
        case "${1}" in
        ${aFlag})
            shift
            after=${1}
        ;;
        ${aLongFlag}=)
            after=${1#${aLongFlag}=}
        ;;
        ${BFlag})
            shift
            before=${1}
        ;;
        ${BLongFlag}=)
            before=${1#${BLongFlag}=}
        ;;
        ${cFlag}|${cLongFlagUK}|${cLongFlagUS})
            colour="${cLongFlagUS}"
        ;;
        ${caseFlag})
            case="${caseFlag}"
        ;;
        ${numbersFlag})
            numbers="${numbersFlag}"
        ;;
        ${wFlag}|${wLongFlag})
            wholeWords="${wFlag}"
        ;;
        ${bFlag}|${bLongFlag})
            binary_files_allowed="-a"
        ;;
        ${ignoreBinaryFlag}|${ignoreBinaryLongFlag})
            ignoreBinary="${ignoreBinaryFlag}"
        ;;
        ${lFlag}|${lLongFlag})
            listonly="-l"
        ;;
        ${LFlag}|${LLongFlag})
            less="y"
            colour="${cLongFlagUS}"
        ;;
        ${xFlag}) excludes[${#excludes[@]}]="${xFlag}"
                  excludes[${#excludes[@]}]="${2}"
                  shift
        ;;
        ${pFlag}) prune_dirs[${#prune_dirs[@]}]="${pFlag}"
                  prune_dirs[${#prune_dirs[@]}]="${2}"
                  shift
        ;;
        ${PFlag}) pruneless=${PFlag} ;;
        ${vFlag}|${vLongFlag})
            useVimRegExp=yes
        ;;
        --) shift ; break ;;
        -*)
            echo "Invalid argument: ${1}" >&2
            echo -ne "usage:\t${cmdName} [[${aFlag} N|${aLongFlag}=N] [${BFlag} N|${BLongFlag}=N] ${caseFlag} ${numbersFlag}] [${ignoreBinaryFlag}|${ignoreBinaryLongFlag}] [${wFlag}|${wLongFlag}] [${cFlag}|${cLongFlagUK}|${cLongFlagUS}] [${bFlag}|${bLongFlag}] [${PFlag}] [-l|--list] " >&2
            echo "[<directory>] <regular expression>" >&2
            error="yes"
            break
        ;;
        *)
            break
        ;;
        esac

        shift
    done

    local -a dir_list=()
    while [[ ${#} -gt 1 && -d "${1}" && "${1}" != "--" ]] ; do
        dir_list=("${1}" "${dir_list[@]}")
        shift
    done
    [[ "${1}" == "--" ]] && shift
    if [[ ${#dir_list[@]} -eq 0 ]] ; then
        dir_list=(.)
    fi

    if [ -z "${error}" ] ; then
        if [ "${listonly}" ] ; then
            colour=""
        fi

        if [ -z "${listonly}" ] ; then
            if doColour "${colour}" ; then
                colour="${cLongFlagUS}=always"
            fi
        fi

        if [[ "${wholeWords}" ]] ; then
            local -r wl='\<'
            local -r wr='\>'
        else
            local -r wl=''
            local -r wr=''
        fi

        local patterns=()
        local RESULT=""
        while [[ ${#} -gt 0 ]] ; do
            RESULT="${1}"
            patterns[${#patterns[@]}]="-e"
            #[[ "${useVimRegExp}" ]] && replace_vim_reg_exp
            patterns[${#patterns[@]}]="${wl}${RESULT}${wr}"
            shift
        done
        unset RESULT

        if [[ "${less}" ]] ; then
            ${findCmdName} ${pruneless} "${prune_dirs[@]}" "${excludes[@]}" -0 "${dir_list[@]}" | xargs -0 -n99 egrep ${ignoreBinary} ${binary_files_allowed} ${case} ${numbers} -B ${before} -A ${after} ${colour} ${listonly} "${patterns[@]}" | less -fR
        else
            ${findCmdName} ${pruneless} "${prune_dirs[@]}" "${excludes[@]}" -0 "${dir_list[@]}" | xargs -0 -n99 egrep ${ignoreBinary} ${binary_files_allowed} ${case} ${numbers} -B ${before} -A ${after} ${colour} ${listonly} "${patterns[@]}"
        fi

    fi
}

function deTrailingSlash ()
{
    #assume local -a RESULT
    RESULT=()
    while [[ ${#} -gt 0 ]] ; do
        RESULT[${#RESULT[@]}]=${1%/}
        shift
    done
}

function __not_named ()
{
    # assume local -a RESULT
    while [[ ${#} -gt 0 ]] ; do
        RESULT[${#RESULT[@]}]="!"
        if [[ "${1}" == "-i" ]] ; then
            shift
            RESULT[${#RESULT[@]}]="-iname"
        else
            RESULT[${#RESULT[@]}]="-name"
        fi
        RESULT[${#RESULT[@]}]="${1}"
        shift
    done
}

function __readRC ()
{
    # assume local -a RESULT
    local -r file="${1}"
    shift
    # After the file, the rest is the default
    if [[ -f "${HOME}/${file}" ]] ; then
        RESULT=($(cat "${HOME}/${file}"))
    else
        RESULT=()
    fi
    if [[ -f "${file}" ]] ; then
        RESULT=("${RESULT[@]}" $(cat "${file}"))
    else
        RESULT=("${RESULT[@]}" "${@}")
    fi
}

function __findDefaultExcludes ()
{
    # assume local -a RESULT
    __readRC .FIexcludes
    __not_named tags '*.log' '.sw?' '.*.sw?' .DS_Store "${RESULT[@]}"
}

function __findDefaultPrunes ()
{
    # assume local -a RESULT
    __readRC .FIprunes CVS .svn .git .idea .hg
}

function findFiles ()
{
    local print="-print"
    local -a RESULT
    __findDefaultExcludes
    local -a excludes=("${RESULT[@]}")
    __findDefaultPrunes
    local -a prune_dirs=("${RESULT[@]}")
    unset RESULT
    while [[ ${#} -gt 0 ]] ; do
        case "${1}" in
        -ls)
            local print="-ls"
        ;;
        -0)
            local print="-print0"
        ;;
        -newer|-anewer|-cnewer)
            local -r newer="${1} ${2}"
            shift
        ;;
        -X) excludes=() ;;
        -x) excludes[${#excludes[@]}]="!"
            excludes[${#excludes[@]}]="-name"
            excludes[${#excludes[@]}]="${2}"
            shift
        ;;
        -P) prune_dirs=() ;;
        -p) prune_dirs[${#prune_dirs[@]}]="${2}"
            shift
        ;;
        *) break ;;
        esac
        shift
    done
    local -a prune_dir_flags=()
    local -i i=0
    while [[ ${i} -lt ${#prune_dirs[@]} ]] ; do
        [[ ${i} -gt 0 ]] && prune_dir_flags[${#prune_dir_flags[@]}]="-o"
        prune_dir_flags[${#prune_dir_flags[@]}]="-iname"
        prune_dir_flags[${#prune_dir_flags[@]}]="${prune_dirs[${i}]}"
        i=$((${i} + 1))
    done
    local -a RESULT
    deTrailingSlash "${@}"
    set -- "${RESULT[@]}"
    if [[ ${#prune_dir_flags[@]} -gt 0 ]] ; then
        local -r -a pruning=(\( -type d \( "${prune_dir_flags[@]}" \) -prune \) -o)
    else
        local -r -a pruning=()
    fi
    find "${@}" "${pruning[@]}" \( -type f ${newer} "${excludes[@]}" ${print} \)
}

function FI ()
{
    __FI FI findFiles "${@}"
}

function suffixOneOf ()
{
    #assume local -a RESULT
    RESULT=()
    if [[ ${#} -gt 0 ]] ; then
        RESULT[${#RESULT[@]}]="-iname"
        RESULT[${#RESULT[@]}]="*.${1}"
        shift
        while [[ ${#} -gt 0 ]] ; do
            RESULT[${#RESULT[@]}]="-o"
            RESULT[${#RESULT[@]}]="-iname"
            RESULT[${#RESULT[@]}]="*.${1}"
            shift
        done
    fi
}

function findNamed ()
{
    #assume local -a RESULT
    #though weirdly RESULT is being used to pass in some parameters
    local -r -a named=("${RESULT[@]}")
    unset RESULT
    local -a names=()
    local print="-print"
    local -a RESULT
    __findDefaultExcludes
    local -a excludes=("${RESULT[@]}")
    __findDefaultPrunes
    local -a prune_dirs=("${RESULT[@]}")
    unset RESULT
    #if [[ ${#} -eq 1 && ! "${1}" =~ "^-.*" ]] ; then
        #set -- -n "${1}"
    #fi
    while [[ ${#} -gt 0 ]] ; do
        case "${1}" in
        -ls)
            local print="-ls"
        ;;
        -0)
            local print="-print0"
        ;;
        -newer|-anewer|-cnewer)
            local -r newer="${1} ${2}"
            shift
        ;;
        -X) excludes=() ;;
        -x) excludes[${#excludes[@]}]="!"
            excludes[${#excludes[@]}]="-name"
            excludes[${#excludes[@]}]="${2}"
            shift
        ;;
        -p) prune_dirs[${#prune_dirs[@]}]="${2}"
            shift
        ;;
        -N|-n) [[ ${#names[@]} -gt 0 ]] && names[${#names[@]}]="-o"
            case "${1}" in
            -n) local finder="-name" ;;
            -N) local finder="-iname" ;;
            esac
            names[${#names[@]}]="${finder}"
            names[${#names[@]}]="${2}"
            shift
        ;;
        *) break ;;
        esac
        shift
    done
    local -a prune_dir_flags=()
    local -i i=0
    while [[ ${i} -lt ${#prune_dirs[@]} ]] ; do
        [[ ${i} -gt 0 ]] && prune_dir_flags[${#prune_dir_flags[@]}]="-o"
        prune_dir_flags[${#prune_dir_flags[@]}]="-iname"
        prune_dir_flags[${#prune_dir_flags[@]}]="${prune_dirs[${i}]}"
        i=$((${i} + 1))
    done
    local -a RESULT
    deTrailingSlash "${@}"
    set -- "${RESULT[@]}"
    if [[ ${#prune_dir_flags[@]} -gt 0 ]] ; then
        local -r -a pruning=(\( -type d \( "${prune_dir_flags[@]}" \) -prune \) -o)
    else
        local -r -a pruning=()
    fi
    find "${@}" "${pruning[@]}" \( -type f ${newer} "${excludes[@]}" \( "${named[@]}"  "${names[@]}" \) ${print} \)
}

# This needs fixing on the bloody =~ expression that either is broken or I don't get!!!!
function __findNamed ()
{
    #assume local -a RESULT
    local -r sought="${1}"
    shift
    if [[ ${#} -gt 0 ]] ; then
        local -a dirs=(${1})
    else
        local -a dirs=(.)
    fi
    shift
    local -a subs=()
    local dir
    while [[ ${#dirs[@]} -gt 0 ]] ; do
        #echo '${dirs[@]} = '"'${dirs[@]}'" >&2
        for dir in "${dirs[@]}" ; do
            local path
            for path in "${dir}"/* "${dir}"/.* ; do
                local basename="${path##*/}"
                #echo '${basename} = '"'${basename}'" >&2
                if [[ -d "${path}" ]] ; then
                    if arrayHas "${basename}" ".svn" ".git" "." ".." ; then
                        continue
                    else
                        subs[${#subs[@]}]="${path}"
                    fi
                elif [[ -f "${path}" ]] ; then
                    if [[ "${basename}" =~ ".swp" ]] ; then
                        continue
                    elif [[ "${path##*/}" =~ "${sought}" ]] ; then
                        RESULT[${#RESULT[@]}]="${path}"
                    fi
                fi
            done
        done
        dirs=("${subs[@]}")
        subs=()
    done
}

function findSuffixed ()
{
    suffixOneOf "${RESULT[@]}"
    findNamed "${@}"
}

function __sourceSuffixes ()
{
    #assume local -a RESULT=()
    RESULT=(py pm pmake cc c cpp cxx l y rb js erb yml m)
}

function findSources ()
{
    local -a RESULT=()
    __sourceSuffixes
    findSuffixed "${@}"
}

function FISources ()
{
    __FI FISources findSources "${@}"
}

function __headerSuffixes ()
{
    #assume local -a RESULT=()
    RESULT=(h hpp bid)
}

function findHeaders ()
{
    local -a RESULT=()
    __headerSuffixes
    findSuffixed "${@}"
}

function FIHeaders ()
{
    __FI FIHeaders findHeaders "${@}"
}

function __sourceAndHeaderSuffixes ()
{
    #assume local -a RESULT=()
    __sourceSuffixes
    local -r -a src=("${RESULT[@]}")
    __headerSuffixes
    RESULT=("${src[@]}" "${RESULT[@]}")
}

function findSourcesAndHeaders ()
{
    local -a RESULT=()
    __sourceAndHeaderSuffixes
    findSuffixed "${@}"
}

function FISourcesAndHeaders ()
{
    __FI FISourcesAndHeaders findSourcesAndHeaders "${@}"
}

function findMakefiles ()
{
    local -a RESULT=(mk mak)
    suffixOneOf "${RESULT[@]}"
    RESULT[${#RESULT[@]}]="-o"
    RESULT[${#RESULT[@]}]="-iname"
    RESULT[${#RESULT[@]}]="Makefile"
    RESULT[${#RESULT[@]}]="-o"
    RESULT[${#RESULT[@]}]="-iname"
    RESULT[${#RESULT[@]}]="gnuMakefile"
    RESULT[${#RESULT[@]}]="-o"
    RESULT[${#RESULT[@]}]="-iname"
    RESULT[${#RESULT[@]}]="Rakefile"
    findNamed "${@}"
}

function FIMakefiles ()
{
    __FI FIMakefiles findMakefiles "${@}"
}

function findMarkup ()
{
    local -a RESULT=('[ytx]ml' rhtml html css)
    findSuffixed "${@}"
}

function FIMarkup ()
{
    __FI FIMarkup findMarkup "${@}"
}

function findSwaps ()
{
    findNamed -X -n '.sw?' -n '.*.sw?'
}

function mrun ()
{
    m "${1}" && "${@}"
}

function dmrun ()
{
    dm "${1}" && "${@}"
}

function caselessRE ()
{
    local re_lower=$(echo "${@}" | tr '[a-zA-Z]' '[a-za-z]')
    local re_upper=$(echo "${@}" | tr '[a-zA-Z]' '[A-ZA-Z]')
}

function getCR ()
{
    local -i ret=${1}
    [[ -t 1 ]] && colour fg green
    trap "echo '' ; stty echo ; return ${ret}" INT
    echo -ne "Please hit return to continue:"
    [[ -t 1 ]] && colour reset
    stty -echo
    read line
    stty echo
    echo ''
    return ${ret}
}

function maybeGetCR ()
{
    local -i ret=${1}
    if [[ "${err}" ]] ; then
        if [[ ${ret} = ${err} ]] ; then
            getCR ${ret}
        else
            return ${ret}
        fi
    else
        if [[ "${noterr}" ]] ; then
            if [[ ${ret} != 0 && ${ret} != ${noterr} ]] ; then
                getCR ${ret}
            else
                return ${ret}
            fi
        else
            if [[ ${ret} != 0 ]] ; then
                getCR ${ret}
            else
                return ${ret}
            fi
        fi
    fi
}

function rxvt ()
{
    rxvt.exe -bg black -fg white -ufbg grey -geometry 200x50 -cr red "${@}"
}

function e ()
{
    local -r me="${FUNCNAME[0]}"
    [[ ${#} -gt 0 ]] && set -- =r "${@}"
    __v "${@}"
}

function E ()
{
    ( rxvt -e vim "${@}" 2>&- <&- >&- & )
}

function v ()
{
    local -r me="${FUNCNAME[0]}"
    __v "${@}"
}

function V ()
{
    local -r me="${FUNCNAME[0]}"
    __v -f "${@}"
}

function __v ()
{
    #assume local -r me="${0}"
    local fg=""
    local arg
    local -x -a args=()
    local remote=""
    local winpathfiles=0
    while [[ ${#} -gt 0 ]] ; do
        arg="${1}"
        case "${arg}" in
        -f) fg=""y ;;
        --help|-h|-\?) echo "usage: ${me} [-f] [=r] [<arguments>]" ; return 0 ;;
        #-*) echo "${arg}: unknown argument" >&2 ; return -1 ;;
        =r) remote="--remote-tab-silent" ;;
        *)
            if [[ ${winpathfiles} -ne 0 && -f "${arg}" ]] ; then
                arg=$(_Pwa "${arg}")
            fi
            args=("${args[@]}" "${arg}") ;;
        esac
        shift
    done
    #local -x T5_SRC_HOME=$(_Pw ${T5_SRC_HOME})
    #local -x VIMINIT='so $HOME\\.viminit'
    local -x -r exe="/cygdrive/c/Program\ Files/Vim/vim73/gvim.exe"
    #local -x -r exe="mvim"
    #local -x -r exe="/usr/bin/gvim"
    if [[ "${fg}" ]] ; then
        ${exe} ${remote} -f "${args[@]}"
    else
        ( ${exe} ${remote} "${args[@]}" & )
    fi
}

function mvrm ()
{
    if [[ "${1}" = "-d" ]] ; then
        shift
        local -r action=diag
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
    titles both "rm ${args[@]} ${moved_files[@]}" >&2
    trace rm "${args[@]}" "${moved_files[@]}"
}

. shared.bash

function __functions()
{
    . functions.bash
}

function __realdir ()
{
    #assume local RESULT
    if [[ "${1}" && -d "${1}" ]] ; then
        pushd "${1}" > /dev/null
        RESULT=$(pwd -P) # I wish I could do this without spawning a sub-shell
        popd > /dev/null
    else
        RESULT=$(pwd -P) # I wish I could do this without spawning a sub-shell
        popd > /dev/null
    fi
}

function realdir ()
{
    if [[ "${1}" ]] ; then
        local RESULT
        __realdir "${1}"
        echo "${RESULT}"
    fi
}

function __realpath ()
{
    #local RESULT
    if [[ -f "${1}" ]] ; then
        __realdir "${1%/*}"
        RESULT=${RESULT}/${1##*/}
    elif [[ -d "${1}" ]] ; then
        __realdir "${1}"
    fi
}

function realpath ()
{
    if [[ "${1}" ]] ; then
        local RESULT
        __realpath "${1}"
        echo "${RESULT}"
    fi
}

function Sleep ()
{
    local -i seconds=${1}
    [[ ${seconds} -gt 0 ]] && while [[ ${seconds} -gt 0 ]] ; do
        read -t 1 -p .
        seconds=$((${seconds}-1))
    done
}

# vim:sw=4:ts=4
