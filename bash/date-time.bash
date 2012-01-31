#!/bin/bash

function plural ()
{
    if [ ${#} -eq 2 ] ; then
      if [ "1" == "${1}" ] ; then
          echo "${1} ${2}"
      else
          echo "${1} ${2}s"
      fi
    else
      if [ "1" == "${1}" ] ; then
          echo "${1} ${2}"
      else
          echo "${1} ${3}"
      fi
    fi
}

function prettyTime ()
{
    local secondsInAMinute=60
    local secondsInAnHour=$((60 * ${secondsInAMinute}))
    local secondsInADay=$((24 * ${secondsInAnHour}))

    local seconds=${1}
    local days=$((${seconds} / ${secondsInADay} ))
    local secondsInTheDays=$((${days} * ${secondsInADay}))
    local hours=$(( ( ${seconds} - ${secondsInTheDays} ) / ${secondsInAnHour}))
    local secondsInTheHours=$((${hours} * ${secondsInAnHour}))
    local minutes=$(( ( ${seconds} - ${secondsInTheHours} - ${secondsInTheDays}) / ${secondsInAMinute}))
    local secondsInTheMinutes=$((${minutes} * ${secondsInAMinute}))

    seconds=$((${seconds} - ${secondsInTheMinutes} - ${secondsInTheHours} - ${secondsInTheDays} ))

    local -i values=0

    if [ ${days} -gt 0 ] ; then
        values=$((++values))
    fi
    if [ ${hours} -gt 0 ] ; then
        values=$((++values))
    fi
    if [ ${minutes} -gt 0 ] ; then
        values=$((++values))
    fi
    if [ ${seconds} -gt 0 ] ; then
        values=$((++values))
    fi

    local -i val=1
    local str=

    if [ ${days} -gt 0 ] ; then
        str="$(plural ${days} day)"
        val=$((++val))
    fi

    if [ ${hours} -gt 0 ] ; then
        [ "${str}" ] && str="${str}, "
        [ ${val} -ne 1 -a ${val} -eq ${values} ] && str="${str}and "
        str="${str}$(plural ${hours} hour)"
        val=$((++val))
    fi

    if [ ${minutes} -gt 0 ] ; then
        [ "${str}" ] && str="${str}, "
        [ ${val} -ne 1 -a ${val} -eq ${values} ] && str="${str}and "
        str="${str}$(plural ${minutes} minute)"
        val=$((++val))
    fi

    [ "${str}" ] && str="${str}, "
    [ ${val} -ne 1 -a ${val} -eq ${values} ] && str="${str}and "
    str="${str}$(plural ${seconds} second)"
    val=$((++val))

    echo "${str}"
}

function __secondsSinceEpoch ()
{
    #assume local -i RESULT
    case $(uname) in
    SunOS) RESULT=$(perl -e 'print time, "\n"') ;;
    *)     RESULT=$(date +%s) ;;
    esac
}

function secondsSinceEpoch ()
{
    local -i RESULT
    __secondsSinceEpoch
    echo ${RESULT}
}

function timeFromSecondsSinceEpoch ()
{
    local -r -i sse=${1}
    shift
    date --date="Jan 1 1970 + ${sse} seconds" "${@}"
}

function elapsed ()
{
    if [ ${#} -gt 1 ] ; then
        local now=${2}
    else
        local now=$(secondsSinceEpoch)
    fi

    local then=${1}

    if [ ${now} -lt ${then} ] ; then
        echo 'You'"'"'ve given me a time in the future!'
    else
        prettyTime $((${now} - ${then}))
    fi
}

function ordinal ()
{
    local day=${1}
    local ord=""

    case ${day} in
    11|12|13)   ord=th ;;
    1|*1)       ord=st ;;
    *2)         ord=nd ;;
    *3)         ord=rd ;;
    *)          ord=th ;;
    esac

    echo ${ord}
}

function today ()
{
    local month=$(date +%B)
    local day=$(date +%d | sed -e 's@^0@@')
    local ord=$(ordinal ${day})
    local year=$(date +%Y)

    echo "${month} ${day}${ord} ${year}"
}

function __date_time ()
{
    . date-time.bash
}
