#!/bin/bash
# check-url-status.sh
#
# 一个用于检查 URL 可访问性、HTTP 状态和响应时间的脚本。

# --- 配置 ---
set -e
set -o pipefail

# --- 默认值 ---
REQUEST_METHOD="HEAD"
TIMEOUT=10
FOLLOW_REDIRECTS=false
VERBOSE=false

# --- 颜色定义 ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_CYAN='\033[0;36m'

# --- 函数定义 ---

function show_usage() {
    echo "用法: $0 [选项] <URL>"
    echo "检查一个 URL 的可访问性、HTTP 状态和响应时间。"
    echo
    echo "选项:"
    echo "  -m, --method <方法>    指定 HTTP 请求方法 (例如 GET, HEAD, POST)。默认为 HEAD。"
    echo "  -t, --timeout <秒>     设置请求超时时间。默认为 10 秒。"
    echo "  -f, --follow-redirects 跟随 HTTP 重定向 (-L)。"
    echo "  -v, --verbose           显示完整的响应头信息。"
    echo "  -h, --help              显示此帮助信息。"
}

# --- 参数解析 ---
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--method) REQUEST_METHOD="$2"; shift; shift;; 
        -t|--timeout) TIMEOUT="$2"; shift; shift;; 
        -f|--follow-redirects) FOLLOW_REDIRECTS=true; shift;; 
        -v|--verbose) VERBOSE=true; shift;; 
        -h|--help) show_usage; exit 0;; 
        -*) echo "错误: 未知选项: $1" >&2; show_usage; exit 1;; 
        *) POSITIONAL_ARGS+=("$1"); shift;;
    esac
done
set -- "${POSITIONAL_ARGS[@]}"

# --- 主逻辑 ---

# 1. 验证输入和依赖
URL=$1
if [ -z "$URL" ]; then
    echo "错误: 未提供 URL。" >&2
    show_usage
    exit 1
fi

if ! command -v curl &> /dev/null; then
    echo "错误: 'curl' 命令未找到。请先安装 curl。" >&2
    exit 1
fi

# 2. 构建 curl 命令
CURL_OPTS=("-s" "-X" "$REQUEST_METHOD" "--connect-timeout" "$TIMEOUT")

# 如果是 HEAD 请求，使用 -I。否则，使用 -i 并丢弃 body。这可以确保我们总是能看到头信息。
if [ "$REQUEST_METHOD" == "HEAD" ]; then
    CURL_OPTS+=("-I")
else
    CURL_OPTS+=("-i" "-o" "/dev/null")
fi

if [ "$FOLLOW_REDIRECTS" = true ]; then
    CURL_OPTS+=("-L")
fi

# 添加自定义输出格式
WRITE_OUT_FORMAT="{\"status\":\"%{http_code}\",\"time\":\"%{time_total}\",\"ip\":\"%{remote_ip}\"}"
CURL_OPTS+=("-w" "$WRITE_OUT_FORMAT")

# 3. 执行并解析结果
printf "${C_CYAN}--- 正在检查 URL: %s ---${C_RESET}\n" "$URL"

# 将头信息和统计信息分开捕获
# stderr 用于捕获头信息 (-D -)，stdout 用于捕获统计信息 (-w %{stdout})
exec 3>&1 # 保存原始的 stdout
RESPONSE=$(curl "${CURL_OPTS[@]}" "$URL" -o /dev/null -D - 1>&3)
exec 3>&- # 关闭文件描述符3

# 响应体包含两部分：头信息和我们的 JSON 统计数据
HEADERS=$(echo "$RESPONSE" | sed '/^{.*}$/d')
STATS_JSON=$(echo "$RESPONSE" | sed -n '/^{.*}$/p')

HTTP_STATUS=$(echo "$STATS_JSON" | awk -F'"' '{print $4}')
TOTAL_TIME=$(echo "$STATS_JSON" | awk -F'"' '{print $8}')
REMOTE_IP=$(echo "$STATS_JSON" | awk -F'"' '{print $12}')

# 4. 显示结果
STATUS_COLOR=$C_RESET
case "$HTTP_STATUS" in
    2*) STATUS_COLOR=$C_GREEN;;
    3*) STATUS_COLOR=$C_BLUE;;
    4*) STATUS_COLOR=$C_YELLOW;;
    5*) STATUS_COLOR=$C_RED;;
esac

printf "状态码: %b%s%b\n" "$STATUS_COLOR" "$HTTP_STATUS" "$C_RESET"
printf "响应时间: %s 秒\n" "$TOTAL_TIME"
printf "远程 IP: %s\n" "$REMOTE_IP"

if [ "$VERBOSE" = true ]; then
    printf "\n${C_CYAN}--- 响应头 ---${C_RESET}\n%s\n" "$HEADERS"
fi
