#!/usr/bin/env bash

function __cut_and_paste_func_example ()
{
    #Mixed args
    #Arg with param choices from an array
    #( these work great with = switch handling: find =<something> and <something> is one
    #  of the values in an array, then pretend --arg=<someting> was appropriately supplied )
    local -r -a locales=(us uk)
    local -r locales_l=$(listArray --comma "${locales[@]}")
    local -r l_s="-l"
    local -r l_l="--locale"
    local -r l_c="${l_s}|${l_l} <locale> or ${l_l}=<locale>"
    local -r l_h="Which locality of cluster to use (must be one of ${locales_l})"
    local iteration=""

    #Arg with arbitrary param
    local -r i_s="-i"
    local -r i_l="--iteration"
    local -r i_c="${i_s}|${i_l} <iteration> or ${i_l}=<iteration>"
    local -r i_h="Which iteration to use"
    local locale=""

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
    local -r short_help="usage: ${FUNCNAME[0]} [${h_s}|${h2_s}|${h_l}] [${i_c}] [${l_c}]"
    local -r long_help="${short_help}${sep}${i_s}: ${i_h}${sep}${l_s}: ${l_h}${sep}Some flags are deducable from =*, i.e. =bounce is infered as -a bounce etc"

    while [[ ${#} -gt 0 ]] ; do
        local arg="${1}"
        case "${arg}" in
        --*) # long switches
            case "${arg}" in
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
        ${i_s}) if [[ ${#} -gt 0 ]] ; then
                    iteration="${2}" ;
                    shift
                else
                    echo "${i_s} needs an argument" >&2
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
            if arrayHas "${eq_arg}" "${locales[@]}" ; then
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

    if [[ ${verbosity} -gt 0 ]] ; then
        echo '${iteration} = '"'${iteration}'" >&2
        echo '${locale} = '"'${locale}'" >&2
    fi

    #Validate args that should be chosen from a list
    if ! arrayHas "${locale}" "${locales[@]}" ; then
        echo "Locale '${locale}' should be one of ${locales_l}" >&2
        return -1
    fi

    [[ "${dry_run}" ]] && return

    #Actually do work
}

