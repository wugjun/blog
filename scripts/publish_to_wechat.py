#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
微信公众号自动发布脚本
功能：将Hugo博客的Markdown文件转换为微信公众号格式并自动发布
"""

import os
import re
import sys
import json
import requests
import markdown
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional
import yaml
from html.parser import HTMLParser
from html import unescape

# 配置微信公众号API
WECHAT_CONFIG = {
    'appid': os.getenv('WECHAT_APPID', ''),
    'appsecret': os.getenv('WECHAT_APPSECRET', ''),
    'access_token_url': 'https://api.weixin.qq.com/cgi-bin/token',
    'upload_url': 'https://api.weixin.qq.com/cgi-bin/media/upload',  # 上传临时素材
    'upload_img_url': 'https://api.weixin.qq.com/cgi-bin/media/uploadimg',  # 上传图片（用于图文消息）
    'add_news_url': 'https://api.weixin.qq.com/cgi-bin/material/add_news',  # 新增永久图文素材
    'add_draft_url': 'https://api.weixin.qq.com/cgi-bin/draft/add',  # 新增草稿
    'upload_thumb_url': 'https://api.weixin.qq.com/cgi-bin/material/add_material',  # 上传永久素材（封面图）
}

class WeChatPublisher:
    """微信公众号发布器"""
    
    def __init__(self):
        self.access_token = None
        self.uploaded_images = {}  # 本地图片路径 -> 微信图片URL映射
        
    def get_access_token(self) -> Optional[str]:
        """获取Access Token"""
        if self.access_token:
            return self.access_token
            
        params = {
            'grant_type': 'client_credential',
            'appid': WECHAT_CONFIG['appid'],
            'secret': WECHAT_CONFIG['appsecret']
        }
        
        try:
            response = requests.get(WECHAT_CONFIG['access_token_url'], params=params, timeout=10)
            response.raise_for_status()
            data = response.json()
            
            if 'access_token' in data:
                self.access_token = data['access_token']
                print(f"✓ 成功获取Access Token")
                return self.access_token
            else:
                error_msg = data.get('errmsg', '未知错误')
                error_code = data.get('errcode', '')
                
                # 处理常见的错误
                if error_code == 40164:
                    print(f"✗ 获取Access Token失败: IP地址不在白名单中")
                    print(f"  错误代码: {error_code}")
                    print(f"  错误信息: {error_msg}")
                    print(f"\n解决方案:")
                    print(f"  1. 登录微信公众平台: https://mp.weixin.qq.com")
                    print(f"  2. 进入 开发 -> 基本配置 -> IP白名单")
                    print(f"  3. 添加当前IP地址到白名单")
                    print(f"  4. 或者使用服务器IP（如果通过服务器调用）")
                elif error_code == 40013:
                    print(f"✗ 获取Access Token失败: AppID无效")
                    print(f"  请检查 WECHAT_APPID 是否正确")
                elif error_code == 40125:
                    print(f"✗ 获取Access Token失败: AppSecret无效")
                    print(f"  请检查 WECHAT_APPSECRET 是否正确")
                else:
                    print(f"✗ 获取Access Token失败: {error_msg} (错误代码: {error_code})")
                
                return None
        except Exception as e:
            print(f"✗ 获取Access Token异常: {e}")
            return None
    
    def upload_image(self, image_path: str) -> Optional[str]:
        """上传图片到微信公众号（用于图文消息内容）"""
        if image_path in self.uploaded_images:
            return self.uploaded_images[image_path]
        
        access_token = self.get_access_token()
        if not access_token:
            return None
        
        url = f"{WECHAT_CONFIG['upload_img_url']}?access_token={access_token}"
        
        try:
            with open(image_path, 'rb') as f:
                files = {'media': f}
                response = requests.post(url, files=files, timeout=30)
                response.raise_for_status()
                data = response.json()
                
                if 'url' in data:
                    image_url = data['url']
                    self.uploaded_images[image_path] = image_url
                    print(f"✓ 上传图片成功: {os.path.basename(image_path)}")
                    return image_url
                else:
                    error_msg = data.get('errmsg', '未知错误')
                    error_code = data.get('errcode', '')
                    print(f"✗ 上传图片失败: {error_msg} (错误代码: {error_code})")
                    return None
        except Exception as e:
            print(f"✗ 上传图片异常: {e}")
            return None
    
    def upload_thumb(self, image_path: str) -> Optional[str]:
        """上传封面图（永久素材），返回media_id"""
        access_token = self.get_access_token()
        if not access_token:
            return None
        
        url = f"{WECHAT_CONFIG['upload_thumb_url']}?access_token={access_token}&type=thumb"
        
        try:
            # 检查文件大小（封面图限制1MB）
            file_size = os.path.getsize(image_path)
            if file_size > 1024 * 1024:  # 1MB
                print(f"⚠️  警告: 封面图大小 {file_size/1024:.1f}KB，建议小于1MB")
            
            with open(image_path, 'rb') as f:
                files = {'media': f}
                response = requests.post(url, files=files, timeout=30)
                response.raise_for_status()
                data = response.json()
                
                if 'media_id' in data:
                    media_id = data['media_id']
                    print(f"✓ 上传封面图成功: {os.path.basename(image_path)} (media_id: {media_id[:20]}...)")
                    return media_id
                else:
                    error_msg = data.get('errmsg', '未知错误')
                    error_code = data.get('errcode', '')
                    print(f"✗ 上传封面图失败: {error_msg} (错误代码: {error_code})")
                    return None
        except Exception as e:
            print(f"✗ 上传封面图异常: {e}")
            return None
    
    def parse_front_matter(self, content: str) -> tuple:
        """解析Front Matter"""
        if not content.startswith('---'):
            return {}, content
        
        parts = content.split('---', 2)
        if len(parts) < 3:
            return {}, content
        
        try:
            front_matter = yaml.safe_load(parts[1])
            body = parts[2].strip()
            return front_matter or {}, body
        except:
            return {}, content
    
    def markdown_to_wechat_html(self, md_content: str, base_dir: str = '') -> str:
        """将Markdown转换为微信公众号HTML格式"""
        # 解析Front Matter
        front_matter, body = self.parse_front_matter(md_content)
        
        # 转换Markdown为HTML
        md = markdown.Markdown(extensions=[
            'markdown.extensions.codehilite',
            'markdown.extensions.fenced_code',
            'markdown.extensions.tables',
            'markdown.extensions.toc'
        ])
        html = md.convert(body)
        
        # 处理图片：上传到微信并替换URL
        def replace_image(match):
            alt = match.group(1)
            src = match.group(2)
            
            # 处理相对路径
            if not src.startswith('http'):
                if base_dir:
                    image_path = os.path.join(base_dir, src)
                else:
                    image_path = src
                
                if os.path.exists(image_path):
                    wechat_url = self.upload_image(image_path)
                    if wechat_url:
                        return f'<img src="{wechat_url}" alt="{alt}"/>'
            
            # 如果是外部URL，直接使用
            return f'<img src="{src}" alt="{alt}"/>'
        
        # 替换图片标签
        html = re.sub(r'<img[^>]*src=["\']([^"\']+)["\'][^>]*alt=["\']([^"\']*)["\'][^>]*>', 
                     lambda m: replace_image(m) if 'src=' in m.group(0) else m.group(0), 
                     html)
        html = re.sub(r'!\[([^\]]*)\]\(([^)]+)\)', replace_image, html)
        
        # 处理代码块：微信公众号不支持代码高亮，转换为纯文本
        html = re.sub(r'<pre><code[^>]*>(.*?)</code></pre>', 
                     lambda m: f'<pre>{unescape(m.group(1))}</pre>', 
                     html, flags=re.DOTALL)
        
        # 处理内联代码
        html = re.sub(r'<code[^>]*>(.*?)</code>', 
                     lambda m: f'<code>{unescape(m.group(1))}</code>', 
                     html)
        
        # 添加样式（微信公众号支持的样式有限）
        styled_html = f"""
<div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen', 'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue', sans-serif; line-height: 1.8; color: #333;">
{html}
</div>
"""
        return styled_html.strip()
    
    def publish_article(self, md_file: str, publish: bool = False) -> bool:
        """发布文章到微信公众号"""
        md_path = Path(md_file)
        if not md_path.exists():
            print(f"✗ 文件不存在: {md_file}")
            return False
        
        print(f"\n开始处理: {md_path.name}")
        
        # 读取Markdown内容
        with open(md_path, 'r', encoding='utf-8') as f:
            md_content = f.read()
        
        # 解析Front Matter
        front_matter, body = self.parse_front_matter(md_content)
        
        # 获取文章信息
        title = front_matter.get('title', md_path.stem)
        description = front_matter.get('description', front_matter.get('lead', ''))
        
        # 确定图片基础目录
        content_dir = md_path.parent
        images_dir = content_dir.parent / 'images'
        
        # 转换为微信公众号HTML
        html_content = self.markdown_to_wechat_html(md_content, str(images_dir))
        
        # 如果是预览模式，只输出内容
        if not publish:
            print("\n" + "="*50)
            print("预览模式 - 文章内容:")
            print("="*50)
            print(f"标题: {title}")
            print(f"摘要: {description}")
            print(f"\n内容长度: {len(html_content)} 字符")
            print("\n提示: 使用 --publish 参数实际发布到微信公众号")
            return True
        
        # 发布到微信公众号
        print("\n开始发布到微信公众号...")
        
        # 1. 上传封面图
        thumb_media_id = None
        # 尝试从文章目录或images目录查找封面图
        cover_image_paths = [
            content_dir / 'cover.jpg',
            content_dir / 'cover.png',
            images_dir / f'{md_path.stem}.jpg',
            images_dir / f'{md_path.stem}.png',
            images_dir / 'cover.jpg',
            images_dir / 'cover.png',
        ]
        
        cover_image = None
        for path in cover_image_paths:
            if path.exists():
                cover_image = str(path)
                break
        
        if cover_image:
            print(f"找到封面图: {cover_image}")
            thumb_media_id = self.upload_thumb(cover_image)
        else:
            print("⚠️  未找到封面图，将使用默认封面")
            # 可以提示用户上传封面图，或使用默认图片
            print("提示: 在文章目录或content/images/目录放置cover.jpg或cover.png作为封面图")
            # 这里可以选择：1. 使用默认封面 2. 跳过封面 3. 要求用户提供
            use_default = input("是否继续发布（无封面图）? (y/N): ").strip().lower()
            if use_default != 'y':
                print("已取消发布")
                return False
        
        if not thumb_media_id:
            print("⚠️  警告: 未获取到封面图media_id，将尝试无封面发布")
        
        # 2. 构建图文消息
        article_data = {
            "articles": [{
                "title": title,
                "thumb_media_id": thumb_media_id or "",  # 封面图media_id
                "author": front_matter.get('author', ''),
                "digest": description[:120] if description else title[:120],  # 摘要最多120字
                "show_cover_pic": 1 if thumb_media_id else 0,  # 是否显示封面
                "content": html_content,
                "content_source_url": "",  # 原文链接，可以设置为博客URL
            }]
        }
        
        # 3. 发布到素材库（永久素材）
        access_token = self.get_access_token()
        if not access_token:
            return False
        
        url = f"{WECHAT_CONFIG['add_news_url']}?access_token={access_token}"
        
        try:
            response = requests.post(url, json=article_data, timeout=30)
            response.raise_for_status()
            data = response.json()
            
            if 'media_id' in data:
                media_id = data['media_id']
                print(f"\n✓ 文章发布成功!")
                print(f"  标题: {title}")
                print(f"  Media ID: {media_id}")
                print(f"\n下一步:")
                print(f"  1. 登录微信公众平台: https://mp.weixin.qq.com")
                print(f"  2. 进入 素材管理 -> 图文消息")
                print(f"  3. 找到刚发布的文章，可以预览、编辑或群发")
                return True
            else:
                error_msg = data.get('errmsg', '未知错误')
                error_code = data.get('errcode', '')
                print(f"\n✗ 发布失败: {error_msg} (错误代码: {error_code})")
                
                # 常见错误处理
                if error_code == 40007:
                    print("  提示: 可能是封面图media_id无效，请检查封面图")
                elif error_code == 40008:
                    print("  提示: 可能是文章内容格式不正确")
                
                return False
        except Exception as e:
            print(f"\n✗ 发布异常: {e}")
            return False


def main():
    """主函数"""
    import argparse
    
    parser = argparse.ArgumentParser(description='发布文章到微信公众号')
    parser.add_argument('files', nargs='+', help='要发布的Markdown文件')
    parser.add_argument('--publish', action='store_true', help='实际发布（否则只预览）')
    parser.add_argument('--config', help='配置文件路径')
    
    args = parser.parse_args()
    
    # 检查配置
    if not WECHAT_CONFIG['appid'] or not WECHAT_CONFIG['appsecret']:
        print("⚠️  警告: 未设置微信公众号配置")
        print("请设置环境变量:")
        print("  export WECHAT_APPID='your_appid'")
        print("  export WECHAT_APPSECRET='your_appsecret'")
        if not args.publish:
            print("\n继续预览模式...")
        else:
            print("\n无法发布，退出")
            sys.exit(1)
    
    publisher = WeChatPublisher()
    
    success_count = 0
    for file in args.files:
        if publisher.publish_article(file, args.publish):
            success_count += 1
    
    print(f"\n处理完成: {success_count}/{len(args.files)}")
    
    if not args.publish:
        print("\n提示: 使用 --publish 参数实际发布到微信公众号")


if __name__ == '__main__':
    main()

