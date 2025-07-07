#!/bin/bash

# linux-docker-setup.sh
# 在 Debian/Ubuntu 系统上自动化安装 Docker Engine 和 Docker Compose。

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
echo_green "   开始自动化安装 Docker 和 Docker Compose...   "
echo_green "=================================================="

# 检查是否以 root 用户运行，如果不是，则使用 sudo
if [ "$(id -u)" -ne 0 ]; then
    SUDO='sudo'
    echo_cyan "脚本需要使用 sudo 权限来安装软件包。"
    $SUDO -v
else
    SUDO=''
fi

# 1. 卸载旧版本
echo_cyan "\n[1/5] 正在卸载旧的 Docker 版本 (如果存在)..."
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    $SUDO apt-get remove -y $pkg > /dev/null 2>&1 || true
done

# 2. 设置 Docker 的 APT 仓库
echo_cyan "\n[2/5] 正在设置 Docker 的官方 APT 仓库..."
# 安装依赖
$SUDO apt-get update
$SUDO apt-get install -y ca-certificates curl

# 添加 Docker 的官方 GPG 密钥
$SUDO install -m 0755 -d /etc/apt/keyrings
$SUDO curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
$SUDO chmod a+r /etc/apt/keyrings/docker.asc

# 添加仓库到 Apt sources
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null
$SUDO apt-get update

# 3. 安装 Docker Engine
echo_cyan "\n[3/5] 正在安装最新版本的 Docker Engine..."
$SUDO apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin

# 4. 安装 Docker Compose
echo_cyan "\n[4/5] 正在安装 Docker Compose 插件..."
$SUDO apt-get install -y docker-compose-plugin

# 5. 配置 Docker 用户组（免 sudo）
echo_cyan "\n[5/5] 正在将当前用户添加到 'docker' 组..."
if getent group docker > /dev/null; then
    echo "'docker' 组已存在。"
else
    echo "创建 'docker' 组。"
    $SUDO groupadd docker
fi

# 将当前用户添加到 docker 组
$SUDO usermod -aG docker $USER

echo_green "\n=================================================="
echo_green "      ✅ Docker 安装和配置完成! ✅"
echo_green "=================================================="
echo_green "已安装:
- Docker Engine
- Docker Compose"

echo_green "\n重要提示:"
echo_green "为了使 'docker' 组的权限生效，您需要退出并重新登录。"
echo_green "在 WSL 中，这意味着您需要关闭当前的终端窗口，然后重新打开一个新的。"
echo_green "之后，您就可以直接运行 'docker' 命令，无需 'sudo'。"

# 验证安装
echo_cyan "\n验证安装版本:"
docker --version
docker compose version
