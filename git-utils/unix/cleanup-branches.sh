#!/bin/bash
# cleanup-branches.sh (Unix/Linux/macOS - Bash)

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

# --- 1. 确定主分支 (main 或 master) ---
if git show-ref --verify --quiet refs/heads/main; then
    MAIN_BRANCH="main"
elif git show-ref --verify --quiet refs/heads/master; then
    MAIN_BRANCH="master"
else
    echo "错误: 未找到 'main' 或 'master' 分支。"
    exit 1
fi
echo "检测到主分支为: $MAIN_BRANCH"

# --- 2. 查找已合并的本地分支 ---
# 获取当前分支名，并去除星号和空格
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# 查找已合并到主分支的分支列表，并过滤掉主分支和当前分支
BRANCHES_TO_DELETE=$(git branch --merged "$MAIN_BRANCH" | sed 's/\*//g' | sed 's/ //g' | grep -vE "^($MAIN_BRANCH|$CURRENT_BRANCH)$" | sed '/^$/d')

# --- 3. 显示并请求确认 ---
if [ -z "$BRANCHES_TO_DELETE" ]; then
    echo -e "\n没有检测到可以安全删除的分支。仓库很干净！"
    exit 0
fi

echo -e "\n以下分支已完全合并到 '$MAIN_BRANCH'，可以安全删除:"
# 将字符串转换为数组以便打印
readarray -t branches_array <<<"$BRANCHES_TO_DELETE"
for branch in "${branches_array[@]}"; do
    echo "  - $branch"
done

read -p "\n您确定要删除这 ${#branches_array[@]} 个分支吗? (y/n) " -n 1 -r
echo # 移动到新行

# --- 4. 执行删除 ---
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "\n正在删除分支..."
    # 使用 xargs 批量删除
    echo "$BRANCHES_TO_DELETE" | xargs -n 1 git branch -d
    echo -e "\n清理完毕！"
else
    echo -e "\n操作已取消。"
fi
