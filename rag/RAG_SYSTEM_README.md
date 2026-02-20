# ImageToArkTS RAG System

本项目构建了一个针对 HarmonyOS (ArkTS) 开发文档的 RAG (检索增强生成) 系统。目的是通过检索最新的官方 API 文档，增强大模型生成 ArkTS 代码的准确性与时效性，并提供一个对比评测环境。

## 1. 系统概述

由于 HarmonyOS API 更新频繁，通用大模型（如 GPT-4、DeepSeek）的训练数据可能滞后，导致生成的 ArkTS 代码经常包含过时的 API 或错误的 Import 路径。

本系统通过以下流程解决此问题：
1. **知识库构建**：将结构化的 JSON API 文档转换为向量数据库。
2. **混合检索**：根据用户问题检索最相关的 API 接口定义和示例。
3. **增强生成**：将检索到的精确上下文注入到 Prompt 中，引导 LLM 生成可编译的代码。
4. **对比评测**：同时展示 "纯 LLM" 与 "RAG 增强 LLM" 的回答，便于直观评估 RAG 的效果。

## 2. 目录结构

```text
rag/
├── updated_reference_cleaned/ # [输入] 原始 JSON 格式的 API 文档
├── processed_data.jsonl       # [中间产物] 清洗并切分后的文本数据
├── chroma_db/                 # [输出] 向量数据库持久化文件 (自动生成)
├── prepare_data.py            # [脚本] 数据预处理：JSON -> 文本切片
├── build_db.py                # [脚本] 数据库构建：文本切片 -> 向量库 (Embedding)
├── rag_engine.py              # [核心] 封装向量数据库操作和检索逻辑
├── query_system.py            # [应用] 交互式命令行问答与对比工具
└── RAG_SYSTEM_README.md       # 本文档
```

## 3. 快速开始

### 3.1 环境准备

确保安装 Python 3.8+，并安装必要的依赖库：

```bash
pip install chromadb sentence-transformers openai
```

*注意：`sentence-transformers` 在首次运行时会自动下载预训练的 Embedding 模型（约 400MB）。*

### 3.2 步骤一：数据预处理

解析 `updated_reference_cleaned/` 下的所有 JSON 文件，按 API 粒度进行切分，保留 Import 路径、方法签名和属性表。

```powershell
python rag/prepare_data.py
```
*   **输出**：生成 `processed_data.jsonl` 文件。

### 3.3 步骤二：构建向量索引

读取切分好的数据，计算向量并存入 ChromaDB。此过程视数据量而定，可能需要 10-20 分钟。

```powershell
python rag/build_db.py
```
*   **输出**：在 `rag/chroma_db/` 目录下生成数据库文件。

### 3.4 步骤三：配置 LLM

打开 `rag/query_system.py`，配置你的 OpenAI API Key 或兼容接口（如 DeepSeek）：

```python
# rag/query_system.py 第 12 行附近
client = OpenAI(
    # 如果使用第三方服务，请取消注释并设置 base_url
    # base_url="https://api.deepseek.com/v1", 
    api_key=os.environ.get("OPENAI_API_KEY", "sk-xxxxxxxxxxxxxxxx")
)
```

目前配置的是阿里云的deepseek-v3.2

### 3.5 步骤四：运行对比系统

启动交互式终端，输入技术问题，实时查看 RAG 与非 RAG 的效果对比。

```powershell
python rag/query_system.py
```

## 4. 典型测试用例

在系统启动后，尝试输入以下问题进行测试：

1. **API 使用**：
   > "如何使用 UiTest 模拟点击操作？"
   *   *预期 RAG 优势*：提供正确的 `@ohos.UiTest` 导入路径和最新的 `findComponent` / `click` 方法。

2. **特定模块功能**：
   > "如何实现华为账号一键登录？"
   *   *预期 RAG 优势*：检索到 `authentication.HuaweiIDProvider` 等特定 API 类定义。

3. **权限查询**：
   > "申请麦克风权限的 constant 是什么？"
   *   *预期 RAG 优势*：准确返回 `ohos.permission.MICROPHONE` 或相关 ability 定义。

## 5. 自定义配置

*   **更换 Embedding 模型**：
    在 `rag_engine.py` 中修改 `model_name`。默认使用 multilingual 模型以支持中英文混合文档。
    ```python
    embedding_functions.SentenceTransformerEmbeddingFunction(
        model_name="paraphrase-multilingual-MiniLM-L12-v2" 
    )
    ```

*   **调整检索数量**：
    在 `query_system.py` 的检索调用中修改 `n_results` 参数（默认 5 条）。
