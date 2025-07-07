#!/bin/bash
# clean-directory.sh
#
# 一个安全、灵活的目录清理工具，支持按模式、按时间清理，并默认启用演练模式。

# --- 配置 ---
set -e
set -o pipefail

# --- 默认值 ---
PATTERNS=()
DAYS_OLD=""
RECURSIVE=false
FORCE=false
TARGET_DIR=""

# --- 颜色定义 ---
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_RED='\033[0;31m'
C_YELLOW='\033[0;33m'
C_CYAN='\033[0;36m'

# --- 函数定义 ---

function show_usage() {
    echo "用法: $0 <目标目录> [选项]"
    echo "安全地清理目录中的文件。默认在演练模式下运行。"
    echo
    echo "必须至少提供一个清理条件 (--pattern 或 --days-old)。"
    echo
    echo "选项:"
    echo "  -p, --pattern <模式>      要删除的文件模式 (例如 '*.log')，可多次使用。"
    echo "  -d, --days-old <天数>   删除修改时间早于 N 天的文件。"
    echo "  -r, --recursive           递归清理子目录。"
    echo "      --force                 禁用演练模式，实际执行删除操作。"
    echo "  -h, --help                  显示此帮助信息。"
}

# --- 参数解析 ---
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--pattern)
            PATTERNS+=("$2"); shift 2;;
        -d|--days-old)
            if ! [[ "$2" =~ ^[0-9]+$ ]]; then
                echo -e "${C_RED}错误: --days-old 的值必须是一个整数。${C_RESET}" >&2; exit 1;
            fi
            DAYS_OLD="$2"; shift 2;;
        -r|--recursive)
            RECURSIVE=true; shift;;
        --force)
            FORCE=true; shift;;
        -h|--help)
            show_usage; exit 0;;
        -*)
            echo -e "${C_RED}错误: 未知选项: $1${C_RESET}" >&2; show_usage; exit 1;;
        *)
            POSITIONAL_ARGS+=("$1"); shift;;
    esac
done
set -- "${POSITIONAL_ARGS[@]}"
TARGET_DIR=${1:-.}

# --- 输入校验 ---
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${C_RED}错误: 目标目录 '$TARGET_DIR' 不存在。${C_RESET}" >&2; exit 1;
fi
if [ ${#PATTERNS[@]} -eq 0 ] && [ -z "$DAYS_OLD" ]; then
    echo -e "${C_RED}错误: 请至少提供一个清理条件 (--pattern 或 --days-old)。${C_RESET}" >&2; show_usage; exit 1;
fi

# --- 主逻辑 ---

# 1. 构建 find 命令
FIND_CMD=("find" "$TARGET_DIR")
if [ "$RECURSIVE" = false ]; then
    FIND_CMD+=("-maxdepth" "1")
fi
FIND_CMD+=("-type" "f")

if [ ${#PATTERNS[@]} -gt 0 ]; then
    FIND_CMD+=("(")
    for i in "${!PATTERNS[@]}"; do
        if [ $i -ne 0 ]; then FIND_CMD+=("-o"); fi
        FIND_CMD+=("-name" "${PATTERNS[$i]}")
    done
    FIND_CMD+=(")")
fi

if [ -n "$DAYS_OLD" ]; then
    FIND_CMD+=("-mtime" "+$DAYS_OLD")
fi

# 2. 查找文件
printf "${C_CYAN}--- 目录清理 ---${C_RESET}\n"
printf "${C_YELLOW}%-12s${C_RESET} %s\n" "目标目录:" "$TARGET_DIR"

readarray -t FILES_TO_DELETE < <("${FIND_CMD[@]}")

if [ ${#FILES_TO_DELETE[@]} -eq 0 ]; then
    echo "没有找到符合条件的文件。"
    exit 0
fi

# 3. 执行操作 (演练或强制删除)
if [ "$FORCE" = false ]; then
    printf "\n${C_BOLD}${C_YELLOW}*** 演练模式 (Dry Run) ***${C_RESET}\n"
    printf "以下 ${#FILES_TO_DELETE[@]} 个文件将会被删除 (使用 --force 选项以实际执行):\n"
    printf '%s\n' "${FILES_TO_DELETE[@]}"
else
    printf "\n${C_BOLD}${C_RED}*** 强制执行模式 ***${C_RESET}\n"
    printf "将要删除以下 ${#FILES_TO_DELETE[@]} 个文件:\n"
    printf '%s\n' "${FILES_TO_DELETE[@]}"
    echo
    read -p "是否确认删除? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "正在删除..."
        # 使用 xargs 提高效率
        printf '%s\0' "${FILES_TO_DELETE[@]}" | xargs -0 rm -v
        echo "清理完成。"
    else
        echo "操作已取消。"
    fi
fi
