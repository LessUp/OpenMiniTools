[CmdletBinding(DefaultParameterSetName = 'Help')]
[OutputType([void])]
param(
    # --- General Management (from wsl-manager) ---
    [Parameter(ParameterSetName = 'List')]
    [switch]$List,

    [Parameter(ParameterSetName = 'Status')]
    [switch]$Status,

    [Parameter(ParameterSetName = 'Start')]
    [string]$Start,

    [Parameter(ParameterSetName = 'Stop')]
    [string]$Stop,

    [Parameter(ParameterSetName = 'SetDefault')]
    [string]$SetDefault,

    [Parameter(ParameterSetName = 'Install')]
    [string]$Install,

    [Parameter(ParameterSetName = 'Uninstall')]
    [string]$Uninstall,

    [Parameter(ParameterSetName = 'Update')]
    [switch]$Update,

    # --- Backup & Restore ---
    [Parameter(ParameterSetName = 'Backup')]
    [string]$Backup,

    [Parameter(ParameterSetName = 'BackupAll')]
    [switch]$BackupAll,

    [Parameter(ParameterSetName = 'Restore')]
    [string]$Restore,

    [Parameter(ParameterSetName = 'ListBackups')]
    [switch]$ListBackups,

    # --- Disk Management ---
    [Parameter(ParameterSetName = 'DiskUsage')]
    [switch]$ShowDiskUsage,

    [Parameter(ParameterSetName = 'CompactDisk')]
    [string]$CompactDisk,

    # --- Network Management ---
    [Parameter(ParameterSetName = 'GetIP')]
    [string]$GetIP,

    [Parameter(ParameterSetName = 'AddPortForward')]
    [switch]$AddPortForward,

    [Parameter(ParameterSetName = 'RemovePortForward')]
    [switch]$RemovePortForward,

    [Parameter(ParameterSetName = 'RepairDNS')]
    [string]$RepairDNS,

    [Parameter(ParameterSetName = 'ResetNetwork')]
    [switch]$ResetNetwork,

    # --- Config Management ---
    [Parameter(ParameterSetName = 'ShowConfig')]
    [switch]$ShowConfig,

    [Parameter(ParameterSetName = 'SetVersion')]
    [ValidateSet(1, 2)]
    [int]$SetVersion,

    [Parameter(ParameterSetName = 'ConfigureMemory')]
    [string]$ConfigureMemory,

    [Parameter(ParameterSetName = 'ConfigureProcessors')]
    [int]$ConfigureProcessors,

    # --- Common Options ---
    [Parameter(ParameterSetName = 'Backup')]
    [Parameter(ParameterSetName = 'BackupAll')]
    [Parameter(ParameterSetName = 'Restore')]
    [Parameter(ParameterSetName = 'ListBackups')]
    [string]$Path = '.\backups',

    [Parameter(ParameterSetName = 'Backup')]
    [Parameter(ParameterSetName = 'BackupAll')]
    [int]$KeepLast = 5,

    [Parameter(ParameterSetName = 'Restore')]
    [string]$FromFile,

    [Parameter(ParameterSetName = 'Restore')]
    [string]$As, # New name for restored distro

    [Parameter(ParameterSetName = 'AddPortForward')]
    [Parameter(ParameterSetName = 'RemovePortForward')]
    [int]$ListenPort,

    [Parameter(ParameterSetName = 'AddPortForward')]
    [int]$ForwardPort,

    [Parameter(ParameterSetName = 'AddPortForward')]
    [Parameter(ParameterSetName = 'RepairDNS')]
    [string]$Distro,

    [Parameter(ParameterSetName = 'Help')]
    [switch]$Help
)

# --- Script Initialization ---
function Show-AdminHelp {
    Write-Host "WSL 管理工具集 - 统一入口" -ForegroundColor Yellow
    Write-Host "用法: .\wsl-admin.ps1 [-Command] [Options...]`n"

    Write-Host "常规管理:"
    Write-Host "  -List                      列出所有已安装的发行版"
    Write-Host "  -Status                    查看WSL状态"
    Write-Host "  -Start <Distro>            启动指定的发行版"
    Write-Host "  -Stop <Distro>             停止指定的发行版 (使用 'all' 停止所有)"
    Write-Host "  -SetDefault <Distro>       设置默认发行版"
    Write-Host "  -Install [Distro]          安装新的发行版"
    Write-Host "  -Uninstall <Distro>        卸载一个发行版"
    Write-Host "  -Update                    更新WSL核心组件`n"

    Write-Host "备份与恢复:"
    Write-Host "  -Backup <Distro> -Path <...>  备份指定发行版"
    Write-Host "  -BackupAll -Path <...>     备份所有发行版"
    Write-Host "  -Restore <Distro> -FromFile <...> [-As <NewName>] 恢复发行版"
    Write-Host "  -ListBackups -Path <...>   列出目录中的备份`n"

    Write-Host "磁盘管理:"
    Write-Host "  -ShowDiskUsage             显示所有发行版的磁盘使用情况"
    Write-Host "  -CompactDisk <Distro>      压缩指定发行版的虚拟磁盘`n"

    Write-Host "网络管理:"
    Write-Host "  -GetIP <Distro>            获取发行版的IP地址"
    Write-Host "  -AddPortForward -ListenPort <p1> -ForwardPort <p2> -Distro <d> 添加端口转发"
    Write-Host "  -RemovePortForward -ListenPort <p1> 移除端口转发"
    Write-Host "  -RepairDNS <Distro>        尝试修复DNS问题"
    Write-Host "  -ResetNetwork              重置WSL网络`n"

    Write-Host "配置管理:"
    Write-Host "  -ShowConfig                显示当前WSL配置"
    Write-Host "  -SetVersion <1|2>          设置默认WSL版本"
    Write-Host "  -ConfigureMemory <Size>    配置WSL内存限制 (如 '4GB')"
    Write-Host "  -ConfigureProcessors <Num> 配置WSL处理器数量`n"

    Write-Host "使用 -Help 查看此帮助信息。"
}

try {
    $scriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
    . "$scriptRoot\wsl-manager.ps1"
    . "$scriptRoot\wsl-config.ps1"
    . "$scriptRoot\wsl-backup-restore.ps1"
    . "$scriptRoot\wsl-disk-manager.ps1"
    . "$scriptRoot\wsl-network.ps1"
} catch {
    Write-Host "错误：无法加载一个或多个模块脚本。请确保所有脚本都在同一目录下。" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# --- Main Command Dispatcher ---
if (-not (Test-WSLInstalled)) {
    exit 1
}

switch ($PSCmdlet.ParameterSetName) {
    'List'                { List-WSLDistros }
    'Status'              { Get-WSLStatus }
    'Start'               { Start-WSLDistro -distroName $Start }
    'Stop'                { Stop-WSLDistro -distroName $Stop }
    'SetDefault'          { Set-DefaultWSL -distroName $SetDefault }
    'Install'             { Install-WSLDistro -distroName $Install }
    'Uninstall'           { Uninstall-WSLDistro -distroName $Uninstall }
    'Update'              { Update-WSL }

    'Backup'              { Backup-SingleDistro -distroName $Backup -backupPath $Path -keepLast $KeepLast }
    'BackupAll'           { 
        $distros = wsl --list --quiet
        foreach ($d in $distros) {
            Backup-SingleDistro -distroName $d -backupPath $Path -keepLast $KeepLast
        }
    }
    'Restore'             { Restore-WSLDistro -distroName $Restore -restoreFile $FromFile -newDistroName $As }
    'ListBackups'         { Get-AvailableBackups -backupPath $Path }

    'DiskUsage'           { Show-DistroDiskUsage }
    'CompactDisk'         { Invoke-WSLDiskCompact -distroName $CompactDisk }

    'GetIP'               { Get-WSLIPAddress -distroName $GetIP }
    'AddPortForward'      { Add-WSLPortForward -listenPort $ListenPort -forwardPort $ForwardPort -distroName $Distro }
    'RemovePortForward'   { Remove-WSLPortForward -listenPort $ListenPort }
    'RepairDNS'           { Repair-WSLDNS -distroName $Distro }
    'ResetNetwork'        { Reset-WSLNetwork }

    'ShowConfig'          { Show-WSLConfig }
    'SetVersion'          { Set-WSLVersion -version $SetVersion }
    'ConfigureMemory'     { Set-WSLMemory -memoryLimit $ConfigureMemory }
    'ConfigureProcessors' { Set-WSLProcessors -processorCount $ConfigureProcessors }

    'Help'                { Show-AdminHelp }
    default               { Show-AdminHelp }
}
