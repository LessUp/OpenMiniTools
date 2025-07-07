@echo off
powershell.exe -ExecutionPolicy Bypass -File "%~dp0\docker-remove-all-images.ps1"
pause
