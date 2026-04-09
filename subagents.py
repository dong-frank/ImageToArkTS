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
CODER_ORCHESTRATOR_TOOLS = []
CODER_SKELETON_WORKER_TOOLS = [request_human_guidance]
CODER_PAGE_WORKER_TOOLS = [request_human_guidance]
CODER_INTEGRATION_WORKER_TOOLS = [*CODER_TOOLS, request_human_guidance]
TESTER_SUBAGENT_TOOLS = [*TESTER_TOOLS, request_human_guidance]


ARCHITECT_SUBAGENT_SPEC = {
    "name": ARCHITECT_DEFINITION.name,
    "description": ARCHITECT_DEFINITION.description,
    "model": base_model,
    "system_prompt": load_prompt("architect_system_prompt.md"),
    "tools": ARCHITECT_SUBAGENT_TOOLS,
}

CODER_ORCHESTRATOR_SPEC = {
    "name": "coder_orchestrator",
    "description": "Coordinate skeleton, page worker, and integration stages for coding tasks.",
    "model": base_model,
    "system_prompt": load_prompt("coder_orchestrator_system_prompt.md"),
    "tools": CODER_ORCHESTRATOR_TOOLS,
}

CODER_SKELETON_WORKER_SPEC = {
    "name": "coder_skeleton_worker",
    "description": "Plan shared project skeleton and page tasks from architect design.",
    "model": base_model,
    "system_prompt": load_prompt("coder_skeleton_system_prompt.md"),
    "tools": CODER_SKELETON_WORKER_TOOLS,
}

CODER_PAGE_WORKER_SPEC = {
    "name": "coder_page_worker",
    "description": "Implement one page and its page-local components inside assigned file boundaries.",
    "model": base_model,
    "system_prompt": load_prompt("coder_page_system_prompt.md"),
    "skills": ["/skills"],
    "tools": CODER_PAGE_WORKER_TOOLS,
}

CODER_INTEGRATION_WORKER_SPEC = {
    "name": "coder_integration_worker",
    "description": "Integrate page results, resolve shared issues, and support compile closure.",
    "model": base_model,
    "system_prompt": load_prompt("coder_integration_system_prompt.md"),
    "skills": ["/skills"],
    "tools": CODER_INTEGRATION_WORKER_TOOLS,
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
    CODER_ORCHESTRATOR_SPEC,
    CODER_SKELETON_WORKER_SPEC,
    CODER_PAGE_WORKER_SPEC,
    CODER_INTEGRATION_WORKER_SPEC,
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
def get_coder_skeleton_worker():
    return _build_subagent(CODER_SKELETON_WORKER_SPEC)


def _build_coder_orchestrator():
    from tools.routing_tools import CODER_ORCHESTRATOR_TOOLS

    return create_deep_agent(
        model=CODER_ORCHESTRATOR_SPEC["model"],
        system_prompt=CODER_ORCHESTRATOR_SPEC["system_prompt"],
        tools=[*CODER_ORCHESTRATOR_TOOLS, request_human_guidance],
        backend=backend_factory,
        checkpointer=get_checkpointer(),
        name=CODER_ORCHESTRATOR_SPEC["name"],
    )


@lru_cache(maxsize=1)
def get_coder_orchestrator():
    return _build_coder_orchestrator()


def build_coder_page_worker():
    return _build_subagent(CODER_PAGE_WORKER_SPEC)


@lru_cache(maxsize=1)
def get_coder_integration_worker():
    return _build_subagent(CODER_INTEGRATION_WORKER_SPEC)


@lru_cache(maxsize=1)
def get_tester_agent():
    return _build_subagent(TESTER_SUBAGENT_SPEC)
