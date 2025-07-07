#!/bin/bash
# Ubuntu数据库管理工具
# 用法: ./11-db-manager.sh [操作] [参数]
# 操作: status, backup, restore, mysql-optimize, postgres-optimize

# 显示帮助信息
show_help() {
  echo "Ubuntu数据库管理工具"
  echo "用法: $0 [操作] [参数]"
  echo "操作:"
  echo "  status                 - 显示数据库服务状态"
  echo "  backup <类型> <名称>   - 备份数据库 (类型: mysql/postgres)"
  echo "  restore <类型> <文件> <名称> - 恢复数据库"
  echo "  mysql-optimize         - 优化MySQL数据库"
  echo "  postgres-optimize      - 优化PostgreSQL数据库"
  echo "例如: "
  echo "  $0 backup mysql mydatabase"
  echo "  $0 restore mysql backup_file.sql mydatabase"
}

# 检查是否为root用户
check_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "警告: 某些操作可能需要root权限"
    echo "建议使用: sudo $0 $*"
  fi
}

# 检查MySQL是否安装
check_mysql() {
  if ! command -v mysql &> /dev/null; then
    echo "错误: MySQL未安装"
    echo "请安装MySQL: sudo apt install -y mysql-server"
    return 1
  fi
  return 0
}

# 检查PostgreSQL是否安装
check_postgres() {
  if ! command -v psql &> /dev/null; then
    echo "错误: PostgreSQL未安装"
    echo "请安装PostgreSQL: sudo apt install -y postgresql postgresql-contrib"
    return 1
  fi
  return 0
}

# 显示数据库状态
db_status() {
  echo "===== 数据库服务状态 ====="
  
  echo "MySQL状态:"
  if check_mysql; then
    systemctl status mysql --no-pager | head -n 5
    echo "MySQL版本:"
    mysql --version
    
    echo "MySQL数据库列表:"
    mysql -e "SHOW DATABASES;" 2>/dev/null || echo "无法获取数据库列表，可能需要权限"
  else
    echo "MySQL未安装"
  fi
  
  echo -e "\nPostgreSQL状态:"
  if check_postgres; then
    systemctl status postgresql --no-pager | head -n 5
    echo "PostgreSQL版本:"
    psql --version
    
    echo "PostgreSQL数据库列表:"
    sudo -u postgres psql -c "\l" 2>/dev/null || echo "无法获取数据库列表，可能需要权限"
  else
    echo "PostgreSQL未安装"
  fi
}

# 备份数据库
db_backup() {
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "错误: 缺少参数"
    echo "用法: $0 backup <类型> <名称>"
    echo "例如: $0 backup mysql mydatabase"
    return 1
  fi
  
  DB_TYPE="$1"
  DB_NAME="$2"
  BACKUP_DIR="$HOME/db_backups"
  TIMESTAMP=$(date +%Y%m%d_%H%M%S)
  
  # 创建备份目录
  mkdir -p "$BACKUP_DIR"
  
  case "$DB_TYPE" in
    "mysql")
      if ! check_mysql; then
        return 1
      fi
      
      BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_mysql_${TIMESTAMP}.sql"
      echo "正在备份MySQL数据库 '$DB_NAME' 到 $BACKUP_FILE..."
      
      mysqldump "$DB_NAME" > "$BACKUP_FILE" 2>/dev/null
      
      if [ $? -eq 0 ]; then
        echo "备份成功: $BACKUP_FILE"
        echo "备份大小: $(du -h "$BACKUP_FILE" | cut -f1)"
      else
        echo "备份失败，请检查数据库名称和权限"
      fi
      ;;
      
    "postgres")
      if ! check_postgres; then
        return 1
      fi
      
      BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_postgres_${TIMESTAMP}.sql"
      echo "正在备份PostgreSQL数据库 '$DB_NAME' 到 $BACKUP_FILE..."
      
      sudo -u postgres pg_dump "$DB_NAME" > "$BACKUP_FILE" 2>/dev/null
      
      if [ $? -eq 0 ]; then
        echo "备份成功: $BACKUP_FILE"
        echo "备份大小: $(du -h "$BACKUP_FILE" | cut -f1)"
      else
        echo "备份失败，请检查数据库名称和权限"
      fi
      ;;
      
    *)
      echo "未知的数据库类型: $DB_TYPE"
      echo "支持的类型: mysql, postgres"
      return 1
      ;;
  esac
}

# 恢复数据库
db_restore() {
  if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "错误: 缺少参数"
    echo "用法: $0 restore <类型> <文件> <名称>"
    echo "例如: $0 restore mysql backup_file.sql mydatabase"
    return 1
  fi
  
  DB_TYPE="$1"
  BACKUP_FILE="$2"
  DB_NAME="$3"
  
  # 检查备份文件
  if [ ! -f "$BACKUP_FILE" ]; then
    echo "错误: 备份文件不存在: $BACKUP_FILE"
    return 1
  fi
  
  case "$DB_TYPE" in
    "mysql")
      if ! check_mysql; then
        return 1
      fi
      
      echo "正在恢复MySQL数据库 '$DB_NAME' 从 $BACKUP_FILE..."
      
      # 检查数据库是否存在，如果不存在则创建
      mysql -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;" 2>/dev/null
      
      if [ $? -ne 0 ]; then
        echo "创建数据库失败，请检查权限"
        return 1
      fi
      
      # 恢复数据库
      mysql "$DB_NAME" < "$BACKUP_FILE" 2>/dev/null
      
      if [ $? -eq 0 ]; then
        echo "恢复成功"
      else
        echo "恢复失败，请检查文件格式和权限"
      fi
      ;;
      
    "postgres")
      if ! check_postgres; then
        return 1
      fi
      
      echo "正在恢复PostgreSQL数据库 '$DB_NAME' 从 $BACKUP_FILE..."
      
      # 检查数据库是否存在，如果不存在则创建
      sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;" 2>/dev/null
      
      # 恢复数据库
      sudo -u postgres psql "$DB_NAME" < "$BACKUP_FILE" 2>/dev/null
      
      if [ $? -eq 0 ]; then
        echo "恢复成功"
      else
        echo "恢复失败，请检查文件格式和权限"
      fi
      ;;
      
    *)
      echo "未知的数据库类型: $DB_TYPE"
      echo "支持的类型: mysql, postgres"
      return 1
      ;;
  esac
}

# 优化MySQL数据库
mysql_optimize() {
  if ! check_mysql; then
    return 1
  fi
  
  echo "===== MySQL数据库优化 ====="
  
  echo "1. 优化所有数据库表..."
  mysql -e "SELECT CONCAT('OPTIMIZE TABLE ', table_schema, '.', table_name, ';') FROM information_schema.tables WHERE table_schema NOT IN ('information_schema', 'mysql', 'performance_schema') INTO OUTFILE '/tmp/optimize_tables.sql';" 2>/dev/null
  
  if [ -f "/tmp/optimize_tables.sql" ]; then
    mysql < "/tmp/optimize_tables.sql" 2>/dev/null
    rm -f "/tmp/optimize_tables.sql"
  else
    echo "无法生成优化脚本，可能需要权限"
  fi
  
  echo "2. 显示MySQL状态信息..."
  mysql -e "SHOW STATUS WHERE Variable_name IN ('Threads_connected', 'Threads_running', 'Connections', 'Queries', 'Slow_queries', 'Uptime');" 2>/dev/null
  
  echo "3. MySQL优化建议:"
  echo "- 检查慢查询日志: /var/log/mysql/mysql-slow.log"
  echo "- 调整my.cnf配置参数:"
  echo "  * innodb_buffer_pool_size: 设置为系统内存的50-80%"
  echo "  * max_connections: 根据同时连接数调整"
  echo "  * query_cache_size: 可以适当提高查询缓存"
}

# 优化PostgreSQL数据库
postgres_optimize() {
  if ! check_postgres; then
    return 1
  fi
  
  echo "===== PostgreSQL数据库优化 ====="
  
  echo "1. 执行VACUUM操作..."
  sudo -u postgres psql -c "VACUUM ANALYZE;" 2>/dev/null || echo "VACUUM操作失败，可能需要权限"
  
  echo "2. 显示PostgreSQL统计信息..."
  sudo -u postgres psql -c "SELECT datname, numbackends, xact_commit, xact_rollback, blks_read, blks_hit FROM pg_stat_database;" 2>/dev/null
  
  echo "3. PostgreSQL优化建议:"
  echo "- 调整postgresql.conf配置参数:"
  echo "  * shared_buffers: 设置为系统内存的25%"
  echo "  * effective_cache_size: 设置为系统内存的50%"
  echo "  * work_mem: 根据复杂查询需求调整"
  echo "  * maintenance_work_mem: 用于维护操作的内存"
}

# 主函数
main() {
  # 如果没有参数，显示帮助
  if [ -z "$1" ]; then
    show_help
    exit 1
  fi
  
  # 检查权限
  check_root "$@"
  
  # 根据参数执行相应功能
  case "$1" in
    "status")
      db_status
      ;;
    "backup")
      db_backup "$2" "$3"
      ;;
    "restore")
      db_restore "$2" "$3" "$4"
      ;;
    "mysql-optimize")
      mysql_optimize
      ;;
    "postgres-optimize")
      postgres_optimize
      ;;
    *)
      echo "未知操作: $1"
      show_help
      exit 1
      ;;
  esac
}

# 执行主函数
main "$@"
