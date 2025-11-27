#!/bin/bash

# 部署配置
REMOTE_HOST="qiaopan.tech"
REMOTE_USER="root"  # 根据实际情况修改用户名
REMOTE_PATH="/var/www/myblog/html"
LOCAL_PUBLIC_DIR="./public"
DEPLOY_LOG="./deploy_history.log"
INCLUDE_DRAFTS=false  # 是否包含草稿内容

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 错误处理
set -e
trap 'echo -e "${RED}部署失败！${NC}"' ERR

# 记录部署日志
log_deploy() {
    local version=$1
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] 部署版本: $version 到 $REMOTE_HOST:$REMOTE_PATH" >> "$DEPLOY_LOG"
}

# 生成版本号
generate_version() {
    echo "v$(date '+%Y%m%d-%H%M%S')"
}

# 主函数
main() {
    echo -e "${GREEN}开始部署到 qiaopan.tech...${NC}"
    
    # 1. 构建 Hugo 站点
    echo -e "${YELLOW}步骤 1/4: 构建 Hugo 站点 (使用 --minify)${NC}"
    if [ "$INCLUDE_DRAFTS" = true ]; then
        echo -e "${YELLOW}  包含草稿内容 (--buildDrafts)${NC}"
        hugo --minify --buildDrafts
    else
        hugo --minify
    fi
    if [ $? -ne 0 ]; then
        echo -e "${RED}Hugo 构建失败！${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Hugo 构建完成${NC}"
    
    # 2. 检查 public 目录
    if [ ! -d "$LOCAL_PUBLIC_DIR" ]; then
        echo -e "${RED}错误: $LOCAL_PUBLIC_DIR 目录不存在！${NC}"
        exit 1
    fi
    
    # 3. 生成版本号
    VERSION=$(generate_version)
    echo -e "${YELLOW}步骤 2/4: 生成部署版本号${NC}"
    echo -e "${GREEN}版本号: $VERSION${NC}"
    
    # 4. 部署到远程服务器
    echo -e "${YELLOW}步骤 3/4: 部署到远程服务器${NC}"
    echo -e "目标: ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}"
    
    # 使用 rsync 同步文件（推荐方式，支持增量更新）
    rsync -avz --delete \
        --exclude='.git' \
        --exclude='.DS_Store' \
        "$LOCAL_PUBLIC_DIR/" \
        "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}/"
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}rsync 同步失败！${NC}"
        echo -e "${YELLOW}提示: 请确保已配置 SSH 密钥认证或准备好密码${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ 文件同步完成${NC}"
    
    # 5. 在远程服务器创建版本标记文件
    echo -e "${YELLOW}步骤 4/4: 创建版本标记${NC}"
    ssh "${REMOTE_USER}@${REMOTE_HOST}" "echo '$VERSION' > ${REMOTE_PATH}/.deploy_version && echo '$(date)' >> ${REMOTE_PATH}/.deploy_version"
    
    # 6. 记录部署日志
    log_deploy "$VERSION"
    
    # 7. 显示部署信息
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}部署成功！${NC}"
    echo -e "${GREEN}版本号: $VERSION${NC}"
    echo -e "${GREEN}目标服务器: $REMOTE_HOST${NC}"
    echo -e "${GREEN}目标路径: $REMOTE_PATH${NC}"
    echo -e "${GREEN}部署时间: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    
    # 8. 可选：在本地 git 中创建 tag（如果当前目录是 git 仓库）
    if [ -d ".git" ]; then
        read -p "是否创建 git tag? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git tag -a "$VERSION" -m "Deploy to qiaopan.tech: $VERSION"
            echo -e "${GREEN}✓ Git tag 已创建: $VERSION${NC}"
            read -p "是否推送 tag 到远程仓库? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                git push origin "$VERSION"
                echo -e "${GREEN}✓ Git tag 已推送${NC}"
            fi
        fi
    fi
}

# 显示使用说明
show_usage() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -D, --drafts    包含草稿内容 (相当于 hugo server -D)"
    echo "  -h, --help     显示此帮助信息"
    echo ""
    echo "功能:"
    echo "  1. 使用 hugo --minify 构建站点"
    echo "  2. 将 public 目录部署到 qiaopan.tech 服务器"
    echo "  3. 创建版本标记和部署日志"
    echo ""
    echo "配置:"
    echo "  远程服务器: $REMOTE_HOST"
    echo "  远程用户: $REMOTE_USER"
    echo "  远程路径: $REMOTE_PATH"
    echo ""
    echo "提示:"
    echo "  - 默认不包含草稿内容，使用 -D 参数可包含草稿"
    echo "  - 确保已配置 SSH 密钥认证"
    echo "  - 确保远程服务器目录存在且有写权限"
    echo "  - 部署历史记录在: $DEPLOY_LOG"
    echo ""
    echo "示例:"
    echo "  $0              # 正常部署（不包含草稿）"
    echo "  $0 -D           # 部署包含草稿内容"
    echo "  $0 --drafts     # 同上"
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -D|--drafts)
            INCLUDE_DRAFTS=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo -e "${RED}未知参数: $1${NC}"
            show_usage
            exit 1
            ;;
    esac
done

# 执行主函数
main
