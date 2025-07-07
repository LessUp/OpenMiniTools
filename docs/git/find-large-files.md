# `find-large-files` - Git 仓库大文件审查器

## 功能简介

`find-large-files` 是一个用于诊断 Git 仓库体积问题的专用工具。它会深度扫描整个项目的提交历史，找出那些即使已被删除但仍占用着仓库空间的“幽灵”大文件。

## 核心功能

-   **深度历史扫描**: 不同于简单的检查当前文件，此工具通过分析 Git 的底层 packfiles，能够追溯到仓库中存在过的每一个大文件。
-   **体积排序**: 精确计算并按文件大小降序排列，列出仓库中体积最大的 Top 10 对象。
-   **路径定位**: 显示每个大文件在提交历史中最后出现的文件路径，帮助您快速定位问题源。

## 为什么需要它？

Git 的设计机制决定了每一次提交都是永久性的。如果您不小心将一个 100MB 的视频文件提交到了仓库，即使您在下一个 commit 中就把它删除了，这个 100MB 的文件依然会永久地存在于 `.git` 目录中。随着时间推移，这类无用的大文件会不断累积，导致：

-   **仓库体积急剧膨胀**: 使得新成员 `clone` 仓库的时间变得极长。
-   **网络操作缓慢**: `fetch` 和 `push` 等日常操作也会因为需要传输大量无用数据而变慢。

`find-large-files` 能帮助您在问题变得严重之前，主动发现这些“定时炸弹”，是保持仓库长期健康、高效的关键工具。

**注意**: 本工具只负责**查找**。要将这些文件从历史中**彻底移除**，您需要使用 `git filter-repo` 或 `BFG Repo-Cleaner` 等更专业的工具。

## 如何使用

在您本地 Git 项目的根目录下打开终端，然后运行对应的脚本。**此操作为只读分析，非常安全，但根据仓库大小，可能需要几分钟时间。**

### Windows (PowerShell)

```powershell
f:\Deving\OpenMiniTools\GitTools\win\find-large-files.ps1
```

### Unix/Linux/macOS (Bash)

首次使用请确保脚本有执行权限：

```bash
chmod +x f:/Deving/OpenMiniTools/GitTools/unix/find-large-files.sh
```

然后运行脚本：

```bash
f:/Deving/OpenMiniTools/GitTools/unix/find-large-files.sh
```
