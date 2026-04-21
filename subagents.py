from __future__ import annotations

from functools import lru_cache

from deepagents import create_deep_agent

from contracts.agent_contracts import ARCHITECT_DEFINITION, CODER_DEFINITION, TESTER_DEFINITION
from models import base_model, vision_model
from tools.human_guidance import request_human_guidance
from tools.json_tools import validate_json_syntax
from tools.project_tools import create_project, compile_project
from tools.review_flow_tools import (
    run_review_node_with_inputs,
    run_visual_review_with_inputs,
    summarize_review_features_by_page,
)
from tools.tester_tools import TESTER_TOOLS
from utils.checkpointing import get_checkpointer
from utils.session_backend import backend_factory
from utils.utils import load_prompt

ARCHITECT_SUBAGENT_TOOLS = [validate_json_syntax, request_human_guidance]
CODER_ORCHESTRATOR_TOOLS = []
CODER_SKELETON_WORKER_TOOLS = [create_project, validate_json_syntax, request_human_guidance]
CODER_PAGE_WORKER_TOOLS = [validate_json_syntax, request_human_guidance]
CODER_INTEGRATION_WORKER_TOOLS = [compile_project, validate_json_syntax, request_human_guidance]
TESTER_SUBAGENT_TOOLS = [*TESTER_TOOLS, validate_json_syntax, request_human_guidance]
REVIEW_EXECUTOR_SUBAGENT_TOOLS = [run_review_node_with_inputs, validate_json_syntax, request_human_guidance]
FLOW_SUMMARY_SUBAGENT_TOOLS = [summarize_review_features_by_page, validate_json_syntax, request_human_guidance]
VISUAL_REVIEW_SUBAGENT_TOOLS = [run_visual_review_with_inputs, validate_json_syntax, request_human_guidance]


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
    "skills": ["/skills"],
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

REVIEW_EXECUTOR_SUBAGENT_SPEC = {
    "name": "review_executor",
    "description": "Run review node full-flow testing right after coder finishes.",
    "model": vision_model,
    "system_prompt": load_prompt("review_executor_system_prompt.md"),
    "tools": REVIEW_EXECUTOR_SUBAGENT_TOOLS,
}

FLOW_SUMMARY_SUBAGENT_SPEC = {
    "name": "flow_summary",
    "description": "Summarize implemented popup/state-change behaviors and navigation paths from review outputs.",
    "model": vision_model,
    "system_prompt": load_prompt("flow_summary_system_prompt.md"),
    "tools": FLOW_SUMMARY_SUBAGENT_TOOLS,
}

VISUAL_REVIEW_SUBAGENT_SPEC = {
    "name": "visual_review",
    "description": "Run visual matching between user input references and runtime screenshots after flow summary.",
    "model": vision_model,
    "system_prompt": load_prompt("visual_review_system_prompt.md"),
    "tools": VISUAL_REVIEW_SUBAGENT_TOOLS,
}

SUBAGENT_SPECS = [
    ARCHITECT_SUBAGENT_SPEC,
    CODER_ORCHESTRATOR_SPEC,
    CODER_SKELETON_WORKER_SPEC,
    CODER_PAGE_WORKER_SPEC,
    CODER_INTEGRATION_WORKER_SPEC,
    TESTER_SUBAGENT_SPEC,
    REVIEW_EXECUTOR_SUBAGENT_SPEC,
    FLOW_SUMMARY_SUBAGENT_SPEC,
    VISUAL_REVIEW_SUBAGENT_SPEC,
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
    return _build_subagent(ARCHITECT_SUBAGENT_SPEC)


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
        tools=[*CODER_ORCHESTRATOR_TOOLS, validate_json_syntax, request_human_guidance],
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


@lru_cache(maxsize=1)
def get_review_executor_agent():
    return _build_subagent(REVIEW_EXECUTOR_SUBAGENT_SPEC)


@lru_cache(maxsize=1)
def get_flow_summary_agent():
    return _build_subagent(FLOW_SUMMARY_SUBAGENT_SPEC)


@lru_cache(maxsize=1)
def get_visual_review_agent():
    return _build_subagent(VISUAL_REVIEW_SUBAGENT_SPEC)
