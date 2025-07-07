# find-large-files.ps1 (Windows - PowerShell)
<#
.SYNOPSIS
    深度扫描 Git 历史，找出仓库中体积最大的文件。

.DESCRIPTION
    此脚本会分析 .git 目录中的 packfiles，找出体积最大的对象，
    并定位它们在项目历史中的文件路径。这对于发现无意中提交的大文件、
    诊断仓库体积膨胀问题以及进行仓库瘦身至关重要。

.EXAMPLE
    .\find-large-files.ps1
    # 脚本会扫描整个仓库历史，并列出 Top 10 大文件。
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

    Write-Host "--- 大文件审查器 ---" -ForegroundColor Yellow
    Write-Host "正在深度扫描仓库历史，这可能需要一些时间..."

    # --- 1. 从 packfiles 中找到最大的对象 ---
    # 我们获取比10个更多的对象，因为其中一些可能不是文件 (blob)
    $largestObjects = git verify-pack -v .git/objects/pack/pack-*.idx | Sort-Object -Property { [long]($_ -split ' ')[2] } -Descending | Select-Object -First 30

    $results = [System.Collections.Generic.List[object]]@()

    # --- 2. 过滤出文件对象 (blob) 并找到它们的文件名 ---
    foreach ($line in $largestObjects) {
        $parts = $line.Split(' ')
        $hash = $parts[0]
        $size = [long]$parts[2]

        # 确认对象类型是 blob (文件)
        $type = git cat-file -t $hash 2>$null
        if ($type -ne 'blob') {
            continue
        }

        # 查找此 blob 对应的文件路径
        # 这可能会找到多个路径（如果文件被重命名），我们只取第一个
        $pathInfo = git rev-list --all --objects | Where-Object { $_.StartsWith($hash) } | Select-Object -First 1
        $path = if ($pathInfo) { $pathInfo.Substring(41).Trim() } else { "(路径未找到)" }
        
        # 避免重复添加同一个文件 (基于路径)
        if ($results.Path -notcontains $path) {
             $results.Add([pscustomobject]@{
                Size = $size
                Path = $path
                Hash = $hash
            })
        }

        if ($results.Count -ge 10) {
            break
        }
    }

    # --- 3. 显示结果 ---
    if ($results.Count -eq 0) {
        Write-Host "`n未在仓库历史中发现大文件。" -ForegroundColor Green
        exit 0
    }

    Write-Host "`n[+] 仓库历史中体积最大的 Top $($results.Count) 文件:" -ForegroundColor Cyan
    $results | ForEach-Object {
        $sizeInMB = "{0:N2} MB" -f ($_.Size / 1MB)
        Write-Host ("  - {0,-15} : {1}" -f $sizeInMB, $_.Path)
    }

    Write-Host "`n--- 分析完毕 ---" -ForegroundColor Yellow

}
catch {
    Write-Error "发生未知错误。请确保 git 已安装并且在您的 PATH 环境变量中。"
}
