# AGENTS.md — 博客系统架构与维护指南

本文档面向在此仓库中协助维护、撰写与发布博文的 AI Agent 及开发者，详细说明了站点的技术架构、目录规范、发文工作流，以及关于时间戳与生成器机制的说明。

---

## 1. 站点概述与架构

- **站点定位**：个人学术与随记静态博客（[zhecai's blog](https://isirin1131.github.io)），托管于 GitHub Pages。
- **排版引擎**：主要使用 [Typst](https://typst.app/) 撰写并编译为 PDF，兼有少量 Markdown（画廊）及纯文本。
- **静态生成器**：根目录下的自主实现脚本 `generator.py`（Python 3 原生标准库实现，无外部第三方 Python 依赖）。
- **前端风格**：
  - **主站与分类归档**：学术杂志风格（Magazine-style），由 `assets/site.css` 与 `assets/site.js` 驱动。
  - **画廊 (Gallery)**：TUI 终端交互风格（Terminal UI），支持键盘快捷键（`j`/`k` 上下移动、`Enter` 查看等），由 `assets/gallery.css` 与 `assets/gallery.js` 驱动。

---

## 2. 目录结构与命名规范

```text
isirin1131.github.io/
├── typst_files/           # 文章 Typst 源码工作区（.typ、配图、.bib 等）
│   ├── ref.bib            # 参考文献引用库
│   └── *.typ              # 博文源码（如 20261019日思夜想Transformer.typ）
│
├── [XXX]分类名/           # 公开分类目录（严格匹配正则 ^\[(\d{3})\](.+)$）
│   ├── [001]技术报告/
│   ├── [002]读书笔记/
│   ├── [003]随记/
│   ├── [004]正经学线性代数/
│   ├── [006]二手影评/
│   ├── [007]games101/
│   ├── [012]杂物归档/
│   └── [013]调研报告/
│       └── *.pdf          # 编译后的产物文件（通常为 .pdf，也支持 .txt、图片等）
│
├── gallery/               # 画廊数据源
│   └── items/
│       └── <条目目录>/     # 每个子目录内包含一张图片和一个同名或主 .md 文件
│
├── object/                # 静态生成产物：各分类归档页面（由 generator.py 单向生成）
│   └── [XXX]分类名.html
│
├── assets/                # 全局样式与脚本（site.css, site.js, gallery.css, gallery.js）
├── index.html             # 静态生成产物：站点主页（由 generator.py 单向生成）
├── gallery.html           # 静态生成产物：画廊页面（由 generator.py 单向生成）
├── generator.py           # 静态站点生成核心脚本
├── typstFontSetting.txt   # Typst 字体配置参考
└── [unPublic].../         # 私密/非公开目录（不匹配 ^\[\d{3}\]，会被生成器自动忽略）
```

### 目录与分类规则：
1. **公开分类规则**：任何根目录下命名符合 `[三位数字]分类名称`（正则 `^\[(\d{3})\](.+)$`）的文件夹均会被视作一个公开分类。分类的编号决定其显示排序。
2. **私密/草稿规则**：若目录名称不符合上述正则（如 `[unPublic][notReally]...`），生成器会自动跳过，绝不会将其暴露在 `index.html` 或公开归档中。
3. **单向生成保护**：`index.html`、`gallery.html` 以及 `object/` 下的所有 HTML 均由 `generator.py` 覆盖生成，**严禁手动编辑这些 HTML 文件**。

---

## 3. 标准博文发布与更新流程

### 3.1 撰写新博文
1. 在 `typst_files/` 目录下创建 `.typ` 文件。
2. 基础头部模板（参考历史文档）：
   ```typst
   #import "@preview/basic-document-props:0.1.0": simple-page
   #show: simple-page.with("刌刈", "isirin1131@outlook.com", middle-text: "", date: true, numbering: true, supress-mail-link: true)

   #set text(font: ("Sarasa Fixed Slab SC"), lang:("zh"))

   // 正文内容...
   ```

### 3.2 编译输出
使用系统已安装的 `typst` CLI，将 `.typ` 源码直接编译输出到对应的公开分类目录中：
```bash
# 示例：将随记编译至 [003]随记/
typst compile typst_files/20261022折腾.typ "[003]随记/20261022折腾.pdf"
```

### 3.3 生成站点
在项目根目录运行生成器：
```bash
python3 generator.py
```
生成器会：
1. 扫描所有 `[XXX]分类名/` 目录下的内容。
2. 扫描 `gallery/items/` 下的条目。
3. 计算首次发布（`published`）与更新（`updated`）时间戳。
4. 渲染并覆写 `index.html`、`gallery.html` 与 `object/*.html`。
5. 自动清理 `object/` 中已失效的旧分类 HTML。

### 3.4 提交与部署
确认生成无误后，一次性提交并推送：
```bash
git add .
git commit -m "feat: 发布新博文《20261022折腾》"
git push
```

---

## 4. 时间戳机制与“发新文需两次 Commit”问题剖析

### 4.1 历史现象与原因剖析
- **历史现象**：每次发布新博文时，必须先 `git commit` 一次，再执行 `python3 generator.py`，再 `git commit` 一次（共两次 commit）时间戳才会正确；而更新旧文章版本时看似不需要。
- **根本原因**：
  `generator.py` 依赖 `git log --follow --format=%ad --date=short -- <相对路径>` 获取文件历史。
  1. **对于新文章**：在首次提交前，该 PDF 文件在 Git 历史上没有任何提交记录，`git log` 输出为空。因此生成器解析出 `published = None`、`updated = None`。
     - HTML 中被渲染为 `<span class="date-unknown">未记录</span>`；
     - 排序权重被视作 `"0000-00-00"`，直接导致新文章掉出主页“最近更新”列表；
     - 开发者不得不先提交该 PDF 进 Git，使 `git log` 产生记录，再二次运行 `generator.py`，再做第二次提交。
  2. **对于更新旧文章**：该文件已存在早期的 Git 提交记录，`git log` 能返回旧提交的日期。因此页面上依然显示有具体日期，不会变为“未记录”，视觉上不会异常，开发者因而误以为“更新旧文章不需要二次 commit”（但实际上若未做感知优化，此时 HTML 记录的更新时间仍停留在上一次旧提交的时间点）。

### 4.2 优化解决机制（已合入 `generator.py`）
`generator.py` 现已内置基于 `git status --porcelain -z` 的工作区状态感知机制：
1. **全新文件（Untracked / 新增未提交）**：
   若 `git log` 无提交历史，自动将 `published` 与 `updated` 缺省为当日日期（`datetime.date.today().isoformat()`）。
   - **效果**：在新写文章首次运行 `generator.py` 时，就能立刻以当天日期排在最前并正确显示时间，**一次 commit 即可直接发布**。
2. **已存在但在工作区中被修改的文件（Dirty / Modified）**：
   若文件已有提交历史且检测到工作区存在未提交修改，保持最初创建日期的同时，自动将 `updated` 标记为当日日期。
   - **效果**：更新旧文章时，在 commit 前重新编译并运行 `generator.py`，更新时间戳能精确同步为当天，无需二次补提。
3. **未修改的历史文件（Clean）**：
   完全保持读取自 `git log` 的精确历史时间戳，不产生不必要的内容漂移。

---

## 5. Agent 协作准则 (Agent Rules)

1. **绝对禁止手动覆写生成物**：不要直接修改 `index.html`、`gallery.html` 或 `object/*.html`。任何页面结构的调整均须修改 `generator.py` 或 `assets/` 静态资源，然后通过执行脚本重新生成。
2. **遵守分类命名正则**：如果新增分类，目录名必须严格符合 `[000]分类名` 的三位编号格式。
3. **保持 Typst 源码与产物对应**：文章源码保存在 `typst_files/`，编译产物保存在对应公开分类文件夹中。
4. **验证构建**：在完成任何博文增删或脚本调整后，务必执行 `python3 generator.py` 并在 `git status` 中核对生成文件的变更。
