# ImageToArkTS-DeepAgents

一个面向 HarmonyOS/ArkTS 快速原型生成的多 Agent 项目。

目标流程是：

1. 产品经理把草图、截图、需求说明放进 `agent_workspace/user_input`
2. `architect` 负责提炼页面结构、视觉风格和跳转关系
3. `coder` 负责生成一个可编译、可展示的 HarmonyOS 原型

当前策略偏向快速原型：

- 优先做出可用 UI
- 允许 mock 数据和简化交互
- 不强调工程规范化优先
- 默认优先硬编码字符串和颜色，减少资源系统复杂度

## 环境要求

- Python `3.11+`
- [uv](https://docs.astral.sh/uv/)
- 本地可用的 HarmonyOS/Hvigor/ACE 工具链

如果下面这些命令在你的机器上不可用，项目编译和创建工程会失败：

- `ace`
- `ohpm`
- `hvigorw`

## `.env` 配置

项目使用 `dotenv` 读取根目录下的 `.env`。

最少需要配置：

```env
DASHSCOPE_API_KEY=your_dashscope_api_key
DASHSCOPE_BASE_URL=https://dashscope.aliyuncs.com/compatible-mode/v1
```

当前代码里：

- `vision_model` 使用 `qwen3-vl-plus`
- `base_model` 使用 `qwen3.5-plus`

如果你想接 LangSmith，建议再补上：

```env
LANGSMITH_TRACING=true
LANGSMITH_API_KEY=your_langsmith_api_key
LANGSMITH_PROJECT=ImageToArkTS-DeepAgents
```

## 用 `uv` 快速配置环境

第一次进入项目：

```bash
uv sync
```

如果你想显式使用虚拟环境中的 Python：

```bash
uv run python --version
```

运行主流程：

```bash
uv run python main.py
```

这条命令会先：

1. 清空 `agent_workspace/projects`
2. 清空 `agent_workspace/designs`
3. 保留 `agent_workspace/skills`
4. 保留 `agent_workspace/user_input`
5. 然后运行 agent 流程

## 推荐启动步骤

1. 把用户输入放到 `agent_workspace/user_input`
2. 确认 `.env` 已配置
3. 执行：

```bash
uv run python main.py
```

## `agent_workspace` 目录说明

```text
agent_workspace/
  user_input/   # 用户输入：草图、截图、需求文本
  skills/       # 供 agent 使用的 skills
  designs/      # architect 输出的结构化设计
  projects/     # coder 生成的 HarmonyOS 项目
```

其中：

- `user_input` 视为用户材料
- `skills` 视为系统能力
- `designs` 是中间产物
- `projects` 是生成结果

## 常用命令

同步依赖：

```bash
uv sync
```

运行主流程：

```bash
uv run python main.py
```

只重置测试输出：

```bash
./scripts/reset_agent_workspace.sh
```

## 说明

这个项目当前更适合做“产品原型快速落地”，而不是严格工程化生成器。

如果模型生成了不符合 ArkTS 语法的代码，当前系统会依赖：

- `compile_project` 的编译摘要
- `arkts-syntax-assistant` skill
- `harmony-project-layout` skill

来逐步修正并继续迭代。
