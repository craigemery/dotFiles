#!/usr/bin/bash

make_ssh_wrappers mbw elan

function make_vnc_file ()
{
    local -r vnc_file="${1}" ; shift
    local -r password="${1}" ; shift
    local -r port="${1}" ; shift
    echo -e "[connection]\nhost=LOCALHOST\nport=${port}\nproxyhost=\nproxyport=5900\npassword=${password}\n[options]\nuse_encoding_0=1\nuse_encoding_1=1\nuse_encoding_2=1\nuse_encoding_3=0\nuse_encoding_4=1\nuse_encoding_5=1\nuse_encoding_6=1\nuse_encoding_7=1\nuse_encoding_8=1\nuse_encoding_9=1\nuse_encoding_10=0\nuse_encoding_11=0\nuse_encoding_12=0\nuse_encoding_13=0\nuse_encoding_14=0\nuse_encoding_15=0\nuse_encoding_16=1\nuse_encoding_17=1\npreferred_encoding=16\nrestricted=0\nviewonly=0\nnostatus=0\nnohotkeys=0\nshowtoolbar=1\nAutoScaling=0\nfullscreen=0\nautoDetect=1\n8bit=1\nshared=1\nswapmouse=0\nbelldeiconify=0\nemulate3=1\nJapKeyboard=0\nemulate3timeout=100\nemulate3fuzz=4\ndisableclipboard=0\nlocalcursor=1\nScaling=0\nscale_num=100\nscale_den=100\ncursorshape=1\nnoremotecursor=0\ncompresslevel=6\nquality=6\nServerScale=1\nReconnect=0\nEnableCache=0\nQuickOption=1\nUseDSMPlugin=0\nUseProxy=0\nsponsor=0\nDSMPlugin=NoPlugin\nExitCheck=0\nFileTransferTimeout=30\nKeepAliveInterval=5" > "${vnc_file}"
    chmod a+x "${vnc_file}"
}

function Vnc ()
{
    local -r who="${1}"
    local -r file=/tmp/${who}-${$}.vnc
    local -r pw="9e0ebe4c52888c57"
    case "${who}" in
    me|craig) local -r port=15907 ;;
    car) local -r port=15908 ;;
    [0-9]|[0-9][0-9]|[0-9][0-9][0-9]|[0-9][0-9][0-9][0-9]|[0-9][0-9][0-9][0-9][0-9]) local -r port=${who} ;;
    *) return ;;
    esac
    make_vnc_file "${file}" "${pw}" "${port}"
    start $(cygpath -was "${file}")
    echo rm -f "${file}"
}

function __home ()
{
   . home.bash
}

