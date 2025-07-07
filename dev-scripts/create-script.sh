#!/bin/bash
# create-script.sh
#
# 一个用于快速创建带有模板和执行权限的新脚本文件的工具。

# --- 配置 ---
set -e
set -o pipefail

# --- 默认值 ---
TYPE="bash"
EXECUTABLE=true
AUTHOR=$(git config user.name || echo "$USER")

# --- 颜色定义 ---
C_RESET='\033[0m'
C_GREEN='\033[0;32m'
C_CYAN='\033[0;36m'

# --- 函数定义 ---

function show_usage() {
    echo "用法: $0 <脚本路径/文件名> [选项]"
    echo "创建一个新的脚本文件，并可选地赋予执行权限。"
    echo
    echo "选项:"
    echo "  -t, --type <类型>     要创建的脚本类型 (bash, python, node, perl)。默认为 bash。"
    echo "      --no-exec         创建文件但不赋予执行权限。"
    echo "  -h, --help            显示此帮助信息。"
}

# --- 参数解析 ---
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type)
            TYPE="$2"; shift; shift;;
        --no-exec)
            EXECUTABLE=false; shift;;
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
SCRIPT_PATH=$1
if [ -z "$SCRIPT_PATH" ]; then echo "错误: 未提供脚本文件名。" >&2; show_usage; exit 1; fi
if [ -e "$SCRIPT_PATH" ]; then echo "错误: 文件 '$SCRIPT_PATH' 已存在。" >&2; exit 1; fi

# 2. 根据类型选择 Shebang 和模板
SHEBANG=""
TEMPLATE=""
case "$TYPE" in
    bash)
        SHEBANG="#!/usr/bin/env bash"
        TEMPLATE='echo "Hello from Bash!"'
        ;;
    python)
        SHEBANG="#!/usr/bin/env python3"
        TEMPLATE='def main():\n    print("Hello from Python!")\n\nif __name__ == "__main__":\n    main()'
        ;;
    node)
        SHEBANG="#!/usr/bin/env node"
        TEMPLATE='console.log("Hello from Node.js!");'
        ;;
    perl)
        SHEBANG="#!/usr/bin/env perl"
        TEMPLATE='use strict;\nuse warnings;\n\nprint "Hello from Perl!\\n";'
        ;;
    *)
        echo "错误: 不支持的脚本类型 '$TYPE'。" >&2; exit 1;;
esac

# 3. 创建文件和目录
printf "${C_CYAN}正在创建脚本: %s${C_RESET}\n" "$SCRIPT_PATH"

# 确保目录存在
DIR=$(dirname "$SCRIPT_PATH")
mkdir -p "$DIR"

# 写入模板内容
# 使用 printf 是为了正确处理模板中的换行符 \n
printf "%s\n" "$SHEBANG" > "$SCRIPT_PATH"
printf "#\n" >> "$SCRIPT_PATH"
printf "# %s\n" "$(basename "$SCRIPT_PATH")" >> "$SCRIPT_PATH"
printf "#\n" >> "$SCRIPT_PATH"
printf "# 作者: %s\n" "$AUTHOR" >> "$SCRIPT_PATH"
printf "# 日期: %s\n" "$(date +%Y-%m-%d)" >> "$SCRIPT_PATH"
printf "#\n# 描述: 脚本的简要描述。\n#\n\n" >> "$SCRIPT_PATH"
printf "%b\n" "$TEMPLATE" >> "$SCRIPT_PATH"

# 4. 设置权限
if [ "$EXECUTABLE" = true ]; then
    chmod +x "$SCRIPT_PATH"
    printf "${C_GREEN}成功创建脚本 '%s' 并已赋予执行权限。${C_RESET}\n" "$SCRIPT_PATH"
else
    printf "${C_GREEN}成功创建脚本 '%s' (未赋予执行权限)。${C_RESET}\n" "$SCRIPT_PATH"
fi
