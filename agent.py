from langchain.agents import create_agent
from langchain.agents.middleware import TodoListMiddleware
from langchain_anthropic.middleware import AnthropicPromptCachingMiddleware

from deepagents.graph import BASE_AGENT_PROMPT
from deepagents.middleware.filesystem import FilesystemMiddleware
from deepagents.middleware.patch_tool_calls import PatchToolCallsMiddleware
from deepagents.middleware.summarization import create_summarization_middleware
from models import base_model
from subagents import SUBAGENT_SPECS
from tools.tool_sets import ORCHESTRATOR_AGENT_TOOLS
from utils.checkpointing import get_checkpointer
from utils.session_backend import backend_factory
from utils.utils import load_prompt


agent = create_agent(
    model=base_model,
    system_prompt=load_prompt("system_prompt.md") + "\n\n" + BASE_AGENT_PROMPT,
    tools=ORCHESTRATOR_AGENT_TOOLS,
    middleware=[
        TodoListMiddleware(),
        FilesystemMiddleware(backend=backend_factory),
        create_summarization_middleware(base_model, backend_factory),
        AnthropicPromptCachingMiddleware(unsupported_model_behavior="ignore"),
        PatchToolCallsMiddleware(),
    ],
    checkpointer=get_checkpointer(),
).with_config(
    {
        "recursion_limit": 1000,
        "metadata": {
            "ls_integration": "deepagents",
        },
    }
)

graph = agent
subagents = SUBAGENT_SPECS


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
