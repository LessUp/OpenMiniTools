@echo off
rem This batch file runs the corresponding PowerShell script.
rem It should be run from a directory containing a docker-compose.yml file.

rem The PowerShell script is located in the same directory as this batch file.
set PWSCRIPT_PATH=%~dp0compose-up.ps1

powershell.exe -ExecutionPolicy Bypass -File "%PWSCRIPT_PATH%"
pause
