#!/bin/bash
# find-large-files.sh
#
# 一个用于在文件系统中查找并列出最大文件的脚本。

# --- 配置 ---
set -e
set -o pipefail

# --- 默认值 ---
TOP_N=10
MIN_SIZE=""

# --- 颜色定义 ---
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_CYAN='\033[0;36m'

# --- 函数定义 ---

function show_usage() {
    echo "用法: $0 [目标目录] [选项]"
    echo "查找并列出指定目录中体积最大的文件。"
    echo
    echo "参数:"
    echo "  目标目录              要扫描的目录。默认为当前目录。"
    echo
    echo "选项:"
    echo "  -n, --top <数量>        要显示的顶部文件数量。默认为 10。"
    echo "  -s, --min-size <大小>   设置查找的最小文件大小 (例如 100M, 1G)。"
    echo "  -h, --help              显示此帮助信息。"
}

# --- 参数解析 ---
TARGET_DIR="."
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--top)
            TOP_N="$2"; shift; shift;;
        -s|--min-size)
            MIN_SIZE="$2"; shift; shift;;
        -h|--help)
            show_usage; exit 0;; 
        -*) 
            echo "错误: 未知选项: $1" >&2; show_usage; exit 1;; 
        *)
            POSITIONAL_ARGS+=("$1"); shift;;
    esac
done

# 处理位置参数
if [ ${#POSITIONAL_ARGS[@]} -gt 0 ]; then
    TARGET_DIR="${POSITIONAL_ARGS[0]}"
fi

if [ ! -d "$TARGET_DIR" ]; then echo "错误: 目录 '$TARGET_DIR' 不存在。" >&2; exit 1; fi
if ! [[ "$TOP_N" =~ ^[0-9]+$ ]]; then echo "错误: --top 的值必须是一个正整数。" >&2; exit 1; fi

# --- 主逻辑 ---

# 1. 构建 find 命令
FIND_CMD=("find" "$TARGET_DIR" "-type" "f")

if [ -n "$MIN_SIZE" ]; then
    FIND_CMD+=("-size" "+$MIN_SIZE")
fi

# 使用 printf 输出字节数和路径，便于精确排序
FIND_CMD+=("-printf" "%s %p\n")

printf "${C_CYAN}正在扫描 '%s' 中大于 %s 的文件...${C_RESET}\n" "$TARGET_DIR" "${MIN_SIZE:-0B}"

# 2. 执行查找和排序
# 使用 eval 来正确处理带空格的路径
RESULTS=$(eval "${FIND_CMD[@]}" | sort -rn | head -n "$TOP_N")

if [ -z "$RESULTS" ]; then
    echo "没有找到匹配的文件。"
    exit 0
fi

# 3. 格式化并显示结果
printf "\n${C_BOLD}%-5s %-15s %s${C_RESET}\n" "排名" "大小" "文件路径"
printf "%s\n" "------------------------------------------------------------------"

# 检查 numfmt 是否可用，用于美化文件大小显示
HAS_NUMFMT=false
if command -v numfmt &> /dev/null; then
    HAS_NUMFMT=true
fi

RANK=1
echo "$RESULTS" | while read -r line; do
    # 从行中分离大小和路径
    size=$(echo "$line" | awk '{print $1}')
    path=$(echo "$line" | cut -d' ' -f2-)

    # 格式化大小
    if [ "$HAS_NUMFMT" = true ]; then
        formatted_size=$(numfmt --to=iec-i --suffix=B --format='%.2f' "$size")
    else
        formatted_size="${size}B"
    fi

    printf "%-5d %-15s %s\n" "$RANK" "$formatted_size" "$path"
    ((RANK++))
done
