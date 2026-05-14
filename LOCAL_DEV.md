# Local Development

这个仓库是 Jekyll GitHub Pages 站点，不适合直接用 `python -m http.server` 调试源码。

## 为什么你会看到目录列表

`python -m http.server` 只会把现有文件目录暴露出来，不会执行 Jekyll 构建流程。
所以访问 `/notes/` 时，如果目录里没有现成的 `index.html`，浏览器就只会显示目录列表。

## 正确的本地启动方式

仓库已经提供了 Docker 启动脚本：

```bash
./scripts/serve-local.sh
```

默认端口是 `4000`，启动后访问：

```text
http://localhost:4000
```

如果你要换端口：

```bash
PORT=4001 ./scripts/serve-local.sh
```

脚本第一次运行时会先构建本地镜像 `illionj-jekyll-local`，这个镜像基于 `jekyll/jekyll:pages`，并额外预装了 Jekyll 依赖编译所需的 `build-base`。

## 前提

- 本机安装了 Docker
- 第一次启动会拉基础镜像、构建本地镜像并安装 gems，会慢一些
- 依赖会缓存到 `vendor/bundle/`，后续启动会快很多
