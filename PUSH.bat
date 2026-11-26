@echo off
setlocal EnableExtensions
title OJB Test Hub - push

rem Repo root is this file's directory.
cd /d "%~dp0"
set "EXITCODE=0"
set "GH_USER="
set "ARGS="

if not "%~1"=="" (
    set "ARGS=%*"
) else (
    echo.
    echo Create the empty repo first: https://github.com/new  ^(name: ojb-test-hub, no README^)
    echo.
    set /p "GH_USER=GitHub username: "
    if defined GH_USER set "ARGS=%GH_USER%"
)

if not defined ARGS (
    echo No username given - nothing to do.
    goto :done
)

where python >nul 2>nul
if errorlevel 1 (
    echo.
    echo python is not on PATH. Install it, or run this from a terminal:
    echo     python scripts\push.py your-username
    goto :done
)

python "%~dp0scripts\push.py" %ARGS%
set "EXITCODE=%ERRORLEVEL%"

:done
echo.
pause
exit /b %EXITCODE%
