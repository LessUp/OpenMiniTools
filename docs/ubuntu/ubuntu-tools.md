# Ubuntu开发工具集

这是一系列用于Ubuntu系统的开发辅助工具，旨在提高开发效率和系统维护便捷性。

## 工具列表

### 系统与环境配置

1. **依赖安装工具** - `01-install-deps.sh`
   - 安装基础开发环境依赖组件
   - 用法: `./01-install-deps.sh`

2. **SSH配置工具** - `02-setup-ssh.sh`
   - 生成并配置SSH密钥
   - 用法: `./02-setup-ssh.sh`

3. **系统监控工具** - `03-system-monitor.sh`
   - 全面监控系统资源使用情况
   - 用法: `./03-system-monitor.sh`

4. **网络诊断工具** - `04-network-diagnosis.sh`
   - 诊断网络连接问题
   - 用法: `./04-network-diagnosis.sh [主机名]`

5. **开发环境快速配置工具** - `05-setup-dev-env.sh`
   - 快速配置各种开发环境
   - 用法: `./05-setup-dev-env.sh [环境类型]`
   - 环境类型: web, python, java, nodejs, go, docker, all

6. **备份与恢复工具** - `06-backup-restore.sh`
   - 文件备份与恢复
   - 用法:
     - 备份: `./06-backup-restore.sh backup <源目录> <目标目录>`
     - 恢复: `./06-backup-restore.sh restore <备份文件> <目标目录>`

7. **性能优化工具** - `07-performance-tune.sh`
   - 系统性能优化
   - 用法: `./07-performance-tune.sh [选项]`
   - 选项: clean, swap, services, all

### 开发与服务管理

8. **Docker管理工具** - `08-docker-manager.sh`
   - 简化Docker容器和镜像管理
   - 用法: `./08-docker-manager.sh [操作]`
   - 操作: status, clean, start, stop, restart, logs

9. **日志分析工具** - `09-log-analyzer.sh`
   - 分析系统和应用日志
   - 用法: `./09-log-analyzer.sh [日志文件路径] [选项]`
   - 选项: errors, warnings, all

10. **防火墙管理工具** - `10-firewall-manager.sh`
    - 管理UFW防火墙规则
    - 用法: `./10-firewall-manager.sh [操作] [参数]`
    - 操作: status, enable, disable, list, allow, deny, delete

11. **数据库管理工具** - `11-db-manager.sh`
    - MySQL和PostgreSQL数据库管理
    - 用法: `./11-db-manager.sh [操作] [参数]`
    - 操作: status, backup, restore, mysql-optimize, postgres-optimize

### Docker 高级管理

12. **Docker高级管理工具** - `12-docker-advanced.sh`
    - 提供Docker的详细信息、统计和深度清理功能
    - 用法: `./12-docker-advanced.sh [操作]`
    - 操作: info, prune, stats, top, inspect, network, volumes

13. **Docker镜像迁移工具** - `13-docker-image-transfer.sh`
    - 支持将Docker镜像保存、加载或通过SSH传输到远程主机
    - 用法: `./13-docker-image-transfer.sh [操作] [参数]`
    - 操作: list, save, load, transfer, registry

14. **Docker容器迁移工具** - `14-docker-container-migrate.sh`
    - 支持将整个容器（文件系统和元数据）导出和导入
    - 用法: `./14-docker-container-migrate.sh [操作] [参数]`
    - 操作: export, import

15. **Docker故障排查工具** - `15-docker-troubleshoot.sh`
    - 帮助诊断Docker守护进程、容器、网络和存储问题
    - 用法: `./15-docker-troubleshoot.sh [操作] [参数]`
    - 操作: check-daemon, check-container, check-network, check-storage, check-permissions, full-check

## 使用方法

1. 确保所有脚本有执行权限:
   ```bash
   chmod +x ./unix/*.sh
   ```

2. 直接执行所需的工具脚本:
   ```bash
   ./unix/03-system-monitor.sh
   ```

3. 大多数工具支持不带参数执行，会显示帮助信息

## 注意事项

- 某些脚本需要root权限才能执行，请使用sudo运行
- 在执行修改系统配置的脚本前，建议先备份相关文件
- 这些工具主要在Ubuntu 20.04和22.04上测试，其他版本可能需要调整
