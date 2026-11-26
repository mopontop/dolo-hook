@echo off
setlocal
cd /d "%~dp0.."

if "%~1"=="" (
	echo usage: PUSH.bat ^<github-username^>
	echo.
	echo   1. create an empty repo named ojb-test-hub at https://github.com/new
	echo   2. run: PUSH.bat your-username
	exit /b 2
)

python scripts\push.py %*
set EXITCODE=%ERRORLEVEL%
echo.
pause
exit /b %EXITCODE%
