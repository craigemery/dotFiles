#!/bin/bash

# [[ "${T5_SRC_HOME}" ]] && export T5_SRC_HOME=$(_Pu ${T5_SRC_HOME})

[[ "${BREWADDINS}" ]] && export BASH_BREWADDINS=$(_Pu ${BREWADDINS})
#[[ "${BREW_SDK_2_1_0}" ]] && export BASH_BREW_SDK_2_1_0=$(_Pu ${BREW_SDK_2_1_0})
[[ "${BREWSDK210EN}" ]] && export BASH_BREWSDK210EN=$(_Pu ${BREWSDK210EN})
[[ "${BREWSDK312EN}" ]] && export BASH_BREWSDK312EN=$(_Pu ${BREWSDK312EN})
[[ "${BREWSDK314EN}" ]] && export BASH_BREWSDK314EN=$(_Pu ${BREWSDK314EN})
[[ "${BREWBTIL}" ]] && export BASH_BREWBTIL=$(_Pu ${BREWBTIL})
[[ "${BREWBTILMAIN}" ]] && export BASH_BREWBTILMAIN=$(_Pu ${BREWBTILMAIN})
[[ "${BREWBTIL3X}" ]] && export BASH_BREWBTIL3X=$(_Pu ${BREWBTIL3X})
[[ "${BREWBTIL102}" ]] && export BASH_BREWBTIL102=$(_Pu ${BREWBTIL102})
[[ "${BREWDIR}" ]] && export BASH_BREWDIR=$(_Pu ${BREWDIR})
[[ "${BREWTOOLSDIR310}" ]] && export BASH_BREWTOOLSDIR310=$(_Pu ${BREWTOOLSDIR310})
[[ "${BREWSDKTOOLSDIR}" ]] && export BASH_BREWSDKTOOLSDIR=$(_Pu ${BREWSDKTOOLSDIR})
[[ "${BREWSDK}" ]] && export BASH_BREWSDK=$(_Pu ${BREWSDK})
[[ "${BREWPKGENERIC312}" ]] && export BASH_BREWPKGENERIC312=$(_Pu ${BREWPKGENERIC312})
[[ "${BREWPKMSM312}" ]] && export BASH_BREWPKMSM312=$(_Pu ${BREWPKMSM312})
[[ "${BREWPK}" ]] && export BASH_BREWPK=$(_Pu ${BREWPK})
[[ "${BREWTOOLSDIR}" ]] && export BASH_BREWTOOLSDIR=$(_Pu ${BREWTOOLSDIR})

[[ "${QP_TOOLS_1}" ]] && export BASH_QP_TOOLS_1=$(_Pu ${QP_TOOLS_1})

perl -v | egrep -qe MSWin32-x86-multi-thread && export PERL_IS_WIN32=1

export QPB_TIME_PERFORCE=
