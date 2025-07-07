<#
.SYNOPSIS
    启动一个后台 SSH SOCKS5 代理，并为特定的私有 Git 服务器配置代理。
.DESCRIPTION
    本脚本通过连接到 SSH 跳板机，在本地创建一个 SOCKS5 代理。
    然后，它会生成一个临时的 Git 配置文件，使得只有匹配特定域名的 Git 操作
    才会通过此代理进行，从而实现全局配置的隔离。
.NOTES
    Author: Your Name
    Version: 1.1
    Last Modified: 2024-07-01
#>

#Requires -Version 5.1

# ========================= 脚本配置 (请自定义) =========================

# 在 ~/.ssh/config 文件中定义的、用于创建 SOCKS 代理的 SSH 别名
$TargetHost = "gitlab-proxy"

# SOCKS 代理的本地监听端口 (必须与 ssh_config 中的 DynamicForward 端口一致)
$SocksPort  = 1080

# 【重要】您私有 Git 服务器的域名
$GitServerDomain = "your-git-server.com"

# =====================================================================

# --- 内部变量定义 ---
$ScriptRoot = $PSScriptRoot
$PidFile = Join-Path -Path $ScriptRoot -ChildPath ".proxy-pid"
$GitProxyConfigFile = Join-Path -Path $env:USERPROFILE -ChildPath ".gitconfig-proxy"

# --- 函数定义 ---

function Test-ProxyRunning {
    if (-not (Test-Path -Path $PidFile)) {
        return $false
    }
    $existingPid = Get-Content -Path $PidFile
    if (Get-Process -Id $existingPid -ErrorAction SilentlyContinue) {
        Write-Host "[警告] 代理已在运行 (进程号 PID: $existingPid)" -ForegroundColor Yellow
        return $true
    }
    return $false
}

function Create-GitProxyConfig {
    Write-Host "[信息] 正在为 $GitServerDomain 创建 Git 代理配置..." -ForegroundColor Cyan
    
    # 使用 Here-String 创建配置文件内容
    $proxyConfigContent = @"
#
# 本文件由 start-proxy.ps1 自动生成
# 修改无效，因为每次启动都会被覆盖
#
[http "https://$GitServerDomain/"]
    proxy = socks5://127.0.0.1:$SocksPort
"@

    try {
        Set-Content -Path $GitProxyConfigFile -Value $proxyConfigContent -Encoding UTF8 -Force
        Write-Host "[成功] Git 代理配置文件已创建于: $GitProxyConfigFile" -ForegroundColor Green
    } catch {
        Write-Host "[错误] 创建 Git 配置文件时出错: $_" -ForegroundColor Red
        throw "无法创建 Git 配置文件。"
    }
}

function Start-SshProxy {
    Write-Host "[信息] 正在后台启动 SSH SOCKS 代理..." -ForegroundColor Cyan
    
    $SshConfigPath = Join-Path -Path $env:USERPROFILE -ChildPath ".ssh\config"
    $commandLine = "ssh.exe -F `"$SshConfigPath`" -N $TargetHost"

    # 使用 WMI (Windows Management Instrumentation) 创建一个完全隐藏的后台进程。
    # 这是在 PowerShell 中实现真正后台运行的可靠方法。
    $startupConfig = New-CimInstance -ClassName Win32_ProcessStartup -Property @{ ShowWindow = [uint16]0 } -ClientOnly
    $processInfo = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{
        CommandLine = $commandLine
        ProcessStartupInformation = $startupConfig
    }

    if ($processInfo.ReturnValue -ne 0) {
        throw "使用 WMI 启动 SSH 进程失败。错误码: $($processInfo.ReturnValue)"
    }
    
    # 返回新创建进程的 PID
    return $processInfo.ProcessId
}

function Verify-ProxyAndSavePid {
    param($ProcessId)
    
    Write-Host "[信息] 正在等待代理在端口 $SocksPort 上完成初始化..."
    Start-Sleep -Seconds 3 # 等待几秒钟，让 SSH 进程有足够时间建立连接并监听端口

    try {
        # 验证端口是否真的在监听
        $connection = Get-NetTCPConnection -LocalPort $SocksPort -State Listen -ErrorAction Stop
        if ($connection -and ($connection.OwningProcess -eq $ProcessId)) {
            $ProcessId | Out-File -FilePath $PidFile
            Write-Host "[成功] 代理已成功启动: socks5://127.0.0.1:$SocksPort (进程号 PID: $ProcessId)" -ForegroundColor Green
            Write-Host "[提示] 请运行 '.\stop-proxy.ps1' 来终止代理。"
        } else {
            throw "检测到端口监听，但进程号不匹配。"
        }
    } catch {
        Write-Host "[错误] 启动后未能检测到在端口 $SocksPort 上的监听进程。" -ForegroundColor Red
        Write-Host "[调试] 请尝试手动运行命令进行调试: ssh -v $TargetHost"
        # 杀掉刚刚启动的僵尸进程
        Stop-Process -Id $ProcessId -Force -ErrorAction SilentlyContinue
        throw "代理启动失败。"
    }
}

# --- 主程序 ---
try {
    if (Test-ProxyRunning) {
        # 如果代理已在运行，则直接退出
        exit
    }

    Create-GitProxyConfig
    $newPid = Start-SshProxy
    Verify-ProxyAndSavePid -ProcessId $newPid

} catch {
    # 捕获任何在执行过程中抛出的异常
    Write-Host "[致命错误] 脚本执行失败: $_" -ForegroundColor Red
    # 清理掉可能已创建的配置文件
    if (Test-Path -Path $GitProxyConfigFile) {
        Remove-Item -Path $GitProxyConfigFile -Force
    }
} finally {
    Write-Host ""
    Read-Host "按回车键退出..."
}
