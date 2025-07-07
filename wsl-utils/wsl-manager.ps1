# WSL管理工具
# 作者：Cascade
# 创建日期：2025-06-24

<#
.SYNOPSIS
    WSL (Windows Subsystem for Linux) 管理工具。

.DESCRIPTION
    此脚本提供了一系列功能来管理WSL实例，包括列出、启动、停止、
    备份、恢复、安装和卸载WSL发行版，以及管理WSL资源等。

.EXAMPLE
    .\wsl-manager.ps1 -List
    列出所有已安装的WSL发行版。

.EXAMPLE
    .\wsl-manager.ps1 -Start Ubuntu
    启动名为Ubuntu的WSL发行版。
#>



# 验证WSL是否已安装
function Test-WSLInstalled {
    try {
        $null = Get-Command wsl -ErrorAction Stop
        return $true
    } catch {
        Write-Host "错误: 未找到WSL命令。请确保WSL已安装并启用。" -ForegroundColor Red
        Write-Host "可以通过管理员PowerShell运行 'dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart' 启用WSL功能。" -ForegroundColor Yellow
        return $false
    }
}

# 列出所有已安装的WSL发行版
function List-WSLDistros {
    Write-Host "已安装的WSL发行版:" -ForegroundColor Green
    $result = wsl --list --verbose
    if ($result) {
        $result | ForEach-Object { Write-Host $_ }
    } else {
        Write-Host "未找到已安装的WSL发行版。" -ForegroundColor Yellow
    }
}

# 检查WSL状态
function Get-WSLStatus {
    Write-Host "WSL状态信息:" -ForegroundColor Green
    wsl --status
    Write-Host "`n默认WSL发行版：" -ForegroundColor Green
    wsl -l -v | Where-Object { $_ -match "默认" -or $_ -match "default" }
}

# 启动指定的WSL发行版
function Start-WSLDistro {
    param([string]$distroName)
    
    if ([string]::IsNullOrEmpty($distroName)) {
        Write-Host "错误: 请指定要启动的WSL发行版名称。" -ForegroundColor Red
        return
    }

    Write-Host "正在启动 $distroName..." -ForegroundColor Green
    try {
        wsl -d $distroName echo "WSL发行版已启动"
        Write-Host "$distroName 已成功启动。" -ForegroundColor Green
    } catch {
        Write-Host "启动 $distroName 时出错: $_" -ForegroundColor Red
    }
}

# 停止指定的WSL发行版
function Stop-WSLDistro {
    param([string]$distroName)
    
    if ([string]::IsNullOrEmpty($distroName)) {
        Write-Host "错误: 请指定要停止的WSL发行版名称。" -ForegroundColor Red
        return
    }

    Write-Host "正在停止 $distroName..." -ForegroundColor Green
    try {
        if ($distroName -eq "all") {
            wsl --shutdown
            Write-Host "所有WSL发行版已停止。" -ForegroundColor Green
        } else {
            wsl --terminate $distroName
            Write-Host "$distroName 已成功停止。" -ForegroundColor Green
        }
    } catch {
        Write-Host "停止 $distroName 时出错: $_" -ForegroundColor Red
    }
}

# 备份指定的WSL发行版
function Backup-WSLDistro {
    param(
        [string]$distroName,
        [string]$backupPath
    )
    
    if ([string]::IsNullOrEmpty($distroName)) {
        Write-Host "错误: 请指定要备份的WSL发行版名称。" -ForegroundColor Red
        return
    }

    # 创建备份目录（如果不存在）
    if (-not (Test-Path $backupPath)) {
        New-Item -Path $backupPath -ItemType Directory | Out-Null
    }

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFile = Join-Path $backupPath "$($distroName)_backup_$timestamp.tar"

    Write-Host "正在备份 $distroName 到 $backupFile..." -ForegroundColor Green

    try {
        # 先停止发行版以确保备份一致性
        wsl --terminate $distroName
        Start-Sleep -Seconds 2
        
        # 执行备份
        wsl --export $distroName $backupFile
        
        if (Test-Path $backupFile) {
            Write-Host "$distroName 已成功备份到 $backupFile" -ForegroundColor Green
        } else {
            Write-Host "备份失败：未找到备份文件。" -ForegroundColor Red
        }
    } catch {
        Write-Host "备份 $distroName 时出错: $_" -ForegroundColor Red
    }
}

# 恢复WSL发行版
function Restore-WSLDistro {
    param(
        [string]$distroName,
        [string]$restorePath
    )
    
    if ([string]::IsNullOrEmpty($distroName)) {
        Write-Host "错误: 请指定要恢复的WSL发行版名称。" -ForegroundColor Red
        return
    }

    if ([string]::IsNullOrEmpty($restorePath) -or -not (Test-Path $restorePath)) {
        Write-Host "错误: 无效的恢复文件路径。" -ForegroundColor Red
        return
    }

    Write-Host "正在恢复 $distroName 从 $restorePath..." -ForegroundColor Green
    
    try {
        # 检查发行版是否已存在，如果存在则先卸载
        $existingDistros = wsl --list --quiet
        if ($existingDistros -contains $distroName) {
            Write-Host "发行版 $distroName 已存在，将先卸载..." -ForegroundColor Yellow
            wsl --unregister $distroName
        }
        
        # 恢复发行版
        wsl --import $distroName "$env:LOCALAPPDATA\WSL\$distroName" $restorePath
        Write-Host "$distroName 已从备份成功恢复。" -ForegroundColor Green
    } catch {
        Write-Host "恢复 $distroName 时出错: $_" -ForegroundColor Red
    }
}

# 设置默认WSL发行版
function Set-DefaultWSL {
    param([string]$distroName)
    
    if ([string]::IsNullOrEmpty($distroName)) {
        Write-Host "错误: 请指定要设置为默认的WSL发行版名称。" -ForegroundColor Red
        return
    }

    Write-Host "正在将 $distroName 设置为默认WSL发行版..." -ForegroundColor Green
    try {
        wsl --set-default $distroName
        Write-Host "$distroName 已成功设置为默认WSL发行版。" -ForegroundColor Green
    } catch {
        Write-Host "设置 $distroName 为默认时出错: $_" -ForegroundColor Red
    }
}

# 安装新的WSL发行版
function Install-WSLDistro {
    param([string]$distroName)

    Write-Host "WSL发行版安装向导" -ForegroundColor Green
    
    if ([string]::IsNullOrEmpty($distroName)) {
        Write-Host "可安装的发行版: Ubuntu, Debian, kali-linux, openSUSE-Leap-15.2, SLES-12, Ubuntu-18.04, Ubuntu-20.04" -ForegroundColor Yellow
        $distroName = Read-Host "请输入要安装的发行版名称"
    }
    
    if ([string]::IsNullOrEmpty($distroName)) {
        Write-Host "未指定发行版，取消安装。" -ForegroundColor Red
        return
    }

    Write-Host "正在安装 $distroName..." -ForegroundColor Green
    try {
        wsl --install -d $distroName
        Write-Host "WSL发行版 $distroName 安装已开始。安装完成后可能需要重启计算机。" -ForegroundColor Green
    } catch {
        Write-Host "安装 $distroName 时出错: $_" -ForegroundColor Red
    }
}

# 卸载WSL发行版
function Uninstall-WSLDistro {
    param([string]$distroName)
    
    if ([string]::IsNullOrEmpty($distroName)) {
        Write-Host "错误: 请指定要卸载的WSL发行版名称。" -ForegroundColor Red
        return
    }

    Write-Host "警告: 即将卸载 $distroName，此操作将删除所有相关数据!" -ForegroundColor Yellow
    $confirmation = Read-Host "是否继续? (Y/N)"
    
    if ($confirmation -eq "Y" -or $confirmation -eq "y") {
        Write-Host "正在卸载 $distroName..." -ForegroundColor Green
        try {
            wsl --unregister $distroName
            Write-Host "$distroName 已成功卸载。" -ForegroundColor Green
        } catch {
            Write-Host "卸载 $distroName 时出错: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "卸载已取消。" -ForegroundColor Green
    }
}

# 更新WSL
function Update-WSL {
    Write-Host "正在更新WSL..." -ForegroundColor Green
    try {
        wsl --update
        Write-Host "WSL已成功更新到最新版本。" -ForegroundColor Green
    } catch {
        Write-Host "更新WSL时出错: $_" -ForegroundColor Red
    }
}

# 显示WSL资源使用情况
function Show-WSLResources {
    Write-Host "WSL资源使用情况:" -ForegroundColor Green
    
    try {
        # 使用tasklist获取WSL相关进程
        Write-Host "`nWSL进程:" -ForegroundColor Yellow
        $processes = Get-Process | Where-Object { $_.Name -like "*wsl*" }
        if ($processes) {
            $processes | Format-Table Id, Name, CPU, WorkingSet, Description -AutoSize
        } else {
            Write-Host "未找到运行中的WSL进程。" -ForegroundColor Yellow
        }
        
        # 显示WSL版本信息
        Write-Host "`nWSL版本信息:" -ForegroundColor Yellow
        wsl --version
    } catch {
        Write-Host "获取WSL资源信息时出错: $_" -ForegroundColor Red
    }
}


