#!/bin/bash

# 自动发布新增文章到微信公众号
# 使用方法: ./scripts/publish_new_articles.sh [--publish]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BLOG_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PYTHON_SCRIPT="$SCRIPT_DIR/publish_to_wechat.py"
TRACKING_FILE="$SCRIPT_DIR/published_articles.json"

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 检查Python环境
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}错误: 未找到python3${NC}"
    exit 1
fi

# 安装依赖
echo -e "${YELLOW}检查Python依赖...${NC}"
if [ ! -f "$SCRIPT_DIR/.venv/bin/activate" ]; then
    echo -e "${YELLOW}创建虚拟环境...${NC}"
    cd "$SCRIPT_DIR"
    python3 -m venv .venv
    source .venv/bin/activate
    pip install -r requirements.txt
else
    source "$SCRIPT_DIR/.venv/bin/activate"
fi

# 初始化已发布文章追踪文件
if [ ! -f "$TRACKING_FILE" ]; then
    echo "[]" > "$TRACKING_FILE"
fi

# 获取新增或修改的文章
get_new_articles() {
    local new_articles=()
    
    # 查找所有Markdown文件
    while IFS= read -r -d '' file; do
        # 跳过draft文件
        if grep -q "^draft: true" "$file" 2>/dev/null; then
            continue
        fi
        
        # 检查是否已发布
        local file_hash=$(md5sum "$file" | cut -d' ' -f1)
        local file_path=$(realpath --relative-to="$BLOG_DIR" "$file")
        
        if ! grep -q "\"$file_path\"" "$TRACKING_FILE" 2>/dev/null; then
            new_articles+=("$file")
        fi
    done < <(find "$BLOG_DIR/content" -name "*.md" -type f -print0)
    
    printf '%s\n' "${new_articles[@]}"
}

# 标记文章为已发布
mark_as_published() {
    local file="$1"
    local file_path=$(realpath --relative-to="$BLOG_DIR" "$file")
    local file_hash=$(md5sum "$file" | cut -d' ' -f1)
    local timestamp=$(date -Iseconds)
    
    # 读取现有记录
    local temp_file=$(mktemp)
    if [ -f "$TRACKING_FILE" ]; then
        cat "$TRACKING_FILE" > "$temp_file"
    else
        echo "[]" > "$temp_file"
    fi
    
    # 添加新记录（使用Python处理JSON）
    python3 << EOF
import json
import sys

with open("$temp_file", 'r', encoding='utf-8') as f:
    records = json.load(f)

# 检查是否已存在
exists = False
for record in records:
    if record.get('path') == "$file_path":
        record['hash'] = "$file_hash"
        record['published_at'] = "$timestamp"
        exists = True
        break

if not exists:
    records.append({
        "path": "$file_path",
        "hash": "$file_hash",
        "published_at": "$timestamp"
    })

with open("$TRACKING_FILE", 'w', encoding='utf-8') as f:
    json.dump(records, f, ensure_ascii=False, indent=2)
EOF
    
    rm "$temp_file"
}

# 主函数
main() {
    cd "$BLOG_DIR"
    
    echo -e "${GREEN}开始检查新增文章...${NC}"
    
    # 获取新增文章（兼容 macOS 的 bash 3.x）
    new_articles=()
    while IFS= read -r line; do
        [ -n "$line" ] && new_articles+=("$line")
    done < <(get_new_articles)
    
    if [ ${#new_articles[@]} -eq 0 ]; then
        echo -e "${YELLOW}没有发现新文章${NC}"
        exit 0
    fi
    
    echo -e "${GREEN}发现 ${#new_articles[@]} 篇新文章:${NC}"
    for article in "${new_articles[@]}"; do
        echo "  - $(basename "$article")"
    done
    
    # 检查是否使用发布模式
    local publish_mode=""
    if [ "$1" == "--publish" ]; then
        publish_mode="--publish"
        echo -e "\n${YELLOW}⚠️  发布模式: 将实际发布到微信公众号${NC}"
        read -p "确认继续? (y/N): " confirm
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            echo "已取消"
            exit 0
        fi
    else
        echo -e "\n${YELLOW}预览模式: 不会实际发布${NC}"
        echo "使用 --publish 参数实际发布"
    fi
    
    # 发布每篇文章
    local success_count=0
    for article in "${new_articles[@]}"; do
        echo -e "\n${GREEN}处理: $(basename "$article")${NC}"
        
        if python3 "$PYTHON_SCRIPT" "$article" $publish_mode; then
            if [ "$publish_mode" == "--publish" ]; then
                mark_as_published "$article"
                success_count=$((success_count + 1))
            else
                success_count=$((success_count + 1))
            fi
        else
            echo -e "${RED}处理失败: $(basename "$article")${NC}"
        fi
    done
    
    echo -e "\n${GREEN}完成: 成功处理 $success_count/${#new_articles[@]} 篇文章${NC}"
}

# 运行主函数
main "$@"

