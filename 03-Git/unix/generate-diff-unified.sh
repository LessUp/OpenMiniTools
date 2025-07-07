#!/bin/bash
# generate-diff.sh (Unix/Linux/macOS - Bash)

# --- 用户可配置参数 ---
# 指定要包含的目录或文件 (用空格分隔, 例如: "src lib"). 留空则包含所有。
INCLUDE_PATHS=""
# 指定要排除的目录或文件 (用空格分隔, 例如: "*.md" "dist/"). 留空则不排除任何。
EXCLUDE_PATHS=""
# --- 配置结束 ---

# --- 函数定义 ---

# 检查是否在 git 仓库中
function check_git_repo() {
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo "错误：这里不是一个 git 仓库。请在您的 git 项目目录中运行此脚本。"
        exit 1
    fi
}

# --- 主逻辑 ---

check_git_repo

# 获取脚本所在目录并创建 diffs 目录
SCRIPT_DIR=$(dirname "$0")
DIFFS_DIR="$SCRIPT_DIR/../diffs"
if [ ! -d "$DIFFS_DIR" ]; then
    mkdir -p "$DIFFS_DIR"
    echo "已创建目录: $DIFFS_DIR"
fi

# 显示菜单
echo ""
echo "请选择要生成的 diff 类型:"
echo "  a. 工作区中未提交的更改 (git diff HEAD)"
echo "  b. 从指定 commit 到 HEAD 的更改"
echo "  c. 两个指定 commit 之间的更改"
echo "  d. 从指定 commit 到当前工作区 (包含未提交的更改)"
read -p "请输入选项 (a/b/c/d): " choice

# 基础命令已优化
GIT_DIFF_CMD="git diff --unified=10 -w --no-prefix"
GIT_SHOW_CMD="git show --unified=10 -w --no-prefix"
OUTPUT_FILE=""
GIT_FULL_CMD=""

# 构造路径过滤参数
PATHSPEC=""
if [ -n "$INCLUDE_PATHS" ]; then
    PATHSPEC=" -- $INCLUDE_PATHS"
fi
if [ -n "$EXCLUDE_PATHS" ]; then
    if [ -z "$INCLUDE_PATHS" ]; then
        PATHSPEC=" --"
    fi
    for p in $EXCLUDE_PATHS; do
        PATHSPEC="$PATHSPEC ':(exclude)$p'"
    done
fi

case $choice in
    a)
        OUTPUT_FILE="$DIFFS_DIR/diff_workspace_uncommitted.diff"
        GIT_FULL_CMD="$GIT_DIFF_CMD HEAD"
        ;;
    b)
        read -p "请输入起始 commit hash: " startHash
        if [ -z "$startHash" ]; then echo "Hash 不能为空。"; exit 1; fi
        OUTPUT_FILE="$DIFFS_DIR/diff_${startHash}_to_HEAD.diff"
        GIT_FULL_CMD="$GIT_DIFF_CMD ${startHash}..HEAD"
        ;;
    c)
        read -p "请输入起始 commit hash: " startHash
        read -p "请输入结束 commit hash: " endHash
        if [ -z "$startHash" ] || [ -z "$endHash" ]; then echo "Hash 不能为空。"; exit 1; fi
        OUTPUT_FILE="$DIFFS_DIR/diff_${startHash}_${endHash}.diff"
        GIT_FULL_CMD="$GIT_DIFF_CMD ${startHash}..${endHash}"
        ;;
    d)
        read -p "请输入起始 commit hash: " startHash
        if [ -z "$startHash" ]; then echo "Hash 不能为空。"; exit 1; fi
        OUTPUT_FILE="$DIFFS_DIR/diff_${startHash}_to_workspace.diff"
        GIT_FULL_CMD="$GIT_DIFF_CMD $startHash"
        ;;
    *)
        echo "无效的选项 '$choice'。"
        exit 1
        ;;
esac

# 将路径过滤器追加到最终命令
GIT_FULL_CMD="$GIT_FULL_CMD$PATHSPEC"

# 执行生成
echo "正在执行 git 命令: $GIT_FULL_CMD"
eval "$GIT_FULL_CMD" > "$OUTPUT_FILE"

if [ $? -eq 0 ]; then
    if [ -s "$OUTPUT_FILE" ]; then
        echo "成功创建 diff 文件: $OUTPUT_FILE"
    else
        echo "操作成功，但未检测到差异，已生成空文件: $OUTPUT_FILE"
    fi
else
    echo "生成 diff 文件失败。请检查输入是否正确。"
    rm -f "$OUTPUT_FILE"
fi