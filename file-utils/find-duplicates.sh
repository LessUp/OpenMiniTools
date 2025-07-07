#!/bin/bash
# find-duplicates.sh
#
# 一个高效查找并交互式删除重复文件的工具。
# 首先按文件大小筛选，然后按 MD5 哈希比较，以提高效率。

# --- 配置 ---
set -o pipefail

# --- 默认值 ---
SEARCH_DIRS=()
MIN_SIZE="1c" # 默认为 1 字节，即不限制
INTERACTIVE_DELETE=false
DRY_RUN=false

# --- 颜色定义 ---
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_CYAN='\033[0;36m'

# --- 函数定义 ---

function show_usage() {
    echo "用法: $0 [目录...] [选项]"
    echo "高效地查找并可选择地删除指定目录中的重复文件。"
    echo
    echo "选项:"
    echo "  -s, --min-size <大小>   要考虑的最小文件大小 (例如 '1k', '10M', '1G')。"
    echo "  -d, --delete              查找后进入交互式删除模式。"
    echo "      --dry-run             与 --delete 配合使用，仅显示将要删除的文件。"
    echo "  -h, --help                显示此帮助信息。"
}

# --- 参数解析 ---
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--min-size)
            MIN_SIZE="$2"; shift 2;;
        -d|--delete)
            INTERACTIVE_DELETE=true; shift;;
        --dry-run)
            DRY_RUN=true; shift;;
        -h|--help)
            show_usage; exit 0;;
        -*)
            echo -e "${C_RED}错误: 未知选项: $1${C_RESET}" >&2; show_usage; exit 1;;
        *)
            SEARCH_DIRS+=("$1"); shift;;
    esac
done

# --- 输入校验 ---
if [ ${#SEARCH_DIRS[@]} -eq 0 ]; then SEARCH_DIRS+=("."); fi
for dir in "${SEARCH_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        echo -e "${C_RED}错误: 目录 '$dir' 不存在。${C_RESET}" >&2; exit 1;
    fi
done
if ! command -v md5sum &> /dev/null; then
    echo -e "${C_RED}错误: 'md5sum' 命令未找到。${C_RESET}" >&2; exit 1;
fi

# --- 主逻辑 ---

printf "${C_CYAN}--- 查找重复文件 ---${C_RESET}\n"
printf "${C_YELLOW}%-15s${C_RESET} %s\n" "搜索目录:" "${SEARCH_DIRS[*]}"
printf "${C_YELLOW}%-15s${C_RESET} %s\n" "最小文件大小:" "$MIN_SIZE"
echo "(这可能需要一些时间...)"

# 核心：首先按大小分组，然后仅对大小相同的文件计算哈希值
DUPLICATES=$(find "${SEARCH_DIRS[@]}" -type f -size +$MIN_SIZE -printf "%s\n" | \
    sort | uniq -d | \
    xargs -I {} find "${SEARCH_DIRS[@]}" -type f -size {}c -print0 | \
    xargs -0 md5sum | sort | uniq -w32 --all-repeated=separate)

if [ -z "$DUPLICATES" ]; then
    echo -e "\n${C_GREEN}没有找到重复文件。${C_RESET}"
    exit 0
fi

TOTAL_SETS=0
TOTAL_RECLAIMABLE_BYTES=0

echo -e "\n${C_BOLD}发现以下重复文件组:${C_RESET}"

# 使用 readarray 和进程替换来逐组处理重复项
while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ -z "$line" ]]; then continue; fi # 跳过空行（分隔符）
    
    # 将一组重复文件读入数组
    readarray -t group < <(echo "$line"; \
        while IFS= read -r next_line && [[ -n "$next_line" ]]; do echo "$next_line"; done)

    ((TOTAL_SETS++))
    
    # 提取文件路径和大小
    files_in_group=()
    for item in "${group[@]}"; do
        # md5sum 输出格式为: <hash>  <filename>
        files_in_group+=("$(echo "$item" | cut -d' ' -f3-)")
    done
    
    file_size_bytes=$(stat -c%s "${files_in_group[0]}")
    file_size_human=$(numfmt --to=iec-i --suffix=B --format="%.2f" $file_size_bytes)
    reclaimable_bytes=$((file_size_bytes * (${#files_in_group[@]} - 1)))
    TOTAL_RECLAIMABLE_BYTES=$((TOTAL_RECLAIMABLE_BYTES + reclaimable_bytes))

    echo -e "\n${C_CYAN}--- 组 $TOTAL_SETS (每个文件大小: $file_size_human) ---${C_RESET}"
    for i in "${!files_in_group[@]}"; do
        echo "  $((i+1))) ${files_in_group[$i]}"
    done

    # --- 交互式删除逻辑 ---
    if [ "$INTERACTIVE_DELETE" = true ]; then
        echo
        read -p "输入要保留的文件编号 (1-${#files_in_group[@]})，或按 Enter 跳过: " choice

        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#files_in_group[@]} ]; then
            for i in "${!files_in_group[@]}"; do
                if [ $((i+1)) -ne "$choice" ]; then
                    if [ "$DRY_RUN" = true ]; then
                        echo -e "  ${C_YELLOW}[演练] 将删除: ${files_in_group[$i]}${C_RESET}"
                    else
                        echo -e "  ${C_RED}正在删除: ${files_in_group[$i]}${C_RESET}"
                        rm "${files_in_group[$i]}"
                    fi
                fi
            done
        else
            echo "已跳过此组。"
        fi
    fi
done <<< "$DUPLICATES"

# --- 总结报告 ---
TOTAL_RECLAIMABLE_HUMAN=$(numfmt --to=iec-i --suffix=B --format="%.2f" $TOTAL_RECLAIMABLE_BYTES)
echo -e "\n${C_BOLD}${C_GREEN}--- 总结 ---${C_RESET}"
echo "共找到 $TOTAL_SETS 组重复文件。"
echo "可释放空间: $TOTAL_RECLAIMABLE_HUMAN"

if [ "$DRY_RUN" = true ] && [ "$INTERACTIVE_DELETE" = true ]; then
    echo -e "${C_YELLOW}当前为演练模式，未删除任何文件。${C_RESET}"
fi
