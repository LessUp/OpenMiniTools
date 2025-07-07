#!/bin/bash
# cleanup-directory.sh
#
# 一个强大且可配置的脚本，用于根据多种条件（如名称模式、时间和大小）清理目录中的文件。

# --- 配置 ---
set -e
set -o pipefail

# --- 默认值 ---
PATTERN=""
DAYS_OLD=""
MIN_SIZE=""
RECURSIVE=false
DRY_RUN=false
FORCE=false
CLEAN_EMPTY_DIRS=false

# --- 颜色定义 ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_YELLOW='\033[0;33m'
C_CYAN='\033[0;36m'

# --- 函数定义 ---

function show_usage() {
    echo "用法: $0 [选项] <目标目录>"
    echo "根据指定的条件清理目录中的文件。"
    echo
    echo "选项:"
    echo "  -p, --pattern <模式>   要删除的文件名模式 (例如 '*.log', 'tmp-*')。"
    echo "  -d, --days-old <天数>  删除修改时间早于指定天数的文件。"
    echo "  -s, --size <大小>      删除大于指定大小的文件 (例如 10M, 1G)。"
    echo "  -r, --recursive         递归清理子目录。默认为仅当前目录。"
    echo "      --empty-dirs        清理文件后，删除所有变为空的子目录。"
    echo "      --dry-run           显示将要删除的文件，但不实际执行删除操作。"
    echo "  -f, --force             无需确认，直接执行删除。适用于自动化脚本。"
    echo "  -h, --help              显示此帮助信息。"
}

# --- 参数解析 ---
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--pattern) PATTERN="$2"; shift; shift;;
        -d|--days-old) DAYS_OLD="$2"; shift; shift;;
        -s|--size) MIN_SIZE="$2"; shift; shift;;
        -r|--recursive) RECURSIVE=true; shift;;
        --empty-dirs) CLEAN_EMPTY_DIRS=true; shift;;
        --dry-run) DRY_RUN=true; shift;;
        -f|--force) FORCE=true; shift;;
        -h|--help) show_usage; exit 0;; 
        -*) echo "错误: 未知选项: $1" >&2; show_usage; exit 1;; 
        *) POSITIONAL_ARGS+=("$1"); shift;;
    esac
done
set -- "${POSITIONAL_ARGS[@]}"

# --- 主逻辑 ---

# 1. 验证输入
TARGET_DIR=$1
if [ -z "$TARGET_DIR" ]; then echo "错误: 未提供目标目录。" >&2; show_usage; exit 1; fi
if [ ! -d "$TARGET_DIR" ]; then echo "错误: 目录 '$TARGET_DIR' 不存在。" >&2; exit 1; fi
if [ -z "$PATTERN" ] && [ -z "$DAYS_OLD" ] && [ -z "$MIN_SIZE" ]; then
    echo "错误: 至少需要提供一个过滤条件 (--pattern, --days-old, 或 --size)。" >&2; exit 1;
fi

# 2. 构建 find 命令
FIND_CMD=("find" "$TARGET_DIR")

if [ "$RECURSIVE" = false ]; then FIND_CMD+=("-maxdepth" "1"); fi

FIND_CMD+=("-type" "f")

if [ -n "$PATTERN" ]; then FIND_CMD+=("-name" "$PATTERN"); fi
if [ -n "$DAYS_OLD" ]; then FIND_CMD+=("-mtime" "+$DAYS_OLD"); fi
if [ -n "$MIN_SIZE" ]; then FIND_CMD+=("-size" "+$MIN_SIZE"); fi

# 3. 查找文件
printf "${C_CYAN}--- 正在查找匹配的文件... ---${C_RESET}\n"
# 使用 process substitution 和 tee 来同时显示和捕获列表
# 使用 readarray -t 来安全处理带空格的文件名
readarray -t FILES_TO_DELETE < <(eval "${FIND_CMD[@]}")

if [ ${#FILES_TO_DELETE[@]} -eq 0 ]; then
    echo "没有找到匹配的文件。无需清理。"
    exit 0
fi

# 4. 执行操作 (演练或删除)
if [ "$DRY_RUN" = true ]; then
    printf "${C_YELLOW}[演练模式] 以下文件将会被删除:${C_RESET}\n"
    printf '%s\n' "${FILES_TO_DELETE[@]}"
    exit 0
fi

printf "${C_RED}警告: 将要删除以下 ${#FILES_TO_DELETE[@]} 个文件:${C_RESET}\n"
printf '%s\n' "${FILES_TO_DELETE[@]}"
echo

if [ "$FORCE" = false ]; then
    read -p "你确定要继续吗? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "操作已取消。"
        exit 1
    fi
fi

# 5. 执行删除
printf "${C_CYAN}--- 正在删除文件... ---${C_RESET}\n"
# 使用 -print0 和 xargs -0 来最安全地处理所有文件名
eval "${FIND_CMD[@]} -print0" | xargs -0 --no-run-if-empty rm -v

if [ "$CLEAN_EMPTY_DIRS" = true ]; then
    printf "\n${C_CYAN}--- 正在清理空目录... ---${C_RESET}\n"
    find "$TARGET_DIR" -mindepth 1 -type d -empty -delete -print
fi

printf "\n清理完成。\n"
