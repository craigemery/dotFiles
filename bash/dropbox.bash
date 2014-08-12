#!/bin/bash
function dropbox_daemon ()
{
    if [[ "$(hostname)" =~ pikachu.* ]] ; then
        if [[ -f ~/Dropbox/dropbox.py ]] ; then
            python ~/Dropbox/dropbox.py running && orphan ~/.dropbox-dist/dropboxd
        fi
    fi
}

dropbox_daemon
alias "dropbox=python ~/Dropbox/dropbox.py"
