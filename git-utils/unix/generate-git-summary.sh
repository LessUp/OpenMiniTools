#!/bin/bash
# generate-git-summary.sh
#
# 生成一个关于 Git 仓库在指定时间段内活动情况的摘要报告。

# --- 配置 ---
set -e
set -o pipefail

# --- 默认值 ---
SINCE="30.days.ago"
UNTIL="now"
TOP_FILES=10
REPO_PATH="."

# --- 颜色定义 ---
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_CYAN='\033[0;36m'
C_YELLOW='\033[0;33m'
C_GREEN='\033[0;32m'

# --- 函数定义 ---

function show_usage() {
    echo "用法: $0 [仓库路径] [选项]"
    echo "为指定的 Git 仓库生成一个活动摘要报告。"
    echo
    echo "参数:"
    echo "  仓库路径              目标 Git 仓库的路径。默认为当前目录。"
    echo
    echo "选项:"
    echo "  --since <日期>        统计的起始日期 (例如 '2.weeks.ago', '2023-01-01')。默认为 '30.days.ago'。"
    echo "  --until <日期>        统计的结束日期。默认为 'now'。"
    echo "  --top-files <数量>    显示被修改最多次的文件数量。默认为 10。"
    echo "  -h, --help            显示此帮助信息。"
}

# --- 参数解析 ---
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        --since)
            SINCE="$2"; shift; shift;;
        --until)
            UNTIL="$2"; shift; shift;;
        --top-files)
            TOP_FILES="$2"; shift; shift;;
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
    REPO_PATH="${POSITIONAL_ARGS[0]}"
fi

# --- 主逻辑 ---

# 1. 验证环境
if ! command -v git &> /dev/null; then echo "错误: 'git' 命令未找到。" >&2; exit 1; fi
if [ ! -d "$REPO_PATH" ]; then echo "错误: 目录 '$REPO_PATH' 不存在。" >&2; exit 1; fi

cd "$REPO_PATH"
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "错误: '$REPO_PATH' 不是一个有效的 Git 仓库。" >&2
    exit 1
fi

# 2. 生成报告
printf "${C_BOLD}${C_CYAN}Git 仓库活动摘要: %s${C_RESET}\n" "$(pwd)"
printf "${C_CYAN}时间范围: %s -> %s${C_RESET}\n" "$SINCE" "$UNTIL"

# --- 贡献者统计 ---
printf "\n${C_YELLOW}--- 贡献者统计 ---${C_RESET}\n"
CONTRIBUTORS=$(git shortlog -sn --since="$SINCE" --until="$UNTIL")
if [ -z "$CONTRIBUTORS" ]; then
    echo "在此期间内没有贡献者。"
else
    echo "$CONTRIBUTORS"
fi

# --- 提交统计 ---
printf "\n${C_YELLOW}--- 提交统计 ---${C_RESET}\n"
STATS=$(git log --shortstat --since="$SINCE" --until="$UNTIL" | grep "files changed" | awk '{
    files += $1;
    inserted += $4;
    deleted += $6
} END {
    print files " " inserted " " deleted
}')

TOTAL_COMMITS=$(git rev-list --count --since="$SINCE" --until="$UNTIL" HEAD)

files_changed=$(echo "$STATS" | awk '{print $1}')
insertions=$(echo "$STATS" | awk '{print $2}')
deletions=$(echo "$STATS" | awk '{print $3}')

printf "总提交数: %s\n" "${C_GREEN}${TOTAL_COMMITS:-0}${C_RESET}"
printf "变更的文件数: %s\n" "${C_GREEN}${files_changed:-0}${C_RESET}"
printf "插入的总行数: %s\n" "${C_GREEN}${insertions:-0}${C_RESET}"
printf "删除的总行数: %s\n" "${C_GREEN}${deletions:-0}${C_RESET}"

# --- 热门文件 ---
printf "\n${C_YELLOW}--- Top %d 个被修改最多次的文件 ---${C_RESET}\n" "$TOP_FILES"
HOT_FILES=$(git log --pretty=format: --name-only --since="$SINCE" --until="$UNTIL" | grep -v '^$' | sort | uniq -c | sort -rn | head -n "$TOP_FILES")

if [ -z "$HOT_FILES" ]; then
    echo "在此期间内没有文件被修改。"
else
    printf "${C_BOLD}%-10s %s${C_RESET}\n" "修改次数" "文件路径"
    echo "$HOT_FILES" | awk '{printf "%-10d %s\n", $1, $2}'
fi

printf "\n${C_CYAN}--- 报告结束 ---${C_RESET}\n"
