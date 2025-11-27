---
title: "Ngrok 内网穿透部署指南"
date: 2023-08-21
description: "基于自建服务器的Ngrok内网穿透完整部署方案"
lead: "自建内网穿透隧道，安全高效实现公网访问"
categories:
  - "运维部署"
tags:
  - "内网穿透"
  - "Ngrok"
  - "网络隧道"
toc: false
mathjax: false
---

## 🎯 场景概述

实现基于自建服务器的 Ngrok 公网转发访问，将本地服务安全暴露到公网环境。

---

## 🖥️ 服务器环境准备

### 系统要求
- **操作系统**: Ubuntu 16.04+ / CentOS 7+
- **内存**: 至少 1GB
- **存储**: 至少 10GB 可用空间
- **网络**: 公网 IP，开放所需端口

### Ubuntu 环境依赖安装

```bash
# 更新系统包
apt-get update

# 安装必要依赖
apt-get -y install zlib-devel openssl-devel perl hg cpio expat-devel \
                   gettext-devel curl curl-devel perl-ExtUtils-MakeMaker \
                   hg wget gcc gcc-c++ git
```

---

## ⚙️ Go 语言环境配置

### 清理旧版本 Golang
```bash
# 删除现有golang依赖包
rpm -qa | grep golang | xargs rpm -e 2>/dev/null || true
```

### 安装 Go 1.16.3
```bash
# 下载安装包
wget https://golang.org/dl/go1.16.3.linux-amd64.tar.gz

# 解压到系统目录
tar -C /usr/local -xzf go1.16.3.linux-amd64.tar.gz

# 配置环境变量
cat >> /etc/profile << 'EOF'
# Go Language Environment
export GOROOT=/usr/local/go
export PATH=$PATH:$GOROOT/bin
export GOPATH=/home/go
EOF

# 加载环境变量
source /etc/profile

# 验证安装
go version
```
**预期输出**: `go version go1.16.3 linux/amd64`

---

## 🔒 防火墙端口配置

### 开放必要端口
```bash
# 编辑iptables配置
vim /etc/sysconfig/iptables

# 添加以下内容到INPUT链：
-A INPUT -m state --state NEW -m tcp -p tcp --dport 50123 -j ACCEPT
-A INPUT -m state --state NEW -m tcp -p tcp --dport 4443 -j ACCEPT
```

### 应用防火墙规则
```bash
# 重新加载配置
/etc/init.d/iptables reload
/etc/init.d/iptables restart

# 验证端口开放状态
iptables -nL
```

**端口说明**:
- `4443`: Ngrok 客户端连接端口
- `50123`: 自定义隧道服务端口

---

## 🚀 一键部署方案

### 完整自动化部署
[获取代码](https://github.com/blowizer/ngrok) 
```bash
# 执行一键部署脚本
./deploy-ngrok-full.sh
```

### 分步部署（推荐用于生产环境）

#### 步骤 1: 生成 SSL 证书
```bash
echo "生成Ngrok服务端证书..."
sudo chmod +x /usr/local/bin/setup-ngrok-cert.sh
sudo /usr/local/bin/setup-ngrok-cert.sh
```

#### 步骤 2: 同步证书文件
```bash
echo "同步证书到Ngrok编译目录..."
sudo chmod +x /usr/local/bin/sync-ngrok-certs.sh  
sudo /usr/local/bin/sync-ngrok-certs.sh 
```

#### 步骤 3: 编译 Ngrok 服务
```bash
echo "编译Ngrok服务端和客户端..."
sudo chmod +x /usr/local/bin/build-ngrok.sh  
sudo /usr/local/bin/build-ngrok.sh
```

#### 步骤 4: 配置系统服务
```bash
echo "配置Ngrok系统服务..."
sudo chmod +x /usr/local/bin/setup-ngrok-service.sh
sudo /usr/local/bin/setup-ngrok-service.sh
```

#### 步骤 5: 生成客户端配置
```bash
echo "生成客户端配置文件..."
sudo chmod +x /usr/local/bin/setup-ngrok-client.sh
/usr/local/bin/setup-ngrok-client.sh
```

---

## 🔧 服务管理

### 启动 Ngrok 服务
```bash
systemctl start ngrokd
```

### 设置开机自启
```bash
systemctl enable ngrokd
```

### 查看服务状态
```bash
systemctl status ngrokd
```

### 查看服务日志
```bash
journalctl -u ngrokd -f
```

---

## 📱 客户端配置

### 获取客户端文件
部署完成后，在以下位置获取客户端文件：
- **Linux 客户端**: `/usr/local/ngrok/bin/ngrok`
- **Windows 客户端**: `/usr/local/ngrok/bin/windows_amd64/ngrok.exe`
- **配置文件**: `/usr/local/ngrok/ngrok.cfg`

### 客户端配置文件示例
```yaml
server_addr: "your-server-domain.com:4443"
trust_host_root_certs: false
tunnels:
  web:
    proto:
      http: 80
    subdomain: "test"
  ssh:
    proto:
      tcp: 22
    remote_port: 50022
```

### 客户端使用
```bash
# 启动HTTP隧道
./ngrok -config=ngrok.cfg start web

# 启动TCP隧道  
./ngrok -config=ngrok.cfg start ssh
```

---

## 🧪 验证部署

### 服务端验证
```bash
# 检查服务监听状态
netstat -tlnp | grep ngrokd

# 预期输出应包含：
# tcp6       0      0 :::4443                 :::*                    LISTEN      1234/ngrokd
```

### 客户端连接测试
```bash
# 从客户端测试连接
./ngrok -config=ngrok.cfg -log=stdout -proto=http 8080
```

---

## ⚠️ 故障排除

### 常见问题及解决方案

#### 1. 证书生成失败
```bash
# 重新生成证书
cd /usr/local/ngrok
openssl genrsa -out rootCA.key 2048
openssl req -x509 -new -nodes -key rootCA.key -subj "/CN=your-domain.com" -days 5000 -out rootCA.pem
```

#### 2. 端口被占用
```bash
# 检查端口占用
lsof -i :4443

# 终止占用进程
kill -9 <PID>
```

#### 3. 客户端连接超时
- 检查服务器防火墙设置
- 验证域名解析是否正确
- 确认客户端配置文件中的服务器地址

---

## 🔐 安全建议

1. **定期更新证书**: 建议每6个月更新一次SSL证书
2. **使用复杂令牌**: 客户端认证使用强令牌
3. **限制访问IP**: 通过防火墙限制客户端连接IP
4. **监控服务状态**: 设置服务监控和告警
5. **日志审计**: 定期检查访问日志，发现异常行为

---

## 💡 高级配置

### 多域名支持
在证书生成时指定多个域名：
```bash
openssl req -new -key device.key -subj "/CN=ngrok1.domain.com" -out device1.csr
openssl req -new -key device.key -subj "/CN=ngrok2.domain.com" -out device2.csr
```

### 负载均衡配置
```yaml
# 在多台服务器间配置负载均衡
server_addr: "ngrok1.domain.com:4443,ngrok2.domain.com:4443"
```

> 部署完成后，您就拥有了一个完全自控的内网穿透服务，可以安全地将本地服务暴露到公网，适用于开发测试、演示、远程访问等多种场景。
```
