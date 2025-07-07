#!/bin/bash
# extract-csv-column.sh
#
# 一个强大的 CSV/TSV 列提取工具，支持按列号或列名提取，并能从文件或管道读取。

# --- 配置 ---
set -e
set -o pipefail

# --- 默认值 ---
COLUMNS_STR=""
DELIMITER=","
NO_HEADER=false
INPUT_FILE=""

# --- 函数定义 ---

function show_usage() {
    echo "用法: $0 -c <列> [选项] [输入文件]"
    echo "从 CSV 文件或标准输入中提取指定的列。"
    echo
    echo "参数:"
    echo "  -c, --columns <列>      要提取的列，以逗号分隔。可以是列号 (例如 '1,3') 或列名 (例如 'UserName,Email')。"
    echo
    echo "选项:"
    echo "  -d, --delimiter <分隔符>  字段分隔符。默认为逗号 ','。"
    echo "      --no-header           文件没有标题行。当按列名提取时，此选项无效。"
    echo "  -f, --file <文件路径>     输入文件。如果未提供，则从标准输入读取。"
    echo "  -h, --help                显示此帮助信息。"
}

# --- 参数解析 ---
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--columns)
            COLUMNS_STR="$2"; shift 2;;
        -d|--delimiter)
            DELIMITER="$2"; shift 2;;
        --no-header)
            NO_HEADER=true; shift;;
        -f|--file)
            INPUT_FILE="$2"; shift 2;;
        -h|--help)
            show_usage; exit 0;;
        -*)
            echo "错误: 未知选项: $1" >&2; show_usage; exit 1;;
        *)
            if [ -z "$INPUT_FILE" ]; then INPUT_FILE="$1"; fi; shift;;
    esac
done

# --- 输入校验 ---
if [ -z "$COLUMNS_STR" ]; then
    echo "错误: 必须使用 -c 选项指定要提取的列。" >&2; show_usage; exit 1;
fi
if [ -n "$INPUT_FILE" ] && [ ! -f "$INPUT_FILE" ]; then
    echo "错误: 输入文件 '$INPUT_FILE' 不存在。" >&2; exit 1;
fi

# --- 主逻辑 (AWK) ---

# 判断是按列名还是按列号提取
IS_NUMERIC=true
if ! [[ $(echo "$COLUMNS_STR" | tr ',' ' ') =~ ^[0-9\ ]+$ ]]; then
    IS_NUMERIC=false
fi

# 如果按列名提取，但又指定了 no-header，则报错
if [ "$IS_NUMERIC" = false ] && [ "$NO_HEADER" = true ]; then
    echo "错误: 不能在指定 '--no-header' 的同时按列名提取。" >&2; exit 1;
fi

# 使用 awk 执行所有核心逻辑
# -v 传递 bash 变量给 awk
awk -v cols="$COLUMNS_STR" \
    -v del="$DELIMITER" \
    -v is_numeric="$IS_NUMERIC" \
    -v no_header="$NO_HEADER" '
BEGIN {
    FS = del;
    # 将列字符串分割成数组
    split(cols, wanted_cols, ",");
}

# NR==1: 只在处理第一行时执行
NR == 1 {
    if (is_numeric) {
        # 按列号提取: 直接使用列号
        for (i in wanted_cols) {
            col_indices[i] = wanted_cols[i];
        }
    } else {
        # 按列名提取: 查找列名对应的索引
        for (i=1; i<=NF; i++) {
            header[$i] = i;
        }
        for (i in wanted_cols) {
            col_name = wanted_cols[i];
            if (header[col_name]) {
                col_indices[i] = header[col_name];
            } else {
                print "错误: 在标题行中未找到列名 '" col_name "'" > "/dev/stderr";
                exit 1;
            }
        }
    }
    
    # 如果没有 no-header 标志，打印标题行
    if (!no_header) {
        for (i=1; i<=length(col_indices); i++) {
            printf "%s%s", $(col_indices[i]), (i==length(col_indices) ? "" : FS);
        }
        printf "\n";
    }
}

# NR > 1: 处理第一行之后的所有行
# 或者，如果指定了 no-header，则处理所有行
NR > 1 || no_header {
    for (i=1; i<=length(col_indices); i++) {
        printf "%s%s", $(col_indices[i]), (i==length(col_indices) ? "" : FS);
    }
    printf "\n";
}
' "${INPUT_FILE:-/dev/stdin}" # 如果 INPUT_FILE 为空，则从 stdin 读取

