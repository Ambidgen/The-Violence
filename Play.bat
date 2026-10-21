@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0."

REM Play The Violence from this folder (the source folder or a release folder).
REM 1. A Godot 4.4+ editor (4.7.2 tested) sitting in this folder runs the project files here.
REM 2. Otherwise a Godot on PATH does.
REM 3. Otherwise the standalone TheViolence.exe here, or in build\.
REM Anything after Play.bat is passed on, e.g.  Play.bat -- --ops

set "RUNTIME="
for %%F in (Godot*.exe godot*.exe) do (
  echo %%~nF | findstr /i "console" >nul || (
    if not defined RUNTIME set "RUNTIME=%%~fF"
  )
)
if not defined RUNTIME (
  for %%F in (Godot*console*.exe godot*console*.exe) do (
    if not defined RUNTIME set "RUNTIME=%%~fF"
  )
)
if not defined RUNTIME (
  where godot >nul 2>&1 && set "RUNTIME=godot"
)
if defined RUNTIME if exist "%~dp0project.godot" (
  "!RUNTIME!" --path "%~dp0." %*
  goto :done
)

if exist "%~dp0TheViolence.exe" (
  "%~dp0TheViolence.exe" %*
  goto :done
)
if exist "%~dp0build\TheViolence.exe" (
  "%~dp0build\TheViolence.exe" %*
  goto :done
)

echo Could not play The Violence from this folder.
echo.
echo Put a Godot 4.4 or newer editor in this folder with the project files, for example
echo   Godot_v4.7.2-stable_win64.exe
echo or put TheViolence.exe here (or in build\), then double-click Play.bat again.
echo.
pause
exit /b 1

:done
set "ERR=!ERRORLEVEL!"
if not "!ERR!"=="0" pause
exit /b !ERR!
