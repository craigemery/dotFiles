#!/usr/bin/bash

make_ssh_wrappers $(awk '/^Host /{h=$2};/Hostname .*\.xensource\.com/{print h}' < ~/.ssh/config)
