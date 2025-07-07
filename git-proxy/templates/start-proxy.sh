#!/bin/bash
# ==============================================================================
#
#   文件: start-proxy.sh
#   描述: 启动一个后台 SSH SOCKS5 代理，并为特定的私有 Git 服务器配置代理。
#   作者: Your Name
#   版本: 1.1
#   更新日期: 2024-07-01
#
# ==============================================================================

# --- 配置 ---
set -e
set -o pipefail

# ========================= 脚本配置 (请自定义) =========================

# 在 ~/.ssh/config 文件中定义的、用于创建 SOCKS 代理的 SSH 别名
TARGET_HOST="gitlab-proxy"

# SOCKS 代理的本地监听端口
SOCKS_PORT=1080

# 【重要】您私有 Git 服务器的域名
GIT_SERVER_DOMAIN="your-git-server.com"

# =====================================================================

# --- 内部变量定义 ---
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PID_FILE="$SCRIPT_DIR/.proxy-pid"
GIT_PROXY_CONFIG_FILE="$HOME/.gitconfig-proxy"

# --- 颜色定义 ---
C_RESET='\033[0m'
C_CYAN='\033[0;36m'
C_GREEN='\033[0;32m'
C_RED='\033[0;31m'
C_YELLOW='\033[0;33m'

# --- 函数定义 ---

info() { echo -e "${C_CYAN}[信息] $1${C_RESET}"; }
success() { echo -e "${C_GREEN}[成功] $1${C_RESET}"; }
error() { echo -e "${C_RED}[错误] $1${C_RESET}"; }
warn() { echo -e "${C_YELLOW}[警告] $1${C_RESET}"; }

function test_proxy_running() {
  if [ -f "$PID_FILE" ]; then
    local pid
    pid=$(cat "$PID_FILE")
    if ps -p "$pid" > /dev/null; then
      warn "代理已在运行 (进程号 PID: $pid)，无需重复启动。"
      return 0 # 0 表示成功（正在运行）
    else
      info "发现残留的 PID 文件，正在清理..."
      rm "$PID_FILE"
    fi
  fi
  return 1 # 1 表示失败（未运行）
}

function create_git_proxy_config() {
  info "正在为 $GIT_SERVER_DOMAIN 创建 Git 代理配置..."
  cat > "$GIT_PROXY_CONFIG_FILE" << EOL
#
# 本文件由 start-proxy.sh 自动生成
# 修改无效，因为每次启动都会被覆盖
#
[http "https://$GIT_SERVER_DOMAIN/"]
    proxy = socks5://127.0.0.1:$SOCKS_PORT
EOL

  if [ $? -ne 0 ]; then
    error "创建 Git 配置文件失败: $GIT_PROXY_CONFIG_FILE"
    exit 1
  fi
  success "Git 代理配置文件已创建于: $GIT_PROXY_CONFIG_FILE"
}

function start_ssh_proxy() {
  info "正在后台启动 SSH SOCKS 代理..."
  # -f: 请求 ssh 在执行命令前进入后台
  # -N: 不执行远程命令，仅用于端口转发
  ssh -fN "$TARGET_HOST"

  # 等待一小会儿，让代理进程完成初始化
  sleep 2
}

function verify_proxy_and_save_pid() {
  # 使用 pgrep 查找后台 SSH 代理进程的 PID。
  # -f 选项匹配整个命令行字符串，确保我们找到的是正确的进程。
  local proxy_pid
  proxy_pid=$(pgrep -f "ssh -fN $TARGET_HOST")

  if [ -n "$proxy_pid" ]; then
    echo "$proxy_pid" > "$PID_FILE"
    success "代理已成功启动: socks5://127.0.0.1:$SOCKS_PORT (进程号 PID: $proxy_pid)"
    info "请运行 './stop-proxy.sh' 来终止代理。"
  else
    error "未能找到已启动的代理进程。"
    error "请尝试手动运行命令进行调试: ssh -v $TARGET_HOST"
    # 如果代理启动失败，清理掉已创建的配置文件
    rm -f "$GIT_PROXY_CONFIG_FILE"
    exit 1
  fi
}

# --- 主程序 ---

if test_proxy_running; then
  exit 0
fi

create_git_proxy_config
start_ssh_proxy
verify_proxy_and_save_pid
