# PowerShell script to turn off the monitor
# This script uses Windows API P/Invoke to send the monitor power off signal

Add-Type @"
using System;
using System.Runtime.InteropServices;

public class MonitorControl {
    [DllImport("user32.dll")]
    public static extern int SendMessage(int hWnd, int hMsg, int wParam, int lParam);
    
    public const int WM_SYSCOMMAND = 0x0112;
    public const int SC_MONITORPOWER = 0xF170;
    public const int HWND_BROADCAST = 0xFFFF;
    
    public const int MONITOR_ON = -1;
    public const int MONITOR_OFF = 2;
    public const int MONITOR_STANDBY = 1;
    
    public static void TurnOffMonitor() {
        SendMessage(HWND_BROADCAST, WM_SYSCOMMAND, SC_MONITORPOWER, MONITOR_OFF);
    }
}
"@

# Wait a brief moment before turning off the monitor
Write-Host "关闭显示器中，请稍等1秒..."
Start-Sleep -Seconds 1

# Turn off the monitor
[MonitorControl]::TurnOffMonitor()

# Exit immediately to avoid any keypress turning the monitor back on
