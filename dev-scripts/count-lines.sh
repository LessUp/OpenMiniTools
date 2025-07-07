#!/bin/bash
# count-lines.sh
#
# 一个灵活的代码行数统计工具，支持按文件类型统计并排除特定目录。

# --- 配置 ---
set -e
set -o pipefail

# --- 默认值 ---
FILE_TYPES=()
EXCLUDE_DIRS=()
TARGET_DIR="."

# --- 颜色定义 ---
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_CYAN='\033[0;36m'
C_GREEN='\033[0;32m'

# --- 函数定义 ---

function show_usage() {
    echo "用法: $0 [目标目录] [选项]"
    echo "统计指定目录中各类文件的代码行数。"
    echo
    echo "选项:"
    echo "  -t, --types <类型>      要统计的文件类型，以逗号分隔 (例如: 'sh,py,md')。"
    echo "  -e, --exclude-dir <目录>  要排除的目录名 (例如: 'node_modules')，可多次使用。"
    echo "  -h, --help                显示此帮助信息。"
}

# --- 参数解析 ---
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--types)
            IFS=',' read -r -a FILE_TYPES <<< "$2"; shift 2;;
        -e|--exclude-dir)
            EXCLUDE_DIRS+=("$2"); shift 2;;
        -h|--help)
            show_usage; exit 0;;
        -*)
            echo "错误: 未知选项: $1" >&2; show_usage; exit 1;;
        *)
            POSITIONAL_ARGS+=("$1"); shift;;
    esac
done
set -- "${POSITIONAL_ARGS[@]}"
if [ -n "$1" ]; then TARGET_DIR="$1"; fi

# --- 输入校验 ---
if [ ! -d "$TARGET_DIR" ]; then
    echo "错误: 目标目录 '$TARGET_DIR' 不存在。" >&2; exit 1;
fi
if [ ${#FILE_TYPES[@]} -eq 0 ]; then
    echo "错误: 请使用 -t 或 --types 指定至少一种文件类型。" >&2; show_usage; exit 1;
fi

# --- 主逻辑 ---

# 1. 构建 find 命令的排除部分
EXCLUDE_ARGS=()
for dir in "${EXCLUDE_DIRS[@]}"; do
    EXCLUDE_ARGS+=("-path" "*/$dir/*" "-prune" "-o")
done

# 2. 统计并打印结果
printf "${C_BOLD}${C_CYAN}%-15s %10s %15s %15s${C_RESET}\n" "文件类型" "文件数" "总行数" "平均行数"
printf -- '-%.0s' {1..60}; echo

TOTAL_FILES=0
TOTAL_LINES=0

for type in "${FILE_TYPES[@]}"; do
    # 查找文件并传递给 wc
    # 使用 find ... -print0 | xargs -0 ... 来安全处理包含特殊字符的文件名
    readarray -t files < <(find "$TARGET_DIR" ${EXCLUDE_ARGS[@]} -type f -name "*.$type" -print0 | xargs -0 -r realpath)
    
    NUM_FILES=${#files[@]}
    
    if [ "$NUM_FILES" -gt 0 ]; then
        # 使用 cat 和 wc 一次性计算所有文件的总行数
        NUM_LINES=$(cat "${files[@]}" | wc -l | awk '{print $1}')
        AVG_LINES=$((NUM_LINES / NUM_FILES))
    else
        NUM_LINES=0
        AVG_LINES=0
    fi

    printf "%-15s %10d %15d %15d\n" "*.$type" "$NUM_FILES" "$NUM_LINES" "$AVG_LINES"
    
    TOTAL_FILES=$((TOTAL_FILES + NUM_FILES))
    TOTAL_LINES=$((TOTAL_LINES + NUM_LINES))
done

# 3. 打印总计
printf -- '-%.0s' {1..60}; echo
AVG_TOTAL_LINES=0
if [ "$TOTAL_FILES" -gt 0 ]; then
    AVG_TOTAL_LINES=$((TOTAL_LINES / TOTAL_FILES))
fi
printf "${C_BOLD}${C_GREEN}%-15s %10d %15d %15d${C_RESET}\n" "总计" "$TOTAL_FILES" "$TOTAL_LINES" "$AVG_TOTAL_LINES"
