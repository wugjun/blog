---
title: "Kubernetes 集群部署 - etcd 安装与配置"
date: 2025-12-29
description: "K8s 集群中 etcd 的完整安装、配置和部署指南"
lead: "etcd 作为 Kubernetes 的数据存储核心，稳定可靠的部署至关重要"
categories:
  - "运维部署"
tags:
  - "Kubernetes"
  - "etcd"
  - "集群部署"
toc: true
mathjax: false
---

## 📋 概述

etcd 是 Kubernetes 集群的核心数据存储组件，负责存储集群的所有配置数据、状态信息和元数据。本文档提供 etcd 集群的完整安装、配置和部署方案。

### 架构说明

- **集群模式**: 建议至少 3 个节点（奇数个节点，避免脑裂）
- **数据目录**: `/var/lib/etcd`
- **配置文件**: `/etc/etcd/etcd.conf`
- **服务文件**: `/etc/systemd/system/etcd.service`
- **端口**: 
  - `2379`: 客户端通信端口
  - `2380`: 节点间通信端口

---

## 🔧 环境准备

### 节点信息配置

根据实际环境修改以下节点信息：

```bash
# 节点格式: 主机名:IP地址:etcd节点名
NODES=(
    "k8s-master-01:192.168.1.100:etcd-01"
    "k8s-node-01:192.168.1.101:etcd-02"
    "k8s-master-02:192.168.1.102:etcd-03"
)
```

### 系统要求

- **操作系统**: CentOS 7+ / Ubuntu 18.04+
- **内存**: 至少 2GB（推荐 4GB+）
- **磁盘**: 至少 20GB 可用空间（SSD 推荐）
- **网络**: 节点间网络延迟 < 10ms

---

## 📦 安装 etcd

### 步骤 1: 下载 etcd 二进制文件

```bash
#!/bin/bash
# install-etcd.sh - etcd 安装脚本

set -e

ETCD_VERSION="v3.5.9"  # 根据 K8s 版本选择兼容的 etcd 版本
INSTALL_DIR="/usr/local/bin"
DATA_DIR="/var/lib/etcd"
CONFIG_DIR="/etc/etcd"

# 交互式确认
read -p "是否执行 etcd 安装步骤？(y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已跳过 etcd 安装"
    exit 0
fi

echo "=== 开始安装 etcd ${ETCD_VERSION} ==="

# 创建必要目录
sudo mkdir -p ${INSTALL_DIR}
sudo mkdir -p ${DATA_DIR}
sudo mkdir -p ${CONFIG_DIR}

# 下载 etcd
cd /tmp
wget https://github.com/etcd-io/etcd/releases/download/${ETCD_VERSION}/etcd-${ETCD_VERSION}-linux-amd64.tar.gz

# 解压并安装
tar -xzf etcd-${ETCD_VERSION}-linux-amd64.tar.gz
sudo cp etcd-${ETCD_VERSION}-linux-amd64/etcd* ${INSTALL_DIR}/
sudo chmod +x ${INSTALL_DIR}/etcd*

# 验证安装
${INSTALL_DIR}/etcd --version
${INSTALL_DIR}/etcdctl version

echo "✓ etcd 安装完成"
```

### 步骤 2: 配置 etcd 集群

```bash
#!/bin/bash
# configure-etcd.sh - etcd 集群配置脚本

set -e

NODES=(
    "k8s-master-01:192.168.1.100:etcd-01"
    "k8s-node-01:192.168.1.101:etcd-02"
    "k8s-master-02:192.168.1.102:etcd-03"
)

ETCD_VERSION="v3.5.9"
INSTALL_DIR="/usr/local/bin"
DATA_DIR="/var/lib/etcd"
CONFIG_DIR="/etc/etcd"
CERT_DIR="/etc/etcd/ssl"

# 交互式确认
read -p "是否执行 etcd 集群配置？(y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已跳过 etcd 配置"
    exit 0
fi

echo "=== 开始配置 etcd 集群 ==="

# 生成集群初始成员列表
INITIAL_CLUSTER=""
for NODE_INFO in "${NODES[@]}"; do
    IFS=':' read -r HOSTNAME NODE_IP ETCD_NAME <<< "$NODE_INFO"
    INITIAL_CLUSTER+="${ETCD_NAME}=https://${NODE_IP}:2380,"
done
INITIAL_CLUSTER=${INITIAL_CLUSTER%,}

echo "集群成员列表: ${INITIAL_CLUSTER}"

# 为每个节点配置 etcd
for NODE_INFO in "${NODES[@]}"; do
    IFS=':' read -r HOSTNAME NODE_IP ETCD_NAME <<< "$NODE_INFO"
    
    echo "配置节点: ${HOSTNAME} (${ETCD_NAME})"
    
    ssh root@${NODE_IP} << EOF
        # 创建目录
        mkdir -p ${DATA_DIR}
        mkdir -p ${CONFIG_DIR}
        mkdir -p ${CERT_DIR}
        
        # 创建 etcd 配置文件
        cat > ${CONFIG_DIR}/etcd.conf << EOC
# 节点名称
ETCD_NAME=${ETCD_NAME}
# 数据目录
ETCD_DATA_DIR=${DATA_DIR}
# 监听客户端请求的地址
ETCD_LISTEN_CLIENT_URLS=https://${NODE_IP}:2379,https://127.0.0.1:2379
# 监听对等节点请求的地址
ETCD_LISTEN_PEER_URLS=https://${NODE_IP}:2380
# 客户端访问地址
ETCD_INITIAL_ADVERTISE_PEER_URLS=https://${NODE_IP}:2380
ETCD_ADVERTISE_CLIENT_URLS=https://${NODE_IP}:2379
# 初始集群成员列表
ETCD_INITIAL_CLUSTER=${INITIAL_CLUSTER}
# 集群状态（new 表示新集群，existing 表示加入已有集群）
ETCD_INITIAL_CLUSTER_STATE=new
# 集群 token
ETCD_INITIAL_CLUSTER_TOKEN=k8s-etcd-cluster
# 客户端证书配置（如果使用 TLS）
ETCD_CLIENT_CERT_AUTH=true
ETCD_CERT_FILE=${CERT_DIR}/server.crt
ETCD_KEY_FILE=${CERT_DIR}/server.key
ETCD_TRUSTED_CA_FILE=${CERT_DIR}/ca.crt
# 对等节点证书配置
ETCD_PEER_CLIENT_CERT_AUTH=true
ETCD_PEER_CERT_FILE=${CERT_DIR}/peer.crt
ETCD_PEER_KEY_FILE=${CERT_DIR}/peer.key
ETCD_PEER_TRUSTED_CA_FILE=${CERT_DIR}/ca.crt
EOC
        
        # 设置权限
        chmod 644 ${CONFIG_DIR}/etcd.conf
        chown -R etcd:etcd ${DATA_DIR} ${CONFIG_DIR} 2>/dev/null || true
        
        echo "✓ ${HOSTNAME} 配置完成"
EOF
done

echo "✓ etcd 集群配置完成"
```

### 步骤 3: 创建 systemd 服务

```bash
#!/bin/bash
# setup-etcd-service.sh - 创建 etcd systemd 服务

set -e

NODES=(
    "k8s-master-01:192.168.1.100:etcd-01"
    "k8s-node-01:192.168.1.101:etcd-02"
    "k8s-master-02:192.168.1.102:etcd-03"
)

INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/etcd"

# 交互式确认
read -p "是否创建 etcd systemd 服务？(y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已跳过服务创建"
    exit 0
fi

echo "=== 创建 etcd systemd 服务 ==="

for NODE_INFO in "${NODES[@]}"; do
    IFS=':' read -r HOSTNAME NODE_IP ETCD_NAME <<< "$NODE_INFO"
    
    echo "为 ${HOSTNAME} 创建服务..."
    
    ssh root@${NODE_IP} << EOF
        cat > /etc/systemd/system/etcd.service << EOS
[Unit]
Description=Etcd Server
Documentation=https://github.com/coreos/etcd
After=network.target
Wants=network-online.target

[Service]
Type=notify
EnvironmentFile=-${CONFIG_DIR}/etcd.conf
ExecStart=${INSTALL_DIR}/etcd
Restart=on-failure
RestartSec=10
LimitNOFILE=65536
# 关键：增加启动超时时间，避免集群启动时超时
TimeoutStartSec=120

[Install]
WantedBy=multi-user.target
EOS
        
        # 重新加载 systemd
        systemctl daemon-reload
        systemctl enable etcd
        
        echo "✓ ${HOSTNAME} 服务创建完成"
EOF
done

echo "✓ etcd 服务创建完成"
```

---

## 🚀 启动 etcd 集群

### 步骤 4: 启动集群

```bash
#!/bin/bash
# start-etcd-cluster.sh - 启动 etcd 集群

set -e

NODES=(
    "k8s-master-01:192.168.1.100:etcd-01"
    "k8s-node-01:192.168.1.101:etcd-02"
    "k8s-master-02:192.168.1.102:etcd-03"
)

# 交互式确认
read -p "是否启动 etcd 集群？(y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已跳过集群启动"
    exit 0
fi

echo "=== 启动 etcd 集群 ==="

# 按顺序启动节点（避免同时启动导致的问题）
for i in "${!NODES[@]}"; do
    NODE_INFO="${NODES[$i]}"
    IFS=':' read -r HOSTNAME NODE_IP ETCD_NAME <<< "$NODE_INFO"
    
    echo "启动节点 ${HOSTNAME} (第 $((i+1)) 个节点)..."
    
    ssh root@${NODE_IP} "systemctl start etcd"
    
    # 等待节点启动
    sleep 5
    
    # 检查节点状态
    if ssh root@${NODE_IP} "systemctl is-active --quiet etcd"; then
        echo "✓ ${HOSTNAME} 启动成功"
    else
        echo "✗ ${HOSTNAME} 启动失败，请检查日志: journalctl -u etcd -n 50"
    fi
done

echo "=== 检查集群状态 ==="
# 使用第一个节点检查集群状态
FIRST_NODE="${NODES[0]}"
IFS=':' read -r FIRST_HOST FIRST_IP FIRST_NAME <<< "$FIRST_NODE"

ssh root@${FIRST_IP} "/usr/local/bin/etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/etcd/ssl/ca.crt --cert=/etc/etcd/ssl/server.crt --key=/etc/etcd/ssl/server.key endpoint health" || echo "注意: 如果使用 TLS，请确保证书已正确配置"

echo "✓ etcd 集群启动完成"
```

---

## ✅ 验证和监控

### 检查集群状态

```bash
# 检查服务状态
systemctl status etcd

# 查看日志
journalctl -u etcd -f

# 检查集群健康（如果使用 TLS）
etcdctl --endpoints=https://127.0.0.1:2379 \
    --cacert=/etc/etcd/ssl/ca.crt \
    --cert=/etc/etcd/ssl/server.crt \
    --key=/etc/etcd/ssl/server.key \
    endpoint health

# 查看集群成员
etcdctl --endpoints=https://127.0.0.1:2379 \
    --cacert=/etc/etcd/ssl/ca.crt \
    --cert=/etc/etcd/ssl/server.crt \
    --key=/etc/etcd/ssl/server.key \
    member list
```

### 常用维护命令

```bash
# 备份 etcd 数据
etcdctl snapshot save /backup/etcd-snapshot-$(date +%Y%m%d).db

# 恢复 etcd 数据
etcdctl snapshot restore /backup/etcd-snapshot-20231229.db \
    --data-dir=/var/lib/etcd-restore

# 查看集群统计信息
etcdctl endpoint status --write-out=table
```

---

## 📝 注意事项

1. **证书配置**: 如果使用 TLS，确保所有节点的证书已正确配置
2. **网络连通性**: 确保所有节点间的 2379 和 2380 端口互通
3. **数据备份**: 定期备份 etcd 数据，防止数据丢失
4. **资源监控**: 监控 etcd 的 CPU、内存和磁盘使用情况
5. **版本兼容**: 确保 etcd 版本与 Kubernetes 版本兼容

---

## 🔗 相关资源

- [etcd 官方文档](https://etcd.io/docs/)
- [Kubernetes etcd 集成](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/)
