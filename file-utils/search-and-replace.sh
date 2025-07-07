#!/bin/bash
# search-and-replace.sh
#
# 在目录中递归地查找和替换文件中的文本，并提供安全功能。

# --- 配置 ---
set -e
set -o pipefail

# --- 默认值 ---
TARGET_DIR="."
RECURSIVE=false
DRY_RUN=false
FORCE=false
NO_BACKUP=false
INCLUDE_PATTERN="*"

# --- 颜色定义 ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_CYAN='\033[0;36m'

# --- 函数定义 ---

function show_usage() {
    echo "用法: $0 <查找内容> <替换内容> [选项]"
    echo "在文件中查找并替换文本。"
    echo
    echo "参数:"
    echo "  <查找内容>            要搜索的字符串或正则表达式。"
    echo "  <替换内容>            用于替换的字符串。"
    echo
    echo "选项:"
    echo "  -d, --dir <目录>      目标目录。默认为当前目录。"
    echo "  -r, --recursive       递归搜索子目录。"
    echo "  --include <模式>      要包含的文件模式 (例如 '*.txt')。默认为所有文件。"
    echo "  --dry-run             演练模式，显示将要进行的更改 (diff) 而不修改文件。"
    echo "  --force               强制执行，无需交互式确认。"
    echo "  --no-backup           执行原地替换，不创建 .bak 备份文件。"
    echo "  -h, --help            显示此帮助信息。"
}

# --- 参数解析 ---
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dir) TARGET_DIR="$2"; shift 2;; 
        -r|--recursive) RECURSIVE=true; shift;; 
        --include) INCLUDE_PATTERN="$2"; shift 2;; 
        --dry-run) DRY_RUN=true; shift;; 
        --force) FORCE=true; shift;; 
        --no-backup) NO_BACKUP=true; shift;; 
        -h|--help) show_usage; exit 0;; 
        -*) echo "错误: 未知选项: $1" >&2; show_usage; exit 1;; 
        *)
            POSITIONAL_ARGS+=("$1"); shift;;
    esac
done
set -- "${POSITIONAL_ARGS[@]}"

# --- 主逻辑 ---

# 1. 验证输入
SEARCH_TERM=$1
REPLACE_TERM=$2
if [ -z "$SEARCH_TERM" ] || [ ${#POSITIONAL_ARGS[@]} -lt 2 ]; then echo "错误: 未提供查找和替换内容。" >&2; show_usage; exit 1; fi
if [ ! -d "$TARGET_DIR" ]; then echo "错误: 目录 '$TARGET_DIR' 不存在。" >&2; exit 1; fi

# 2. 构建 grep 命令
GREP_OPTS=(-l)
if [ "$RECURSIVE" = true ]; then GREP_OPTS+=(-r); fi

# 使用 -Z 和 read -d '' 来安全处理带特殊字符的文件名
FILES_TO_PROCESS=()
while IFS= read -r -d '' file; do
    FILES_TO_PROCESS+=("$file")
done < <(grep "${GREP_OPTS[@]}" -Z -- "$SEARCH_TERM" "$TARGET_DIR" --include="$INCLUDE_PATTERN")

if [ ${#FILES_TO_PROCESS[@]} -eq 0 ]; then
    echo "未找到包含 '$SEARCH_TERM' 的文件。"
    exit 0
fi

# 3. 执行操作
if [ "$DRY_RUN" = true ]; then
    printf "${C_YELLOW}--- 演练模式 ---${C_RESET}\n"
    printf "将对以下文件模拟 's/%s/%s/g' 操作:\n" "$SEARCH_TERM" "$REPLACE_TERM"
    for file in "${FILES_TO_PROCESS[@]}"; do
        printf "\n${C_CYAN}--- diff for %s ---${C_RESET}\n" "$file"
        # 使用 diff 和进程替换来显示更改，而不修改文件
        diff -u --color=always "$file" <(sed "s|${SEARCH_TERM}|${REPLACE_TERM}|g" "$file") || true
    done
    exit 0
fi

# 4. 真实执行
printf "将对以下 ${#FILES_TO_PROCESS[@]} 个文件执行替换:\n"
printf '%s\n' "${FILES_TO_PROCESS[@]}"
printf "\n"

if [ "$FORCE" = false ]; then
    read -p "是否要将 '${SEARCH_TERM}' 替换为 '${REPLACE_TERM}'? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "操作已取消。"
        exit 1
    fi
fi

SED_OPTS=(-i)
if [ "$NO_BACKUP" = false ]; then
    SED_OPTS+=('.bak')
fi

printf "正在替换...\n"
for file in "${FILES_TO_PROCESS[@]}"; do
    sed "${SED_OPTS[@]}" "s|${SEARCH_TERM}|${REPLACE_TERM}|g" "$file"
    printf "已修改: %s%s\n" "$file" "$([ "$NO_BACKUP" = false ] && echo ' (备份已创建)')"
done

printf "\n${C_GREEN}替换完成。${C_RESET}\n"
