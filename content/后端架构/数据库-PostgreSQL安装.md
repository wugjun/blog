---
title: "典籍篇"
date: 2025-11-27
description: "开源文档典籍篇汇总"
lead: "聚社区之智，传技术之火"
disable_comments: false
authorbox: true
toc: false
mathjax: true
categories:
  - "开源文档"
tags:
  - "postgresql"

#draft: true
---
[◀ 返回](/后端架构/后端架构-兵法篇/)


# 源码安装PostgreSQL稳定版本（Linux）

## 📋 准备工作

### 1. **查看最新稳定版本**
```bash
# 访问PostgreSQL官网或使用命令查看
curl -s https://www.postgresql.org/ftp/source/ | grep -E 'href="v[0-9]+\.[0-9]+/"' | tail -5

# 当前长期支持版本（LTS）
# PostgreSQL 16.x (最新稳定版)
# PostgreSQL 15.x (长期支持)
# PostgreSQL 14.x (长期支持到2026年)
# PostgreSQL 13.x (长期支持到2025年)
```

### 2. **安装编译依赖**
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y \
    build-essential \
    libreadline-dev \
    zlib1g-dev \
    flex bison \
    libxml2-dev \
    libxslt-dev \
    libssl-dev \
    libssl-dev \
    libpam0g-dev \
    libldap-dev \
    libperl-dev \
    libicu-dev \
    tcl-dev \
    python3-dev \
    git \
    wget \
    curl

# CentOS/RHEL/Rocky/AlmaLinux
sudo yum groupinstall -y "Development Tools"
sudo yum install -y \
    readline-devel \
    zlib-devel \
    flex bison \
    libxml2-devel \
    libxslt-devel \
    openssl-devel \
    pam-devel \
    openldap-devel \
    perl-devel \
    perl-ExtUtils-Embed \
    tcl-devel \
    python3-devel \
    git \
    wget
```
```shell
vi /etc/sysctl.conf
#最大共享内存段大小
kernel.shmmax = 68719476736(默认) 
 #可以使用的共享内存的总量
kernel.shmall = 4294967296(默认)
#整个系统共享内存段的最大数目
kernel.shmmni = 4096 
#每个信号对象集的最大信号对象数
kernel.sem = 50100 64128000 50100 1280 
#文件句柄的最大数量。
fs.file-max = 7672460 
#应用程序可使用的IPv4端口范围
net.ipv4.ip_local_port_range = 9000 65000 
#套接字接收缓冲区大小的缺省值
net.core.rmem_default = 1048576 
#套接字发送缓冲区大小的缺省
net.core.wmem_default = 262144 值
#套接字发送缓冲区大小的最大值
net.core.wmem_max = 1048576 

# sysctl -p #配置生效
```
## 🚀 源码安装PostgreSQL 16.2（当前稳定版）

### 步骤1：创建专用用户和目录
```bash
# 创建postgres系统用户和组
sudo groupadd -r postgres
sudo useradd -r -g postgres -s /bin/bash -d /usr/local/pgsql -m -k /dev/null postgres

# 创建安装目录和数据目录
sudo mkdir -p /usr/local/pgsql/{data,logs,backup}
sudo chown -R postgres:postgres /usr/local/pgsql
sudo chmod 750 /usr/local/pgsql

# 创建源码目录
sudo mkdir -p /opt/postgresql_src
sudo chown $(whoami):$(whoami) /opt/postgresql_src
cd /opt/postgresql_src
```

### 步骤2：下载源码
```bash
# 下载PostgreSQL 16.2（截至2024年3月的最新稳定版）
wget https://ftp.postgresql.org/pub/source/v16.2/postgresql-16.2.tar.gz

# 或者使用国内镜像（清华源）
# wget https://mirrors.tuna.tsinghua.edu.cn/postgresql/source/v16.2/postgresql-16.2.tar.gz

# 验证下载完整性（可选）
wget https://ftp.postgresql.org/pub/source/v16.2/postgresql-16.2.tar.gz.sha256
sha256sum -c postgresql-16.2.tar.gz.sha256

# 解压源码
tar -zxvf postgresql-16.2.tar.gz
cd postgresql-16.2
```

### 步骤3：配置编译选项
```bash
# 查看所有配置选项
./configure --help

# 创建编译目录（推荐）
mkdir build && cd build

# 基本配置（适用于大多数情况）
../configure \
    --prefix=/usr/local/pgsql \
    --with-pgport=5432 \
    --with-perl \
    --with-python \
    --with-tcl \
    --with-openssl \
    --with-pam \
    -with-uuid=ossp \
    --with-ldap \
    --with-libxml \
    --with-libxslt \
    --with-icu \
    --enable-thread-safety \
    --enable-debug \
    --enable-nls \
    --with-system-tzdata=/usr/share/zoneinfo
    

   

# 或者精简配置（最小化安装）
# ../configure --prefix=/usr/local/pgsql --with-openssl
```

### 步骤4：编译和安装
```bash
# 查看CPU核心数，决定并行编译数
nproc

# 编译（使用4个并行任务，根据CPU核心数调整）
make -j4

# 可选：运行回归测试（需要较长时间）
# make check

# 安装到系统
sudo make install

# 安装contrib模块（扩展工具）
cd contrib
make -j4
sudo make install
cd ..
```

### 步骤5：配置环境变量
```bash
# 为postgres用户配置环境变量
sudo tee -a /usr/local/pgsql/.bash_profile << 'EOF'
export PGHOME=/usr/local/pgsql
export PGDATA=/usr/local/pgsql/data
export PATH=$PGHOME/bin:$PATH
export LD_LIBRARY_PATH=$PGHOME/lib:$LD_LIBRARY_PATH
export MANPATH=$PGHOME/share/man:$MANPATH
EOF

# 为当前用户配置环境变量
echo 'export PATH=/usr/local/pgsql/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# 验证安装
/usr/local/pgsql/bin/postgres --version
```

## ⚙️ 初始化数据库和配置

### 步骤6：初始化数据库
```bash
# 切换到postgres用户
sudo su - postgres

# 初始化数据库集群
initdb -D /usr/local/pgsql/data -E UTF8 --locale=C -U postgres

# 或者使用详细参数
initdb \
  -D /usr/local/pgsql/data \
  -E UTF8 \
  --locale=en_US.UTF-8 \
  --lc-collate=C \
  --lc-ctype=en_US.UTF-8 \
  --username=postgres \
  --pwprompt

# 设置密码（记下这个密码）
# 输入并确认postgres用户的密码
```

### 步骤7：配置postgresql.conf
```bash
# 备份原始配置
cp /usr/local/pgsql/data/postgresql.conf /usr/local/pgsql/data/postgresql.conf.original

# 编辑主配置文件
nano /usr/local/pgsql/data/postgresql.conf
```

```ini
# 修改以下参数（根据服务器配置调整）
listen_addresses = '*'          # 允许远程连接
port = 5432                     # 监听端口
max_connections = 100           # 最大连接数
shared_buffers = 128MB          # 共享缓冲区大小（建议为内存的25%）
work_mem = 4MB                  # 每个查询的工作内存
maintenance_work_mem = 64MB     # 维护操作的内存
dynamic_shared_memory_type = posix  # 动态共享内存类型
wal_level = replica             # WAL级别
synchronous_commit = on         # 同步提交
wal_buffers = -1                # WAL缓冲区（-1表示自动）
checkpoint_timeout = 5min       # 检查点超时时间
max_wal_size = 1GB              # 最大WAL大小
min_wal_size = 80MB             # 最小WAL大小
archive_mode = off              # 归档模式
archive_command = '/bin/date'   # 归档命令（关闭时随意设置）
logging_collector = on          # 启用日志收集
log_directory = 'pg_log'        # 日志目录
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'  # 日志文件名格式
log_rotation_age = 1d           # 日志轮转时间
log_rotation_size = 10MB        # 日志轮转大小
log_truncate_on_rotation = on   # 轮转时截断
log_line_prefix = '%m [%p] %q%u@%d '  # 日志前缀
log_timezone = 'Asia/Shanghai'  # 日志时区
timezone = 'Asia/Shanghai'      # 时区
datestyle = 'iso, ymd'          # 日期格式
lc_messages = 'en_US.UTF-8'     # 消息语言
lc_monetary = 'en_US.UTF-8'     # 货币格式
lc_numeric = 'en_US.UTF-8'      # 数字格式
lc_time = 'en_US.UTF-8'         # 时间格式
default_text_search_config = 'pg_catalog.english'  # 全文搜索配置
```

### 步骤8：配置客户端认证
```bash
# 编辑pg_hba.conf
nano /usr/local/pgsql/data/pg_hba.conf
```

```conf
# 允许本地连接（md5需要密码，trust不需要密码）
local   all             postgres                                peer
local   all             all                                     md5
host    all             all             127.0.0.1/32            md5

# 允许特定IP段连接
host    all             all             192.168.1.0/24          md5

# 允许所有IP连接（生产环境慎用）
host    all             all             0.0.0.0/0               md5

# 示例：只允许特定用户从特定IP访问特定数据库
# host    exam_db         app_user        192.168.1.100/32       md5
```

### 步骤9：创建系统服务
```bash
# 退出postgres用户
exit

# 创建systemd服务文件
sudo tee /etc/systemd/system/postgresql.service << 'EOF'
[Unit]
Description=PostgreSQL Database Server
After=network.target

[Service]
Type=forking
User=postgres
Group=postgres
Environment=PGDATA=/usr/local/pgsql/data
OOMScoreAdjust=-1000
ExecStart=/usr/local/pgsql/bin/pg_ctl -D ${PGDATA} start
ExecStop=/usr/local/pgsql/bin/pg_ctl -D ${PGDATA} stop
ExecReload=/usr/local/pgsql/bin/pg_ctl -D ${PGDATA} reload
TimeoutSec=300

[Install]
WantedBy=multi-user.target
EOF

# 或者使用simple类型（推荐）
sudo tee /etc/systemd/system/postgresql.service << 'EOF'
[Unit]
Description=PostgreSQL Database Server
After=network.target

[Service]
Type=simple
User=postgres
Group=postgres
Environment=PGDATA=/usr/local/pgsql/data
Environment=PGPORT=5432
OOMScoreAdjust=-1000
ExecStart=/usr/local/pgsql/bin/postgres -D ${PGDATA}
ExecReload=/bin/kill -HUP $MAINPID
KillMode=mixed
KillSignal=SIGINT
TimeoutSec=300

[Install]
WantedBy=multi-user.target
EOF
```

### 步骤10：启动服务
```bash
# 重新加载systemd配置
sudo systemctl daemon-reload

# 启动PostgreSQL服务
sudo systemctl start postgresql

# 设置开机自启
sudo systemctl enable postgresql

# 查看服务状态
sudo systemctl status postgresql

# 查看日志
sudo journalctl -u postgresql -f
```

## 🔧 验证和基础配置

### 步骤11：验证安装
```bash
# 连接到数据库
psql -h localhost -U postgres -d postgres

# 在psql中执行
SELECT version();
SELECT current_user;
SHOW data_directory;
SHOW config_file;
\q  # 退出
```

### 步骤12：创建数据库和用户
```bash
# 切换到postgres用户
sudo su - postgres

# 创建测试数据库
createdb test_db

# 创建应用用户
createuser -P -d -e app_user
# 输入密码：AppPass123

# 连接到数据库并授权
psql -d test_db <<EOF
-- 创建schema
CREATE SCHEMA IF NOT EXISTS app_schema;

-- 创建测试表
CREATE TABLE app_schema.users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 插入测试数据
INSERT INTO app_schema.users (username, email) VALUES
('admin', 'admin@example.com'),
('user1', 'user1@example.com');

-- 授权给应用用户
GRANT ALL PRIVILEGES ON DATABASE test_db TO app_user;
GRANT ALL PRIVILEGES ON SCHEMA app_schema TO app_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA app_schema TO app_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA app_schema TO app_user;

-- 查看表
SELECT * FROM app_schema.users;
EOF
```

### 步骤13：安装常用扩展
```bash
# 安装pg_stat_statements（性能监控）
psql -U postgres -d test_db <<EOF
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS uuid-ossp;
CREATE EXTENSION IF NOT EXISTS btree_gin;
CREATE EXTENSION IF NOT EXISTS btree_gist;
SELECT * FROM pg_available_extensions ORDER BY name;
EOF
```

## 🛠️ 高级配置和优化

### 内存优化配置
```bash
# 根据服务器内存调整配置
sudo nano /usr/local/pgsql/data/postgresql.conf
```

```ini
# 内存相关优化（8GB内存服务器示例）
shared_buffers = 2GB           # 内存的25%
work_mem = 16MB                # 每个查询的工作内存
maintenance_work_mem = 512MB   # 维护操作内存
effective_cache_size = 6GB     # 可用于缓存的磁盘空间估计值

# 性能优化
max_connections = 200          # 根据应用需求调整
checkpoint_completion_target = 0.9
random_page_cost = 1.1         # SSD设为1.1，HDD设为4.0
effective_io_concurrency = 200 # SSD可以设高，HDD设低

# WAL优化
wal_buffers = 16MB
min_wal_size = 1GB
max_wal_size = 4GB
```

### 配置归档和备份
```bash
# 创建归档目录
sudo mkdir -p /usr/local/pgsql/archive
sudo chown postgres:postgres /usr/local/pgsql/archive

# 配置归档
sudo nano /usr/local/pgsql/data/postgresql.conf
```

```ini
# 启用归档
archive_mode = on
archive_command = 'test ! -f /usr/local/pgsql/archive/%f && cp %p /usr/local/pgsql/archive/%f'
archive_timeout = 3600  # 每小时强制归档
```

## 📊 监控和维护脚本

### 创建监控脚本
```bash
# 创建数据库健康检查脚本
sudo tee /usr/local/bin/check_postgres.sh << 'EOF'
#!/bin/bash
# PostgreSQL健康检查脚本

PGHOME=/usr/local/pgsql
PGDATA=/usr/local/pgsql/data
PGPORT=5432

echo "=== PostgreSQL健康检查 $(date) ==="

# 检查服务状态
systemctl is-active postgresql > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ 服务状态: 运行中"
else
    echo "✗ 服务状态: 停止"
    exit 1
fi

# 检查连接
$PGHOME/bin/pg_isready -p $PGPORT -h localhost -U postgres
if [ $? -eq 0 ]; then
    echo "✓ 数据库连接: 正常"
else
    echo "✗ 数据库连接: 失败"
fi

# 检查磁盘空间
df -h $PGDATA | tail -1

# 检查数据库大小
echo "数据库大小:"
$PGHOME/bin/psql -h localhost -U postgres -d postgres -c "
SELECT 
    datname as \"数据库\",
    pg_size_pretty(pg_database_size(datname)) as \"大小\"
FROM pg_database 
ORDER BY pg_database_size(datname) DESC;
"

echo "=== 检查完成 ==="
EOF

sudo chmod +x /usr/local/bin/check_postgres.sh
sudo chown postgres:postgres /usr/local/bin/check_postgres.sh
```

### 创建备份脚本
```bash
# 创建备份脚本
sudo tee /usr/local/bin/backup_postgres.sh << 'EOF'
#!/bin/bash
# PostgreSQL备份脚本

BACKUP_DIR="/usr/local/pgsql/backup"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=7

# 创建备份目录
mkdir -p $BACKUP_DIR/$DATE

echo "开始备份: $(date)"

# 备份所有数据库
/usr/local/pgsql/bin/pg_dumpall -h localhost -U postgres \
    | gzip > $BACKUP_DIR/$DATE/full_backup_$DATE.sql.gz

# 备份单个重要数据库（可选）
/usr/local/pgsql/bin/pg_dump -h localhost -U postgres test_db \
    -F c -f $BACKUP_DIR/$DATE/test_db_$DATE.dump

echo "备份完成: $(date)"
echo "备份文件:"
ls -lh $BACKUP_DIR/$DATE/

# 清理旧备份
find $BACKUP_DIR -type d -mtime +$RETENTION_DAYS -exec rm -rf {} \;

echo "已清理超过${RETENTION_DAYS}天的备份"
EOF

sudo chmod +x /usr/local/bin/backup_postgres.sh
sudo chown postgres:postgres /usr/local/bin/backup_postgres.sh
```

## 🎯 安装其他稳定版本

### 安装PostgreSQL 15.7（LTS版本）
```bash
cd /opt/postgresql_src
wget https://ftp.postgresql.org/pub/source/v15.7/postgresql-15.7.tar.gz
tar -zxvf postgresql-15.7.tar.gz
cd postgresql-15.7
mkdir build && cd build

# 配置（与16.2类似）
../configure \
    --prefix=/usr/local/pgsql15 \
    --with-pgport=5433 \
    --with-openssl \
    --with-perl \
    --with-python

make -j$(nproc)
sudo make install
```

### 安装PostgreSQL 14.12（长期支持）
```bash
cd /opt/postgresql_src
wget https://ftp.postgresql.org/pub/source/v14.12/postgresql-14.12.tar.gz
tar -zxvf postgresql-14.12.tar.gz
cd postgresql-14.12
mkdir build && cd build

../configure --prefix=/usr/local/pgsql14 --with-openssl
make -j$(nproc)
sudo make install
```

## ⚠️ 故障排除

### 常见问题解决
```bash
# 1. 编译错误：缺少依赖
# 重新安装所有依赖后清理重试
make distclean

# 2. 启动失败：端口被占用
netstat -tlnp | grep 5432
sudo lsof -i :5432

# 3. 连接失败：认证问题
# 检查pg_hba.conf配置

# 4. 内存不足：调整编译并行度
make -j2  # 使用更少的并行任务

# 5. 查看详细错误日志
tail -f /usr/local/pgsql/data/log/postgresql-*.log
```

## 📝 总结

### 安装步骤回顾
1. **安装依赖**：确保编译环境完整
2. **下载源码**：选择稳定版本（推荐16.2或15.7）
3. **配置编译**：根据需求选择编译选项
4. **编译安装**：使用并行编译提高速度
5. **初始化数据库**：设置数据目录和编码
6. **配置参数**：优化性能和安全
7. **创建服务**：使用systemd管理
8. **验证测试**：确保安装成功

### 版本选择建议
- **生产环境**：PostgreSQL 15.x（LTS支持到2027年）
- **学习测试**：PostgreSQL 16.x（最新特性）
- **兼容性要求**：PostgreSQL 14.x（支持到2026年）

### 关键配置文件
- `/usr/local/pgsql/data/postgresql.conf` - 主配置文件
- `/usr/local/pgsql/data/pg_hba.conf` - 客户端认证
- `/etc/systemd/system/postgresql.service` - 服务文件

通过源码安装可以获得更好的性能和定制性，适合生产环境和对性能有要求的场景。
# 配置 PostgreSQL 主从复制（远程 → 本地 macOS 备份）

我将帮你配置 `qiaopan.tech`（远程服务器）作为主库，本地 macOS 作为从库进行异步复制，用于数据备份。

## 📋 **架构设计**
```
主库 (远程服务器)         从库 (本地 macOS)
qiaopan.tech:5432  →   本地:5432
     ↓
定时同步备份
```

## 🔧 **第一部分：配置远程主库（qiaopan.tech）**

### **步骤1：创建复制用户**
```bash
# 在远程服务器上执行
sudo -i -u postgres psql

-- 创建复制专用用户
CREATE USER replicator WITH REPLICATION LOGIN 
    PASSWORD 'YourStrongReplicaPass123!'
    CONNECTION LIMIT 3
    VALID UNTIL '2025-12-31';

-- 验证创建
\du replicator
```

### **步骤2：配置主库 postgresql.conf**
```bash
# 远程服务器上编辑配置文件
sudo nano /etc/postgresql/16/main/postgresql.conf
```

```ini
# 修改或添加以下配置
listen_addresses = '*'                     # 允许所有IP连接（或指定具体IP）
port = 5432                               # 默认端口
wal_level = replica                       # 复制级别
max_wal_senders = 10                      # 最大WAL发送进程数
wal_keep_size = 1024                      # 保留1GB的WAL日志
max_replication_slots = 10                # 最大复制槽数
hot_standby = on                          # 从库可读
archive_mode = on                         # 开启归档
archive_command = 'test ! -f /var/lib/postgresql/16/main/archive/%f && cp %p /var/lib/postgresql/16/main/archive/%f'

# 性能优化
synchronous_commit = off                  # 异步复制，性能更好
wal_sender_timeout = 60s                  # 发送超时时间
```

### **步骤3：配置客户端认证（pg_hba.conf）**
```bash
sudo nano /etc/postgresql/16/main/pg_hba.conf
```

```conf
# 添加以下行（根据你的本地IP配置）
# 允许本地macOS连接进行复制
# TYPE  DATABASE        USER            ADDRESS                 METHOD
host    replication     replicator      your_local_ip/32        md5
# 如果本地IP经常变化，可以放宽限制（不推荐生产环境）
# host    replication     replicator      0.0.0.0/0               md5

# 获取你的公网IP（在本地macOS执行）
curl ifconfig.me
```

### **步骤4：重启远程PostgreSQL并创建复制槽**
```bash
# 重启服务
sudo systemctl restart postgresql@16-main

# 创建复制槽（可选，但推荐）
sudo -i -u postgres psql -c "SELECT * FROM pg_create_physical_replication_slot('macos_backup_slot');"

# 查看复制槽
sudo -i -u postgres psql -c "SELECT * FROM pg_replication_slots;"

# 查看当前WAL位置
sudo -i -u postgres psql -c "SELECT pg_current_wal_lsn();"
```

## 🔧 **第二部分：配置本地macOS从库**

### **步骤1：准备本地环境**
```bash
# 停止本地PostgreSQL（如果正在运行）
/Library/PostgreSQL/16/bin/pg_ctl -D /Library/PostgreSQL/16/data stop

# 备份现有数据（如果重要）
sudo cp -r /Library/PostgreSQL/16/data /Library/PostgreSQL/16/data.backup.$(date +%Y%m%d)

# 删除现有数据目录
sudo rm -rf /Library/PostgreSQL/16/data
```

### **步骤2：从主库同步基础数据**
```bash
# 使用pg_basebackup从远程主库同步数据
sudo -u postgres /Library/PostgreSQL/16/bin/pg_basebackup \
    -h qiaopan.tech \
    -p 5432 \
    -U replicator \
    -D /Library/PostgreSQL/16/data \
    -Fp \              # 普通格式
    -Xs \              # 使用流式复制
    -R \               # 生成recovery配置
    -P \               # 显示进度
    -v                 # 详细输出

# 输入密码：YourStrongReplicaPass123!
```

### **步骤3：配置从库恢复参数**
```bash
# 查看生成的配置
cat /Library/PostgreSQL/16/data/standby.signal
cat /Library/PostgreSQL/16/data/postgresql.auto.conf

# 如果未自动生成，手动创建
sudo tee /Library/PostgreSQL/16/data/standby.signal << EOF
standby_mode = 'on'
EOF

# 创建恢复配置
sudo tee /Library/PostgreSQL/16/data/postgresql.auto.conf << EOF
primary_conninfo = 'host=qiaopan.tech port=5432 user=replicator password=YourStrongReplicaPass123! application_name=macos_backup'
primary_slot_name = 'macos_backup_slot'
restore_command = 'cp /var/lib/postgresql/archive/%f %p'
recovery_target_timeline = 'latest'
hot_standby = 'on'
EOF

# 设置权限
sudo chown -R postgres:staff /Library/PostgreSQL/16/data
```

### **步骤4：配置本地postgresql.conf**
```bash
sudo nano /Library/PostgreSQL/16/data/postgresql.conf
```

```ini
# 从库特有配置
hot_standby = on
hot_standby_feedback = on
max_standby_streaming_delay = 30s
max_standby_archive_delay = 30s
wal_receiver_status_interval = 10s

# 设置为只读模式（备份用途）
default_transaction_read_only = on

# 监听配置（本地使用）
listen_addresses = 'localhost'
port = 5432
```

### **步骤5：启动本地从库**
```bash
# 启动PostgreSQL
sudo -u postgres /Library/PostgreSQL/16/bin/pg_ctl \
    -D /Library/PostgreSQL/16/data \
    -l /Library/PostgreSQL/16/logfile \
    start

# 查看启动日志
tail -f /Library/PostgreSQL/16/logfile
```

## 🔍 **验证复制状态**

### **在远程主库上检查**
```bash
# 查看复制连接状态
sudo -i -u postgres psql -c "
SELECT 
    pid,
    usename,
    application_name,
    client_addr,
    state,
    sync_state,
    pg_wal_lsn_diff(pg_current_wal_lsn(), sent_lsn) as sent_lag_bytes,
    pg_wal_lsn_diff(pg_current_wal_lsn(), write_lsn) as write_lag_bytes,
    pg_wal_lsn_diff(pg_current_wal_lsn(), flush_lsn) as flush_lag_bytes,
    pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) as replay_lag_bytes
FROM pg_stat_replication;
"

# 查看复制槽状态
sudo -i -u postgres psql -c "SELECT * FROM pg_replication_slots;"
```

### **在本地从库上检查**
```bash
# 检查恢复状态
/Library/PostgreSQL/16/bin/psql -U postgres -c "
SELECT 
    pg_is_in_recovery() as is_in_recovery,
    pg_last_wal_receive_lsn() as last_receive_lsn,
    pg_last_wal_replay_lsn() as last_replay_lsn,
    pg_last_xact_replay_timestamp() as last_replay_time,
    now() - pg_last_xact_replay_timestamp() as replay_delay,
    pg_wal_lsn_diff(pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn()) as replay_lag_bytes;
"

# 测试数据同步
# 在主库创建一个测试表
# ssh到远程服务器执行：
# sudo -i -u postgres psql -c "CREATE DATABASE backup_test;"
# sudo -i -u postgres psql -d backup_test -c "CREATE TABLE test_data AS SELECT generate_series(1,1000) as id, md5(random()::text) as data;"

# 在本地验证数据
/Library/PostgreSQL/16/bin/psql -U postgres -d backup_test -c "SELECT COUNT(*) FROM test_data;"
```

## 📊 **创建监控和管理脚本**

### **监控脚本：check_replication_status.sh**
```bash
sudo tee /usr/local/bin/check_replication_status.sh << 'EOF'
#!/bin/bash
# 检查主从复制状态

PRIMARY_HOST="qiaopan.tech"
PRIMARY_PORT="5432"
PRIMARY_USER="postgres"
REPLICA_DATA="/Library/PostgreSQL/16/data"

echo "=== PostgreSQL 复制状态检查 $(date) ==="
echo "主库: ${PRIMARY_HOST}:${PRIMARY_PORT}"
echo "从库: localhost:5432"

# 检查从库状态
echo -e "\n1. 从库状态:"
if /Library/PostgreSQL/16/bin/pg_isready -h localhost; then
    echo "✓ 从库服务正常"
    
    # 检查是否在恢复模式
    RECOVERY_STATUS=$(/Library/PostgreSQL/16/bin/psql -U postgres -t -c "SELECT pg_is_in_recovery();" 2>/dev/null)
    if [ "$RECOVERY_STATUS" = "t" ]; then
        echo "✓ 运行在恢复模式（从库）"
        
        # 检查复制延迟
        echo -e "\n2. 复制延迟:"
        /Library/PostgreSQL/16/bin/psql -U postgres -c "
        SELECT 
            now() - pg_last_xact_replay_timestamp() AS replication_delay,
            pg_size_pretty(pg_wal_lsn_diff(pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn())) AS replay_lag,
            pg_last_xact_replay_timestamp() AS last_replay_time;
        "
    else
        echo "✗ 不在恢复模式，可能不是从库"
    fi
else
    echo "✗ 从库服务异常"
fi

# 检查主库连接（可选）
echo -e "\n3. 主库连接测试:"
if nc -z $PRIMARY_HOST $PRIMARY_PORT 2>/dev/null; then
    echo "✓ 可以连接到主库端口"
else
    echo "✗ 无法连接到主库端口"
fi

echo -e "\n=== 检查完成 ==="
EOF

sudo chmod +x /usr/local/bin/check_replication_status.sh
```

### **定时备份验证脚本**
```bash
sudo tee /usr/local/bin/verify_backup.sh << 'EOF'
#!/bin/bash
# 验证备份数据的完整性

LOG_FILE="/Library/PostgreSQL/16/logs/backup_verify.log"
REPLICA_DATA="/Library/PostgreSQL/16/data"

# 创建日志目录
mkdir -p /Library/PostgreSQL/16/logs

echo "$(date): 开始备份验证" | tee -a $LOG_FILE

# 1. 检查从库状态
if ! /Library/PostgreSQL/16/bin/pg_isready -h localhost; then
    echo "$(date): 错误: 从库服务未运行" | tee -a $LOG_FILE
    exit 1
fi

# 2. 检查恢复模式
RECOVERY_STATUS=$(/Library/PostgreSQL/16/bin/psql -U postgres -t -c "SELECT pg_is_in_recovery();" 2>/dev/null)
if [ "$RECOVERY_STATUS" != "t" ]; then
    echo "$(date): 警告: 不在恢复模式" | tee -a $LOG_FILE
fi

# 3. 检查最近的复制活动
LAST_REPLAY=$(/Library/PostgreSQL/16/bin/psql -U postgres -t -c "SELECT pg_last_xact_replay_timestamp();" 2>/dev/null)
if [ -n "$LAST_REPLAY" ]; then
    REPLAY_AGE=$(/Library/PostgreSQL/16/bin/psql -U postgres -t -c "SELECT EXTRACT(EPOCH FROM (now() - pg_last_xact_replay_timestamp()));" 2>/dev/null)
    
    if [ $(echo "$REPLAY_AGE > 300" | bc) -eq 1 ]; then
        echo "$(date): 警告: 最近5分钟内没有复制活动" | tee -a $LOG_FILE
    else
        echo "$(date): 正常: 最近有复制活动 ($REPLAY_AGE 秒前)" | tee -a $LOG_FILE
    fi
fi

# 4. 检查关键数据库的完整性
echo "$(date): 检查数据库完整性" | tee -a $LOG_FILE
/Library/PostgreSQL/16/bin/psql -U postgres -t -c "
SELECT 
    datname,
    pg_size_pretty(pg_database_size(datname)) as size,
    pg_stat_file('base/' || oid || '/PG_VERSION') IS NOT NULL as files_ok
FROM pg_database 
WHERE datname NOT IN ('template0', 'template1', 'postgres')
ORDER BY pg_database_size(datname) DESC;
" | tee -a $LOG_FILE

# 5. 检查表空间
echo -e "\n$(date): 表空间状态:" | tee -a $LOG_FILE
/Library/PostgreSQL/16/bin/psql -U postgres -t -c "
SELECT 
    spcname,
    pg_tablespace_location(oid) as location,
    pg_stat_file(pg_tablespace_location(oid)) IS NOT NULL as accessible
FROM pg_tablespace;
" | tee -a $LOG_FILE

echo "$(date): 备份验证完成" | tee -a $LOG_FILE
EOF

sudo chmod +x /usr/local/bin/verify_backup.sh
```

## 🔄 **配置定时任务（crontab）**

```bash
# 编辑当前用户的crontab
crontab -e
```

添加以下内容：
```crontab
# PostgreSQL 备份监控和验证
# 每30分钟检查一次复制状态
*/30 * * * * /usr/local/bin/check_replication_status.sh >> /Library/PostgreSQL/16/logs/replication_monitor.log 2>&1

# 每天凌晨2点验证备份完整性
0 2 * * * /usr/local/bin/verify_backup.sh

# 每周一凌晨3点清理旧日志
0 3 * * 1 find /Library/PostgreSQL/16/logs -name "*.log" -mtime +30 -delete

# 每小时发送一次健康报告到通知（可选）
# 0 * * * * /usr/local/bin/send_health_report.sh
```

## 🛠️ **故障排除和恢复**

### **问题1：网络中断后的恢复**
```bash
# 如果网络中断导致复制停止
# 1. 检查主库是否可访问
ping -c 3 qiaopan.tech

# 2. 在从库重新启动复制
/Library/PostgreSQL/16/bin/pg_ctl -D /Library/PostgreSQL/16/data restart

# 3. 如果仍然失败，可能需要重新同步
/Library/PostgreSQL/16/bin/pg_ctl -D /Library/PostgreSQL/16/data stop
sudo rm -rf /Library/PostgreSQL/16/data
sudo -u postgres /Library/PostgreSQL/16/bin/pg_basebackup -h qiaopan.tech -p 5432 -U replicator -D /Library/PostgreSQL/16/data -Fp -Xs -R -P
/Library/PostgreSQL/16/bin/pg_ctl -D /Library/PostgreSQL/16/data start
```

### **问题2：复制延迟过大**
```bash
# 查看当前延迟
/Library/PostgreSQL/16/bin/psql -U postgres -c "
SELECT 
    now() - pg_last_xact_replay_timestamp() as replication_delay,
    pg_size_pretty(pg_wal_lsn_diff(pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn())) as replay_lag;
"

# 如果延迟过大，可能是网络或性能问题
# 优化本地macOS PostgreSQL配置
sudo nano /Library/PostgreSQL/16/data/postgresql.conf
```

```ini
# 增加以下优化参数
max_standby_streaming_delay = -1        # 禁用延迟，尽快应用
max_standby_archive_delay = -1          # 禁用归档延迟
wal_receiver_timeout = 120s             # 增加接收超时
```

### **问题3：主库空间不足**
```bash
# 在主库检查WAL日志大小
sudo -i -u postgres psql -c "
SELECT 
    slot_name,
    pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) as replication_lag,
    active
FROM pg_replication_slots;
"

# 如果从库长时间离线，可能需要清理复制槽
# sudo -i -u postgres psql -c "SELECT pg_drop_replication_slot('macos_backup_slot');"
```

## 📱 **创建简单的Web监控界面（可选）**

```bash
# 安装Python依赖
pip3 install flask psycopg2-binary

# 创建监控应用
sudo tee /Library/PostgreSQL/16/scripts/monitor_app.py << 'EOF'
#!/usr/bin/env python3
from flask import Flask, jsonify
import psycopg2
import psycopg2.extras
import os
from datetime import datetime

app = Flask(__name__)

def get_replication_status():
    """获取复制状态"""
    try:
        conn = psycopg2.connect(
            host="localhost",
            port=5432,
            user="postgres",
            database="postgres"
        )
        cursor = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        
        # 检查是否在恢复模式
        cursor.execute("SELECT pg_is_in_recovery() as is_replica")
        is_replica = cursor.fetchone()['is_replica']
        
        if is_replica:
            # 获取复制延迟信息
            cursor.execute("""
                SELECT 
                    now() - pg_last_xact_replay_timestamp() as replication_delay,
                    pg_wal_lsn_diff(pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn()) as replay_lag_bytes,
                    pg_last_xact_replay_timestamp() as last_replay_time,
                    pg_last_wal_receive_lsn() as last_receive_lsn,
                    pg_last_wal_replay_lsn() as last_replay_lsn
            """)
            replication_info = dict(cursor.fetchone())
            
            # 计算延迟秒数
            if replication_info['replication_delay']:
                replication_info['replication_delay_seconds'] = replication_info['replication_delay'].total_seconds()
            else:
                replication_info['replication_delay_seconds'] = None
                
            replication_info['status'] = 'replicating'
        else:
            replication_info = {'status': 'not_replica'}
            
        conn.close()
        return replication_info
        
    except Exception as e:
        return {'status': 'error', 'message': str(e)}

@app.route('/api/replication/status')
def replication_status():
    """返回复制状态API"""
    return jsonify(get_replication_status())

@app.route('/api/databases')
def list_databases():
    """列出所有数据库"""
    try:
        conn = psycopg2.connect(
            host="localhost",
            port=5432,
            user="postgres",
            database="postgres"
        )
        cursor = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        
        cursor.execute("""
            SELECT 
                datname,
                pg_size_pretty(pg_database_size(datname)) as size,
                datcollate,
                pg_stat_file('base/' || oid || '/PG_VERSION') IS NOT NULL as files_ok
            FROM pg_database 
            WHERE datname NOT IN ('template0', 'template1')
            ORDER BY pg_database_size(datname) DESC
        """)
        
        databases = []
        for row in cursor:
            databases.append(dict(row))
            
        conn.close()
        return jsonify({'databases': databases})
        
    except Exception as e:
        return jsonify({'error': str(e)})

@app.route('/')
def index():
    """简单监控页面"""
    status = get_replication_status()
    
    html = f"""
    <html>
    <head>
        <title>PostgreSQL 备份监控</title>
        <style>
            body {{ font-family: Arial, sans-serif; margin: 40px; }}
            .status {{ padding: 20px; border-radius: 5px; }}
            .healthy {{ background-color: #d4edda; color: #155724; }}
            .warning {{ background-color: #fff3cd; color: #856404; }}
            .error {{ background-color: #f8d7da; color: #721c24; }}
        </style>
    </head>
    <body>
        <h1>PostgreSQL 备份监控</h1>
        <p>时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
        
        <div class="status {'healthy' if status.get('status') == 'replicating' else 'error'}">
            <h2>复制状态: {status.get('status', 'unknown')}</h2>
    """
    
    if status.get('status') == 'replicating':
        html += f"""
            <p>复制延迟: {status.get('replication_delay_seconds', 'N/A')} 秒</p>
            <p>最后复制时间: {status.get('last_replay_time')}</p>
            <p>WAL 接收位置: {status.get('last_receive_lsn')}</p>
            <p>WAL 重放位置: {status.get('last_replay_lsn')}</p>
        """
    elif status.get('status') == 'error':
        html += f"<p>错误: {status.get('message')}</p>"
    
    html += """
        </div>
        
        <p><a href="/api/replication/status">JSON 状态</a> | 
        <a href="/api/databases">数据库列表</a></p>
    </body>
    </html>
    """
    
    return html

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5000, debug=False)
EOF

# 创建启动脚本
sudo tee /Library/PostgreSQL/16/scripts/start_monitor.sh << 'EOF'
#!/bin/bash
cd /Library/PostgreSQL/16/scripts
nohup python3 monitor_app.py > monitor.log 2>&1 &
echo $! > monitor.pid
EOF

sudo chmod +x /Library/PostgreSQL/16/scripts/start_monitor.sh
```

## 📝 **安全建议**

1. **使用SSH隧道（推荐）**：
   ```bash
   # 在本地macOS创建SSH隧道
   ssh -N -L 5433:localhost:5432 user@qiaopan.tech
   
   # 然后在配置中使用 localhost:5433 连接
   ```

2. **加强密码安全**：
   - 使用强密码
   - 定期更换复制用户密码
   - 使用不同密码用于不同用途

3. **限制访问IP**：
   ```bash
   # 在主库pg_hba.conf中只允许你的公网IP
   host    replication     replicator      your_public_ip/32        md5
   ```

## ✅ **完成验证**

测试一切正常工作：

```bash
# 1. 检查复制状态
/usr/local/bin/check_replication_status.sh

# 2. 在主库创建测试数据
# ssh到远程服务器执行：
# sudo -i -u postgres psql -c "CREATE TABLE test_sync AS SELECT generate_series(1,100) as id, now() as timestamp;"

# 3. 在本地验证数据
/Library/PostgreSQL/16/bin/psql -U postgres -c "SELECT COUNT(*) FROM test_sync;"

# 4. 查看监控页面（如果启用了Web监控）
# 访问 http://localhost:5000
```

这样你就有了一个完整的远程到本地的 PostgreSQL 主从复制备份方案！
---
[◀ 返回](/后端架构/后端架构-兵法篇/)
