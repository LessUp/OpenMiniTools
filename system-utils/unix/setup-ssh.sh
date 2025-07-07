#!/bin/bash
# Ubuntu SSH配置脚本
# 用法: ./02-setup-ssh.sh

# 生成SSH密钥(如果不存在)
if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
fi

# 设置SSH目录权限
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub

# 显示公钥
echo "你的SSH公钥是:"
cat ~/.ssh/id_rsa.pub
