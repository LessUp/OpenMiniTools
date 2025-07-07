#!/bin/bash
# find-duplicate-files.sh
#
# 一个用于根据文件内容 (哈希值) 查找并选择性删除重复文件的脚本。

# --- 配置 ---
set -e
set -o pipefail

# --- 默认值 ---
ALGO="md5"
DELETE=false
FORCE=false
DRY_RUN=true # 默认开启演练模式，除非指定 --force
OUTPUT_FILE=""

# --- 颜色定义 ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_YELLOW='\033[0;33m'
C_CYAN='\033[0;36m'
C_BOLD='\033[1m'

# --- 函数定义 ---

function show_usage() {
    echo "用法: $0 <目标目录> [选项]"
    echo "根据文件内容的哈希值查找重复文件。"
    echo
    echo "选项:"
    echo "  --algo <md5|sha256>   使用的哈希算法。默认为 md5。"
    echo "  -o, --output <文件>     将重复文件列表报告输出到指定文件。"
    echo "  --delete                启用删除模式。默认只报告不删除。"
    echo "  --force                 与 --delete 配合使用，实际执行删除操作。否则 --delete 只会进行演练。"
    echo "  -h, --help              显示此帮助信息。"
}

# --- 参数解析 ---
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        --algo)
            ALGO="$2"; shift; shift;;
        -o|--output)
            OUTPUT_FILE="$2"; shift; shift;;
        --delete)
            DELETE=true; shift;;
        --force)
            FORCE=true; shift;;
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
TARGET_DIR=$1
if [ -z "$TARGET_DIR" ]; then echo "错误: 未提供目标目录。" >&2; show_usage; exit 1; fi
if [ ! -d "$TARGET_DIR" ]; then echo "错误: 目录 '$TARGET_DIR' 不存在。" >&2; exit 1; fi

HASH_CMD="${ALGO}sum"
if ! command -v "$HASH_CMD" &> /dev/null; then
    echo "${C_RED}错误: 命令 '$HASH_CMD' 未找到。请安装它。${C_RESET}" >&2; exit 1;
fi

# 安全检查：如果指定了 --delete 但未指定 --force，则保持 dry_run=true
if [ "$DELETE" = true ] && [ "$FORCE" = false ]; then
    DRY_RUN=true
    echo "${C_YELLOW}警告: --delete 已指定但未提供 --force。将以演练模式运行。${C_RESET}"
fi
if [ "$DELETE" = true ] && [ "$FORCE" = true ]; then
    DRY_RUN=false
fi

# 2. 查找并计算哈希值
printf "${C_CYAN}正在扫描目录 '%s' 并计算 %s 哈希值... (这可能需要一些时间)${C_RESET}\n" "$TARGET_DIR" "$ALGO"

# 创建临时文件来存储结果
TMP_FILE=$(mktemp)
trap 'rm -f -- "$TMP_FILE"' EXIT

# 核心逻辑：查找文件 -> 计算哈希 -> 排序 -> 找出重复项
find "$TARGET_DIR" -type f -exec "$HASH_CMD" {} + | sort > "$TMP_FILE"

DUPLICATES=$(uniq -w32 --all-repeated=separate "$TMP_FILE")

if [ -z "$DUPLICATES" ]; then
    echo "${C_GREEN}太棒了！没有找到任何重复文件。${C_RESET}"
    exit 0
fi

# 3. 处理结果
if [ "$DELETE" = false ]; then
    # 只报告
    REPORT=$(echo "$DUPLICATES" | awk '
        BEGIN { print "发现以下重复文件组:\n" }
        NF == 0 { print "----------------------------------------\n"; next }
        { print "  " $2 " (哈希: " $1 ")" }
    ')
    echo -e "$REPORT"
    if [ -n "$OUTPUT_FILE" ]; then
        echo -e "$REPORT" > "$OUTPUT_FILE"
        printf "\n${C_GREEN}报告已保存到: %s${C_RESET}\n" "$OUTPUT_FILE"
    fi
else
    # 删除模式
    printf "\n${C_RED}${C_BOLD}--- 删除模式已激活 ---${C_RESET}\n"
    if [ "$DRY_RUN" = false ]; then
        read -p "此操作将永久删除文件。你确定要继续吗? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "操作已取消。"
            exit 1
        fi
    fi

    echo "$DUPLICATES" | awk -v dry_run="$DRY_RUN" '
    BEGIN { group_count=0 }
    # 处理每个重复文件组
    NF > 0 {
        files[group_count, ++file_idx[group_count]] = $0
    }
    # 空行表示一个组的结束
    NF == 0 {
        if (file_idx[group_count] > 1) { # 确保是重复组
            # 保留第一个文件
            split(files[group_count, 1], parts, " ");
            printf "\n组 %d: 保留 \"%s\"\n", group_count+1, parts[2];
            # 删除其余文件
            for (i=2; i<=file_idx[group_count]; i++) {
                split(files[group_count, i], del_parts, " ");
                file_to_delete = del_parts[2];
                for (j=3; j<=length(del_parts); j++) file_to_delete = file_to_delete " " del_parts[j];
                if (dry_run) {
                    printf "  [演练] 将会删除 \"%s\"\n", file_to_delete;
                } else {
                    printf "  正在删除 \"%s\"...\n", file_to_delete;
                    # 构建并执行删除命令
                    cmd = "rm -v \"" file_to_delete "\""
                    system(cmd)
                }
            }
        }
        group_count++;
        delete file_idx[group_count-1];
    }'
    printf "\n${C_GREEN}重复文件清理完成。${C_RESET}\n"
fi
