#!/bin/bash
# Ubuntu性能优化工具
# 用法: ./07-performance-tune.sh [选项]
# 选项: clean (清理), swap (优化交换分区), services (优化服务), all (全部)

# 显示帮助信息
show_help() {
  echo "Ubuntu性能优化工具"
  echo "用法: $0 [选项]"
  echo "选项:"
  echo "  clean    - 清理系统垃圾文件"
  echo "  swap     - 优化交换分区设置"
  echo "  services - 优化系统服务"
  echo "  all      - 执行所有优化"
  echo "例如: $0 clean"
}

# 检查权限
check_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "错误: 请以root权限运行此脚本"
    echo "请尝试: sudo $0 $1"
    exit 1
  fi
}

# 清理系统
clean_system() {
  echo "===== 清理系统垃圾文件 ====="
  
  echo "1. 清理APT缓存..."
  apt clean
  apt autoclean
  
  echo "2. 删除不需要的软件包..."
  apt autoremove -y
  
  echo "3. 清理日志文件..."
  journalctl --vacuum-time=7d
  
  echo "4. 清理临时文件..."
  rm -rf /tmp/*
  
  echo "5. 清理缩略图缓存..."
  rm -rf /home/*/.cache/thumbnails/*
  
  echo "系统清理完成！"
}

# 优化交换分区
optimize_swap() {
  echo "===== 优化交换分区 ====="
  
  # 获取系统内存信息
  MEM_TOTAL=$(free -m | grep Mem | awk '{print $2}')
  SWAP_TOTAL=$(free -m | grep Swap | awk '{print $2}')
  
  echo "系统内存: $MEM_TOTAL MB"
  echo "交换分区: $SWAP_TOTAL MB"
  
  # 调整交换分区使用率
  echo "设置交换分区使用率参数..."
  sysctl -w vm.swappiness=10
  echo "vm.swappiness=10" > /etc/sysctl.d/99-swappiness.conf
  
  # 如果没有交换分区，询问是否创建
  if [ "$SWAP_TOTAL" -eq 0 ]; then
    echo "未检测到交换分区。推荐创建交换文件。"
    echo "请手动运行以下命令创建2GB交换文件:"
    echo "sudo fallocate -l 2G /swapfile"
    echo "sudo chmod 600 /swapfile"
    echo "sudo mkswap /swapfile"
    echo "sudo swapon /swapfile"
    echo "echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab"
  fi
  
  echo "交换分区优化完成！"
}

# 优化系统服务
optimize_services() {
  echo "===== 优化系统服务 ====="
  
  echo "1. 列出所有运行的服务..."
  systemctl list-units --type=service --state=running
  
  echo "2. 禁用一些不必要的服务（仅供参考，请手动执行）..."
  echo "sudo systemctl disable bluetooth.service  # 如果不使用蓝牙"
  echo "sudo systemctl disable cups.service       # 如果不使用打印机"
  echo "sudo systemctl disable avahi-daemon.service # 本地网络服务发现"
  
  echo "3. 优化开机启动时间..."
  systemd-analyze blame | head -n 10
  
  echo "系统服务优化建议已列出。请谨慎禁用服务！"
}

# 主函数
main() {
  # 如果没有参数，显示帮助
  if [ -z "$1" ]; then
    show_help
    exit 1
  fi
  
  # 检查root权限
  check_root "$1"
  
  # 根据参数执行相应功能
  case "$1" in
    "clean")
      clean_system
      ;;
    "swap")
      optimize_swap
      ;;
    "services")
      optimize_services
      ;;
    "all")
      clean_system
      optimize_swap
      optimize_services
      ;;
    *)
      echo "未知选项: $1"
      show_help
      exit 1
      ;;
  esac
}

# 执行主函数
main "$1"
