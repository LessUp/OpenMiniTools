# generate-changelog.ps1 (Windows - PowerShell)
<#
.SYNOPSIS
    根据 Git 提交历史自动生成更新日志 (Changelog)。

.DESCRIPTION
    此脚本遵循“约定式提交”规范，扫描两个 Git 引用之间的提交，
    并将它们自动分类为新功能 (Features)、修复 (Fixes) 等，
    最终生成一个格式优美的 Markdown 文件。

.EXAMPLE
    .\generate-changelog.ps1
    # 脚本会自动查找最新的标签，并生成从该标签到 HEAD 的更新日志。
#>

# --- 函数定义 ---

# 检查是否在 git 仓库中
function Test-GitRepository {
    git rev-parse --is-inside-work-tree | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "错误: 当前目录不是一个 Git 仓库。" -ForegroundColor Red
        exit 1
    }
}

# --- 主逻辑 ---

try {
    Test-GitRepository

    # --- 1. 获取 Git 引用范围 ---
    $latestTag = try { git describe --tags --abbrev=0 } catch { $null }
    if ($null -eq $latestTag) {
        Write-Warning "未找到任何标签。将从最初的提交开始生成日志。"
        $startRef = git rev-list --max-parents=0 HEAD
    } else {
        Write-Host "找到最新标签: $latestTag" -ForegroundColor Green
        $startRef = $latestTag
    }

    $userStartRef = Read-Host -Prompt "请输入起始引用 (默认为: $startRef)"
    if (-not [string]::IsNullOrWhiteSpace($userStartRef)) {
        $startRef = $userStartRef
    }

    $endRef = "HEAD"
    $userEndRef = Read-Host -Prompt "请输入结束引用 (默认为: HEAD)"
    if (-not [string]::IsNullOrWhiteSpace($userEndRef)) {
        $endRef = $userEndRef
    }

    Write-Host "正在生成从 '$startRef' 到 '$endRef' 的更新日志..." -ForegroundColor Cyan

    # --- 2. 定义提交类型和标题 ---
    $commitTypes = [ordered]@{
        feat     = '✨ 新功能 (Features)';
        fix      = '🐛 Bug 修复 (Bug Fixes)';
        perf     = '⚡ 性能优化 (Performance Improvements)';
        refactor = '♻️ 代码重构 (Code Refactoring)';
        docs     = '📚 文档更新 (Documentation)';
        style    = '💎 代码风格 (Styles)';
        test     = '✅ 测试相关 (Tests)';
        build    = '📦 构建系统 (Builds)';
        ci       = '🔁 持续集成 (Continuous Integration)';
        chore    = '🔧 其他杂项 (Chores)';
    }

    # --- 3. 获取并分类提交 ---
    $commits = git log --pretty=format:"%s" "${startRef}..${endRef}" --no-merges
    $categorizedCommits = @{}

    foreach ($commit in $commits) {
        if ($commit -match '^(\w+)(?:\((.+)\))?!?:\s(.+)') {
            $type = $matches[1]
            $scope = if ($matches[2]) { "**$($matches[2])**: " } else { "" }
            $subject = $matches[3]

            if ($commitTypes.Contains($type)) {
                $formattedMessage = "- $scope$subject"
                if (-not $categorizedCommits.Contains($type)) {
                    $categorizedCommits[$type] = [System.Collections.Generic.List[string]]@()
                }
                $categorizedCommits[$type].Add($formattedMessage)
            }
        }
    }

    # --- 4. 生成 Markdown 内容 ---
    $outputFile = "CHANGELOG_new.md"
    $changelogContent = @()
    $newVersion = (git describe --tags $endRef 2>$null) -replace '^v', ''
    if ([string]::IsNullOrWhiteSpace($newVersion)) { $newVersion = "Unreleased" }
    $changelogContent += "# Changelog - $newVersion ($((Get-Date).ToString('yyyy-MM-dd')))"
    $changelogContent += ""

    $hasContent = $false
    foreach ($type in $commitTypes.Keys) {
        if ($categorizedCommits.Contains($type)) {
            $hasContent = $true
            $changelogContent += "### $($commitTypes[$type])"
            $changelogContent += ""
            $changelogContent += $categorizedCommits[$type]
            $changelogContent += ""
        }
    }

    if (-not $hasContent) {
        Write-Host "`n在指定范围内没有找到符合约定式提交规范的记录。" -ForegroundColor Yellow
        exit 0
    }

    # --- 5. 写入文件 ---
    Set-Content -Path $outputFile -Value ($changelogContent | Out-String)
    Write-Host "`n成功生成更新日志: $outputFile" -ForegroundColor Green

}
catch {
    Write-Error "发生未知错误。请确保 git 已安装并且在您的 PATH 环境变量中。"
}
