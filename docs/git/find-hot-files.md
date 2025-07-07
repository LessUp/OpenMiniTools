# `find-hot-files` - 热点文件分析工具

## 功能简介

`find-hot-files` 是一个代码库分析工具，它通过扫描 Git 提交历史来识别项目中被修改最频繁的文件，即“热点文件”。

## 核心功能

-   **历史分析**: 深入分析指定数量的最新提交记录（默认为 500 次）。
-   **频率统计**: 精确计算每个文件在这些提交中被更改的次数。
-   **Top N 列表**: 以降序排列，清晰地展示出修改次数最多的 Top 10 文件。
-   **参数可调**: 您可以轻松地通过命令行参数调整分析的提交数量范围。

## 为什么需要它？

在软件开发中，文件的修改频率（Code Churn）是一个非常重要但常被忽略的指标。高频率修改的文件往往是项目的关键所在，它们可能是：

-   **核心业务逻辑**: 项目的主要功能都围绕这些文件构建。
-   **高复杂度模块**: 代码难以理解和维护，导致需要不断进行小的修复和调整。
-   **设计缺陷**: “牵一发而动全身”，修改一个地方需要连锁改动这些文件。

通过 `find-hot-files` 识别出这些文件，可以帮助您和您的团队快速定位代码审查、重构和优化的重点区域，从而更有效地提升代码质量。

## 如何使用

在您本地 Git 项目的根目录下打开终端，然后运行对应的脚本。

### Windows (PowerShell)

默认分析最近 500 次提交：
```powershell
f:\Deving\MiniTools\GitTools\win\find-hot-files.ps1
```

指定分析最近 1000 次提交：
```powershell
f:\Deving\MiniTools\GitTools\win\find-hot-files.ps1 -CommitLimit 1000
```

### Unix/Linux/macOS (Bash)

首次使用请确保脚本有执行权限：

```bash
chmod +x f:/Deving/MiniTools/GitTools/unix/find-hot-files.sh
```

默认分析最近 500 次提交：
```bash
f:/Deving/MiniTools/GitTools/unix/find-hot-files.sh
```

指定分析最近 1000 次提交：
```bash
f:/Deving/MiniTools/GitTools/unix/find-hot-files.sh 1000
```
