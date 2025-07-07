#!/bin/bash
# Ubuntu Docker管理工具
# 用法: ./08-docker-manager.sh [操作]
# 操作: status, clean, start, stop, restart, logs

# 显示帮助信息
show_help() {
  echo "Ubuntu Docker管理工具"
  echo "用法: $0 [操作]"
  echo "操作:"
  echo "  status   - 显示Docker状态和容器列表"
  echo "  clean    - 清理未使用的Docker资源"
  echo "  start    - 启动所有容器"
  echo "  stop     - 停止所有容器"
  echo "  restart  - 重启所有容器"
  echo "  logs [容器名] - 查看指定容器的日志"
  echo "例如: $0 status"
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

# 显示Docker状态
docker_status() {
  echo "===== Docker状态 ====="
  echo "Docker版本:"
  docker --version
  
  echo -e "\nDocker服务状态:"
  systemctl status docker --no-pager | head -n 5
  
  echo -e "\n运行中的容器:"
  docker ps
  
  echo -e "\n所有容器:"
  docker ps -a
  
  echo -e "\nDocker镜像:"
  docker images
  
  echo -e "\nDocker磁盘使用情况:"
  docker system df
}

# 清理Docker资源
docker_clean() {
  echo "===== 清理Docker资源 ====="
  
  echo "停止所有未运行的容器..."
  docker container prune -f
  
  echo "删除未使用的镜像..."
  docker image prune -f
  
  echo "删除未使用的网络..."
  docker network prune -f
  
  echo "删除未使用的数据卷..."
  docker volume prune -f
  
  echo "Docker清理完成！"
  
  # 显示清理后状态
  echo -e "\n清理后的Docker磁盘使用情况:"
  docker system df
}

# 启动所有容器
docker_start() {
  echo "===== 启动所有Docker容器 ====="
  
  # 获取所有停止的容器
  CONTAINERS=$(docker ps -a -q -f "status=exited")
  
  if [ -z "$CONTAINERS" ]; then
    echo "没有已停止的容器可启动"
    return
  fi
  
  echo "正在启动容器..."
  for container in $CONTAINERS; do
    NAME=$(docker ps -a --format "{{.Names}}" -f "id=$container")
    echo "启动容器: $NAME"
    docker start "$container"
  done
  
  echo "所有容器已启动！"
}

# 停止所有容器
docker_stop() {
  echo "===== 停止所有Docker容器 ====="
  
  # 获取所有运行中的容器
  CONTAINERS=$(docker ps -q)
  
  if [ -z "$CONTAINERS" ]; then
    echo "没有正在运行的容器可停止"
    return
  fi
  
  echo "正在停止容器..."
  for container in $CONTAINERS; do
    NAME=$(docker ps --format "{{.Names}}" -f "id=$container")
    echo "停止容器: $NAME"
    docker stop "$container"
  done
  
  echo "所有容器已停止！"
}

# 重启所有容器
docker_restart() {
  echo "===== 重启所有Docker容器 ====="
  
  # 获取所有运行中的容器
  CONTAINERS=$(docker ps -q)
  
  if [ -z "$CONTAINERS" ]; then
    echo "没有正在运行的容器可重启"
    return
  fi
  
  echo "正在重启容器..."
  for container in $CONTAINERS; do
    NAME=$(docker ps --format "{{.Names}}" -f "id=$container")
    echo "重启容器: $NAME"
    docker restart "$container"
  done
  
  echo "所有容器已重启！"
}

# 查看容器日志
docker_logs() {
  if [ -z "$1" ]; then
    echo "错误: 未指定容器名"
    echo "用法: $0 logs <容器名>"
    exit 1
  fi
  
  CONTAINER="$1"
  
  # 检查容器是否存在
  if ! docker ps -a --format "{{.Names}}" | grep -q "^${CONTAINER}$"; then
    echo "错误: 容器 '$CONTAINER' 不存在"
    exit 1
  fi
  
  echo "===== 容器 '$CONTAINER' 的日志 ====="
  docker logs -n 50 "$CONTAINER"
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
    "status")
      docker_status
      ;;
    "clean")
      docker_clean
      ;;
    "start")
      docker_start
      ;;
    "stop")
      docker_stop
      ;;
    "restart")
      docker_restart
      ;;
    "logs")
      docker_logs "$2"
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
