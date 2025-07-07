#!/bin/bash
# update-system.sh
#
# 一个用于安全、智能地更新 Linux 系统的脚本，能自动检测包管理器。

# --- 配置 ---
set -e
set -o pipefail

# --- 默认值 ---
CHECK_ONLY=false
AUTO_CLEAN=false
ASSUME_YES=false

# --- 颜色定义 ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_CYAN='\033[0;36m'

# --- 函数定义 ---

function show_usage() {
    echo "用法: $0 [选项]"
    echo "安全、智能地更新系统。自动检测包管理器。"
    echo
    echo "选项:"
    echo "  --check           只检查可用的更新，不执行安装。"
    echo "  --clean           更新后自动清理无用的依赖包。"
    echo "  -y, --yes         自动对所有提示回答 '是'，以非交互模式运行。"
    echo "  -h, --help        显示此帮助信息。"
}

# --- 参数解析 ---
while [[ $# -gt 0 ]]; do
    case $1 in
        --check)
            CHECK_ONLY=true; shift;;
        --clean)
            AUTO_CLEAN=true; shift;;
        -y|--yes)
            ASSUME_YES=true; shift;;
        -h|--help)
            show_usage; exit 0;; 
        -*) 
            echo "错误: 未知选项: $1" >&2; show_usage; exit 1;; 
    esac
done

# --- 主逻辑 ---

# 1. 检测包管理器
PKG_MANAGER=""
UPDATE_CMD=""
UPGRADE_CMD=""
CHECK_CMD=""
CLEAN_CMD=""
YES_FLAG=""

if command -v apt &>/dev/null; then
    PKG_MANAGER="apt"
    UPDATE_CMD="sudo apt update"
    UPGRADE_CMD="sudo apt upgrade"
    CHECK_CMD="apt list --upgradable"
    CLEAN_CMD="sudo apt autoremove --purge"
    YES_FLAG="-y"
elif command -v dnf &>/dev/null; then
    PKG_MANAGER="dnf"
    UPDATE_CMD="sudo dnf check-update"
    UPGRADE_CMD="sudo dnf upgrade"
    CHECK_CMD="dnf check-update"
    CLEAN_CMD="sudo dnf autoremove"
    YES_FLAG="-y"
elif command -v yum &>/dev/null; then
    PKG_MANAGER="yum"
    UPDATE_CMD="sudo yum check-update"
    UPGRADE_CMD="sudo yum update"
    CHECK_CMD="yum check-update"
    CLEAN_CMD="sudo yum autoremove"
    YES_FLAG="-y"
elif command -v pacman &>/dev/null; then
    PKG_MANAGER="pacman"
    UPDATE_CMD="sudo pacman -Sy"
    UPGRADE_CMD="sudo pacman -Su"
    CHECK_CMD="pacman -Qu"
    CLEAN_CMD="# Pacman 没有标准的 autoremove，可使用 'paccache -r' (from pacman-contrib)"
    YES_FLAG="--noconfirm"
elif command -v zypper &>/dev/null; then
    PKG_MANAGER="zypper"
    UPDATE_CMD="sudo zypper ref"
    UPGRADE_CMD="sudo zypper dup"
    CHECK_CMD="zypper lu"
    CLEAN_CMD="# Zypper 没有标准的 autoremove"
    YES_FLAG="--non-interactive"
else
    echo -e "${C_RED}错误: 未能检测到已知的包管理器 (apt, dnf, yum, pacman, zypper)。${C_RESET}" >&2
    exit 1
fi

printf "${C_CYAN}--- 系统更新工具 ---${C_RESET}\n"
printf "检测到包管理器: ${C_YELLOW}%s${C_RESET}\n" "$PKG_MANAGER"

# 2. 执行检查模式
if [ "$CHECK_ONLY" = true ]; then
    printf "\n${C_CYAN}正在检查可用的更新...${C_RESET}\n"
    $CHECK_CMD
    exit 0
fi

# 3. 确认并执行更新
if [ "$ASSUME_YES" = false ]; then
    read -p "是否要继续更新系统? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "操作已取消。"
        exit 0
    fi
fi

if [ "$ASSUME_YES" = true ]; then
    UPGRADE_CMD+=" $YES_FLAG"
fi

printf "\n${C_CYAN}第一步: 正在更新软件包列表...${C_RESET}\n"
$UPDATE_CMD

printf "\n${C_CYAN}第二步: 正在升级已安装的软件包...${C_RESET}\n"
$UPGRADE_CMD

# 4. 执行清理
if [ "$AUTO_CLEAN" = true ]; then
    if [[ -n "$CLEAN_CMD" && ! "$CLEAN_CMD" =~ ^# ]]; then
        printf "\n${C_CYAN}第三步: 正在清理无用的软件包...${C_RESET}\n"
        if [ "$ASSUME_YES" = true ]; then
            CLEAN_CMD+=" $YES_FLAG"
        fi
        $CLEAN_CMD
    else
        printf "\n${C_YELLOW}注意: 包管理器 '%s' 没有标准的自动清理命令，已跳过清理。${C_RESET}\n" "$PKG_MANAGER"
    fi
fi

printf "\n${C_GREEN}系统更新完成。${C_RESET}\n"
