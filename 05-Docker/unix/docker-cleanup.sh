#!/bin/bash
# docker-cleanup.sh
#
# 一个安全、模块化的 Docker 资源清理工具，支持演练模式和选择性清理。

# --- 配置 ---
set -e
set -o pipefail

# --- 默认值 ---
CLEAN_CONTAINERS=false
CLEAN_IMAGES=false
CLEAN_IMAGES_ALL=false
CLEAN_VOLUMES=false
CLEAN_NETWORKS=false
FORCE=false
DRY_RUN=false

# --- 颜色定义 ---
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_RED='\033[0;31m'
C_YELLOW='\033[0;33m'
C_CYAN='\033[0;36m'
C_GREEN='\033[0;32m'

# --- 函数定义 ---

function show_usage() {
    echo "用法: $0 [选项]"
    echo "安全地清理未使用的 Docker 资源。"
    echo
    echo "必须至少选择一个清理目标。默认在演练模式下运行。"
    echo
    echo "清理目标:"
    echo "  --containers          清理已停止的容器。"
    echo "  --images              清理悬空 (dangling) 的镜像。"
    echo "  --images-all          清理所有未使用的镜像 (比 --images 更彻底)。"
    echo "  --volumes             清理未使用的卷。"
    echo "  --networks            清理未使用的网络。"
    echo "  --all                 选择所有清理目标 (不包括 --images-all)。"
    echo
    echo "操作模式:"
    echo "      --dry-run             (默认) 显示将要删除的内容，但不执行任何操作。"
    echo "      --force               实际执行删除操作。"
    echo "  -h, --help                显示此帮助信息。"
}

# --- 参数解析 ---
if [ $# -eq 0 ]; then show_usage; exit 1; fi

while [[ $# -gt 0 ]]; do
    case $1 in
        --containers)       CLEAN_CONTAINERS=true; shift;;
        --images)           CLEAN_IMAGES=true; shift;;
        --images-all)       CLEAN_IMAGES_ALL=true; shift;;
        --volumes)          CLEAN_VOLUMES=true; shift;;
        --networks)         CLEAN_NETWORKS=true; shift;;
        --all)              CLEAN_CONTAINERS=true; CLEAN_IMAGES=true; CLEAN_VOLUMES=true; CLEAN_NETWORKS=true; shift;;
        --force)            FORCE=true; DRY_RUN=false; shift;;
        --dry-run)          DRY_RUN=true; FORCE=false; shift;;
        -h|--help)          show_usage; exit 0;;
        -*)
            echo -e "${C_RED}错误: 未知选项: $1${C_RESET}" >&2; show_usage; exit 1;;
        *)
            shift;;
    esac
done

# --- 输入校验 ---
if ! docker info >/dev/null 2>&1; then
    echo -e "${C_RED}错误: Docker 守护进程未运行或当前用户无权限访问。${C_RESET}" >&2; exit 1;
fi
if [ "$CLEAN_CONTAINERS" = false ] && [ "$CLEAN_IMAGES" = false ] && [ "$CLEAN_IMAGES_ALL" = false ] && [ "$CLEAN_VOLUMES" = false ] && [ "$CLEAN_NETWORKS" = false ]; then
    echo -e "${C_RED}错误: 请至少选择一个清理目标。${C_RESET}" >&2; show_usage; exit 1;
fi
if [ "$FORCE" = false ] && [ "$DRY_RUN" = false ]; then
    DRY_RUN=true # 默认启用演练模式
fi

# --- 主逻辑 ---
MODE_MSG=""
if [ "$DRY_RUN" = true ]; then
    MODE_MSG="${C_BOLD}${C_YELLOW}*** 演练模式 (Dry Run) ***${C_RESET}"
else
    MODE_MSG="${C_BOLD}${C_RED}*** 强制执行模式 ***${C_RESET}"
fi

printf "${C_CYAN}--- Docker 清理工具 ---${C_RESET}\n"
printf "模式: %s\n\n" "$MODE_MSG"

function list_items() {
    local title="$1"
    local cmd="$2"
    local count
    
    echo -e "${C_CYAN}将要清理的 $title:${C_RESET}"
    # 使用 eval 来执行包含管道和重定向的命令字符串
    items=$(eval "$cmd")
    count=$(echo "$items" | wc -l | awk '{print $1}')

    if [ $count -gt 0 ]; then
        echo "$items"
        echo -e "${C_YELLOW}找到 $count 个可清理的 $title。${C_RESET}\n"
    else
        echo "没有找到可清理的 $title。\n"
    fi
}

# 获取清理前的磁盘使用情况
SPACE_BEFORE=$(docker system df --format "{{.ReclaimableSpace}}" | head -n 1)

if [ "$CLEAN_CONTAINERS" = true ]; then
    if [ "$DRY_RUN" = true ]; then
        list_items "已停止的容器" "docker ps -a --filter status=exited --format '{{.ID}}\t{{.Names}}'"
    else
        echo "清理已停止的容器..."
        docker container prune -f
    fi
fi

if [ "$CLEAN_IMAGES_ALL" = true ]; then
    if [ "$DRY_RUN" = true ]; then
        list_items "所有未使用的镜像" "docker images -f dangling=false | tail -n +2 | awk '\''{if(\$2==\"<none>\") print \$3; else print \$1\":\"\$2}'\'' | xargs -r docker image inspect -f '{{.Id}} {{.RepoTags}}' --filter 'dangling=false' | grep -v ' '"
    else
        echo "清理所有未使用的镜像..."
        docker image prune -a -f
    fi
elif [ "$CLEAN_IMAGES" = true ]; then
    if [ "$DRY_RUN" = true ]; then
        list_items "悬空的镜像" "docker images -f dangling=true --format '{{.ID}}\t{{.Repository}}:{{.Tag}}'"
    else
        echo "清理悬空的镜像..."
        docker image prune -f
    fi
fi

if [ "$CLEAN_VOLUMES" = true ]; then
    if [ "$DRY_RUN" = true ]; then
        list_items "未使用的卷" "docker volume ls -f dangling=true --format '{{.Name}}'"
    else
        echo "清理未使用的卷..."
        docker volume prune -f
    fi
fi

if [ "$CLEAN_NETWORKS" = true ]; then
    if [ "$DRY_RUN" = true ]; then
        list_items "未使用的网络" "docker network ls -f dangling=true --format '{{.ID}}\t{{.Name}}'"
    else
        echo "清理未使用的网络..."
        docker network prune -f
    fi
fi

if [ "$FORCE" = true ]; then
    SPACE_AFTER=$(docker system df --format "{{.ReclaimableSpace}}" | head -n 1)
    # 简单的空间计算，可能不完全精确，但能提供一个大概的估算
    # docker system df 的输出是带单位的，这里简化处理
    echo -e "\n${C_GREEN}--- 清理报告 ---${C_RESET}"
    echo "操作已完成。"
    docker system df
fi

printf "\n${C_GREEN}操作结束。${C_RESET}\n"
