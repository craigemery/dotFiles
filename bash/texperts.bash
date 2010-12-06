#!/bin/env bash

. svn.bash
. functions.bash
. xterm.bash
. macos.bash
. date-time.bash
. lists.bash
. ssh.bash

export RUBY_HEAP_MIN_SLOTS=500000
export RUBY_HEAP_SLOTS_INCREMENT=250000
export RUBY_HEAP_SLOTS_GROWTH_FACTOR=1
export RUBY_GC_MALLOC_LIMIT=50000000

export GREP_OPTIONS=--color=auto

function __need_args ()
{
    local -i -r supplied=${1} ; shift
    local -r test="${1}" ; shift
    local -i -r boundary=${1} ; shift
    local -r usage="usage ${FUNCNAME[1]}: ${1}" ; shift
    local -i cmp=1
    case "${test}" in
    ==)  [[ ${supplied} -ne ${boundary} ]] ; cmp=${?} ;;
    !=)  [[ ${supplied} -eq ${boundary} ]] ; cmp=${?} ;;
    \>)  [[ ${supplied} -le ${boundary} ]] ; cmp=${?} ;;
    \<)  [[ ${supplied} -ge ${boundary} ]] ; cmp=${?} ;;
    \>=) [[ ${supplied} -lt ${boundary} ]] ; cmp=${?} ;;
    \<=) [[ ${supplied} -gt ${boundary} ]] ; cmp=${?} ;;
    esac
    if [[ ${cmp} -eq 0 ]] ; then
        echo "${usage}" >&2
        return 1
    fi
    return 0
}

function __determine_ruby_enterprise_edition ()
{
    local d
    for d in /opt/ruby-enterprise-*/bin ; do
        export RUBY_ENTERPRISE_EDITION=${d%/bin}
    done
}

__determine_ruby_enterprise_edition

function __which_mongrel_rails ()
{
    local -r exe=$(which mongrel_rails)
    [[ -f "${exe}" ]] && export "RUBY_MONGREL_RAILS=${exe}"
}

__which_mongrel_rails

function Ruby ()
{
    ${RUBY_ENTERPRISE_EDITION}/bin/ruby "${@}"
}

function Rake ()
{
    Ruby "${RUBY_ENTERPRISE_EDITION}/bin/rake" "${@}"
}

function Gem ()
{
    sudo "${RUBY_ENTERPRISE_EDITION}/bin/gem" "${@}"
}

function Rapidf_n_pid ()
{
    local -r app="${1}";
    shift
    local f;
    for f in ${TEXPERT_HOME}/${app}/log/mongrel.*.pid;
    do
        if [[ -f "${f}" ]] ; then
            pid_file="${f}"
            pid=$((0 + $(cat "${pid_file}")))
            return
        fi
    done
}

function Rapidf () 
{ 
    local -i pid=-1
    local pid_file=""
    Rapidf_n_pid "${1}"
    echo "${pid_file}"
}

function Rapid () 
{ 
    local -i pid=-1
    local pid_file=""
    Rapidf_n_pid "${1}"
    echo "${pid}"
}

function Rarunning () 
{ 
    local -i pid=-1
    local pid_file=""
    Rapidf_n_pid "${1}"
    Rpid_exists ${pid}
    return ${?}
}

function Rpid_exists ()
{
    local -i -r pid=${1}
    ps auxwww | awk 'BEGIN{r=1};$2 ~ /^'"${pid}"'$/{r=0};END{exit r}' > /dev/null
    return ${?}
}

function __app_from_arg ()
{
    #assume local RESULT
    case "${1}" in
    ""|.) RdeduceCurrentApp ;;
    *) RESULT="${1}" ;;
    esac
    if [[ "${RESULT}" ]] ; then return 0 ; else return -1 ; fi
}

function asignal ()
{
    #assume local -i pid=-1
    #assume local pid_file=""
    local -r signal="${1}"
    shift
    local RESULT
    __app_from_arg "${1}"
    local -r app="${RESULT}"
    shift
    Rapidf_n_pid "${app}"
    if [[ "${pid}"  && ${pid} > 0 ]] ; then
        if Rpid_exists ${pid} ; then
            trace kill ${signal} ${pid}
        fi
        return 0
    fi
    return -1
}

function Rapp_kill ()
{
    local -i pid=-1
    local pid_file=""
    local RESULT
    __app_from_arg "${1}"
    local -r app="${RESULT}"
    if asignal -TERM ${app} ; then
        sleep 2
        trace kill -KILL ${pid}
        sleep 2
        if ! Rpid_exists ${pid} ; then
            echo rm -f "${pid_file}"
            rm -f "${pid_file}"
        else
            echo "Not removing pid file ${pid_file} as process ${pid} still running"
        fi
    fi
}

function Rapp_signal ()
{
    local -i pid=-1
    local pid_file=""
    local signal="${1}"
    shift
    local RESULT
    __app_from_arg "${1}"
    local -r app="${RESULT}"
    unset RESULT
    asignal ${signal} ${app}
}

function Rapp_restart ()
{
    Rapp_signal -USR2 "${@}"
}

function Rapps_signal ()
{
    local -r signal="${1}"
    shift
    Rapp_each Rapp_signal ${signal} .
}

function Rapps_restart ()
{
    Rcap_stop
    trace rm -f /usr/local/sphinx/var/data/*.spl
    Rcap_start
}

function Rapp_exists ()
{
    local -r app="${1}"
    if [[ ! -z "${app}" && -d "${TEXPERT_HOME}/${app}" ]] ; then
        return 0
    else
        return 1
    fi
}

function Rapp_script ()
{
    local -r app="${1}"
    shift
    local -r script="script/${1}"
    shift
    if Rapp_exists "${app}" ; then
        if [[ -f "${TEXPERT_HOME}/${app}/${script}" ]] ; then
            pushd "${TEXPERT_HOME}/${app}" >&-
            pwd
            xtrace =f Ruby "${script}" "${@}"
            popd >&-
        fi
    fi
}

function Rapp_log ()
{
    #Mixed args
    #Arg with param choices from an array
    #( these work great with = switch handling: find =<something> and <something> is one
    #  of the values in an array, then pretend --arg=<someting> was appropriately supplied )

    local -a RESULT
    __Rapps_list --basename
    local -r -a apps=("${RESULT[@]}")
    unset RESULT
    local -r apps_l=$(listArray --comma "${apps[@]}")
    local -r a_s="-a"
    local -r a_l="--app"
    local -r a_c="${a_s} <app> or ${a_l}=<app>"
    local -r a_h="Which application to log (must be one of ${apps_l})"
    local app=""

    local -r default_k=(development)
    local -r -a kinds=(${default_k} test)
    local -r kind_l=$(listArray --comma "${kinds[@]}")
    local -r k_s="-k"
    local -r k_l="--kind"
    local -r k_c="${k_s} <kind> or ${k_l}=<kind>"
    local -r k_h="Which kind of log (must be one of ${kind_l})"
    local kind="${default_k}"

    #Args with arbitrary param
    local -r c_s="-c"
    local -r c_l="--comment"
    local -r c_c="${c_s}|${c_l} <comment>"
    local -r c_h="Comment to inject into log file before viewing"
    local comment=""

    local -i -r default_w=1
    local -r w_s="-w"
    local -r w_l="--wait"
    local -r w_c="${w_s} <seconds> | ${w_l}=<seconds>"
    local -r w_h="Number of seconds to sleep in between retries"
    local -i wait=${default_w}
    local -r r_s="-r"
    local -r r_l="--retries"
    local -r r_c="${r_s} <attempts> | ${r_l}=<attempts>"
    local -r r_h="Wait for log file to 'appear' sleep -W <n> (default = ${default_w}) second(s) between <attempts> retries (Should be >= -1, -1 == 'forever', 0 == 'never')"
    local -i attempts=0
    local retry=""

    #Solo args
    local -r v_s="-v"
    local -i verbosity=0
    local -r d_s="-d"
    local dry_run=""
    local -r z_s="-0"
    local zero_log=""
    local -r t_s="-t"
    local timestamp_log=""

    #Standard helper args
    local -r h_s="-h"
    local -r h2_s="-?"
    local -r h_l="--help"
    local -r sep="\n\t\t"
    local -r more_help="${sep}${h_l} for more verbose help"
    local -r short_help="usage: ${FUNCNAME[0]} [${h_s}|${h2_s}|${h_l}] [${z_s}] [${t_s}] [${a_c}] [${k_c}] [${c_c}] [${r_c}] [${w_c}]"
    local -r long_help="${short_help}${sep}${a_s}: ${a_h}${sep}${k_s}: ${k_h}${sep}${r_s}: ${r_h}${sep}${w_s}: ${w_h}${sep}${c_s}: ${c_h}Some flags are deducable from =*, i.e. =${default_k} is infered as ${k_s} ${default_k} etc"

    while [[ ${#} -gt 0 ]] ; do
        local arg="${1}"
        case "${arg}" in
        --*) # long switches
            case "${arg}" in
            ${a_l}=*) app="${arg#${a_l}=}" ; shift ;;
            ${a_l}) if [[ ${#} -gt 0 ]] ; then
                        app="${2}" ;
                        shift
                    else
                        echo "${a_l} needs an argument" >&2
                        return -1
                    fi
                    app="${2}"
                    shift
                    ;;

            ${k_l}=*) kind="${arg#${k_l}=}" ; shift ;;
            ${k_l}) if [[ ${#} -gt 0 ]] ; then
                        kind="${2}" ;
                        shift
                    else
                        echo "${k_l} needs an argument" >&2
                        return -1
                    fi
                    kind="${2}"
                    shift
                    ;;

            ${c_l}=*) comment="${arg#${c_l}=}" ; shift ;;
            ${c_l}) if [[ ${#} -gt 0 ]] ; then
                        comment="${2}" ;
                        shift
                    else
                        echo "${c_l} needs an argument" >&2
                        return -1
                    fi
                    shift
                    ;;

            ${r_l}=*) attempts=$((0 + ${arg#${r_l}=})) ; shift ;;
            ${r_l}) if [[ ${#} -ge -1 ]] ; then
                        attempts=$((0 + ${2})) ;
                        retry=y
                        shift
                    else
                        echo "${r_l} needs an argument" >&2
                        return -1
                    fi
                    shift
                    ;;

            ${w_l}=*) wait=$((0 + ${arg#${w_l}=})) ; shift ;;
            ${w_l}) if [[ ${#} -gt 0 ]] ; then
                        wait=$((0 + ${2})) ;
                        shift
                    else
                        echo "${w_l} needs an argument" >&2
                        return -1
                    fi
                    wait=$((0 + ${2}))
                    shift
                    ;;

            ${h_l}) echo -e "${long_help}" ; return ;;
            *) echo "Invalid switch '${arg}'" >&2 ; return 1 ;; # bad switch
            esac
        ;;
        # short switches that take args
        ${a_s}) if [[ ${#} -gt 0 ]] ; then
                    app="${2}" ;
                    shift
                else
                    echo "${a_s} needs an argument" >&2
                    return -1
                fi ;;

        ${k_s}) if [[ ${#} -gt 0 ]] ; then
                    kind="${2}" ;
                    shift
                else
                    echo "${k_s} needs an argument" >&2
                    return -1
                fi ;;

        ${c_s}) if [[ ${#} -gt 0 ]] ; then
                    comment="${2}" ;
                    shift
                else
                    echo "${c_s} needs an argument" >&2
                    return -1
                fi ;;

        ${r_s}) if [[ ${#} -gt 1 && "${2}" ]] ; then
                    attempts=$((0 + ${2})) ;
                    retry=y
                    shift
                else
                    echo "${r_s} needs an argument" >&2
                    return -1
                fi ;;

        ${w_s}) if [[ ${#} -gt 0 ]] ; then
                    wait=$((0 + ${2})) ;
                    shift
                else
                    echo "${w_s} needs an argument" >&2
                    return -1
                fi ;;

        -*) # short switches which take no arguments
            arg=${arg:1} # remove leading dash
            while [[ "${arg}" ]] ; do
                case "-${arg:0:1}" in

                ${v_s}) verbosity=$((${verbosity} + 1)) ;;
                ${d_s}) dry_run=yes ;;
                ${z_s}) timestamp_log=yes ; zero_log=yes ;;
                ${t_s}) timestamp_log=yes ;;

                ${h_s}|${h2_s}) echo -e "${short_help}${more_help}" ; return ;;
                *) echo "Invalid switch '${arg}'" >&2 ; return 1 ;; # bad switch
                esac
                arg="${arg:1}"
            done
        ;;
        =*)
            local eq_arg="${arg:1}" # remove leading equals
            if arrayHas "${eq_arg}" "${apps[@]}" ; then
                app="${eq_arg}"
            elif arrayHas "${eq_arg}" "${kinds[@]}" ; then
                kind="${eq_arg}"
            else
                echo "'Equals arg' '${arg}' should be an app or a kind" >&2
                return -1
            fi
        ;;
        *) break ;;
        esac
        shift
    done

    if [[ ${verbosity} -gt 0 ]] ; then
        echo '${app} = '"'${app}'" >&2
        echo '${kind} = '"'${kind}'" >&2
        echo '${comment} = '"'${comment}'" >&2
    fi

    if [[ -z "${app}" ]] ; then
        local RESULT
        RdeduceCurrentApp && app="${RESULT}"
        unset RESULT
    fi

    #Validate args that should be chosen from a list
    if ! arrayHas "${app}" "${apps[@]}" ; then
        echo "Application '${app}' should be one of ${apps_l}" >&2
        return -1
    elif ! arrayHas "${kind}" "${kinds[@]}" ; then
        echo "Log kind '${kind}' should be one of ${kinds_l}" >&2
        return -1
    elif [[ ${attempts} -lt -1 ]] ; then
        echo "Retry attempts '${attempts}' should be a number >= 1" >&2
        return -1
    elif [[ ${wait} -lt 1 ]] ; then
        echo "Retry wait time '${wait}' should be a number of seconds >= -1" >&2
        return -1
    fi

    if [[ ${attempts} -eq 0 ]] ; then
        retry=""
    fi

    [[ "${dry_run}" ]] && return

    #Actually do work
    log="${TEXPERT_HOME}/${app}/log/${kind}.log"
    while [[ ${attempts} -ge -1 ]] ; do
        if [[ -f "${log}" ]] ; then
            # No more retries, found it
            retry=""
            if [[ "${zero_log}" ]] ; then
                echo -n "" > "${log}"
            fi
            if [[ "${timestamp_log}" ]] ; then
                local -r style="$(colour bold fg red)"
                [[ "${zero_log}" ]] && local -r verb="created" || local -r verb="annotated"
                date "+${style}Logfile ${verb} on %c$(colour reset)" >> "${log}"
            fi
            if [[ "${comment}" ]] ; then
                echo "NCE:${comment}" >> "${log}"
            fi
            less -fR '+/^NCE:.*' "${log}"
        fi
        if [[ "${retry}" ]] ; then
            [[ ${attempts} -gt -1 ]] && attempts=$((${attempts} - 1))
            trace sleep ${wait}
        else
            # stop the loop when retry is blank
            break
        fi
    done
}

function __complete_is_app ()
{
    COMPREPLY=()
    local -a RESULT
    __Rapps_list --basename
    local -r CWORD="${COMP_WORDS[${COMP_CWORD}]}"
    COMPREPLY=( $(compgen -W "${RESULT[*]}" -- ${CWORD}) )
    return 0
}

function Rcd ()
{
    local -r app="${1}"
    if [[ "${app}" ]] ; then
        local -r app_dir="${TEXPERT_HOME}/${app}"
        __IsRailsDir "${app_dir}" || return -1
    else
        local -r app_dir="${TEXPERT_HOME}"
    fi
    [[ "${PWD}" == "${app_dir}" ]] || [[ -d "${app_dir}" ]] && trace_eval cd "${app_dir}"
}

[[ -z "${NO_COMPLETE}" ]] && complete -F __complete_is_app Rcd

function RdeduceCurrentApp ()
{
    #assume local RESULT
    RESULT=""
    __realdir .
    RESULT=${RESULT##*/}
    if Rapp_exists ${RESULT} ; then
        return 0
    else
        RESULT=""
        return 1
    fi
}

function Rconsole ()
{
    local app=""
    if [[ ${#} -gt 0 ]] ; then
        local -r app="${1}"
        shift
    else
        local RESULT
        RdeduceCurrentApp && app="${RESULT}"
    fi
    if [[ "${app}" ]] ; then
        Rapp_script "${app}" console "${@}"
    fi
}

[[ -z "${NO_COMPLETE}" ]] && complete -F __complete_is_app Rconsole

function Rdbconsole ()
{
    local app=""
    if [[ ${#} -gt 0 ]] ; then
        local -r app="${1}"
        shift
    else
        local RESULT
        RdeduceCurrentApp && local app="${RESULT}"
    fi
    if [[ "${app}" ]] ; then
        Rapp_script "${app}" dbconsole "${@}"
    fi
}

[[ -z "${NO_COMPLETE}" ]] && complete -F __complete_is_app Rdbconsole

function __add_tests ()
{
    #assume local -a RESULT
    local -i ret=0
    local name
    for name in "${@}" ; do
        local dir
        for dir in unit functional ; do
            local file="test/${dir}/${name}.rb"
            if [[ -f "${file}" ]] ; then
                RESULT[${#RESULT[@]}]="${file}"
                ret=$((${ret} + 1))
                continue
            fi
        done
    done
    return ${ret}
}

function Rut ()
{
    local -r ut_fname="test/unit/${1}.rb"
    shift
    if [[ -d lib ]] ; then
        local lib=":lib"
    else
        local lib=""
    fi
    if [[ -f "${ut_fname}" ]] ; then
        trace Ruby -Itest${lib} "${ut_fname}" "${@}"
    fi
}

function __list_rb_files_in_dir ()
{
    #assume local -a RESULT
    RESULT=()
    local -r d="${1}"
    shift
    __findNamed .rb "${d}"
    local -i i=$((${#RESULT[@]} - 1))
    local f
    while [[ ${i} -ge 0 ]] ; do
        f=${RESULT[${i}]#${d}/}
        f=${f%.*}
        RESULT[${i}]=${f}
        i=$((${i} - 1))
    done
    return
    [[ -d "./${d}" ]] || return -1
    local f
    for f in ${d}/{,*/}*.rb ; do
        if [[ -f "${f}" ]] ; then
            f=${f#${d}/}
            f=${f%.*}
            RESULT[${#RESULT[@]}]=${f}
        fi
    done
}

function __list_unit_test_names ()
{
    #assume local -a RESULT
    RESULT=()
    __list_rb_files_in_dir "test/unit"
}

Rlist_unit_test_names ()
{
    local -a RESULT
    __list_unit_test_names
    listArray --comma ${RESULT[@]}
    unset RESULT
}

function __complete_Rut ()
{
    COMPREPLY=()
    local -a RESULT
    __list_unit_test_names
    local -r CWORD="${COMP_WORDS[${COMP_CWORD}]}"
    COMPREPLY=( $(compgen -W "${RESULT[*]}" -- ${CWORD}) )
    return 0
}

[[ -z "${NO_COMPLETE}" ]] && complete -F __complete_Rut Rut

function Rft ()
{
    local -r ft_fname="test/functional/${1}.rb"
    shift
    if [[ -f "${ft_fname}" ]] ; then
        trace Ruby -Itest "${ft_fname}" "${@}"
    fi
}

function __list_functional_test_names ()
{
    #assume local -a RESULT
    RESULT=()
    __list_rb_files_in_dir "test/functional"
}

Rlist_functional_test_names ()
{
    local -a RESULT
    __list_functional_test_names
    listArray --comma ${RESULT[@]}
    unset RESULT
}

function __complete_Rft ()
{
    COMPREPLY=()
    local -a RESULT
    __list_functional_test_names
    local -r CWORD="${COMP_WORDS[${COMP_CWORD}]}"
    COMPREPLY=( $(compgen -W "${RESULT[*]}" -- ${CWORD}) )
    return 0
}

[[ -z "${NO_COMPLETE}" ]] && complete -F __complete_Rft Rft

function _IsRailsDir ()
{
    local -r d="${1}"
    local p
    for p in REVISION ; do
        if [[ ! -f ${d}/${p} ]] ; then
            return 1
        fi
    done
    #for p in app/views app/controllers app/models app/helpers ; do
    #    if [[ ! -d ${d}/${p} ]] ; then
    #        return 1
    #    fi
    #done
    return 0
}

function __IsRailsDir ()
{
    #assume local -a RESULT=()
    while [[ ${#} -gt 0 ]] ; do
        _IsRailsDir "${1}" && RESULT[${#RESULT[@]}]="${1}"
        shift
    done
}

function __Rapps_list ()
{
    #assume local -a RESULT
    __IsRailsDir ${TEXPERT_HOME}/*
    if [[ "${1}" == "--basename" ]] ; then
        local -i idx=0
        while [[ ${idx} -lt ${#RESULT[@]} ]] ; do
            RESULT[${idx}]=${RESULT[${idx}]##*/}
            idx=$((idx+1))
        done
    fi
}

function Rapps_list ()
{
    local -a RESULT
    __Rapps_list "${@}"
    listArray --comma "${RESULT[@]}"
}

function Rapps_FI ()
{
    local -r f_s="-f"
    local -r f_l="--files"
    local -r f_c="${f_s}|${f_l}"
    local -r f_h="find word in all files"
    local -r s_s="-s"
    local -r s_l="--sources"
    local -r s_c="${s_s}|${s_l}"
    local -r s_h="find word in source files"
    local -r S_s="-S"
    local -r S_l="--sources-and-headers"
    local -r S_c="${S_s}|${S_l}"
    local -r S_h="find word in source & header files"
    local -r H_s="-H"
    local -r H_l="--headers"
    local -r H_c="${H_s}|${H_l}"
    local -r H_h="find word in header files"
    local -r m_s="-m"
    local -r m_l="--markup"
    local -r m_c="${m_s}|${m_l}"
    local -r m_h="find word in markup files"
    local -r M_s="-M"
    local -r M_l="--makefiles"
    local -r M_c="${M_s}|${M_l}"
    local -r M_h="find word in makefile files"
    local -r i_s="-i"
    local -r i_l="--ignore-case"
    local -r i_c="${i_s}|${i_l}"
    local -r i_h="ignore case when searching"
    local -r c_s="-c"
    local -r c_l="--colourise"
    local -r c_c="${c_s}|${c_l}"
    local -r c_h="Colourise the output even if the output is not a tty"
    local -r l_s="-l"
    local -r l_l="--list"
    local -r l_c="${l_s}|${l_l}"
    local -r l_h="Just list the files, not the lines that match"
    local -r L_s="-L"
    local -r L_l="--less"
    local -r L_c="${L_s}|${L_l}"
    local -r L_h="Pass the output results thhrough less"
    local -r z_s="-0"
    local -r z_l="--zero"
    local -r z_c="${z_s}|${z_l}"
    local -r z_h="When used with ${l_c} causes the files names to be separated by NUL characters, not newlines"
    local -r w_s="-w"
    local -r w_l="--whole-words"
    local -r w_c="${w_s}|${w_l}"
    local -r w_h="Match whole words only"

    local -r x_s="-x"
    local -r x_l="--exclude"
    local -r x_c="${x_s} <pattern>|${x_l} <pattern>"
    local -r x_h="Exclude <pattern>"

    local -r P_s="-P"
    local -r P_l="--pruneless"
    local -r P_c="${P_s}|${P_l} "
    local -r P_h="Clear default list of pruned dirs"

    local -r h_s="-h"
    local -r h2_s="-?"
    local -r h_l="--help"
    local -r sep="\n\t\t"
    local -r more_help="${sep}${h_l} for more verbose help"
    local -r short_help="usage: ${FUNCNAME[0]} [${h_s}|${h2_s}|${h_l}] [${f_c}] [${s_c}] [${S_c}] [${H_c}] [${m_c}] [${M_c}] [${i_c}] [${c_c}] [${l_c}] [${x_c}] [${z_c}] [${w_c}] [${P_c}] <word> [<word>...]"
    local -r long_help="${short_help}${sep}${f_c}: ${f_h}${sep}${s_s}: ${s_h}${sep}${H_s}: ${H_h}${sep}${S_s}: ${S_h}${sep}${m_s}: ${m_h}${sep}${M_s}: ${M_h}${sep}${i_s}: ${i_h}${sep}${c_s}: ${c_h}${sep}${l_s}: ${l_h}${sep}${x_s}: ${x_h}${sep}${z_s}: ${z_h}${sep}${w_s}: ${w_h}${sep}${P_s}: ${P_h}"

    local kind=""
    local colour=""
    local ic=""
    local list=""
    local less=""
    local zero=""
    local wholewords=""
    local pruneless=""

    local -a excludes=(-x tags -x '*.log')
    while [[ ${#} -gt 0 ]] ; do
        local arg="${1}"
        case "${arg}" in
        --*) # long switches
            case "${arg}" in
            ${f_l}) kind="" ;;
            ${s_l}) kind=Sources ;;
            ${S_l}) kind=SourcesAndHeaders ;;
            ${H_l}) kind=Headers ;;
            ${m_l}) kind=Markup ;;
            ${i_l}) ic=-i ;;
            ${c_l}) colour=-c ;;
            ${l_l}) list=-l ;;
            ${x_l}) excludes[${#excludes[@]}]="${x_s}" ;
                    excludes[${#excludes[@]}]="${2}" ;
                    shift ;;
            ${L_l}) less=-L ;;
            ${z_l}) zero=-0 ;;
            ${w_l}) wholewords=${w_s} ;;
            ${P_l}) pruneless=${P_s} ;;

            ${h_l}) echo -e "${long_help}" ; return ;;
            *) echo "Invalid switch '${arg}'" >&2 ; return 1 ;; # bad switch
            esac
        ;;
        # short switches that take args
        ${x_s}) excludes[${#excludes[@]}]="${x_s}" ;
                excludes[${#excludes[@]}]="${2}" ;
                shift ;;
        -*) # short switches
            arg=${arg:1} # remove leading dash
            while [[ "${arg}" ]] ; do
                case "-${arg:0:1}" in
                ${f_s}) kind="" ;;
                ${s_s}) kind=Sources ;;
                ${S_s}) kind=SourcesAndHeaders ;;
                ${H_s}) kind=Headers ;;
                ${m_s}) kind=Markup ;;
                ${i_s}) ic=-i ;;
                ${c_s}) colour=-c ;;
                ${l_s}) list=-l ;;
                ${L_s}) less=-L ;;
                ${z_s}) zero=-0 ;;
                ${w_s}) wholewords=${w_s} ;;
                ${P_s}) pruneless=${P_s} ;;

                ${h_s}|${h2_s}) echo -e "${short_help}${more_help}" ; return ;;
                *) echo "Invalid switch '${arg}'" >&2 ; return 1 ;; # bad switch
                esac
                arg="${arg:1}"
            done
        ;;
        *) break ;;
        esac
        shift
    done
    local -a RESULT
    __Rapps_list
    if [[ "${list}" && "${zero}" ]] ; then
        FI${kind} ${pruneless} ${wholewords} ${less} ${list} ${colour} ${ic} ${excludes[@]} "${RESULT[@]}" "${@}" | tr '\012' '\000'
    else
        FI${kind} ${pruneless} ${wholewords} ${less} ${list} ${colour} ${ic} ${excludes[@]} "${RESULT[@]}" "${@}"
    fi
}

function Rapp_each
{
    local -r x_s="-x"
    local -r x_l="--exclude"
    local -r x_c="${x_s} <app>|${x_l} <app>"
    local -r x_h="Exclude <app>"
    local -r k_s="-k"
    local -r k_l="--keep-going"
    local -r k_c="${k_s}|${k_l}"
    local -r k_h="Keep going even if the run command 'fails'"

    local -r h_s="-h"
    local -r h2_s="-?"
    local -r h_l="--help"
    local -r sep="\n\t\t"
    local -r more_help="${sep}${h_l} for more verbose help"
    local -r short_help="usage: ${FUNCNAME[0]} [${h_s}|${h2_s}|${h_l}] [${k_c}] [${x_c}]"
    local -r long_help="${short_help}${sep}${k_c}: ${k_h}"

    local -a exclude=()
    local keepgoing=""
    while [[ ${#} -gt 0 ]] ; do
        case "${1}" in
        -*|=*) # switches
            case "${1}" in
            ${x_s}|${x_l}) exclude[${#exlude[@]}]="${2}" ; shift ;;
            ${k_s}|${k_l}) keepgoing=y ;;

            ${h_s}|${h2_s}) echo -e "${short_help}${more_help}" ; return ;;
            ${h_l}) echo -e "${long_help}" ; return ;;
            *) echo "Invalid switch '${1}'" >&2 ; return 1 ;; # bad switch
            esac
        ;;
        *) break ;;
        esac
        shift
    done

    local -a RESULT
    local -i ret=0
    __Rapps_list
    local d
    for d in "${RESULT[@]}" ; do
        local excluded=0
        local x
        for x in "${exclude[@]}" ; do
            if [[ "${d##*/}" == "${x}" ]] ; then
                excluded=1
                break
            fi
        done
        if [[ ${excluded} -eq 1 ]] ; then
            continue
        fi
        pushd $d >&-
        msg "${d}"
        xtrace_eval =f "${@}"
        ret=${?}
        popd >&-
        if [[ -z "${keepgoing}" && ${ret} -ne 0 ]] ; then
            break
        fi
    done
    return ${ret}
}

function Rrake ()
{
    local -i ret=-1
    local sphinx=0
    local -r current="${TEXPERT_HOME}"
    local app="${1}"
    shift
    if [[ -z "${app}" ]] ; then
        local RESULT
        RdeduceCurrentApp && app="${RESULT}"
        unset RESULT
    fi
    if [[ "${app}" && -d "${current}/${app}" ]] ; then
        pushd "${current}/${app}" >&-
        case "${app}" in
        texpert)
            Rsphinx -q >&-
            sphinx=${?}
            if [[ ${sphinx} -ne 0 ]] ; then
                echo "${app} needs sphinx running, it's not, so it's now being started"
                Rsphinx --start
            fi
        ;;
        esac
        msg "$(pwd)"
        xtrace_eval =f Rake "${@}"
        ret=${?}
        if [[ ${sphinx} -ne 0 ]] ; then
            sphinx=0
            echo "${app} needed sphinx running, it wasn't, it was started, so now it's being stopped"
            Rsphinx --stop
        fi
        popd >&-
    fi
    return ${ret}
}

function Rapps_rake ()
{
    local keepgoing="y"
    local -i RESULT
    __secondsSinceEpoch
    local -r -i start=${RESULT}
    local -i ret=0
    local app
    local -r -a apps_to_rake=(gatekeeper rota texpertise2 ui texpert)
    for app in "${apps_to_rake[@]}" ; do
        Rrake "${app}" "${@}"
        ret=${?}
        if [[ -z "${keepgoing}" && ${ret} -ne 0 ]] ; then
            break
        fi
    done
    __secondsSinceEpoch
    local -r -i end=${RESULT}
    echo "Finished testing $(plural ${#apps_to_rake[@]} app) in $(elapsed $start $end)."
    return ${ret}
}

function Rapps_svn ()
{
    Rapp_each svn "${@}"
}

function Rapps_svn_up ()
{
    Rapps_svn up "${@}"
}

function Rapps_svn_stat ()
{
    Rapps_svn stat "${@}"
}

function Rall_svn_stat ()
{
    local -r t_s="-t"
    local -r t_l="--trim-paths"
    local -r t_c="${t_s}|${t_l}"
    local -r t_h="Trim paths so remove "'${TEXPERT_HOME}'" (${TEXPERT_HOME})"

    local -r u_s="-u"
    local -r u_c="${u_s}"
    local -r u_h="Show what needs updating"

    local -r h_s="-h"
    local -r h2_s="-?"
    local -r h_l="--help"
    local -r sep="\n\t\t"
    local -r more_help="${sep}${h_l} for more verbose help"
    local -r short_help="usage: ${FUNCNAME[0]} [${h_s}|${h2_s}|${h_l}] [${t_c}] [${u_c}]"
    local -r long_help="${short_help}${sep}${t_c}: ${t_h}${sep}${u_c}: ${u_h}"

    local trim_paths=""
    local update=""
    while [[ ${#} -gt 0 ]] ; do
        local arg="${1}"
        case "${arg}" in
        --) shift ; break ;; # no more argument parsing
        --*) # long switches
            case "${arg}" in
            ${t_l}) trim_paths=y ;;

            ${h_l}) echo -e "${long_help}" ; return ;;
            *) echo "Invalid switch '${arg}'" >&2 ; return 1 ;; # bad switch
            esac
        ;;
        # short switches that take args
        # none
        -*) # short switches
            arg=${arg:1} # remove leading dash
            while [[ "${arg}" ]] ; do
                case "-${arg:0:1}" in
                ${t_s}) trim_paths=y ;;
                ${u_s}) update=-u ;;

                ${h_s}|${h2_s}) echo -e "${short_help}${more_help}" ; return ;;
                *) echo "Invalid switch '${arg}'" >&2 ; return 1 ;; # bad switch
                esac
                arg="${arg:1}"
            done
        ;;
        *) break ;;
        esac
        shift
    done

    local -a RESULT=()
    __IsSvnDir ${TEXPERT_HOME}/*
    if [[ "${trim_paths}" ]] ; then
        svn stat ${update} ${RESULT[@]} "${@}" | sed -e "s@${TEXPERT_HOME}/@@g"
    else
        svn stat ${update} ${RESULT[@]} "${@}"
    fi
}

function Rctags ()
{
    local -r temp_tags_file=.tags.new
    ctags -f "${temp_tags_file}" "${@}" && mv "${temp_tags_file}" tags || rm -f "${temp_tags_file}"
}

function Rapps_ctags ()
{
    local -r n_s="-n"
    local -r n_l="--nowait"
    local -r n_c="${n_s}|${n_l}"
    local -r n_h="Do not wait for the background jobs to complete"
    local -r b_s="-b"
    local -r b_l="--background"
    local -r b_c="${b_s}|${b_l}"
    local -r b_h="Run ctags on each app in the background"
    #local -r f_s="-f"
    #local -r f_l="--force"
    #local -r f_c="${f_s}|${f_l}"
    #local -r f_h="Force a new tags file by deleting the old one first"

    local -r h_s="-h"
    local -r h2_s="-?"
    local -r h_l="--help"
    local -r sep="\n\t\t"
    local -r more_help="${sep}${h_l} for more verbose help"
    local -r short_help="usage: ${FUNCNAME[0]} [${h_s}|${h2_s}|${h_l}] [${b_c}] [${n_c}]" #[${f_c}]
    local -r long_help="${short_help}${sep}${b_c}: ${b_h}${sep}${n_c}: ${n_h}" #${sep}${f_c}: ${f_h}"

    local background=""
    local force=""
    local dowait="y"
    while [[ ${#} -gt 0 ]] ; do
        case "${1}" in
        -*|=*) # switches
            case "${1}" in
            ${b_s}|${b_l}) background=y ;;
            #${f_s}|${f_l}) force=y ;;
            ${n_s}|${n_l}) dowait="" ;;

            ${h_s}|${h2_s}) echo -e "${short_help}${more_help}" ; return ;;
            ${h_l}) echo -e "${long_help}" ; return ;;
            *) echo "Invalid switch '${1}'" >&2 ; return 1 ;; # bad switch
            esac
        ;;
        *) break ;;
        esac
        shift
    done

    #if [[ "${force}" ]] ; then
        #Rapp_each rm -f tags
    #fi

    if [[ "${background}" ]] ; then
        local -a RESULT
        __Rapps_list
        local d
        for d in "${RESULT[@]}" ; do
            pushd $d >&-
            msg "$(pwd)"
            msg "Rctags -R"
            #titles both "Rctags -R"
            Rctags -R >&- 2>&- <&- &
            #fake_xterm_title
            popd >&-
        done
        if [[ "${dowait}" ]] ; then
            wait >&- 2>&-
        fi
    else
        Rapp_each Rctags -R
    fi
}

function Rapps_update_test_db ()
{
    Rapp_each -k [[ -f Rakefile ]] \&\& Rake db:test:prepare
}

function Rrake_files ()
{
    #local -a RESULT
    RESULT=()
    local f
    for f in ${TEXPERT_HOME}/*/Rakefile ; do
        [[ -f ${f} ]] && RESULT[${#RESULT[@]}]="${f}"
    done
}

function Rrake_each ()
{
    if [[ ${#RESULT[@]} -eq 0 ]] ; then
        local -a RESULT
        Rrake_files
    fi
    local f
    local d
    for f in ${RESULT[@]} ; do
        d="${f%/*}"
        pushd "${d}" >&-
        msg "${d}"
        xtrace_eval Rake "${@}"
        popd >&-
    done
}

function Rapps_migrate ()
{
    local -i RESULT
    __secondsSinceEpoch
    local -r -i start=${RESULT}
    unset RESULT
    #Rrake_each db:migrate
    Rapp_each --exclude definer --keep-going [[ -f Rakefile ]] \&\& Rake db:migrate
    __secondsSinceEpoch
    local -r -i end=${RESULT}
    echo "Finished raking db:migrate in $(elapsed $start $end)."
}

function Rapp_list_migrations
{
    #assume local -a RESULT
    RESULT=()
    #assume local -r app="${1}"
    local m
    RESULT=($(cd ${TEXPERT_HOME}/${app}/db/migrate ; ls -1 $(date +%Y)*.rb | sed -ne 's@^\([[:digit:]]\{14\}\)_.*@\1@p' | sort -n))
}

function Rapp_migrate ()
{
    local RESULT
    __app_from_arg "${1}"
    [[ "${RESULT}" ]] && local -r app="${RESULT}" || return -1
    unset RESULT
    local version="${2}"
    case "${version}" in
    -*)
        local -a RESULT
        Rapp_list_migrations
        local -r -i n=$((-1+${#RESULT[@]}${version}))
        version=${RESULT[${n}]}
        unset RESULT
    ;;
    esac
    if [[ "${version}" ]] ; then
        version="VERSION=${version}"
    fi
    local -i RESULT
    __secondsSinceEpoch
    local -r -i start=${RESULT}
    unset RESULT
    pushd "${TEXPERT_HOME}/${app}" >&-
    trace Rake db:migrate ${version}
    popd >&-
    __secondsSinceEpoch
    local -r -i end=${RESULT}
    echo "Finished raking db:migrate in $(elapsed $start $end)."
}

function Rcap_dev_do ()
{
    (
        cd ~/src/multistage_management
        xtrace =f cap development "${@}"
    )
}

function Rcapfile_do ()
{
    local -r dir="${HOME}/src/kgb-deploy"
    if [[ ! -d "${dir}" ]] ; then
        echo "Where's your kgb-deploy checkout directory?" >&2
        return -1
    fi

    local -r -x capfile="${1}"

    if [[ -f "${dir}/config/deploy/${capfile}.rb" ]] ; then
        (
            cd "${dir}"
            pwd
            xtrace =f cap ${capfile} "${@}"
        )
    else
        echo "That's odd. The cap-file ${capfile} didn't appear on disk in the cap files" >&2
        return -1
    fi
}

function Rcluster ()
{
    local -r g_s="-g"
    local -r g_l="--geography"
    local -r g_c="${g_s}|${g_l} <geo> or ${g_l}=<geo>"
    local -r -a geographies=(nj ca)
    local -r geos_l=$(listArray --comma "${geographies[@]}")
    local -r g_h="Which geographical location to use (must be one of ${geos_l})"

    local -r c_s="-c"
    local -r c_l="--cluster"
    local -r c_c="${c_s}|${c_l} <cluster> or ${c_l}=<cluster>"
    local -r -a clusters=(kg00 kg01)
    local -r clusters_l=$(listArray --comma "${clusters[@]}")
    local -r c_h="Which cluster to use (must be one of ${clusters_l})"

    local -r -a locales=(us uk)
    local -r locales_l=$(listArray --comma "${locales[@]}")
    local -r l_s="-l"
    local -r l_l="--locale"
    local -r l_c="${l_s}|${l_l} <locale> or ${l_l}=<locale>"
    local -r l_h="Which locality of cluster to use (must be one of ${locales_l})"

    local -r -a kinds=(staging production)
    local -r kinds_l=$(listArray --comma "${kinds[@]}")
    local -r k_s="-k"
    local -r k_l="--kind"
    local -r k_c="${k_s}|${k_l} <cluster> or ${k_l}=<cluster>"
    local -r k_h="Which kind of cluster to use (must be one of ${kinds_l})"

    local -r i_s="-i"
    local -r i_l="--iteration"
    local -r i_c="${i_s}|${i_l} <iteration> or ${i_l}=<iteration>"
    local -r i_h="Which iteration to use"

    local -r -a actions_needing_iteration=(tag deploy)
    local -r -a actions=(tagclean start up stop down bounce switch "${actions_needing_iteration[@]}")
    local -r actions_l=$(listArray --comma "${actions[@]}")
    local -r a_s="-a"
    local -r a_l="--action"
    local -r a_c="${a_s}|${a_l} <action> or ${a_l}=<action>"
    local -r a_h="Which action to perform (must be one of ${actions_l})"

    local -r h_s="-h"
    local -r h2_s="-?"
    local -r h_l="--help"
    local -r sep="\n\t\t"
    local -r more_help="${sep}${h_l} for more verbose help"
    local -r short_help="usage: ${FUNCNAME[0]} [${h_s}|${h2_s}|${h_l}] [${g_c}] [${c_c}] [${i_c}] [${k_c}] [${l_c}] ${a_c}"
    local -r long_help="${short_help}${sep}${g_c}: ${g_h}${sep}${c_s}: ${c_h}${sep}${i_s}: ${i_h}${sep}${k_s}: ${k_h}${sep}${l_s}: ${l_h}${sep}${a_s}: ${a_h}${sep}${sep}Some flags are deducable from =*, i.e. =bounce is infered as -a bounce etc"

    local geography="nj"
    local kind=""
    local cluster=""
    local action=""
    local iteration=""
    local locale=""
    while [[ ${#} -gt 0 ]] ; do
        local arg="${1}"
        case "${arg}" in
        --*) # long switches
            case "${arg}" in
            ${k_l}=*) kind="${arg#${k_l}=}" ; shift ;;
            ${k_l}) if [[ ${#} -gt 0 ]] ; then
                        kind="${2}" ;
                        shift
                    else
                        echo "${k_l} needs an argument" >&2
                        return -1
                    fi
                    kind="${2}"
                    shift
                    ;;

            ${a_l}=*) action="${arg#${a_l}=}" ; shift ;;
            ${a_l}) if [[ ${#} -gt 0 ]] ; then
                        action="${2}" ;
                        shift
                    else
                        echo "${a_l} needs an argument" >&2
                        return -1
                    fi
                    action="${2}"
                    shift
                    ;;

            ${i_l}=*) iteration="${arg#${i_l}=}" ; shift ;;
            ${i_l}) if [[ ${#} -gt 0 ]] ; then
                        iteration="${2}" ;
                        shift
                    else
                        echo "${i_l} needs an argument" >&2
                        return -1
                    fi
                    iteration="${2}"
                    shift
                    ;;

            ${g_l}=*) geography="${arg#${g_l}=}" ; shift ;;
            ${g_l}) if [[ ${#} -gt 0 ]] ; then
                        geography="${2}" ;
                        shift
                    else
                        echo "${g_l} needs an argument" >&2
                        return -1
                    fi
                    geography="${2}"
                    shift
                    ;;

            ${c_l}=*) cluster="${arg#${c_l}=}" ; shift ;;
            ${c_l}) if [[ ${#} -gt 0 ]] ; then
                        cluster="${2}" ;
                        shift
                    else
                        echo "${c_l} needs an argument" >&2
                        return -1
                    fi
                    cluster="${2}"
                    shift
                    ;;

            ${l_l}=*) locale="${arg#${l_l}=}" ; shift ;;
            ${l_l}) if [[ ${#} -gt 0 ]] ; then
                        locale="${2}" ;
                        shift
                    else
                        echo "${l_l} needs an argument" >&2
                        return -1
                    fi
                    locale="${2}"
                    shift
                    ;;

            ${h_l}) echo -e "${long_help}" ; return ;;
            *) echo "Invalid switch '${arg}'" >&2 ; return 1 ;; # bad switch
            esac
        ;;
        # short switches that take args
        ${k_s}) if [[ ${#} -gt 0 ]] ; then
                    kind="${2}" ;
                    shift
                else
                    echo "${k_s} needs an argument" >&2
                    return -1
                fi ;;

        ${a_s}) if [[ ${#} -gt 0 ]] ; then
                    action="${2}" ;
                    shift
                else
                    echo "${a_s} needs an argument" >&2
                    return -1
                fi ;;

        ${i_s}) if [[ ${#} -gt 0 ]] ; then
                    iteration="${2}" ;
                    shift
                else
                    echo "${i_s} needs an argument" >&2
                    return -1
                fi ;;

        ${g_s}) if [[ ${#} -gt 0 ]] ; then
                    geography="${2}" ;
                    shift
                else
                    echo "${g_s} needs an argument" >&2
                    return -1
                fi ;;

        ${c_s}) if [[ ${#} -gt 0 ]] ; then
                    cluster="${2}" ;
                    shift
                else
                    echo "${c_s} needs an argument" >&2
                    return -1
                fi ;;

        ${l_s}) if [[ ${#} -gt 0 ]] ; then
                    locale="${2}" ;
                    shift
                else
                    echo "${l_s} needs an argument" >&2
                    return -1
                fi ;;

        -*) # short switches which take no arguments
            arg=${arg:1} # remove leading dash
            while [[ "${arg}" ]] ; do
                case "-${arg:0:1}" in

                ${h_s}|${h2_s}) echo -e "${short_help}${more_help}" ; return ;;
                *) echo "Invalid switch '${arg}'" >&2 ; return 1 ;; # bad switch
                esac
                arg="${arg:1}"
            done
        ;;
        =*)
            local eq_arg="${arg:1}" # remove leading equals
            if arrayHas "${eq_arg}" "${kinds[@]}" ; then
                kind="${eq_arg}"
            elif arrayHas "${eq_arg}" "${actions[@]}" ; then
                action="${eq_arg}"
            elif arrayHas "${eq_arg}" "${clusters[@]}" ; then
                cluster="${eq_arg}"
            elif arrayHas "${eq_arg}" "${geographies[@]}" ; then
                geography="${eq_arg}"
            elif arrayHas "${eq_arg}" "${locales[@]}" ; then
                locale="${eq_arg}"
            else
                echo "'Equals arg' '${arg}' should be an action" >&2
                return -1
            fi
        ;;
        *) break ;;
        esac
        shift
    done

    # Do some deducing of unspecified parameters
    case "${locale}" in
    uk) # regardless of staging / production
        [[ "${geography}" ]] || geography=nj
        [[ "${cluster}" ]] || cluster=kg01
        [[ "${kind}" ]] || kind=production
    ;;
    us) # sort out staging / production
        [[ "${geography}" ]] || geography=ca
        [[ "${cluster}" ]] || cluster=kg00
    ;;
    esac

    if [[ -z "${geography}" ]] ; then
        echo "Geography wasn't specified (should be one of ${geos_l})" >&2
        return -1
    elif ! arrayHas "${geography}" "${geographies[@]}" ; then
        echo "Geography '${geography}' should be one of ${geos_l}" >&2
        return -1
    fi

    if [[ -z "${cluster}" ]] ; then
        echo "Cluster wasn't specified (should be one of ${clusters_l})" >&2
        return -1
    elif ! arrayHas "${cluster}" "${clusters[@]}" ; then
        echo "Cluster '${cluster}' should be one of ${clusters_l}" >&2
        return -1
    fi

    #echo '${geography} = '"'${geography}'"
    #echo '${kind} = '"'${kind}'"
    #echo '${cluster} = '"'${cluster}'"
    #echo '${action} = '"'${action}'"
    #echo '${iteration} = '"'${iteration}'"
    #echo '${locale} = '"'${locale}'"

    if ! arrayHas "${action}" "${actions[@]}" ; then
        echo "Action '${action}' should be one of ${actions_l}" >&2
        return -1
    elif arrayHas "${action}" "${actions_needing_iteration[@]}" ; then
        if [[ "${ALLOW_DEPLOY_TRUNK}" && "${action}" == "deploy" ]] ; then
            echo "Action '${action}' only requires an iteration specified when "'${ALLOW_DEPLOY_TRUNK} isn'"'t set" >&2
        elif [[ -z "${iteration}" ]] ; then
            echo "Action '${action}' requires an iteration specified too" >&2
            return -1
        else
            local -r -x ITERATION="${iteration}"
            echo "Set ITERATION to '${iteration}'"
        fi
    fi

    if ! arrayHas "${kind}" "${kinds[@]}" ; then
        echo "Kind '${kind}' should be one of ${kinds_l}" >&2
        return -1
    fi

    if ! arrayHas "${locale}" "${locales[@]}" ; then
        echo "Locale '${locale}' should be one of ${locales_l}" >&2
        return -1
    fi

    case ${action} in
    tag) action=kgb:tag:create ;;
    tagclean) action=kgb:tag:cleanup ;;
    deploy) action=kgb:deploy ;;
    start|up) action=kgb:up ;;
    stop|down) action=kgb:down ;;
    bounce) action=kgb:restart ;;
    switch) action=kgb:switch ;;
    esac

    Rcapfile_do ${geography}_${locale}_${cluster} ${action}
}

function Rstaging ()
{
    Rcluster =nj =kg01 =staging =us "${@}"
}

function RUK ()
{
    Rcluster =nj =kg01 =uk "${@}"
}

function Rapps_stop ()
{
    Rapps_mongrels --stop
    Rsphinx --stop
}

function Rcap_stop ()
{
    Rcap_dev_do kgb:daemon_control:stop "${@}"
}

function Rcap_start ()
{
    trace rm -f ${TEXPERT_HOME}/*/log/development.log
    Rcap_dev_do kgb:daemon_control:start "${@}"
}

function Rapps_start ()
{
    trace rm -f ${TEXPERT_HOME}/*/log/development.log
    Rapps_mongrels --start
    Rsphinx --start
}

function Rmongrel_rails
{
    local -r ruby=$(which ruby)
    #local -r ruby=${RUBY_ENTERPRISE_EDITION}/bin/ruby
    local -r mongrel_rails=${RUBY_MONGREL_RAILS} # $(which mongrel_rails)
    xtrace =f "${ruby}" "${mongrel_rails}" "${@}"
}

function Rcluster_action
{
    local -r action="${1}"
    shift
    if [[ "${action}" == restart ]] ; then
        Rmongrel_rails cluster::stop "${@}"
        trace sleep 2
        Rmongrel_rails cluster::start "${@}"
    else
        Rmongrel_rails cluster::${action} "${@}"
    fi
}

function Rapps_mongrels ()
{
    local -r -a actions=(start stop restart query)
    local -r actions_l=$(listArray --comma "${actions[@]}")
    local -r r_s="-r"
    local -r r_l="--restart"
    local -r r_c="${r_s}|${r_l}"
    local -r r_h="Restart the mongrels"
    local -r s_s="-s"
    local -r s_l="--start"
    local -r s_c="${s_s}|${s_l}"
    local -r s_h="Start the mongrels"
    local -r S_s="-S"
    local -r S_l="--stop"
    local -r S_c="${S_s}|${S_l}"
    local -r S_h="Stop the mongrels"
    local -r q_s="-q"
    local -r q_l="--query"
    local -r q_c="${q_s}|${q_l}"
    local -r q_h="Query the mongrels"

    local -r h_s="-h"
    local -r h2_s="-?"
    local -r h_l="--help"
    local -r sep="\n\t\t"
    local -r more_help="${sep}${h_l} for more verbose help"
    local -r short_help="usage: ${FUNCNAME[0]} [${h_s}|${h2_s}|${h_l}] [${s_c}] [${S_c}] [${r_c}] [${q_c}]"
    local -r long_help="${short_help}${sep}${s_c}: ${s_h}${sep}${S_c}: ${S_h}${sep}${r_c}: ${r_h}${sep}${q_c}: ${q_h}"

    local action=""
    while [[ ${#} -gt 0 ]] ; do
        case "${1}" in
        -*|=*) # switches
            case "${1}" in
            ${s_s}|${s_l}) action="start" ;;
            ${S_s}|${S_l}) action="stop" ;;
            ${r_s}|${r_l}) action="restart" ;;
            ${q_s}|${q_l}) action="query" ;;

            =*) local post_eq="${1#=}"
                if arrayHas "${post_eq}" "${actions[@]}" ; then
                    action="${post_eq}"
                fi ;;

            ${h_s}|${h2_s}) echo -e "${short_help}${more_help}" ; return ;;
            ${h_l}) echo -e "${long_help}" ; return ;;
            *) echo "Invalid switch '${1}'" >&2 ; return 1 ;; # bad switch
            esac
        ;;
        *) break ;;
        esac
        shift
    done

    [[ "${action}" ]] || return 1

    local -r base=config/mongrel_cluster
    local -r cfg="${base}.yml"
    local -r dev_cfg="${base}_development.yml"
    local -a RESULT=("${@}")
    [[ ${#RESULT[@]} -gt 0 ]] || __Rapps_list --basename
    local app
    local d
    for app in "${RESULT[@]}" ; do
        d="${TEXPERT_HOME}/${app}"
        local c=""
        if [[ -e "${d}/${dev_cfg}" ]] ; then
            c="${dev_cfg}"
        elif [[ -e "${d}/${cfg}" ]] ; then
            c="${cfg}"
        fi
        if [[ "${c}" ]] ; then
            pushd "${d}" >&-
            case "${action}" in
            query)
                #msg "${d}"
                if Rarunning "${app}" ; then
                    echo "Mongrel for app ${app} is running"
                else
                    echo "Mongrel for app ${app} not running"
                fi
            ;;

            restart)
                msg "${d}"
                if Rarunning "${app}" ; then
                    Rcluster_action stop --config "${c}"
                fi
                Rcluster_action start --config "${c}"
            ;;

            start)
                if Rarunning "${app}" ; then
                    echo "Mongrel for app ${app} already running"
                else
                    msg "${d}"
                    Rcluster_action ${action} --config "${c}"
                fi
            ;;

            stop)
                if Rarunning "${app}" ; then
                    msg "${d}"
                    Rcluster_action ${action} --config "${c}"
                else
                    echo "Mongrel for app ${app} not running"
                fi
            ;;
            esac
            popd >&-
        fi
    done
}

function Rcap_update ()
{
    Rcap_stop
    Rapps_svn_up --non-interactive
    Rapps_ctags --background --nowait #--force 
    Rcap_dev_do kgb:migrate
    Rapps_rake db:test:prepare
    # RAILS_ENV=development Rapps_migrate
    wait >&- 2>&-
}

function Rapps_update ()
{
    Rapps_stop #Rcap_stop
    Rapps_svn_up --non-interactive
    Rapps_ctags --background --nowait #--force 
    Rcap_dev_do kgb:migrate
    Rapps_rake db:test:prepare
    # RAILS_ENV=development Rapps_migrate
    wait >&- 2>&-
}

function Rcap_restart ()
{
    Rcap_stop
    Rcap_start
}

function Rmongrel
{
    #Mixed args
    #Arg with param choices from an array
    #( these work great with = switch handling: find =<something> and <something> is one
    #  of the values in an array, then pretend --arg=<someting> was appropriately supplied )
    local -r -a actions=(start stop restart)
    local -r actions_l=$(listArray --comma "${actions[@]}")
    local -r a_s="-a"
    local -r a_l="--action"
    local -r a_c="${a_s}|${a_l} <action> or ${a_l}=<action>"
    local -r a_h="Which action to perform (must be one of ${actions_l})"
    local action=""

    local -r -a booleans=(y n yes no)
    local -r booleans_l=$(listArray --comma "${booleans[@]}")
    local -r D_s="-D"
    local -r D_l="--delete-pid-files"
    local -r D_c="${D_s}|${D_l} <choice> or ${D_l}=<choice>"
    local -r D_h="Whether to delete the pid files before starting a new mongrel (must be one of ${booleans_l})"
    local delete_pid_files="y"

    #Solo args
    local -r v_s="-v"
    local -i verbosity=0
    local -r d_s="-d"
    local dry_run=""

    #Standard helper args
    local -r h_s="-h"
    local -r h2_s="-?"
    local -r h_l="--help"
    local -r sep="\n\t\t"
    local -r more_help="${sep}${h_l} for more verbose help"
    local -r short_help="usage: ${FUNCNAME[0]} [${h_s}|${h2_s}|${h_l}] [${a_c}] [${D_c}] [application name]"
    local -r long_help="${short_help}${sep}${a_s}: ${a_h}${sep}${D_s}: ${D_h}${sep}Some flags are deducable from =*, i.e. =start is infered as -a start etc${sep}application name, if missing, is deduced from current directory"

    while [[ ${#} -gt 0 ]] ; do
        local arg="${1}"
        case "${arg}" in
        --*) # long switches
            case "${arg}" in
            ${a_l}=*) action="${arg#${a_l}=}" ; shift ;;
            ${a_l}) if [[ ${#} -gt 0 ]] ; then
                        action="${2}" ;
                        shift
                    else
                        echo "${a_l} needs an argument" >&2
                        return -1
                    fi
                    action="${2}"
                    shift
                    ;;

            ${D_l}=*) delete_pid_files="${arg#${D_l}=}" ; shift ;;
            ${D_l}) if [[ ${#} -gt 0 ]] ; then
                        delete_pid_files="${2}" ;
                        shift
                    else
                        echo "${D_l} needs an argument" >&2
                        return -1
                    fi
                    delete_pid_files="${2}"
                    shift
                    ;;

            ${h_l}) echo -e "${long_help}" ; return ;;
            *) echo "Invalid switch '${arg}'" >&2 ; return 1 ;; # bad switch
            esac
        ;;
        # short switches that take args
        ${a_s}) if [[ ${#} -gt 0 ]] ; then
                    action="${2}" ;
                    shift
                else
                    echo "${i_s} needs an argument" >&2
                    return -1
                fi ;;

        -*) # short switches which take no arguments
            arg=${arg:1} # remove leading dash
            while [[ "${arg}" ]] ; do
                case "-${arg:0:1}" in

                ${d_s}) dry_run=yes ;;

                ${v_s}) verbosity=$((${verbosity} + 1)) ;;
                ${d_s}) dry_run=yes ;;

                ${h_s}|${h2_s}) echo -e "${short_help}${more_help}" ; return ;;
                *) echo "Invalid switch '${arg}'" >&2 ; return 1 ;; # bad switch
                esac
                arg="${arg:1}"
            done
        ;;
        =*)
            local eq_arg="${arg:1}" # remove leading equals
            if arrayHas "${eq_arg}" "${actions[@]}" ; then
                action="${eq_arg}"
            else
                echo "'Equals arg' '${arg}' should be an action" >&2
                return -1
            fi
        ;;
        *) break ;;
        esac
        shift
    done

    if [[ ${verbosity} -gt 0 ]] ; then
        echo '${action} = '"'${action}'" >&2
    fi

    #Validate args that should be chosen from a list
    if ! arrayHas "${action}" "${actions[@]}" ; then
        echo "Action '${action}' should be one of ${actions_l}" >&2
        return -1
    fi

    [[ "${dry_run}" ]] && return

    local RESULT
    __app_from_arg "${1}" || return -1
    local -r app="${RESULT}"
    shift
    unset RESULT
    if Rapp_exists "${app}" ; then
        local yml
        local -r r="config/mongrel_cluster"
        if [[ "${RAILS_ENV}" ]] ; then
            if [[ -e "${TEXPERT_HOME}/${app}/${r}_${RAILS_ENV}.yml" ]] ; then
                msg Using RAIL_ENV=${RAILS_ENV}
                yml="${r}_${RAILS_ENV}.yml"
            else
                msg Invalid RAIL_ENV=${RAILS_ENV}
                return 1
            fi
        else
            if [[ -e "${TEXPERT_HOME}/${app}/${r}_development.yml" ]] ; then
                msg Defaulting to development environment
                yml="${r}_development.yml"
            else
                msg Using default environment
                yml="${r}.yml"
            fi
        fi
        if [[ -e "${TEXPERT_HOME}/${app}/${yml}" ]] ; then
            pushd "${TEXPERT_HOME}/${app}" >&-
            pwd
            Rcluster_action ${action} --config "${yml}" "${@}"
            popd >&-
        fi
    fi
}

function Rapp_restart ()
{
    Rmongrel stop "${1}"
    Rmongrel start "${1}"
}

#function __std_app_port ()
#{
#    #assum local -i RESULT
#    case "${1}" in
#    texpert) RESULT=3000 ;;
#    rota) RESULT=3001 ;;
#    texpertise2) RESULT=3002 ;;
#    gatekeeper) RESULT=3003 ;;
#    definer) RESULT=3013 ;;
#    shifty) RESULT=3014 ;;
#    ui) RESULT=4000 ;;
#    texpert-report) RESULT=3100 ;;
#    rota-report) RESULT=3101 ;;
#    gatekeeper-test) RESULT=3103 ;;
#    *) RESULT=-1 ;;
#    esac
#}

#function Rapp_launch ()
#{
#    local RESULT
#    __app_from_arg "${1}" || return -1
#    local -r app="${RESULT}"
#    unset RESULT
#    local -i RESULT=-1
#    __std_app_port "${app}" || return -1
#    local -i -r port=${RESULT}
#    local -r m=log/mongrel.${port}
#    local -r pid_file=${m}.pid
#    local -r log_file=${m}.log
#    local -x -r RAILS_ENV=development
#    local -r daemon=-d
#    if Rarunning "${app}" ; then
#        echo "Application ${app} already running"
#    else
#        pushd ${TEXPERT_HOME}/${app} >&-
#        Rmongrel_rails start ${daemon} -e ${RAILS_ENV} -a 127.0.0.1 -p ${port} -P ${pid_file} -l ${log_file}
#        popd >&-
#    fi
#}

#function Rapps_launch ()
#{
#    Rapp_each Rapp_launch
#}

unset __std_app_port
unset Rapp_launch
unset Rapps_launch

function Rlocale ()
{
    local RESULT # used when calling things like __realdir
    local -r q_s="-q"
    local -r q_l="--query"
    local -r q_c="${q_s}|${q_l}"
    local -r q_h="simply query which locale is 'in effect'"
    local -r f_s="-f"
    local -r f_l="--force"
    local -r f_c="${f_s}|${f_l}"
    local -r f_h="force the switch even if the specified locale is already 'in effect'"
    local -r c_s="-c"
    local -r c_l="--clean"
    local -r c_c="${c_s}|${c_l}"
    local -r c_h="clean all apps of non-svn files between locale switches"
    local -r s_s="-s"
    local -r s_l="--stop"
    local -r s_c="${s_s}|${s_l}"
    local -r s_h="stop all apps before switching locales"
    local -r r_s="-r"
    local -r r_l="--restart"
    local -r r_c="${r_s}|${r_l}"
    local -r r_h="restart all apps afterwards"
    local -r S_s="-S"
    local -r S_l="--stop-restart"
    local -r S_c="${S_s}|${S_l}"
    local -r S_h="${s_h} & then ${r_h}"
    local -r u_s="-u"
    local -r u_l="--usual"
    local -r u_c="${u_s}|${u_l}"
    local -r u_h="Do the usual thing (i.e. ${S_l})"

    local -r h_s="-h"
    local -r h2_s="-?"
    local -r h_l="--help"
    local -r sep="\n\t\t"
    local -r more_help="${sep}${h_l} for more verbose help"
    local -r short_help="usage: ${FUNCNAME[0]} [${h_s}|${h2_s}|${h_l}] [${q_c}] [${f_c}] [${u_c}] [${c_c}] [${S_c}] [${s_c}] [${r_c}] <locale>"
    local -r long_help="${short_help}${sep}${u_c}: ${u_h}${sep}${c_c}: ${c_h}${sep}${s_c}: ${s_h}${sep}${S_c}: ${S_h}${sep}${f_c}: ${f_h}${sep}${q_c}: ${q_h}${sep}${r_c}: ${r_h}"

    local query=""
    local force=""
    local stop_first=""
    local restart_after=""
    local svn_clean=""
    while [[ ${#} -gt 0 ]] ; do
        local arg="${1}"
        case "${arg}" in
        --*) # long switches
            case "${arg}" in
            ${q_l}) query=y ;;
            ${f_l}) force=y ;; # force the change even if the current locale already is the specified one
            ${u_l}) restart_after=y; stop_first=y ;;
            ${c_l}) svn_clean=y ;;
            ${r_l}) restart_after=y ;;
            ${S_l}) restart_after=y # stop first, restart afterwards
                    stop_first=y ;; # stop first
            ${s_l}) stop_first=y ;; # stop first

            ${h_l}) echo -e "${long_help}" ; return ;;
            *) echo "Invalid switch '${arg}'" >&2 ; return 1 ;; # bad switch
            esac
        ;;
        # short switches that take args
        -*) # short switches
            arg=${arg:1} # remove leading dash
            while [[ "${arg}" ]] ; do
                case "-${arg:0:1}" in
                ${q_s}) query=y ;;
                ${f_s}) force=y ;; # force the change even if the current locale already is the specified one
                ${u_s}) restart_after=y; stop_first=y ;;
                ${c_s}) svn_clean=y ;;
                ${r_s}) restart_after=y ;;
                ${S_s}) restart_after=y # stop first, restart afterwards
                        stop_first=y ;; # stop first
                ${s_s}) stop_first=y ;; # stop first

                ${h_s}|${h2_s}) echo -e "${short_help}${more_help}" ; return ;;
                *) echo "Invalid switch '${arg}'" >&2 ; return 1 ;; # bad switch
                esac
                arg="${arg:1}"
            done
        ;;
        *) break ;;
        esac
        shift
    done
    local -r locale="${1}"
    local -r dir="${TEXPERT_HOME}/shared_plugins/shared_config/locales"
    local -r current="${dir}/current"
    if [[ -h "${current}" && ( -z "${force}" || "${query}" ) ]] ; then
        __realdir "${current}"
        local -r current_links_to="${RESULT}"
    fi
    if [[ "${query}" ]] ; then
        if [[ -d "${current_links_to}" ]] ; then
            echo "The current locale in effect is ${current_links_to##*/}"
        else
            echo "There is no locale currently in effect"
        fi
        return
    elif [[ -z "${locale}" ]] ; then
        echo "I need a locale" >&2
        return
    fi
    if [[ -d "${dir}/${locale}" ]] ; then
        if [[ -h "${current}" && -z "${force}" ]] ; then
            __realdir "${dir}/${locale}"
            local -r realdir_of_requested="${RESULT}"
            if [[ "${realdir_of_requested}" == "${current_links_to}" ]] ; then
                echo "Locale '${locale}' already in effect and ${f_c} not supplied"
                return
            fi
        fi
        [[ "${stop_first}" ]] && Rcap_stop
        if [[ -h "${current}" ]] ; then
            trace unlink "${current}"
        fi
        pushd "${dir}" >&-
        msg ${PWD}
        trace ln -s "${locale}" current
        popd >&-
        if [[ "${svn_clean}" ]] ; then
            pushd ${TEXPERT_HOME} >&-
            msg Cleaning non-svn files
            SvnClean -a *
            popd >&-
        fi
        [[ "${restart_after}" ]] && Rcap_start
        return 0
    else
        echo "Locale '${1}' doesn't exist" >&2
        return 1
    fi
}

function Rsphinx
{
    local -r q_s="-q"
    local -r q_l="--query"
    local -r q_c="${q_s}|${q_l}"
    local -r q_h="Query the running state of the Sphinx daemon"
    local -r s_s="-s"
    local -r s_l="--stop"
    local -r s_c="${s_s}|${s_l}"
    local -r s_h="Stop Sphinx daemon"
    local -r S_s="-S"
    local -r S_l="--start"
    local -r S_c="${S_s}|${S_l}"
    local -r S_h="Start Sphinx daemon"

    local -r h_s="-h"
    local -r h2_s="-?"
    local -r h_l="--help"
    local -r sep="\n\t\t"
    local -r more_help="${sep}${h_l} for more verbose help"
    local -r short_help="usage: ${FUNCNAME[0]} [${h_s}|${h2_s}|${h_l}] [${q_c}] [${s_c}] [${S_c}] <locale>"
    local -r long_help="${short_help}${sep}${q_c}: ${q_h}${sep}${s_c}: ${s_h}${sep}${S_c}: ${S_h}"

    local -r texpert="${TEXPERT_HOME}/texpert"
    local action="start"
    local description="Starting"
    while [[ ${#} -gt 0 ]] ; do
        local arg="${1}"
        case "${arg}" in
        --*) # long switches
            case "${arg}" in
            ${s_l}) action=stop ; description=Stopping ;;
            ${S_l}) action=start ; description=Starting ;;
            ${q_l}) action=query ;;

            ${h_l}) echo -e "${long_help}" ; return ;;
            *) echo "Invalid switch '${arg}'" >&2 ; return 1 ;; # bad switch
            esac
        ;;
        -*) # short switches
            arg=${arg:1} # remove leading dash
            while [[ "${arg}" ]] ; do
                case "-${arg:0:1}" in
                ${s_s}) action=stop ; description=Stopping ;;
                ${S_s}) action=start ; description=Starting ;;
                ${q_s}) action=query ;;

                ${h_s}|${h2_s}) echo -e "${short_help}${more_help}" ; return ;;
                *) echo "Invalid switch '-${arg}'" >&2 ; return 1 ;; # bad switch
                esac
                arg="${arg:1}"
            done
        ;;
        *) break ;;
        esac
        shift
    done

    local -r conf_file="${texpert}/config/sphinx.conf"
    local -r pid_file=$(awk 'BEGIN{inside=0};/^searchd/{inside=1};/pid_file/{if(inside==1){print $3}};/^}/{inside=0}' < "${conf_file}")
    local -i pid=-1
    [[ -f ${pid_file} ]] && pid=$(cat "${pid_file}")

    local -r f=./daemons/sphinx_control
    case "${action}" in
    query)
        if [[ ${pid} -gt 0 ]] ; then
            if Rpid_exists ${pid} ; then
                [[ -t 1 ]] && echo "Sphinx process appears to be running"
                return 0
            else
                [[ -t 1 ]] && echo "Sphinx process has pid file, but process ${pid} isn't running"
            fi
        else
            [[ -t 1 ]] && echo "No pid file present to Sphinx not running"
        fi
        return 1
    ;;

    start)
        if [[ ${pid} -gt 0 ]] ; then
            if Rpid_exists ${pid} ; then
                return 0
            fi
        fi
        if [[ -f "${texpert}/${f}" ]] ; then
            pushd "${texpert}" >&-
            [[ -t 1 ]] && echo "${description} Sphinx daemon"
            ${f} ${action}
            popd >&-
        fi
    ;;

    stop)
        if [[ ${pid} -gt 0 ]] ; then
            if Rpid_exists ${pid} ; then
                if [[ -f "${texpert}/${f}" ]] ; then
                    pushd "${texpert}" >&-
                    [[ -t 1 ]] && echo "${description} Sphinx daemon"
                    ${f} ${action}
                    popd >&-
                fi
            fi
        fi
    ;;
    esac
}

function Rset_class_caching ()
{
    __need_args ${#} == 1 "<want>" || return 1
    local -r want="${1}"
    case "${want}" in
    false) local -r was=true ;;
    true) local -r was=false ;;
    *) echo "Invalid 'want' '${want}'" >&2 ; return 1 ;;
    esac
    local -r -a files=(${TEXPERT_HOME}/*/config/environments/development.rb)
    perl -pi -e 's/^(\s*config\.cache_classes\s+=\s+)'"${was}"'(.*$)/$1'"${want}"'$2/' "${files[@]}"
}

function setTexpertsHome ()
{
    local RESULT
    __realdir "${HOME}/deploy/current"
    export TEXPERT_HOME="${RESULT}"
}

setTexpertsHome

function ff-selenium ()
{
    ff-p ~/seleniumtemplate
}

function pg_query ()
{
    __need_args ${#} \> 3 "<limit> <reviews_count> <action> <desc>" || return 1
    local -i -r limit=${1}
    shift
    local -i -r reviews_count=${1}
    shift
    local -r action=${1}
    shift
    local -r desc="${@}"
    echo -n "SELECT estdate(recruitment_logs.created_at) AS 'Date', COUNT(*) AS '${desc}' FROM recruitment_logs JOIN texperts WHERE texperts.id = recruitment_logs.texpert_id AND texperts.do_more_reviews_count = ${reviews_count} AND recruitment_logs.action = '${action}' GROUP BY 1 ORDER BY 1 DESC LIMIT ${limit}; "
}

function pg_yesterday ()
{
    echo -n 'SELECT t.login AS "Candidate Login", COUNT(tms.id) AS "Playground Questions Taken Yesterday", estdate(im.created_at) AS "Date" '
    echo -n 'FROM training_message_statuses AS tms '
    echo -n 'JOIN education_incoming_messages AS eim ON tms.education_incoming_message_id = eim.id '
    echo -n 'JOIN incoming_messages AS im ON tms.incoming_message_id = im.id '
    echo -n 'JOIN texperts AS t ON tms.texpert_id = t.id '
    echo -n 'WHERE estdate(im.created_at) = estyesterday() '
    echo -n 'AND eim.training_module_id = 27 '
    echo -n 'GROUP BY t.login ASC; '
}

function pg_queries ()
{
    __need_args ${#} == 1 "<limit>" || return 1
    local -i -r limit=${1}
    shift
    pg_query ${limit} 0 'successful_candidate_review' 'Passed Certification on 1st attempt'
    pg_query ${limit} 0 'failed_candidate_review' 'Failed Certification on 1st attempt'
    pg_query ${limit} 1 'pooled_for_registration' 'Passed Certification on 2nd attempt'
    pg_query ${limit} 1 'deactivated' 'Failed Certification on 2nd attempt'
    pg_query ${limit} 1 'expired' 'Expired - never attempted 2nd chance'
}

function Rapp_rexec ()
{
    local local_first="n"
    if [[ "${1}" == "--local-first" ]] ; then
        local_first="y"
        shift
    fi
    if [[ -f "${1}" ]] ; then
        local -r dev_home="${HOME}/deploy/releases/development/"
        local script=$(realpath "${1}")
        local app=${script#${dev_home}}
        app=${app%%/*}
        script=${script#${dev_home}}
        script=${script#${app}/}
        local -r host=kg00-s00045
        local -r dest=/data/${app}/current
        local -r cmd="ruby ${script}"
        local -x required_rails_env=slave
        if [[ "${local_first}" == y ]] ; then
            [[ -d "${dev_home}${app}" ]] && ( cd "${dev_home}${app}" && [[ -f "${script}" ]] && trace ${cmd} ; exit ${?} )
            [[ ${?} -ne 0 ]] && return
        fi
        if trace rsync -ac --rsh=ssh ~/deploy/current-${app}/${script} ${host}:${dest}/${script} ; then
            trace ssh -t ${host} "[[ -d '${dest}' ]] && cd ${dest} && [[ -f '${script}' ]] && echo 'RAILS_ENV=${required_rails_env} ${cmd}' && RAILS_ENV=${required_rails_env} ${cmd}"
        fi
    fi
}

function Rrexec ()
{
    __need_args ${#} \> 4 "<cluster> <geography> <kind> <number>" || return 1
    local -r cluster="${1}"
    shift
    local -r geography="${1}"
    shift
    local -r kind="${1}"
    shift
    local -i -r number=${1}
    shift
    #trace ssh -t kg${cluster}-${geography}-${kind}-${number} date
    trace ssh -t kg${cluster}-${geography}-${kind}-${number} "${@}"
}

function Rrapp_do ()
{
    __need_args ${#} \> 5 "<cluster> <geography> <kind> <number> <app>" || return 1
    local -r cluster="${1}"
    shift
    local -r geography="${1}"
    shift
    local -r kind="${1}"
    shift
    local -i -r number=${1}
    shift
    local -r app="${1}"
    shift
    Rrexec "${cluster}" "${geography}" "${kind}" ${number} "cd /data/${app}/current && ${*}"
}

function __std_machine_for_app ()
{
    #assume local RESULT
    case "${1}" in
    shifty) RESULT=shifty ;;
    *) RESULT=utility ;;
    esac
}

function Rrlog ()
{
    __need_args ${#} == 3 "<cluster> <geography> <log-name>" || return 1
    local -r cluster="${1}"
    shift
    local -r geography="${1}"
    shift
    local -r log="${1}"
    shift
    Rrexec ${cluster} ${geography} utility 1 "exec less -i /var/log/engineyard/mongrel/texpert/${log}.log"
}

function __make_remote_funcs ()
{
    local args=( us 00 production staging 01 staging uk 01 production )
    set -- "${args[@]}"
    while [[ ${#} -gt 0 ]] ; do
        local geo="${1}" ; shift
        local cluster="${1}" ; shift
        local log="${1}" ; shift
        eval "function R${geo}_log() { Rrlog ${cluster} ${geo} ${log}; }"
        eval 'function R'"${geo}"'_console () { __need_args ${#} == 2 "<app> <env>" || return 1 ; local -r app="${1}" ; shift ; local -r env="${1}" ; shift ; local RESULT ; __std_machine_for_app "${app}" ; Rrapp_do '"${cluster} ${geo}"' ${RESULT} 1 "${app}" "exec ruby script/console ${env}" ; }'
        eval 'function R'"${geo}"'_dbconsole () { __need_args ${#} == 2 "<app> <db>" || return 1 ; local -r app="${1}" ; shift ; local -r db="${1}" ; shift ; local RESULT ; __std_machine_for_app "${app}" ; Rrapp_do '"${cluster} ${geo}"' ${RESULT} 1 "${app}" "exec ruby script/dbconsole ${db}" ; }'
    done
}
__make_remote_funcs
#?unset __make_remote_funcs

function Rshify_test ()
{
    local -r tester='RAILS_ENV=slave ruby /data/texpert/current/script/runner "puts \"Shifty working just fine\" if ShiftyApiProxy.send(:remote_as_JSON, :ping, {})"'
    local host
    for host in {kg00-us,kg01-uk}-{utility-1,texpert-{1,2}} ; do
        trace ssh "${host}" "${tester}"
    done
}

function PGQUERIES ()
{
    if [[ "${1}" ]] ; then
        local -r -i limit=${1}
        shift
    else
        local -r -i limit=4
    fi
    pg_queries ${limit}
    echo ''
    Rus_dbconsole gatekeeper slave
}

function PGYESTERDAY ()
{
    pg_yesterday
    echo ''
    Rus_dbconsole texpert slave
}

function __app_slice_count ()
{
    __need_args ${#} == 3 "<cluster>" "<geography>" "<app>" || return 1
    local cluster="${1}"
    shift
    local geography="${1}"
    shift
    case "${cluster}-${geography}" in
    kg01-uk)
        case "${1}" in
        texpert) return 5 ;;
        categoriser|utility|texpertise2|ui|gatekeeper|rota) return 2 ;;
        use_matcher|reporting) return 1 ;;
        esac
    ;;
    esac
}

function Rmonit ()
{
    __need_args ${#} == 1 "<app>" || return 1
    local -r cluster=kg01
    local -r geography=uk
    local -r app="${1}"
    shift
    __app_slice_count "${cluster}" "${geography}" "${app}"
    local -r -i slices=${?}
    local i=1
    while [[ ${i} < ${slices} ]] ; do
        trace ssh -t ${cluster}-${geography}-${app}-${i} sudo monit "${@}"
        i=$((i + 1))
    done
}

#function Rapologise ()
#{
    #local -r csv="${1}"
    #local -r suf=csv
    #if [[ -f "${csv}" && "${csv##*.}" = "csv" ]] ; then
        #local -r remote="$(date +%Y%m%d)-apology-CLIs.${suf}"
        #local -r host=kg00-s00045
        #trace scp -p "${csv}" "${host}:${remote}"
        #trace ssh -n ${host} screen -d -m bash -c 'export RAILS_ENV=production ; env ; ls -lAF ruby /data/texpert/current/utilities/queue_adhoc.rb -g 41 '"${remote} ; rm -f ${remote}"
    #fi
#}

function __texperts ()
{
   . texperts.bash
}

# vim:sw=4:ts=4
