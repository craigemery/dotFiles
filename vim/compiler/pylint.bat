@echo off
:call :lastarg %*
echo [%LAST_ARG%]
C:\Python27\Scripts\pylint.exe %*
goto :eof

:lastarg
  set "LAST_ARG=%~1"
  shift
  if not "%~1"=="" goto lastarg
goto :eof
