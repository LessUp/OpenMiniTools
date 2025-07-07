<#
.SYNOPSIS
    停止后台运行的 SSH SOCKS5 代理进程，并清理所有相关的临时配置文件。
.DESCRIPTION
    本脚本通过读取 .proxy-pid 文件来识别并终止代理进程，
    然后删除由 start-proxy.ps1 创建的条件性 Git 配置文件，
    从而彻底、干净地关闭代理。
.NOTES
    Author: Your Name
    Version: 1.1
    Last Modified: 2024-07-01
#>

#Requires -Version 5.1

# --- 内部变量定义 ---
$ScriptRoot = $PSScriptRoot
$PidFile = Join-Path -Path $ScriptRoot -ChildPath ".proxy-pid"
$ConditionalGitConfigFile = Join-Path -Path $env:USERPROFILE -ChildPath ".gitconfig-proxy"

# --- 函数定义 ---

function Stop-ProxyProcess {
    Write-Host "[*] 步骤 1: 正在停止代理进程..."
    if (-not (Test-Path -Path $PidFile)) {
        Write-Host "    [信息] 未找到 PID 文件，无需停止进程。" -ForegroundColor Cyan
        return
    }

    try {
        $processId = Get-Content -Path $PidFile -ErrorAction Stop
        $process = Get-Process -Id $processId -ErrorAction SilentlyContinue

        if ($process) {
            Stop-Process -Id $processId -Force
            Write-Host "    [成功] 代理进程 (PID: $processId) 已终止。" -ForegroundColor Green
        } else {
            Write-Host "    [信息] 未找到进程号为 $processId 的进程，可能已被手动停止。" -ForegroundColor Cyan
        }
    } catch {
        Write-Host "    [警告] 无法读取 PID 文件或 PID 无效。" -ForegroundColor Yellow
    } finally {
        # 无论成功与否，都清理 PID 文件
        Remove-Item -Path $PidFile -Force -ErrorAction SilentlyContinue
        Write-Host "    [成功] PID 文件已清理。" -ForegroundColor Green
    }
}

function Clean-GitConfig {
    Write-Host "[*] 步骤 2: 正在清理代理配置文件..."
    if (-not (Test-Path -Path $ConditionalGitConfigFile)) {
        Write-Host "    [信息] 未找到代理配置文件，无需清理。" -ForegroundColor Cyan
        return
    }

    try {
        Remove-Item -Path $ConditionalGitConfigFile -Force
        Write-Host "    [成功] 已成功移除 '$ConditionalGitConfigFile'。" -ForegroundColor Green
    } catch {
        Write-Host "    [错误] 移除配置文件时出错: $_" -ForegroundColor Red
    }
}

# --- 主程序 ---
Clear-Host
Write-Host "======================================"
Write-Host "==      通用 Git 代理停止程序       =="
Write-Host "======================================"
Write-Host ""

Stop-ProxyProcess
Write-Host ""
Clean-GitConfig

Write-Host ""
Write-Host "======================================"
Write-Host "==         所有清理操作已完成         =="
Write-Host "======================================"
Read-Host "按回车键退出..."
