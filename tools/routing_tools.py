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
    clear_subagent_caches,
)
from tools.architect_tools import batch_extract_page_drafts
from tools.coder_tools import (
    _coder_page_tasks_path,
    append_coder_compile_fix_attempt,
    build_coder_compile_fix_attempt_payload,
    load_coder_integration_report_payload,
    save_coder_compile_fix_trace_payload,
    save_coder_integration_report_payload,
)
from utils.session_context import reset_current_session_id, set_current_session_id

# ---------------------------------------------------------------------------
# Session / Workspace helpers (copied from routing_tools.py)
# ---------------------------------------------------------------------------

def _runtime_thread_id(runtime: ToolRuntime | None) -> str | None:
    config = getattr(runtime, "config", None)
    if not isinstance(config, dict):
        return None
    configurable = config.get("configurable")
    if not isinstance(configurable, dict):
        return None
    return configurable.get("thread_id")

_EXCLUDED_STATE_KEYS = {"messages", "todos", "structured_response", "skills_metadata", "memory_contents"}

def _build_subagent_state(description: str, runtime: ToolRuntime) -> dict:
    state = {k: v for k, v in runtime.state.items() if k not in _EXCLUDED_STATE_KEYS}
    state["messages"] = [{"type": "human", "content": description}]
    return state

def _result_text(result: dict) -> str:
    if not result.get("messages"):
        return ""
    msg = result["messages"][-1]
    return getattr(msg, "text", "") or getattr(msg, "content", "") or ""

def _command_from_result(result: dict, tool_call_id: str, final_message_override: str | None = None) -> Command:
    state_update = {k: v for k, v in result.items() if k not in _EXCLUDED_STATE_KEYS}
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
# Architect Stage 1
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
# Baseline Coder
# ---------------------------------------------------------------------------

def _baseline_coder_prompt() -> str:
    return """
你是 `ImageToArkTS` 系统的 `BaselineCoder`（端到端生成基线）。

你的任务：
- 读取 `/designs/page_drafts_index.json` 和所有 `/designs/page_drafts/page_draft_{n}.json`。
- 自主分析所有 drafts，决定页面归并，设计导航关系。
- 将 `observation_status` 为 `success` 或 `repaired` 的 draft 视为可用输入；`repaired` 表示 Architect 已从 fallback/raw observation 中恢复出可用结构。
- 对仍为 `partial` 的 draft 要谨慎：只有在顶层结构或 `raw_preservation.raw_observation` 中有明确页面语义时才作为补充参考，否则不要让残缺内容污染页面生成。
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
        # Ensure subagent singletons are rebuilt so they use the correct models/tools
        clear_subagent_caches()
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
# Integration helpers (copied from full system routing_tools.py)
# ---------------------------------------------------------------------------

def _classify_compile_error_line(line: str) -> tuple[str, str]:
    text = str(line or "").strip()
    lowered = text.lower()

    file_match = re.search(r"(/projects/[^\s:]+|entry/src/[^\s:]+\.ets|[A-Za-z0-9_./-]+\.ets)", text)
    file_key = file_match.group(1) if file_match else "unknown_file"

    if any(token in lowered for token in ("cannot find module", "module not found", "import")):
        return "import_resolution_error", file_key
    if any(token in lowered for token in ("export", "not exported")):
        return "export_visibility_error", file_key
    if any(token in lowered for token in ("cannot find name", "unresolved", "symbol")):
        return "symbol_not_found_error", file_key
    if any(token in lowered for token in ("type", "assignable", "incompatible")):
        return "type_mismatch_error", file_key
    if any(token in lowered for token in ("@component", "@entry", "@builder", "decorator")):
        return "decorator_usage_error", file_key
    if any(token in lowered for token in ("resource", "media", "$r(", "string.json")):
        return "resource_reference_error", file_key
    if any(token in lowered for token in ("route", "entry", "pages.json", "module.json", "main_pages.json")):
        return "route_or_entry_config_error", file_key
    return "unknown_error", file_key

def _build_compile_fingerprint(compile_output: str) -> dict[str, list]:
    parsed = _parse_compile_output(compile_output)
    key_errors = list(parsed.get("key_errors") or [])

    normalized_error_groups = []
    primary_blockers = []

    for line in key_errors:
        error_type, file_key = _classify_compile_error_line(line)
        if error_type not in normalized_error_groups:
            normalized_error_groups.append(error_type)
        blocker = {"file": file_key, "type": error_type}
        if blocker not in primary_blockers:
            primary_blockers.append(blocker)

    return {
        "normalized_error_groups": normalized_error_groups,
        "primary_blockers": primary_blockers[:8],
    }

def _parse_compile_output(compile_output: str) -> dict:
    if not compile_output or not compile_output.strip():
        return {
            "compile_status": "FAILED",
            "project_name": "",
            "project_path": "",
            "key_errors": ["compile output was empty"],
        }

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
        "key_errors": key_errors[:12],
    }

def _extract_final_compile_output(text: str) -> str:
    m = re.search(r"<<FINAL_COMPILE_OUTPUT>>\s*(.*?)\s*<<END_FINAL_COMPILE_OUTPUT>>", text, re.DOTALL)
    if m:
        return m.group(1).strip()
    if "compile_status:" in text:
        return text.strip()
    return "compile_status: FAILED\nkey_errors:\n- integration worker did not return a compile output block\n"

def _strip_compile_output_block(text: str) -> str:
    return re.sub(r"<<FINAL_COMPILE_OUTPUT>>.*?<<END_FINAL_COMPILE_OUTPUT>>", "", text, flags=re.DOTALL).strip()

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

def _compile_fingerprint_stalled(prev: dict | None, curr: dict | None) -> bool:
    if not prev or not curr:
        return False
    prev_groups = sorted(set(prev.get("normalized_error_groups") or []))
    curr_groups = sorted(set(curr.get("normalized_error_groups") or []))
    prev_blockers = sorted({(b.get("file",""), b.get("type","")) for b in (prev.get("primary_blockers") or [])})
    curr_blockers = sorted({(b.get("file",""), b.get("type","")) for b in (curr.get("primary_blockers") or [])})
    return prev_groups == curr_groups and prev_blockers == curr_blockers

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

def _get_project_name_from_tasks() -> str:
    try:
        if _coder_page_tasks_path().exists():
            with open(_coder_page_tasks_path(), encoding="utf-8") as f:
                bundle = json.load(f)
                return bundle.get("project_name", "app_project")
    except Exception:
        pass
    return "app_project"

# ---------------------------------------------------------------------------
# Baseline integration loop (parallel to run_coder_integration)
# ---------------------------------------------------------------------------

def run_baseline_integration(
    runtime: ToolRuntime,
    task_type: Literal["implementation", "fix_from_test"] = "implementation",
    max_rounds: int | None = None,
    stall_limit: int = 3,
) -> dict:
    project_name = _get_project_name_from_tasks()
    worker_summaries = []
    attempt_records = []
    prev_fingerprint = None
    stall_count = 0
    last_compile_output = ""
    parsed_compile = {"compile_status": "FAILED", "project_name": "", "project_path": "", "key_errors": []}
    round_idx = 0

    while True:
        round_idx += 1
        if max_rounds is not None and round_idx > max_rounds:
            break

        prompt = _baseline_integration_prompt(
            task_type=task_type,
            round_idx=round_idx,
            prev_compile_feedback=last_compile_output if round_idx > 1 else None,
        )
        result = _invoke_subagent(get_coder_integration_worker(), prompt, runtime)
        raw_summary = _result_text(result).strip()
        if raw_summary:
            worker_summaries.append(_strip_compile_output_block(raw_summary))

        compile_output = _extract_final_compile_output(raw_summary)
        parsed_compile = _parse_compile_output(compile_output)
        fingerprint = _build_compile_fingerprint(compile_output)

        attempt = build_coder_compile_fix_attempt_payload(
            attempt_index=round_idx,
            task_type=task_type,
            project_name=project_name,
            compile_status=parsed_compile["compile_status"],
            error_signature=json.dumps(fingerprint, ensure_ascii=False, sort_keys=True),
            key_errors=parsed_compile["key_errors"],
            worker_summary=_strip_compile_output_block(raw_summary) or "integration worker executed",
            worker_summaries_so_far=[s for s in worker_summaries if s],
            modified_files=[],
            fixes_applied=[],
            skills_referenced=["/skills/arkts-syntax-assistant/SKILL.md", "/skills/harmony-next/SKILL.md"],
        )
        append_coder_compile_fix_attempt(attempt)
        attempt_records.append(attempt)

        if parsed_compile["compile_status"] == "SUCCESS":
            last_compile_output = compile_output
            project_name = parsed_compile["project_name"] or project_name
            break

        if _compile_fingerprint_stalled(prev_fingerprint, fingerprint):
            stall_count += 1
            if stall_count >= stall_limit:
                break
        else:
            stall_count = 0
        prev_fingerprint = fingerprint

        last_compile_output = compile_output
        project_name = parsed_compile["project_name"] or project_name

    save_coder_compile_fix_trace_payload({
        "project_name": project_name,
        "task_type": task_type,
        "attempts": attempt_records,
        "final_compile_status": parsed_compile["compile_status"],
        "final_success": parsed_compile["compile_status"] == "SUCCESS",
    })

    report = _infer_integration_report_from_compile(last_compile_output or "", project_name)
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
        report = run_baseline_integration(runtime, task_type, max_rounds, stall_limit)
        return _command_from_result(
            {"messages": [], "structured_response": report},
            runtime.tool_call_id,
            final_message_override=json.dumps(report, ensure_ascii=False, indent=2),
        )
    finally:
        reset_current_session_id(session_token)

# ---------------------------------------------------------------------------
# Baseline Pipeline (stage1 -> coder -> integration)
# ---------------------------------------------------------------------------

@tool
def dispatch_baseline_pipeline(
    runtime: ToolRuntime,
    max_rounds: int | None = None,
    stall_limit: int = 3,
) -> Command:
    """Baseline orchestrator: stage1 -> BaselineCoder -> Integration -> done."""
    if not runtime.tool_call_id:
        raise ValueError("Tool call ID required for baseline pipeline dispatch")

    session_token = set_current_session_id(_runtime_thread_id(runtime))
    try:
        # Stage1
        stage1_result = batch_extract_page_drafts()
        if not _stage1_result_is_success(stage1_result):
            return _command_from_result(
                {"messages": [], "structured_response": None},
                runtime.tool_call_id,
                final_message_override=f"Architect stage1 failed:\n{stage1_result}",
            )

        # BaselineCoder
        # Clear cached subagents so any agents bound to earlier model configs
        # (for example a vision-capable architect_agent) are rebuilt fresh
        # before starting the coder worker.
        clear_subagent_caches()
        coder_result = _invoke_subagent(
            get_coder_baseline_worker(),
            _baseline_coder_prompt(),
            runtime,
        )
        # 可选：记录 coder 输出，但未使用

        # Integration
        report = run_baseline_integration(runtime, "implementation", max_rounds, stall_limit)

        return _command_from_result(
            {"messages": [], "structured_response": report},
            runtime.tool_call_id,
            final_message_override=json.dumps(report, ensure_ascii=False, indent=2),
        )
    finally:
        reset_current_session_id(session_token)

# ---------------------------------------------------------------------------
# Exported tool list
# ---------------------------------------------------------------------------

ROUTING_TOOLS = [
    dispatch_architect_stage1,
    dispatch_baseline_coder,
    dispatch_baseline_integration,
    dispatch_baseline_pipeline,
]
