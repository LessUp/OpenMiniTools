#!/bin/bash
# Ubuntu开发环境快速配置工具
# 用法: ./05-setup-dev-env.sh [环境类型]
# 环境类型: web, python, java, nodejs, go, docker, all

# 检查参数
if [ -z "$1" ]; then
  echo "请指定要安装的环境类型: web, python, java, nodejs, go, docker, all"
  echo "例如: ./05-setup-dev-env.sh python"
  exit 1
fi

ENV_TYPE="$1"
echo "===== Ubuntu开发环境配置 - $ENV_TYPE ====="

# 更新系统包
update_system() {
  echo "正在更新系统包..."
  sudo apt update && sudo apt upgrade -y
}

# 安装Web开发环境
install_web() {
  echo "正在安装Web开发环境..."
  sudo apt install -y apache2 nginx
  sudo apt install -y php php-cli php-fpm php-mysql php-json php-common
  sudo apt install -y mysql-server
  
  echo "启动服务..."
  sudo systemctl start apache2
  sudo systemctl start mysql
  
  echo "Web开发环境安装完成！"
}

# 安装Python开发环境
install_python() {
  echo "正在安装Python开发环境..."
  sudo apt install -y python3 python3-pip python3-venv python3-dev
  sudo apt install -y ipython3
  
  echo "安装常用Python库..."
  pip3 install --user numpy pandas matplotlib scikit-learn jupyter
  
  echo "Python开发环境安装完成！"
}

# 安装Java开发环境
install_java() {
  echo "正在安装Java开发环境..."
  sudo apt install -y openjdk-17-jdk openjdk-17-jre maven gradle
  
  # 设置JAVA_HOME环境变量
  echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' >> ~/.bashrc
  echo 'export PATH=$PATH:$JAVA_HOME/bin' >> ~/.bashrc
  
  echo "Java开发环境安装完成！"
}

# 安装Node.js开发环境
install_nodejs() {
  echo "正在安装Node.js开发环境..."
  curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
  sudo apt install -y nodejs
  sudo apt install -y npm
  
  echo "安装常用全局包..."
  sudo npm install -g yarn webpack typescript nodemon
  
  echo "Node.js开发环境安装完成！"
}

# 安装Go开发环境
install_go() {
  echo "正在安装Go开发环境..."
  sudo apt install -y golang-go
  
  # 设置GOPATH环境变量
  echo 'export GOPATH=$HOME/go' >> ~/.bashrc
  echo 'export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin' >> ~/.bashrc
  
  echo "Go开发环境安装完成！"
}

# 安装Docker环境
install_docker() {
  echo "正在安装Docker环境..."
  sudo apt install -y docker.io docker-compose
  sudo systemctl enable --now docker
  
  # 添加当前用户到docker组
  sudo usermod -aG docker $USER
  
  echo "Docker环境安装完成！（请注销并重新登录使docker组权限生效）"
}

# 根据参数安装相应环境
update_system

case "$ENV_TYPE" in
  "web")
    install_web
    ;;
  "python")
    install_python
    ;;
  "java")
    install_java
    ;;
  "nodejs")
    install_nodejs
    ;;
  "go")
    install_go
    ;;
  "docker")
    install_docker
    ;;
  "all")
    install_web
    install_python
    install_java
    install_nodejs
    install_go
    install_docker
    ;;
  *)
    echo "未知的环境类型: $ENV_TYPE"
    echo "支持的环境类型: web, python, java, nodejs, go, docker, all"
    exit 1
    ;;
esac

echo "环境配置完成，建议重启终端以应用所有更改。"
