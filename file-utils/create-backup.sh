#!/bin/bash
# create-backup.sh
#
# 一个用于创建文件或目录的压缩备份的脚本。

# --- 配置 ---
# 当命令失败时立即退出
set -e
# 如果管道中的任何命令失败，则整个管道失败
set -o pipefail

# --- 默认值 ---
OUTPUT_DIR="."
COMPRESSION_TYPE="gz"

# --- 函数定义 ---

# 显示用法说明
function show_usage() {
    echo "用法: $0 [选项] <目标文件或目录>"
    echo "创建一个指定文件或目录的压缩备份 (.tar.gz, .tar.bz2, 或 .tar.xz)。"
    echo
    echo "选项:"
    echo "  -o, --output-dir <目录>  指定备份文件的输出目录。默认为当前目录。"
    echo "  -t, --type <类型>        指定压缩类型: gz, bz2, xz。默认为 gz。"
    echo "  -h, --help              显示此帮助信息。"
}

# --- 参数解析 ---
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output-dir)
            OUTPUT_DIR="$2"
            shift; shift
            ;;
        -t|--type)
            COMPRESSION_TYPE="$2"
            shift; shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        -*)
            echo "错误: 未知选项: $1" >&2
            show_usage
            exit 1
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done
set -- "${POSITIONAL_ARGS[@]}" # 恢复位置参数

# --- 主逻辑 ---

# 1. 验证输入
TARGET=$1
if [ -z "$TARGET" ]; then
    echo "错误: 未提供要备份的目标。" >&2
    show_usage
    exit 1
fi

if [ ! -e "$TARGET" ]; then
    echo "错误: 目标 '$TARGET' 不存在。" >&2
    exit 1
fi

# 2. 设置压缩参数
case "$COMPRESSION_TYPE" in
    gz)  TAR_OPTS="z"; EXTENSION="tar.gz";; 
    bz2) TAR_OPTS="j"; EXTENSION="tar.bz2";; 
    xz)  TAR_OPTS="J"; EXTENSION="tar.xz";; 
    *) echo "错误: 不支持的压缩类型 '$COMPRESSION_TYPE'。" >&2; exit 1;;
esac

# 3. 准备输出路径
mkdir -p "$OUTPUT_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
# 清理目标名称以用于文件名
CLEAN_TARGET_NAME=$(basename "$TARGET")
BACKUP_FILENAME="backup_${CLEAN_TARGET_NAME}_${TIMESTAMP}.${EXTENSION}"
BACKUP_FULL_PATH="$(realpath "$OUTPUT_DIR")/$BACKUP_FILENAME"

# 获取目标的父目录和基本名称，以避免在 tar 包中存储绝对路径
TARGET_PARENT_DIR=$(dirname "$TARGET")
TARGET_BASENAME=$(basename "$TARGET")

echo "准备备份..."
echo "  - 目标: $(realpath "$TARGET")"
echo "  - 输出: $BACKUP_FULL_PATH"
echo "  - 类型: $COMPRESSION_TYPE"

# 4. 执行备份
echo "正在创建压缩包..."
# 使用 -C 选项切换到父目录进行打包，这是最佳实践
tar -C "$TARGET_PARENT_DIR" -czf "$BACKUP_FULL_PATH" "$TARGET_BASENAME"

echo "备份成功创建！"
