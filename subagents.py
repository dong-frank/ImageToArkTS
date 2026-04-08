from __future__ import annotations

from functools import lru_cache

from deepagents import create_deep_agent
from langchain.agents import create_agent
from langchain.agents.middleware import TodoListMiddleware
from langchain_anthropic.middleware import AnthropicPromptCachingMiddleware

from contracts.agent_contracts import ARCHITECT_DEFINITION, CODER_DEFINITION, TESTER_DEFINITION
from deepagents.middleware.patch_tool_calls import PatchToolCallsMiddleware
from deepagents.middleware.summarization import create_summarization_middleware
from models import base_model, vision_model
from tools.human_guidance import request_human_guidance
from tools.project_tools import CODER_TOOLS
from tools.tester_tools import TESTER_TOOLS
from utils.checkpointing import get_checkpointer
from utils.session_backend import backend_factory
from utils.utils import load_prompt

ARCHITECT_SUBAGENT_TOOLS = [request_human_guidance]
CODER_SUBAGENT_TOOLS = [*CODER_TOOLS, request_human_guidance]
TESTER_SUBAGENT_TOOLS = [*TESTER_TOOLS, request_human_guidance]


ARCHITECT_SUBAGENT_SPEC = {
    "name": ARCHITECT_DEFINITION.name,
    "description": ARCHITECT_DEFINITION.description,
    "model": base_model,
    "system_prompt": load_prompt("architect_system_prompt.md"),
    "tools": ARCHITECT_SUBAGENT_TOOLS,
}

CODER_SUBAGENT_SPEC = {
    "name": CODER_DEFINITION.name,
    "description": CODER_DEFINITION.description,
    "model": base_model,
    "system_prompt": load_prompt("coder_system_prompt.md"),
    "skills": ["/skills"],
    "tools": CODER_SUBAGENT_TOOLS,
}

TESTER_SUBAGENT_SPEC = {
    "name": TESTER_DEFINITION.name,
    "description": TESTER_DEFINITION.description,
    "model": vision_model,
    "system_prompt": load_prompt("tester_system_prompt.md"),
    "tools": TESTER_SUBAGENT_TOOLS,
}

SUBAGENT_SPECS = [
    ARCHITECT_SUBAGENT_SPEC,
    CODER_SUBAGENT_SPEC,
    TESTER_SUBAGENT_SPEC,
]


def _build_subagent(spec: dict):
    return create_deep_agent(
        model=spec["model"],
        system_prompt=spec["system_prompt"],
        tools=spec["tools"],
        skills=spec.get("skills"),
        backend=backend_factory,
        checkpointer=get_checkpointer(),
        name=spec["name"],
    )


def _build_architect_agent():
    return create_agent(
        model=ARCHITECT_SUBAGENT_SPEC["model"],
        system_prompt=ARCHITECT_SUBAGENT_SPEC["system_prompt"],
        tools=ARCHITECT_SUBAGENT_SPEC["tools"],
        middleware=[
            TodoListMiddleware(),
            create_summarization_middleware(ARCHITECT_SUBAGENT_SPEC["model"], backend_factory),
            AnthropicPromptCachingMiddleware(unsupported_model_behavior="ignore"),
            PatchToolCallsMiddleware(),
        ],
        checkpointer=get_checkpointer(),
        name=ARCHITECT_SUBAGENT_SPEC["name"],
    ).with_config(
        {
            "recursion_limit": 1000,
            "metadata": {
                "ls_integration": "deepagents",
            },
        }
    )


@lru_cache(maxsize=1)
def get_architect_agent():
    return _build_architect_agent()


@lru_cache(maxsize=1)
def get_coder_agent():
    return _build_subagent(CODER_SUBAGENT_SPEC)


@lru_cache(maxsize=1)
def get_tester_agent():
    return _build_subagent(TESTER_SUBAGENT_SPEC)
