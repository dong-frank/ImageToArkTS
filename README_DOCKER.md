# ImageToArkTS-DeepAgents

使用Docker运行方式：针对本地编译工具配置失败场景，如果本地已完成编译工具配置直接使用原来的方式。

TL;DR: 直接将这个文档发给Agent, 如codex, 让它帮你安装

## 前端

安装前端依赖：

```bash
cd frontend
npm install
```

运行bash
```
cd frontend
npm run dev
```

## 后端运行时


Docker 运行 runtime（Windows/Mac/Linux）

### 1. 前置条件

- Docker Desktop（Windows/Mac）或 Docker Engine（Linux）
- Docker Compose Plugin（`docker compose`）
- 可访问 Docker Hub 并拉取镜像 `dongfrank1524/imagetoarkts-runtime:latest`
- 补充: 如果遇到访问困难，可以参考使用镜像站，我使用的镜像站 https://xuanyuan.cloud/?code=U3VY35

### 2. 准备环境变量

从模板创建 `.env`：

```bash
cp .env_template .env
```

然后按实际情况修改 `.env` 至少以下字段：

```env
DASHSCOPE_API_KEY=your_dashscope_api_key
DASHSCOPE_BASE_URL=https://dashscope.aliyuncs.com/compatible-mode/v1

LANGSMITH_API_KEY=your_langsmith_api_key

HDC_AUTO_TCONN=1
HDC_TCP_TARGET=host.docker.internal:<你的模拟器端口>
```

示例（宿主机模拟器是 `127.0.0.1:5555`）：

如何查看模拟器端口：宿主机上运行`hdc list targets`


### 3. 拉取并启动 runtime 容器

```bash
docker pull dongfrank1524/imagetoarkts-runtime:latest
docker run -d --name imagetoarkts-runtime \
  --restart unless-stopped \
  --platform linux/amd64 \
  --env-file .env \
  -p 8080:8080 \
  -v runtime_agent_workspace:/app/agent_workspace \
  dongfrank1524/imagetoarkts-runtime:latest
```

### 4. 验证运行状态

```bash
docker logs -f imagetoarkts-runtime
curl -s http://127.0.0.1:8080/workspace/tree
```

### 5. 停止服务

```bash
docker rm -f imagetoarkts-runtime
```

### 说明与注意事项

- `hdc tconn` 是运行时连接动作，容器启动时会根据 `.env` 自动尝试连接。
- 运行时会根据 `.env` 的 `HDC_TCP_TARGET` 自动尝试连接宿主机模拟器（`host.docker.internal` 会在容器内解析为 IPv4）。
- runtime 对外端口：`8080`。
- 会话数据持久化在 Docker volume：`runtime_agent_workspace`（容器内目录 `/app/agent_workspace`）。

## 开发后本地重新构建

当对代码进行修改后，快速验证，进行镜像重新构建，但如果本地的编译工具已经配置好直接用python运行方式

### 1. 准备命令行工具压缩包

先确认本地存在：

`docker/harmony/commandline-tools-linux-x64-*.zip`

下载地址 https://developer.huawei.com/consumer/cn/download/command-line-tools-for-hmos

没有该文件会导致镜像构建失败。

### 2. 本地构建开发镜像

```bash
docker buildx build \
  --platform linux/amd64 \
  -f Dockerfile.runtime \
  -t imagetoarkts-runtime:dev \
  --load \
  .
```

### 3. 用开发镜像启动容器

```bash
docker run -d --name imagetoarkts-runtime-dev \
  --restart unless-stopped \
  --platform linux/amd64 \
  --env-file .env \
  -p 8080:8080 \
  -v runtime_agent_workspace:/app/agent_workspace \
  imagetoarkts-runtime:dev
```
