# cleanup-local-branches.ps1
#
# 一个用于清理已合并的本地 Git 分支的 PowerShell 脚本。

<#
.SYNOPSIS
    安全地清理已合并到主分支（如 main/master）的本地 Git 分支。

.DESCRIPTION
    此脚本会自动查找已经完全合并到指定主分支的本地分支，
    并提供一个交互式菜单让用户确认。它会智能地跳过当前所在的分支和主分支本身。
    支持通过参数指定主分支，并可通过 -Force 开关跳过确认，适用于自动化流程。

.PARAMETER BaseBranch
    指定用于比较的主分支名称。如果未提供，脚本将自动查找 'main' 或 'master'。

.PARAMETER Force
    如果指定此开关，脚本将跳过交互式确认，直接删除已合并的分支。请谨慎使用。

.EXAMPLE
    # 交互式清理已合并到 main 或 master 的分支
    .\cleanup-local-branches.ps1

.EXAMPLE
    # 指定 'develop' 为主分支进行清理
    .\cleanup-local-branches.ps1 -BaseBranch develop

.EXAMPLE
    # 强制删除所有已合并的分支，无需确认
    .\cleanup-local-branches.ps1 -Force
#>

param(
    [string]$BaseBranch,
    [switch]$Force
)

# --- 函数定义 ---

# 检查当前是否在 git 仓库中
function Test-IsGitRepo {
    git rev-parse --is-inside-work-tree | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "错误: 当前目录不是一个 Git 仓库。" -ForegroundColor Red
        return $false
    }
    return $true
}

# 确定要使用的主分支
function Get-MainBranch {
    param([string]$SpecifiedBranch)

    # 如果用户通过参数指定了分支，则优先使用
    if (-not [string]::IsNullOrWhiteSpace($SpecifiedBranch)) {
        # 验证指定的分支是否存在
        if (git branch -l | ForEach-Object { $_.Trim() } | Where-Object { $_ -eq $SpecifiedBranch }) {
            return $SpecifiedBranch
        } else {
            Write-Host "错误: 指定的主分支 '$SpecifiedBranch' 不存在。" -ForegroundColor Red
            return $null
        }
    }

    # 自动检测 'main' 或 'master'
    $localBranches = git branch -l | ForEach-Object { $_.Trim() }
    if ($localBranches -contains 'main') {
        return 'main'
    }
    if ($localBranches -contains 'master') {
        return 'master'
    }

    Write-Host "错误: 未找到 'main' 或 'master' 分支，请使用 -BaseBranch 参数指定一个。" -ForegroundColor Red
    return $null
}

# 获取可以被删除的分支列表
function Get-BranchesToDelete {
    param([string]$mainBranchName)

    # 获取当前所在分支
    $currentBranch = (git rev-parse --abbrev-ref HEAD).Trim()
    
    # 查找所有已合并到主分支的本地分支
    # 注意：git branch --merged 返回的列表中也包含主分支自身和当前分支（如果已合并）
    $mergedBranches = git branch --merged $mainBranchName | ForEach-Object { $_.Trim().Replace("* ","") }

    # 过滤掉主分支和当前分支，得到最终待删除列表
    $branchesToDelete = $mergedBranches | Where-Object { 
        $_ -ne $mainBranchName -and $_ -ne $currentBranch
    }
    return $branchesToDelete
}

# 确认并执行删除操作
function Confirm-And-RemoveBranches {
    param(
        [System.Array]$BranchList,
        [switch]$IsForced
    )

    if ($BranchList.Length -eq 0) {
        Write-Host "`n没有检测到可以安全删除的分支。仓库很干净！" -ForegroundColor Green
        return
    }

    Write-Host "`n以下 $($BranchList.Length) 个分支已完全合并，可以安全删除:" -ForegroundColor Yellow
    $BranchList | ForEach-Object { Write-Host "  - $_" }

    if ($IsForced) {
        Write-Host "`n检测到 -Force 参数，将直接删除..." -ForegroundColor Cyan
    } else {
        $confirmation = Read-Host -Prompt "`n您确定要删除这些分支吗? (y/n)"
        if ($confirmation.ToLower() -ne 'y') {
            Write-Host "`n操作已取消。" -ForegroundColor Yellow
            return
        }
    }

    Write-Host "`n正在删除分支..." -ForegroundColor Cyan
    foreach ($branch in $BranchList) {
        git branch -d $branch
    }
    Write-Host "`n清理完毕！" -ForegroundColor Green
}


# --- 主逻辑 ---

try {
    if (-not (Test-IsGitRepo)) { exit }

    # 1. 确定主分支
    $mainBranchNameToUse = Get-MainBranch -SpecifiedBranch $BaseBranch
    if (-not $mainBranchNameToUse) { exit }
    Write-Host "将使用 '$mainBranchNameToUse' 作为主分支进行比较。" -ForegroundColor Green

    # 2. 查找已合并的本地分支
    $branchesToDeleteList = Get-BranchesToDelete -mainBranchName $mainBranchNameToUse

    # 3. 显示、确认并执行删除
    Confirm-And-RemoveBranches -BranchList $branchesToDeleteList -IsForced:$Force
}
catch {
    Write-Error "发生未知错误。请确保 git 已安装并且在您的 PATH 环境变量中。"
}
