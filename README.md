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
- `docs/categories/`：分类页和文章。
- `docs/notes/`：笔记索引页。
- `.github/workflows/deploy.yml`：推送到 `main` 后构建并发布到 GitHub Pages。

GitHub Pages 需要在仓库设置中选择 `GitHub Actions` 作为发布来源。
