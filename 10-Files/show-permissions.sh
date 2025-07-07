#!/bin/bash
# show-permissions.sh
#
# 一个用于清晰地显示文件和目录权限的脚本，利用 ls 的强大功能。

# --- 配置 ---
set -e
set -o pipefail

# --- 默认值 ---
RECURSIVE=false

# --- 颜色定义 ---
C_RESET='\033[0m'
C_CYAN='\033[0;36m'
C_BOLD='\033[1m'

# --- 函数定义 ---

function show_usage() {
    echo "用法: $0 [文件/目录...] [选项]"
    echo "以清晰的格式显示一个或多个文件/目录的权限和属性。"
    echo
    echo "选项:"
    echo "  -r, --recursive       递归显示目录内容。"
    echo "  -h, --help            显示此帮助信息。"
    echo
    echo "如果没有提供路径，则显示当前目录的信息。"
}

# --- 参数解析 ---
PATHS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--recursive)
            RECURSIVE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        -*)
            echo "错误: 未知选项: $1" >&2
            show_usage
            exit 1
            ;;
        *)
            PATHS+=("$1")
            shift
            ;;
    esac
done

# 如果没有提供路径，则默认为当前目录
if [ ${#PATHS[@]} -eq 0 ]; then
    PATHS+=(".")
fi

# --- 主逻辑 ---

# 1. 构建 ls 命令选项
LS_OPTS=('-lh' '--color=always')
if [ "$RECURSIVE" = true ]; then
    LS_OPTS+=('-R')
else
    # 使用 -d 来显示目录本身的信息，而不是其内容
    LS_OPTS+=('-d')
fi

# 2. 遍历并显示每个目标的权限
FIRST_ITEM=true
for path in "${PATHS[@]}"; do
    if [ ! -e "$path" ]; then
        echo "警告: '$path' 不存在，已跳过。" >&2
        continue
    fi

    # 添加分隔符
    if [ "$FIRST_ITEM" = false ]; then
        echo
    fi
    FIRST_ITEM=false

    printf "${C_CYAN}${C_BOLD}--- 权限信息: %s ---${C_RESET}\n" "$path"
    ls "${LS_OPTS[@]}" "$path"
done
