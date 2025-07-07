# Script: setup-win-client-to-win-server.ps1
# Description: Helps set up SSH key-based authentication from a Windows client to a Windows SSH server.
# To be run on the Windows SSH CLIENT.
# Version: 1.0

# --- 1. 定义 SSH 密钥路径 ---
$SshUserHome = $env:USERPROFILE
$SshPath = Join-Path -Path $SshUserHome -ChildPath ".ssh"
$PrivateKeyPath = Join-Path -Path $SshPath -ChildPath "id_rsa"
$PublicKeyPath = Join-Path -Path $SshPath -ChildPath "id_rsa.pub"

Write-Host "--- SSH 密钥检查与生成 ---" -ForegroundColor Cyan
Write-Host "将在以下路径检查/创建 SSH 密钥:"
Write-Host "  私钥: $PrivateKeyPath"
Write-Host "  公钥: $PublicKeyPath"
Write-Host ""

# --- 2. 检查 .ssh 目录是否存在，不存在则创建 ---
if (-not (Test-Path $SshPath -PathType Container)) {
    Write-Host "'.ssh' 目录 ($SshPath) 不存在，正在创建..." -ForegroundColor Yellow
    try {
        New-Item -ItemType Directory -Path $SshPath -ErrorAction Stop | Out-Null
        Write-Host "'.ssh' 目录已创建。" -ForegroundColor Green
    }
    catch {
        Write-Host "错误：创建 '.ssh' 目录失败: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "'.ssh' 目录 ($SshPath) 已存在。" -ForegroundColor Green
}
Write-Host ""

# --- 3. 检查 SSH 密钥对是否存在 ---
$generateNewKeys = $false
if (-not (Test-Path $PrivateKeyPath) -or -not (Test-Path $PublicKeyPath)) {
    Write-Host "SSH 密钥对 (id_rsa/id_rsa.pub) 未找到。" -ForegroundColor Yellow
    $generateNewKeys = $true
} else {
    Write-Host "找到现有的 SSH 密钥对。" -ForegroundColor Green
    $choice = Read-Host "是否要覆盖现有密钥并生成新的密钥对? (y/N)"
    if ($choice -eq 'y' -or $choice -eq 'Y') {
        Write-Host "将生成新的密钥对并覆盖现有密钥。" -ForegroundColor Yellow
        $generateNewKeys = $true
    } else {
        Write-Host "将使用现有密钥。" -ForegroundColor Green
    }
}
Write-Host ""

# --- 4. 如果需要，生成新的 SSH 密钥对 ---
if ($generateNewKeys) {
    Write-Host "正在生成新的 SSH 密钥对 (RSA 4096位)..." -ForegroundColor Yellow
    # 删除旧密钥（如果存在且用户选择覆盖）
    if (Test-Path $PrivateKeyPath) { Remove-Item $PrivateKeyPath -Force }
    if (Test-Path $PublicKeyPath) { Remove-Item $PublicKeyPath -Force }

    try {
        # ssh-keygen.exe 通常随 Git for Windows 或 OpenSSH Client 功能一起安装
        # 确保 ssh-keygen 在 PATH 中
        ssh-keygen -t rsa -b 4096 -f $PrivateKeyPath -N "" -C "$env:USERNAME@$env:COMPUTERNAME" -q
        if (Test-Path $PrivateKeyPath -And (Test-Path $PublicKeyPath)) {
            Write-Host "新的 SSH 密钥对已成功生成。" -ForegroundColor Green
            Write-Host "  私钥: $PrivateKeyPath"
            Write-Host "  公钥: $PublicKeyPath"
        } else {
            Write-Host "错误：ssh-keygen 执行后未找到密钥文件。请确保 ssh-keygen.exe 可用并在 PATH 中。" -ForegroundColor Red
            Write-Host "您可以尝试手动运行: ssh-keygen -t rsa -b 4096 -f '$PrivateKeyPath' -N ''"
            exit 1
        }
    }
    catch {
        Write-Host "错误：生成 SSH 密钥对失败: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "请确保 ssh-keygen.exe 可用 (通常随 Git for Windows 或 Windows OpenSSH Client 功能提供) 并在系统 PATH 中。" -ForegroundColor Red
        exit 1
    }
}
Write-Host ""

# --- 5. 显示公钥并提供指导 ---
if (-not (Test-Path $PublicKeyPath)) {
    Write-Host "错误：公钥文件 '$PublicKeyPath' 未找到。无法继续。" -ForegroundColor Red
    exit 1
}

Write-Host "--- 配置 Windows 服务器 ---" -ForegroundColor Cyan
Write-Host "请复制以下公钥内容。您需要将其提供给目标 Windows 服务器上的配置脚本。" -ForegroundColor Yellow
Write-Host "-------------------------- 公钥内容开始 --------------------------" -ForegroundColor White
Get-Content $PublicKeyPath | Write-Host
Write-Host "--------------------------- 公钥内容结束 ---------------------------" -ForegroundColor White
Write-Host ""

# --- 6. 尝试自动配置远程 Windows 服务器 ---
Write-Host "--- 尝试自动配置远程 Windows 服务器 ---" -ForegroundColor Cyan
$attemptAutoConfig = Read-Host "是否尝试通过 SSH 自动将公钥添加到远程 Windows 服务器? (y/N) (这可能需要您输入远程服务器用户的密码)"
Write-Host ""

if ($attemptAutoConfig -eq 'y' -or $attemptAutoConfig -eq 'Y') {
    $remoteServerHost = Read-Host "请输入目标 Windows 服务器的 IP 地址或主机名"
    $remoteServerUser = Read-Host "请输入您在目标 Windows 服务器上的用户名 (用于 SSH 连接和配置)"
    
    if (-not $remoteServerHost -or -not $remoteServerUser) {
        Write-Host "服务器地址和用户名不能为空。跳过自动配置。" -ForegroundColor Yellow
    } else {
        Write-Host "将尝试以用户 '$remoteServerUser' 连接到 '$remoteServerHost'。" -ForegroundColor Yellow
        Write-Host "在 SSH 连接过程中，系统可能会提示您输入 '$remoteServerUser' 的密码。" -ForegroundColor Yellow
        Write-Host "请注意：远程服务器上的 SSH 服务必须已启用并允许密码验证。" -ForegroundColor Yellow
        Write-Host ""

        $publicKeyString = Get-Content $PublicKeyPath -Raw
        # PowerShell doesn't typically need single quotes escaped in public keys, but this is belt-and-suspenders for embedding in a command string.
        $escapedPublicKeyString = $publicKeyString.Replace("'", "''")

        # PowerShell script block to execute on the remote server
        # This script assumes it's running in the context of the target user on the remote machine.
        # Variables like `$env:USERPROFILE` are escaped with backticks to be evaluated on the remote machine.
        $remoteScriptBlock = @"
`$ErrorActionPreference = 'Stop'
try {
    `$currentUserProfile = `$env:USERPROFILE 
    if (!`$currentUserProfile) { 
        Write-Error "无法在远程服务器上确定当前用户的主目录。"
        exit 1
    }
    `$remoteSshPath = Join-Path -Path `$currentUserProfile -ChildPath ".ssh"
    `$remoteAuthorizedKeysPath = Join-Path -Path `$remoteSshPath -ChildPath "authorized_keys"

    Write-Host "远程服务器: 正在检查/创建目录: `$remoteSshPath"
    if (!(Test-Path `$remoteSshPath -PathType Container)) {
        New-Item -ItemType Directory -Path `$remoteSshPath -Force | Out-Null
        Write-Host "远程服务器: '.ssh' 目录已创建。"
    } else {
        Write-Host "远程服务器: '.ssh' 目录已存在。"
    }

    Write-Host "远程服务器: 正在将公钥追加到: `$remoteAuthorizedKeysPath"
    Add-Content -Path `$remoteAuthorizedKeysPath -Value \"$escapedPublicKeyString\" # Embed the public key string
    
    Write-Host "REMOTE_SUCCESS: 公钥已成功追加到远程服务器上的 authorized_keys 文件。"
    Write-Host "远程服务器: 请测试 SSH 免密登录: ssh $remoteServerUser@$remoteServerHost"
    Write-Host "远程服务器: 重要提示：此自动配置仅追加了公钥。"
    Write-Host "远程服务器: 如果 SSH 免密登录仍然失败，或者为了最稳妥的配置，"
    Write-Host "远程服务器: 请在服务器上以管理员身份运行 'configure-win-server-for-ssh-key-auth.ps1' 脚本，"
    Write-Host "远程服务器: 以确保 .ssh 目录和 authorized_keys 文件具有正确的权限和所有权。"
    exit 0
}
catch {
    Write-Error "REMOTE_ERROR: 在远程服务器上配置密钥时发生错误: `$(`$_.Exception.Message)" 
    exit 1
}
"@

        $encodedRemoteCommand = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($remoteScriptBlock))
        $sshFullCommand = "ssh $remoteServerUser@$remoteServerHost powershell.exe -NoProfile -NonInteractive -EncodedCommand $encodedRemoteCommand"
        
        Write-Host "正在执行远程命令 (您可能需要输入密码):" -ForegroundColor Magenta
        
        try {
            Write-Host "--- 开始远程执行 ---" -ForegroundColor DarkCyan
            Invoke-Command -ScriptBlock { param($cmd) Invoke-Expression -Command $cmd } -ArgumentList $sshFullCommand
            Write-Host "--- 远程执行结束 ---" -ForegroundColor DarkCyan
            
            if ($LASTEXITCODE -eq 0) {
                 Write-Host "远程命令似乎已成功执行 (SSH 返回码 0)。请检查上面的输出确认公钥是否已添加。" -ForegroundColor Green
                 Write-Host "您可以尝试 SSH 免密登录: ssh $remoteServerUser@$remoteServerHost" -ForegroundColor Green
            } else {
                Write-Host "远程命令执行可能失败 (SSH 返回码: $LASTEXITCODE)。请检查上面的错误信息。" -ForegroundColor Red
                Write-Host "如果自动配置失败，请使用下面描述的手动步骤。" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "执行 SSH 命令时出错: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "请确保 OpenSSH 客户端 (ssh.exe) 已安装并在 PATH 中。" -ForegroundColor Red
            Write-Host "如果自动配置失败，请使用下面描述的手动步骤。" -ForegroundColor Red
        }
    }
} else {
    Write-Host "跳过自动配置。" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "--- 手动配置步骤 (如果自动配置未尝试、失败或需要更稳妥的权限设置) ---" -ForegroundColor Cyan
Write-Host "1. 确保您已复制上面显示的公钥内容 (从 'ssh-rsa' 开始到末尾)。"
Write-Host "2. 登录到目标 Windows SSH 服务器。"
Write-Host "3. 在服务器上，以管理员身份运行 'configure-win-server-for-ssh-key-auth.ps1' 脚本。"
Write-Host "   (通常位于 'C:\Users\shuai\Nutstore\1\02-开发资料\MiniTools\EnableSHH\configure-win-server-for-ssh-key-auth.ps1')"
Write-Host "   当脚本提示时:"
Write-Host "   - 输入您希望以此密钥登录的 Windows 用户名 (例如 'YourUser' 或 'DOMAIN\YourUser')。"
Write-Host "   - 粘贴您复制的公钥内容。"
Write-Host "4. 该脚本将确保 'authorized_keys' 文件和相关的 .ssh 目录具有 OpenSSH 服务器所需的严格权限。"
Write-Host ""
Write-Host "脚本执行完毕。请根据所选配置方式测试 SSH 连接." -ForegroundColor Green

Write-Host "--- 测试连接和重要提示 ---" -ForegroundColor Cyan
Write-Host "配置完成后，您应该能够从此客户端计算机通过 SSH 免密登录到服务器。" -ForegroundColor Green

if ($attemptAutoConfig -eq 'y' -or $attemptAutoConfig -eq 'Y') {
    if ($remoteServerHost -and $remoteServerUser) {
        Write-Host "如果自动配置已尝试并且可能成功，您可以测试: ssh $remoteServerUser@$remoteServerHost" -ForegroundColor Magenta
    }
}

Write-Host "或者，您可以手动输入连接信息来测试:" -ForegroundColor Green
$FinalTargetUser = Read-Host -Prompt "请输入您在服务器上配置的用户名 (用于显示最终示例命令)"
$FinalTargetServer = Read-Host -Prompt "请输入目标服务器的 IP 地址或主机名 (用于显示最终示例命令)"
if ($FinalTargetUser -and $FinalTargetServer) {
    Write-Host "示例 SSH 命令: ssh $FinalTargetUser@$FinalTargetServer" -ForegroundColor Magenta
} else {
    Write-Host "示例 SSH 命令: ssh <用户名>@<服务器IP或主机名>" -ForegroundColor Magenta
}
Write-Host ""
Write-Host "重要提示:" -ForegroundColor Yellow
Write-Host " - 确保目标 Windows 服务器已安装并运行 OpenSSH Server (sshd 服务)。"
Write-Host " - 确保目标 Windows 服务器的防火墙允许 SSH 连接 (通常是 TCP 端口 22)。"
Write-Host " - 如果自动配置失败或跳过，或者即使自动配置后仍有问题，强烈建议在 Windows 服务器上以管理员身份运行 'configure-win-server-for-ssh-key-auth.ps1' 脚本。"
Write-Host "   该脚本会全面检查并修复 .ssh 目录和 authorized_keys 文件的所有权及 NTFS 权限，这对于 Windows OpenSSH Server 至关重要。"
Write-Host ""
Write-Host "脚本最终执行完毕。"

if ($Host.Name -eq "ConsoleHost") {
    Read-Host "按 Enter 键退出"
}
