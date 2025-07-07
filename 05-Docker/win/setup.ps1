#Requires -RunAsAdministrator

<#
.SYNOPSIS
    一键式安装 Docker Desktop for Windows。
.DESCRIPTION
    此脚本将自动执行以下操作：
    1. 检查 WSL 2 是否已安装并设为默认版本。
    2. 从官方渠道下载最新的 Docker Desktop 安装程序。
    3. 以静默模式执行安装。
    4. 清理下载的安装文件。

    此脚本依赖于已成功安装的 WSL 2 环境。
.NOTES
    作者: Cascade
    版本: 1.0
    文件名: setup-docker-desktop.ps1
#>

function Install-DockerDesktop {
    Write-Host "开始 Docker Desktop 自动化安装..." -ForegroundColor Green

    # 1. 检查 WSL 2 是否为默认版本
    Write-Host "[1/4] 正在检查 WSL 2 是否为默认版本..." -ForegroundColor Cyan
    try {
        $wslStatusOutput = wsl.exe --status
        $defaultVersionLine = $wslStatusOutput | Select-String -Pattern "Default Version|默认版本"
        
        if (-not $defaultVersionLine -or $defaultVersionLine.ToString() -notmatch "2") {
            Write-Host "错误: WSL 2 未安装或未设置为默认版本。" -ForegroundColor Red
            Write-Host "请先成功运行 'setup-wsl.ps1' 脚本，并根据提示重启电脑。" -ForegroundColor Red
            return
        }
        
        Write-Host "检查通过: WSL 2 已被设置为默认版本。" -ForegroundColor Green
    } catch {
        Write-Host "错误: 无法执行 'wsl --status'。请确保 WSL 已安装。" -ForegroundColor Red
        return
    }

    # 2. 下载 Docker Desktop 安装程序
    $installerUrl = "https://desktop.docker.com/win/main/amd64/DockerDesktopInstaller.exe"
    $installerPath = Join-Path $env:TEMP "DockerDesktopInstaller.exe"
    Write-Host "[2/4] 正在从官方网站下载 Docker Desktop 安装程序..." -ForegroundColor Cyan
    Write-Host "下载地址: $installerUrl" -ForegroundColor Gray
    try {
        Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing
        Write-Host "下载完成。文件已保存到: $installerPath" -ForegroundColor Green
    } catch {
        Write-Host "错误: 下载 Docker Desktop 安装程序失败。" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        return
    }

    # 3. 静默安装 Docker Desktop
    Write-Host "[3/4] 正在静默安装 Docker Desktop... 这可能需要几分钟时间。" -ForegroundColor Cyan
    try {
        $process = Start-Process -FilePath $installerPath -ArgumentList "--quiet" -Wait -PassThru
        if ($process.ExitCode -ne 0) {
            # Docker Desktop 安装在某些情况下会返回 1，即使成功了，但通常表示需要重启或有警告。
            # 真正的失败通常是其他非零代码。
            Write-Host "Docker Desktop 安装进程已完成，退出码: $($process.ExitCode)。" -ForegroundColor Yellow
            Write-Host "如果安装失败，请尝试手动运行安装程序: $installerPath" -ForegroundColor Yellow
        } else {
            Write-Host "Docker Desktop 安装成功！" -ForegroundColor Green
        }
    } catch {
        Write-Host "错误: 执行 Docker Desktop 安装程序失败。" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        return
    }

    # 4. 清理安装文件
    Write-Host "[4/4] 正在清理安装文件..." -ForegroundColor Cyan
    Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue
    Write-Host "清理完成。" -ForegroundColor Green

    Write-Host "\n==================================================" -ForegroundColor Green
    Write-Host "      ✅ Docker Desktop 安装脚本执行完毕! ✅" -ForegroundColor Green
    Write-Host "==================================================" -ForegroundColor Green
    Write-Host "请从开始菜单启动 Docker Desktop。首次启动时，可能需要您接受服务条款。"
    Write-Host "启动后，它将自动与您的 WSL 2 环境集成。"
}

# 执行主函数
Install-DockerDesktop
