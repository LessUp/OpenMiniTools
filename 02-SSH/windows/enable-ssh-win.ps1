# -----------------------------------------------------------------------------
# 脚本名称: Enable-SSH.ps1
# 功能描述: 检查并自动开启 Windows 上的 SSH 服务 (OpenSSH Server)。
#           - 检查并安装 OpenSSH Server 功能
#           - 设置 sshd 服务为自动启动并启动该服务
#           - 检查、创建或启用防火墙规则以允许 SSH 连接
# 作者:     AI Assistant & USER
# 版本:     1.2
# -----------------------------------------------------------------------------

# --- 1. 检查是否以管理员身份运行 ---
Write-Host "正在检查管理员权限..." -ForegroundColor Yellow
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "错误：此脚本需要管理员权限才能运行。" -ForegroundColor Red
    Write-Host "请右键单击脚本文件，然后选择 '以管理员身份运行'。" -ForegroundColor Red
    if ($Host.Name -eq "ConsoleHost") {
        Read-Host "按 Enter 键退出"
    }
    exit 1
}
Write-Host "权限检查通过，已获得管理员权限。" -ForegroundColor Green
Write-Host ""

# --- 2. 检查并安装 OpenSSH Server 功能 ---
Write-Host "--- OpenSSH Server 功能检查与安装 ---" -ForegroundColor Cyan
$sshFeature = Get-WindowsCapability -Online | Where-Object { $_.Name -like 'OpenSSH.Server*' }

if ($null -eq $sshFeature) {
    Write-Host "错误：无法查询到 OpenSSH Server 功能。请确保 Windows 更新服务正在运行或系统支持此功能。" -ForegroundColor Red
    exit 1
}

Write-Host "正在检查 OpenSSH Server 功能 ($($sshFeature.Name)) 是否已安装..." -ForegroundColor Yellow
if ($sshFeature.State -ne 'Installed') {
    Write-Host "OpenSSH Server 功能未安装，正在尝试安装..." -ForegroundColor Yellow
    try {
        Add-WindowsCapability -Online -Name $sshFeature.Name -ErrorAction Stop
        Write-Host "OpenSSH Server 功能已成功安装。" -ForegroundColor Green
        # 重新获取功能状态，确保后续步骤使用最新的状态
        $sshFeature = Get-WindowsCapability -Online | Where-Object { $_.Name -eq $sshFeature.Name }
    }
    catch {
        Write-Host "错误：安装 OpenSSH Server 功能失败。" -ForegroundColor Red
        Write-Host "错误详情: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "OpenSSH Server 功能已安装。" -ForegroundColor Green
}
Write-Host ""

# --- 3. 配置并启动 sshd 服务 ---
Write-Host "--- SSH 服务 (sshd) 配置与启动 ---" -ForegroundColor Cyan
$serviceName = "sshd"
$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

if ($null -eq $service) {
    Write-Host "错误：未找到 SSH 服务 (sshd)。OpenSSH Server 可能未正确安装。" -ForegroundColor Red
    exit 1
}

Write-Host "正在检查 SSH 服务 (sshd) 状态..." -ForegroundColor Yellow
if ($service.Status -eq "Running") {
    Write-Host "SSHD 服务已经在运行。" -ForegroundColor Green
} else {
    Write-Host "SSHD 服务当前状态: $($service.Status)。正在尝试启动..." -ForegroundColor Yellow
    try {
        Start-Service -Name $serviceName -ErrorAction Stop
        # 等待服务状态变为 Running，最多等待10秒
        $service.WaitForStatus('Running', (New-TimeSpan -Seconds 10))
        $service = Get-Service -Name $serviceName # Refresh service object
        if ($service.Status -eq "Running") {
            Write-Host "SSHD 服务已成功启动。" -ForegroundColor Green
        } else {
            Write-Host "错误：启动 SSHD 服务后，服务状态为 $($service.Status)。请检查事件查看器中的系统日志以获取更多信息。" -ForegroundColor Red
            exit 1
        }
    }
    catch {
        Write-Host "错误：启动 SSHD 服务失败。" -ForegroundColor Red
        Write-Host "错误详情: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "请尝试手动启动服务 'sshd' 并检查事件查看器中的相关日志。" -ForegroundColor Yellow
        exit 1
    }
}

if ($service.StartType -ne "Automatic") {
    Write-Host "正在设置 SSHD 服务启动类型为自动..." -ForegroundColor Yellow
    try {
        Set-Service -Name $serviceName -StartupType Automatic -ErrorAction Stop
        Write-Host "SSHD 服务启动类型已设置为自动。" -ForegroundColor Green
    }
    catch {
        Write-Host "错误：设置 SSHD 服务启动类型为自动失败。" -ForegroundColor Red
        Write-Host "错误详情: $($_.Exception.Message)" -ForegroundColor Red
        # Non-critical error, so we don't exit
    }
} else {
    Write-Host "SSHD 服务启动类型已经是自动。" -ForegroundColor Green
}
Write-Host ""

# --- 4. 检查并配置防火墙规则 ---
Write-Host "--- 防火墙规则检查与配置 ---" -ForegroundColor Cyan
$firewallRuleName = "OpenSSH-Server-In-TCP" # Default rule name for OpenSSH Server
$sshProgramPath = Join-Path -Path $env:SystemRoot -ChildPath "System32\OpenSSH\sshd.exe"

Write-Host "正在检查防火墙规则 '$firewallRuleName'...'" -ForegroundColor Yellow
$rule = Get-NetFirewallRule -DisplayName $firewallRuleName -ErrorAction SilentlyContinue

if ($null -ne $rule) {
    if ($rule.Enabled -eq $true) {
        Write-Host "防火墙规则 '$firewallRuleName' 已存在并已启用。" -ForegroundColor Green
    } else {
        Write-Host "防火墙规则 '$firewallRuleName' 已存在但未启用，正在尝试启用..." -ForegroundColor Yellow
        try {
            Enable-NetFirewallRule -DisplayName $firewallRuleName -ErrorAction Stop
            Write-Host "防火墙规则 '$firewallRuleName' 已成功启用。" -ForegroundColor Green
        }
        catch {
            Write-Host "错误：启用防火墙规则 '$firewallRuleName' 失败。" -ForegroundColor Red
            Write-Host "错误详情: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "防火墙规则 '$firewallRuleName' 未找到，正在尝试创建并启用..." -ForegroundColor Yellow
    try {
        New-NetFirewallRule -DisplayName $firewallRuleName -Direction Inbound -Action Allow -Protocol TCP -LocalPort 22 -Program $sshProgramPath -Enabled True -ErrorAction Stop
        Write-Host "防火墙规则 '$firewallRuleName' 已成功创建并启用。" -ForegroundColor Green
    }
    catch {
        Write-Host "错误：创建防火墙规则 '$firewallRuleName' 失败。" -ForegroundColor Red
        Write-Host "错误详情: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "请手动检查防火墙设置，确保 TCP 端口 22 (入站) 对程序 '$sshProgramPath' 开放。" -ForegroundColor Yellow
    }
}
Write-Host ""

Write-Host "SSH 服务配置完成。" -ForegroundColor Green
Write-Host "你现在应该可以使用 SSH 连接到此计算机。" -ForegroundColor Green

if ($Host.Name -eq "ConsoleHost") {
    Read-Host "按 Enter 键退出"
}

Write-Host "-----------------------------------------" -ForegroundColor Cyan
Get-Service -Name $serviceName | Format-List Name, DisplayName, Status, StartupType
Write-Host "-----------------------------------------" -ForegroundColor Cyan