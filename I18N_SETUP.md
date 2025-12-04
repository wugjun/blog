# 国际化（i18n）配置说明

## 已完成的配置

1. ✅ 创建了简体中文国际化文件：
   - `/i18n/zh-cn.yaml` - 项目级（优先使用）
   - `/themes/mainroad/i18n/zh.yaml` - 主题级
   - `/themes/mainroad/i18n/zh-cn.yaml` - 主题级

2. ✅ 更新了 `config.toml`：
   - `languageCode = "zh-cn"`

## 如何验证配置是否生效

### 方法 1：重启 Hugo 服务器

```bash
# 停止当前运行的 Hugo 服务器（Ctrl+C）
# 然后重新启动
hugo server -D
```

### 方法 2：清除缓存并重建

```bash
# 删除 public 目录
rm -rf public

# 重新构建
hugo --minify

# 启动服务器
hugo server -D
```

### 方法 3：检查生成的 HTML

访问页面后，检查 HTML 源码：
- `<html>` 标签应该是 `<html lang="zh-cn">`
- 侧边栏应该显示"最新文章"而不是"Recent Posts"
- 菜单应该显示"菜单"而不是"Menu"

## 测试页面

访问以下页面检查翻译是否生效：

1. **侧边栏小部件**：
   - 最新文章（Recent Posts）
   - 分类（Categories）
   - 标签（Tags）
   - 搜索（Search）

2. **404 页面**：
   - 访问不存在的页面，查看错误信息是否为中文

3. **文章导航**：
   - 查看文章页面的"上一篇"和"下一篇"按钮

## 如果仍未生效

### 检查步骤

1. **确认文件位置**：
   ```bash
   ls -la i18n/zh-cn.yaml
   ls -la themes/mainroad/i18n/zh*.yaml
   ```

2. **检查配置文件**：
   ```bash
   grep languageCode config.toml
   ```

3. **查看 Hugo 日志**：
   启动 Hugo 服务器时，查看是否有错误或警告信息

4. **验证 YAML 格式**：
   确保 i18n 文件的 YAML 格式正确，可以使用在线 YAML 验证器

### 手动测试翻译

在模板文件中，可以临时添加测试代码：

```html
{{ T "recent_title" }}
```

如果显示"最新文章"，说明翻译工作正常。

## 文件优先级

Hugo 会按以下顺序查找翻译文件：

1. `/i18n/zh-cn.yaml` （项目级，最高优先级）
2. `/themes/mainroad/i18n/zh-cn.yaml` （主题级）
3. `/themes/mainroad/i18n/zh.yaml` （主题级，回退）

## 常用翻译键

- `recent_title` - 最新文章
- `categories_title` - 分类
- `tags_title` - 标签
- `search_placeholder` - 搜索...
- `menu_label` - 菜单
- `post_nav_prev` - 上一篇
- `post_nav_next` - 下一篇

## 需要帮助？

如果问题仍然存在，请检查：
1. Hugo 版本是否支持 `zh-cn` 语言代码
2. 是否有语法错误导致 YAML 解析失败
3. 浏览器是否缓存了旧页面（尝试硬刷新 Ctrl+F5）

