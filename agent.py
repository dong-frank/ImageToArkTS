from deepagents import create_deep_agent

from models import architect_vision_model, base_model, vision_model
from schemas import ArchitectOutput
from tools.tool_sets import (
    ARCHITECT_SUBAGENT_TOOLS,
    CODER_SUBAGENT_TOOLS,
    MAIN_AGENT_TOOLS,
    TESTER_SUBAGENT_TOOLS,
)
from utils.checkpointing import get_checkpointer
from utils.session_backend import backend_factory
from utils.utils import load_prompt


architect_subagent = {
    "name": "architect",
    "description": "架构师 Agent，负责拆解用户意图并生成结构化设计方案。",
    "model": architect_vision_model,
    "system_prompt": load_prompt("architect_system_prompt.md"),
    "response_format": ArchitectOutput,
    "tools": ARCHITECT_SUBAGENT_TOOLS,
}

coding_subagent = {
    "name": "coder",
    "description": "编码 Agent，负责将架构方案转化为可编译的项目实现。",
    "model": base_model,
    "system_prompt": load_prompt("coder_system_prompt.md"),
    "skills": ["/skills"],
    "tools": CODER_SUBAGENT_TOOLS,
}

test_subagent = {
    "name": "tester",
    "description": "测试验收 Agent，负责启动 app、按坐标点击验证流程并基于 description 做功能与静态 UI 完整性验收。",
    "model": vision_model,
    "system_prompt": load_prompt("tester_system_prompt.md"),
    "tools": TESTER_SUBAGENT_TOOLS,
}

subagents = [architect_subagent, coding_subagent, test_subagent]

agent = create_deep_agent(
    model=base_model,
    system_prompt=load_prompt("system_prompt.md"),
    subagents=subagents,
    backend=backend_factory,
    tools=MAIN_AGENT_TOOLS,
    checkpointer=get_checkpointer(),
)

graph = agent


def run_agent():
    return agent.invoke(
        {
            "messages": [
                {
                    "role": "user",
                    "content": "用户输入资料都在 /user_input 目录下，请只将该目录内容视为用户输入并开始工作。",
                }
            ]
        }
    )


if __name__ == "__main__":
    run_agent()
