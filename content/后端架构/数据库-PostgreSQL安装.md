---
title: "典籍篇"
date: 2025-06-20
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

draft: true
---
[◀ 返回](/后端架构/后端架构-兵法篇/)
### PostgreSQL 安装

#### 创建用户与环境配置

1. 创建用户
```shell
groupadd postgres
useradd -g postgres postgres

环境变量配置(.bash_profile)

export PGPORT=5433

export PG_HOME=/usr/local/pg16.2

export PATH=$PG_HOME/bin:$PATH

export PGDATA=$PG_HOME/data

export LD_LIBRARY_PATH=$PG_HOME/lib

export LANG=en_US.utf8
```

2. 内核参数配置
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

3. centos7 源码安装

- [下载](https://www.postgresql.org/ftp/source/ )

 - 依赖包检查

> **最小依赖**：*gcc、gcc-c++、zlib-devel、readline-devel*

> **其他依赖**：*perl-ExtUtils-Embed、pam-devel、libxml2-devel、libxslt-devel、openldap-devel、python-devel、openssl-devel、cmake*

- 安装

```shell
$ su - postgres
$ cd /soft/postgresql-16.2

$ ./configure --prefix=/usr/local/pg16.2

$ make

$ make install

## Configure常用配置选项：

## prefix：指定安装路径
## with-openssl：对openssl进行扩展支持

## with-python：对python进行扩展支持

## with-perl：对perl进行扩展支持

## with-libxml：对xml进行扩展支持

./configure --prefix=/usr/local/pg16.2 --with-pgport=1922 --with-openssl --with-perl --with-tcl --with-python --with-pam --without-ldap --with-libxml --with-libxslt --enable-thread-safety --with-wal-blocksize=16 --with-blocksize=8 --enable-dtrace --enable-debug
--with-blocksize

## 如果数据库需要经常做插入的操作，数据量增长非常快，尽量把此参数设大一点;
## 经常做小数据查询、更新且内存不是非常大的时候可以设小一点，默认8K即可。
## 生产环境不要加--enable-dtrace --enable-debug

## gmakeworld包括第三方插件全部编译

## gmakecheck-world需要使用普通用户执行，可选，耗时较长

## gmakeinstall包括第三方插件全部安装

## gmakeworld安装包含了文档，所有的contirb

## 安装前先创建好/usr/local/pg16.6目录，同时授权postgres用户可读写权限

```
## PG 的建库与使用

### 创建数据库集簇

```shell

# 1. 创建目录
mkdir /usr/local/pg16.6/data
# 2. 初始化数据库集簇
initdb -D $PG_DATA -W --data-checksums 
```
### 数据库打开和关闭
```shell
# 1. 启动数据库
pg_ctl -D $PG
# 2. 关闭数据库
pg_ctl -D $PG_DATA stop
# 3. 登录数据库
pgsql -U postgres
# 4. 退出数据哭
>\q
```
### 数据库的使用
```shell
# 1. 查看帮助
>help
# 2. 执行 pgsql 命令
>\l
>select * from tab_name;
```
## PG的实例
![PG 实例](/images/Postgresql安装图1.png)
### 参数文件
 1. 静态参数文件: **postgresql.conf** 
 
 >  使用操作系统编辑器手动修改，更改在下次启动生效,仅在实例启动期间读取，默认位置$PG_DATA
  
动态参数文件: **postgresql.auto.conf**
> 由 postgrsql 服务器维护，支持用文本编辑器修改（不推荐），alter sysetem 命令修改的参数保存在该文件，能够在关闭和启动期间持续进行更改，可以实现参数的自我调整。默认位置$PG_DATA,改变一个参数的值，会在文件中自动添加参数，alter system set archive_mode= on，恢复一个参数默认值，会在文件中自动删除参数。

可选参数文件: **postgresql.conf.user**


2. 参数生效条件
```sql
select name ,setting,context from pg_settings where name in('port','work_mem','log_statement','log_checkpoints');
```
 
![pg_settings](/images/Postgresql安装图2.png)

**sighup**: 表示需要超级管理员修改，reload 就能够生效。

**superuser**: 表示使用超级管理员可以为普通用户、数据库、或者超级管理员自己修改。

**postmaster**: 表示需要超级管理员修改，需要重启才能够生效。

**user**: 表示普通用户可以修改参数值，立即生效。

---
[◀ 返回](/后端架构/后端架构-兵法篇/)
