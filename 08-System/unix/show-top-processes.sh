#!/bin/bash
# show-top-processes.sh
#
# 显示当前系统中资源占用最高的进程，支持按 CPU 或内存排序。

# --- 配置 ---
set -e
set -o pipefail

# --- 默认值 ---
SORT_BY="cpu" # 'cpu' 或 'mem'
COUNT=10

# --- 颜色定义 ---
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_CYAN='\033[0;36m'

# --- 函数定义 ---

function show_usage() {
    echo "用法: $0 [选项]"
    echo "显示资源占用最高的进程。"
    echo
    echo "选项:"
    echo "  -s, --sort-by <cpu|mem>   指定排序标准 (默认为: cpu)。"
    echo "  -n, --count <数量>        指定显示的进程数量 (默认为: 10)。"
    echo "  -h, --help                显示此帮助信息。"
}

# --- 参数解析 ---
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--sort-by)
            if [[ "$2" != "cpu" && "$2" != "mem" ]]; then
                echo "错误: --sort-by 的值必须是 'cpu' 或 'mem'。" >&2
                exit 1
            fi
            SORT_BY="$2"
            shift 2
            ;;
        -n|--count)
            if ! [[ "$2" =~ ^[0-9]+$ ]]; then
                echo "错误: --count 的值必须是一个正整数。" >&2
                exit 1
            fi
            COUNT="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "错误: 未知选项: $1" >&2
            show_usage
            exit 1
            ;;
    esac
done

# --- 主逻辑 ---

# 根据排序标准设置 ps 命令的 sort key
SORT_KEY="-%${SORT_BY}"

# 打印标题
printf "${C_BOLD}${C_CYAN}--- 按 %s 使用率排序的前 %d 个进程 ---${C_RESET}\n" "$SORT_BY" "$COUNT"

# 使用 ps 命令获取并格式化进程信息
# -axo: 显示所有用户的进程，包括没有控制终端的进程，并使用用户自定义格式
# --sort: 指定排序键
# head: 获取指定数量的行 (COUNT + 1 是为了包含标题行)
ps -axo user:20,pid,%cpu,%mem,cmd --sort="$SORT_KEY" | head -n $((COUNT + 1))
