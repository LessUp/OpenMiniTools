#!/bin/bash
# extract-archive.sh
#
# 一个能智能识别压缩包类型并使用相应命令进行解压的通用脚本。

# --- 配置 ---
set -e
set -o pipefail

# --- 默认值 ---
OUTPUT_DIR="."

# --- 颜色定义 ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_CYAN='\033[0;36m'

# --- 函数定义 ---

function show_usage() {
    echo "用法: $0 [选项] <压缩文件>"
    echo "智能解压各种类型的压缩文件。"
    echo
    echo "选项:"
    echo "  -o, --output-dir <目录>  指定解压文件的输出目录。默认为当前目录。"
    echo "  -h, --help              显示此帮助信息。"
    echo
    echo "支持的格式: .tar, .tar.gz, .tgz, .tar.bz2, .tbz2, .tar.xz, .txz, .zip, .rar, .7z"
}

# 检查命令是否存在
function check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "${C_RED}错误: 命令 '$1' 未找到。请安装它以支持解压 '$2' 文件。${C_RESET}" >&2
        exit 1
    fi
}

# --- 参数解析 ---
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output-dir)
            OUTPUT_DIR="$2"; shift; shift;;
        -h|--help)
            show_usage; exit 0;; 
        -*) 
            echo "错误: 未知选项: $1" >&2; show_usage; exit 1;; 
        *)
            POSITIONAL_ARGS+=("$1"); shift;;
    esac
done
set -- "${POSITIONAL_ARGS[@]}"

# --- 主逻辑 ---

# 1. 验证输入
ARCHIVE_FILE=$1
if [ -z "$ARCHIVE_FILE" ]; then echo "错误: 未提供要解压的文件。" >&2; show_usage; exit 1; fi
if [ ! -f "$ARCHIVE_FILE" ]; then echo "${C_RED}错误: 文件 '$ARCHIVE_FILE' 不存在。${C_RESET}" >&2; exit 1; fi

# 2. 准备输出目录
mkdir -p "$OUTPUT_DIR"

printf "${C_CYAN}正在解压 '%s' 到 '%s'...${C_RESET}\n" "$ARCHIVE_FILE" "$OUTPUT_DIR"

# 3. 根据扩展名选择解压命令
SUCCESS=false
case "$ARCHIVE_FILE" in
    *.tar.bz2|*.tbz2)
        check_command tar "*.tar.bz2"
        tar xvjf "$ARCHIVE_FILE" -C "$OUTPUT_DIR" && SUCCESS=true
        ;;
    *.tar.gz|*.tgz)
        check_command tar "*.tar.gz"
        tar xvzf "$ARCHIVE_FILE" -C "$OUTPUT_DIR" && SUCCESS=true
        ;;
    *.tar.xz|*.txz)
        check_command tar "*.tar.xz"
        tar xvJf "$ARCHIVE_FILE" -C "$OUTPUT_DIR" && SUCCESS=true
        ;;
    *.tar)
        check_command tar "*.tar"
        tar xvf "$ARCHIVE_FILE" -C "$OUTPUT_DIR" && SUCCESS=true
        ;;
    *.zip)
        check_command unzip "*.zip"
        unzip -o "$ARCHIVE_FILE" -d "$OUTPUT_DIR" && SUCCESS=true
        ;;
    *.rar)
        check_command unrar "*.rar"
        unrar x -o+ "$ARCHIVE_FILE" "$OUTPUT_DIR/" && SUCCESS=true
        ;;
    *.7z)
        check_command 7z "*.7z"
        7z x "$ARCHIVE_FILE" -o"$OUTPUT_DIR" -y && SUCCESS=true
        ;;
    *)
        echo "${C_RED}错误: 无法识别的压缩文件类型: '$ARCHIVE_FILE'${C_RESET}" >&2
        exit 1
        ;;
esac

# 4. 检查结果
if [ "$SUCCESS" = true ]; then
    printf "${C_GREEN}文件已成功解压。${C_RESET}\n"
else
    echo "${C_RED}解压过程中发生错误。${C_RESET}" >&2
    exit 1
fi
