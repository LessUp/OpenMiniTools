#!/bin/bash
# create-archive.sh
#
# 一个强大且灵活的脚本，用于创建 tar 归档文件，支持多种压缩格式、排除规则和演练模式。

# --- 配置 ---
set -e
set -o pipefail

# --- 默认值 ---
OUTPUT_DIR="."
FILENAME=""
COMPRESS="gz" # gz, bz2, xz
EXCLUDE_PATTERNS=()
DRY_RUN=false
VERBOSE=false
SOURCES=()

# --- 颜色定义 ---
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_CYAN='\033[0;36m'

# --- 函数定义 ---

function show_usage() {
    echo "用法: $0 [源文件/目录...] [选项]"
    echo "创建一个灵活的 tar 归档文件。"
    echo
    echo "选项:"
    echo "  -o, --output-dir <目录>   指定归档文件的输出目录 (默认为: 当前目录)。"
    echo "  -f, --filename <名称>       指定归档文件的名称 (不含扩展名)。"
    echo "      --compress <gz|bz2|xz>  指定压缩格式 (默认为: gz)。"
    echo "      --exclude <模式>        排除文件/目录 (可多次使用)。"
    echo "      --dry-run               列出将要归档的文件，但不实际创建归档。"
    echo "  -v, --verbose               显示 tar 命令的详细处理过程。"
    echo "  -h, --help                  显示此帮助信息。"
    echo
    echo "示例: $0 ./project --exclude 'node_modules' -f my_project_backup"
}

# --- 参数解析 ---
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output-dir)
            OUTPUT_DIR="$2"; shift 2;;
        -f|--filename)
            FILENAME="$2"; shift 2;;
        --compress)
            if [[ ! "$2" =~ ^(gz|bz2|xz)$ ]]; then
                echo -e "${C_RED}错误: 无效的压缩格式 '$2'。必须是 'gz', 'bz2', 或 'xz'。${C_RESET}" >&2; exit 1;
            fi
            COMPRESS="$2"; shift 2;;
        --exclude)
            EXCLUDE_PATTERNS+=("--exclude=$2"); shift 2;;
        --dry-run)
            DRY_RUN=true; shift;;
        -v|--verbose)
            VERBOSE=true; shift;;
        -h|--help)
            show_usage; exit 0;;
        -*)
            echo -e "${C_RED}错误: 未知选项: $1${C_RESET}" >&2; show_usage; exit 1;;
        *)
            SOURCES+=("$1"); shift;;
    esac
done

# --- 输入校验 ---
if [ ${#SOURCES[@]} -eq 0 ]; then
    echo -e "${C_RED}错误: 至少需要提供一个源文件或目录。${C_RESET}" >&2; show_usage; exit 1;
fi

for src in "${SOURCES[@]}"; do
    if [ ! -e "$src" ]; then
        echo -e "${C_RED}错误: 源 '$src' 不存在。${C_RESET}" >&2; exit 1;
    fi
done

if [ ! -d "$OUTPUT_DIR" ]; then
    echo -e "${C_YELLOW}输出目录 '$OUTPUT_DIR' 不存在，正在尝试创建...${C_RESET}"
    mkdir -p "$OUTPUT_DIR"
fi

# --- 主逻辑 ---

# 1. 确定压缩选项和文件扩展名
TAR_OPTS=""
EXT=""
case "$COMPRESS" in
    gz) TAR_OPTS="-czf"; EXT=".tar.gz";;
    bz2) TAR_OPTS="-cjf"; EXT=".tar.bz2";;
    xz) TAR_OPTS="-cJf"; EXT=".tar.xz";;
esac

if [ "$VERBOSE" = true ]; then
    TAR_OPTS="${TAR_OPTS}v"
fi

# 2. 构建最终的文件名
if [ -z "$FILENAME" ]; then
    # 如果只有一个源，使用源的基本名
    if [ ${#SOURCES[@]} -eq 1 ]; then
        BASENAME=$(basename "${SOURCES[0]}")
        FILENAME="${BASENAME}-$(date +%Y%m%d_%H%M%S)"
    else
        FILENAME="archive-$(date +%Y%m%d_%H%M%S)"
    fi
fi
FINAL_ARCHIVE_PATH="${OUTPUT_DIR}/${FILENAME}${EXT}"

# 3. 构建并执行 tar 命令
TAR_CMD=("tar" "$TAR_OPTS" "$FINAL_ARCHIVE_PATH" "${EXCLUDE_PATTERNS[@]}" "${SOURCES[@]}")

printf "${C_CYAN}--- 创建归档文件 ---${C_RESET}\n"
printf "${C_YELLOW}%-15s${C_RESET} %s\n" "源:" "${SOURCES[*]}"
printf "${C_YELLOW}%-15s${C_RESET} %s\n" "目标归档:" "$FINAL_ARCHIVE_PATH"
if [ ${#EXCLUDE_PATTERNS[@]} -gt 0 ]; then
    printf "${C_YELLOW}%-15s${C_RESET} %s\n" "排除规则:" "$(printf '%s ' "${EXCLUDE_PATTERNS[@]}")"
fi
echo

if [ "$DRY_RUN" = true ]; then
    printf "${C_BOLD}*** 演练模式 (Dry Run) ***${C_RESET}\n"
    printf "将要包含在归档中的文件列表:\n"
    # 使用 tar 的 list 功能模拟
    # shellcheck disable=SC2068
    tar -cvf /dev/null ${EXCLUDE_PATTERNS[@]} ${SOURCES[@]}
    printf "\n${C_GREEN}演练完成。没有创建任何文件。${C_RESET}\n"
    exit 0
fi

# 执行命令
echo "正在创建归档，请稍候..."
"${TAR_CMD[@]}"

if [ $? -eq 0 ]; then
    printf "\n${C_GREEN}成功创建归档: %s${C_RESET}\n" "$FINAL_ARCHIVE_PATH"
else
    printf "\n${C_RED}创建归档失败。${C_RESET}\n" >&2
    # 清理可能产生的空文件或不完整文件
    rm -f "$FINAL_ARCHIVE_PATH"
    exit 1
fi
