# Monitor Off Tool

一个简单的Windows工具，用于快速关闭显示器。

## 功能

- 一键关闭显示器，无需进行其他操作
- 轻量级应用，执行速度快
- 无需安装，可直接运行

## 使用方法

1. 运行 `build.bat` 编译程序
2. 编译成功后，双击 `MonitorOff.exe` 即可关闭显示器
3. 您也可以创建该程序的快捷方式放在桌面，方便随时使用

## 技术细节

该工具使用Windows API中的SendMessage函数配合SC_MONITORPOWER参数来控制显示器电源状态。
