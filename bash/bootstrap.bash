#!/usr/bin/env bash

me="${BASH_ARGV[0]}"
medir="${me%/*}"
. ${medir}/lists.bash
prependToPath ${medir}
prependToPath /bin
# . common.bash
. cd.bash
. diag.bash
. scons.bash
. tmux.bash
