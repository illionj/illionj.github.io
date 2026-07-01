# 笔记

这个仓库使用 [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/) 构建技术笔记站点。

## 本地预览

直接使用 Python：

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -i https://pypi.tuna.tsinghua.edu.cn/simple -r requirements.txt
mkdocs serve
```

或者使用 Docker：

```bash
./scripts/serve-local.sh
```

启动后访问：

```text
http://127.0.0.1:8000
```

## 常用命令

```bash
mkdocs build --strict
mkdocs serve
PORT=8001 ./scripts/serve-local.sh
FORCE_BUILD=1 ./scripts/serve-local.sh
PIP_INDEX_URL=https://pypi.org/simple FORCE_BUILD=1 ./scripts/serve-local.sh
./scripts/stop-local.sh
```

## 内容结构

- `mkdocs.yml`：站点配置、主题配置和导航。
- `docs/`：发布内容目录。
- `docs/posts/`：博客文章；分类和标签来自文章 front matter。
- `docs/tags.md`：标签索引页。
- `.github/workflows/deploy.yml`：推送到 `main` 后构建并发布到 GitHub Pages。

GitHub Pages 需要在仓库设置中选择 `GitHub Actions` 作为发布来源。

## 新增文章流程

1. 在 `docs/posts/<分类>/` 下新建 Markdown 文件，例如：

   ```text
   docs/posts/cpp/my-note.md
   ```

   目录名只是为了文件组织清晰；真正的分类来自文章 front matter 里的 `categories`。

2. 写入文章 front matter。建议每篇文章至少包含：

   ```markdown
   ---
   title: "文章标题"
   date:
     created: 2026-07-01
     updated: 2026-07-01
   slug: my-note
   categories:
     - cpp
   tags:
     - cpp
     - example
   description: "文章摘要"
   ---

   这里写首页和分类页展示的摘要内容。

   <!-- more -->

   ## 正文小节

   这里写正文。
   ```

   `slug` 用于生成文章 URL；当前配置会生成类似 `/cpp/my-note/` 的地址。

3. 分类和标签会自动生成：

   - `categories`：用于 `/category/`、`/category/<分类>/` 和文章元数据。约定一篇文章放一个主分类，但配置不强制限制。
   - `tags`：用于 `/tags/` 标签页。标签可以多个，也可以跨分类复用。
   - 如果新增了从未出现过的分类，只要有文章使用它，`/category/` 会自动展开显示。

4. 每篇文章必须包含 `<!-- more -->`。当前 `mkdocs.yml` 配置了 `post_excerpt: required`，缺少它时 `mkdocs build --strict` 会失败。

5. 不需要把新文章手动写进 `mkdocs.yml` 的 `nav`。博客列表、分类页、标签页都由 Material blog/tags 插件根据 front matter 自动生成。

6. 本地验证：

   ```bash
   mkdocs build --strict
   mkdocs serve
   ```
