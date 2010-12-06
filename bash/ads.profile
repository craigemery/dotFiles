#!/bin/bash

declare -i ads_profile_version=200

if [[ -z "${ADS_PROFILE_VERSION}" ]] ; then
    export ADS_PROFILE_VERSION=0
fi

if [[ ${ADS_PROFILE_VERSION} -lt ${ads_profile_version} ]] ; then

    export ADS_PROFILE_VERSION=${ads_profile_version}
    [ -z "${ARMHOME}" ] && export ARMHOME=../arm

    if [[ "$(uname -s)" = "Linux" ]] ; then
        export ARMLIB=${ARMHOME}/common/lib
        export ARMINC=${ARMHOME}/common/include
        export ARMSD_DRIVER_DIR=${ARMHOME}/linux/bin
        export ARMDLL=${ARMHOME}/linux/bin
        export ARMCONF=${ARMHOME}/linux/bin
        export WUHOME=${ARMHOME}/windu
        export HHHOME=${ARMHOME}/windu/bin.linux_i32/hyperhelp

        . lists.bash

        prependToLibpath /usr/dt/lib
        prependToLibpath /usr/openwin/lib
        prependToLibpath ${ARMHOME}/windu/lib.linux_i32
        prependToLibpath ${ARMHOME}/linux/bin
        prependToLibpath /usr/lib

        prependToPath ${ARMHOME}/linux/bin
        prependToPath ${WUHOME}/bin.linux_i32
        prependToPath ${WUHOME}/lib.linux_i32
    fi


    if [[ "$(uname -s)" = "CYGWIN_NT-5.0" ]] ; then
        export ARMLIB=${ARMHOME}/common/lib
        export ARMINC=${ARMHOME}/common/include
        # export ARMSD_DRIVER_DIR=${ARMHOME}/linux/bin
        export ARMDLL=${ARMHOME}/windows/bin
        export ARMCONF=${ARMHOME}/windows/bin
        # export WUHOME=${ARMHOME}/windu
        # export HHHOME=${ARMHOME}/windu/bin.linux_i32/hyperhelp
	PATH=$(cygpath -a ${ARMHOME}/windows/bin):$PATH

        . lists.bash

        # prependToLibpath /usr/dt/lib
        # prependToLibpath /usr/openwin/lib
        # prependToLibpath ${ARMHOME}/windu/lib.linux_i32
        prependToLibpath ${ARMHOME}/windows/bin
        # prependToLibpath /usr/lib

        # prependToPath ${ARMHOME}/linux/bin
        # prependToPath ${WUHOME}/bin.linux_i32
        # prependToPath ${WUHOME}/lib.linux_i32
    fi

fi

unset ads_profile_version
