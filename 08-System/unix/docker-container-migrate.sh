#!/bin/bash
# Docker容器迁移工具
# 用法: ./14-docker-container-migrate.sh [操作] [参数]

# 显示帮助信息
show_help() {
  echo "Docker容器迁移工具"
  echo "用法: $0 [操作] [参数]"
  echo "操作:"
  echo "  export <容器> <文件名> - 导出容器为迁移包"
  echo "  import <文件名> <镜像名> - 从迁移包导入容器"
  echo "例如:"
  echo "  $0 export my_container my_container_migration.tar.gz"
  echo "  $0 import my_container_migration.tar.gz new_image_name"
}

# 检查Docker是否安装
check_docker() {
  if ! command -v docker &> /dev/null; then
    echo "错误: Docker未安装"
    exit 1
  fi
}

# 导出容器
export_container() {
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "错误: 参数不足"
    echo "用法: $0 export <容器> <文件名>"
    exit 1
  fi

  CONTAINER="$1"
  OUTPUT_FILE="$2"
  TEMP_DIR="/tmp/docker_migrate_$(date +%s)"

  # 检查容器是否存在
  if ! docker ps -a --format "{{.Names}}" | grep -q "^$CONTAINER$"; then
    echo "错误: 容器 '$CONTAINER' 不存在"
    exit 1
  fi

  echo "===== 导出容器: $CONTAINER ====="
  mkdir -p "$TEMP_DIR"

  # 1. 从容器创建一个镜像
  echo "[1/4] 从容器 '$CONTAINER' 创建临时镜像..."
  IMAGE_NAME="migrate/${CONTAINER}:$(date +%s)"
  docker commit "$CONTAINER" "$IMAGE_NAME"
  if [ $? -ne 0 ]; then
    echo "创建镜像失败"
    rm -rf "$TEMP_DIR"
    exit 1
  fi

  # 2. 保存镜像为tar文件
  echo "[2/4] 保存镜像 '$IMAGE_NAME' 到文件..."
  docker save -o "$TEMP_DIR/image.tar" "$IMAGE_NAME"
  if [ $? -ne 0 ]; then
    echo "保存镜像失败"
    rm -rf "$TEMP_DIR"
    exit 1
  fi

  # 3. 导出容器的元数据
  echo "[3/4] 导出容器元数据..."
  docker inspect "$CONTAINER" > "$TEMP_DIR/metadata.json"

  # 4. 打包成单个文件
  echo "[4/4] 正在打包迁移文件..."
  tar -czf "$OUTPUT_FILE" -C "$TEMP_DIR" .

  # 清理
  docker rmi "$IMAGE_NAME"
  rm -rf "$TEMP_DIR"

  echo "容器 '$CONTAINER' 导出成功: $OUTPUT_FILE"
  echo "请将此文件复制到目标主机并使用 'import' 命令恢复。"
}

# 导入容器
import_container() {
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "错误: 参数不足"
    echo "用法: $0 import <文件名> <新容器名>"
    exit 1
  fi

  INPUT_FILE="$1"
  NEW_CONTAINER_NAME="$2"
  TEMP_DIR="/tmp/docker_migrate_$(date +%s)"

  if [ ! -f "$INPUT_FILE" ]; then
    echo "错误: 迁移文件 '$INPUT_FILE' 不存在"
    exit 1
  fi

  echo "===== 导入容器: $NEW_CONTAINER_NAME ====="
  mkdir -p "$TEMP_DIR"

  # 1. 解压迁移包
  echo "[1/4] 解压迁移文件..."
  tar -xzf "$INPUT_FILE" -C "$TEMP_DIR"
  if [ $? -ne 0 ]; then
    echo "解压失败"
    rm -rf "$TEMP_DIR"
    exit 1
  fi

  # 2. 加载镜像
  echo "[2/4] 加载镜像..."
  docker load -i "$TEMP_DIR/image.tar"
  IMAGE_NAME=$(docker load -i "$TEMP_DIR/image.tar" | grep "Loaded image" | sed 's/Loaded image: //')
  if [ -z "$IMAGE_NAME" ]; then
    echo "加载镜像失败"
    rm -rf "$TEMP_DIR"
    exit 1
  fi

  # 3. 读取元数据并创建容器
  echo "[3/4] 读取元数据并准备创建容器..."
  # 注意：这是一个简化的实现。完整的容器恢复非常复杂，
  # 涉及到网络、卷、环境变量等。这里只使用镜像和名称。
  
  echo "[4/4] 创建新容器 '$NEW_CONTAINER_NAME' ..."
  # 提取原始容器的CMD和ENTRYPOINT
  CMD=$(jq -r '.Config.Cmd | join(" ")' "$TEMP_DIR/metadata.json")
  ENTRYPOINT=$(jq -r '.Config.Entrypoint | join(" ")' "$TEMP_DIR/metadata.json")

  # 运行新容器
  docker create --name "$NEW_CONTAINER_NAME" "$IMAGE_NAME" $ENTRYPOINT $CMD

  if [ $? -eq 0 ]; then
    echo "容器 '$NEW_CONTAINER_NAME' 创建成功！"
    echo "请注意：此迁移只包含容器的文件系统和镜像。"
    echo "网络、卷映射等配置需要手动重新设置。"
    echo "使用 'docker start $NEW_CONTAINER_NAME' 启动容器。"
  else
    echo "创建容器失败"
  fi

  # 清理
  rm -rf "$TEMP_DIR"
}

# 主函数
main() {
  check_docker

  if [ -z "$1" ]; then
    show_help
    exit 1
  fi

  case "$1" in
    "export")
      export_container "$2" "$3"
      ;;
    "import")
      import_container "$2" "$3"
      ;;
    *)
      echo "未知操作: $1"
      show_help
      exit 1
      ;;
  esac
}

main "$@"
