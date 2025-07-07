#!/bin/bash
# Docker高级管理工具
# 用法: ./12-docker-advanced.sh [操作]

# 显示帮助信息
show_help() {
  echo "Docker高级管理工具"
  echo "用法: $0 [操作]"
  echo "操作:"
  echo "  info           - 显示Docker详细信息"
  echo "  prune          - 全面清理未使用的Docker资源"
  echo "  stats          - 显示容器实时统计信息"
  echo "  top <容器>     - 显示容器中运行的进程"
  echo "  inspect <容器> - 查看容器详细配置"
  echo "  network        - 显示Docker网络信息"
  echo "  volumes        - 显示Docker卷信息"
  echo "例如: $0 info"
}

# 检查Docker是否安装
check_docker() {
  if ! command -v docker &> /dev/null; then
    echo "错误: Docker未安装"
    echo "请先安装Docker: sudo apt install -y docker.io"
    exit 1
  fi
  
  # 检查Docker服务状态
  if ! systemctl is-active --quiet docker; then
    echo "Docker服务未运行，正在启动..."
    sudo systemctl start docker
  fi
}

# 显示Docker详细信息
docker_info() {
  echo "===== Docker详细信息 ====="
  
  echo "Docker版本:"
  docker version
  
  echo -e "\nDocker信息:"
  docker info | grep -v 'WARNING'
  
  echo -e "\nDocker统计:"
  echo "容器数量: $(docker ps -a -q | wc -l)"
  echo "镜像数量: $(docker images -q | wc -l)"
  echo "卷数量: $(docker volume ls -q | wc -l)"
  echo "网络数量: $(docker network ls --format '{{.Name}}' | wc -l)"
  
  echo -e "\nDocker磁盘使用情况:"
  docker system df -v
}

# 全面清理未使用的Docker资源
docker_prune() {
  echo "===== 全面清理Docker资源 ====="
  
  echo "1. 停止所有未运行的容器..."
  docker container prune -f
  
  echo "2. 清理未使用的镜像..."
  docker image prune -a -f
  
  echo "3. 清理未使用的卷..."
  docker volume prune -f
  
  echo "4. 清理未使用的网络..."
  docker network prune -f
  
  echo "5. 清理构建缓存..."
  docker builder prune -f
  
  echo "6. 全面系统清理..."
  docker system prune -a -f --volumes
  
  echo "Docker清理完成！"
  echo -e "\n清理后的Docker磁盘使用情况:"
  docker system df
}

# 显示容器实时统计信息
docker_stats() {
  echo "===== 容器资源使用情况 ====="
  echo "按Ctrl+C停止查看"
  docker stats
}

# 显示容器进程
docker_top() {
  if [ -z "$1" ]; then
    echo "错误: 未指定容器名或ID"
    echo "用法: $0 top <容器名或ID>"
    return 1
  fi
  
  CONTAINER="$1"
  
  # 检查容器是否存在
  if ! docker ps -a --format "{{.Names}}" | grep -q "$CONTAINER"; then
    echo "错误: 容器 '$CONTAINER' 不存在"
    return 1
  fi
  
  echo "===== 容器 '$CONTAINER' 进程列表 ====="
  docker top "$CONTAINER"
}

# 查看容器详细配置
docker_inspect() {
  if [ -z "$1" ]; then
    echo "错误: 未指定容器名或ID"
    echo "用法: $0 inspect <容器名或ID>"
    return 1
  fi
  
  CONTAINER="$1"
  
  # 检查容器是否存在
  if ! docker ps -a --format "{{.Names}}" | grep -q "$CONTAINER"; then
    echo "错误: 容器 '$CONTAINER' 不存在"
    return 1
  fi
  
  echo "===== 容器 '$CONTAINER' 详细信息 ====="
  docker inspect "$CONTAINER" | less
}

# 显示Docker网络信息
docker_network() {
  echo "===== Docker网络信息 ====="
  
  echo "网络列表:"
  docker network ls
  
  echo -e "\n网络详细信息:"
  for network in $(docker network ls --format "{{.Name}}"); do
    echo -e "\n==> 网络: $network"
    docker network inspect "$network" | grep -A 5 "Name\|Subnet\|Gateway\|Containers"
  done
}

# 显示Docker卷信息
docker_volumes() {
  echo "===== Docker卷信息 ====="
  
  echo "卷列表:"
  docker volume ls
  
  echo -e "\n卷详细信息:"
  for volume in $(docker volume ls -q); do
    echo -e "\n==> 卷: $volume"
    docker volume inspect "$volume"
  done
  
  echo -e "\n卷使用情况:"
  echo "总卷数: $(docker volume ls -q | wc -l)"
}

# 主函数
main() {
  # 如果没有参数，显示帮助
  if [ -z "$1" ]; then
    show_help
    exit 1
  fi
  
  # 检查Docker
  check_docker
  
  # 根据参数执行相应功能
  case "$1" in
    "info")
      docker_info
      ;;
    "prune")
      docker_prune
      ;;
    "stats")
      docker_stats
      ;;
    "top")
      docker_top "$2"
      ;;
    "inspect")
      docker_inspect "$2"
      ;;
    "network")
      docker_network
      ;;
    "volumes")
      docker_volumes
      ;;
    *)
      echo "未知操作: $1"
      show_help
      exit 1
      ;;
  esac
}

# 执行主函数
main "$@"
