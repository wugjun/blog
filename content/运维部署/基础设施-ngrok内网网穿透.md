---
title: "Ngrok 内网穿透部署指南"
date: 2025-12-30
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

# Ngrok 内网穿透部署方案

## 📦 项目地址

**代码仓库：** `git@github.com:blowizer/ngrok.git`

```bash
git clone git@github.com:blowizer/ngrok.git
cd ngrok
```

## 🎯 场景使用

实现 ngrok 公网转发访问，用于内网穿透，将本地服务暴露到公网。

## 🖥️ 服务器环境准备

### 1. Ubuntu 系统依赖安装

```bash
apt-get -y install zlib-devel openssl-devel perl hg cpio expat-devel gettext-devel curl curl-devel perl-ExtUtils-MakeMaker hg wget gcc gcc-c++ git
```

### 2. Go 语言环境安装

**推荐版本：** `go version go1.16.3 linux/amd64`

```bash
# 删除旧版本 golang 依赖包（如果存在）
rpm -qa|grep golang|xargs rpm -e

# 下载安装包
wget https://golang.org/dl/go1.16.3.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.16.3.linux-amd64.tar.gz

# 配置环境变量
vim /etc/profile
# 在文件末尾添加以下内容：
# #go lang
# export GOROOT=/usr/local/go
# export PATH=$PATH:$GOROOT/bin

# 使配置生效
source /etc/profile

# 检测是否安装成功
go version
```

### 3. 防火墙端口配置

```bash
vim /etc/sysconfig/iptables
# 添加以下内容：
# -A INPUT -m state --state NEW -m tcp -p tcp --dport 4443 -j ACCEPT
# -A INPUT -m state --state NEW -m tcp -p tcp --dport 8080 -j ACCEPT
# -A INPUT -m state --state NEW -m tcp -p tcp --dport 8081 -j ACCEPT
# -A INPUT -m state --state NEW -m tcp -p tcp --dport 2222 -j ACCEPT

# 重新加载防火墙规则
/etc/init.d/iptables reload
/etc/init.d/iptables restart

# 查看开放的端口
iptables -nL
```

**注意：** 如果使用云服务器（如阿里云），还需要在安全组中开放相应端口。

## 🚀 快速部署

### 一键部署（推荐）

在服务端执行：

```bash
chmod +x deploy-ngrok-full.sh
sudo ./deploy-ngrok-full.sh
```

该脚本会自动执行以下步骤：
1. 生成证书
2. 编译 Ngrok
3. 配置系统服务
4. 配置客户端

## 📝 脚本详细说明

### 1. `deploy-ngrok-full.sh` - 一键部署脚本

**功能：** 自动化执行完整的 Ngrok 部署流程

**操作步骤：**
```bash
chmod +x deploy-ngrok-full.sh
sudo ./deploy-ngrok-full.sh
```

**执行内容：**
- 自动调用 `setup-ngrok-cert.sh` 生成证书
- 自动调用 `build-ngrok.sh` 编译服务端和客户端
- 自动调用 `setup-ngrok-service.sh` 配置系统服务
- 自动调用 `setup-ngrok-client.sh` 配置客户端

**部署完成后的后续操作：**
1. 阿里云安全组开放端口: 4443, 2222
2. 将客户端文件复制到本地机器
3. 在本地运行客户端启动脚本
4. 测试 SSH 连接

---

### 2. `setup-ngrok-cert.sh` - 证书生成脚本

**功能：** 生成自签名的根证书和服务器证书（包含 SAN 扩展）

**操作步骤：**
```bash
chmod +x setup-ngrok-cert.sh
sudo ./setup-ngrok-cert.sh
```

**执行内容：**
1. 清理旧证书文件
2. 生成根证书（rootCA.key, rootCA.pem）
3. 生成服务器密钥（server.key）
4. 创建包含 SAN 的配置文件
5. 生成证书请求（server.csr）
6. 生成 SAN 证书（server.crt）
7. 验证证书链和 SAN 扩展

**证书位置：** `/usr/local/ngrok/cert/`

**验证内容：**
- ✅ 根证书是自签名的
- ✅ 服务器证书由根证书签发
- ✅ 证书链验证通过
- ✅ SAN 扩展正确配置

---

### 3. `sync-ngrok-certs.sh` - 证书同步脚本

**功能：** 将生成的证书同步到 Ngrok 的 assets 目录

**操作步骤：**
```bash
chmod +x sync-ngrok-certs.sh
sudo ./sync-ngrok-certs.sh
```

**执行内容：**
1. 比较证书 MD5 值
2. 同步证书到以下位置：
   - `server.crt` → `/usr/local/ngrok/assets/server/tls/snakeoil.crt`
   - `server.key` → `/usr/local/ngrok/assets/server/tls/snakeoil.key`
   - `rootCA.pem` → `/usr/local/ngrok/assets/client/tls/ngrokroot.crt`
3. 验证同步后的证书链
4. 测试服务端 TLS 握手
5. 重启 ngrokd 服务

**使用场景：** 证书更新后需要同步到 Ngrok 目录

---

### 4. `build-ngrok.sh` - 编译脚本

**功能：** 编译 Ngrok 服务端和客户端（支持多平台）

**操作步骤：**
```bash
chmod +x build-ngrok.sh
sudo ./build-ngrok.sh
```

**执行内容：**
1. 编译 Linux 服务端（ngrokd）
2. 编译 Windows 客户端（amd64）
3. 编译 Linux 客户端（amd64）
4. 编译 macOS 客户端（darwin amd64）

**编译输出位置：** `/usr/local/ngrok/bin/`

**生成文件：**
- `linux_amd64/ngrokd` - Linux 服务端
- `windows_amd64/ngrok.exe` - Windows 客户端
- `linux_amd64/ngrok` - Linux 客户端
- `darwin_amd64/ngrok` - macOS 客户端

---

### 5. `setup-ngrok-service.sh` - 系统服务配置脚本

**功能：** 配置 Ngrok 服务端为 systemd 系统服务

**操作步骤：**
```bash
chmod +x setup-ngrok-service.sh
sudo ./setup-ngrok-service.sh
```

**执行内容：**
1. 停止现有 ngrokd 服务
2. 创建 systemd 服务文件（`/etc/systemd/system/ngrokd.service`）
3. 重新加载 systemd
4. 启用并启动 ngrokd 服务
5. 检查服务状态

**服务配置：**
- 域名：`ngrok.qiaopan.tech`
- TLS 隧道端口：`4443`
- HTTP 端口：`8080`
- HTTPS 端口：`8081`

**常用命令：**
```bash
sudo systemctl status ngrokd    # 查看状态
sudo systemctl restart ngrokd   # 重启服务
sudo systemctl stop ngrokd      # 停止服务
sudo systemctl start ngrokd     # 启动服务
sudo journalctl -u ngrokd -f    # 查看日志
```

---

### 6. `setup-ngrok-client.sh` - 客户端配置脚本

**功能：** 在本地机器配置 Ngrok 客户端

**操作步骤：**
```bash
chmod +x setup-ngrok-client.sh
./setup-ngrok-client.sh
```

**执行内容：**
1. 自动识别操作系统（macOS 或 Linux）
2. 创建客户端目录（`~/ngrok-client`）
3. 生成客户端配置文件（`ngrok.cfg`）
4. 创建客户端启动脚本（`start-ngrok-client.sh`）

**配置文件内容：**
- 服务器地址：`ngrok.qiaopan.tech:4443`
- 隧道类型：TCP
- 本地端口：22（SSH）
- 远程端口：2222

**使用步骤：**
1. 从服务器复制客户端文件到本地：
   ```bash
   # macOS
   scp root@服务器IP:/usr/local/ngrok/bin/darwin_amd64/ngrok ~/ngrok-client/
   
   # Linux
   scp root@服务器IP:/usr/local/ngrok/bin/linux_amd64/ngrok ~/ngrok-client/
   ```
2. 运行启动脚本：
   ```bash
   cd ~/ngrok-client
   ./start-ngrok-client.sh
   ```
3. 查看日志：
   ```bash
   tail -f ~/ngrok-client/ngrok-client.log
   ```

---

### 7. `start-ngrok-client.sh` - 客户端启动脚本

**功能：** 启动 Ngrok 客户端并建立隧道

**操作步骤：**
```bash
cd ~/ngrok-client
chmod +x start-ngrok-client.sh
./start-ngrok-client.sh
```

**执行内容：**
- 以后台方式启动 ngrok 客户端
- 使用 debug 日志级别
- 日志输出到 `ngrok-client.log`

**查看运行状态：**
```bash
# 查看日志
tail -f ~/ngrok-client/ngrok-client.log

# 查看进程
ps aux | grep ngrok
```

---

### 8. `verfiy_cert.sh` - 证书验证脚本

**功能：** 验证证书是否正确配置

**操作步骤：**
```bash
chmod +x verfiy_cert.sh
sudo ./verfiy_cert.sh
```

**执行内容：**
1. 验证证书是否为自签名证书
2. 测试服务端 TLS 握手
3. 检查服务端日志

**使用场景：** 证书配置出现问题时的诊断工具

---

### 9. `diagnose-connection.sh` - 连接诊断脚本

**功能：** 诊断客户端连接问题

**操作步骤：**
```bash
chmod +x diagnose-connection.sh
./diagnose-connection.sh
```

**执行内容：**
1. 测试 DNS 解析
2. 测试网络连通性（ping）
3. 测试端口连通性（telnet, nc）
4. 检查本地证书
5. 测试 TCP 连接
6. 检查路由跟踪

**使用场景：** 客户端无法连接到服务器时的故障排查

---

## 🔧 分步骤部署（手动执行）

如果需要分步骤执行，可以按以下顺序：

```bash
# 步骤1: 生成证书
chmod +x setup-ngrok-cert.sh
sudo ./setup-ngrok-cert.sh

# 步骤2: 同步证书到 Ngrok 目录
chmod +x sync-ngrok-certs.sh
sudo ./sync-ngrok-certs.sh

# 步骤3: 编译 Ngrok
chmod +x build-ngrok.sh
sudo ./build-ngrok.sh

# 步骤4: 配置系统服务
chmod +x setup-ngrok-service.sh
sudo ./setup-ngrok-service.sh

# 步骤5: 配置客户端（在本地机器执行）
chmod +x setup-ngrok-client.sh
./setup-ngrok-client.sh
```

---

## 📋 使用示例

### SSH 隧道示例

1. **服务端已部署完成**

2. **客户端配置和启动：**
   ```bash
   # 在本地机器执行
   cd ~/ngrok-client
   ./start-ngrok-client.sh
   ```

3. **测试 SSH 连接：**
   ```bash
   ssh -p 2222 用户名@ngrok.qiaopan.tech
   ```

### 其他服务隧道配置

修改 `~/ngrok-client/ngrok.cfg` 文件可以添加其他隧道：

```yaml
server_addr: "ngrok.qiaopan.tech:4443"
trust_host_root_certs: false
tunnels:
  ssh:
    proto:
      tcp: 22
    remote_port: 2222
  web:
    proto:
      http: 8080
    subdomain: myapp
```

---

## ⚠️ 注意事项

1. **证书域名：** 默认使用 `ngrok.qiaopan.tech`，如需修改请在所有脚本中统一更改
2. **防火墙：** 确保服务器防火墙和云服务商安全组都已开放相应端口
3. **客户端证书：** 客户端需要信任根证书才能正常连接
4. **服务重启：** 修改证书后需要重启 ngrokd 服务
5. **日志查看：** 遇到问题时查看服务端和客户端日志进行排查

---

## 🐛 故障排查

1. **服务无法启动：** 检查证书路径和权限
2. **客户端连接失败：** 使用 `diagnose-connection.sh` 诊断
3. **证书错误：** 使用 `verfiy_cert.sh` 验证证书
4. **端口被占用：** 检查端口占用情况：`netstat -tlnp | grep 4443`

```
