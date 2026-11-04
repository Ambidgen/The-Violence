@echo off
REM Joins the six parts of the standalone game into release\TheViolence.exe (one file, no install).
cd /d "%~dp0release"
if exist TheViolence.exe del TheViolence.exe
copy /b TheViolence.exe.part0+TheViolence.exe.part1+TheViolence.exe.part2+TheViolence.exe.part3+TheViolence.exe.part4+TheViolence.exe.part5 TheViolence.exe >nul
if errorlevel 1 (echo Could not join the parts. & pause & exit /b 1)
del TheViolence.exe.part0 TheViolence.exe.part1 TheViolence.exe.part2 TheViolence.exe.part3 TheViolence.exe.part4 TheViolence.exe.part5
echo release\TheViolence.exe is ready (SHA-256 51471fd3...fbec). Double-click it, or Play.bat.
pause
