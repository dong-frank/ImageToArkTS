from __future__ import annotations

import json
from typing import Literal

from langchain.tools import ToolRuntime, tool
from langchain_core.messages import HumanMessage, SystemMessage, ToolMessage
from langgraph.types import Command

from contracts.agent_contracts import (
    ARCHITECT_DISPATCH_CONTRACT,
    TESTER_DISPATCH_CONTRACT,
    build_coder_dispatch_contract,
)
from models import base_model
from schemas import ArchitectOutput, TesterReportOutput
from subagents import get_coder_agent, get_tester_agent
from tools.architect_tools import build_architect_image_facts_bundle_payload, save_architect_design_payload
from tools.common import resolve_workspace_path
from utils.session_context import reset_current_session_id, set_current_session_id
from utils.llm_utils import extract_tool_call_args, invoke_with_tool, normalize_tool_schema
from utils.utils import load_prompt

_EXCLUDED_STATE_KEYS = {"messages", "todos", "structured_response", "skills_metadata", "memory_contents"}
_ARCHITECT_SYSTEM_PROMPT = load_prompt("architect_system_prompt.md")


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


def build_architect_aggregation_prompt(metadata_payload: dict, facts_bundle: dict) -> str:
    return "\n".join(
        [
            build_architect_dispatch_description(),
            "",
            "The orchestrator has already materialized the architect inputs below.",
            "Do not call filesystem write tools for the final design. Return only structured ArchitectOutput.",
            "",
            "Materialized input: /user_input/user_input_metadata.json",
            json.dumps(metadata_payload, ensure_ascii=False, indent=2),
            "",
            "Materialized input: /designs/architect_image_facts.json",
            json.dumps(facts_bundle, ensure_ascii=False, indent=2),
        ]
    )


def load_architect_materialized_inputs() -> tuple[dict, dict]:
    metadata_payload = json.loads(resolve_workspace_path("/user_input/user_input_metadata.json").read_text(encoding="utf-8"))
    facts_bundle = json.loads(resolve_workspace_path("/designs/architect_image_facts.json").read_text(encoding="utf-8"))
    return metadata_payload, facts_bundle


def load_tester_report_payload() -> dict:
    report_payload = json.loads(resolve_workspace_path("/logs/tester/latest_tester_report.json").read_text(encoding="utf-8"))
    return TesterReportOutput.model_validate(report_payload).model_dump(mode="json", exclude_none=True)


def invoke_architect_aggregator(metadata_payload: dict, facts_bundle: dict) -> dict:
    tool_name = "ArchitectOutput"
    tool_schema = normalize_tool_schema(ArchitectOutput.model_json_schema())
    llm_response = invoke_with_tool(
        base_model,
        [
            SystemMessage(content=_ARCHITECT_SYSTEM_PROMPT),
            HumanMessage(content=build_architect_aggregation_prompt(metadata_payload=metadata_payload, facts_bundle=facts_bundle)),
        ],
        tool_name,
        tool_schema,
    )
    tool_args = extract_tool_call_args(llm_response, tool_name)
    if tool_args is not None:
        return tool_args

    content = getattr(llm_response, "content", "")
    if isinstance(content, str):
        stripped = content.strip()
        if "```json" in stripped:
            stripped = stripped.split("```json", 1)[1].split("```", 1)[0].strip()
        elif stripped.startswith("```") and "```" in stripped[3:]:
            stripped = stripped.split("```", 1)[1].split("```", 1)[0].strip()
        if stripped:
            return json.loads(stripped)

    raise ValueError("Architect dispatch requires tool-call output from ArchitectOutput")


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

    build_architect_image_facts_bundle_payload()
    metadata_payload, facts_bundle = load_architect_materialized_inputs()
    structured_response = invoke_architect_aggregator(metadata_payload=metadata_payload, facts_bundle=facts_bundle)
    save_result = save_architect_design_payload(structured_response)
    final_message = json.dumps(structured_response, ensure_ascii=False, indent=2)
    return _command_from_result(
        {"messages": [], "structured_response": structured_response},
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
    final_message_override = None
    try:
        report_payload = load_tester_report_payload()
        final_message_override = json.dumps(report_payload, ensure_ascii=False, indent=2)
    except Exception:
        final_message_override = None
    return _command_from_result(result, runtime.tool_call_id, final_message_override=final_message_override)


ROUTING_TOOLS = [
    dispatch_architect,
    dispatch_coder,
    dispatch_tester,
]
