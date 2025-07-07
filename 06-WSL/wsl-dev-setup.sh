#!/bin/bash

# wsl-dev-setup.sh
# 在一个全新的 WSL/Ubuntu 环境中自动化安装常用的开发工具。

# 设置 -e: 如果任何命令失败，脚本将立即退出。
set -e

# --- Helper Functions ---
echo_green() {
    echo -e "\033[0;32m$1\033[0m"
}
echo_cyan() {
    echo -e "\033[0;36m$1\033[0m"
}

# --- Main Script ---
echo_green "=================================================="
echo_green "   开始自动化配置 WSL (Ubuntu) 开发环境...   "
echo_green "=================================================="

# 由于许多命令需要 sudo，我们先请求一次密码，让后续的 sudo 命令在一段时间内无需再次输入。
echo_cyan "脚本需要使用 sudo 权限来安装软件包。"
sudo -v

# 1. 更新和升级 APT 包
echo_cyan "\n[1/4] 正在更新和升级系统软件包..."
sudo apt-get update && sudo apt-get upgrade -y

# 2. 安装基础开发工具
echo_cyan "\n[2/4] 正在安装基础开发工具 (git, curl, build-essential)..."
sudo apt-get install -y git curl wget build-essential

# 3. 安装 NVM 和 Node.js
echo_cyan "\n[3/4] 正在安装 NVM (Node Version Manager) 和最新的 LTS Node.js..."
# 从 GitHub 下载并执行 NVM 安装脚本
export NVM_DIR="$HOME/.nvm"
if [ -d "$NVM_DIR" ]; then
    echo_green "NVM 已经安装在 $NVM_DIR"
else
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi

# 让 nvm 命令在当前脚本中生效
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# 安装最新的长期支持 (LTS) 版本的 Node.js
nvm install --lts
nvm use --lts
nvm alias default 'lts/*'

echo_green "Node.js 版本: $(node -v)"
echo_green "npm 版本: $(npm -v)"

# 4. 安装 Zsh 和 Oh My Zsh
echo_cyan "\n[4/4] 正在安装 Zsh 和 Oh My Zsh..."
sudo apt-get install -y zsh

# 以非交互模式安装 Oh My Zsh
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo_green "Oh My Zsh 已经安装。"
else
    # 使用 --unattended 标志来避免 'chsh' 提示
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# 将 Zsh 设置为默认 shell。这可能需要用户手动输入密码。
# 我们检查当前的 shell 是否已经是 zsh，如果不是，则提示用户。
if [ "$(basename "$SHELL")" != "zsh" ]; then
    echo_cyan "\n为了将 Zsh 设置为您的默认 shell，请输入您的密码。"
    chsh -s $(which zsh)
    if [ $? -eq 0 ]; then
        echo_green "已成功将 Zsh 设置为默认 shell。请重新启动终端以使更改生效。"
    else
        echo "无法自动更改 shell。您可以稍后手动运行 'chsh -s $(which zsh)'。"
    fi
fi

echo_green "\n=================================================="
echo_green "      ✅ 开发环境配置完成! ✅"
echo_green "=================================================="
echo_green "已安装:
- Git, Curl, Wget, Build-Essential
- NVM (Node Version Manager)
- Node.js (LTS 版本)
- Zsh 和 Oh My Zsh"
echo_green "\n请关闭并重新打开您的 WSL 终端以加载新的 Zsh shell 和所有环境变量。"
