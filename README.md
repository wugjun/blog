# 补漏砖匠

> 独钓寒江雪，为有暗香来。

个人技术博客，记录编程学习与实践的点点滴滴。

## 📚 内容目录

### 📄 关于我

- **分类目录**: [国内访问](http://qiaopan.tech/post/) | [国外访问](https://wugjun.github.io/post/)

- **个人简历-中文** (2025-11-25)

  - [国内访问](http://qiaopan.tech/post/about/) | [国外访问](https://wugjun.github.io/post/about/)

- **个人简历-英文** (2024-01-09)
  - [国内访问](http://qiaopan.tech/post/about-en/) | [国外访问](https://wugjun.github.io/post/about-en/)

---

### 🗡️ 编程语言

- **分类目录**: [国内访问](http://qiaopan.tech/%E7%BC%96%E7%A8%8B%E8%AF%AD%E8%A8%80/) | [国外访问](https://wugjun.github.io/%E7%BC%96%E7%A8%8B%E8%AF%AD%E8%A8%80/)

---

### ⚔️ 后端架构

- **分类目录**: [国内访问](http://qiaopan.tech/%E5%90%8E%E7%AB%AF%E6%9E%B6%E6%9E%84/) | [国外访问](https://wugjun.github.io/%E5%90%8E%E7%AB%AF%E6%9E%B6%E6%9E%84/)

---

### 📖 开源文档

- **分类目录**: [国内访问](http://qiaopan.tech/%E5%BC%80%E6%BA%90%E6%96%87%E6%A1%93/) | [国外访问](https://wugjun.github.io/%E5%BC%80%E6%BA%90%E6%96%87%E6%A1%93/)

---

### 🔧 运维部署

- **分类目录**: [国内访问](http://qiaopan.tech/%E8%BF%90%E7%BB%B4%E9%83%A8%E7%BD%B2/) | [国外访问](https://wugjun.github.io/%E8%BF%90%E7%BB%B4%E9%83%A8%E7%BD%B2/)

---

### 🎯 算法与数据结构

- **分类目录**: [国内访问](http://qiaopan.tech/%E7%AE%97%E6%B3%95%E4%B8%8E%E6%95%B0%E6%8D%AE%E7%BB%93%E6%9E%84/) | [国外访问](https://wugjun.github.io/%E7%AE%97%E6%B3%95%E4%B8%8E%E6%95%B0%E6%8D%AE%E7%BB%93%E6%9E%84/)

---

### 🛠️ 工具效率

- **分类目录**: [国内访问](http://qiaopan.tech/%E5%B7%A5%E5%85%B7%E6%95%88%E7%8E%87/) | [国外访问](https://wugjun.github.io/%E5%B7%A5%E5%85%B7%E6%95%88%E7%8E%87/)

---

### 🎨 前端开发

- **分类目录**: [国内访问](http://qiaopan.tech/%E5%89%8D%E7%AB%AF%E5%BC%80%E5%8F%91/) | [国外访问](https://wugjun.github.io/%E5%89%8D%E7%AB%AF%E5%BC%80%E5%8F%91/)

---

## 🚀 部署说明

### 本地开发

```bash
# 启动开发服务器（包含草稿）
hugo server -D

# 构建站点（不包含草稿）
hugo --minify
```

### 部署到服务器

```bash
# 部署到国内服务器 (qiaopan.tech)
./deploy_qiaopan.sh

# 部署包含草稿内容
./deploy_qiaopan.sh -D
```

### 部署到 GitHub Pages

通过 GitHub Actions 自动部署，推送代码到 master 分支即可。

---

## 📝 站点信息

- **国内站点**: [https://qiaopan.tech](http://qiaopan.tech)
- **国外站点**: [https://wugjun.github.io](https://wugjun.github.io)
- **主题**: Mainroad
- **生成器**: Hugo

---

## 📧 联系方式

- **GitHub**: [blowizer](https://github.com/blowizer)
- **Email**: blowizer@qq.com

ssl_certificate /etc/nginx/sites-enabled/qiaopan.tech.pem;
ssl_certificate_key /etc/nginx/sites-enabled/qiaopan.tech.key;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384;

---

© 2025 补漏砖匠. 左键右鼠运阴阳，挖山填海码几行。人海浮沉皆过客，我是人间补漏匠。
