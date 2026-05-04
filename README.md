# ImageToArkTS-DeepAgents

## 环境配置

### 1. 安装基础依赖

- Python `3.11+`
- [uv](https://docs.astral.sh/uv/)
- Node.js / npm
- HarmonyOS 工具链：`ohpm`、`hvigorw`

### 2. 配置环境变量

项目会读取根目录下的 `.env`，至少需要：

```env
DASHSCOPE_API_KEY=your_dashscope_api_key
DASHSCOPE_BASE_URL=https://dashscope.aliyuncs.com/compatible-mode/v1
```

如果要启用 LangSmith，再补充：

```env
LANGSMITH_TRACING=true
LANGSMITH_API_KEY=your_langsmith_api_key
LANGSMITH_PROJECT=ImageToArkTS
```

### 3. 安装依赖

安装 Python 依赖：

```bash
uv sync
```

安装前端依赖：

```bash
cd frontend
npm install
```

## 如何运行

### 方式一：运行主流程

先把输入资料放到 `agent_workspace/user_input`，然后在项目根目录执行：

```bash
uv run python main.py
```

### 方式二：启动对话页面

在项目根目录启动后端：

```bash
uv run python runtime.py
```

再在 `frontend` 目录启动前端：

```bash
cd frontend
npm run dev
```

默认访问地址：

- 后端：`http://127.0.0.1:8080`
- 前端：`http://127.0.0.1:5173`

## Session 隔离（本地）

默认使用本地文件系统隔离，不需要额外云端沙箱配置。

```env
# 可选，默认即 filesystem
SANDBOX_PROVIDER=filesystem
```

启动应用：

```bash
uv run python runtime.py
```

前端每个 `session_id` 会映射到独立本地目录：

`agent_workspace/sessions/<session_id>/...`
