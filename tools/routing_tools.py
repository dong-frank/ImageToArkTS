from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Literal

from langchain.tools import ToolRuntime, tool
from langgraph.types import Command

from subagents import (
    get_architect_observation_extractor,
    get_coder_baseline_worker,
    get_coder_integration_worker,
)
from tools.architect_tools import batch_extract_page_drafts
from tools.coder_tools import (
    _coder_page_tasks_path,
    load_coder_integration_report_payload,
    save_coder_integration_report_payload,
)
from tools.project_tools import compile_project
from utils.session_context import reset_current_session_id, set_current_session_id

# ---------------------------------------------------------------------------
# Session / Workspace helpers
# ---------------------------------------------------------------------------

def _runtime_thread_id(runtime: ToolRuntime | None) -> str | None:
    config = getattr(runtime, "config", None)
    if not isinstance(config, dict):
        return None
    configurable = config.get("configurable")
    if not isinstance(configurable, dict):
        return None
    return configurable.get("thread_id")

def _excluded_state_keys() -> set:
    return {"messages", "todos", "structured_response", "skills_metadata", "memory_contents"}

def _build_subagent_state(description: str, runtime: ToolRuntime) -> dict:
    state = {k: v for k, v in runtime.state.items() if k not in _excluded_state_keys()}
    state["messages"] = [{"type": "human", "content": description}]
    return state

def _result_text(result: dict) -> str:
    if not result.get("messages"):
        return ""
    msg = result["messages"][-1]
    return getattr(msg, "text", "") or getattr(msg, "content", "") or ""

def _command_from_result(
    result: dict, tool_call_id: str, final_message_override: str | None = None
) -> Command:
    state_update = {k: v for k, v in result.items() if k not in _excluded_state_keys()}
    final_msg = final_message_override if final_message_override is not None else (_result_text(result) or "done")
    return Command(
        update={
            **state_update,
            "messages": [{"type": "tool", "content": final_msg, "tool_call_id": tool_call_id}],
        }
    )

def _invoke_subagent(agent, description: str, runtime: ToolRuntime) -> dict:
    thread_id = _runtime_thread_id(runtime)
    session_token = set_current_session_id(thread_id)
    try:
        return agent.invoke(
            _build_subagent_state(description, runtime),
            config=getattr(runtime, "config", None),
        )
    finally:
        reset_current_session_id(session_token)

# ---------------------------------------------------------------------------
# Architect Stage 1 (Baseline)
# ---------------------------------------------------------------------------

def _stage1_result_is_success(stage1_result: str) -> bool:
    return "status: SUCCESS" in str(stage1_result or "")


@tool
def dispatch_architect_stage1(runtime: ToolRuntime) -> Command:
    """Run only stage1 of Architect (observation draft extraction) for Baseline mode."""
    if not runtime.tool_call_id:
        raise ValueError("Tool call ID is required for architect stage1 dispatch")

    session_token = set_current_session_id(_runtime_thread_id(runtime))
    try:
        result = batch_extract_page_drafts()
        if not _stage1_result_is_success(result):
            return _command_from_result(
                {"messages": [], "structured_response": None},
                runtime.tool_call_id,
                final_message_override=f"Architect stage1 failed:\n{result}",
            )
        return _command_from_result(
            {"messages": [], "structured_response": {"status": "SUCCESS", "message": result}},
            runtime.tool_call_id,
            final_message_override=result,
        )
    finally:
        reset_current_session_id(session_token)

# ---------------------------------------------------------------------------
# Baseline Coder (end-to-end generation)
# ---------------------------------------------------------------------------

def _baseline_coder_prompt() -> str:
    return """
你是 `ImageToArkTS` 系统的 `BaselineCoder`（端到端生成基线）。

你的任务：
- 读取 `/designs/page_drafts_index.json` 和所有 `/designs/page_drafts/page_draft_{n}.json`。
- 自主分析所有 drafts，决定页面归并，设计导航关系。
- 直接生成完整的 HarmonyOS 项目：调用 create_project(project_name)，然后自行生成所有页面代码、main_pages.json、Index.ets、必要的导航组件等。
- 使用 router 进行跳转。
- 最终确保项目可编译（但不负责迭代修复，后续会有 Integration Worker）。

你有完全自主权。不要输出冗长中间日志，只输出最终总结。
"""


@tool
def dispatch_baseline_coder(runtime: ToolRuntime) -> Command:
    """Run BaselineCoder: end-to-end project generation from observation drafts."""
    if not runtime.tool_call_id:
        raise ValueError("Tool call ID required for baseline coder dispatch")

    session_token = set_current_session_id(_runtime_thread_id(runtime))
    try:
        result = _invoke_subagent(
            get_coder_baseline_worker(),
            _baseline_coder_prompt(),
            runtime,
        )
        return _command_from_result(
            result,
            runtime.tool_call_id,
            final_message_override=_result_text(result) or "BaselineCoder finished.",
        )
    finally:
        reset_current_session_id(session_token)

# ---------------------------------------------------------------------------
# Baseline Integration Worker (compile-fix loop)
# ---------------------------------------------------------------------------

def _baseline_integration_prompt(
    task_type: Literal["implementation", "fix_from_test"] = "implementation",
    round_idx: int = 1,
    prev_compile_feedback: str | None = None,
) -> str:
    prompt = f"task_type: {task_type}\nintegration_round: {round_idx}\n"
    prompt += "You are the Integration Worker for Baseline. Your goal: fix compilation errors, ensure routing is correct, respect layout safety rules.\n"
    prompt += "Use compile_project to get errors, then fix files directly. You may read any project file.\n"
    prompt += "Do not rewrite whole pages unless necessary for compilation. Only make minimal fixes.\n"
    prompt += "Return a short summary and a compile output block exactly as: <<FINAL_COMPILE_OUTPUT>> ... <<END_FINAL_COMPILE_OUTPUT>>\n"
    if prev_compile_feedback:
        prompt += f"\nPrevious compile output:\n<<PREVIOUS_COMPILE_OUTPUT>>\n{prev_compile_feedback}\n<<END_PREVIOUS_COMPILE_OUTPUT>>\n"
    return prompt


def _extract_final_compile_output(text: str) -> str:
    m = re.search(r"<<FINAL_COMPILE_OUTPUT>>\s*(.*?)\s*<<END_FINAL_COMPILE_OUTPUT>>", text, re.DOTALL)
    if m:
        return m.group(1).strip()
    return text.strip()


def _parse_compile_output(compile_output: str) -> dict:
    """Simplified parse of compile output lines."""
    status = "FAILED"
    project_name = ""
    project_path = ""
    key_errors = []
    in_errors = False
    for line in compile_output.splitlines():
        line = line.strip()
        if line.startswith("compile_status:"):
            status = line.split(":", 1)[1].strip()
        elif line.startswith("project_name:"):
            project_name = line.split(":", 1)[1].strip()
        elif line.startswith("project_path:"):
            project_path = line.split(":", 1)[1].strip()
        elif line == "key_errors:":
            in_errors = True
        elif line in ("recent_log_tail:", "") and in_errors:
            in_errors = False
        elif in_errors and line.startswith("- "):
            key_errors.append(line[2:])
    return {
        "compile_status": "SUCCESS" if status == "SUCCESS" else "FAILED",
        "project_name": project_name,
        "project_path": project_path,
        "key_errors": key_errors,
    }


def _strip_compile_output_block(text: str) -> str:
    return re.sub(r"<<FINAL_COMPILE_OUTPUT>>\s*.*?\s*<<END_FINAL_COMPILE_OUTPUT>>", "", text, flags=re.DOTALL).strip()


def _infer_integration_report_from_compile(compile_output: str, project_name: str) -> dict:
    parsed = _parse_compile_output(compile_output)
    success = parsed["compile_status"] == "SUCCESS"
    return {
        "compile_status": parsed["compile_status"],
        "project_name": parsed["project_name"] or project_name,
        "project_path": parsed["project_path"] or f"/projects/{project_name}",
        "ready_for_tester": success,
        "fixes_applied": [],
        "remaining_errors": parsed["key_errors"],
        "blocker": "none" if success else (parsed["key_errors"][0] if parsed["key_errors"] else "compile failed"),
        "next_recommended_agent": "tester" if success else "coder",
    }


def run_baseline_integration_loop(
    runtime: ToolRuntime,
    task_type: Literal["implementation", "fix_from_test"] = "implementation",
    max_rounds: int | None = None,
    stall_limit: int = 3,
) -> dict:
    """
    Run compile-fix loop for Baseline generated project.

    Args:
        runtime: ToolRuntime instance.
        task_type: "implementation" or "fix_from_test".
        max_rounds: Maximum number of rounds. If None, run indefinitely until success or stall.
        stall_limit: Number of consecutive identical error signatures to tolerate before giving up.
    """
    # Determine project name (fallback)
    project_name = "app_project"
    try:
        if _coder_page_tasks_path().exists():
            with open(_coder_page_tasks_path(), encoding="utf-8") as f:
                bundle = json.load(f)
                project_name = bundle.get("project_name", project_name)
    except Exception:
        pass

    round_idx = 0
    prev_fingerprint = None
    stall_count = 0
    compile_output = ""

    while True:
        round_idx += 1
        # 如果设置了硬上限且超过，则退出
        if max_rounds is not None and round_idx > max_rounds:
            break

        # 第一轮只编译获取错误，不调用 integration worker
        if round_idx == 1:
            compile_output = compile_project(project_name=project_name, runtime=runtime)
            parsed = _parse_compile_output(compile_output)
            if parsed["compile_status"] == "SUCCESS":
                break
            # 记录初始指纹
            fingerprint = json.dumps(parsed["key_errors"], sort_keys=True)
            prev_fingerprint = fingerprint
            continue

        # 后续轮次调用 integration worker 修复
        prompt = _baseline_integration_prompt(
            task_type=task_type,
            round_idx=round_idx,
            prev_compile_feedback=compile_output,
        )
        result = _invoke_subagent(
            get_coder_integration_worker(),
            prompt,
            runtime,
        )
        raw_summary = _result_text(result).strip()
        compile_output = _extract_final_compile_output(raw_summary)
        parsed = _parse_compile_output(compile_output)

        if parsed["compile_status"] == "SUCCESS":
            break

        # 停滞检测：比较错误指纹
        fingerprint = json.dumps(parsed["key_errors"], sort_keys=True)
        if fingerprint == prev_fingerprint:
            stall_count += 1
            if stall_count >= stall_limit:
                break
        else:
            stall_count = 0
            prev_fingerprint = fingerprint

    report = _infer_integration_report_from_compile(compile_output, project_name)
    save_coder_integration_report_payload(report)
    return report


@tool
def dispatch_baseline_integration(
    runtime: ToolRuntime,
    task_type: Literal["implementation", "fix_from_test"] = "implementation",
    max_rounds: int | None = None,
    stall_limit: int = 3,
) -> Command:
    """Run integration (compile-fix loop) for Baseline mode."""
    if not runtime.tool_call_id:
        raise ValueError("Tool call ID required for baseline integration dispatch")
    session_token = set_current_session_id(_runtime_thread_id(runtime))
    try:
        report = run_baseline_integration_loop(
            runtime,
            task_type=task_type,
            max_rounds=max_rounds,
            stall_limit=stall_limit,
        )
        return _command_from_result(
            {"messages": [], "structured_response": report},
            runtime.tool_call_id,
            final_message_override=json.dumps(report, ensure_ascii=False, indent=2),
        )
    finally:
        reset_current_session_id(session_token)

# ---------------------------------------------------------------------------
# Baseline Orchestrator's main routing tool
# ---------------------------------------------------------------------------

@tool
def dispatch_baseline_pipeline(
    runtime: ToolRuntime,
    max_rounds: int | None = None,
    stall_limit: int = 3,
) -> Command:
    """
    Baseline orchestrator: stage1 -> BaselineCoder -> Integration -> done.
    """
    if not runtime.tool_call_id:
        raise ValueError("Tool call ID required for baseline pipeline dispatch")

    session_token = set_current_session_id(_runtime_thread_id(runtime))
    try:
        # Step 1: Architect stage1 extraction
        stage1_result = batch_extract_page_drafts()
        if not _stage1_result_is_success(stage1_result):
            return _command_from_result(
                {"messages": [], "structured_response": None},
                runtime.tool_call_id,
                final_message_override=f"Architect stage1 failed:\n{stage1_result}",
            )

        # Step 2: BaselineCoder
        coder_result = _invoke_subagent(
            get_coder_baseline_worker(),
            _baseline_coder_prompt(),
            runtime,
        )
        coder_summary = _result_text(coder_result) or "BaselineCoder finished."

        # Step 3: Integration loop
        report = run_baseline_integration_loop(
            runtime,
            task_type="implementation",
            max_rounds=max_rounds,
            stall_limit=stall_limit,
        )

        return _command_from_result(
            {"messages": [], "structured_response": report},
            runtime.tool_call_id,
            final_message_override=json.dumps(report, ensure_ascii=False, indent=2),
        )
    finally:
        reset_current_session_id(session_token)

# ---------------------------------------------------------------------------
# List of tools to be exposed for baseline orchestrator

ROUTING_TOOLS = [
    dispatch_architect_stage1,
    dispatch_baseline_coder,
    dispatch_baseline_integration,
    dispatch_baseline_pipeline,
]