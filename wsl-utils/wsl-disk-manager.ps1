# WSL 磁盘管理工具
# 作者：Cascade
# 创建日期：2025-06-24

<#
.SYNOPSIS
    管理WSL2发行版磁盘空间的工具。

.DESCRIPTION
    此脚本可以帮助您查看WSL2发行版虚拟磁盘（.vhdx）的大小，并提供压缩功能以回收未使用的磁盘空间。

.EXAMPLE
    .\wsl-disk-manager.ps1 -ShowUsage
    显示所有已安装WSL发行版的磁盘使用情况。

.EXAMPLE
    .\wsl-disk-manager.ps1 -CompactDistro Ubuntu
    压缩名为Ubuntu的发行版的虚拟磁盘。需要管理员权限。
#>



# 检查管理员权限
function Test-AdminPrivileges {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

# 获取WSL发行版VHDX文件的路径
function Get-VHDXPath {
    param ([string]$distroName)

    try {
        # 尝试通过Get-AppxPackage查找路径
        $package = Get-AppxPackage | Where-Object { $_.Name -like "*$distroName*" -and $_.IsFramework -eq $false }
        if ($package) {
            $vhdxPath = Join-Path $package.InstallLocation "LocalState\ext4.vhdx"
            if (Test-Path $vhdxPath) {
                return $vhdxPath
            }
        }

        # 如果上述方法失败，则在通用位置搜索
        $basePath = "$env:LOCALAPPDATA\Packages"
        $packages = Get-ChildItem -Path $basePath -Directory -Filter "*$distroName*"
        foreach ($pkg in $packages) {
            $vhdxPath = Join-Path $pkg.FullName "LocalState\ext4.vhdx"
            if (Test-Path $vhdxPath) {
                return $vhdxPath
            }
        }
        return $null
    } catch {
        Write-Host "查找 '$distroName' 的VHDX文件时出错: $_" -ForegroundColor Red
        return $null
    }
}

# 显示所有发行版的磁盘使用情况
function Show-DistroDiskUsage {
    Write-Host "正在获取WSL发行版磁盘使用情况..." -ForegroundColor Green
    $distros = wsl --list --quiet

    if (-not $distros) {
        Write-Host "未找到已安装的WSL发行版。" -ForegroundColor Yellow
        return
    }

    foreach ($distro in $distros) {
        Write-Host "`n发行版: $distro" -ForegroundColor Cyan
        $vhdxPath = Get-VHDXPath -distroName $distro
        if ($vhdxPath) {
            $fileInfo = Get-Item $vhdxPath
            $sizeGB = [math]::Round($fileInfo.Length / 1GB, 2)
            Write-Host "  - VHDX 路径: $vhdxPath"
            Write-Host "  - 磁盘占用: $sizeGB GB"
        } else {
            Write-Host "  - 未能定位到VHDX文件。可能不是WSL2发行版或安装在非标准位置。" -ForegroundColor Yellow
        }
    }
}

# 压缩指定的WSL发行版磁盘
function Invoke-WSLDiskCompact {
    param ([string]$distroName)

    if (-not (Test-AdminPrivileges)) {
        Write-Host "错误: 压缩磁盘需要管理员权限。请以管理员身份重新运行此脚本。" -ForegroundColor Red
        return
    }

    $vhdxPath = Get-VHDXPath -distroName $distroName
    if (-not $vhdxPath) {
        Write-Host "错误: 未能找到 '$distroName' 的虚拟磁盘文件。" -ForegroundColor Red
        return
    }

    Write-Host "警告: 此操作将关闭所有正在运行的WSL实例。" -ForegroundColor Yellow
    $confirmation = Read-Host "是否继续? (Y/N)"
    if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
        Write-Host "操作已取消。" -ForegroundColor Green
        return
    }

    Write-Host "正在关闭WSL..." -ForegroundColor Green
    wsl --shutdown
    Start-Sleep -Seconds 5 # 等待WSL完全关闭

    Write-Host "正在使用diskpart压缩磁盘: $vhdxPath" -ForegroundColor Green
    $diskpartScript = @"
select vdisk file="$vhdxPath"
attach vdisk readonly
compact vdisk
detach vdisk
exit
"@
    $scriptPath = "$env:TEMP\diskpart_script.txt"
    $diskpartScript | Out-File -FilePath $scriptPath -Encoding ascii -NoNewline

    try {
        diskpart /s $scriptPath | Out-Null
        Write-Host "磁盘压缩完成。" -ForegroundColor Green
    } catch {
        Write-Host "执行diskpart时出错: $_" -ForegroundColor Red
    } finally {
        Remove-Item $scriptPath -ErrorAction SilentlyContinue
    }

    Write-Host "`n操作完成。您可以重新启动WSL发行版。" -ForegroundColor Green
}

# 显示帮助信息
function Show-Help {
    Get-Help $PSCommandPath -Detailed
}


