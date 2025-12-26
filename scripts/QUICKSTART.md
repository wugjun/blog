# 微信公众号自动发布 - 快速开始

## 第一步：获取微信公众号凭证

1. 登录[微信公众平台](https://mp.weixin.qq.com/)
2. 进入 **开发 -> 基本配置**
3. 记录以下信息：
   - **AppID** (应用ID)
   - **AppSecret** (应用密钥)

4. **重要：配置IP白名单**
   - 获取当前公网IP：
     ```bash
     ./scripts/get_current_ip.sh
     # 或
     curl https://api.ipify.org
     ```
   - 在 **开发 -> 基本配置 -> IP白名单** 中添加你的IP地址
   - 如果不配置IP白名单，API调用会失败（错误代码：40164）

## 第二步：配置环境变量

### 本地使用

```bash
# 临时设置（当前终端会话）
export WECHAT_APPID='your_appid_here'
export WECHAT_APPSECRET='your_appsecret_here'

# 永久设置（添加到 ~/.bashrc 或 ~/.zshrc）
echo 'export WECHAT_APPID="your_appid_here"' >> ~/.zshrc
echo 'export WECHAT_APPSECRET="your_appsecret_here"' >> ~/.zshrc
source ~/.zshrc
```

### GitHub Actions使用

1. 进入GitHub仓库
2. 点击 **Settings -> Secrets and variables -> Actions**
3. 添加以下Secrets：
   - `WECHAT_APPID`: 你的AppID
   - `WECHAT_APPSECRET`: 你的AppSecret

## 第三步：安装依赖

```bash
cd scripts
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## 第四步：测试发布（预览模式）

```bash
# 在博客根目录执行
./scripts/publish_new_articles.sh
```

这会：
- ✅ 检测新增文章
- ✅ 转换为微信公众号格式
- ✅ 显示预览内容
- ❌ **不会实际发布**

## 第五步：实际发布

确认预览内容无误后：

```bash
./scripts/publish_new_articles.sh --publish
```

## 发布指定文章

```bash
cd scripts
source .venv/bin/activate
python3 publish_to_wechat.py ../content/后端架构/第一章-单机苦修·草根启程.md --publish
```

## 常见问题

### Q: 如何只发布特定目录的文章？

A: 修改 `publish_new_articles.sh` 中的查找逻辑，或直接指定文件：

```bash
python3 scripts/publish_to_wechat.py content/后端架构/第一章-单机苦修·草根启程.md --publish
```

### Q: 图片上传失败怎么办？

A: 检查：
1. 图片路径是否正确（相对于content目录）
2. 图片大小是否超过5MB
3. 图片格式是否支持（jpg, png, gif等）

### Q: 如何跳过草稿文章？

A: 脚本会自动跳过 `draft: true` 的文章。确保你的Front Matter中有：

```yaml
---
draft: true
---
```

### Q: 如何重新发布已发布的文章？

A: 删除 `scripts/published_articles.json` 中对应的记录，或直接删除整个文件。

## 下一步

- 查看 [README.md](README.md) 了解详细功能
- 配置 GitHub Actions 实现自动发布
- 自定义转换规则以适应你的需求

