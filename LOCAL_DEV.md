# 本地开发

这个仓库使用 Material for MkDocs 构建，源码目录是 `docs/`，站点配置是 `mkdocs.yml`。

## Python 方式

在仓库根目录执行：

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -i https://pypi.tuna.tsinghua.edu.cn/simple -r requirements.txt
mkdocs serve
```

启动后访问：

```text
http://127.0.0.1:8000
```

构建检查：

```bash
mkdocs build --strict
```

## Docker 方式

在仓库根目录执行：

```bash
./scripts/serve-local.sh
```

默认会使用：

- 镜像：`illionj-mkdocs-local`
- 容器名：`illionj-mkdocs-dev`
- 端口：`8000`

第一次启动会自动构建本地镜像，并安装 `requirements.txt` 中的 MkDocs 依赖。
Docker 构建默认使用清华 PyPI 源：`https://pypi.tuna.tsinghua.edu.cn/simple`。

## 停止

执行：

```bash
./scripts/stop-local.sh
```

它会关闭本地预览容器 `illionj-mkdocs-dev`。

## 常用方式

更换端口：

```bash
PORT=8001 ./scripts/serve-local.sh
```

自定义容器名：

```bash
CONTAINER_NAME=my-mkdocs ./scripts/serve-local.sh
CONTAINER_NAME=my-mkdocs ./scripts/stop-local.sh
```

依赖或 Dockerfile 变化后强制重建镜像：

```bash
FORCE_BUILD=1 ./scripts/serve-local.sh
```

临时切换 pip 源：

```bash
PIP_INDEX_URL=https://pypi.org/simple FORCE_BUILD=1 ./scripts/serve-local.sh
```

## 修改源码后的行为

普通页面、Markdown、分类页修改后，MkDocs 会自动重新生成；通常只需要刷新浏览器，不需要重新执行启动脚本。

以下情况通常需要重新启动：

- 修改 `Dockerfile`
- 修改 `requirements.txt`
- 修改 `mkdocs.yml`
- 想切换端口或容器名
