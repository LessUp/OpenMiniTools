#!/bin/bash
# extract-archive.sh
#
# 一个通用的归档文件解压工具，能自动识别文件类型并使用合适的命令进行解压。

# --- 配置 ---
set -e
set -o pipefail

# --- 默认值 ---
OUTPUT_DIR=""
ARCHIVE_FILES=()

# --- 颜色定义 ---
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_CYAN='\033[0;36m'

# --- 函数定义 ---

function show_usage() {
    echo "用法: $0 [选项] <归档文件1> [归档文件2] ..."
    echo "自动解压一个或多个常见格式的归档文件。"
    echo
    echo "选项:"
    echo "  -o, --output <目录>   指定解压文件的输出目录。"
    echo "  -h, --help              显示此帮助信息。"
    echo
    echo "支持的格式: .tar, .tar.gz, .tgz, .tar.bz2, .tbz, .tar.xz, .txz, .zip, .rar, .7z"
}

# 检查所需命令是否存在
function check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${C_RED}错误: 命令 '$1' 未找到。请安装它以支持此格式的解压。${C_RESET}"
        return 1
    fi
    return 0
}

# --- 参数解析 ---
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output)
            OUTPUT_DIR="$2"; shift 2;;
        -h|--help)
            show_usage; exit 0;;
        -*)
            echo -e "${C_RED}错误: 未知选项: $1${C_RESET}" >&2; show_usage; exit 1;;
        *)
            ARCHIVE_FILES+=("$1"); shift;;
    esac
done

# --- 输入校验 ---
if [ ${#ARCHIVE_FILES[@]} -eq 0 ]; then
    echo -e "${C_RED}错误: 请至少提供一个要解压的归档文件。${C_RESET}" >&2; show_usage; exit 1;
fi

if [ -n "$OUTPUT_DIR" ] && [ ! -d "$OUTPUT_DIR" ]; then
    echo -e "${C_YELLOW}输出目录 '$OUTPUT_DIR' 不存在，正在创建...${C_RESET}"
    mkdir -p "$OUTPUT_DIR"
fi

# --- 主逻辑 ---
for file in "${ARCHIVE_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo -e "${C_RED}警告: 文件 '$file' 不存在，已跳过。${C_RESET}"
        continue
    fi

    echo -e "${C_CYAN}--- 正在解压: $file ---${C_RESET}"
    
    # 根据文件扩展名选择解压命令
    case "$file" in
        *.tar.gz|*.tgz)
            check_command tar && tar xvzf "$file" ${OUTPUT_DIR:+-C "$OUTPUT_DIR"} ;;
        *.tar.bz2|*.tbz|*.tbz2)
            check_command tar && tar xvjf "$file" ${OUTPUT_DIR:+-C "$OUTPUT_DIR"} ;;
        *.tar.xz|*.txz)
            check_command tar && tar xvJf "$file" ${OUTPUT_DIR:+-C "$OUTPUT_DIR"} ;;
        *.tar)
            check_command tar && tar xvf "$file" ${OUTPUT_DIR:+-C "$OUTPUT_DIR"} ;;
        *.zip)
            check_command unzip && unzip -o "$file" ${OUTPUT_DIR:+-d "$OUTPUT_DIR"} ;;
        *.rar)
            check_command unrar && unrar x -o+ "$file" ${OUTPUT_DIR:+"$OUTPUT_DIR/"} ;;
        *.7z)
            check_command 7z && 7z x "$file" ${OUTPUT_DIR:+-o"$OUTPUT_DIR"} -y ;;
        *)
            echo -e "${C_RED}错误: 无法识别的文件类型 '$file'。${C_RESET}"
            continue ;;
    esac
    
    # 检查上一个命令的退出状态
    if [ $? -eq 0 ]; then
        echo -e "${C_GREEN}成功解压 '$file'${OUTPUT_DIR:+ 到 '$OUTPUT_DIR'}${C_RESET}\n"
    else
        echo -e "${C_RED}解压 '$file' 时发生错误。${C_RESET}\n"
    fi
done

echo -e "${C_BOLD}${C_GREEN}所有操作完成。${C_RESET}"
