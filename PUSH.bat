@echo off
setlocal EnableExtensions
title OJB Test Hub - push

rem Repo root is this file's directory.
cd /d "%~dp0"
set "EXITCODE=0"
set "ARGS="

if not "%~1"=="" goto have_args

echo.
echo Create the empty repo first: https://github.com/new  ^(name: ojb-test-hub, no README^)
echo.
set "GH_USER="
set /p "GH_USER=GitHub username: "
if not defined GH_USER goto no_user
set "ARGS=%GH_USER%"
goto run

:have_args
set "ARGS=%*"
goto run

:no_user
echo No username given - nothing to do.
goto done

:run
where python >nul 2>nul
if errorlevel 1 goto no_python
python "%~dp0scripts\push.py" %ARGS%
set "EXITCODE=%ERRORLEVEL%"
goto done

:no_python
echo.
echo python is not on PATH. Install it, or run this from a terminal:
echo     python scripts\push.py your-username

:done
echo.
pause
exit /b %EXITCODE%
