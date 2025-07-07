#!/bin/bash
# generate-password.sh
#
# 一个灵活的密码生成器，支持自定义长度、字符集和数量。

# --- 配置 ---
set -e
set -o pipefail

# --- 默认值 ---
LENGTH=16
COUNT=1
USE_UPPER=true
USE_LOWER=true
USE_NUMBERS=true
USE_SYMBOLS=true

# --- 字符集定义 ---
LOWERCASE_CHARS='a-z'
UPPERCASE_CHARS='A-Z'
NUMBER_CHARS='0-9'
SYMBOL_CHARS='_!@#$%^&*()-=+'

# --- 颜色定义 ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_CYAN='\033[0;36m'

# --- 函数定义 ---

function show_usage() {
    echo "用法: $0 [选项]"
    echo "生成一个或多个安全的随机密码。"
    echo
    echo "选项:"
    echo "  -l, --length <长度>     密码的长度。默认为 16。"
    echo "  -c, --count <数量>      要生成的密码数量。默认为 1。"
    echo "      --no-uppercase      密码中不包含大写字母。"
    echo "      --no-lowercase      密码中不包含小写字母。"
    echo "      --no-numbers        密码中不包含数字。"
    echo "      --no-symbols        密码中不包含特殊符号。"
    echo "  -h, --help              显示此帮助信息。"
}

# --- 参数解析 ---
while [[ $# -gt 0 ]]; do
    case $1 in
        -l|--length)
            LENGTH="$2"; shift; shift;;
        -c|--count)
            COUNT="$2"; shift; shift;;
        --no-uppercase)
            USE_UPPER=false; shift;;
        --no-lowercase)
            USE_LOWER=false; shift;;
        --no-numbers)
            USE_NUMBERS=false; shift;;
        --no-symbols)
            USE_SYMBOLS=false; shift;;
        -h|--help)
            show_usage; exit 0;; 
        -*) 
            echo "错误: 未知选项: $1" >&2; show_usage; exit 1;; 
        *)
            shift;;
    esac
done

# --- 主逻辑 ---

# 1. 验证参数
if ! [[ "$LENGTH" =~ ^[0-9]+$ ]] || [ "$LENGTH" -lt 4 ]; then
    echo "${C_RED}错误: 密码长度必须是大于 3 的数字。${C_RESET}" >&2; exit 1;
fi
if ! [[ "$COUNT" =~ ^[0-9]+$ ]] || [ "$COUNT" -lt 1 ]; then
    echo "${C_RED}错误: 生成数量必须是大于 0 的数字。${C_RESET}" >&2; exit 1;
fi

# 2. 构建字符集
CHAR_SET=""
if [ "$USE_UPPER" = true ]; then CHAR_SET+="$UPPERCASE_CHARS"; fi
if [ "$USE_LOWER" = true ]; then CHAR_SET+="$LOWERCASE_CHARS"; fi
if [ "$USE_NUMBERS" = true ]; then CHAR_SET+="$NUMBER_CHARS"; fi
if [ "$USE_SYMBOLS" = true ]; then CHAR_SET+="$SYMBOL_CHARS"; fi

if [ -z "$CHAR_SET" ]; then
    echo "${C_RED}错误: 所有字符类型都已被禁用，无法生成密码。${C_RESET}" >&2; exit 1;
fi

# 3. 生成密码
printf "${C_CYAN}正在生成 %d 个长度为 %d 的密码...${C_RESET}\n" "$COUNT" "$LENGTH"
for ((i=0; i<COUNT; i++)); do
    LC_ALL=C tr -dc "$CHAR_SET" < /dev/urandom | head -c "$LENGTH"
    echo # 每个密码后换行
done
