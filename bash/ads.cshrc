#
# ADS 1.2 Environment Settings
#

# ADS home directory:
setenv ARMHOME ../arm

if ( "`uname -s`" == "Linux" ) then
  #
  # ADS Environment Settings for sh on Linux
  #
  # These all depend on ARMHOME, which should already be set.
  #
  
  setenv ARMLIB $ARMHOME/common/lib
  setenv ARMINC $ARMHOME/common/include
  setenv ARMSD_DRIVER_DIR $ARMHOME/linux/bin
  setenv ARMDLL $ARMHOME/linux/bin
  setenv ARMCONF $ARMHOME/linux/bin
  setenv WUHOME $ARMHOME/windu
  setenv HHHOME $ARMHOME/windu/bin.linux_i32/hyperhelp
  
  if ( "x$LD_LIBRARY_PATH" == "x" ) then
    setenv LD_LIBRARY_PATH /usr/dt/lib
  else
    setenv LD_LIBRARY_PATH /usr/dt/lib:$LD_LIBRARY_PATH
  endif

  echo $LD_LIBRARY_PATH | grep -i "/usr/openwin/lib" > /dev/null
  if ( $? != 0 ) then
    setenv LD_LIBRARY_PATH /usr/openwin/lib:$LD_LIBRARY_PATH
  endif
  
  setenv LD_LIBRARY_PATH $ARMHOME/windu/lib.linux_i32:$LD_LIBRARY_PATH

  setenv LD_LIBRARY_PATH=$ARMHOME/linux/bin:$LD_LIBRARY_PATH

  setenv LD_LIBRARY_PATH /usr/lib:$LD_LIBRARY_PATH
  setenv PATH $ARMHOME/linux/bin:$WUHOME/bin.linux_i32:$WUHOME/lib.linux_i32:$PATH
endif
