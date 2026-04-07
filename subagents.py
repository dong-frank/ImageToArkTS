from __future__ import annotations

from functools import lru_cache

from deepagents import create_deep_agent
from langchain.agents.structured_output import ToolStrategy

from contracts.agent_contracts import ARCHITECT_DEFINITION, CODER_DEFINITION, TESTER_DEFINITION
from models import architect_vision_model, base_model, vision_model
from schemas import ArchitectOutput, TesterReportOutput
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
    "model": architect_vision_model,
    "system_prompt": load_prompt("architect_system_prompt.md"),
    "tools": ARCHITECT_SUBAGENT_TOOLS,
    "response_format": ToolStrategy(ArchitectOutput),
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
    "response_format": ToolStrategy(TesterReportOutput),
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
        response_format=spec.get("response_format"),
        backend=backend_factory,
        checkpointer=get_checkpointer(),
        name=spec["name"],
    )


@lru_cache(maxsize=1)
def get_architect_agent():
    return _build_subagent(ARCHITECT_SUBAGENT_SPEC)


@lru_cache(maxsize=1)
def get_coder_agent():
    return _build_subagent(CODER_SUBAGENT_SPEC)


@lru_cache(maxsize=1)
def get_tester_agent():
    return _build_subagent(TESTER_SUBAGENT_SPEC)
