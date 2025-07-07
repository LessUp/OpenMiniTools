#!/bin/bash
# ==============================================================================
#
#   文件: stop-proxy.sh
#   描述: 停止后台运行的 SSH SOCKS5 代理进程，并清理所有相关的临时配置文件。
#   作者: Your Name
#   版本: 1.1
#   更新日期: 2024-07-01
#
# ==============================================================================

# --- 配置 ---
set -e
set -o pipefail

# --- 内部变量定义 ---
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PID_FILE="$SCRIPT_DIR/.proxy-pid"
GIT_PROXY_CONFIG_FILE="$HOME/.gitconfig-proxy"

# --- 颜色定义 ---
C_RESET='\033[0m'
C_CYAN='\033[0;36m'
C_GREEN='\033[0;32m'
C_RED='\033[0;31m'

# --- 函数定义 ---

info() { echo -e "${C_CYAN}$1${C_RESET}"; }
success() { echo -e "${C_GREEN}$1${C_RESET}"; }
error() { echo -e "${C_RED}$1${C_RESET}"; }

function stop_proxy_process() {
  info "[*] 步骤 1: 正在停止代理进程..."
  if [ ! -f "$PID_FILE" ]; then
    info "    [信息] 未找到 PID 文件，无需停止进程。"
    return
  fi

  local pid
  pid=$(cat "$PID_FILE")
  if ps -p "$pid" > /dev/null; then
    info "    正在终止代理进程 (PID: $pid)..."
    if kill "$pid"; then
      success "    [成功] 代理进程已终止。"
    else
      error "    [错误] 终止进程失败，请手动检查。"
    fi
  else
    info "    [信息] 未找到进程号为 $pid 的进程，可能已被手动停止。"
  fi
  
  # 无论成功与否，都清理 PID 文件
  rm -f "$PID_FILE"
  success "    [成功] PID 文件已清理。"
}

function clean_git_config() {
  info "[*] 步骤 2: 正在清理代理配置文件..."
  if [ -f "$GIT_PROXY_CONFIG_FILE" ]; then
    if rm "$GIT_PROXY_CONFIG_FILE"; then
      success "    [成功] 已成功移除 '$GIT_PROXY_CONFIG_FILE'。"
    else
      error "    [错误] 移除配置文件时出错。"
    fi
  else
    info "    [信息] 未找到代理配置文件，无需清理。"
  fi
}

# --- 主程序 ---
echo "======================================"
echo "==      通用 Git 代理停止程序       =="
echo "======================================"

stop_proxy_process
echo
clean_git_config

echo
echo "======================================"
echo "==         所有清理操作已完成         =="
echo "======================================"
