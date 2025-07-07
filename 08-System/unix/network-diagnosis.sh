#!/bin/bash
# Ubuntu网络诊断工具
# 用法: ./04-network-diagnosis.sh [主机名]

# 定义默认主机
DEFAULT_HOST="google.com"
HOST="${1:-$DEFAULT_HOST}"

echo "===== Ubuntu网络诊断工具 ====="
echo "当前时间: $(date)"
echo

# 显示网络接口信息
echo "--- 网络接口信息 ---"
ip a
echo

# 显示路由表
echo "--- 路由表 ---"
ip route
echo

# 检查DNS配置
echo "--- DNS配置 ---"
cat /etc/resolv.conf
echo

# 测试DNS解析
echo "--- DNS解析测试 ---"
echo "解析 $HOST:"
host "$HOST"
echo

# Ping测试
echo "--- Ping测试 ---"
echo "Ping $HOST (5次):"
ping -c 5 "$HOST"
echo

# 路由追踪
echo "--- 路由追踪 ---"
echo "追踪到 $HOST 的路由:"
traceroute "$HOST" 2>/dev/null || tracepath "$HOST"
echo

# 显示网络连接状态
echo "--- 网络连接状态 ---"
echo "建立的连接:"
netstat -tunapl | grep ESTABLISHED | head -n 10
echo "监听的端口:"
netstat -tunapl | grep LISTEN | head -n 10
echo

# 检查公网IP
echo "--- 公网IP ---"
echo "您的公网IP是:"
curl -s https://api.ipify.org || wget -qO- https://api.ipify.org || echo "无法获取公网IP"
echo
