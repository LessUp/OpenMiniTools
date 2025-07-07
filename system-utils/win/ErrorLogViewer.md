# Windows 错误日志查看器 (Windows Error Log Viewer)

这个工具集提供了两种方式来快速查看 Windows 系统的错误日志：PowerShell 脚本和 GUI 应用程序。

## PowerShell 脚本版本 (ErrorLogViewer.ps1)

这是一个功能强大的 PowerShell 脚本，可以从命令行快速查询系统日志。

### 使用方法

基本用法（查看过去 24 小时的系统错误日志）:
```powershell
.\ErrorLogViewer.ps1
```

高级用法:
```powershell
.\ErrorLogViewer.ps1 -LogName "Application" -Level "Warning" -HoursBack 48 -MaxEvents 100
```

### 参数说明

- `-LogName`: 日志名称，默认为"System"。可选值包括："System", "Application", "Security"等
- `-Level`: 日志级别，默认为"Error"。可选值："Error", "Warning", "Information", "All"
- `-HoursBack`: 查询过去多少小时内的日志，默认为24小时
- `-MaxEvents`: 最多显示的事件数量，默认为50
- `-ExportPath`: 导出日志到CSV文件的路径（可选）

## C# GUI 应用程序 (ErrorLogViewer.exe)

提供了图形界面，方便用户进行交互式操作。

### 使用方法

1. 编译应用程序:
   ```
   .\build_error_log_viewer.bat
   ```

2. 运行生成的可执行文件:
   ```
   .\ErrorLogViewer.exe
   ```

### 主要功能

- 选择日志源（System、Application等）
- 按级别筛选（Error、Warning、Information、All）
- 设置时间范围（过去多少小时）
- 限制显示的日志数量
- 导出日志到CSV文件

## 系统要求

- PowerShell 脚本：Windows PowerShell 3.0 或更高版本
- C# 应用程序：.NET Framework 4.0 或更高版本
