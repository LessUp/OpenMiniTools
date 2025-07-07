#!/bin/bash
# organize-files-by-type.sh
#
# 一个根据文件扩展名将文件整理到分类子目录中的脚本。

# --- 配置 ---
set -e
set -o pipefail

# --- 默认值 ---
SOURCE_DIR="."
DEST_DIR=""
ACTION="mv"
DRY_RUN=false
RECURSIVE=false
OTHER_DIR="misc"

# --- 颜色定义 ---
C_RESET='\033[0m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_CYAN='\033[0;36m'

# --- 文件分类定义 (易于扩展) ---
declare -A CATEGORIES
CATEGORIES=(
    [images]="jpg jpeg png gif bmp svg tiff"
    [documents]="pdf doc docx odt rtf txt md xls xlsx ppt pptx csv"
    [archives]="zip tar gz bz2 7z rar xz"
    [audio]="mp3 wav ogg flac aac m4a"
    [video]="mp4 avi mkv mov wmv flv webm"
    [code]="sh py js html css java c cpp h rb php"
)

# --- 函数定义 ---

function show_usage() {
    echo "用法: $0 [源目录] [选项]"
    echo "根据文件类型整理文件。"
    echo
    echo "参数:"
    echo "  源目录                要整理的目录。默认为当前目录。"
    echo
    echo "选项:"
    echo "  --dest <目录>         整理后文件的存放目录。默认为源目录。"
    echo "  --copy                复制文件而不是移动文件。"
    echo "  -r, --recursive       递归整理所有子目录中的文件。"
    echo "  --other-dir <名称>    未分类文件的目录名。默认为 'misc'。"
    echo "  --dry-run             演练模式，只显示操作而不执行。"
    echo "  -h, --help            显示此帮助信息。"
}

# --- 参数解析 ---
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        --dest) DEST_DIR="$2"; shift 2;; 
        --copy) ACTION="cp"; shift;; 
        -r|--recursive) RECURSIVE=true; shift;; 
        --other-dir) OTHER_DIR="$2"; shift 2;; 
        --dry-run) DRY_RUN=true; shift;; 
        -h|--help) show_usage; exit 0;; 
        -*) echo "错误: 未知选项: $1" >&2; show_usage; exit 1;; 
        *)
            POSITIONAL_ARGS+=("$1"); shift;;
    esac
done
set -- "${POSITIONAL_ARGS[@]}"
if [ ${#POSITIONAL_ARGS[@]} -gt 0 ]; then SOURCE_DIR="${POSITIONAL_ARGS[0]}"; fi
if [ -z "$DEST_DIR" ]; then DEST_DIR="$SOURCE_DIR"; fi

# --- 主逻辑 ---

# 1. 验证输入
if [ ! -d "$SOURCE_DIR" ]; then echo "错误: 源目录 '$SOURCE_DIR' 不存在。" >&2; exit 1; fi
if [ "$DRY_RUN" = true ]; then printf "${C_YELLOW}--- 演练模式已激活 ---${C_RESET}\n"; fi
printf "${C_CYAN}源目录: %s${C_RESET}\n" "$SOURCE_DIR"
printf "${C_CYAN}目标目录: %s${C_RESET}\n" "$DEST_DIR"
printf "${C_CYAN}操作: %s${C_RESET}\n\n" "$ACTION"

# 2. 构建 find 命令
FIND_OPTS=()
if [ "$RECURSIVE" = false ]; then FIND_OPTS+=("-maxdepth" "1"); fi

# 3. 查找并处理文件
find "$SOURCE_DIR" "${FIND_OPTS[@]}" -type f | while IFS= read -r file; do
    # 跳过此脚本本身
    if [[ "$(basename "$file")" == "$(basename "$0")" ]]; then continue; fi

    EXTENSION="${file##*.}"
    # 如果没有扩展名或扩展名与文件名相同
    if [ "$EXTENSION" == "$file" ] || [ -z "$EXTENSION" ]; then
        CATEGORY=$OTHER_DIR
    else
        EXTENSION=${EXTENSION,,} # 转为小写
        CATEGORY=""
        for cat in "${!CATEGORIES[@]}"; do
            if [[ " ${CATEGORIES[$cat]} " =~ " $EXTENSION " ]]; then
                CATEGORY=$cat
                break
            fi
        done
        if [ -z "$CATEGORY" ]; then CATEGORY=$OTHER_DIR; fi
    fi

    # 4. 执行操作
    TARGET_SUBDIR="$DEST_DIR/$CATEGORY"
    ACTION_VERB=$([ "$ACTION" == "cp" ] && echo "复制" || echo "移动")

    if [ "$DRY_RUN" = true ]; then
        printf "[演练] %s '%s' -> '%s/'\n" "$ACTION_VERB" "$file" "$TARGET_SUBDIR"
    else
        mkdir -p "$TARGET_SUBDIR"
        # 使用 -v 选项来显示操作详情
        "$ACTION" -v "$file" "$TARGET_SUBDIR/"
    fi
done

printf "\n${C_GREEN}文件整理完成。${C_RESET}\n"
