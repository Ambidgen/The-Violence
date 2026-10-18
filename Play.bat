@echo off
setlocal EnableExtensions
cd /d "%~dp0."

REM Double-click this in the project folder. It plays the files in this
REM folder when a Godot runtime is sitting here with everything else.
REM A standalone TheViolence.exe in this folder (or in build\) is used
REM if no editor is present.

set "RUNTIME="
for %%F in (Godot*.exe godot*.exe) do (
  if exist "%%~fF" (
    set "RUNTIME=%%~fF"
    goto :run_project
  )
)

where godot >nul 2>&1 && (
  set "RUNTIME=godot"
  goto :run_project
)
where Godot >nul 2>&1 && (
  set "RUNTIME=Godot"
  goto :run_project
)

if exist "%~dp0TheViolence.exe" (
  "%~dp0TheViolence.exe" %*
  set "ERR=%ERRORLEVEL%"
  if not "%ERR%"=="0" pause
  exit /b %ERR%
)
if exist "%~dp0build\TheViolence.exe" (
  "%~dp0build\TheViolence.exe" %*
  set "ERR=%ERRORLEVEL%"
  if not "%ERR%"=="0" pause
  exit /b %ERR%
)

echo Could not play The Violence from this folder.
echo.
echo Put a Godot 4.4+ editor in this folder with the rest of the project, for example:
echo   Godot_v4.7.2-stable_win64.exe
echo or put the standalone TheViolence.exe here ^(or in build\^), then double-click Play.bat again.
echo.
pause
exit /b 1

:run_project
"%RUNTIME%" --path "%~dp0." %*
set "ERR=%ERRORLEVEL%"
if not "%ERR%"=="0" pause
exit /b %ERR%
