#!/bin/bash
# Ubuntu开发环境依赖安装脚本
# 用法: ./01-install-deps.sh

# 更新软件包列表
sudo apt update

# 安装基础开发工具
sudo apt install -y git curl wget build-essential

# 安装常用开发工具
sudo apt install -y python3 python3-pip nodejs npm

# 安装Docker
sudo apt install -y docker.io
sudo systemctl enable --now docker

# 安装其他你可能需要的工具
# sudo apt install -y ...
