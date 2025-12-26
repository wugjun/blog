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
        local file_path=$(realpath --relative-to="$BLOG_DIR" "$file")
        
        # 使用Python检查JSON文件，更可靠
        local is_tracked=$(python3 << EOF
import json
import sys
import os

file_path = "$file_path"
tracking_file = "$TRACKING_FILE"

try:
    if not os.path.exists(tracking_file):
        print("0")  # 文件不存在，视为未追踪
        sys.exit(0)
    
    with open(tracking_file, 'r', encoding='utf-8') as f:
        content = f.read().strip()
        if not content or content == "[]":
            print("0")  # 文件为空，视为未追踪
            sys.exit(0)
        
        records = json.loads(content)
    
    # 检查文件路径是否在记录中
    for record in records:
        if record.get('path') == file_path:
            print("1")  # 已追踪
            sys.exit(0)
    
    print("0")  # 未追踪
    sys.exit(0)
except Exception as e:
    print("0")  # 出错，视为未追踪
    sys.exit(0)
EOF
)
        
        if [ "$is_tracked" = "0" ]; then
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

# 初始化追踪文件（将现有非草稿文章标记为已发布，避免重复发布）
init_tracking_file() {
    echo -e "${YELLOW}初始化追踪文件...${NC}"
    
    local count=0
    while IFS= read -r -d '' file; do
        # 跳过draft文件
        if grep -q "^draft: true" "$file" 2>/dev/null; then
            continue
        fi
        
        local file_path=$(realpath --relative-to="$BLOG_DIR" "$file")
        local file_hash=$(md5sum "$file" | cut -d' ' -f1)
        local timestamp=$(date -Iseconds)
        
        # 检查是否已存在
        local exists=$(python3 << EOF
import json
import sys
import os

file_path = "$file_path"
tracking_file = "$TRACKING_FILE"

try:
    if not os.path.exists(tracking_file):
        print("0")
        sys.exit(0)
    
    with open(tracking_file, 'r', encoding='utf-8') as f:
        content = f.read().strip()
        if not content or content == "[]":
            print("0")
            sys.exit(0)
        
        records = json.loads(content)
    
    for record in records:
        if record.get('path') == file_path:
            print("1")
            sys.exit(0)
    
    print("0")
    sys.exit(0)
except Exception:
    print("0")
    sys.exit(0)
EOF
)
        
        if [ "$exists" != "1" ]; then
            # 添加到追踪文件
            python3 << EOF
import json
import os

file_path = "$file_path"
file_hash = "$file_hash"
timestamp = "$timestamp"

# 读取现有记录
if os.path.exists("$TRACKING_FILE"):
    with open("$TRACKING_FILE", 'r', encoding='utf-8') as f:
        records = json.load(f)
else:
    records = []

# 添加新记录
records.append({
    "path": file_path,
    "hash": file_hash,
    "published_at": timestamp,
    "auto_init": True  # 标记为自动初始化
})

# 保存
with open("$TRACKING_FILE", 'w', encoding='utf-8') as f:
    json.dump(records, f, ensure_ascii=False, indent=2)
EOF
            count=$((count + 1))
        fi
    done < <(find "$BLOG_DIR/content" -name "*.md" -type f -print0)
    
    if [ $count -gt 0 ]; then
        echo -e "${GREEN}✓ 已初始化 $count 篇现有文章到追踪文件${NC}"
    else
        echo -e "${YELLOW}所有文章已在追踪文件中${NC}"
    fi
}

# 主函数
main() {
    cd "$BLOG_DIR"
    
    # 如果追踪文件为空或不存在，先初始化
    if [ ! -f "$TRACKING_FILE" ] || [ ! -s "$TRACKING_FILE" ] || [ "$(cat "$TRACKING_FILE")" = "[]" ]; then
        echo -e "${YELLOW}追踪文件为空，是否初始化现有文章？${NC}"
        echo -e "${YELLOW}（这将把所有非草稿文章标记为已发布，避免重复发布）${NC}"
        read -p "初始化? (y/N): " init_confirm
        if [ "$init_confirm" = "y" ] || [ "$init_confirm" = "Y" ]; then
            init_tracking_file
        fi
    fi
    
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

