from __future__ import annotations

import concurrent.futures
import hashlib
import json
import re
from typing import Any, Literal

from langchain.tools import ToolRuntime, tool
from langchain_core.messages import HumanMessage, SystemMessage, ToolMessage
from langgraph.types import Command

from contracts.agent_contracts import (
    ARCHITECT_DISPATCH_CONTRACT,
    TESTER_DISPATCH_CONTRACT,
    build_coder_dispatch_contract,
)
from models import base_model
from schemas import (
    ArchitectOutput,
    CoderIntegrationReport,
    CoderPageTask,
    CoderPageTaskBundle,
    CoderPageWorkerResult,
    CoderPageWorkerResultBundle,
    CoderSkeletonOutput,
    TesterReportOutput,
)
from subagents import (
    build_coder_page_worker,
    get_architect_agent,
    get_coder_integration_worker,
    get_coder_orchestrator,
    get_coder_skeleton_worker,
    get_tester_agent,
)
from tools.architect_tools import build_architect_image_facts_bundle_payload
from tools.coder_tools import (
    append_coder_compile_fix_attempt,
    build_coder_compile_fix_attempt_payload,
    load_coder_integration_report_payload,
    load_coder_page_worker_results_payload,
    load_coder_page_task_bundle_payload,
    save_coder_compile_fix_trace_payload,
    save_coder_integration_report_payload,
    save_coder_page_worker_results_payload,
)
from tools.common import resolve_workspace_path
from utils.llm_utils import extract_tool_call_args, invoke_with_tool, normalize_tool_schema
from utils.session_context import reset_current_session_id, set_current_session_id
from utils.utils import load_prompt

_EXCLUDED_STATE_KEYS = {"messages", "todos", "structured_response", "skills_metadata", "memory_contents"}
_ARCHITECT_SYSTEM_PROMPT = load_prompt("architect_system_prompt.md")
_CODER_SKELETON_SYSTEM_PROMPT = load_prompt("coder_skeleton_system_prompt.md")
_CODER_PAGE_SYSTEM_PROMPT = load_prompt("coder_page_system_prompt.md")
_CODER_INTEGRATION_SYSTEM_PROMPT = load_prompt("coder_integration_system_prompt.md")


def build_architect_dispatch_description() -> str:
    return ARCHITECT_DISPATCH_CONTRACT.render()


def build_coder_dispatch_description(task_type: Literal["implementation", "fix_from_test"]) -> str:
    return build_coder_dispatch_contract(task_type=task_type).render()


def build_coder_integration_dispatch_description(task_type: Literal["implementation", "fix_from_test"]) -> str:
    return "\n".join(
        [
            f"task_type: {task_type}",
            "trigger: page_worker_results_ready",
            "inputs:",
            "- /designs/coder_page_tasks.json",
            "- /logs/coder/page_worker_results.json",
            "- /logs/tester/latest_tester_report.json (only for fix_from_test)",
            "required_outputs:",
            "- /logs/coder/integration_report.json",
            "done_criteria:",
            "- resolve imports, dependencies, interface mismatches, and naming inconsistencies",
            "- own the compile-fix loop inside integration: compile, fix when needed, and compile again",
            "- capture remaining blockers when compilation still fails",
            "- preserve UI fidelity and allow minimal or placeholder functionality when needed",
            "fallback:",
            "- if repeated compile errors do not change => need_human_guidance",
            "- if task mismatch => wrong_agent",
        ]
    )


def build_tester_dispatch_description() -> str:
    return TESTER_DISPATCH_CONTRACT.render()


def _build_subagent_state(description: str, runtime: ToolRuntime):
    subagent_state = {k: v for k, v in runtime.state.items() if k not in _EXCLUDED_STATE_KEYS}
    subagent_state["messages"] = [HumanMessage(content=description)]
    return subagent_state


def _runtime_thread_id(runtime: ToolRuntime | None) -> str | None:
    runtime_config = getattr(runtime, "config", None)
    if not isinstance(runtime_config, dict):
        return None
    configurable = runtime_config.get("configurable")
    if not isinstance(configurable, dict):
        return None
    return configurable.get("thread_id")


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
    thread_id = _runtime_thread_id(runtime)

    session_token = set_current_session_id(thread_id)
    try:
        return agent.invoke(
            _build_subagent_state(description, runtime),
            config=runtime_config,
        )
    finally:
        reset_current_session_id(session_token)


def build_architect_aggregation_prompt(metadata_payload: dict, facts_bundle: dict) -> str:
    return "\n".join(
        [
            build_architect_dispatch_description(),
            "",
            "Read the required input files yourself from the session workspace.",
            "Do not call filesystem write tools for the final design. Return only structured ArchitectOutput.",
            "",
            "Required input paths:",
            "- /user_input/user_input_metadata.json",
            "- /designs/architect_image_facts.json",
        ]
    )


def load_architect_materialized_inputs() -> tuple[dict, dict]:
    metadata_payload = json.loads(resolve_workspace_path("/user_input/user_input_metadata.json").read_text(encoding="utf-8"))
    facts_bundle = json.loads(resolve_workspace_path("/designs/architect_image_facts.json").read_text(encoding="utf-8"))
    return metadata_payload, facts_bundle


def load_architect_design_payload() -> dict:
    return json.loads(resolve_workspace_path("/designs/architect.json").read_text(encoding="utf-8"))


def load_tester_report_payload() -> dict:
    return json.loads(resolve_workspace_path("/logs/tester/latest_tester_report.json").read_text(encoding="utf-8"))


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


def build_coder_skeleton_planning_prompt(architect_payload: dict, task_type: Literal["implementation", "fix_from_test"]) -> str:
    skeleton_task_envelope = "\n".join(
        [
            f"task_type: {task_type}",
            "trigger: architect_design_ready",
            "inputs:",
            "- /designs/architect.json",
            "required_outputs:",
            "- /designs/coder_page_tasks.json",
            "done_criteria:",
            "- skeleton stage owns project bootstrap, page registration, and page-task planning",
            "- save /designs/coder_page_tasks.json before page implementation begins",
            "fallback:",
            "- if task mismatch => wrong_agent",
            "- if missing critical skeleton inputs => need_human_guidance",
        ]
    )
    return "\n".join(
        [
            skeleton_task_envelope,
            "",
            "You own the skeleton stage.",
            "You must both plan the skeleton and execute project bootstrap work that belongs to the skeleton stage.",
            "Use create_project when needed, and write /designs/coder_page_tasks.json yourself before returning.",
            "Do not claim the full app is complete.",
            "Unified navigation belongs to skeleton when the project has multiple pages.",
            "Page registration, startup page alignment, and avoiding stale template entry pages also belong to skeleton.",
            "",
            "Read required skills yourself before planning:",
            "- /skills/harmony-coding-guardrails/SKILL.md",
            "- /skills/harmony-next/SKILL.md",
            "",
            "Read required input file yourself:",
            "- /designs/architect.json",
        ]
    )


def _normalize_project_relative_path(project_name: str, raw_path: str) -> str:
    raw = str(raw_path or "").strip().replace("\\", "/")
    if not raw:
        return raw
    if raw.startswith("/projects/"):
        return raw
    if raw.startswith("/"):
        return f"/projects/{project_name}{raw}"
    return f"/projects/{project_name}/{raw.lstrip('/')}"


def _normalize_coder_skeleton_paths(payload: dict) -> dict:
    normalized = dict(payload)
    project_name = str(normalized.get("project_name") or "").strip()
    if not project_name:
        return normalized

    page_tasks = []
    for task in normalized.get("page_tasks", []) or []:
        item = dict(task)
        if item.get("page_file"):
            item["page_file"] = _normalize_project_relative_path(project_name, str(item["page_file"]))
        item["allowed_write_paths"] = [
            _normalize_project_relative_path(project_name, str(path))
            for path in (item.get("allowed_write_paths") or [])
        ]
        page_tasks.append(item)
    normalized["page_tasks"] = page_tasks
    return normalized


def _ensure_navigation_scaffold(payload: dict) -> dict:
    normalized = dict(payload)
    page_tasks = list(normalized.get("page_tasks") or [])
    if len(page_tasks) <= 1:
        return normalized

    normalized_tasks = []
    for task in page_tasks:
        item = dict(task)
        shared_dependencies = list(item.get("shared_dependencies") or [])
        for dependency in ("BottomNavBar", "NavigationService"):
            if dependency not in shared_dependencies:
                shared_dependencies.append(dependency)
        item["shared_dependencies"] = shared_dependencies
        normalized_tasks.append(item)
    normalized["page_tasks"] = normalized_tasks
    return normalized


def _normalize_coder_skeleton_tool_args(tool_args: dict) -> dict:
    normalized_tool_args = dict(tool_args)
    normalized_tool_args = _normalize_coder_skeleton_paths(normalized_tool_args)
    normalized_tool_args = _ensure_navigation_scaffold(normalized_tool_args)
    return normalized_tool_args


def invoke_coder_skeleton_planner(architect_payload: dict, task_type: Literal["implementation", "fix_from_test"]) -> dict:
    tool_name = "CoderSkeletonOutput"
    llm_response = invoke_with_tool(
        base_model,
        [
            SystemMessage(content=_CODER_SKELETON_SYSTEM_PROMPT),
            HumanMessage(content=build_coder_skeleton_planning_prompt(architect_payload=architect_payload, task_type=task_type)),
        ],
        tool_name,
        normalize_tool_schema(CoderSkeletonOutput.model_json_schema()),
    )
    tool_args = extract_tool_call_args(llm_response, tool_name)
    if tool_args is not None:
        return _normalize_coder_skeleton_tool_args(tool_args)
    raise ValueError("Coder skeleton stage requires tool-call output from CoderSkeletonOutput")


def _build_coder_skeleton_result_prompt(architect_payload: dict, task_type: Literal["implementation", "fix_from_test"], agent_summary: str) -> str:
    return "\n".join(
        [
            "Summarize the skeleton worker result into structured CoderSkeletonOutput.",
            "Use /designs/architect.json as the source of truth for pages and product structure.",
            "Preserve unified navigation scaffolding for multi-page projects.",
            "",
            f"task_type: {task_type}",
            "",
            "Read required input file yourself:",
            "- /designs/architect.json",
            "",
            "Skeleton worker summary:",
            agent_summary or "(empty)",
        ]
    )


def invoke_coder_skeleton_result_formatter(
    architect_payload: dict,
    task_type: Literal["implementation", "fix_from_test"],
    agent_summary: str,
) -> dict:
    tool_name = "CoderSkeletonOutput"
    llm_response = invoke_with_tool(
        base_model,
        [
            SystemMessage(content=_CODER_SKELETON_SYSTEM_PROMPT),
            HumanMessage(
                content=_build_coder_skeleton_result_prompt(
                    architect_payload=architect_payload,
                    task_type=task_type,
                    agent_summary=agent_summary,
                )
            ),
        ],
        tool_name,
        normalize_tool_schema(CoderSkeletonOutput.model_json_schema()),
    )
    tool_args = extract_tool_call_args(llm_response, tool_name)
    if tool_args is not None:
        return _normalize_coder_skeleton_tool_args(tool_args)
    raise ValueError("Coder skeleton stage requires tool-call output from CoderSkeletonOutput")


def run_coder_skeleton_stage(
    *,
    architect_payload: dict,
    task_type: Literal["implementation", "fix_from_test"],
    runtime: ToolRuntime,
) -> tuple[dict, str]:
    result = _invoke_subagent(
        get_coder_skeleton_worker(),
        build_coder_skeleton_planning_prompt(architect_payload=architect_payload, task_type=task_type),
        runtime,
    )
    agent_summary = _result_text(result)
    payload = invoke_coder_skeleton_result_formatter(
        architect_payload=architect_payload,
        task_type=task_type,
        agent_summary=agent_summary,
    )
    return payload, agent_summary


def _build_page_task_prompt(
    task_payload: dict,
    architect_page_payload: dict,
    skeleton_payload: dict,
    task_type: Literal["implementation", "fix_from_test"],
    tester_report_payload: dict | None = None,
) -> str:
    execution_priority = {
        "primary_goal": "Reconstruct the UI as faithfully as possible.",
        "secondary_goal": "Implement only minimal functionality needed to support the visible UI.",
        "allowed_tradeoffs": [
            "Use placeholder handlers when full business logic is complex.",
            "Use static mock data when real data flow would block UI delivery.",
            "Prefer visually correct sections over deep functional completeness.",
        ],
    }
    sections = [
        build_coder_dispatch_description(task_type=task_type),
        "",
        "You are executing one page implementation task only.",
        f"target_page_name: {str(task_payload.get('page_name') or '')}",
        "Skill usage is mandatory before code generation for ArkTS / ArkUI details.",
        "Respect allowed_write_paths and page-local component boundaries.",
        "Do not compile the whole project and do not edit shared skeleton files directly.",
        "Read the relevant task and design files yourself before coding.",
        "",
        "Execution priority:",
        json.dumps(execution_priority, ensure_ascii=False, indent=2),
        "",
        "Read required skills yourself before coding:",
        "- /skills/harmony-coding-guardrails/SKILL.md",
        "- /skills/harmony-next/SKILL.md",
        "",
        "Required input paths:",
        "- /designs/coder_page_tasks.json",
        "- /designs/architect.json",
    ]
    if tester_report_payload is not None:
        sections.extend(
            [
                "",
                "Optional input path:",
                "- /logs/tester/latest_tester_report.json",
            ]
        )
    return "\n".join(sections)


def _build_integration_prompt(
    task_type: Literal["implementation", "fix_from_test"],
    skeleton_payload: dict,
    page_results_payload: dict,
    tester_report_payload: dict | None = None,
) -> str:
    execution_priority = {
        "primary_goal": "Preserve and stabilize UI fidelity first.",
        "secondary_goal": "Keep functionality at a minimal compile-safe level when necessary.",
        "allowed_tradeoffs": [
            "Do not rewrite visually accurate pages just to chase nonessential behavior.",
            "Prefer compile-safe placeholders over risky feature-heavy rewrites.",
            "Protect layout, styling, and visible section structure unless a change is required to compile.",
        ],
    }
    sections = [
        build_coder_integration_dispatch_description(task_type=task_type),
        "",
        "You are executing the integration stage only.",
        "Skill usage is mandatory before fixing ArkTS / ArkUI engineering issues.",
        "Resolve shared contract mismatches, import/export issues, route registration gaps, and naming inconsistencies.",
        "You own the compile-fix loop in this stage.",
        "Run compile_project yourself first. If compile fails, fix the issue and compile again until success or until the main error stops changing.",
        "Your final response must include a short human summary and a final compile output block wrapped exactly with <<FINAL_COMPILE_OUTPUT>> and <<END_FINAL_COMPILE_OUTPUT>>.",
        "",
        "Execution priority:",
        json.dumps(execution_priority, ensure_ascii=False, indent=2),
        "",
        "Read required skills yourself before fixing:",
        "- /skills/harmony-coding-guardrails/SKILL.md",
        "- /skills/harmony-next/SKILL.md",
        "",
        "Required input paths:",
        "- /designs/coder_page_tasks.json",
        "- /logs/coder/page_worker_results.json",
    ]
    if tester_report_payload is not None:
        sections.extend(
            [
                "",
                "Optional input path:",
                "- /logs/tester/latest_tester_report.json",
            ]
        )
    return "\n".join(sections)


def _build_page_result_prompt(task_payload: dict, modified_files: list[str], agent_summary: str) -> str:
    return "\n".join(
        [
            "Summarize the page worker result into structured CoderPageWorkerResult.",
            "Use the task payload for page_name and intended boundaries.",
            "Use modified_files as the canonical modified file list.",
            "Keep the result minimal: focus on completion status, modified files, blockers, and a short summary.",
            "",
            "Task payload:",
            json.dumps(task_payload, ensure_ascii=False, indent=2),
            "",
            "Modified files:",
            json.dumps(modified_files, ensure_ascii=False, indent=2),
            "",
            "Worker summary:",
            agent_summary or "(empty)",
        ]
    )


def invoke_coder_page_result_formatter(task_payload: dict, modified_files: list[str], agent_summary: str) -> dict:
    tool_name = "CoderPageWorkerResult"
    llm_response = invoke_with_tool(
        base_model,
        [
            SystemMessage(content=_CODER_PAGE_SYSTEM_PROMPT),
            HumanMessage(content=_build_page_result_prompt(task_payload, modified_files, agent_summary)),
        ],
        tool_name,
        normalize_tool_schema(CoderPageWorkerResult.model_json_schema()),
    )
    tool_args = extract_tool_call_args(llm_response, tool_name)
    if tool_args is not None:
        return tool_args
    raise ValueError("Coder page worker result requires tool-call output from CoderPageWorkerResult")


def _build_integration_report_prompt(
    project_name: str,
    compile_output: str,
    worker_summaries: list[str],
) -> str:
    return "\n".join(
        [
            "Summarize the integration stage into structured CoderIntegrationReport.",
            "Use compile_output as the source of truth for compile status.",
            f"project_name: {project_name}",
            "",
            "Worker summaries:",
            json.dumps(worker_summaries, ensure_ascii=False, indent=2),
            "",
            "Compile output:",
            compile_output,
        ]
    )


def invoke_coder_integration_report_formatter(project_name: str, compile_output: str, worker_summaries: list[str]) -> dict:
    tool_name = "CoderIntegrationReport"
    llm_response = invoke_with_tool(
        base_model,
        [
            SystemMessage(content=_CODER_INTEGRATION_SYSTEM_PROMPT),
            HumanMessage(content=_build_integration_report_prompt(project_name, compile_output, worker_summaries)),
        ],
        tool_name,
        normalize_tool_schema(CoderIntegrationReport.model_json_schema()),
    )
    tool_args = extract_tool_call_args(llm_response, tool_name)
    if tool_args is not None:
        return tool_args
    parsed = _parse_compile_output(compile_output)
    return {
        "compile_status": parsed["compile_status"],
        "project_name": parsed["project_name"] or project_name,
        "project_path": parsed["project_path"] or f"/projects/{project_name}",
        "ready_for_tester": parsed["compile_status"] == "SUCCESS",
        "fixes_applied": [summary for summary in worker_summaries if summary],
        "remaining_errors": parsed["key_errors"],
        "blocker": "none" if parsed["compile_status"] == "SUCCESS" else (parsed["key_errors"][0] if parsed["key_errors"] else "compile failed"),
        "next_recommended_agent": "tester" if parsed["compile_status"] == "SUCCESS" else "human",
    }


def _page_slice_for_task(architect_payload: dict, page_name: str) -> dict:
    for page in architect_payload.get("pages", []) or []:
        if str(page.get("name") or "") == page_name:
            return page
    return {"name": page_name}


def _hash_file(path: str) -> str | None:
    target = resolve_workspace_path(path)
    if not target.exists() or not target.is_file():
        return None
    return hashlib.sha256(target.read_bytes()).hexdigest()


def _snapshot_allowed_paths(paths: list[str]) -> dict[str, str | None]:
    return {path: _hash_file(path) for path in paths}


def _detect_modified_files(paths: list[str], before: dict[str, str | None]) -> list[str]:
    modified: list[str] = []
    for path in paths:
        after = _hash_file(path)
        if before.get(path) != after and after is not None:
            modified.append(path)
    return modified


def _result_text(result: dict) -> str:
    if not result.get("messages"):
        return ""
    message = result["messages"][-1]
    return getattr(message, "text", "") or getattr(message, "content", "") or ""


def _extract_final_compile_output(agent_summary: str) -> str:
    text = str(agent_summary or "")
    match = re.search(
        r"<<FINAL_COMPILE_OUTPUT>>\s*(.*?)\s*<<END_FINAL_COMPILE_OUTPUT>>",
        text,
        re.DOTALL,
    )
    if not match:
        raise ValueError("Integration worker summary missing final compile output block")
    return match.group(1).strip()


def _strip_compile_output_block(agent_summary: str) -> str:
    text = str(agent_summary or "")
    stripped = re.sub(
        r"<<FINAL_COMPILE_OUTPUT>>\s*.*?\s*<<END_FINAL_COMPILE_OUTPUT>>",
        "",
        text,
        flags=re.DOTALL,
    ).strip()
    return stripped


def _select_page_tasks(task_bundle: dict, tester_report_payload: dict | None = None) -> list[dict]:
    tasks = list(task_bundle.get("tasks") or task_bundle.get("page_tasks") or [])
    if not tester_report_payload:
        return tasks
    haystack = json.dumps(tester_report_payload, ensure_ascii=False)
    selected = [task for task in tasks if str(task.get("page_name") or "") in haystack]
    return selected or tasks


def _run_single_page_worker(
    task_payload: dict,
    skeleton_payload: dict,
    architect_payload: dict,
    runtime: ToolRuntime,
    task_type: Literal["implementation", "fix_from_test"],
    tester_report_payload: dict | None = None,
) -> dict:
    before = _snapshot_allowed_paths(list(task_payload.get("allowed_write_paths") or []))
    result = _invoke_subagent(
        build_coder_page_worker(),
        _build_page_task_prompt(
            task_payload=task_payload,
            architect_page_payload=_page_slice_for_task(architect_payload, str(task_payload.get("page_name") or "")),
            skeleton_payload=skeleton_payload,
            task_type=task_type,
            tester_report_payload=tester_report_payload,
        ),
        runtime,
    )
    modified_files = _detect_modified_files(list(task_payload.get("allowed_write_paths") or []), before)
    structured = invoke_coder_page_result_formatter(
        task_payload=task_payload,
        modified_files=modified_files,
        agent_summary=_result_text(result),
    )
    return structured


def dispatch_page_coders(
    *,
    task_type: Literal["implementation", "fix_from_test"],
    skeleton_payload: dict,
    task_bundle: dict,
    architect_payload: dict,
    runtime: ToolRuntime,
    tester_report_payload: dict | None = None,
) -> dict:
    selected_tasks = _select_page_tasks(task_bundle, tester_report_payload=tester_report_payload)
    results: list[dict] = []
    if not selected_tasks:
        bundle = {"project_name": skeleton_payload["project_name"], "results": results}
        save_coder_page_worker_results_payload(bundle)
        return bundle

    max_workers = min(4, max(1, len(selected_tasks)))
    with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = [
            executor.submit(
                _run_single_page_worker,
                task_payload=task,
                skeleton_payload=skeleton_payload,
                architect_payload=architect_payload,
                runtime=runtime,
                task_type=task_type,
                tester_report_payload=tester_report_payload,
            )
            for task in selected_tasks
        ]
        for future, task in zip(futures, selected_tasks):
            try:
                results.append(future.result())
            except Exception as exc:  # noqa: BLE001
                results.append(
                    {
                        "status": "blocked",
                        "page_name": str(task.get("page_name") or ""),
                        "modified_files": [],
                        "exports_added": [],
                        "shared_contract_requests": [],
                        "blockers": [str(exc)],
                        "summary": "page worker failed before returning a structured result",
                    }
                )

    bundle = {"project_name": skeleton_payload["project_name"], "results": results}
    save_coder_page_worker_results_payload(bundle)
    return bundle


def _compile_status_signature(compile_output: str) -> str:
    failed_step = re.search(r"^failed_step:\s*(.+)$", compile_output, re.MULTILINE)
    if failed_step:
        return failed_step.group(1).strip()
    error_line = re.search(r"^- (.+)$", compile_output, re.MULTILINE)
    if error_line:
        return error_line.group(1).strip()
    return compile_output.strip().splitlines()[0] if compile_output.strip() else "unknown"


def _parse_compile_output(compile_output: str) -> dict[str, Any]:
    compile_status = "FAILED"
    project_name = ""
    project_path = ""
    key_errors: list[str] = []
    in_errors = False

    for raw_line in str(compile_output or "").splitlines():
        line = raw_line.strip()
        if line.startswith("compile_status:"):
            compile_status = line.split(":", 1)[1].strip()
        elif line.startswith("project_name:"):
            project_name = line.split(":", 1)[1].strip()
        elif line.startswith("project_path:"):
            project_path = line.split(":", 1)[1].strip()
        elif line == "key_errors:":
            in_errors = True
        elif line == "recent_log_tail:":
            in_errors = False
        elif in_errors and line.startswith("- "):
            key_errors.append(line[2:])

    return {
        "compile_status": "SUCCESS" if compile_status == "SUCCESS" else "FAILED",
        "project_name": project_name,
        "project_path": project_path,
        "key_errors": key_errors[:12],
    }


def run_coder_integration(
    *,
    task_type: Literal["implementation", "fix_from_test"],
    skeleton_payload: dict,
    page_results_payload: dict,
    runtime: ToolRuntime,
    tester_report_payload: dict | None = None,
) -> dict:
    worker_summaries: list[str] = []
    modified_files = sorted(
        {
            path
            for result in list(page_results_payload.get("results") or [])
            for path in list(result.get("modified_files") or [])
        }
    )
    result = _invoke_subagent(
        get_coder_integration_worker(),
        _build_integration_prompt(
            task_type=task_type,
            skeleton_payload=skeleton_payload,
            page_results_payload=page_results_payload,
            tester_report_payload=tester_report_payload,
        ),
        runtime,
    )
    raw_summary = _result_text(result).strip()
    if raw_summary:
        worker_summaries.append(_strip_compile_output_block(raw_summary))
    compile_feedback = _extract_final_compile_output(raw_summary)
    parsed_compile = _parse_compile_output(compile_feedback)
    signature = _compile_status_signature(compile_feedback)
    attempt_records: list[dict[str, Any]] = [
        build_coder_compile_fix_attempt_payload(
            attempt_index=1,
            task_type=task_type,
            project_name=skeleton_payload["project_name"],
            compile_status=parsed_compile["compile_status"],
            error_signature=signature,
            key_errors=parsed_compile["key_errors"],
            worker_summary=_strip_compile_output_block(raw_summary) or "integration worker executed compile-fix loop",
            worker_summaries_so_far=[summary for summary in worker_summaries if summary],
            modified_files=modified_files,
            fixes_applied=[summary for summary in worker_summaries if summary],
            skills_referenced=["/skills/harmony-next/SKILL.md"],
        )
    ]

    report = invoke_coder_integration_report_formatter(
        project_name=skeleton_payload["project_name"],
        compile_output=compile_feedback or "",
        worker_summaries=worker_summaries,
    )
    final_success = report["compile_status"] == "SUCCESS"
    for index, attempt in enumerate(attempt_records):
        updated_attempt = dict(attempt)
        updated_attempt["final_success"] = final_success
        if index + 1 < len(attempt_records):
            next_attempt = attempt_records[index + 1]
            updated_attempt["resolved_in_next_attempt"] = next_attempt.get("compile_status") == "SUCCESS" or (
                next_attempt.get("error_signature") != attempt.get("error_signature")
            )
        else:
            updated_attempt["resolved_in_next_attempt"] = None
        append_coder_compile_fix_attempt(updated_attempt)
        attempt_records[index] = updated_attempt

    save_coder_compile_fix_trace_payload(
        {
            "project_name": skeleton_payload["project_name"],
            "task_type": task_type,
            "attempts": attempt_records,
            "final_compile_status": report["compile_status"],
            "final_success": final_success,
        }
    )
    save_coder_integration_report_payload(report)
    return report


def run_coder_pipeline(
    *,
    task_type: Literal["implementation", "fix_from_test"],
    runtime: ToolRuntime,
) -> dict:
    architect_payload = load_architect_design_payload()
    tester_report_payload = load_tester_report_payload() if task_type == "fix_from_test" else None

    try:
        task_bundle = load_coder_page_task_bundle_payload()
    except Exception:  # noqa: BLE001
        task_bundle = None

    if task_bundle is None:
        skeleton_payload, _ = run_coder_skeleton_stage(
            architect_payload=architect_payload,
            task_type=task_type,
            runtime=runtime,
        )
        task_bundle = {
            "project_name": skeleton_payload["project_name"],
            "tasks": skeleton_payload.get("page_tasks", []),
        }
    else:
        skeleton_payload = task_bundle

    page_results_payload = dispatch_page_coders(
        task_type=task_type,
        skeleton_payload=skeleton_payload,
        task_bundle=task_bundle,
        architect_payload=architect_payload,
        runtime=runtime,
        tester_report_payload=tester_report_payload,
    )
    integration_report = run_coder_integration(
        task_type=task_type,
        skeleton_payload=skeleton_payload,
        page_results_payload=page_results_payload,
        runtime=runtime,
        tester_report_payload=tester_report_payload,
    )
    return integration_report


@tool
def dispatch_coder_skeleton(
    task_type: Literal["implementation", "fix_from_test"] = "implementation",
    runtime: ToolRuntime = None,
) -> Command:
    """
    Run the coder skeleton stage and let the skeleton worker own project bootstrap work.
    """
    if runtime is None or not runtime.tool_call_id:
        raise ValueError("Tool call ID is required for coder skeleton dispatch")

    session_token = set_current_session_id(_runtime_thread_id(runtime))
    try:
        architect_payload = load_architect_design_payload()
        skeleton_payload, worker_summary = run_coder_skeleton_stage(
            architect_payload=architect_payload,
            task_type=task_type,
            runtime=runtime,
        )
        final_message = json.dumps(
            {
                "project_name": skeleton_payload["project_name"],
                "skeleton_plan_saved": False,
                "worker_execution_summary": worker_summary,
            },
            ensure_ascii=False,
            indent=2,
        )
        return _command_from_result(
            {"messages": [], "structured_response": skeleton_payload},
            runtime.tool_call_id,
            final_message_override=final_message,
        )
    finally:
        reset_current_session_id(session_token)


@tool
def dispatch_page_coder_tasks(
    task_type: Literal["implementation", "fix_from_test"] = "implementation",
    runtime: ToolRuntime = None,
) -> Command:
    """
    Run page worker tasks from the materialized skeleton artifacts.
    """
    if runtime is None or not runtime.tool_call_id:
        raise ValueError("Tool call ID is required for page coder dispatch")

    session_token = set_current_session_id(_runtime_thread_id(runtime))
    try:
        task_bundle = load_coder_page_task_bundle_payload()
        architect_payload = load_architect_design_payload()
        tester_report_payload = load_tester_report_payload() if task_type == "fix_from_test" else None
        page_results_payload = dispatch_page_coders(
            task_type=task_type,
            skeleton_payload=task_bundle,
            task_bundle=task_bundle,
            architect_payload=architect_payload,
            runtime=runtime,
            tester_report_payload=tester_report_payload,
        )
        final_message = json.dumps(page_results_payload, ensure_ascii=False, indent=2)
        return _command_from_result(
            {"messages": [], "structured_response": page_results_payload},
            runtime.tool_call_id,
            final_message_override=final_message,
        )
    finally:
        reset_current_session_id(session_token)


@tool
def dispatch_coder_integration(
    task_type: Literal["implementation", "fix_from_test"] = "implementation",
    runtime: ToolRuntime = None,
) -> Command:
    """
    Run the integration stage and persist the final integration report.
    """
    if runtime is None or not runtime.tool_call_id:
        raise ValueError("Tool call ID is required for coder integration dispatch")

    session_token = set_current_session_id(_runtime_thread_id(runtime))
    try:
        skeleton_payload = load_coder_page_task_bundle_payload()
        page_results_payload = load_coder_page_worker_results_payload()
        tester_report_payload = load_tester_report_payload() if task_type == "fix_from_test" else None
        integration_report = run_coder_integration(
            task_type=task_type,
            skeleton_payload=skeleton_payload,
            page_results_payload=page_results_payload,
            runtime=runtime,
            tester_report_payload=tester_report_payload,
        )
        final_message = json.dumps(integration_report, ensure_ascii=False, indent=2)
        return _command_from_result(
            {"messages": [], "structured_response": integration_report},
            runtime.tool_call_id,
            final_message_override=final_message,
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
    session_token = set_current_session_id(_runtime_thread_id(runtime))
    try:
        build_architect_image_facts_bundle_payload()
        result = _invoke_subagent(get_architect_agent(), build_architect_dispatch_description(), runtime)
        architect_output = _result_text(result)
        final_message = architect_output or ""
        return _command_from_result(
            {"messages": [], "structured_response": architect_output},
            runtime.tool_call_id,
            final_message_override=final_message,
        )
    finally:
        reset_current_session_id(session_token)


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
    result = _invoke_subagent(get_coder_orchestrator(), description, runtime)
    final_message_override = None
    try:
        integration_report = load_coder_integration_report_payload()
        final_message_override = json.dumps(integration_report, ensure_ascii=False, indent=2)
    except Exception:
        final_message_override = None
    return _command_from_result(result, runtime.tool_call_id, final_message_override=final_message_override)


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


CODER_ORCHESTRATOR_TOOLS = [
    dispatch_coder_skeleton,
    dispatch_page_coder_tasks,
    dispatch_coder_integration,
]

ROUTING_TOOLS = [
    dispatch_architect,
    dispatch_coder,
    dispatch_tester,
]
