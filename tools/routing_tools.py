from __future__ import annotations

import json
from typing import Literal

from langchain.tools import ToolRuntime, tool
from langchain_core.messages import HumanMessage, ToolMessage
from langgraph.types import Command

from contracts.agent_contracts import (
    ARCHITECT_DISPATCH_CONTRACT,
    TESTER_DISPATCH_CONTRACT,
    build_coder_dispatch_contract,
)
from subagents import get_architect_agent, get_coder_agent, get_tester_agent
from tools.architect_tools import save_architect_design_payload
from utils.session_context import reset_current_session_id, set_current_session_id

_EXCLUDED_STATE_KEYS = {"messages", "todos", "structured_response", "skills_metadata", "memory_contents"}


def build_architect_dispatch_description() -> str:
    return ARCHITECT_DISPATCH_CONTRACT.render()


def build_coder_dispatch_description(task_type: Literal["implementation", "fix_from_test"]) -> str:
    return build_coder_dispatch_contract(task_type=task_type).render()


def build_tester_dispatch_description() -> str:
    return TESTER_DISPATCH_CONTRACT.render()


def _build_subagent_state(description: str, runtime: ToolRuntime):
    subagent_state = {k: v for k, v in runtime.state.items() if k not in _EXCLUDED_STATE_KEYS}
    subagent_state["messages"] = [HumanMessage(content=description)]
    return subagent_state


def _command_from_result(result: dict, tool_call_id: str, final_message_override: str | None = None) -> Command:
    state_update = {k: v for k, v in result.items() if k not in _EXCLUDED_STATE_KEYS}
    final_message = final_message_override
    if final_message is None:
        final_message = result["messages"][-1].text.rstrip() if result.get("messages") else ""
    return Command(
        update={
            **state_update,
            "messages": [ToolMessage(final_message, tool_call_id=tool_call_id)],
        }
    )


def _invoke_subagent(agent, description: str, runtime: ToolRuntime) -> dict:
    runtime_config = getattr(runtime, "config", None)
    thread_id = None
    if isinstance(runtime_config, dict):
        configurable = runtime_config.get("configurable")
        if isinstance(configurable, dict):
            thread_id = configurable.get("thread_id")

    session_token = set_current_session_id(thread_id)
    try:
        return agent.invoke(
            _build_subagent_state(description, runtime),
            config=runtime_config,
        )
    finally:
        reset_current_session_id(session_token)


@tool
def dispatch_architect(runtime: ToolRuntime) -> Command:
    """
    Dispatch the architect stage with a fixed architecture contract.
    """
    if not runtime.tool_call_id:
        raise ValueError("Tool call ID is required for architect dispatch")

    result = _invoke_subagent(get_architect_agent(), build_architect_dispatch_description(), runtime)
    structured_response = result.get("structured_response")
    final_message = result["messages"][-1].text if result.get("messages") else ""
    payload_for_save = structured_response if structured_response is not None else final_message
    save_result = save_architect_design_payload(payload_for_save)
    if structured_response is not None:
        final_message = json.dumps(structured_response, ensure_ascii=False, indent=2)
    return _command_from_result(
        result,
        runtime.tool_call_id,
        final_message_override=f"{final_message}\n\nsave_result: {save_result}",
    )


@tool
def dispatch_coder(
    task_type: Literal["implementation", "fix_from_test"] = "implementation",
    runtime: ToolRuntime = None,
) -> Command:
    """
    Dispatch the coder stage with a fixed implementation or fix contract.
    """
    if runtime is None or not runtime.tool_call_id:
        raise ValueError("Tool call ID is required for coder dispatch")

    description = build_coder_dispatch_description(task_type=task_type)
    result = _invoke_subagent(get_coder_agent(), description, runtime)
    return _command_from_result(result, runtime.tool_call_id)


@tool
def dispatch_tester(runtime: ToolRuntime) -> Command:
    """
    Dispatch the tester stage with a fixed validation contract.
    """
    if not runtime.tool_call_id:
        raise ValueError("Tool call ID is required for tester dispatch")

    result = _invoke_subagent(get_tester_agent(), build_tester_dispatch_description(), runtime)
    structured_response = result.get("structured_response")
    final_message_override = None
    if structured_response is not None:
        final_message_override = json.dumps(structured_response, ensure_ascii=False, indent=2)
    return _command_from_result(result, runtime.tool_call_id, final_message_override=final_message_override)


ROUTING_TOOLS = [
    dispatch_architect,
    dispatch_coder,
    dispatch_tester,
]
