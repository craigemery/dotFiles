#!/bin/bash

function _sc ()
{
    scons "${@}" | tr '\015' '\012' | tee .scons.out;
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
