#!/bin/bash

if [[ -z "$(declare -F _powerline_prompt)" ]] ; then
    case "$(python -V 2>&1)" in
    *2.[567]*)
        . ~/.dotFiles/powerline/powerline/bindings/bash/powerline.sh
        if [[ -z "$(declare -F appendToPath)" ]] ; then
            . ~/.dotFiles/bash/lists.bash
        fi
        appendToPath ~/.dotFiles/powerline/scripts
    ;;
    esac
fi
