# 切特的技术博客 — Hugo + GitHub Pages

> **AI Agent 工程实践** 方向。源码即文档，文档即产品。

## 🚀 快速开始

### 本地开发

```bash
# 克隆仓库（含 PaperMod 子模块）
git clone --recursive https://github.com/CHET-LI/CHET-LI.github.io.git
cd CHET-LI.github.io

# 或已有仓库拉取子模块
git submodule update --init --recursive

# 本地预览
hugo server -D

# 本地构建验证
hugo --minify
```

### 发布流程

> **当前状态**：等待用户提供 GitHub PAT，阶段 4 未解锁。

```bash
# 1. 内容自测（阶段 1 质量门）
hugo --minify                    # 构建门
# 检查 public/ 目录内链、页面渲染

# 2. 推送触发自动部署
git add .
git commit -m "feat: 新增/更新文章"
git push origin main             # 触发 GitHub Actions → 部署到 https://CHET-LI.github.io/
```

**部署链路**：
```
Markdown (content/) → git push main → GitHub Actions (hugo --minify)
  → GitHub Pages (CHET-LI.github.io) → 公网可访问
```

## 📁 目录结构

```
.
├── hugo.toml                 # 站点配置
├── themes/PaperMod/          # 主题（git submodule）
├── content/
│   ├── about.md              # 关于页面
│   └── posts/                # 文章
│       ├── neko-mcp-adapter.md
│       └── agent20-retrospective.md
├── .github/workflows/
│   └── gh-pages.yml          # 自动部署工作流
└── README.md                 # 本文件
```

## ⚙️ 配置要点

| 配置项 | 说明 |
|--------|------|
| `baseURL` | `https://CHET-LI.github.io/` |
| `theme` | `PaperMod` (submodule) |
| `languageCode` | `zh-cn` |
| 构建命令 | `hugo --minify` |
| 发布分支 | `gh-pages` (Actions 自动管理) |

## 🧪 质量门（阶段 1 自测闭环）

每篇文章/改动发布前必须通过：

1. ✅ **构建门**：`hugo build` 无报错
2. ✅ **链接门**：内部链接、图片、锚点全通
3. ✅ **质量门**：数据真实 / 无幻觉 / 可追溯 / 长度克制（见 `notes/quality-gate-checklist.md`）

> **铁律**：不过门不发布。不能只管写不管验。

## 📦 依赖

- Hugo **extended** ≥ 0.111（小主机已装 `v0.111.3+extended`）
- Git
- GitHub 账号 + PAT（发布时需要）

## 🔐 发布凭证（阶段 4 解锁项）

- GitHub PAT：`repo` + `workflow` + `pages` 权限
- 仓库：`CHET-LI/CHET-LI.github.io`
- 由用户在 GitHub Settings → Pages 配置：Source = GitHub Actions

## 📝 维护者

- **长明 / Akari** —— 常驻自主 Agent，负责骨架维护、内容自测、持续增值
- **切特** —— 产品主理人，拍板发布、提供 PAT

---

> 这不是一次性项目，是**长期守护、越做越好**的作品。
> 每轮巡检有余力，默认推进它一点点。