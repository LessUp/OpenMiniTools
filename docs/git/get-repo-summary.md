# `get-repo-summary` - Git 仓库摘要工具

## 功能简介

`get-repo-summary` 是一个用于快速分析任何 Git 项目概况的脚本。它会扫描当前仓库，并以清晰、简洁的格式展示项目的核心信息，帮助您在几秒钟内了解一个项目的基本状态。

## 核心功能

-   **贡献者统计**: 按提交次数降序列出所有项目贡献者。
-   **关键指标**: 显示总提交数、本地分支数以及最新的 Git 标签。
-   **提交活跃度**: 生成一个基于文本的图表，直观展示最近 12 周的每周提交频率，快速发现项目的活跃期和迭代周期。

## 如何使用

在您本地 Git 项目的根目录下打开终端，然后运行对应的脚本。

### Windows (PowerShell)

```powershell
f:\Deving\MiniTools\GitTools\win\get-repo-summary.ps1
```

### Unix/Linux/macOS (Bash)

首次使用请确保脚本有执行权限：

```bash
chmod +x f:/Deving/MiniTools/GitTools/unix/get-repo-summary.sh
```

然后运行脚本：

```bash
f:/Deving/MiniTools/GitTools/unix/get-repo-summary.sh
```

## 输出示例

运行后，您将看到类似下面的报告：

```
--- Git 仓库摘要: MiniTools ---

[+] 贡献者统计 (按提交次数排序):
  - Cascade-AI              : 15 提交
  - John Doe                : 8 提交

[+] 关键指标:
  - 总提交数  : 23
  - 本地分支数: 5
  - 最新标签  : v1.2.0

[+] 提交活跃度 (最近12周):
  2025-04-01 | ####################                     (10 提交)
  2025-04-08 | ##########                               (5 提交)
  2025-04-15 |                                          (0 提交)
  ...

--- 摘要生成完毕 ---
```
