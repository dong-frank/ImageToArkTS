from deepagents import create_deep_agent
from langchain_openai import ChatOpenAI
import dotenv
import os
from utils.utils import load_prompt
from schemas import ArchitectOutput
from deepagents.backends import FilesystemBackend
from deepagents.middleware.subagents import SubAgentMiddleware
from tools import create_project, compile_project
from models import vision_model, base_model

architect_subagent = {
    "name": "architect",
    "description": "架构师Agent，负责拆解用户的意图，识别用户草图的UI组件，并将其转化为设计方案的高层次描述。",
    "model": vision_model,
    "system_prompt": load_prompt("architect_system_prompt.md"),
    "response_format": ArchitectOutput,
    "tools": []
}

# 预期是一个ReAct 根据编译的结果优化，直到生成编译没有错误的项目
coding_subagent = {
    "name": "coder",
    "description": "编码Agent，负责将架构师Agent提供的设计方案转化为可执行的代码实现。",
    "model": base_model,
    "system_prompt": load_prompt("coder_system_prompt.md"),
    "skills": ["/skills"],
    "tools": [create_project, compile_project]
}

test_subagent = {
    "name": "tester",
    "description": "测试Agent，负责验证编码Agent生成的代码是否符合架构师Agent提供的设计方案，并确保代码的正确性和功能完整性。",
    "model": base_model,
    "system_prompt": load_prompt("tester_system_prompt.md"),
    "tools": []
}

subagents = [architect_subagent, coding_subagent]

agent = create_deep_agent(
    model=base_model,
    system_prompt=load_prompt("system_prompt.md"),
    subagents=subagents,
    backend=FilesystemBackend(root_dir="/Users/dong/2026/ImageToArkTS-DeepAgents/agent_workspace", virtual_mode=True),
    tools=[],
)

agent.invoke({
    "messages": [
        {
            "role": "user",
            "content": "用户的所有信息都在工作目录下，请开始工作"
        }
    ]
})
