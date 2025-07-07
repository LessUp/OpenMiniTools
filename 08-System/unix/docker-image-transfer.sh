#!/bin/bash
# Docker镜像迁移工具
# 用法: ./13-docker-image-transfer.sh [操作] [参数]

# 显示帮助信息
show_help() {
  echo "Docker镜像迁移工具"
  echo "用法: $0 [操作] [参数]"
  echo "操作:"
  echo "  list                  - 列出所有本地Docker镜像"
  echo "  save <镜像> <文件>    - 将镜像保存为tar文件"
  echo "  load <文件>           - 从tar文件加载镜像"
  echo "  transfer <镜像> <目标> - 将镜像传输到远程主机 (SSH)"
  echo "  registry <操作>       - 管理本地镜像仓库"
  echo "例如:"
  echo "  $0 save nginx:latest nginx-image.tar"
  echo "  $0 transfer mysql:5.7 user@remote-host:/path/to/save"
  echo "  $0 registry start    # 启动本地仓库"
}

# 检查Docker是否安装
check_docker() {
  if ! command -v docker &> /dev/null; then
    echo "错误: Docker未安装"
    echo "请先安装Docker: sudo apt install -y docker.io"
    exit 1
  fi
}

# 列出所有本地Docker镜像
list_images() {
  echo "===== 本地Docker镜像列表 ====="
  
  echo "所有镜像:"
  docker images --format "table {{.Repository}}:{{.Tag}}\t{{.ID}}\t{{.Size}}\t{{.CreatedAt}}"
  
  echo -e "\n镜像总数: $(docker images -q | wc -l)"
  echo -e "总磁盘占用: $(docker system df | grep "Images" | awk '{print $4}')"
}

# 将镜像保存为tar文件
save_image() {
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "错误: 参数不足"
    echo "用法: $0 save <镜像> <文件>"
    exit 1
  fi
  
  IMAGE="$1"
  OUTPUT_FILE="$2"
  
  # 检查镜像是否存在
  if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^$IMAGE$"; then
    echo "错误: 镜像 '$IMAGE' 不存在"
    echo "可用的镜像列表:"
    docker images --format "{{.Repository}}:{{.Tag}}"
    exit 1
  fi
  
  echo "===== 保存Docker镜像 ====="
  echo "镜像: $IMAGE"
  echo "输出文件: $OUTPUT_FILE"
  
  # 开始保存
  echo "正在保存镜像，这可能需要一些时间..."
  start_time=$(date +%s)
  docker save -o "$OUTPUT_FILE" "$IMAGE"
  
  if [ $? -eq 0 ]; then
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    file_size=$(du -h "$OUTPUT_FILE" | cut -f1)
    
    echo "镜像保存成功！"
    echo "文件大小: $file_size"
    echo "耗时: $duration 秒"
  else
    echo "保存失败，请检查错误信息"
  fi
}

# 从tar文件加载镜像
load_image() {
  if [ -z "$1" ]; then
    echo "错误: 参数不足"
    echo "用法: $0 load <文件>"
    exit 1
  fi
  
  INPUT_FILE="$1"
  
  # 检查文件是否存在
  if [ ! -f "$INPUT_FILE" ]; then
    echo "错误: 文件不存在: $INPUT_FILE"
    exit 1
  fi
  
  echo "===== 加载Docker镜像 ====="
  echo "输入文件: $INPUT_FILE"
  
  # 开始加载
  echo "正在加载镜像，这可能需要一些时间..."
  start_time=$(date +%s)
  docker load -i "$INPUT_FILE"
  
  if [ $? -eq 0 ]; then
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    echo "镜像加载成功！"
    echo "耗时: $duration 秒"
    
    echo -e "\n新加载的镜像:"
    docker images --format "table {{.Repository}}:{{.Tag}}\t{{.ID}}\t{{.Size}}\t{{.CreatedAt}}" | head -n 5
  else
    echo "加载失败，请检查错误信息"
  fi
}

# 将镜像传输到远程主机
transfer_image() {
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "错误: 参数不足"
    echo "用法: $0 transfer <镜像> <目标>"
    echo "目标格式: user@remote-host:/path/to/save"
    exit 1
  fi
  
  IMAGE="$1"
  DESTINATION="$2"
  
  # 检查镜像是否存在
  if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^$IMAGE$"; then
    echo "错误: 镜像 '$IMAGE' 不存在"
    echo "可用的镜像列表:"
    docker images --format "{{.Repository}}:{{.Tag}}"
    exit 1
  fi
  
  # 检查目标格式
  if ! echo "$DESTINATION" | grep -q ".*@.*:.*"; then
    echo "错误: 目标格式不正确"
    echo "正确格式: user@remote-host:/path/to/save"
    exit 1
  fi
  
  # 分隔目标字符串
  REMOTE_USER_HOST=$(echo "$DESTINATION" | cut -d ':' -f1)
  REMOTE_PATH=$(echo "$DESTINATION" | cut -d ':' -f2-)
  
  echo "===== 镜像传输 ====="
  echo "镜像: $IMAGE"
  echo "目标: $DESTINATION"
  
  # 创建临时文件
  TEMP_FILE="/tmp/docker-image-$(date +%s).tar"
  echo "创建临时文件: $TEMP_FILE"
  
  # 保存镜像
  echo "正在保存镜像..."
  docker save -o "$TEMP_FILE" "$IMAGE"
  
  if [ $? -ne 0 ]; then
    echo "保存镜像失败，传输终止"
    rm -f "$TEMP_FILE" 2>/dev/null
    exit 1
  fi
  
  # 传输文件
  echo "正在传输到远程服务器..."
  scp "$TEMP_FILE" "$DESTINATION"
  
  if [ $? -eq 0 ]; then
    echo "传输成功！"
    echo "镜像已传输到: $DESTINATION"
    
    # 清理临时文件
    rm -f "$TEMP_FILE"
    
    # 提示远程加载
    echo -e "\n在远程服务器上执行以下命令加载镜像:"
    echo "ssh $REMOTE_USER_HOST \"docker load -i $REMOTE_PATH\""
  else
    echo "传输失败，请检查目标服务器连接和权限"
    # 清理临时文件
    rm -f "$TEMP_FILE"
  fi
}

# 管理本地镜像仓库
registry_manage() {
  if [ -z "$1" ]; then
    echo "错误: 参数不足"
    echo "用法: $0 registry <操作>"
    echo "操作: start, stop, push, pull, list"
    exit 1
  fi
  
  ACTION="$1"
  
  case "$ACTION" in
    "start")
      echo "===== 启动本地Docker镜像仓库 ====="
      
      # 检查是否已启动仓库容器
      if docker ps | grep -q "registry:2"; then
        echo "本地仓库已在运行"
        docker ps | grep "registry:2"
        return 0
      fi
      
      # 启动仓库容器
      echo "正在启动本地镜像仓库容器..."
      docker run -d -p 5000:5000 --restart=always --name registry registry:2
      
      if [ $? -eq 0 ]; then
        echo "本地镜像仓库已启动"
        echo "地址: localhost:5000"
        echo "上传镜像示例: docker tag myimage:latest localhost:5000/myimage:latest && docker push localhost:5000/myimage:latest"
      else
        echo "启动失败"
      fi
      ;;
      
    "stop")
      echo "===== 停止本地Docker镜像仓库 ====="
      docker stop registry && docker rm registry
      echo "本地镜像仓库已停止并删除"
      ;;
      
    "push")
      if [ -z "$2" ]; then
        echo "错误: 未指定镜像"
        echo "用法: $0 registry push <镜像>"
        exit 1
      fi
      
      IMAGE="$2"
      REGISTRY_IMAGE="localhost:5000/$(echo $IMAGE | cut -d ':' -f1):${IMAGE##*:}"
      
      echo "===== 推送镜像到本地仓库 ====="
      echo "标记镜像: $IMAGE -> $REGISTRY_IMAGE"
      docker tag "$IMAGE" "$REGISTRY_IMAGE"
      
      echo "推送镜像: $REGISTRY_IMAGE"
      docker push "$REGISTRY_IMAGE"
      ;;
      
    "pull")
      if [ -z "$2" ]; then
        echo "错误: 未指定镜像"
        echo "用法: $0 registry pull <镜像>"
        exit 1
      fi
      
      IMAGE="$2"
      REGISTRY_IMAGE="localhost:5000/$IMAGE"
      
      echo "===== 从本地仓库拉取镜像 ====="
      echo "拉取镜像: $REGISTRY_IMAGE"
      docker pull "$REGISTRY_IMAGE"
      ;;
      
    "list")
      echo "===== 本地仓库镜像列表 ====="
      curl -X GET http://localhost:5000/v2/_catalog
      echo -e "\n详细信息请访问: http://localhost:5000/v2/<镜像名>/tags/list"
      ;;
      
    *)
      echo "未知操作: $ACTION"
      echo "可用操作: start, stop, push, pull, list"
      exit 1
      ;;
  esac
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
    "list")
      list_images
      ;;
    "save")
      save_image "$2" "$3"
      ;;
    "load")
      load_image "$2"
      ;;
    "transfer")
      transfer_image "$2" "$3"
      ;;
    "registry")
      shift
      registry_manage "$@"
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
