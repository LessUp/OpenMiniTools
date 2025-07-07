@echo off
powershell.exe -ExecutionPolicy Bypass -File "%~dp0\docker-remove-all-containers.ps1"
pause
