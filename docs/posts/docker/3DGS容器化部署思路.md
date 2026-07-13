---
title: "3DGS容器化部署思路"
date:
  created: 2025-06-28
  updated: 2026-06-28
slug: 3dgs-docker
categories:
  - tools
tags:
  - docker
description: "学习docker使用"
---


# 3DGS容器化部署思路

这篇文档是一次方案复盘，不是 Docker 教程，也不是完整的分布式调度器设计说明或最佳实践。重点是分享思路：为什么 3DGS 最后选择容器化，过程中遇到了哪些问题，以及当前项目里的 Dockerfile 是怎么解决这些问题的。

在 AI 工具加持下，无需刻意记背各种 Docker 用法，思路更重要。

<!-- more -->

## 1. 先说项目背景

三维重建渲染传感器，也就是这里的 `3dgs_node`，和传统物理传感器不太一样。它对显存、CUDA、PyTorch、gsplat 以及 Python 依赖都有比较高的要求。

如果所有渲染任务都压在仿真机本机上，很快就会遇到单机单卡容量不够的问题。因此项目一开始就引入了分布式调度思路：把 `3dgs_node` 放到其他计算设备上运行，由 `simpro` 下发数据帧和控制帧，渲染工作在分布式设备上完成。

这样设计以后，`workmanager(调度器)` 就变成了一个很关键的角色。它负责和 `simpro` 通信，接收下发的任务，拉起子任务，上报状态，以及在任务结束后清理环境。

这里调度器和容器化相关的设计约束主要有三点：

1. `workmanager` 自身应该尽量轻量、独立，不能被子任务拖垮。
2. 同一台机器理论上可以部署多个 `workmanager`，用后缀或配置做隔离，提供给不同 `simpro` 使用。这个能力做了，但生产上后来发现不一定需要。
3. `simpro`、`workmanager`、子任务之间都需要双向交互，而且不同关系适合不同通道。

当前通信关系大致是：

| 通信双方 | 通道 | 说明 |
| --- | --- | --- |
| `simpro` 与 `workmanager` | ZMQ(TCP) ROUTER | 注册、控制、任务下发、状态交互 |
| `simpro` 与 `3dgs_node` 子任务 | ZMQ/TCP | 数据/控制流 |
| `workmanager` 与 `3dgs_node` 子任务 | UDS(Unix Domain Socket) | 启动状态和任务内状态回传 |

这些约束决定了一个基本方向：`workmanager` 不适合把 3DGS 渲染任务直接塞进自己进程里跑。

## 2. 当时考虑过的三种方案

最初 `3dgs_node` 子任务有三种候选方案。

### 2.1 线程池方案

最简单的做法是让 `workmanager` 维护一个线程池，任务来了就提交到线程池里执行。

这个方案实现成本最低，但问题也很直接：`workmanager` 会变重，子任务出问题也更容易影响调度器本身。这和“调度器轻量、独立、不受子任务影响”的目标冲突，所以很快就被排除了。

### 2.2 独立进程方案

第二种方案是由 `workmanager` 拉起独立进程，进程里运行 `3dgs_node`。

如果渲染核心依赖比较简单，或者依赖都已经被很好地打包，这个方案其实不错。问题是当时算法组的渲染核心，和我这边的 `simpro`、`workmanager`、`3dgs_node` 是同步开发的，我无法预判最终依赖会复杂到什么程度。

后面渲染核心出来以后，依赖复杂度已经明显超过了进程方案适合承载的范围，所以 3DGS 主路径转向容器化。

不过这个方案没有浪费。它被用于香港/小米项目的分布式物理传感器子任务，因为物理传感器的依赖与 3DGS 相比简单很多。

### 2.3 容器化方案

第三种方案是由 `workmanager` 拉起容器，容器里再运行 `3dgs_node`。

这个方案工作量最大，但隔离最清楚，也最适合处理 CUDA、PyTorch、gsplat、自定义子模块这类重依赖。随着项目推进，进程方案不再适用，容器化就成了 3DGS 的主方案。

**这里要强调一点：容器化方案并不是什么包治百病的灵药，也没有一开始就完全拍板确定走容器化，而是根据项目特点具体问题具体分析，存在一个探索过程。**

## 3. 我当时真正想解决的问题

我之前对 Docker 了解不多，更多时候只是使用别人准备好的镜像。用这些镜像时遇到了很多让我难受的痛点，所以真正开始做这个方案时，我参考了一些容器化部署的最佳实践，不过指导原则是：痛点优先于最佳实践。

### 3.1 镜像是黑盒

早期最大的问题是镜像不透明。没人真正知道容器里有什么东西、装过哪些库、做过哪些配置。每个人遇到问题以后进容器改一下，再重新打包成一个新镜像，时间久了就很难维护。

解决这个问题的第一步就是启用 Dockerfile。至少基础镜像、CUDA、PyTorch、Python 依赖、子模块安装这些步骤都能被记录下来。

我一开始写 Dockerfile 的方式也不好，就是尽量写一个完整版本，然后进容器跑测试程序，缺什么补什么，反复调整。更理想的方式应该是先开一个交互式容器，一边安装一边记录，直到程序可以跑起来，再把过程固化成 Dockerfile。

不过即使这样，后面调 Dockerfile 还是躲不开反复构建。Dockerfile 每条指令都会形成缓存层，如果前面的层失效，后面的层通常也要重新执行。**所以经常变的内容，比如 Python 依赖、业务包安装，最好尽量放在靠后的位置，减少无意义的重建时间。**

### 3.2 容器化以后调试反而变麻烦

如果 Dockerfile 直接写成：

```dockerfile
CMD ["python", "main.py"]
```

看起来很自然，容器启动就运行程序，程序结束容器也结束。但这对调试并不友好。

尤其是分布式场景里，任务失败后还要先远程到宿主机，再判断是容器问题、环境问题、代码问题，还是任务参数问题。如果再加上 `--rm`，容器退出后现场直接消失。

所以我这里把四件事解耦：

1. 启动容器。
2. 在容器中执行业务程序。
3. 根据任务结果决定容器退出方式。
4. 最后由调度器或脚本决定是否删除容器。

当前 3DGS 镜像的 entrypoint 只负责启动 `sshd`。真正的业务命令由 `workmanager` 通过 Docker exec 执行。这样失败后容器可以保留，直接 SSH 或 exec 进去排查。

容器里启动 SSHD 不是一个通用意义上的好做法，**我可以负责任地说，容器启动 SSHD 是一个非常差的做法，非常不建议推广**。但对我这里的调试很重要，尤其是用 VS Code Remote SSH 直接进入容器看环境和代码时非常方便。

另一个经验是：程序运行通常有三类输入，环境变量、启动命令、执行参数。我的做法是环境变量尽量跟容器启动绑定，复杂执行参数落成单独的任务配置文件。这样出问题后进入容器，一行命令就能重跑，不需要重新拼一长串环境变量。

命令样例：只有最后的 `task_config` 存在差异。
```
/opt/venv/bin/python3 \
  -m 3dgs_node.main \
  -c 3dgs_node/fusion_config.yaml \
  -t /home/app/3DGS/src/logs/task_config/3DGSFusion_projA_0af1206e.yaml
```

### 3.3 构建依赖太重

3DGS 镜像要装基础库、CUDA、PyTorch、gsplat 和大量 Python 依赖。每次构建都在线下载，很容易遇到网络慢、下载失败、版本漂移等问题。

所以我采用离线构建思路，把依赖提前下载到 `docker/deps/`。这一步的主要难点是要对所有依赖有非常清晰的认识：需要做哪些设置，用哪些库，甚至连版本号都要清楚。

主要材料包括：

- `docker/deps/cudahouse/`：CUDA runfile。
- `docker/deps/torchhouse/torch_cu128/`：PyTorch CUDA 12.8 相关 wheel。
- `docker/deps/wheelhouse/`：3DGS 渲染容器的 Python wheel。
- `docker/deps/workmanager_wheelhouse/`：`workmanager` 容器的 Python wheel。
- `docker/deps/submodules/`：需要从本地安装或编译的子模块。

这样做以后，构建不再强依赖外网，部署到多台设备时也更稳定。

### 3.4 离线材料不能直接 COPY 进镜像

一开始很容易想到：把 CUDA runfile、wheelhouse、requirements 都 `COPY` 进镜像，安装完再删掉。

但 Docker 分层会带来一个坑：拷贝再删除，不代表这些文件真的从镜像历史层里消失。它们依然会占用镜像体积。

所以当前主要 Dockerfile，也就是 `Dockerfile_3dgs_sm120_fusion`，大量使用 BuildKit 的 bind mount：

```dockerfile
RUN --mount=type=bind,source=${DEPS_ROOT}/wheelhouse,target=/wheels,readonly \
    --mount=type=bind,source=${DEPS_ROOT}/requirements.txt,target=/tmp/requirements.txt,readonly \
    /opt/venv/bin/python3 -m pip install --no-index --find-links=/wheels -r /tmp/requirements.txt
```

这种方式是在构建时临时把材料挂进去，安装完成后不会把 wheelhouse 这类大目录写进镜像层。

使用这种方式后，镜像体积缩减了约 20 GB：
```bash
saimo/3dgs-cuda12.8                   sm120-base-fusion            c8ff816ceaa6   3 weeks ago    17.6GB
saimo/3dgs-cuda12.8                   sm120-base-fusion-old   0f5ff0ec1250   3 weeks ago     36.5GB
```

我之前也研究过多阶段构建，但在当前这个 Dockerfile 里没有采用。主要原因是 `--mount=type=bind` 已经解决了最大的镜像层膨胀问题，继续引入多阶段构建带来的收益没有那么明显。如果以后出现更重的编译产物，再考虑多阶段构建会更合适。

### 3.5 代码/可执行程序不能和镜像强绑定

如果把业务代码/可执行程序打进镜像，代码一改就要重新构建镜像。3DGS 依赖重、分布式机器多，这个成本很高。

所以当前方案里，镜像只提供运行环境，代码和模型通过宿主机挂载：

```yaml
volumes:
  - /opt/3DGS:/home/app/3DGS:rw
```

`workmanager` 拉起子任务容器时，也会把同一个工作区挂到容器内。这样代码更新主要变成同步宿主机目录，不需要频繁重新打镜像。

### 3.6 gsplat 的 JIT 预热

`gsplat` 有 CUDA kernel JIT 编译路径。简单说，就是某些执行路径第一次跑到时才会编译 CUDA kernel。第一次非常慢，后面才恢复正常。

如果每个任务都是新容器，那么每次任务启动都可能重新遇到这个首次编译成本。比如一个 15 秒的仿真任务，光 JIT 就可能花掉一分钟。这个问题在任务调度场景里非常明显。

当前方案分两步处理：

1. Dockerfile 构建末尾执行 `docker/deps/precompile_gsplat.py`，尽量提前触发常见路径。
2. 如果预编译脚本覆盖不了真实任务路径，就用真实任务跑一次，然后把运行过真实路径的容器重新提交成 warmed 镜像。

配置里现在已经能看到这种演进：

```yaml
# 3dgs-cuda12.8:sm120-base-fusion 完成预热
# => saimo/3dgs-cuda12.8:sm120-base-fusion-warmed

# gsplat 官方版本测试并完成预热
# => saimo/3dgs-cuda12.8:sm120-fusion-gsplat-warmed
```

这也是我后面想明白的一点：没必要执着于一个 Dockerfile 里一次性解决所有真实路径。Dockerfile 负责打好基础环境，真实路径预热可以通过 warmed 镜像补上。

## 4. 细节补充

### 4.1 Fusion 镜像构建

当前主要看的 Dockerfile 是：

```text
docker/dockerfiles/Dockerfile_3dgs_sm120_fusion
```

构建命令建议显式启用 BuildKit：

```bash
DOCKER_BUILDKIT=1 docker build \
  --file Dockerfile_3dgs_sm120_fusion \
  --tag saimo/3dgs-cuda12.8:sm120-base-fusion \
  ..
```

如果完成真实任务预热后要固化 warmed 镜像，可以提交容器：

```bash
docker commit <container_id_or_name> saimo/3dgs-cuda12.8:sm120-fusion-gsplat-warmed
```

### 4.2 宿主机路径约定

容器中不存放代码和模型，默认从宿主机 `/opt/3DGS` 挂载。

常用做法是建立软链接：

```bash
sudo ln -s /home/saimo/3dgs/3DGS /opt/3DGS
```

如果目标机器路径不同，需要同步调整：

- `docker/compose/docker-compose.yml`
- `src/workmanager/config/agent.yaml`
- 其他 compose 文件中的宿主机映射路径

### 4.3 子任务配置

`src/workmanager/config/agent.yaml` 里定义了不同子任务 profile，例如 `3DGSCamera`、`3DGSLidar`、`3DGSFusion`。

Fusion 配置示例：

```yaml
3DGSFusion:
  suffix: "projA"
  container:
    image: saimo/3dgs-cuda12.8:sm120-fusion-gsplat-warmed
    command: ["/opt/venv/bin/python3","-m","3dgs_node.main","-c","3dgs_node/fusion_config.yaml"]
    workdir: /home/app/3DGS/src/
    volumes: [
      {"description":"workspace","host": "/opt/3DGS", "container": "/home/app/3DGS","mode": "rw"},
      {"description":"time","host": "/etc/localtime", "container": "/etc/localtime", "mode": "ro"},
      {"description":"time","host": "/etc/timezone", "container": "/etc/timezone", "mode": "ro"},
    ]
    task_config_path: /home/app/3DGS/src/logs/task_config
```

`workmanager` 启动任务时，会把任务参数写入：

```text
/home/app/3DGS/src/logs/task_config/<profile>_<task_id>.yaml
```

然后拼接成最终命令：

```bash
/opt/venv/bin/python3 -m 3dgs_node.main \
  -c 3dgs_node/fusion_config.yaml \
  -t /home/app/3DGS/src/logs/task_config/3DGSFusion_projA_<task_id>.yaml
```

这个设计的好处是调试成本低。容器环境变量不用塞得很复杂，任务参数也有文件可查。需要复现问题时，进容器后直接拿重跑上述命令即可。

## 5. 总结

这套容器化方案最后留下来的核心思路是：

- `workmanager` 保持轻量，3DGS 渲染任务独立运行。
- 镜像只固化重依赖，不固化代码和模型。
- 容器启动、业务程序运行、容器退出、容器删除尽量解耦，方便定位问题。
- 用 Dockerfile 解决镜像黑盒问题。
- 用离线依赖解决网络和构建稳定性问题。
- 用 BuildKit bind mount 避免离线材料进入镜像层。
- 用任务配置文件承载复杂参数，降低复现和调试成本。
- 对 gsplat JIT 不追求一次性完美，用“构建期预编译 + 真实任务 warmed 镜像”组合处理。

**这个方案只是当前 3DGS 项目在约束、时间和调试成本之间做出来的选择，是一个偏工程实用主义的方案，不是标准化、云原生、强安全的容器化方案。**

## 附录：Dockerfile_3dgs_sm120_fusion 注释版

下面内容来自 `docker/dockerfiles/Dockerfile_3dgs_sm120_fusion`。这里重新整理了注释，便于阅读。

```dockerfile
# 使用 Ubuntu 22.04 作为基础环境。
FROM ubuntu:22.04

# 构建过程中不弹交互式提示。
ENV DEBIAN_FRONTEND=noninteractive

# 默认让容器看到 GPU，并声明需要 compute / utility 能力。
# 实际 GPU 注入仍然依赖 docker run --gpus 或 compose gpus 配置。
ENV NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility

# 安装基础工具、Python venv、编译工具、SSH 服务和常用开发库。
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git \
    openssh-server sudo \
    python3 python3-venv python3-pip python3-dev \
    build-essential pkg-config \
    libssl-dev libffi-dev \
    libzmq3-dev \
    libyaml-dev \
 && rm -rf /var/lib/apt/lists/*

# 创建统一的 Python 虚拟环境，后续 Python 依赖都装到 /opt/venv。
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv "$VIRTUAL_ENV"

# 让 venv 优先于系统 Python，并关闭 pip 缓存。
ENV PATH="$VIRTUAL_ENV/bin:$PATH" \
    PIP_NO_CACHE_DIR=1

# 离线依赖目录，默认对应 docker/deps。
ARG DEPS_ROOT="deps"

# 通过 BuildKit bind mount 临时挂载 CUDA runfile。
# 这里只安装 Toolkit，不安装驱动；驱动来自宿主机。
RUN --mount=type=bind,source=${DEPS_ROOT}/cudahouse/cuda_12.8.0_570.86.10_linux.run,target=/tmp/cuda.run,readonly \
  set -eux; \
  sh /tmp/cuda.run --silent --toolkit --toolkitpath=/usr/local/cuda-12.8; \
  ln -s /usr/local/cuda-12.8 /usr/local/cuda || true

# CUDA 基础环境变量。
ENV CUDA_HOME=/usr/local/cuda-12.8
ENV LD_LIBRARY_PATH="$CUDA_HOME/lib64:${LD_LIBRARY_PATH}"
ENV PATH="/usr/local/cuda-12.8/bin:/opt/venv/bin:${PATH}"

# 把 CUDA 和 venv 写入 profile、ldconfig、sudo secure_path、交互 shell。
# 这样登录 shell、非登录 shell、sudo 场景和 VS Code Remote 场景都能找到 CUDA / venv。
RUN set -eux; \
  printf '%s\n' \
'export CUDA_HOME=/usr/local/cuda-12.8' \
'export PATH=/usr/local/cuda-12.8/bin:/opt/venv/bin:$PATH' \
'export LD_LIBRARY_PATH=/usr/local/cuda-12.8/lib64:${LD_LIBRARY_PATH}' \
> /etc/profile.d/zz-cuda-venv.sh; \
  chmod 644 /etc/profile.d/zz-cuda-venv.sh; \
  echo "/usr/local/cuda-12.8/lib64" > /etc/ld.so.conf.d/cuda-12-8.conf; \
  ldconfig; \
  printf 'Defaults secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/cuda-12.8/bin:/opt/venv/bin"\n' \
    > /etc/sudoers.d/secure_path_cuda_venv; \
  chmod 440 /etc/sudoers.d/secure_path_cuda_venv; \
  ln -sf /usr/local/cuda-12.8/bin/nvcc /usr/local/bin/nvcc; \
  printf '\n# CUDA + venv for interactive shells\nexport CUDA_HOME=/usr/local/cuda-12.8\nexport PATH=/usr/local/cuda-12.8/bin:/opt/venv/bin:$PATH\nexport LD_LIBRARY_PATH=/usr/local/cuda-12.8/lib64:${LD_LIBRARY_PATH}\n' \
    >> /etc/bash.bashrc

# 创建 app 用户，开启 SSH 密码登录和公钥登录。
# 这里的密码主要服务测试和调试环境，生产环境应按现场安全策略调整。
RUN mkdir -p /var/run/sshd \
 && useradd -m -s /bin/bash app \
 && echo 'app:123456' | chpasswd \
 && usermod -aG sudo app \
 && sed -ri 's/^#?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config \
 && sed -ri 's/^#?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config \
 && sed -ri 's/^#?PubkeyAuthentication .*/PubkeyAuthentication yes/' /etc/ssh/sshd_config \
 && mkdir -p /home/app/.ssh && chown -R app:app /home/app/.ssh && chmod 700 /home/app/.ssh \
 && chown -R app:app /home/app \
 && chmod 700 /home/app \
 && printf '%s\n' \
'export CUDA_HOME=/usr/local/cuda-12.8' \
'export PATH=/usr/local/cuda-12.8/bin:/opt/venv/bin:$PATH' \
'export LD_LIBRARY_PATH=/usr/local/cuda-12.8/lib64:${LD_LIBRARY_PATH}' \
>> /home/app/.bashrc \
 && chown app:app /home/app/.bashrc

# 离线安装 PyTorch、torchvision、torch_scatter。
# wheelhouse 和 torchhouse 只在构建时挂载，不进入镜像层。
RUN --mount=type=bind,source=${DEPS_ROOT}/wheelhouse,target=/wheels,readonly \
    --mount=type=bind,source=${DEPS_ROOT}/torchhouse/torch_cu128,target=/torch_cu128,readonly \
    chown -R app:app /opt/venv \
 && ls -al /wheels | sed -n '1,200p' \
 && su -s /bin/bash - app -c '\
    set -eux; \
    /opt/venv/bin/python3 -m pip install --no-index --find-links=/torch_cu128 \
      /torch_cu128/torch-2.8.0+cu128-cp310-*.whl \
      /torch_cu128/torchvision-0.23.0+cu128-cp310-*.whl \
      /torch_cu128/torch_scatter-*-cp310-*-linux_x86_64.whl \
  '

# 把 torch 自带动态库路径写入 ldconfig。
# 如果 Python 版本变化，这里的 python3.10 路径也要同步调整。
RUN echo "/opt/venv/lib/python3.10/site-packages/torch/lib" > /etc/ld.so.conf.d/torch.conf \
 && ldconfig

# 先安装构建 Python 包常用的基础工具。
RUN --mount=type=bind,source=${DEPS_ROOT}/wheelhouse,target=/wheels,readonly \
    /opt/venv/bin/python3 -m pip install --no-index --find-links=/wheels \
      pip setuptools wheel Cython

# 再安装 3DGS 运行所需的其余 Python 依赖。
RUN --mount=type=bind,source=${DEPS_ROOT}/wheelhouse,target=/wheels,readonly \
    --mount=type=bind,source=${DEPS_ROOT}/requirements.txt,target=/tmp/requirements.txt,readonly \
    /opt/venv/bin/python3 -m pip install --no-index --find-links=/wheels -r /tmp/requirements.txt

# 入口脚本只负责启动 SSHD。
# 业务程序由 workmanager 在容器启动后通过 docker exec 执行。
RUN printf '%s\n' \
'#!/usr/bin/env bash' \
'set -euo pipefail' \
': "${SSH_PORT:=2222}"' \
'if grep -qE "^#?Port " /etc/ssh/sshd_config; then' \
'  sed -ri "s/^#?Port .*/Port ${SSH_PORT}/" /etc/ssh/sshd_config' \
'else' \
'  echo "Port ${SSH_PORT}" >> /etc/ssh/sshd_config' \
'fi' \
'mkdir -p /var/run/sshd' \
'/usr/bin/ssh-keygen -A >/dev/null 2>&1 || true' \
'# 若存在公钥则仍然支持公钥登录（可选）' \
'if [ -f /home/app/.ssh/authorized_keys ]; then' \
'  chown -R app:app /home/app/.ssh' \
'  chmod 700 /home/app/.ssh' \
'  chmod 600 /home/app/.ssh/authorized_keys' \
'fi' \
'exec /usr/sbin/sshd -D -e' \
> /usr/local/bin/container-entrypoint.sh \
 && chmod +x /usr/local/bin/container-entrypoint.sh

# host 网络下 EXPOSE 主要是文档提示，实际端口由 SSH_PORT 决定。
EXPOSE 2222

# 指定需要编译的 CUDA 架构，避免 torch 在没有 GPU 的构建环境里猜测架构。
ENV TORCH_CUDA_ARCH_LIST="8.6 8.9 12.0+PTX"

# 早期曾考虑把多个本地子模块都安装进镜像。
# 当前 fusion 镜像主路径只安装 gsplat，下面这段保留为历史参考，不会执行。
# RUN set -eux; \
#   python3 -m pip install --no-build-isolation --no-deps /tmp/submodules/simple-knn \
#   && python3 -m pip install --no-build-isolation --no-deps /tmp/submodules/diff_lidargs_rasterization \
#   && python3 -m pip install --no-build-isolation --no-deps /tmp/submodules/diff_lidargs_surfel_rasterization \
#   && python3 -m pip install --no-build-isolation --no-deps /tmp/submodules/pano_ext_pkg \
#   && python3 -m pip install --no-build-isolation --no-deps /tmp/submodules/gsplat \
#   && rm -rf /tmp/submodules

# 临时挂载 submodules，复制到 /tmp 后安装 gsplat。
# 这里复制一份是为了满足 pip 安装过程对源码路径的访问需求，安装后立即清理。
RUN --mount=type=bind,source=${DEPS_ROOT}/submodules,target=/mnt/submodules,readonly \
  set -eux; \
  cp -a /mnt/submodules /tmp/submodules; \
  /opt/venv/bin/python3 -m pip install --no-build-isolation --no-deps /tmp/submodules/gsplat \
  && rm -rf /tmp/submodules /root/.cache/pip /tmp/pip-* /tmp/tmp*

# 构建末尾执行 gsplat 预热脚本。
# 这个脚本不能保证覆盖全部真实业务路径，但可以提前编译一部分常见 CUDA kernel。
COPY ${DEPS_ROOT}/precompile_gsplat.py /tmp/precompile_gsplat.py
RUN chown app:app /tmp/precompile_gsplat.py \
 && su -s /bin/bash - app -c "\
    HOME=/home/app \
    MAX_JOBS=10 \
    TORCH_CUDA_ARCH_LIST='${TORCH_CUDA_ARCH_LIST}' \
    /opt/venv/bin/python3 /tmp/precompile_gsplat.py" \
 && rm -f /tmp/precompile_gsplat.py

# 容器启动后常驻 SSHD，业务命令由外部调度器注入执行。
ENTRYPOINT ["/usr/local/bin/container-entrypoint.sh"]
```
