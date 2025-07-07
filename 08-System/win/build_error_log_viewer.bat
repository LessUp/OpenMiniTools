@echo off
echo Building ErrorLogViewer.cs...
C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe /target:winexe /out:ErrorLogViewer.exe ErrorLogViewer.cs

if %errorlevel% equ 0 (
    echo Build successful! ErrorLogViewer.exe has been created.
) else (
    echo Build failed with error level %errorlevel%.
)

echo.
echo Press any key to exit...
pause >nul
