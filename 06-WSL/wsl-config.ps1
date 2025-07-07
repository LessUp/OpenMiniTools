# WSL 配置管理工具
# 作者：Cascade
# 创建日期：2025-06-24

<#
.SYNOPSIS
    WSL (Windows Subsystem for Linux) 配置管理工具。

.DESCRIPTION
    此脚本提供了管理WSL全局配置的功能，包括修改WSL配置文件、
    设置WSL默认版本、配置内存和处理器限制等。

.EXAMPLE
    .\wsl-config.ps1 -SetVersion 2
    将WSL默认版本设置为WSL2。

.EXAMPLE
    .\wsl-config.ps1 -ConfigureMemory 4GB
    设置WSL内存限制为4GB。
#>



# 检查管理员权限
function Test-AdminPrivileges {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

# 获取WSL配置文件路径
function Get-WSLConfigPath {
    $configDir = "$env:USERPROFILE\.wslconfig"
    $globalConfigDir = "$env:ProgramData\Microsoft\WSL\.wslconfig"
    
    if (Test-Path $configDir) {
        return $configDir
    } elseif (Test-Path $globalConfigDir) {
        return $globalConfigDir
    } else {
        return $configDir # 默认使用用户配置路径
    }
}

# 显示WSL当前配置
function Show-WSLConfig {
    Write-Host "WSL 当前配置:" -ForegroundColor Green
    
    # 显示WSL版本
    $wslVersion = wsl --status | Select-String "默认版本"
    if (-not $wslVersion) {
        $wslVersion = wsl --status | Select-String "Default"
    }
    Write-Host $wslVersion -ForegroundColor Yellow
    
    # 显示.wslconfig文件内容（如果存在）
    $configPath = Get-WSLConfigPath
    if (Test-Path $configPath) {
        Write-Host "`n.wslconfig 文件内容:" -ForegroundColor Green
        Get-Content $configPath | ForEach-Object { Write-Host $_ }
    } else {
        Write-Host "`n未找到.wslconfig文件，使用WSL默认配置。" -ForegroundColor Yellow
    }
    
    # 显示全局WSL设置
    Write-Host "`nWSL全局设置:" -ForegroundColor Green
    wsl --status
}

# 设置WSL默认版本
function Set-WSLVersion {
    param([int]$version)
    
    if (-not (Test-AdminPrivileges)) {
        Write-Host "警告: 更改WSL默认版本需要管理员权限。" -ForegroundColor Red
        return
    }
    
    Write-Host "正在将WSL默认版本设置为 $version..." -ForegroundColor Green
    try {
        wsl --set-default-version $version
        Write-Host "WSL默认版本已设置为 $version。" -ForegroundColor Green
    } catch {
        Write-Host "设置WSL默认版本时出错: $_" -ForegroundColor Red
    }
}

# 创建或更新.wslconfig文件
function Update-WSLConfig {
    param (
        [hashtable]$settings
    )
    
    $configPath = Get-WSLConfigPath
    $configContent = ""
    
    # 如果配置文件已存在，读取现有内容
    if (Test-Path $configPath) {
        $configContent = Get-Content $configPath -Raw
        
        # 如果不存在[wsl2]部分，添加它
        if (-not ($configContent -match "\[wsl2\]")) {
            $configContent = "[wsl2]`n" + $configContent
        }
    } else {
        $configContent = "[wsl2]`n"
    }
    
    # 更新配置项
    foreach ($key in $settings.Keys) {
        $value = $settings[$key]
        
        # 检查配置是否已存在
        if ($configContent -match "$key\s*=") {
            # 更新现有配置
            $configContent = $configContent -replace "$key\s*=.*", "$key=$value"
        } else {
            # 添加新配置（确保在[wsl2]部分内）
            $configContent = $configContent -replace "\[wsl2\]", "[wsl2]`n$key=$value"
        }
    }
    
    # 保存更新后的配置
    $configContent | Out-File -FilePath $configPath -Encoding utf8
    Write-Host "已更新WSL配置文件: $configPath" -ForegroundColor Green
}

# 配置WSL内存限制
function Set-WSLMemory {
    param([string]$memoryLimit)
    
    if ([string]::IsNullOrEmpty($memoryLimit)) {
        Write-Host "错误: 请指定内存限制值，例如 '4GB'。" -ForegroundColor Red
        return
    }
    
    Write-Host "正在配置WSL内存限制为 $memoryLimit..." -ForegroundColor Green
    Update-WSLConfig -settings @{ "memory" = $memoryLimit }
    
    Write-Host "配置已保存，请重启WSL以应用更改。" -ForegroundColor Yellow
    Write-Host "提示: 使用命令 'wsl --shutdown' 重启WSL。" -ForegroundColor Yellow
}

# 配置WSL处理器数量
function Set-WSLProcessors {
    param([int]$processorCount)
    
    if ($processorCount -le 0) {
        Write-Host "错误: 处理器数量必须大于0。" -ForegroundColor Red
        return
    }
    
    $totalProcessors = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors
    if ($processorCount -gt $totalProcessors) {
        Write-Host "警告: 指定的处理器数量($processorCount)超过系统总处理器数量($totalProcessors)。" -ForegroundColor Yellow
        Write-Host "将使用最大可用处理器数量: $totalProcessors" -ForegroundColor Yellow
        $processorCount = $totalProcessors
    }
    
    Write-Host "正在配置WSL使用 $processorCount 个处理器..." -ForegroundColor Green
    Update-WSLConfig -settings @{ "processors" = $processorCount }
    
    Write-Host "配置已保存，请重启WSL以应用更改。" -ForegroundColor Yellow
    Write-Host "提示: 使用命令 'wsl --shutdown' 重启WSL。" -ForegroundColor Yellow
}

# 设置嵌套虚拟化
function Set-NestedVirtualization {
    param([bool]$enable)
    
    $status = if ($enable) { "true" } else { "false" }
    $actionText = if ($enable) { "启用" } else { "禁用" }
    
    Write-Host "正在${actionText}WSL嵌套虚拟化..." -ForegroundColor Green
    Update-WSLConfig -settings @{ "nestedVirtualization" = $status }
    
    Write-Host "配置已保存，请重启WSL以应用更改。" -ForegroundColor Yellow
    Write-Host "提示: 使用命令 'wsl --shutdown' 重启WSL。" -ForegroundColor Yellow
}

# 设置GPU支持
function Set-GPUSupport {
    param([bool]$enable)
    
    $status = if ($enable) { "true" } else { "false" }
    $actionText = if ($enable) { "启用" } else { "禁用" }
    
    Write-Host "正在${actionText}WSL GPU支持..." -ForegroundColor Green
    Update-WSLConfig -settings @{ "gpuSupport" = $status }
    
    Write-Host "配置已保存，请重启WSL以应用更改。" -ForegroundColor Yellow
    Write-Host "提示: 使用命令 'wsl --shutdown' 重启WSL。" -ForegroundColor Yellow
}

# 显示帮助信息
function Show-Help {
    Get-Help $PSCommandPath -Detailed
    
    Write-Host "`n配置说明:" -ForegroundColor Green
    Write-Host "1. WSL配置存储在 ~/.wslconfig 文件中"
    Write-Host "2. 修改配置后需要重启WSL (使用 wsl --shutdown)"
    Write-Host "3. 配置选项详细说明请参考微软官方文档"
}


