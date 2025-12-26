#!/bin/bash
# 获取当前公网IPv4地址

echo "正在获取当前公网IPv4地址..."
echo ""

# 验证是否为IPv4地址的函数
is_ipv4() {
    local ip=$1
    # 检查格式：xxx.xxx.xxx.xxx (1-3位数字，4段)
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 0
    else
        return 1
    fi
}
# 方法2: 使用 ifconfig.me (强制IPv4)
IP2=$(curl -s -4 https://ifconfig.me 2>/dev/null | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$')
if [ -n "$IP2" ] && is_ipv4 "$IP2"; then
    echo "✓ 方法2 (ifconfig.me): $IP2"
    if [ -z "$MAIN_IP" ]; then
        MAIN_IP="$IP2"
    fi
fi

# 方法3: 使用 icanhazip.com (强制IPv4)
IP3=$(curl -s -4 https://icanhazip.com 2>/dev/null | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$')
if [ -n "$IP3" ] && is_ipv4 "$IP3"; then
    echo "✓ 方法3 (icanhazip.com): $IP3"
    if [ -z "$MAIN_IP" ]; then
        MAIN_IP="$IP3"
    fi
fi

# 方法4: 使用 ip.sb (专门返回IPv4)
IP4=$(curl -s -4 https://api.ip.sb/ip 2>/dev/null | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$')
if [ -n "$IP4" ] && is_ipv4 "$IP4"; then
    echo "✓ 方法4 (ip.sb): $IP4"
    if [ -z "$MAIN_IP" ]; then
        MAIN_IP="$IP4"
    fi
fi

echo ""
if [ -n "$MAIN_IP" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "你的IPv4地址: $MAIN_IP"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "请将此IP地址添加到微信公众号的IP白名单中："
    echo "1. 登录 https://mp.weixin.qq.com"
    echo "2. 进入 开发 -> 基本配置 -> IP白名单"
    echo "3. 添加IP地址: $MAIN_IP"
    echo "4. 保存配置"
else
    echo "⚠️  无法获取IPv4地址，请检查网络连接"
    echo ""
    echo "手动获取方法："
    echo "  curl -4 https://api.ipify.org"
fi

