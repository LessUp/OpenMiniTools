# OpenMiniTools - 开发常用脚本合集

![许可证: MIT](https://img.shields.io/badge/License-MIT-yellow.svg) ![代码风格: 标准](https://img.shields.io/badge/code%20style-standard-brightgreen.svg)

欢迎来到 MiniTools，这是一个精心整理的、旨在简化常见开发和系统管理任务的脚本与工具合集。

## ✨ 亮点功能

- **Git-Proxy (安全代理)**: 为私有 Git 服务器（如公司 GitLab）设置安全、隔离的代理，无需改动全局 Git 配置，不影响访问 GitHub 等公共服务。详见 `git-proxy` 目录。

- **SSH 交互式连接**: 提供支持 `fzf` 模糊搜索的菜单，快速连接到常用 SSH 主机。详见 `02-SSH` 目录。

- **跨平台支持**: 同时提供 Windows (PowerShell) 和类 Unix 系统 (Bash) 解决方案。

## 💡 快速开始

1.  **克隆仓库**:
    ```bash
    git clone https://github.com/LessUp/OpenMiniTools.git
    ```
2.  **浏览目录**: 探索感兴趣的目录，查找所需脚本
3.  **阅读文档**:
    - **核心工具**: [使用指南](./01-Docs/USAGE.md)
    - **项目规划**: [演进路线图](./ROADMAP.md)

## 目录结构

- **`01-Docs`**: 项目的核心文档，包括使用指南和路线图。
- **`02-SSH`**: SSH 相关工具。
- **`03-Git`**: 增强 Git 工作流的脚本。
- **`git-proxy`**: 用于为私有 Git 服务器设置代理的模板。
- **`05-Docker`**: Docker 相关辅助脚本。
- **`06-WSL`**: 用于管理 Windows Subsystem for Linux (WSL) 的工具。
- **`07-Dev`**: 通用开发者工具。
- **`08-System`**: 用于系统管理、监控和诊断的脚本。
- **`09-Network`**: 网络相关工具。
- **`10-Files`**: 文件和目录管理脚本。
- **`11-Data`**: 数据处理与操作脚本。
- **`12-Security`**: 安全相关工具，如密码生成器。
- **`13-Backup`**: 用于执行备份的脚本。

## 🤝 参与贡献

欢迎提出建议和改进！如果您有新脚本的想法或对现有脚本的增强建议，请随时创建 Issue 或提交 Pull Request。

## 📜 许可证

本项目采用 [MIT 许可证](LICENSE) 授权。

---

# OpenMiniTools - A Curated Collection of Developer Scripts (English Version)

Welcome to OpenMiniTools, a curated collection of scripts and tools designed to simplify common development and system administration tasks.

## ✨ Highlights

- **Git-Proxy (Secure Proxy)**: Set up a secure, isolated proxy for your private Git server (e.g., company GitLab) without changing your global Git config or affecting access to public services like GitHub. See the `git-proxy` directory.

- **Interactive SSH Connection**: Provides a menu with `fzf` fuzzy search support for quickly connecting to frequently used SSH hosts. See the `02-SSH` directory.

- **Cross-Platform Support**: Where possible, solutions are provided for both Windows (PowerShell) and Unix-like systems (Bash).

## 💡 Getting Started

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/LessUp/OpenMiniTools.git
    ```
2.  **Browse the directories** to find scripts you need.
3.  **Read the documentation**:
    *   For a quick start, read the **[Core Usage Guide](./01-Docs/USAGE.md)**.
    *   For project roadmap, see **[ROADMAP](./ROADMAP.md)**.

## Directory Structure

- **`01-Docs`**: Core documentation, including usage guide and roadmap.
- **`02-SSH`**: SSH-related tools.
- **`03-Git`**: Scripts to enhance Git workflow.
- **`git-proxy`**: Templates for setting up a proxy for private Git servers.
- **`05-Docker`**: Docker helper scripts.
- **`06-WSL`**: Tools for managing Windows Subsystem for Linux (WSL).
- **`07-Dev`**: General developer tools.
- **`08-System`**: Scripts for system management, monitoring, and diagnostics.
- **`09-Network`**: Network-related tools.
- **`10-Files`**: File and directory management scripts.
- **`11-Data`**: Data processing and manipulation scripts.
- **`12-Security`**: Security tools, such as password generators.
- **`13-Backup`**: Scripts for performing backups.

## Contributing

Suggestions and improvements are always welcome! If you have ideas for new scripts or enhancements to existing ones, feel free to open an issue or submit a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
