# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a **Hugo static site blog** ("补漏砖匠") built with the **Mainroad** theme. Content is written in Chinese Markdown and deployed to two targets: GitHub Pages (`wugjun.github.io`) and a remote Linux server (`qiaopan.tech`).

## Common Commands

```bash
# Start dev server (includes drafts)
hugo server -D

# Build production site (minified, excludes drafts)
hugo --minify

# Build with drafts included
hugo --minify --buildDrafts

# Deploy to GitHub Pages (automatic via GitHub Actions on push to master)
# No manual command needed — push triggers .github/workflows/deploy.yml

# Deploy to qiaopan.tech (remote server via rsync + sshpass)
export DEPLOY_SERVER_PASSWORD=''
./deploy_qiaopan.sh            # normal deploy (no drafts)
./deploy_qiaopan.sh -D         # include drafts


```

**Prerequisites:**

- Hugo v0.152.2+extended (installed via brew)
- `sshpass` for server deployment (`brew install hudochenkov/sshpass/sshpass`)
- Python 3.9+ virtual environment in `scripts/.venv/` with `pip install -r scripts/requirements.txt`
- Environment variables: `DEPLOY_SERVER_PASSWORD`, `WECHAT_APPID`, `WECHAT_APPSECRET`

## Architecture

### Content Structure

- `content/` — All blog posts organized by category folders:
  - `post/` — General posts (about pages, resumes)
  - `编程语言/`, `后端架构/`, `前端开发/`, `算法数据结构/`, `运维部署/`, `工具效率/`, `开源文档/` — Category-based posts
  - `content/images/` — Shared image assets referenced by posts
- Each `.md` file uses YAML front matter with `title`, `date`, `tags`, `categories`, and optional `draft: true`

### Layout Overrides (project-level, not in theme)

- `layouts/_default/baseof.html` — Root template; extends Mainroad base, loads `quiz.css`, `quiz.js`, `ai-quiz.js`, and MathJax
- `layouts/index.html` — Custom home page with AI quiz link button and paginated post list
- `layouts/shortcodes/quiz.html` — Interactive quiz container shortcode (renders A/B/C/D options with submit/show-answer/reset buttons)
- `layouts/shortcodes/quizoption.html` — Individual quiz option, nests inside `quiz` shortcode
- `layouts/shortcodes/mermaid.html` — Mermaid diagram rendering shortcode
- `layouts/partials/widgets/categories.html` — Custom categories widget using i18n `T "categories_title"`

### Quiz System

Two quiz systems coexist:

1. **Static quiz** (`{{< quiz >}}` shortcode) — Written in Markdown, rendered as interactive HTML/CSS/JS. See `QUIZ_README.md` for usage.
2. **AI-generated quiz** (`ai-quiz.js`) — Fetches quizzes from a backend API (`POST /api/v1/assistant/chat/save`, `GET /api/v1/assistant/chat/load`). API spec in `AI_QUIZ_API.md`.

### Deployment Targets

| Target       | Method                                             | Config                                                                                |
| ------------ | -------------------------------------------------- | ------------------------------------------------------------------------------------- |
| GitHub Pages | GitHub Actions (`deploy.yml`)                      | Push to `master` → builds with `--buildDrafts` → deploys to `wugjun/wugjun.github.io` |
| qiaopan.tech | `deploy_qiaopan.sh` (rsync over SSH)               | `hugo --minify` → rsync to `root@qiaopan.tech:/var/www/myblog/html`                   |
| WeChat OA    | `publish_new_articles.sh` + `publish_to_wechat.py` | Converts Markdown → WeChat HTML, uploads images, publishes to draft box               |

### i18n / Internationalization

- `i18n/zh-cn.yaml` — Project-level Chinese translations (takes priority over theme translations)
- Theme translations in `themes/mainroad/i18n/`
- All sidebar widget labels (Recent Posts, Categories, Tags, Search, Menu, Prev/Next nav) are controlled via `T "key"` in templates, translated in `zh-cn.yaml`
- See `I18N_SETUP.md` and `页面文字配置说明.md` for details

### Configuration

- `config.toml` — Site config: theme = "mainroad", pagination pagerSize = 5, sidebar widgets order, mermaid/goldmark settings, author info
- `static/css/quiz.css`, `static/js/quiz.js`, `static/js/ai-quiz.js` — Quiz system assets

## Writing Content

1. Create a `.md` file in the appropriate category folder under `content/`
2. Include YAML front matter with at least `title` and `date`
3. Set `draft: true` to exclude from production builds
4. Images referenced in posts should be placed in `content/images/` with relative paths
5. For interactive quizzes, use the `{{< quiz >}}` / `{{< quizoption >}}` shortcodes
6. For diagrams, use the `{{< mermaid >}}` shortcode

## WeChat Publishing Workflow

1. Write and finalize blog post in `content/`
2. Run `./scripts/publish_new_articles.sh` (preview mode — shows converted HTML, doesn't publish)
3. Review output, then run `./scripts/publish_new_articles.sh --publish` to publish to WeChat draft box
4. Manually publish from WeChat MP admin panel
5. `scripts/published_articles.json` tracks which articles have been published (prevents duplicates)
6. WeChat IP whitelist must include the publishing machine's IP (use `scripts/get_current_ip.sh` to check)
