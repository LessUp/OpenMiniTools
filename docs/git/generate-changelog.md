# `generate-changelog` - 约定式更新日志生成器

## 功能简介

`generate-changelog` 是一个强大的自动化工具，它能根据您项目的 Git 提交历史，自动生成一份专业、规范的更新日志 (Changelog)。

该工具的核心是遵循业界广泛采用的 **“约定式提交” (Conventional Commits)** 规范。它通过解析标准化的 commit message，智能地将变更分类，从而免去了手动整理和编写更新日志的繁琐工作。

## 核心功能

-   **自动化扫描**: 自动查找 Git 历史，支持指定任意两个引用（标签、commit hash 或分支名）作为日志生成的范围。
-   **智能分类**: 根据 commit message 的前缀（如 `feat:`, `fix:`, `perf:` 等），将提交自动归类到“新功能”、“Bug 修复”、“性能优化”等章节中。
-   **格式化输出**: 生成一个结构清晰、格式优美的 Markdown 文件，可直接用于 GitHub Releases、项目文档或团队通告。
-   **推动规范**: 鼓励团队成员采用规范化的提交信息，提升代码历史的可读性和项目的长期可维护性。

## “约定式提交”简介

约定式提交是一种轻量级的提交信息规范，格式如下：

```
<类型>[可选的作用域]: <描述>
```

-   **类型 (type)**: 必须是 `feat`, `fix`, `perf`, `docs`, `refactor` 等预定义关键字中的一个。
-   **作用域 (scope)**: 可选，用于描述本次提交影响的范围（如某个模块或组件名）。
-   **描述 (description)**: 对本次提交的简短描述。

**示例:**

```
git commit -m "feat(api): add user authentication endpoint"
git commit -m "fix: correct calculation error in payment module"
```

采纳此规范能让提交历史变得像机器可读的 API，从而为自动化工具（如本脚本）提供了可能。

## 如何使用

在您本地 Git 项目的根目录下打开终端，然后运行对应的脚本。

脚本会引导您输入日志的**起始引用**和**结束引用**。通常，您可以：
-   从上一个版本标签生成到 `HEAD` (当前最新)。
-   比较任意两个版本标签之间的差异。

### Windows (PowerShell)

```powershell
f:\Deving\OpenMiniTools\GitTools\win\generate-changelog.ps1
```

### Unix/Linux/macOS (Bash)

首次使用请确保脚本有执行权限：

```bash
chmod +x f:/Deving/OpenMiniTools/GitTools/unix/generate-changelog.sh
```

然后运行脚本：

```bash
f:/Deving/OpenMiniTools/GitTools/unix/generate-changelog.sh
```

脚本运行后，会在项目根目录生成一个 `CHANGELOG_new.md` 文件。
