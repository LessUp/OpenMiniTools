# Script: configure-win-server-for-ssh-key-auth.ps1
# Description: Configures a Windows OpenSSH server to accept a public key for a specific user.
# To be run on the Windows SSH SERVER.
# Version: 1.0

param (
    [string]$Username = $(Read-Host -Prompt "请输入要为其配置SSH免密登录的Windows用户名 (例如 'john.doe' 或 'DOMAIN\user')"),
    [string]$PublicKeyString = $(Read-Host -Prompt "请输入客户端的SSH公钥内容 (例如 'ssh-rsa AAAA...')")
)

# --- 0. 检查管理员权限 ---
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

# --- 1. 验证输入 ---
if ([string]::IsNullOrWhiteSpace($Username)) {
    Write-Host "错误：用户名不能为空。" -ForegroundColor Red
    exit 1
}
if ([string]::IsNullOrWhiteSpace($PublicKeyString) -or -not ($PublicKeyString.StartsWith("ssh-rsa") -or $PublicKeyString.StartsWith("ecdsa-") -or $PublicKeyString.StartsWith("ssh-ed25519"))) {
    Write-Host "错误：提供的公钥格式似乎不正确。它应该以 'ssh-rsa', 'ecdsa-', 或 'ssh-ed25519' 开头。" -ForegroundColor Red
    exit 1
}

# --- 2. 解析用户名并获取用户SID和主目录 ---
Write-Host "正在解析用户 '$Username'...'" -ForegroundColor Cyan
try {
    $UserAccount = New-Object System.Security.Principal.NTAccount($Username)
    $UserSID = $UserAccount.Translate([System.Security.Principal.SecurityIdentifier]).Value
    Write-Host "用户 '$Username' 的 SID 是: $UserSID" -ForegroundColor Green
}
catch {
    Write-Host "错误：无法解析用户名 '$Username'。请确保用户存在。错误: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 获取用户主目录
# 对于本地账户，通常是 C:\Users\<username>
# 对于域账户，可能需要更复杂的逻辑或依赖于 AD 模块，这里简化处理
$UserProfilePath = ""
if ($Username -match "\\") { # Domain user
    # Attempt to get profile path from registry (might not always work for non-logged-in domain users)
    try {
         $UserProfilePath = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$UserSID").ProfileImagePath
    } catch {
        Write-Host "警告：无法自动确定域用户 '$Username' 的主目录。将尝试使用标准路径。" -ForegroundColor Yellow
        # Fallback for domain users, assuming a standard structure if profile exists
        $LocalUsername = $Username.Split('\\')[1]
        $PotentialPath = "C:\Users\$LocalUsername"
        if (Test-Path $PotentialPath) {
            $UserProfilePath = $PotentialPath
        } else {
             Write-Host "错误：无法找到用户 '$Username' 的主目录。请手动创建 '$PotentialPath' 或确保用户已在此机器登录过一次。" -ForegroundColor Red
             exit 1
        }
    }
} else { # Local user
    $UserProfilePath = Join-Path -Path $env:SystemDrive -ChildPath "Users\$Username"
}

if (-not (Test-Path $UserProfilePath -PathType Container)) {
    Write-Host "错误：用户 '$Username' 的主目录 '$UserProfilePath' 不存在。" -ForegroundColor Red
    exit 1
}
Write-Host "用户 '$Username' 的主目录是: $UserProfilePath" -ForegroundColor Green
Write-Host ""

# --- 3. 创建 .ssh 目录和 authorized_keys 文件 ---
$SshFolderPath = Join-Path -Path $UserProfilePath -ChildPath ".ssh"
$AuthorizedKeysPath = Join-Path -Path $SshFolderPath -ChildPath "authorized_keys"

Write-Host "正在处理 SSH 配置文件路径..." -ForegroundColor Cyan
Write-Host ".ssh 目录: $SshFolderPath"
Write-Host "authorized_keys 文件: $AuthorizedKeysPath"

if (-not (Test-Path $SshFolderPath -PathType Container)) {
    Write-Host "'.ssh' 目录不存在，正在创建..." -ForegroundColor Yellow
    try {
        New-Item -ItemType Directory -Path $SshFolderPath -ErrorAction Stop | Out-Null
        Write-Host "'.ssh' 目录已创建。" -ForegroundColor Green
    }
    catch {
        Write-Host "错误：创建 '.ssh' 目录失败: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "'.ssh' 目录已存在。" -ForegroundColor Green
}

# --- 4. 将公钥添加到 authorized_keys 文件 ---
Write-Host "正在将公钥添加到 '$AuthorizedKeysPath'...'" -ForegroundColor Yellow
try {
    # 检查公钥是否已存在
    $KeyExists = $false
    if (Test-Path $AuthorizedKeysPath) {
        $CurrentKeys = Get-Content $AuthorizedKeysPath -ErrorAction SilentlyContinue
        if ($CurrentKeys -contains $PublicKeyString) {
            $KeyExists = $true
        }
    }

    if ($KeyExists) {
        Write-Host "公钥已存在于 '$AuthorizedKeysPath' 中，无需重复添加。" -ForegroundColor Green
    } else {
        Add-Content -Path $AuthorizedKeysPath -Value $PublicKeyString -ErrorAction Stop
        Write-Host "公钥已成功添加到 '$AuthorizedKeysPath'。" -ForegroundColor Green
    }
}
catch {
    Write-Host "错误：将公钥添加到 '$AuthorizedKeysPath' 失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
Write-Host ""

# --- 5. 设置 .ssh 目录和 authorized_keys 文件的权限 ---
# 这是 OpenSSH on Windows 的关键步骤，权限必须严格。
# 文件和目录必须由用户拥有，并且只有用户有写入权限。
# Administrators 或 SYSTEM 拥有写入权限可能会导致 PubkeyAuthentication 失败。

Write-Host "--- 设置文件和目录权限 ---" -ForegroundColor Cyan

# Step 5.1: Take ownership if needed (usually current admin owns it if created by admin script)
# Set owner to the target user
Write-Host "设置 '$SshFolderPath' 的所有者为 '$Username'...'" -ForegroundColor Yellow
try {
    $acl = Get-Acl $SshFolderPath
    $acl.SetOwner([System.Security.Principal.NTAccount]$Username)
    Set-Acl -Path $SshFolderPath -AclObject $acl -ErrorAction Stop
    Write-Host "'$SshFolderPath' 所有者设置成功。" -ForegroundColor Green
} catch {
    Write-Host "警告：设置 '$SshFolderPath' 所有者失败: $($_.Exception.Message)。这可能导致问题，请手动检查。" -ForegroundColor Yellow
}

Write-Host "设置 '$AuthorizedKeysPath' 的所有者为 '$Username'...'" -ForegroundColor Yellow
try {
    if (Test-Path $AuthorizedKeysPath) {
        $acl = Get-Acl $AuthorizedKeysPath
        $acl.SetOwner([System.Security.Principal.NTAccount]$Username)
        Set-Acl -Path $AuthorizedKeysPath -AclObject $acl -ErrorAction Stop
        Write-Host "'$AuthorizedKeysPath' 所有者设置成功。" -ForegroundColor Green
    }
} catch {
    Write-Host "警告：设置 '$AuthorizedKeysPath' 所有者失败: $($_.Exception.Message)。这可能导致问题，请手动检查。" -ForegroundColor Yellow
}


# Step 5.2: Remove inheritance and explicit permissions for other users
# For .ssh folder
Write-Host "正在为 '$SshFolderPath' 配置权限..." -ForegroundColor Yellow
icacls.exe $SshFolderPath /inheritance:r /grant "$($Username):(OI)(CI)F" /T /C /Q # Grant user Full Control, Object Inherit, Container Inherit
icacls.exe $SshFolderPath /remove "Administrators" "Authenticated Users" "Users" "SYSTEM" /T /C /Q # Attempt to remove common groups

# For authorized_keys file
Write-Host "正在为 '$AuthorizedKeysPath' 配置权限..." -ForegroundColor Yellow
if (Test-Path $AuthorizedKeysPath) {
    icacls.exe $AuthorizedKeysPath /inheritance:r /grant "$($Username):F" /T /C /Q # Grant user Full Control
    icacls.exe $AuthorizedKeysPath /remove "Administrators" "Authenticated Users" "Users" "SYSTEM" /T /C /Q # Attempt to remove common groups
    
    # Verify permissions (basic check)
    $aclCheck = Get-Acl $AuthorizedKeysPath
    $owner = $aclCheck.Owner
    Write-Host "'$AuthorizedKeysPath' 当前所有者: $owner"
    # A more thorough check would list all ACEs.
} else {
    Write-Host "警告: '$AuthorizedKeysPath' 未找到，无法设置权限。" -ForegroundColor Yellow
}

# An alternative, more PowerShell-idiomatic way to set permissions:
# This ensures only the user and SYSTEM have access, with user having FullControl.
# OpenSSH is very picky; sometimes only giving the user access and removing SYSTEM/Administrators is required.
# The icacls method above is generally more robust for stripping permissions.

# $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule($Username, "FullControl", "Allow")
# $Acl = Get-Acl $AuthorizedKeysPath
# $Acl.SetAccessRuleProtection($True, $False) # Disable inheritance, remove inherited rules
# $Acl.Access | ForEach-Object { $Acl.RemoveAccessRule($_) } | Out-Null # Remove all existing explicit rules
# $Acl.AddAccessRule($Ar)
# # Optionally add SYSTEM if needed for some operations, but often best to keep minimal for OpenSSH
# # $SystemPrincipal = New-Object System.Security.Principal.NTAccount("SYSTEM")
# # $SystemAr = New-Object System.Security.AccessControl.FileSystemAccessRule($SystemPrincipal, "FullControl", "Allow")
# # $Acl.AddAccessRule($SystemAr)
# Set-Acl -Path $AuthorizedKeysPath -AclObject $Acl

Write-Host "权限设置尝试完成。请务必验证 SSH 连接。" -ForegroundColor Green
Write-Host "重要提示：Windows 上的 OpenSSH 对 '$AuthorizedKeysPath' 文件的权限非常敏感。" -ForegroundColor Yellow
Write-Host "确保该文件及其父 '.ssh' 目录仅对目标用户和 SYSTEM (有时) 具有必要的访问权限。" -ForegroundColor Yellow
Write-Host "如果其他账户（如 Administrators）拥有写入权限，公钥认证可能会失败。" -ForegroundColor Yellow
Write-Host ""

# --- 6. 检查 sshd_config ---
$sshdConfigPath = Join-Path -Path $env:ProgramData -ChildPath "ssh\sshd_config"
Write-Host "正在检查 '$sshdConfigPath' 中的公钥认证设置..." -ForegroundColor Cyan
if (Test-Path $sshdConfigPath) {
    $configContent = Get-Content $sshdConfigPath
    $pubkeyAuthLine = $configContent | Select-String -Pattern "^\s*PubkeyAuthentication\s+yes"
    $authorizedKeysFileLines = $configContent | Select-String -Pattern "^\s*AuthorizedKeysFile\s+"
    
    if (-not $pubkeyAuthLine) {
        Write-Host "警告：'$sshdConfigPath' 中 'PubkeyAuthentication yes' 未找到或被注释掉。" -ForegroundColor Yellow
        Write-Host "请确保该行存在且未被注释，以启用公钥认证。" -ForegroundColor Yellow
    } else {
        Write-Host "'PubkeyAuthentication yes' 配置正确。" -ForegroundColor Green
    }

    # Default is .ssh/authorized_keys, check if it's overridden
    $defaultAuthKeysPath = ".ssh/authorized_keys"
    $isDefaultAuthKeysPath = $true
    if ($authorizedKeysFileLines) {
        foreach ($line in $authorizedKeysFileLines) {
            if ($line -notmatch "[#;]" -and $line -notmatch $defaultAuthKeysPath) { # Check if active and not default
                 Write-Host "警告：'$sshdConfigPath' 中 'AuthorizedKeysFile' 被设置为非默认值: $($line.ToString().Trim())" -ForegroundColor Yellow
                 Write-Host "此脚本配置的是默认路径 '$defaultAuthKeysPath'。如果 SSH 服务器使用了自定义路径，您可能需要手动调整。" -ForegroundColor Yellow
                 $isDefaultAuthKeysPath = $false
                 break
            }
        }
    }
    if ($isDefaultAuthKeysPath) {
         Write-Host "'AuthorizedKeysFile' 配置为默认值或未显式设置 (将使用默认值 '$defaultAuthKeysPath')。" -ForegroundColor Green
    }

} else {
    Write-Host "警告：未找到 SSHD 配置文件 '$sshdConfigPath'。无法验证公钥认证设置。" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "Windows Server SSH 公钥配置过程完成。" -ForegroundColor Green
Write-Host "请尝试从客户端使用对应的私钥进行 SSH 连接: ssh $Username@<服务器IP或主机名>" -ForegroundColor Green

if ($Host.Name -eq "ConsoleHost") {
    Read-Host "按 Enter 键退出"
}
