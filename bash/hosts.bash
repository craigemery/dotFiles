#!/bin/env bash

function my_ip_address ()
{
    curl --silent http://checkip.dyndns.com:8245 | sed -ne 's@.*Current IP Address: \(.*\)</body>.*$@\1@p'
}

function dig_answers ()
{
    dig "${@}" | __tween ';; ANSWER SECTION:' '^$'
}

function dig_TXT ()
{
    dig_answers -t TXT "${1}"
}

function dig_MX ()
{
    dig_answers -t MX "${1}"
}

function line_count_is ()
{
    local -r in="${1}"
    shift
    local -r op="${1}"
    shift
    local -r -i val=${1}
    shift
    local -r out=/tmp/line_count.${$}.out
    local -r -i count=$(cat "${in}" | tee "${out}" | wc -l)
    cat "${out}"
    rm -f ${out}
    case "${op}" in
    -gt) [[ ${count} -gt ${val} ]] && return 0 ;;
    -lt) [[ ${count} -lt ${val} ]] && return 0 ;;
    -eq) [[ ${count} -eq ${val} ]] && return 0 ;;
    -ne) [[ ${count} -ne ${val} ]] && return 0 ;;
    esac
    return 1
}

function dig_has_TXT ()
{
    dig_TXT "${1}" | line_count_is - -gt 0
}

function dig_has_MX ()
{
    dig_MX "${1}" | line_count_is - -gt 0
}

function __tween ()
{
    local -r start="${1/\//\\/}"
    local -r end="${2/\//\\/}"
    awk "BEGIN{p=0};/${end}/{p=0};//{if (p==1) {print \$0}};/${start}/{p=1}"
}

function whois ()
{
    local -r url="http://webwhois.nic.uk/cgi-bin/whois.cgi?query=${1}"
    curl --silent "${url}" | __tween '<PRE>' '</PRE>'
}

function whois_my_ip_address ()
{
    local -r my_ip=$(my_ip_address)
    trace whois ${my_ip}
}

function Dots () {
    local -i i=${1}
    while [[ ${i} -gt 0 ]]; do
        echo -n .
        i=$((${i} - 1))
    done
}

function Sleep () {
    local -r -i cols=$(tput cols)
    local -i sec=${1}
    local -i to_sleep=1
    if [[ ${sec} -gt ${cols} ]]; then
        to_sleep=$((${sec} / ${cols}))
        sec=${cols}
    fi
    Dots ${sec}
    while [[ ${sec} -gt 0 ]]; do
        sleep ${to_sleep}
        sec=$((${sec} - ${to_sleep}))
        echo -ne '\b \b'
    done
}

function Every ()
{
    local -i period=0
    case ${1} in
    *s) period=${1%s} ;;
    *m) period=$((${1%m} * 60)) ;;
    *h) period=$((${1%h} * 3600)) ;;
    esac
    shift
    readonly period
    local -r out=/tmp/Every.${$}.out
    while echo "${@}"; do
        eval "${@}" && return
        Sleep ${period}
        clear
    done
    rm -f ${out}
}

function __hosts ()
{
    . hosts.bash
}

