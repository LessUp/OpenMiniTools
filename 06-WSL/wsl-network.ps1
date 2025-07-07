# WSL 网络管理工具
# 作者：Cascade
# 创建日期：2025-06-24

<#
.SYNOPSIS
    一个用于管理和排查WSL网络问题的工具。

.DESCRIPTION
    此脚本提供了获取WSL IP地址、管理端口转发、修复DNS问题以及重置网络等功能。

.EXAMPLE
    .\wsl-network.ps1 -GetIP Ubuntu
    获取名为Ubuntu的发行版的IP地址。

.EXAMPLE
    .\wsl-network.ps1 -AddPortForward -ListenPort 8080 -ForwardPort 80 -Distro Ubuntu
    将Windows的8080端口转发到Ubuntu发行版的80端口。
#>



# 检查管理员权限
function Test-AdminPrivileges {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

# 获取指定WSL发行版的IP地址
function Get-WSLIPAddress {
    param ([string]$distroName)

    if ([string]::IsNullOrEmpty($distroName)) {
        Write-Host "错误: 请指定发行版名称。" -ForegroundColor Red
        return
    }

    Write-Host "正在获取 '$distroName' 的IP地址..." -ForegroundColor Green
    try {
        # 执行Linux命令获取网络信息
        $output = wsl.exe -d $distroName -- ip addr show eth0
        # 使用PowerShell的Select-String来过滤包含IP地址的行
        $inetLine = $output | Select-String -Pattern "inet " -ErrorAction Stop
        
        # 从匹配行中解析出IP地址
        # Trim()移除前后空格, -split '\s+' 按一个或多个空格分割, [1] 取出IP/掩码部分
        $ipAndMask = ($inetLine.Line.Trim() -split '\s+')[1]
        # 按'/'分割并取出IP地址部分
        $ipAddress = $ipAndMask.Split('/')[0]

        if ($ipAddress -match '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}') {
            Write-Host "$distroName 的IP地址是: $ipAddress" -ForegroundColor Cyan
            return $ipAddress
        } else {
            Write-Host "无法从 '$distroName' 的网络配置中解析出有效的IP地址。" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "获取IP地址时出错: $_" -ForegroundColor Red
        Write-Host "请确保 '$distroName' 正在运行，网络已连接，并且 'ip' 命令可用。" -ForegroundColor Yellow
    }
    return $null
}

# 添加端口转发规则
function Add-WSLPortForward {
    param (
        [int]$listenPort,
        [int]$forwardPort,
        [string]$distroName
    )

    if (-not (Test-AdminPrivileges)) {
        Write-Host "错误: 添加端口转发需要管理员权限。" -ForegroundColor Red
        return
    }

    $wslIP = Get-WSLIPAddress -distroName $distroName
    if (-not $wslIP) { return }

    Write-Host "正在添加端口转发规则: 0.0.0.0:${listenPort} -> ${wslIP}:${forwardPort}" -ForegroundColor Green
    try {
        netsh interface portproxy add v4tov4 listenport=$listenPort listenaddress=0.0.0.0 connectport=$forwardPort connectaddress=$wslIP
        Write-Host "端口转发规则添加成功。" -ForegroundColor Green
        Write-Host "请确保Windows防火墙允许端口 $listenPort 的入站连接。" -ForegroundColor Yellow
    } catch {
        Write-Host "添加端口转发时出错: $_" -ForegroundColor Red
    }
}

# 移除端口转发规则
function Remove-WSLPortForward {
    param ([int]$listenPort)

    if (-not (Test-AdminPrivileges)) {
        Write-Host "错误: 移除端口转发需要管理员权限。" -ForegroundColor Red
        return
    }

    Write-Host "正在移除监听端口 $listenPort 的转发规则..." -ForegroundColor Green
    try {
        netsh interface portproxy delete v4tov4 listenport=$listenPort listenaddress=0.0.0.0
        Write-Host "端口转发规则移除成功。" -ForegroundColor Green
    } catch {
        Write-Host "移除端口转发时出错: $_" -ForegroundColor Red
    }
}

# 修复WSL的DNS问题
function Repair-WSLDNS {
    param ([string]$distroName)

    Write-Host "警告: 此操作将覆盖 '$distroName' 中的 /etc/resolv.conf 文件。" -ForegroundColor Yellow
    $confirmation = Read-Host "是否继续? (Y/N)"
    if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
        Write-Host "操作已取消。" -ForegroundColor Green
        return
    }

    Write-Host "正在尝试修复 '$distroName' 的DNS配置..." -ForegroundColor Green
    try {
        # 禁用并重新启用自动生成resolv.conf
        $wslConfContent = "[network]`ngenerateResolvConf = false"
        $wslConfContent | wsl -d $distroName -u root -- tee /etc/wsl.conf > $null
        Write-Host "已禁用自动DNS生成。正在重启发行版以应用..."
        wsl --terminate $distroName
        Start-Sleep -Seconds 5

        # 手动设置DNS
        $dnsContent = "nameserver 8.8.8.8`nnameserver 1.1.1.1"
        $dnsContent | wsl -d $distroName -u root -- tee /etc/resolv.conf > $null
        Write-Host "已手动设置DNS。请测试网络连接。"

        # 提示用户恢复自动配置
        Write-Host "`n如果问题解决，您可以考虑恢复自动DNS配置。" -ForegroundColor Yellow
        Write-Host "要恢复，请在 '$distroName' 中运行: 'sudo rm /etc/wsl.conf' 然后重启发行版。" -ForegroundColor Yellow
    } catch {
        Write-Host "修复DNS时出错: $_" -ForegroundColor Red
    }
}

# 重置WSL网络
function Reset-WSLNetwork {
    if (-not (Test-AdminPrivileges)) {
        Write-Host "错误: 重置网络需要管理员权限。" -ForegroundColor Red
        return
    }

    Write-Host "警告: 此操作将重置Windows的网络堆栈并关闭WSL。" -ForegroundColor Yellow
    $confirmation = Read-Host "是否继续? (Y/N)"
    if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
        Write-Host "操作已取消。" -ForegroundColor Green
        return
    }

    try {
        Write-Host "正在关闭WSL..." -ForegroundColor Green
        wsl --shutdown
        Start-Sleep -Seconds 3

        Write-Host "正在重置网络配置..." -ForegroundColor Green
        netsh winsock reset | Out-Null
        netsh int ip reset | Out-Null

        Write-Host "网络重置完成。建议您现在重启计算机以使所有更改生效。" -ForegroundColor Cyan
    } catch {
        Write-Host "重置网络时出错: $_" -ForegroundColor Red
    }
}

# 显示帮助信息
function Show-Help {
    Get-Help $PSCommandPath -Detailed
}


