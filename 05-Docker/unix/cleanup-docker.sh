#!/bin/bash
# cleanup-docker.sh
#
# 一个用于清理未使用 Docker 资源的模块化脚本，例如停止的容器、悬空镜像、未使用的卷和网络。

# --- 配置 ---
set -e
set -o pipefail

# --- 默认值 ---
CLEAN_CONTAINERS=false
CLEAN_IMAGES=false
CLEAN_VOLUMES=false
CLEAN_NETWORKS=false
CLEAN_ALL=false
FORCE=false

# --- 颜色定义 ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_YELLOW='\033[0;33m'
C_CYAN='\033[0;36m'

# --- 函数定义 ---

function show_usage() {
    echo "用法: $0 [选项]"
    echo "清理未使用的 Docker 资源。"
    echo
    echo "选项:"
    echo "  --containers          清理所有已停止的容器。"
    echo "  --images              清理所有悬空 (dangling) 的镜像。"
    echo "  --volumes             清理所有未使用的卷。"
    echo "  --networks            清理所有未使用的网络。"
    echo "  --all                 执行 'docker system prune'，清理所有未使用的资源。"
    echo "  -f, --force           无需确认，直接执行清理。"
    echo "  -h, --help            显示此帮助信息。"
    echo
    echo "如果没有提供任何选项，将不会执行任何操作。"
}

# --- 参数解析 ---
while [[ $# -gt 0 ]]; do
    case $1 in
        --containers) CLEAN_CONTAINERS=true; shift;; 
        --images) CLEAN_IMAGES=true; shift;; 
        --volumes) CLEAN_VOLUMES=true; shift;; 
        --networks) CLEAN_NETWORKS=true; shift;; 
        --all) CLEAN_ALL=true; shift;; 
        -f|--force) FORCE=true; shift;; 
        -h|--help) show_usage; exit 0;; 
        -*) echo "错误: 未知选项: $1" >&2; show_usage; exit 1;; 
        *) shift;;
    esac
done

# --- 主逻辑 ---

# 1. 验证依赖
if ! command -v docker &> /dev/null; then
    echo "${C_RED}错误: 'docker' 命令未找到。请确保 Docker 已安装并正在运行。${C_RESET}" >&2
    exit 1
fi

# 如果没有选择任何操作，则显示帮助并退出
if [ "$CLEAN_CONTAINERS" = false ] && [ "$CLEAN_IMAGES" = false ] && [ "$CLEAN_VOLUMES" = false ] && [ "$CLEAN_NETWORKS" = false ] && [ "$CLEAN_ALL" = false ]; then
    echo "${C_YELLOW}未指定任何清理操作。${C_RESET}"
    show_usage
    exit 0
fi

# 2. 显示将要执行的操作
printf "${C_CYAN}--- Docker 清理计划 ---${C_RESET}\n"
if [ "$CLEAN_ALL" = true ]; then
    echo "- 将执行 'docker system prune' (清理所有未使用的容器、镜像、网络和构建缓存)。"
else
    if [ "$CLEAN_CONTAINERS" = true ]; then echo "- 清理已停止的容器。"; fi
    if [ "$CLEAN_IMAGES" = true ]; then echo "- 清理悬空的镜像。"; fi
    if [ "$CLEAN_VOLUMES" = true ]; then echo "- 清理未使用的卷。"; fi
    if [ "$CLEAN_NETWORKS" = true ]; then echo "- 清理未使用的网络。"; fi
fi
echo

# 3. 请求确认
if [ "$FORCE" = false ]; then
    read -p "你确定要继续吗? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "操作已取消。"
        exit 1
    fi
fi

# 4. 执行清理
printf "\n${C_CYAN}--- 开始执行清理 ---${C_RESET}\n"

if [ "$CLEAN_ALL" = true ]; then
    docker system prune -f
else
    if [ "$CLEAN_CONTAINERS" = true ]; then
        echo "正在清理容器..."
        docker container prune -f
    fi
    if [ "$CLEAN_IMAGES" = true ]; then
        echo "正在清理镜像..."
        docker image prune -f
    fi
    if [ "$CLEAN_VOLUMES" = true ]; then
        echo "正在清理卷..."
        docker volume prune -f
    fi
    if [ "$CLEAN_NETWORKS" = true ]; then
        echo "正在清理网络..."
        docker network prune -f
    fi
fi

printf "\n${C_CYAN}Docker 清理完成。${C_RESET}\n"
