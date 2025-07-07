# WSL 备份与恢复工具
# 作者：Cascade
# 创建日期：2025-06-24

<#
.SYNOPSIS
    一个专门用于备份和恢复WSL发行版的工具。

.DESCRIPTION
    此脚本提供了比 wsl-manager.ps1 中更高级的备份和恢复功能，
    包括备份所有发行版、备份轮换、以及更灵活的恢复选项。

.EXAMPLE
    .\wsl-backup-restore.ps1 -BackupDistro Ubuntu -BackupPath C:\wsl_backups
    备份名为Ubuntu的发行版到指定目录。

.EXAMPLE
    .\wsl-backup-restore.ps1 -RestoreDistro Ubuntu -BackupFile C:\wsl_backups\Ubuntu_backup.tar
    从指定的备份文件恢复Ubuntu发行版。
#>



# 显示帮助信息
function Show-Help {
    Get-Help $PSCommandPath -Detailed
}

# 验证WSL是否已安装
function Test-WSLInstalled {
    try {
        $null = Get-Command wsl -ErrorAction Stop
        return $true
    } catch {
        Write-Host "错误: 未找到WSL命令。请确保WSL已安装并启用。" -ForegroundColor Red
        return $false
    }
}

# 备份单个WSL发行版
function Backup-SingleDistro {
    param(
        [string]$distroName,
        [string]$backupPath,
        [int]$keepLast
    )

    if ([string]::IsNullOrEmpty($distroName)) {
        Write-Host "错误: 未指定要备份的发行版名称。" -ForegroundColor Red
        return
    }

    # 检查发行版是否存在
    $distros = wsl --list --quiet
    if (-not ($distros -contains $distroName)) {
        Write-Host "错误: 发行版 '$distroName' 不存在。" -ForegroundColor Red
        return
    }

    # 创建备份目录
    if (-not (Test-Path $backupPath)) {
        New-Item -Path $backupPath -ItemType Directory | Out-Null
    }

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFile = Join-Path $backupPath "${distroName}_backup_${timestamp}.tar"

    Write-Host "正在备份 $distroName 到 $backupFile..." -ForegroundColor Green

    try {
        # 停止发行版以确保数据一致性
        wsl --terminate $distroName
        Start-Sleep -Seconds 2

        # 执行备份
        wsl --export $distroName $backupFile

        if (Test-Path $backupFile) {
            Write-Host "$distroName 已成功备份到 $backupFile" -ForegroundColor Green
            # 执行备份轮换
            Invoke-BackupRotation -distroName $distroName -backupPath $backupPath -keepLast $keepLast
        } else {
            Write-Host "备份失败：未找到备份文件。" -ForegroundColor Red
        }
    } catch {
        Write-Host "备份 $distroName 时出错: $_" -ForegroundColor Red
    }
}

# 备份轮换，删除旧的备份
function Invoke-BackupRotation {
    param(
        [string]$distroName,
        [string]$backupPath,
        [int]$keepLast
    )

    if ($keepLast -le 0) { return } # 如果keepLast为0或负数，则不执行轮换

    $backups = Get-ChildItem -Path $backupPath -Filter "${distroName}_backup_*.tar" | Sort-Object LastWriteTime -Descending

    if ($backups.Count -gt $keepLast) {
        $backupsToClean = $backups[$keepLast..($backups.Count - 1)]
        foreach ($backup in $backupsToClean) {
            Write-Host "正在删除旧备份: $($backup.FullName)" -ForegroundColor Yellow
            Remove-Item $backup.FullName -Force
        }
    }
}

# 恢复WSL发行版
function Restore-WSLDistro {
    param(
        [string]$distroName,
        [string]$restoreFile,
        [string]$newDistroName
    )

    if ([string]::IsNullOrEmpty($distroName)) {
        Write-Host "错误: 请指定要恢复的发行版名称。" -ForegroundColor Red
        return
    }

    if ([string]::IsNullOrEmpty($restoreFile) -or -not (Test-Path $restoreFile)) {
        Write-Host "错误: 无效的恢复文件路径 '$restoreFile'。" -ForegroundColor Red
        return
    }

    $targetDistroName = if ([string]::IsNullOrEmpty($newDistroName)) { $distroName } else { $newDistroName }
    $installPath = "$env:LOCALAPPDATA\WSL\$targetDistroName"

    Write-Host "正在从 $restoreFile 恢复到 $targetDistroName..." -ForegroundColor Green

    try {
        # 检查目标发行版是否已存在
        $existingDistros = wsl --list --quiet
        if ($existingDistros -contains $targetDistroName) {
            Write-Host "警告: 发行版 '$targetDistroName' 已存在。将先卸载它。" -ForegroundColor Yellow
            $confirmation = Read-Host "此操作将删除现有数据，是否继续? (Y/N)"
            if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
                Write-Host "恢复操作已取消。" -ForegroundColor Green
                return
            }
            wsl --unregister $targetDistroName
            Start-Sleep -Seconds 2
            # 删除旧的安装目录
            if (Test-Path $installPath) {
                Remove-Item -Recurse -Force $installPath
            }
        }

        # 创建安装目录
        New-Item -Path $installPath -ItemType Directory | Out-Null

        # 恢复发行版
        wsl --import $targetDistroName $installPath $restoreFile --version 2
        Write-Host "$targetDistroName 已从备份成功恢复。" -ForegroundColor Green
    } catch {
        Write-Host "恢复 $targetDistroName 时出错: $_" -ForegroundColor Red
    }
}

# 列出备份文件
function Get-AvailableBackups {
    param([string]$backupPath)

    if (-not (Test-Path $backupPath)) {
        Write-Host "备份目录 '$backupPath' 不存在。" -ForegroundColor Red
        return
    }

    Write-Host "在 '$backupPath' 中可用的备份:" -ForegroundColor Green
    Get-ChildItem -Path $backupPath -Filter "*.tar" | ForEach-Object {
        Write-Host "- $($_.Name) ($($_.LastWriteTime))"
    }
}


