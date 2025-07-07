#!/bin/bash
# Docker 故障排查工具
# 用法: ./15-docker-troubleshoot.sh [操作] [参数]

# 显示帮助信息
show_help() {
  echo "Docker 故障排查工具"
  echo "用法: $0 [操作] [参数]"
  echo "操作:"
  echo "  check-daemon             - 检查Docker守护进程状态"
  echo "  check-container <容器>   - 检查特定容器的健康状况"
  echo "  check-network [容器]     - 检查Docker网络或特定容器的网络"
  echo "  check-storage            - 检查Docker磁盘使用情况"
  echo "  check-permissions        - 检查当前用户的Docker权限"
  echo "  full-check               - 执行全面的健康检查"
  echo "例如: $0 check-container my_web_server"
}

# 检查Docker是否安装
check_docker_installed() {
  if ! command -v docker &> /dev/null; then
    echo "错误: Docker未安装。请先安装Docker。"
    exit 1
  fi
}

# 检查Docker守护进程
check_daemon() {
  echo "===== 1. 检查Docker守护进程 ====="
  
  if systemctl is-active --quiet docker; then
    echo "[OK] Docker守护进程正在运行。"
  else
    echo "[FAIL] Docker守护进程未运行!"
    echo "尝试启动Docker: sudo systemctl start docker"
    sudo systemctl start docker
    if systemctl is-active --quiet docker; then
      echo "[OK] Docker守护进程已成功启动。"
    else
      echo "[FAIL] 启动失败。"
    fi
  fi
  
  echo -e "\n查看最近的Docker守护进程日志:"
  journalctl -u docker.service -n 20 --no-pager
}

# 检查特定容器
check_container() {
  if [ -z "$1" ]; then
    echo "错误: 未指定容器名或ID。"
    echo "用法: $0 check-container <容器>"
    exit 1
  fi
  
  CONTAINER="$1"
  echo "===== 检查容器: $CONTAINER ====="

  if ! docker ps -a --format "{{.Names}}" | grep -q "^$CONTAINER$"; then
    echo "[FAIL] 容器 '$CONTAINER' 不存在。"
    exit 1
  fi

  echo "--- 容器状态 ---"
  docker ps -a -f "name=$CONTAINER"
  
  STATUS=$(docker inspect --format '{{.State.Status}}' "$CONTAINER")
  RESTARTS=$(docker inspect --format '{{.RestartCount}}' "$CONTAINER")
  
  echo "当前状态: $STATUS, 重启次数: $RESTARTS"
  
  if [ "$STATUS" != "running" ]; then
    echo "[WARN] 容器未在运行状态。"
  fi

  echo -e "\n--- 最近的容器日志 (最后50行) ---"
  docker logs --tail 50 "$CONTAINER"

  echo -e "\n--- 容器资源使用情况 ---"
  docker stats --no-stream "$CONTAINER"
}

# 检查网络
check_network() {
  echo "===== 检查Docker网络 ====="
  
  echo "--- 主机网络配置 ---"
  echo "DNS服务器:"
  cat /etc/resolv.conf
  echo "防火墙状态:"
  if command -v ufw &> /dev/null; then
    sudo ufw status
  else
    echo "UFW防火墙未安装。"
  fi

  if [ -n "$1" ]; then
    CONTAINER="$1"
    echo -e "\n--- 容器 '$CONTAINER' 网络检查 ---"
    if ! docker ps -a --format "{{.Names}}" | grep -q "^$CONTAINER$"; then
      echo "[FAIL] 容器 '$CONTAINER' 不存在。"
      exit 1
    fi

    echo "[1/2] 测试到外部网络的连接 (ping 8.8.8.8)..."
    if docker exec "$CONTAINER" ping -c 3 8.8.8.8; then
      echo "[OK] 外部连接正常。"
    else
      echo "[FAIL] 无法连接到外部IP。请检查容器网络模式和主机防火墙规则。"
    fi

    echo "[2/2] 测试DNS解析 (ping google.com)..."
    if docker exec "$CONTAINER" ping -c 3 google.com; then
      echo "[OK] DNS解析正常。"
    else
      echo "[FAIL] DNS解析失败。请检查容器的DNS设置或主机/etc/resolv.conf。"
    fi
  fi
}

# 检查存储
check_storage() {
  echo "===== 检查Docker存储 ====="
  docker system df
  echo -e "\n要查看更详细的信息，请运行 'docker system df -v'"
  echo "如果磁盘空间不足，可以运行 './12-docker-advanced.sh prune' 进行清理。"
}

# 检查权限
check_permissions() {
  echo "===== 检查Docker权限 ====="
  if groups "$USER" | grep -q '\bdocker\b'; then
    echo "[OK] 当前用户 ($USER) 在 'docker' 组中，可以无需sudo运行docker命令。"
  else
    echo "[FAIL] 当前用户 ($USER) 不在 'docker' 组中。"
    echo "要无需sudo运行docker，请执行:"
    echo "  sudo usermod -aG docker $USER"
    echo "然后请注销并重新登录以使更改生效。"
  fi
}

# 全面检查
full_check() {
  echo "===== Docker全面健康检查 ====="
  check_daemon
  echo
  check_permissions
  echo
  check_storage
  echo
  check_network
  echo
  echo "===== 容器概览 ====="
  docker ps -a
  echo -e "\n检查完成。如果发现问题容器，请使用 'check-container <容器名>' 进行详细排查。"
}

# 主函数
main() {
  check_docker_installed

  if [ -z "$1" ]; then
    show_help
    exit 1
  fi

  case "$1" in
    "check-daemon")
      check_daemon
      ;;
    "check-container")
      check_container "$2"
      ;;
    "check-network")
      check_network "$2"
      ;;
    "check-storage")
      check_storage
      ;;
    "check-permissions")
      check_permissions
      ;;
    "full-check")
      full_check
      ;;
    *)
      echo "未知操作: $1"
      show_help
      exit 1
      ;;
  esac
}

main "$@"
