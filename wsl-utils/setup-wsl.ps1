#Requires -RunAsAdministrator

<#
.SYNOPSIS
    一键式安装和配置 Windows Subsystem for Linux (WSL) 2。
.DESCRIPTION
    此脚本将自动执行以下操作：
    1. 检查并确保以管理员权限运行。
    2. 启用“虚拟机平台”和“适用于 Linux 的 Windows 子系统”功能。
    3. 安装 WSL 核心组件和默认的 Ubuntu 发行版。
    4. 将 WSL 2 设置为默认版本。

    此脚本旨在 Windows 10 2004 (Build 19041) 及更高版本或 Windows 11 上运行。
    运行前请确保您的网络连接正常。
.NOTES
    作者: Cascade
    版本: 1.0
    文件名: setup-wsl.ps1
#>

function Install-WslEnvironment {
    Write-Host "开始 WSL 2 自动化安装..." -ForegroundColor Green

    # 'wsl --install' 是现代的、一体化的安装命令。
    # 它会自动启用所需功能、下载内核、将 WSL 2 设为默认，并安装默认发行版 (Ubuntu)。
    # 此命令需要网络连接。

    Write-Host "正在执行 'wsl --install'。此过程可能需要几分钟时间。" -ForegroundColor Cyan
    Write-Host "该命令将启用所需的 Windows 功能并安装 Ubuntu。" -ForegroundColor Cyan
    
    # 我们使用 --no-launch 参数，以便在脚本中控制流程，而不是立即启动 Ubuntu。
    wsl.exe --install --no-launch
    $exitCode = $LASTEXITCODE

    # wsl --install 在需要重启时会返回特定退出码 3010 (0xBC2)
    # ERROR_SUCCESS_REBOOT_REQUIRED
    if ($exitCode -eq 0) {
        Write-Host "WSL 安装命令已成功完成。" -ForegroundColor Green
    } elseif ($exitCode -eq 3010) {
        Write-Host "需要重启计算机以完成 WSL 安装。" -ForegroundColor Yellow
        Write-Host "请重启您的计算机，然后在开始菜单中运行 'Ubuntu' 来完成发行版的初始化设置。" -ForegroundColor Yellow
        return
    } else {
        Write-Host "WSL 安装失败，退出码: $exitCode" -ForegroundColor Red
        Write-Host "请检查上面的输出以获取错误信息。您可能需要先运行 Windows 更新。" -ForegroundColor Red
        return
    }

    Write-Host "正在更新 WSL 内核..." -ForegroundColor Cyan
    wsl.exe --update
    if ($LASTEXITCODE -ne 0) {
        Write-Host "无法更新 WSL 内核。可能是因为需要重启或网络连接问题。" -ForegroundColor Yellow
    } else {
        Write-Host "WSL 内核更新成功。" -ForegroundColor Green
    }

    Write-Host "正在将 WSL 2 设置为默认版本..." -ForegroundColor Cyan
    wsl.exe --set-default-version 2
    if ($LASTEXITCODE -ne 0) {
        Write-Host "无法将 WSL 2 设置为默认版本。" -ForegroundColor Yellow
    } else {
        Write-Host "已成功将 WSL 2 设置为默认版本。" -ForegroundColor Green
    }
    
    Write-Host "WSL 环境安装脚本执行完毕。" -ForegroundColor Green
    Write-Host "如果脚本没有提示重启，您现在可以在开始菜单中找到 'Ubuntu'。" -ForegroundColor Green
    Write-Host "首次启动时，它将完成安装并要求您创建 Linux 用户名和密码。" -ForegroundColor Green
}

# 执行主函数
Install-WslEnvironment
