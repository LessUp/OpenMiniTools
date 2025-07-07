# MiniTools 核心工具使用指南

本文档提供了 MiniTools 项目中一些核心工具的详细配置和使用方法。

---

## 1. Git-Proxy: 为私有 Git 服务器设置安全代理

`Git-Proxy` 是一个强大的工具，它能让你在访问公司内网等私有 Git 服务器时，自动启用一个安全的 SSH 代理，同时完全不影响你访问 GitHub 等公共服务。

### 1.1 工作原理

它利用了 SSH 的 `DynamicForward` 功能创建一个本地 SOCKS5 代理，并通过 Git 的 `includeIf` 条件加载机制，实现仅对特定域名启用该代理。

### 1.2 详细配置步骤

**第一步：复制并重命名模板**

1.  进入 `04-Git-Proxy/配置模板` 目录。
2.  将该目录下的所有 `.template` 文件复制到一个你方便管理的位置（例如 `~/.config/minitools/git-proxy`）。
3.  移除所有文件的 `.template` 后缀。

**第二步：修改 `ssh_config`**

打开你新复制的 `ssh_config` 文件，找到并修改以下占位符：

- `your-jump-host.example.com`: 替换为你的跳板机（堡垒机）的 IP 地址或域名。
- `your-username`: 替换为登录跳板机所用的用户名。
- `path/to/your/private_key`: （可选）如果你的私钥不在默认位置 `~/.ssh/id_rsa`，请修改此路径。

**第三步：修改启停脚本**

打开 `start-proxy.ps1` (Windows) 或 `start-proxy.sh` (macOS/Linux)，找到并修改以下占位符：

- `your-git-server.com`: **非常重要**，这必须精确替换为你的私有 Git 服务器的域名。

**第四步：设置全局 Git 配置**

这是**一次性**操作。打开终端，执行以下命令，将 `your-git-server.com` 替换为你的域名：

```bash
git config --global includeIf."gitdir:**/your-git-server.com/**/.path" ~/.gitconfig-proxy
```

这条命令告诉 Git：“当你在一个包含 `your-git-server.com` 路径的仓库中时，才加载 `~/.gitconfig-proxy` 这个代理配置”。

### 1.3 日常使用

- **启动代理**: 在你存放脚本的目录中，运行 `.\start-proxy.ps1` 或 `./start-proxy.sh`。
- **停止代理**: 运行 `.\stop-proxy.ps1` 或 `./stop-proxy.sh`。

启动代理后，所有对私有服务器的 `git` 操作都会自动通过代理进行。

### 1.4 常见问题 (FAQ)

- **Q: 启动失败，提示“端口已被占用”？**
  - **A:** 可能是 `1080` 端口被其他程序占用了。你可以修改启停脚本和 `ssh_config` 中的 `1080` 为其他端口（如 `1081`）。

- **Q: 如何调试连接问题？**
  - **A:** 在终端直接运行 `ssh -v gitlab-proxy`，`-v` 参数会打印详细的连接日志，帮助你定位问题。

---

## 2. Get-SystemInfo: 快速获取 Windows 系统信息

这是一个位于 `08-System/win/` 目录下的 PowerShell 脚本，用于快速诊断 Windows 系统的核心信息。

### 2.1 使用方法

1.  打开 PowerShell 终端。
2.  进入 `08-System/win/` 目录。
3.  运行脚本：`.\Get-SystemInfo.ps1`

### 2.2 输出解读

脚本会清晰地列出以下信息：

- **操作系统**: Windows 版本和名称。
- **激活状态**: 当前系统是否已激活。
- **硬件信息**: CPU 型号和物理内存大小。
- **磁盘信息**: 一个包含所有物理磁盘型号、类型、大小、健康状况的表格。
