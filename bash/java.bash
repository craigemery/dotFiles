#!/bin/bash

function setJDK ()
{
    local one_1="1.1"
    local one_2="1.2"
    local one_3="1.3"
    local one_4="1.4"
    local java_runtime=/jre/lib/rt.jar

    if [ ${#} -eq 0 ] ; then
        local req=${one_4}
    else
        local req=${1}
        shift
    fi

    if [ "${HOSTNAME}" == sunflora ] ; then
	case "${req}" in
	${one_1}|${one_2}) export JAVA_HOME=/usr/java${req} ;;
	*) echo "I've no idea what JDK you're talking about" ;;
	esac
    else
	case "${req}" in
	${one_3}) local theRpm=jdk ;;
	${one_4}) local theRpm=j2sdk ;;
	*) echo "I've no idea what JDK you're talking about" ;;
	esac

	if [ "$(rpm -q ${theRpm} 2>&-)" ] ; then # is the rpm installed?
	    export JAVA_HOME=$(rpm -ql ${theRpm} 2>&- | sed -ne 's@'${java_runtime}'$@@p')
	fi
    fi

    if [ "${JAVA_HOME}" ] ; then
	export CLASSPATH=.:${JAVA_HOME}${java_runtime}
        local p=""
        local dir=""
        for dir in $(echo ${PATH} | tr : ' ') ; do
            local x="${dir}/javac"
            if [ ! -x "${x}" -o -L "${x}" ] ; then
                if [ "${p}" ] ; then
                    p="${p}:${dir}"
                else
                    p="${dir}"
                fi
            fi
        done
        export PATH=${JAVA_HOME}/bin:${p}
    fi
}
