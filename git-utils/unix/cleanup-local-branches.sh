#!/bin/bash
# cleanup-local-branches.sh
#
# 一个用于清理已合并的本地 Git 分支的 Bash 脚本。

# --- 配置 ---
# 当命令失败时立即退出
set -e
# 如果管道中的任何命令失败，则整个管道失败
set -o pipefail

# --- 默认值 ---
BASE_BRANCH=""
FORCE_DELETE=false

# --- 函数定义 ---

# 显示用法说明
function show_usage() {
    echo "用法: $0 [-b <base_branch>] [-f] [-h]"
    echo "安全地清理已合并到主分支的本地 Git 分支。"
    echo
    echo "选项:"
    echo "  -b, --base-branch <branch>  指定用于比较的主分支。如果未提供，将自动查找 'main' 或 'master'。"
    echo "  -f, --force                   强制删除，跳过交互式确认。请谨慎使用。"
    echo "  -h, --help                    显示此帮助信息。"
}

# 检查当前是否在 git 仓库中
function check_git_repo() {
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo "错误: 当前目录不是一个 Git 仓库。" >&2
        exit 1
    fi
}

# 确定要使用的主分支
function get_main_branch() {
    # 如果用户通过参数指定了分支，则优先使用
    if [ -n "$BASE_BRANCH" ]; then
        # 验证指定的分支是否存在于本地
        if git show-ref --verify --quiet "refs/heads/$BASE_BRANCH"; then
            echo "$BASE_BRANCH"
            return
        else
            echo "错误: 指定的主分支 '$BASE_BRANCH' 在本地不存在。" >&2
            exit 1
        fi
    fi

    # 自动检测 'main' 或 'master'
    if git show-ref --verify --quiet refs/heads/main; then
        echo "main"
    elif git show-ref --verify --quiet refs/heads/master; then
        echo "master"
    else
        echo "错误: 未找到 'main' 或 'master' 分支，请使用 -b 参数指定一个。" >&2
        exit 1
    fi
}

# --- 参数解析 ---
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -b|--base-branch)
            BASE_BRANCH="$2"
            shift # 越过参数名
            shift # 越过参数值
            ;;
        -f|--force)
            FORCE_DELETE=true
            shift # 越过参数名
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "错误: 未知选项: $1" >&2
            show_usage
            exit 1
            ;;
    esac
done

# --- 主逻辑 ---

check_git_repo

# 1. 确定主分支
main_branch_to_use=$(get_main_branch)
printf "将使用 '%s' 作为主分支进行比较。\n" "$main_branch_to_use"

# 2. 查找已合并的本地分支
current_branch=$(git rev-parse --abbrev-ref HEAD)
branches_to_delete=()

# 使用 while read 循环处理分支列表，比复杂的 sed/grep 管道更安全可靠
# tr -d ' *' 用于删除 git branch 命令输出中当前分支前的 '*' 和多余的空格
git branch --merged "$main_branch_to_use" | tr -d ' *' | grep -vE "^(${main_branch_to_use}|${current_branch})$" | while read -r branch; do
    # 避免将空行添加到数组中
    if [ -n "$branch" ]; then
        branches_to_delete+=("$branch")
    fi
done

# 3. 显示、确认并执行删除
if [ ${#branches_to_delete[@]} -eq 0 ]; then
    echo
    echo "没有检测到可以安全删除的分支。仓库很干净！"
    exit 0
fi

echo
printf "以下 %s 个分支已完全合并，可以安全删除:\n" "${#branches_to_delete[@]}"
printf '  - %s\n' "${branches_to_delete[@]}"

if [ "$FORCE_DELETE" = true ]; then
    echo
    echo "检测到 --force 参数，将直接删除..."
else
    echo
    read -p "您确定要删除这些分支吗? (y/n) " -n 1 -r
    echo # 移动到新行
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo
        echo "操作已取消。"
        exit 0
    fi
fi

echo
echo "正在删除分支..."
# 使用 printf 和 xargs 安全地删除分支，即使分支名包含特殊字符
printf '%s\n' "${branches_to_delete[@]}" | xargs -n 1 git branch -d

echo
echo "清理完毕！"
