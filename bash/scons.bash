#!/bin/bash

# revision (no longer exists)
unset _do_log
DFBASHDIR=~/.dotFiles/bash
case "${PATH}" in
${DFBASHDIR}|${DFBASHDIR}:*|*:${DFBASHDIR}:*|*:${DFBASHDIR}) true ;;
*) export PATH=${DFBASHDIR}:${PATH} ;;
esac
. date-time.bash

# base functions

function _do_logname ()
{
    # assume local log
    log="${PWD}/.${PWD##*/}.${1}.out";
}

function _do_logit ()
{
    local log; _do_logname "${1}"; shift; readonly log;
    # date > "${log}";
    # local -i RESULT
    # __secondsSinceEpoch
    echo "$*" >> "${log}";
    time_it "${1}" "${@}" 2>&1 | tr '\015' '\012' | tee -a "${log}";
    # date | tee -a "${log}";
    # elapsed ${RESULT} | tee -a "${log}";
}

function _do_log_cat ()
{
    local log; _do_logname scons; shift; readonly log;
    cat "${log}";
}

# scons functions

function _sc ()
{
    _do_logit scons scons "${@}";
}

function _sco ()
{
    _do_log_cat scons;
}

function _scl ()
{
    local log; _do_logname scons; shift; readonly log;
    less "${log}";
}

function _sct ()
{
    local log; _do_logname scons; shift; readonly log;
    tail -f -n +0 "${log}";
}

# build_all.sh functions

function _ba ()
{
    _do_logit build_all ./tools/build/build_all.sh "${@}"
}

function _bao ()
{
    _do_log_cat build_all
}

function _bal ()
{
    local log; _do_logname build_all; shift; readonly log;
    less "${log}";
}

function _bat ()
{
    local log; _do_logname build_all; shift; readonly log;
    tail -f -n +0 "${log}";
}

# other

function _clean_build ()
{
    ( local -r B=build.$$; mv build $B; rm -fr $B & ) > /dev/null 2>&1
}

function _clean_scons ()
{
    scons -c;
}

function _clean_pyc ()
{
    find -name '*.py[co]' -print0 | xargs -0rtn99 rm 2>&1 ;
}

function _find_test_xml ()
{
    find \( -name 'cxx*.xml' -o -name 'TESTS-*.xml' \) -print0
}

function find_test_xml ()
{
    _find_test_xml | tr '\000' '\012' | sort
}

function _clean_test_xml ()
{
    _find_test_xml | xargs -0rtn99 rm 2>&1 ;
}

function _clean ()
{
    _clean_build;
    _clean_scons;
    _clean_pyc;
    _clean_test_xml;
}

function untar_sdk () {
    local -r sdk="${1}";
    local name="${sdk%.tar.gz}";
    local -ri build=${name##*-};
    name=${name%-${build}};
    local -r dest=untarred/${name};
    mkdir -p ${dest};
    if [[ -d "${dest}" ]]; then
        cd "${dest}";
        tar zxf ~1/${1};
        rm -fr ${build};
        mv corelogger_sdk ${build};
        back;
        cd "${dest}/${build}";
        ls -lAF;
        pwd;
    fi;
}

# self-source (aka reload)

function __scons_bash ()
{
    . ~/.dotFiles/bash/scons.bash
}
