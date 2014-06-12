# bash
# vim: set ft=sh fenc=utf-8:
#
# Rainer Müller <raimue@codingfarm.de>
# Version 2013-01-30
# http://raim.codingfarm.de/blog/2013/01/30/tmux-update-environment/
#
# Released into Public Domain

if [ -n "$(which tmux 2>/dev/null)" ]; then
    function tmux() {
        local tmux=$(type -fp tmux)
        case "$1" in
            reorder-windows|reorder|defrag)
                local i=$(tmux show-option -g |awk '/^base-index/ {print $2}')
                local w
                for w in $(tmux lsw | awk -F: '{print $1}'); do
                    if [ $w -gt $i ]; then
                        echo "Moving $w -> $i"
                        $tmux movew -d -s $w -t $i
                    fi
                    (( i++ ))
                done
                ;;
            update-environment|update-env|env-update)
                local v
                while read v; do
                    if [[ $v == -* ]]; then
                        unset ${v/#-/}
                    else
                        # Add quotes around the argument
                        v=${v/=/=\"}
                        v=${v/%/\"}
                        eval export $v
                    fi
                done < <(tmux show-environment)
                ;;
            *)
                $tmux "$@"
                ;;
        esac
    }
fi
