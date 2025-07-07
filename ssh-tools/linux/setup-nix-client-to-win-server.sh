#!/bin/bash

# Script: setup-nix-client-to-win-server.sh
# Description: Helps set up SSH key-based authentication from a macOS/Linux client to a Windows SSH server.
# To be run on the macOS or Linux SSH CLIENT.
# Version: 1.0

echo -e "\033[0;36m--- SSH 密钥检查与生成 (macOS/Linux 客户端) ---\033[0m"
SSH_DIR="$HOME/.ssh"
PRIVATE_KEY="$SSH_DIR/id_rsa"
PUBLIC_KEY="$SSH_DIR/id_rsa.pub"

echo "将在以下路径检查/创建 SSH 密钥:"
echo "  私钥: $PRIVATE_KEY"
echo "  公钥: $PUBLIC_KEY"
echo ""

# 检查 .ssh 目录
if [ ! -d "$SSH_DIR" ]; then
    echo -e "\033[0;33m'.ssh' 目录 ($SSH_DIR) 不存在，正在创建...\033[0m"
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    if [ $? -ne 0 ]; then
        echo -e "\033[0;31m错误：创建 '.ssh' 目录失败。\033[0m"
        exit 1
    fi
    echo -e "\033[0;32m'.ssh' 目录已创建。\033[0m"
else
    echo -e "\033[0;32m'.ssh' 目录 ($SSH_DIR) 已存在。\033[0m"
fi
echo ""

# 检查 SSH 密钥对
generate_new_keys=false
if [ ! -f "$PRIVATE_KEY" ] || [ ! -f "$PUBLIC_KEY" ]; then
    echo -e "\033[0;33mSSH 密钥对 (id_rsa/id_rsa.pub) 未找到。\033[0m"
    generate_new_keys=true
else
    echo -e "\033[0;32m找到现有的 SSH 密钥对。\033[0m"
    read -p "是否要覆盖现有密钥并生成新的密钥对? (y/N): " choice
    case "$choice" in
      y|Y )
        echo -e "\033[0;33m将生成新的密钥对并覆盖现有密钥。\033[0m"
        generate_new_keys=true
        ;;
      * )
        echo -e "\033[0;32m将使用现有密钥。\033[0m"
        ;;
    esac
fi
echo ""

# 如果需要，生成新的 SSH 密钥对
if [ "$generate_new_keys" = true ]; then
    echo -e "\033[0;33m正在生成新的 SSH 密钥对 (RSA 4096位)... (将提示您确认路径和密码，建议直接回车使用默认值且无密码)\033[0m"
    rm -f "$PRIVATE_KEY" "$PUBLIC_KEY" # 删除旧密钥
    ssh-keygen -t rsa -b 4096 -f "$PRIVATE_KEY" -C "$(whoami)@$(hostname -f)"
    if [ $? -ne 0 ] || [ ! -f "$PUBLIC_KEY" ]; then
        echo -e "\033[0;31m错误：生成 SSH 密钥对失败。\033[0m"
        exit 1
    fi
    echo -e "\033[0;32m新的 SSH 密钥对已成功生成。\033[0m"
fi
echo ""

# 显示公钥并提供指导
if [ ! -f "$PUBLIC_KEY" ]; then
    echo -e "\033[0;31m错误：公钥文件 '$PUBLIC_KEY' 未找到。无法继续。\033[0m"
    exit 1
fi

echo -e "\033[0;36m--- 配置 Windows 服务器 ---\033[0m"
echo -e "\033[0;33m请复制以下公钥内容。您需要将其提供给目标 Windows 服务器上的配置脚本。\033[0m"
echo -e "\033[0;37m-------------------------- 公钥内容开始 --------------------------\033[0m"
cat "$PUBLIC_KEY"
echo -e "\033[0;37m--------------------------- 公钥内容结束 ---------------------------\033[0m"
echo ""

echo -e "\033[0;32m操作步骤:\033[0m"
echo "1. 将上面显示的完整公钥内容 (从 'ssh-rsa' 开始到末尾) 复制到剪贴板。"
echo "2. 登录到目标 Windows SSH 服务器。"
echo "3. 在 Windows 服务器上，运行之前创建的 PowerShell 脚本 'configure-win-server-for-ssh-key-auth.ps1'。"
echo "   (通常位于 'c:\\Users\\shuai\\Nutstore\\1\\02-开发资料\\OpenMiniTools\\EnableSHH\\configure-win-server-for-ssh-key-auth.ps1')"
echo "   当脚本提示时:"
echo "   - 输入您希望以此密钥登录的 Windows 用户名 (例如 'YourUser' 或 'DOMAIN\\YourUser')。"
echo "   - 粘贴您刚刚复制的公钥内容。"
echo "4. PowerShell 脚本将在 Windows 服务器上配置 'authorized_keys' 文件和相关权限。"
echo ""
echo -e "\033[0;32m配置完成后，您应该能够从此客户端计算机通过 SSH 免密登录到 Windows 服务器：\033[0m"
read -p "请输入您将在 Windows 服务器上配置的用户名 (用于显示示例命令): " target_user
read -p "请输入目标 Windows 服务器的 IP 地址或主机名 (用于显示示例命令): " target_server
if [ -n "$target_user" ] && [ -n "$target_server" ]; then
    echo -e "示例 SSH 命令: \033[0;35mssh $target_user@$target_server\033[0m"
else
    echo -e "示例 SSH 命令: \033[0;35mssh <用户名>@<服务器IP或主机名>\033[0m"
fi
echo ""
echo -e "\033[0;33m重要提示:\033[0m"
echo " - 确保目标 Windows 服务器已安装并运行 OpenSSH Server (sshd 服务)。"
echo " - 确保目标 Windows 服务器的防火墙允许 SSH 连接 (通常是 TCP 端口 22)。"
echo " - 'configure-win-server-for-ssh-key-auth.ps1' 脚本需要在 Windows 服务器上以管理员身份运行。"
echo ""
echo "脚本执行完毕。"
