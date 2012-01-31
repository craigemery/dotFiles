#!/usr/bin/env bash

function __get_me ()
{
    # assume local RESULT
    RESULT=${FUNCNAME[$((${#FUNCNAME[@]}-1))]}
}

function __wrapped_ssh ()
{
    #Mixed args
    #Arg with param choices from an array
    #( these work great with = switch handling: find =<something> and <something> is one
    #  of the values in an array, then pretend --arg=<someting> was appropriately supplied )
    local RESULT
    __get_me
    local -r me=${RESULT}
    unset RESULT

    local -r -a ssh_cmds=(ssh Ssh)
    local -r ssh_cmds_l=$(listArray --comma "${ssh_cmds[@]}")
    local -r c_s="-c"
    local -r c_l="--command"
    local -r c_c="${c_s}|${c_l} <command> or ${c_l}=<command>"
    local -r c_h="Which ssh command to use (must be one of ${ssh_cmds_l})"
    local ssh_cmd="${ssh_cmds[0]}"

    #Arg with arbitrary param
    local -r u_s="-u"
    local -r u_l="--user"
    local -r u_c="${u_s}|${u_l} <user> or ${u_l}=<user>"
    local -r u_h="Which user to log in as (Defaults to |unspecified|)"
    local user=""

    local -r e_s="-e"
    local -r e_l="--extra"
    local -r e_c="${e_s}|${e_l} <extra> or ${e_l}=<extra>"
    local -r e_h="I use extra strings on the end of hostnames to enable certain ssh options"
    local host_extra=""

    local -r s_s="-s"
    local -r s_l="--ssh"
    local -r s_c="${s_s}|${s_l} <ssh option> or ${s_l}=<ssh option>"
    local -r s_h="Blindly pass on option to ssh"
    local ssh_opts=()

    local -r S_s="-S"
    local -r S_l="--screen"
    local -r S_c="${s_s}|${s_l}"
    local -r S_h="Invoke screen on the remote machine (-s -t screen -l -T "\$"TERM -s -bash)"
    local screen_opts=(-- -- -s -t -- screen)

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
    local -r short_help="usage: ${me} [${h_s}|${h2_s}|${h_l}] [${u_c}] [${c_c}] [${e_c}] [${S_c}] <hostname>"
    local -r long_help="${short_help}${sep}${u_s}: ${u_h}${sep}${c_s}: ${c_h}${sep}${e_s}: ${e_h}${sep}${S_s}: ${S_h}${sep}Some flags are deducable from =*, i.e. =ssh is infered as -c ssh etc"

    if [[ ${#} -lt 1 ]] ; then
        echo -e "Hostname must be supplied\n${long_help}" >&2
        return 1
    fi

    case "${1}" in
    -*) ;;
    *)
        local -r hostname="${1}"
        shift
    esac

    while [[ ${#} -gt 0 ]] ; do
        local arg="${1}"
        case "${arg}" in
        --) shift ; break ;; # stop processing args
        --*) # long switches
            case "${arg}" in
            ${c_l}=*) ssh_cmd="${arg#${c_l}=}" ;;
            ${c_l}) if [[ ${#} -gt 0 ]] ; then
                        ssh_cmd="${2}" ;
                        shift
                    else
                        echo "${c_l} needs an argument" >&2
                        return -1
                    fi ;;

            ${u_l}=*) user="${arg#${u_l}=}" ; shift ;;
            ${u_l}) if [[ ${#} -gt 0 ]] ; then
                        user="${2}" ;
                        shift
                    else
                        echo "${u_l} needs an argument" >&2
                        return -1
                    fi ;;

            ${e_l}=*) user="${arg#${e_l}=}" ;;
            ${e_l}) if [[ ${#} -gt 0 ]] ; then
                        host_extra="${host_extra}${2}" ;
                        shift
                    else
                        echo "${e_l} needs an argument" >&2
                        return -1
                    fi ;;

            ${s_l}=*) ssh_opts[${#ssh_opts}]="${arg#${s_l}=}" ;;
            ${s_l}) if [[ ${#} -gt 0 ]] ; then
                        ssh_opts[${#ssh_opts}]="${2}" ;
                        shift
                    else
                        echo "${s_l} needs an argument" >&2
                        return -1
                    fi ;;

            ${h_l}) echo -e "${long_help}" ; return ;;

            ${S_l}) set "${screen_opts[@]}" ;;

            *) echo "Invalid switch '${arg}'" >&2 ; return 1 ;; # bad switch
            esac
        ;;
        # short switches that take args
        ${u_s}) if [[ ${#} -gt 0 ]] ; then
                    user="${2}" ;
                    shift
                else
                    echo "${u_s} needs an argument" >&2
                    return -1
                fi ;;

        ${c_s}) if [[ ${#} -gt 0 ]] ; then
                    ssh_cmd="${2}" ;
                    shift
                else
                    echo "${c_s} needs an argument" >&2
                    return -1
                fi ;;

        ${e_s}) if [[ ${#} -gt 0 ]] ; then
                    host_extra="${host_extra}${2}" ;
                    shift
                else
                    echo "${e_s} needs an argument" >&2
                    return -1
                fi ;;

        ${s_s}) if [[ ${#} -gt 0 ]] ; then
                    ssh_opts[${#ssh_opts}]="${2}" ;
                    shift
                else
                    echo "${e_s} needs an argument" >&2
                    return -1
                fi ;;

        -*) # short switches which take no arguments
            arg=${arg:1} # remove leading dash
            while [[ "${arg}" ]] ; do
                case "-${arg:0:1}" in

                ${v_s}) verbosity=$((${verbosity} + 1)) ;;
                ${d_s}) dry_run=yes ;;
                ${S_s}) set "${screen_opts[@]}" ;;

                ${h_s}|${h2_s}) echo -e "${short_help}${more_help}" ; return ;;
                *) echo "Invalid switch '${arg}'" >&2 ; return 1 ;; # bad switch
                esac
                arg="${arg:1}"
            done ;;

        =*)
            local eq_arg="${arg:1}" # remove leading equals
            if arrayHas "${eq_arg}" "${ssh_cmds[@]}" ; then
                ssh_cmd="${eq_arg}"
            elif [[ "${eq_arg}" = 0 ]] ; then
                user=root
            else
                echo "'Equals arg' '${arg}' should be an action" >&2
                return -1
            fi ;;

        *) break ;;
        esac
        shift
    done

    if [[ ${verbosity} -gt 0 ]] ; then
        echo '${user} = '"'${user}'" >&2
        echo '${ssh_cmd} = '"'${ssh_cmd}'" >&2
    fi

    #Validate args that should be chosen from a list
    if ! arrayHas "${ssh_cmd}" "${ssh_cmds[@]}" ; then
        echo "Ssh command '${ssh_cmd}' should be one of ${ssh_cmds_l}" >&2
        return -1
    fi

    [[ "${dry_run}" ]] && return

    [[ "${user}" ]] && user="${user}@"

    #Actually do work
    ${ssh_cmd} "${ssh_opts[@]}" "${user}${hostname}${host_extra}" "${@}"
}

function make_ssh_wrappers ()
{
    local -i verbose=0
    [ "${1}" = -v ] && shift && verbose=1
    readonly verbose
    while [[ ${#} -gt 0 ]] ; do
        local hostname=${1}
        shift
        local capped=${hostname}
        __capitalise capped
        [ ${verbose} -ne 0 ] && echo "Making wrapper ${capped}"
        eval "function ${hostname} () { __wrapped_ssh ${hostname} \"\${@}\"; }"
        eval "function ${capped} () { __wrapped_ssh ${hostname} =Ssh \"\${@}\"; }"
    done
}

# make_ssh_wrappers

function rscp ()
{
    rsync -Pazve ssh "${@}"
}

function rscreen ()
{
    local -r host="${1}"
    shift
    local sudo=""
    if [[ "${1}" = "sudo" ]] ; then
      shift
      sudo=sudo
    fi
    readonly sudo
    trace ssh -t "${host}" ${sudo} /opt/bin/screen "${@}"
}

function __ssh ()
{
   . ssh.bash
}

