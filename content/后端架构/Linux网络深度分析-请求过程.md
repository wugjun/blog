---
title: "linux 网络深度分析"
date: 2026-05-27
description: "分析 linux 网络深度"
# lead: "聚社区之智，传技术之火"
disable_comments: false
authorbox: true
toc: false
mathjax: true
categories:
  - "linux网络"
tags:
  - "linux"

#draft: true
---

[◀ 返回](/后端架构/后端架构-兵法篇/)

# HTTP 请求在内核里的奇幻之旅

## 8 层网络

1. 用户态 application layer
2. 系统调用 `sys_sendto`
3. 传输层 TCP `tcp_sendmsg`
4. 网络层 IP `ip_queue_xmit`
5. 邻居子系统 ARP `ARP_Resolve`
6. 数据链路层 `dev_queue_xmit`
7. 驱动层 `ndo_start_xmit`
8. 网卡硬件 DMA + PHY

## 发送路径

```
用户空间
curl / Python / Nginx
|
send() / write()
====系统调用边界=======
VFS: sock_sendmsg()
|
TCP: tcp_sendmsg()
+-- copy_from_user
+-- tcp_push()
+-- tcp_write_xmit()
|
IP: ip_queue_xmit()
+--- 路由查找
+-- NETFILTER_HOOK
+-- ip_output()
|
邻居：neigh_output()
+-- ARP 查询
+-- dev_queue_xmit()
 |
驱动 ndo_start_xmit()
+-- DMA MAP
+-- TX 描述符
+-- write(tail)
======硬件边界======
NIC DMA → PHY → 电信号
```

---

## socket() 创建的内核数据结构

### 用户态 vs 内核态映射

用户调用 `socket()` 时，内核需要创建三层嵌套的数据结构：

```
用户态                          内核态
┌──────────┐                   ┌─────────────────────────────────┐
│  int fd  │  ←── fdtable ────▶ │  files_struct->fd[]             │
└──────────┘                   │                                  │
                               │  struct file *                  │
                               │  ├── f_op → sock_fops          │
                               │  └── private_data ─────────┐   │
                               └──────────────────────────────┼───┘
                                                              │
                                                    ┌─────────▼─────────┐
                                                    │   struct socket   │  (net/socket.c)
                                                    │  ├─ type: SOCK_STREAM
                                                    │  ├─ state: SS_UNCONNECTED
                                                    │  ├─ fasync_list   │
                                                    │  ├─ ops → tcp_socket_ops
                                                    │  └─ sk ───────────┼──┐
                                                    └─────────────────────┘  │
                                                                             │
                                                    ┌────────────────────────▼─────────┐
                                                    │       struct sock              │
                                                    │  ├─ sk_hash: 哈希桶索引        │
                                                    │  ├─ sk_state: TCP_SYN_SENT     │
                                                    │  ├─ sk_prot → tcp_prot         │
                                                    │  │   ├─ recvmsg                │
                                                    │  │   └─ sendmsg                │
                                                    │  ├─ sk_sleep: wait_queue_head_t│
                                                    │  │   阻塞等待队列(connect/send) │
                                                    │  ├─ sk_sndbuf: 发送缓冲区大小   │
                                                    │  ├─ sk_rcvbuf: 接收缓冲区大小   │
                                                    │  ├─ sk_allocation: GFP_KERNEL  │
                                                    │  ├─ sk_backlog:  backlog_head  │
                                                    │  │   半连接队列超限时转入       │
                                                    │  ├─ sk_wmem_alloc: 发送内存引用 │
                                                    │  └─ sk_rmem_alloc: 接收内存引用 │
                                                    └────────────────────────────────┘
                                                                             │
                                                    ┌────────────────────────▼─────────┐
                                                    │   struct tcp_sock (extends sock) │
                                                    │  ├─ write_queue: 待发送/已发送未确认
                                                    │  ├─ write_seq: 发送指针 N+1      │
                                                    │  ├─ rcv_nxt: 期望收到的序号       │
                                                    │  ├─ ssthresh: 慢启动阈值         │
                                                    │  ├─ cwnd: 拥塞窗口               │
                                                    │  ├─ snd_mss / rcv_mss: MSS      │
                                                    │  │  tcp_connect() 时确定         │
                                                    │  ├─ prequeue: 前队列             │
                                                    │  ├─ utime: 用户态耗时            │
                                                    │  └─ 各种标志位: ACK/Nagle/TSO    │
                                                    └────────────────────────────────┘
```

### 三层嵌套结构

| 层级 | 结构体 | 职责 | 文件位置 |
|------|--------|------|----------|
| 文件层 | `struct file` | VFS 统一文件抽象，fd 查找入口 | `fs/file_table.c` |
| 套接字层 | `struct socket` | 协议无关的 socket 抽象，管理状态和 ops | `net/socket.c` |
| 传输层 | `struct sock` → `struct tcp_sock` | 协议具体实现，缓冲区、状态机、拥塞控制 | `net/ipv4/tcp.c` |

### 关键指针链

```c
// 1. 用户传 fd，内核通过 files_struct 找到 file
struct file *filp = fget(fd);

// 2. file->private_data 指向 socket 对象
struct socket *sock = filp->private_data;

// 3. socket->sk 指向传输层 socket（最核心的数据结构）
struct sock *sk = sock->sk;

// 4. 按协议类型转换
struct tcp_sock *tp = tcp_sk(sk);
```

### 重要：socket() 和 connect() 的时机差异

```
socket() 系统调用时:
  ├── 只创建 struct socket
  ├── socket.state = SS_UNCONNECTED
  └── socket.sk = NULL  （此时还未分配 struct sock！）

connect() 系统调用时:
  ├── sk = sk_alloc()       → 分配 struct sock
  ├── sk->prot = &tcp_prot  → 绑定 TCP 操作集
  ├── tcp_connect()         → 发送 SYN，sk_state = TCP_SYN_SENT
  └── 建立哈希表条目        → 五元组 → hash bucket
```

---

## 系统调用全流程

| 步骤 | 系统调用 | 作用 |
|------|----------|------|
| 1 | `socket()` | 创建套接字，返回文件描述符 fd |
| 2 | `connect()` | 三次握手建立 TCP 连接 |
| 3 | `send()` / `write()` | 发送 HTTP 请求 |
| 4 | `recv()` / `read()` | 接收 HTTP 响应 |
| 5 | `close()` | 四次挥手关闭 TCP 连接 |

以 `sendto()` 为例，内核处理流程：

```c
// net/socket.c
int __sys_sendto(int fd, void __user *buff, size_t len, unsigned int flags,
                 struct sockaddr __user *addr, int addr_len)
{
    struct socket *sock;
    struct sockaddr_storage address;
    int err;
    struct msghdr msg;
    struct iovec iov;
    int fput_needed;

    err = import_single_range(WRITE, buff, len, &iov, &msg.msg_iter);
    if (unlikely(err))
        return err;

    // 1. 通过 fd 查找到内核 socket 对象
    sock = sockfd_lookup_light(fd, &err, &fput_needed);
    if (!sock)
        goto out;

    msg.msg_name = NULL;
    msg.msg_control = NULL;
    msg.msg_controllen = 0;
    msg.msg_namelen = 0;

    if (addr) {
        // 2. 复制用户空间地址到内核空间
        err = move_addr_to_kernel(addr, addr_len, &address);
        if (err < 0)
            goto out_put;
        msg.msg_name = (struct sockaddr *)&address;
        msg.msg_namelen = addr_len;
    }

    if (sock->file->f_flags & O_NONBLOCK)
        flags |= MSG_DONTWAIT;

    msg.msg_flags = flags;
    // 3. 调用 socket 操作函数 sendmsg 发送数据
    err = sock_sendmsg(sock, &msg);

out_put:
    fput_light(sock->file, fput_needed);
out:
    return err;
}
```

---

## tcp_sendmsg() 执行流程

```
tcp_sendmsg(sk, msg, size)
    |
    +-- 检查连接状态 == ESTABLISHED
    |
    +-- while(还有数据) {
    |   |
    |   +-- 尝试追加到现有 sk_buff
    |   |
    |   +-- 不够空间？分配新 sk_buff
    |   |     alloc_skb() + skb_reserve()
    |   |
    |   +-- copy_from_user()
    |   |   用户态 → 内核态唯一一次拷贝
    |   |
    |   +-- 更新 skb 信息
    |   }
    +-- tcp_push() → tcp_write_xmit()
        |
        +-- 将 sk_buff 发送到网络栈
```

---

## sk_buff 四指针操作

`sk_buff` 通过四个指针管理数据缓冲区，**数据本身从不移动，只移动指针**：

```
1. skb_reserve(data, len) — 预留 headroom
   head                            end
   |                               |
   [预留 headroom | 空闲数据区      ]
   |                               |
   data=tail (初始位置)

2. skb_put(len) — 填充用户数据，tail 右移
   head                           end
   |                              |
   [预留 | HTTP payload | 空闲    ]
   |                              |
   data                    tail→

3. skb_push(len) — 添加协议头，data 左移
   head        end
   |           |
   [TCP HDR|HTTP payload | 空闲]
   ←data    tail

4. skb_pull(len) — 剥离协议头，data 右移（接收路径）
```

### 分层封装示意

```
填充用户数据后 (TCP 层):
  head                           end
  |                              |
  [headroom| HTTP payload | 空闲]
  [预留   ｜ GET / HTTP/1.1   |  ]
          |                   |
          data                tail→  (tail 右移 len)

TCP 加头后 (skb_push):
  head                           end
  |                              |
  [剩余 | TCP HDR| HTTP payload | 空闲]
        |                   |
        data←              tail

IP 加头后 (skb_push 20B):
  head                           end
  |                              |
  [剩余| IP HDR| TCP HDR| HTTP | 空闲]
      |                          |
      data←                    tail

以太网加头后 (skb_push 14B):
  head                               end
  |                                  |
  [| ETH HDR| IP| TCP| HTTP payload| 空闲]
  |                                    |
 data←                                tail

// 数据从未移动，只有指针移动，相当于先预留空间，每层填充数据移动指针
```

---

## tcp_write_xmit() 发送调度器

```c
tcp_write_xmit(sk, mss_now, ...)
|
+-- while ((skb = tcp_send_head(sk))) {
|   |
|   +-- 拥塞控制检查
|   |   tcp_cwnd_test()  — cwnd 允许发送多少数据
|   |
|   +-- TSO/GSO 分段检查
|   |   超过 MSS？标记 GSO
|   |
|   +-- Nagle 算法检查
|   |   小包不能发？
|   |
|   +-- tcp_transmit_skb()  — 实际构造并发送
|   |
|   +-- tcp_cwnd_validate()
|   }
```

### tcp_transmit_skb() 详细流程

```c
int tcp_transmit_skb(struct sock *sk, struct sk_buff *skb,
                     int clone_it, gfp_t gfp)
{
    // 1. 设置序列号与标志位
    tcp_init_seq(skb)     ← 填充 TCP 序列号
    TCP_SKB_CB(skb)->flags = TCPHDR_ACK | TCPHDR_PSH

    // 2. 填充 TCP 选项（Timestamps / SACK / Window Scale）
    tcp_options_write()   ← 写入 tp->write_seq / rcv_tsoffset
                          典型 12~44 字节

    // 3. 构造 TCP 头部
    th = tcp_hdr(skb)
    th->source / th->dest
    th->seq = TCP_SKB_CB(skb)->seq
    th->doff = 选项长度 / 4
    th->window = tcp_receive_window(sk)

    // 4. 计算 TCP Checksum（TSO/GSO 时标记为分段校验）
    csum_tcpudp_magic(saddr, daddr, len, IPPROTO_TCP, 0)
    → skb->csum / CHECKSUM_PARTIAL

    // 5. 记录发送时间（用于 RTT 测量）
    TCP_SKB_CB(skb)->when = ktime_get_tcp_db()

    // 6. 加入重传队列
    tcp_mark_head_lost()          ← 标记超时/失序段
    __tcp_add_write_queue_tail()
    sk_mem_charge()               ← 计入 sock 内存使用

    // 7. 更新拥塞窗口 & 统计
    tp->packets_out += tcp_skb_pcount(skb)
    tp->bytes_sent += skb->len
    tcp_cong_avoid()              ← CUBIC/BBR 等算法回调

    // 8. 触发 ECN/CWR
    if (ECE) TCP_SKB_CB(skb)->ece = 1
    if (CWR) tp->flags &= ~TCP_CWR_FLAG

    // 9. 交给 IP 层
    inet_csk(sk)->icsk_af_ops->queue_xmit(skb, &inet->cork.fl)
    → ip_queue_xmit()
    → dst_output()
    → 进入网络层
}
```
