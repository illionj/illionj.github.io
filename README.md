# Local Development

这个仓库是一个基于 Jekyll / GitHub Pages 的站点，推荐通过 Docker 在本地预览。

## 启动

在仓库根目录执行：

```bash
./scripts/serve-local.sh
```

默认会使用：

- 镜像：`illionj-jekyll-local`
- 容器名：`illionj-jekyll-dev`
- 端口：`4000`

启动后访问：

```text
http://127.0.0.1:4000
```

第一次启动会自动构建本地镜像，并安装 Jekyll 依赖，因此会慢一些。后续依赖会复用 `vendor/bundle/` 缓存。

## 停止

执行：

```bash
./scripts/stop-local.sh
```

它会关闭本地预览容器 `illionj-jekyll-dev`。

## 常用方式

更换端口：

```bash
PORT=4001 ./scripts/serve-local.sh
```

自定义容器名：

```bash
CONTAINER_NAME=my-jekyll ./scripts/serve-local.sh
CONTAINER_NAME=my-jekyll ./scripts/stop-local.sh
```

## 修改源码后的行为

普通页面、Markdown、分类页修改后，Jekyll 会自动重新生成；通常只需要刷新浏览器，不需要重新执行启动脚本。

以下情况通常需要重新启动：

- 修改 `Dockerfile`
- 修改 `Gemfile`
- 修改 `_config.yml`
- 想切换端口或容器名
