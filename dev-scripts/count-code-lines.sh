#!/bin/bash
# count-code-lines.sh
#
# 一个用于统计指定目录中各类源代码文件行数的脚本，并提供分类汇总报告。

# --- 配置 ---
set -o pipefail

# --- 默认值 ---
# 默认统计常见代码文件类型，可由用户覆盖
INCLUDE_TYPES="sh,py,js,ts,jsx,tsx,html,css,scss,go,rs,java,kt,swift,c,h,cpp,hpp,rb,php,md"
EXCLUDE_DIRS=".git,node_modules,dist,build,target,vendor,*.egg-info"
EXCLUDE_FILES=""

# --- 颜色定义 ---
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_CYAN='\033[0;36m'
C_YELLOW='\033[0;33m'

# --- 函数定义 ---

function show_usage() {
    echo "用法: $0 [目标目录] [选项]"
    echo "统计指定目录中源代码文件的行数，并按类型分类汇总。"
    echo
    echo "参数:"
    echo "  目标目录              要扫描的目录。默认为当前目录。"
    echo
    echo "选项:"
    echo "  --types <exts>        要包含的文件扩展名列表，以逗号分隔 (例如 'sh,py,md')。"
    echo "  --exclude-dir <dirs>  要排除的目录列表，以逗号分隔 (例如 '.git,dist')。"
    echo "  --exclude-file <files> 要排除的文件模式列表，以逗号分隔 (例如 '*.min.js')。"
    echo "  -h, --help              显示此帮助信息。"
}

# --- 参数解析 ---
TARGET_DIR="."
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        --types)
            INCLUDE_TYPES="$2"; shift; shift;;
        --exclude-dir)
            EXCLUDE_DIRS="$2"; shift; shift;;
        --exclude-file)
            EXCLUDE_FILES="$2"; shift; shift;;
        -h|--help)
            show_usage; exit 0;; 
        -*) 
            echo "错误: 未知选项: $1" >&2; show_usage; exit 1;; 
        *)
            POSITIONAL_ARGS+=("$1"); shift;;
    esac
done

# 处理位置参数
if [ ${#POSITIONAL_ARGS[@]} -gt 0 ]; then
    TARGET_DIR="${POSITIONAL_ARGS[0]}"
fi

if [ ! -d "$TARGET_DIR" ]; then echo "错误: 目录 '$TARGET_DIR' 不存在。" >&2; exit 1; fi

# --- 主逻辑 ---

# 1. 构建 find 命令
FIND_CMD=("find" "$TARGET_DIR" "-type" "f")

# 构建包含类型的 find 参数
IFS=',' read -ra types_arr <<< "$INCLUDE_TYPES"
FIND_CMD+=("(")
for i in "${!types_arr[@]}"; do
    if [ $i -gt 0 ]; then FIND_CMD+=("-o"); fi
    FIND_CMD+=("-name" "*.${types_arr[i]}")
done
FIND_CMD+=(")")

# 构建排除目录的 find 参数
IFS=',' read -ra exclude_dirs_arr <<< "$EXCLUDE_DIRS"
for dir in "${exclude_dirs_arr[@]}"; do
    FIND_CMD+=("-not" "-path" "*/$dir/*" "-not" "-path" "*/$dir")
done

# 构建排除文件的 find 参数
IFS=',' read -ra exclude_files_arr <<< "$EXCLUDE_FILES"
for file in "${exclude_files_arr[@]}"; do
    if [ -n "$file" ]; then
        FIND_CMD+=("-not" "-name" "$file")
    fi
done

# 2. 执行统计和格式化
# 使用 awk 进行强大的分类汇总
SUMMARY=$(
    eval "${FIND_CMD[@]} -print0" | xargs -0 --no-run-if-empty wc -l | 
    awk '
    BEGIN {
        printf "%-20s %15s %15s %15s\n", "语言 (类型)", "文件数", "代码行数", "占比";
        printf "%s\n", "---------------------------------------------------------------------";
    }
    # 处理每一行，除了最后一行 total
    /^[[:space:]]*[0-9]+/{ 
        lines = $1;
        # 从文件名提取扩展名作为类型
        n = split($2, path_parts, "/");
        filename = path_parts[n];
        m = split(filename, ext_parts, ".");
        type = (m > 1) ? ext_parts[m] : "(no_ext)";

        lang_lines[type] += lines;
        lang_files[type]++;
        total_lines += lines;
        total_files++;
    }
    END {
        if (total_lines == 0) {
            print "没有找到匹配的文件。";
            exit;
        }
        # 排序并打印每种语言的统计
        PROCINFO["sorted_in"] = "@val_num_desc"; # 需要 gawk 4.0+
        for (type in lang_lines) {
            percentage = (lang_lines[type] / total_lines) * 100;
            printf "%s%-19s %15d %15d %14.2f%%\n", "", type, lang_files[type], lang_lines[type], percentage;
        }
        printf "%s\n", "---------------------------------------------------------------------";
        printf "%s%-19s %15d %15d %14.2f%%\n", "'"$C_BOLD$C_YELLOW'", "总计", total_files, total_lines, 100.00, "'"$C_RESET'";
    }
    '
)

# 3. 显示结果
if [ -n "$SUMMARY" ]; then
    echo -e "$SUMMARY"
else
    echo "在 '$TARGET_DIR' 中没有找到匹配的文件。"
fi
