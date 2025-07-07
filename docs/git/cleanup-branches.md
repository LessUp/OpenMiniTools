# `cleanup-branches` - 已合并分支清理工具

## 功能简介

`cleanup-branches` 是一个用于保持本地 Git 仓库整洁的实用脚本。它会自动扫描并识别出那些已经完全合并到主分支 (`main` 或 `master`) 的本地分支，并提供一个安全的、交互式的清理方案。

## 核心功能

-   **自动检测**: 智能识别 `main` 或 `master` 作为主分支。
-   **安全过滤**: 自动排除主分支和当前所在分支，防止误删。
-   **交互式确认**: 在执行任何删除操作前，会清晰地列出所有待删除的分支，并请求用户最终确认。
-   **批量删除**: 确认后，一键批量删除所有可清理的分支，无需手动逐个操作。

## 为什么需要它？

在日常开发中，我们经常会为新功能或 bug 修复创建临时分支。当这些分支的工作完成后并合并到主线，它们就完成了使命。如果不及时清理，本地会堆积大量无用的分支，不仅会干扰 `git branch` 的输出，也可能在未来引起混淆。

`cleanup-branches` 工具让这个清理过程变得简单、快速且安全。

## 如何使用

在您本地 Git 项目的根目录下打开终端，然后运行对应的脚本。

### Windows (PowerShell)

```powershell
f:\Deving\OpenMiniTools\GitTools\win\cleanup-branches.ps1
```

### Unix/Linux/macOS (Bash)

首次使用请确保脚本有执行权限：

```bash
chmod +x f:/Deving/OpenMiniTools/GitTools/unix/cleanup-branches.sh
```

然后运行脚本：

```bash
f:/Deving/OpenMiniTools/GitTools/unix/cleanup-branches.sh
```

脚本会列出所有可被安全删除的分支，并等待您的 `y/n` 确认。
