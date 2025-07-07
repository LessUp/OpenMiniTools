@echo off
echo Building MonitorOff tool...
where /q csc
if %ERRORLEVEL% neq 0 (
    echo Error: C# compiler (csc) not found.
    echo Please install .NET SDK or .NET Framework SDK.
    pause
    exit /b 1
)

csc /out:MonitorOff.exe MonitorOff.cs
if %ERRORLEVEL% neq 0 (
    echo Build failed.
    pause
    exit /b 1
)

echo Build successful! MonitorOff.exe has been created.
echo You can now run MonitorOff.exe to turn off your monitor.
pause
