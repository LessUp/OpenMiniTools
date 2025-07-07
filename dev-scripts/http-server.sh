#!/bin/bash
# start-http-server.sh
#
# 一个用于在指定目录快速启动一个简单 HTTP 服务器的脚本。

# --- 配置 ---
set -e
set -o pipefail

# --- 默认值 ---
PORT=8000
DIR="."

# --- 颜色定义 ---
C_RESET='\033[0m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_CYAN='\033[0;36m'

# --- 函数定义 ---

function show_usage() {
    echo "用法: $0 [选项]"
    echo "在指定目录快速启动一个 HTTP 服务器。"
    echo
    echo "选项:"
    echo "  -p, --port <端口>     服务器监听的端口。默认为 8000。"
    echo "  -d, --dir <目录>      作为服务器根目录的路径。默认为当前目录。"
    echo "  -h, --help            显示此帮助信息。"
}

# --- 参数解析 ---
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--port)
            PORT="$2"; shift 2;;
        -d|--dir)
            DIR="$2"; shift 2;;
        -h|--help)
            show_usage; exit 0;; 
        -*) 
            echo "错误: 未知选项: $1" >&2; show_usage; exit 1;; 
        *)
            echo "错误: 无效的参数: $1" >&2; show_usage; exit 1;;
    esac
done

# --- 主逻辑 ---

# 1. 验证输入
if [ ! -d "$DIR" ]; then echo "错误: 目录 '$DIR' 不存在。" >&2; exit 1; fi

# 2. 检测 Python 版本
PYTHON_CMD=""
if command -v python3 &>/dev/null; then
    PYTHON_CMD="python3 -m http.server"
elif command -v python &>/dev/null; then
    PYTHON_CMD="python -m SimpleHTTPServer"
else
    echo "错误: 未安装 Python，无法启动服务器。" >&2; exit 1;
fi

# 3. 获取 IP 地址并显示信息
# 尝试获取一个非回环的 IPv4 地址
IP_ADDR=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n 1)

printf "${C_CYAN}--- 启动 HTTP 服务器 ---${C_RESET}\n"
printf "服务目录: ${C_YELLOW}%s${C_RESET}\n" "$(realpath "$DIR")"
printf "端口:       ${C_YELLOW}%s${C_RESET}\n\n" "$PORT"
printf "${C_GREEN}可通过以下地址访问:${C_RESET}\n"
printf "  Local:   http://localhost:%s\n" "$PORT"
if [ -n "$IP_ADDR" ]; then
    printf "  Network: http://%s:%s\n" "$IP_ADDR" "$PORT"
fi
printf "\n${C_YELLOW}(按 Ctrl+C 停止服务器)${C_RESET}\n"

# 4. 切换到目标目录并启动服务器
cd "$DIR"
$PYTHON_CMD "$PORT"
