#!/bin/bash
# find-hot-files.sh (Unix/Linux/macOS - Bash)

# --- 用户可配置参数 ---
# 要分析的最新提交数量
COMMIT_LIMIT=${1:-500} # 允许从命令行传入第一个参数作为数量，否则默认为500

# --- 函数定义 ---

# 检查是否在 git 仓库中
check_git_repo() {
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo "错误: 当前目录不是一个 Git 仓库。"
        exit 1
    fi
}

# --- 主逻辑 ---

check_git_repo

echo "--- 热点文件分析 (最近 $COMMIT_LIMIT 次提交) ---"
echo "正在分析，请稍候..."

# --- 1. 获取文件修改历史并统计排序 ---
HOT_FILES=$(git log --pretty=format: --name-only -n "$COMMIT_LIMIT" --no-merges | \
    sed '/^$/d' | \
    sort | \
    uniq -c | \
    sort -rn | \
    head -n 10)

# --- 2. 显示结果 ---
if [ -z "$HOT_FILES" ]; then
    echo -e "\n在指定的提交范围内未找到任何文件修改记录。"
    exit 0
fi

echo -e "\n[+] 修改最频繁的 Top 10 文件:"

# 使用 awk 进行格式化输出
echo "$HOT_FILES" | awk '{
    count = $1;
    $1 = "";
    # 移除前导空格
    gsub(/^[ ]+/, "", $0);
    printf "  - %-50s : %s 次修改\n", $0, count;
}'

echo -e "\n--- 分析完毕 ---"
