# WSL 统一管理工具集

这是一个通过单一入口点 (`wsl-admin.ps1`) 管理Windows Subsystem for Linux (WSL)的综合性PowerShell脚本工具集。

## 核心设计

- **统一入口**: 所有功能都通过 `wsl-admin.ps1` 调用，无需记忆多个脚本名称。
- **模块化**: 每个核心功能（如常规管理、备份、磁盘、网络）都封装在独立的模块脚本中，易于维护和扩展。
- **参数化命令**: 使用清晰的参数来执行特定任务，支持Tab自动补全。

## 文件结构

- `wsl-admin.ps1`: **主执行脚本**，所有操作的唯一入口。
- `wsl-manager.ps1`: (模块) 提供基础的启停、安装卸载等功能。
- `wsl-config.ps1`: (模块) 专门用于管理WSL全局配置 (`.wslconfig`)。
- `wsl-backup-restore.ps1`: (模块) 提供高级的备份和恢复功能。
- `wsl-disk-manager.ps1`: (模块) 用于管理WSL2虚拟磁盘空间。
- `wsl-network.ps1`: (模块) 用于管理和排查WSL网络问题。
- `README.md`: 本说明文件。

## 如何使用

所有命令都通过 `wsl-admin.ps1` 执行。打开PowerShell，导航到脚本目录，然后使用以下命令格式：

`..\wsl-admin.ps1 -<命令> [参数]`

**重要提示:** 许多操作需要**管理员权限**才能运行。请在管理员模式下的PowerShell中执行这些命令。

--- 

### **常用命令示例**

#### 常规管理

- **列出所有发行版:**
  ```powershell
  .\wsl-admin.ps1 -List
  ```

- **查看WSL状态:**
  ```powershell
  .\wsl-admin.ps1 -Status
  ```

- **启动一个发行版:**
  ```powershell
  .\wsl-admin.ps1 -Start Ubuntu
  ```

- **停止所有发行版:**
  ```powershell
  .\wsl-admin.ps1 -Stop all
  ```

- **设置默认发行版:**
  ```powershell
  .\wsl-admin.ps1 -SetDefault Ubuntu-22.04
  ```

#### 备份与恢复

- **备份单个发行版 (自动轮换，保留最近5个):**
  ```powershell
  .\wsl-admin.ps1 -Backup Ubuntu -Path .\backups
  ```

- **从指定文件恢复发行版:**
  ```powershell
  .\wsl-admin.ps1 -Restore Ubuntu -FromFile .\backups\Ubuntu_20250624_223000.tar
  ```

- **恢复并重命名:**
  ```powershell
  .\wsl-admin.ps1 -Restore Ubuntu -FromFile <path> -As Ubuntu-restored
  ```

#### 磁盘管理 (需要管理员权限)

- **查看所有发行版的磁盘使用情况:**
  ```powershell
  .\wsl-admin.ps1 -ShowDiskUsage
  ```

- **压缩一个发行版的磁盘 (操作前会关闭WSL):**
  ```powershell
  .\wsl-admin.ps1 -CompactDisk Ubuntu
  ```

#### 网络管理 (需要管理员权限)

- **获取发行版的IP地址:**
  ```powershell
  .\wsl-admin.ps1 -GetIP Ubuntu
  ```

- **添加端口转发 (主机8080 -> WSL 80):**
  ```powershell
  .\wsl-admin.ps1 -AddPortForward -ListenPort 8080 -ForwardPort 80 -Distro Ubuntu
  ```

- **修复DNS问题:**
  ```powershell
  .\wsl-admin.ps1 -RepairDNS Ubuntu
  ```

#### 全局配置管理

- **显示当前 `.wslconfig` 配置:**
  ```powershell
  .\wsl-admin.ps1 -ShowConfig
  ```

- **设置WSL2内存上限为8GB:**
  ```powershell
  .\wsl-admin.ps1 -ConfigureMemory 8GB
  ```

- **设置WSL2处理器数量为4:**
  ```powershell
  .\wsl-admin.ps1 -ConfigureProcessors 4
  ```

## 贡献

欢迎提出改进建议和代码贡献！
