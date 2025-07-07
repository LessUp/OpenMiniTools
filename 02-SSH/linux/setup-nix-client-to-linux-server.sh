#!/bin/bash

# Script: setup-nix-client-to-linux-server.sh
# Description: Helps set up SSH key-based authentication from a macOS/Linux client to a Linux SSH server.
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
    rm -f "$PRIVATE_KEY" "$PUBLIC_KEY" # 删除旧密钥（如果存在且用户选择覆盖）
    ssh-keygen -t rsa -b 4096 -f "$PRIVATE_KEY" -C "$(whoami)@$(hostname -f)"
    if [ $? -ne 0 ] || [ ! -f "$PUBLIC_KEY" ]; then
        echo -e "\033[0;31m错误：生成 SSH 密钥对失败。\033[0m"
        exit 1
    fi
    echo -e "\033[0;32m新的 SSH 密钥对已成功生成。\033[0m"
fi
echo ""

# 获取公钥内容并显示 (可选)
echo -e "\033[0;36m--- 公钥内容 ---\033[0m"
if [ -f "$PUBLIC_KEY" ]; then
    cat "$PUBLIC_KEY"
else
    echo -e "\033[0;31m错误：公钥文件 '$PUBLIC_KEY' 未找到。\033[0m"
    exit 1
fi
echo ""

# 连接到 Linux 服务器并配置
echo -e "\033[0;36m--- 将公钥复制到 Linux 服务器 ---\033[0m"
read -p "请输入您在目标 Linux 服务器上的用户名: " linux_user
read -p "请输入目标 Linux 服务器的 IP 地址或主机名: " linux_host

if [ -z "$linux_user" ] || [ -z "$linux_host" ]; then
    echo -e "\033[0;31m错误：Linux 用户名和主机名不能为空。\033[0m"
    exit 1
fi

echo ""
echo -e "\033[0;33m将使用 'ssh-copy-id' 命令将公钥复制到 $linux_user@$linux_host。\033[0m"
echo -e "\033[0;33m您可能需要输入 '$linux_user' 在 '$linux_host' 上的密码。\033[0m"
echo ""

if ! command -v ssh-copy-id &> /dev/null; then
    echo -e "\033[0;31m错误: 'ssh-copy-id' 命令未找到。\033[0m"
    echo "在 macOS 上，您可以尝试通过 Homebrew 安装: brew install ssh-copy-id"
    echo "在某些 Linux 发行版上，它可能包含在 openssh-clients 包中。"
    echo ""
    echo "您可以手动复制公钥:"
    echo "1. 复制上面的公钥内容 (从 'ssh-rsa' 开始)。"
    echo "2. 通过 SSH 登录到您的 Linux 服务器: ssh $linux_user@$linux_host"
    echo "3. 登录后，在 Linux 服务器上执行以下命令:"
    echo -e "   \033[0;32mmkdir -p ~/.ssh\033[0m"
    echo -e "   \033[0;32mecho '在此粘贴您复制的公钥内容' >> ~/.ssh/authorized_keys\033[0m"
    echo -e "   \033[0;32mchmod 700 ~/.ssh\033[0m"
    echo -e "   \033[0;32mchmod 600 ~/.ssh/authorized_keys\033[0m"
    echo -e "   \033[0;32mexit\033[0m"
    exit 1
fi

ssh-copy-id -i "$PUBLIC_KEY" "$linux_user@$linux_host"

if [ $? -eq 0 ]; then
    echo ""
    echo -e "\033[0;32m公钥已成功复制到 $linux_user@$linux_host。\033[0m"
    echo "您现在应该能够通过 SSH 免密登录到服务器："
    echo -e "\033[0;35mssh $linux_user@$linux_host\033[0m"
else
    echo ""
    echo -e "\033[0;31m错误：'ssh-copy-id' 执行失败。\033[0m"
    echo "请检查错误消息，确保目标服务器 SSH 服务正在运行，并且网络连接正常。"
    echo "如果问题持续，请尝试上面提到的手动复制步骤。"
fi

echo ""
echo "脚本执行完毕。"
