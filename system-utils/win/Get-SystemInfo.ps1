<#
.SYNOPSIS
    检查并显示关键的 Windows 系统信息。
.DESCRIPTION
    本脚本旨在快速获取并展示当前 Windows 系统的核心配置与状态，
    包括操作系统版本、激活状态、硬件信息（CPU、内存、磁盘）等。
    所有操作均为只读，不会对系统进行任何修改。
.NOTES
    Author: Your Name
    Version: 1.1
    Last Modified: 2024-07-01
#>

#Requires -Version 5.1

# --- 函数定义 ---

function Get-DiskInfo {
    <#
    .SYNOPSIS
        获取所有物理磁盘的详细信息，并以自定义对象输出。
    #>
    param()
    Get-PhysicalDisk | Select-Object DeviceID, FriendlyName, MediaType, @{Name="Size(GB)";Expression={[math]::Round($_.Size / 1GB, 2)}}, HealthStatus, BusType
}

function Get-WindowsActivationStatus {
    <#
    .SYNOPSIS
        通过 WMI 查询并返回 Windows 的激活状态。
    #>
    param()
    # 此处的 ApplicationID 是 Windows 操作系统自身的标识符
    $activation = Get-CimInstance -ClassName SoftwareLicensingProduct -Filter "ApplicationID = '55c92734-d682-4d71-983e-d6ec3f16059f' and LicenseStatus = 1"
    if ($activation) {
        return "✅ 已激活 (Licensed)"
    } else {
        return "❌ 未激活或状态未知"
    }
}

function Show-SystemInfo {
    # --- 主程序 ---
    Clear-Host

    Write-Host "=================================================" -ForegroundColor Yellow
    Write-Host "==             Windows 系统信息检查            ==" -ForegroundColor Yellow
    Write-Host "=================================================" -ForegroundColor Yellow
    Write-Host ""

    # 操作系统信息
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    Write-Host "💻 操作系统" -ForegroundColor Cyan
    Write-Host "   - 名称: $($osInfo.Caption)"
    Write-Host "   - 版本: $($osInfo.Version)"
    Write-Host "   - 状态: $(Get-WindowsActivationStatus)"
    Write-Host ""

    # 硬件信息
    $cpuInfo = Get-CimInstance -ClassName Win32_Processor
    $memoryInfo = Get-CimInstance -ClassName Win32_ComputerSystem
    Write-Host "⚙️  硬件核心" -ForegroundColor Cyan
    Write-Host "   - CPU: $($cpuInfo.Name)"
    Write-Host "   - 物理内存: $([math]::Round($memoryInfo.TotalPhysicalMemory / 1GB, 2)) GB"
    Write-Host ""

    # 磁盘信息
    Write-Host "💾 磁盘信息" -ForegroundColor Cyan
    Get-DiskInfo | Format-Table -AutoSize

    Write-Host "检查完成。"
}

# --- 脚本入口 ---
Show-SystemInfo
Read-Host "按回车键退出..."
