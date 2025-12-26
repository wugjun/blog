# 微信公众号自动发布脚本

自动将Hugo博客的新增文章发布到微信公众号。

## 功能特性

- ✅ 自动检测新增或修改的文章
- ✅ 将Markdown转换为微信公众号格式
- ✅ 自动上传图片到微信公众号
- ✅ 支持预览模式（不实际发布）
- ✅ 追踪已发布的文章，避免重复发布

## 安装依赖

```bash
cd scripts
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## 配置微信公众号

1. 登录[微信公众平台](https://mp.weixin.qq.com/)
2. 获取AppID和AppSecret（开发 -> 基本配置）
3. 设置环境变量：

```bash
export WECHAT_APPID='wx1ef24c959b4c6fb6'
export WECHAT_APPSECRET='aa9183d44cc3af36e9a912ac266d60f8'
```

或者创建 `.env` 文件：

```bash
WECHAT_APPID=your_appid
WECHAT_APPSECRET=your_appsecret
```

## 使用方法

### 预览模式（推荐先使用）

```bash
./scripts/publish_new_articles.sh
```

这会：
- 检测所有新增文章
- 转换为微信公众号格式
- 显示预览内容
- **不会实际发布**

### 实际发布

```bash
./scripts/publish_new_articles.sh --publish
```

这会：
- 检测所有新增文章
- 转换为微信公众号格式
- 上传图片
- **实际发布到微信公众号**

### 发布指定文章

```bash
cd scripts
source .venv/bin/activate
python3 publish_to_wechat.py ../content/后端架构/第一章-单机苦修·草根启程.md --publish
```

## 工作流程

1. **检测新文章**: 扫描 `content/` 目录下的所有 `.md` 文件
2. **过滤草稿**: 跳过 `draft: true` 的文章
3. **检查已发布**: 使用 `published_articles.json` 追踪已发布的文章
4. **转换格式**: 将Markdown转换为微信公众号HTML格式
5. **上传图片**: 自动上传本地图片到微信公众号
6. **发布文章**: 调用微信公众号API发布

## 注意事项

1. **图片路径**: 图片应该放在 `content/images/` 目录下，使用相对路径引用
2. **代码块**: 微信公众号不支持代码高亮，会转换为纯文本
3. **样式限制**: 微信公众号对HTML样式支持有限
4. **封面图**: 发布图文消息需要先上传封面图（当前脚本需要完善此功能）

## 文件说明

- `publish_to_wechat.py`: 核心发布脚本
- `publish_new_articles.sh`: 自动检测和发布脚本
- `published_articles.json`: 已发布文章追踪文件
- `requirements.txt`: Python依赖

## 集成到GitHub Actions

可以在 `.github/workflows/` 中创建workflow，在文章更新时自动发布：

```yaml
name: Publish to WeChat

on:
  push:
    paths:
      - 'content/**/*.md'

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - name: Install dependencies
        run: |
          cd scripts
          pip install -r requirements.txt
      - name: Publish to WeChat
        env:
          WECHAT_APPID: ${{ secrets.WECHAT_APPID }}
          WECHAT_APPSECRET: ${{ secrets.WECHAT_APPSECRET }}
        run: |
          ./scripts/publish_new_articles.sh --publish
```

## 故障排查

1. **Access Token获取失败**: 检查AppID和AppSecret是否正确
2. **图片上传失败**: 检查图片路径和文件大小（微信公众号限制5MB）
3. **发布失败**: 检查文章内容是否符合微信公众号规范

## 待完善功能

- [ ] 支持上传封面图
- [ ] 支持草稿箱功能
- [ ] 支持定时发布
- [ ] 支持多图文消息
- [ ] 更好的错误处理和重试机制

