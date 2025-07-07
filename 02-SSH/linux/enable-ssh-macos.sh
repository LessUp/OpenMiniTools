#!/bin/bash

# -----------------------------------------------------------------------------
# 脚本名称: enable-ssh-macos.sh
# 功能描述: 检查并启用 macOS 上的远程登录 (SSH 服务)。
# 作者:     AI Assistant & USER
# 版本:     1.0
# -----------------------------------------------------------------------------

echo "macOS SSH 服务启用脚本"
echo "-------------------------"

# 检查是否以 sudo (root) 权限运行
if [ "$(id -u)" -ne 0 ]; then
  echo "错误：此脚本需要管理员权限 (sudo) 才能运行。"
  echo "请尝试使用 'sudo ./enable-ssh-macos.sh' 来运行。"
  exit 1
fi

echo "正在检查远程登录 (SSH) 服务状态..."

# 获取当前远程登录状态
REMOTE_LOGIN_STATUS=$(systemsetup -getremotelogin)

if [[ "$REMOTE_LOGIN_STATUS" == "Remote Login: On" ]]; then
  echo "远程登录 (SSH) 服务已经启用。"
else
  echo "远程登录 (SSH) 服务当前为关闭状态，正在尝试启用..."
  systemsetup -setremotelogin on
  
  # 再次检查状态以确认
  UPDATED_STATUS=$(systemsetup -getremotelogin)
  if [[ "$UPDATED_STATUS" == "Remote Login: On" ]]; then
    echo "远程登录 (SSH) 服务已成功启用。"
  else
    echo "错误：尝试启用远程登录 (SSH) 服务失败。"
    echo "当前状态: $UPDATED_STATUS"
    echo "请检查系统日志或尝试手动在 系统设置 -> 通用 -> 共享 -> 远程登录 中启用。"
    exit 1
  fi
fi

echo ""
echo "防火墙说明:"
echo "在 macOS 上，启用远程登录通常会自动配置系统防火墙以允许传入的 SSH 连接。"
echo "如果遇到连接问题，请检查 系统设置 -> 网络 -> 防火墙 的设置，确保没有阻止传入连接，"
echo "或者 'sshd-keygen-wrapper' (或类似条目) 被允许接收传入连接。"
echo ""
echo "SSH 服务配置检查完成。"
echo "你现在应该可以使用 SSH 连接到此 Mac。"

exit 0
