# 通用 Git 代理模板 (适用于私有服务器)

本工具提供了一套模板，用于为私有 Git 服务器（如公司内部的 GitLab、Gitea）设置一个安全、隔离的代理，而不会影响您的全局 Git 配置。

## 核心原理

许多组织的 Git 服务器部署在内部网络中，需要通过“跳板机”或“堡垒机”才能访问。本方案利用 SSH SOCKS5 代理隧道技术实现这一目标。

**主要优势**:

- **配置隔离**: 使用 Git 的 `includeIf` 指令，仅对您的私有 Git 服务器域名启用代理，完全不影响您访问 GitHub 等公共服务。
- **动态启停**: 通过简单的启停脚本，可以按需开启或关闭代理。关闭后，所有代理配置都会被干净地移除。
- **跨平台**: 为 Windows (PowerShell) 和 macOS/Linux (Bash) 提供了通用模板。

## 工作流程

1.  **SSH 隧道**: 启动脚本会连接到您的跳板机，并在本地创建一个 SOCKS5 代理。
2.  **Git 配置**: 脚本随后会创建一个临时的 Git 配置文件 (`~/.gitconfig-proxy`)，该文件将您私有服务器的流量指向此本地代理。
3.  **条件加载**: 您的主配置文件 (`~/.gitconfig`) 中需要设置一条规则：“如果远程仓库的 URL 包含私有服务器的域名，则加载上述的代理配置文件”。
4.  **清理**: 停止脚本会终止 SSH 隧道，并删除临时的 Git 配置文件，从而关闭代理。

## 配置步骤

### 1. 复制并自定义模板

将本目录 `templates` 文件夹中的所有文件复制到您选择的新位置，并移除 `.template` 后缀。

- `ssh_config.template` -> `ssh_config`
- `start-proxy.ps1.template` -> `start-proxy.ps1` (Windows 用户)
- `stop-proxy.ps1.template` -> `stop-proxy.ps1` (Windows 用户)
- `start-proxy.sh.template` -> `start-proxy.sh` (macOS/Linux 用户)
- `stop-proxy.sh.template` -> `stop-proxy.sh` (macOS/Linux 用户)

### 2. 修改配置文件

打开您刚刚创建的文件，将里面的占位符替换为您自己的设置。

**在 `ssh_config` 文件中:**

- 将 `your-jump-host` 替换为您的 SSH 跳板机/堡垒机的主机名或 IP 地址。
- 将 `your-username` 替换为您登录跳板机所用的用户名。
- 如果您使用特定的私钥，请将 `path/to/your/private_key` 替换为正确的私钥路径。

**在 `start-proxy.ps1` 和 `start-proxy.sh` 文件中:**

- 将 `your-git-server.com` 替换为您的私有 Git 服务器的域名。

### 3. 一次性 Git 配置

在终端中运行以下命令，来设置全局 `.gitconfig` 中的条件加载规则：

```bash
git config --global includeIf."gitdir:**/your-git-server.com/**/.path" ~/.gitconfig-proxy
```
**重要**: 请务必将 `your-git-server.com` 替换为您真实的私有 Git 服务器域名。

## 日常使用

- **启动代理**: 运行 `./start-proxy.sh` 或 `.\start-proxy.ps1`。
- **停止代理**: 运行 `./stop-proxy.sh` 或 `.\stop-proxy.ps1`。

现在，您可以无缝地对您的私有服务器执行 `git clone`, `git push` 和 `git pull` 操作了。

---

# Universal Git Proxy for Private Servers (English)

This tool provides a template for setting up a secure and isolated proxy for a private Git server, without interfering with your global Git configuration.

See the setup and usage instructions in the Chinese section above.
