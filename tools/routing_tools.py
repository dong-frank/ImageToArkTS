from __future__ import annotations

import concurrent.futures
import hashlib
import json
import re
from pathlib import Path
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
    CoderIntegrationReport,
    CoderPageWorkerResult,
    CoderSkeletonOutput,
)
from subagents import (
    build_coder_page_worker,
    get_architect_navigation_planner,
    get_architect_page_merger,
    get_coder_integration_worker,
    get_coder_orchestrator,
    get_coder_skeleton_worker,
    get_tester_agent,
)
from tools.architect_tools import (
    batch_extract_page_drafts,
    check_stage1_artifacts,
    check_stage2_artifacts,
    check_stage3_artifacts,
    inspect_architect_artifacts,
)
from tools.coder_tools import (
    _coder_page_tasks_path,
    append_coder_compile_fix_attempt,
    build_coder_compile_fix_attempt_payload,
    build_coder_skeleton_seed_from_architect,
    load_coder_integration_report_payload,
    load_coder_page_task_bundle_payload,
    load_coder_page_worker_results_payload,
    save_coder_compile_fix_trace_payload,
    save_coder_integration_report_payload,
    save_coder_page_worker_results_payload,
)
from tools.common import resolve_workspace_path
from utils.llm_utils import (
    extract_json_object_from_text,
    extract_tool_call_args,
    invoke_with_tool,
    normalize_tool_schema,
)
from utils.session_context import reset_current_session_id, set_current_session_id
from utils.utils import load_prompt

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

_EXCLUDED_STATE_KEYS = {
    "messages",
    "todos",
    "structured_response",
    "skills_metadata",
    "memory_contents",
}

# ---------------------------------------------------------------------------
# Prompt loading
# ---------------------------------------------------------------------------

_CODER_SKELETON_SYSTEM_PROMPT = load_prompt("coder_skeleton_system_prompt.md")
_CODER_PAGE_SYSTEM_PROMPT = load_prompt("coder_page_system_prompt.md")
_CODER_INTEGRATION_SYSTEM_PROMPT = load_prompt("coder_integration_system_prompt.md")

# ---------------------------------------------------------------------------
# Integration loop configuration
# ---------------------------------------------------------------------------

_INTEGRATION_MAX_ROUNDS = 5
_INTEGRATION_STALL_THRESHOLD = 2

# ---------------------------------------------------------------------------
# Route / identifier helpers
# ---------------------------------------------------------------------------

_ENTRY_ROLES: frozenset[str] = frozenset({"entry"})
_ENTRY_ROUTES: frozenset[str] = frozenset(
    {"pages/index", "pages/home", "pages/homepage", "pages/main"}
)


def _safe_identifier(value: str | None, fallback: str = "page") -> str:
    raw = (value or "").strip().lower()
    raw = re.sub(r"[^a-z0-9_]+", "_", raw)
    raw = re.sub(r"_+", "_", raw).strip("_")
    return raw or fallback


def _normalize_route(route: str | None, page_name: str, page_id: str) -> str:
    raw = str(route or "").strip()

    if raw:
        raw = raw.lstrip("/")

        if not raw.lower().startswith("pages/"):
            raw = f"pages/{raw}"

        prefix = "pages/"
        tail = raw[len(prefix):]
        tail_clean = re.sub(r"[^A-Za-z0-9_]", "_", tail).strip("_")
        if not tail_clean:
            base = _safe_identifier(page_id or page_name, fallback="index")
            tail_clean = "".join(w.capitalize() for w in base.split("_") if w)
        return f"{prefix}{tail_clean}"

    base = _safe_identifier(page_id or page_name, fallback="index")
    pascal = "".join(w.capitalize() for w in base.split("_") if w)
    return f"pages/{pascal}"


def _infer_entry_task(tasks: list[dict[str, Any]]) -> dict[str, Any] | None:
    if not tasks:
        return None

    for task in tasks:
        role = str(task.get("role") or "").strip().lower()
        if role in _ENTRY_ROLES:
            return task

    for task in tasks:
        route = str(task.get("route") or "").strip().lower()
        if route in _ENTRY_ROUTES:
            return task

    return tasks[0]


# ---------------------------------------------------------------------------
# Architect-stage helpers
# ---------------------------------------------------------------------------


def _stage1_result_is_success(stage1_result: str) -> bool:
    return "status: SUCCESS" in str(stage1_result or "")


def _architect_workspace_root() -> Path:
    from utils.session_context import get_current_session_id

    session_id = get_current_session_id()
    if not session_id:
        raise ValueError("current session id is missing")

    return (
        Path(__file__).resolve().parents[1]
        / "agent_workspace"
        / "sessions"
        / session_id
    ).resolve()


def _architect_resolve_path(raw_path: str) -> Path:
    return (_architect_workspace_root() / raw_path.lstrip("/")).resolve()


def _parse_json_text_or_empty_dict(text: str) -> dict[str, Any]:
    try:
        data = json.loads(text)
        return data if isinstance(data, dict) else {}
    except Exception:  # noqa: BLE001
        return {}


def _architect_artifact_status() -> dict[str, Any]:
    return _parse_json_text_or_empty_dict(inspect_architect_artifacts())


def _stage_status(stage_status: dict[str, Any] | None) -> bool:
    return bool(isinstance(stage_status, dict) and stage_status.get("is_complete"))


def _require_architect_stage3_complete() -> None:
    status = _architect_artifact_status()
    stage3 = status.get("stage3") if isinstance(status, dict) else {}
    if not _stage_status(stage3):
        raise ValueError(
            "architect artifacts incomplete: stage3 navigation design is required before coder stage"
        )


# ---------------------------------------------------------------------------
# Path normalization helpers
# ---------------------------------------------------------------------------


def _normalize_project_relative_path(project_name: str, raw_path: str) -> str:
    raw = str(raw_path or "").strip().replace("\\", "/")
    if not raw:
        return raw
    if raw.startswith("/projects/"):
        return raw
    if raw.startswith("/"):
        return f"/projects/{project_name}{raw}"
    return f"/projects/{project_name}/{raw.lstrip('/')}"


def _normalize_shared_dependencies(payload: dict[str, Any]) -> dict[str, Any]:
    normalized = dict(payload)
    tasks = list(normalized.get("tasks") or normalized.get("page_tasks") or [])

    normalized_tasks = []
    for task in tasks:
        item = dict(task)
        item["shared_dependencies"] = list(item.get("shared_dependencies") or [])
        normalized_tasks.append(item)

    normalized["tasks"] = normalized_tasks
    normalized.pop("page_tasks", None)
    return normalized


def _normalize_coder_skeleton_paths(payload: dict[str, Any]) -> dict[str, Any]:
    normalized = dict(payload)
    project_name = str(normalized.get("project_name") or "").strip()
    if not project_name:
        return normalized

    tasks = list(normalized.get("tasks") or normalized.get("page_tasks") or [])
    normalized_tasks = []
    for task in tasks:
        item = dict(task)
        if item.get("page_file"):
            item["page_file"] = _normalize_project_relative_path(
                project_name, str(item["page_file"])
            )
        item["allowed_write_paths"] = [
            _normalize_project_relative_path(project_name, str(p))
            for p in (item.get("allowed_write_paths") or [])
        ]
        normalized_tasks.append(item)

    normalized["tasks"] = normalized_tasks
    normalized.pop("page_tasks", None)
    return normalized


def _normalize_coder_skeleton_tool_args(tool_args: dict[str, Any]) -> dict[str, Any]:
    result = dict(tool_args)
    result = _normalize_coder_skeleton_paths(result)
    result = _normalize_shared_dependencies(result)
    return result


# ---------------------------------------------------------------------------
# Subagent runtime helpers
# ---------------------------------------------------------------------------


def _build_subagent_state(description: str, runtime: ToolRuntime) -> dict:
    state = {k: v for k, v in runtime.state.items() if k not in _EXCLUDED_STATE_KEYS}
    state["messages"] = [HumanMessage(content=description)]
    return state


def _runtime_thread_id(runtime: ToolRuntime | None) -> str | None:
    config = getattr(runtime, "config", None)
    if not isinstance(config, dict):
        return None
    configurable = config.get("configurable")
    if not isinstance(configurable, dict):
        return None
    return configurable.get("thread_id")


def _command_from_result(
    result: dict,
    tool_call_id: str,
    final_message_override: str | None = None,
) -> Command:
    state_update = {k: v for k, v in result.items() if k not in _EXCLUDED_STATE_KEYS}
    final_message = final_message_override
    if final_message is None:
        final_message = (
            result["messages"][-1].text.rstrip() if result.get("messages") else ""
        )
    return Command(
        update={
            **state_update,
            "messages": [ToolMessage(final_message, tool_call_id=tool_call_id)],
        }
    )


def _invoke_subagent(agent: Any, description: str, runtime: ToolRuntime) -> dict:
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


def _result_text(result: dict) -> str:
    if not result.get("messages"):
        return ""
    message = result["messages"][-1]
    return getattr(message, "text", "") or getattr(message, "content", "") or ""


def _extract_structured_response(result: dict) -> Any:
    if not isinstance(result, dict):
        return None
    return result.get("structured_response")


# ---------------------------------------------------------------------------
# Compile output parsing helpers
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


def _build_compile_fingerprint(compile_output: str) -> dict[str, Any]:
    parsed = _parse_compile_output(compile_output)
    key_errors = list(parsed.get("key_errors") or [])

    normalized_error_groups: list[str] = []
    primary_blockers: list[dict[str, str]] = []

    for line in key_errors:
        error_type, file_key = _classify_compile_error_line(line)
        if error_type not in normalized_error_groups:
            normalized_error_groups.append(error_type)

        blocker = {
            "file": file_key,
            "type": error_type,
        }
        if blocker not in primary_blockers:
            primary_blockers.append(blocker)

    primary_blockers = primary_blockers[:8]

    return {
        "normalized_error_groups": normalized_error_groups,
        "primary_blockers": primary_blockers,
    }


def _compile_fingerprint_stalled(
    previous: dict[str, Any] | None,
    current: dict[str, Any] | None,
) -> bool:
    if not previous or not current:
        return False

    prev_groups = sorted(set(previous.get("normalized_error_groups") or []))
    curr_groups = sorted(set(current.get("normalized_error_groups") or []))

    prev_blockers = sorted(
        {
            (str(item.get("file") or ""), str(item.get("type") or ""))
            for item in (previous.get("primary_blockers") or [])
            if isinstance(item, dict)
        }
    )
    curr_blockers = sorted(
        {
            (str(item.get("file") or ""), str(item.get("type") or ""))
            for item in (current.get("primary_blockers") or [])
            if isinstance(item, dict)
        }
    )

    return prev_groups == curr_groups and prev_blockers == curr_blockers


def _parse_compile_output(compile_output: str) -> dict[str, Any]:
    if not compile_output or not compile_output.strip():
        return {
            "compile_status": "FAILED",
            "project_name": "",
            "project_path": "",
            "key_errors": ["compile output was empty"],
        }

    compile_status = "FAILED"
    project_name = ""
    project_path = ""
    key_errors: list[str] = []
    in_errors = False

    for raw_line in compile_output.splitlines():
        line = raw_line.strip()
        if line.startswith("compile_status:"):
            compile_status = line.split(":", 1)[1].strip()
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
        "compile_status": "SUCCESS" if compile_status == "SUCCESS" else "FAILED",
        "project_name": project_name,
        "project_path": project_path,
        "key_errors": key_errors[:12],
    }


def _extract_final_compile_output(agent_summary: str) -> str:
    text = str(agent_summary or "")

    m = re.search(
        r"<<FINAL_COMPILE_OUTPUT>>\s*(.*?)\s*<<END_FINAL_COMPILE_OUTPUT>>",
        text,
        re.DOTALL,
    )
    if m:
        return m.group(1).strip()

    if "compile_status:" in text:
        return text.strip()

    return (
        "compile_status: FAILED\n"
        "key_errors:\n"
        "- integration worker did not return a compile output block\n"
    )


def _strip_compile_output_block(agent_summary: str) -> str:
    return re.sub(
        r"<<FINAL_COMPILE_OUTPUT>>\s*.*?\s*<<END_FINAL_COMPILE_OUTPUT>>",
        "",
        str(agent_summary or ""),
        flags=re.DOTALL,
    ).strip()


# ---------------------------------------------------------------------------
# Dispatch description builders
# ---------------------------------------------------------------------------


def build_architect_dispatch_description() -> str:
    return "\n".join(
        [
            ARCHITECT_DISPATCH_CONTRACT.render(),
            "",
            "Architect internal pipeline contract:",
            "stage1: single-image observation extraction",
            "- extract per-image observation drafts from screenshots",
            "- preserve page identity, visible page frame, visible UI structure, interaction clues, navigation clues, merge clues, subpage clues, overlay clues, state clues, and lightweight visual semantics",
            "- stay faithful to screenshot facts and avoid fabricating unseen or unsupported deep structure",
            "",
            "stage2: final page set construction",
            "- merge related observation drafts into the final page set",
            "- distinguish same-page drafts, state variants, overlays, and standalone pages",
            "- preserve implementation-useful page structure, merged ui_tree, interaction clues, and visual/implementation hints",
            "- do not finalize global navigation relations in this stage",
            "",
            "stage3: hierarchy and navigation inference",
            "- infer page hierarchy and navigation relations from merged pages",
            "- determine entry page and validate global consistency",
            "- save navigation-only design artifact without rewriting stage2 page files",
        ]
    )


def build_coder_dispatch_description(
    task_type: Literal["implementation", "fix_from_test"],
) -> str:
    return build_coder_dispatch_contract(task_type=task_type).render()


def build_coder_integration_dispatch_description(
    task_type: Literal["implementation", "fix_from_test"],
) -> str:
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
            "- if repeated compile blockers do not materially change => need_human_guidance",
            "- if task mismatch => wrong_agent",
        ]
    )


def build_tester_dispatch_description() -> str:
    return TESTER_DISPATCH_CONTRACT.render()


# ---------------------------------------------------------------------------
# Prompt builders
# ---------------------------------------------------------------------------


def build_coder_skeleton_planning_prompt(
    architect_payload: dict,
    task_type: Literal["implementation", "fix_from_test"],
) -> str:
    return "\n".join(
        [
            f"task_type: {task_type}",
            "current_stage: coder_skeleton",
            "You are executing the skeleton stage only.",
            "Use your system prompt as the primary contract.",
            "",
            "Required input files:",
            "- /designs/page_merge_index.json",
            "- /designs/navigation_design.json",
            "- /designs/pages/<page_id>.json  # read page files on demand using actual page ids",
            "",
            "Required output files:",
            "- /designs/coder_page_tasks.json",
            "",
            "Stage goals:",
            "- create the HarmonyOS project from the provided template when needed",
            "- initialize the project skeleton",
            "- register routes and entry trampoline",
            "- create shared navigation scaffold only when explicitly justified by navigation/page evidence",
            "- persist the canonical /designs/coder_page_tasks.json bundle before page workers begin",
            "",
            "Execution boundaries:",
            "- do not implement full page UI in this stage",
            "- do not declare the whole app complete",
            "- navigation hierarchy source of truth is /designs/navigation_design.json",
            "- page structure source of truth is /designs/pages/<page_id>.json",
            "- do not auto-assign shared_dependencies merely because there are multiple pages",
            "",
            "Read required skills and input files yourself before acting.",
        ]
    )


def _build_coder_skeleton_result_prompt(
    architect_payload: dict,
    task_type: Literal["implementation", "fix_from_test"],
    agent_summary: str,
) -> str:
    return "\n".join(
        [
            "Summarize the skeleton-stage result into structured CoderSkeletonOutput.",
            "Use the persisted architect design files as the source of truth.",
            "Use the worker summary only as supporting context.",
            "",
            f"task_type: {task_type}",
            "",
            "Source files:",
            "- /designs/page_merge_index.json",
            "- /designs/navigation_design.json",
            "- /designs/pages/<page_id>.json",
            "",
            "Expected emphasis:",
            "- project_name",
            "- app_display_name if available",
            "- canonical tasks for page workers",
            "- multi-page navigation scaffold expectations only when explicitly supported",
            "- page-level shared_dependencies must remain explicit and must not be inferred solely from page count",
            "",
            "Skeleton worker summary:",
            agent_summary or "(empty)",
        ]
    )


def _build_page_task_prompt(
    task_payload: dict,
    task_type: Literal["implementation", "fix_from_test"],
    tester_report_payload: dict | None = None,
) -> str:
    page_id = str(task_payload.get("page_id") or "")
    sections = [
        f"task_type: {task_type}",
        "current_stage: coder_page_worker",
        "You are executing one page implementation task only.",
        "Use your system prompt as the primary contract.",
        "",
        f"target_page_name: {str(task_payload.get('page_name') or '')}",
        f"target_page_id: {page_id}",
        f"target_route: {str(task_payload.get('route') or '')}",
        f"target_page_file: {str(task_payload.get('page_file') or '')}",
        "",
        "Required input files:",
        "- /designs/coder_page_tasks.json",
        f"- /designs/pages/{page_id}.json",
        "",
        "Optional reference files:",
        "- /designs/page_merge_index.json",
        "- /designs/navigation_design.json",
    ]

    if tester_report_payload is not None:
        sections.append("- /logs/tester/latest_tester_report.json  # optional reference for fix_from_test")

    sections.extend(
        [
            "",
            "Execution boundaries:",
            "- only modify allowed_write_paths for this task",
            "- do not edit shared skeleton files directly",
            "- do not run project-wide integration work in this stage",
            "- prioritize UI fidelity over deep functionality",
            "",
            "Read required skills and input files yourself before coding.",
        ]
    )
    return "\n".join(sections)


def _build_integration_prompt(
    task_type: Literal["implementation", "fix_from_test"],
    tester_report_payload: dict | None = None,
    prev_compile_feedback: str | None = None,
    round_idx: int = 1,
) -> str:
    sections = [
        f"task_type: {task_type}",
        f"integration_round: {round_idx}",
        "current_stage: coder_integration",
        "You are executing the integration stage only.",
        "Use your system prompt as the primary contract.",
        "",
        "Required input files:",
        "- /designs/coder_page_tasks.json",
        "- /logs/coder/page_worker_results.json",
        "- /designs/navigation_design.json",
        "",
        "Optional reference files:",
        "- /designs/page_merge_index.json",
        "- /designs/pages/<page_id>.json",
    ]

    if tester_report_payload is not None:
        sections.append("- /logs/tester/latest_tester_report.json  # optional reference for fix_from_test")

    sections.extend(
        [
            "",
            "Stage goals:",
            "- resolve compile-blocking engineering issues",
            "- preserve page identity, navigation intent, and UI fidelity",
            "- own the compile-fix loop in this stage",
            "- persist the final integration report",
            "",
            "Execution boundaries:",
            "- do not re-plan the app architecture",
            "- do not unnecessarily rewrite page UI",
            "- make the smallest compile-safe fixes first",
            "",
            "Your final response must include:",
            "- a short human-readable summary",
            "- a compile output block wrapped exactly with <<FINAL_COMPILE_OUTPUT>> and <<END_FINAL_COMPILE_OUTPUT>>",
            "",
            "Read required skills and input files yourself before fixing.",
        ]
    )

    if prev_compile_feedback:
        sections.extend(
            [
                "",
                "Previous round compile output:",
                "<<PREVIOUS_COMPILE_OUTPUT>>",
                prev_compile_feedback,
                "<<END_PREVIOUS_COMPILE_OUTPUT>>",
            ]
        )
    return "\n".join(sections)


def _build_page_result_prompt(
    task_payload: dict, modified_files: list[str], agent_summary: str
) -> str:
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


# ---------------------------------------------------------------------------
# Structured-output fallback helpers
# ---------------------------------------------------------------------------


def _extract_json_dict_from_response(response: Any) -> dict[str, Any] | None:
    try:
        return extract_json_object_from_text(response)
    except Exception:  # noqa: BLE001
        return None


def _load_json_dict_file(path: Path) -> dict[str, Any]:
    text = path.read_text(encoding="utf-8")
    try:
        payload = json.loads(text)
    except json.JSONDecodeError:
        payload = extract_json_object_from_text(text)
        if payload is None:
            raise
    if not isinstance(payload, dict):
        raise ValueError(f"JSON payload in {path} must be an object")
    return payload


def _fallback_coder_skeleton_payload(partial: dict[str, Any] | None = None) -> dict[str, Any]:
    inferred = build_coder_skeleton_seed_from_architect()
    if not partial:
        return _normalize_coder_skeleton_tool_args(inferred)

    merged = {**inferred, **partial}
    if not merged.get("tasks"):
        merged["tasks"] = list(inferred.get("tasks") or partial.get("page_tasks") or [])
    return _normalize_coder_skeleton_tool_args(merged)


def _infer_page_worker_status(agent_summary: str, modified_files: list[str]) -> str:
    text = str(agent_summary or "").lower()
    if "need_human_guidance" in text or "need human guidance" in text:
        return "need_human_guidance"
    if any(token in text for token in ("blocker", "blocked", "wrong_agent", "failed")):
        return "blocked"
    if modified_files or any(token in text for token in ("完成", "done", "completed", "implemented")):
        return "done"
    return "blocked"


def _fallback_page_worker_result(
    task_payload: dict[str, Any],
    modified_files: list[str],
    agent_summary: str,
    partial: dict[str, Any] | None = None,
) -> dict[str, Any]:
    partial = dict(partial or {})
    blockers = partial.get("blockers")
    if not isinstance(blockers, list):
        blockers = []

    status = str(partial.get("status") or "").strip().lower()
    if status not in {"done", "blocked", "need_human_guidance"}:
        status = _infer_page_worker_status(agent_summary, modified_files)

    return {
        "status": status,
        "page_name": str(
            partial.get("page_name")
            or task_payload.get("page_name")
            or task_payload.get("page_id")
            or ""
        ),
        "modified_files": list(modified_files),
        "exports_added": list(partial.get("exports_added") or []),
        "shared_contract_requests": list(partial.get("shared_contract_requests") or []),
        "blockers": blockers,
        "summary": str(partial.get("summary") or agent_summary or "").strip() or "page worker finished",
    }


def _resolve_project_name_from_payloads(
    skeleton_payload: dict[str, Any] | None = None,
    task_bundle: dict[str, Any] | None = None,
    architect_payload: dict[str, Any] | None = None,
) -> str:
    candidates = [
        (skeleton_payload or {}).get("project_name"),
        (task_bundle or {}).get("project_name"),
        ((architect_payload or {}).get("page_merge_index") or {}).get("project_name"),
        ((architect_payload or {}).get("navigation_design") or {}).get("project_name"),
    ]

    for value in candidates:
        text = str(value or "").strip()
        if text:
            return text
    return "app_project"


# ---------------------------------------------------------------------------
# Payload loaders
# ---------------------------------------------------------------------------


def load_page_merge_index_payload() -> dict[str, Any]:
    return _load_json_dict_file(_architect_resolve_path("/designs/page_merge_index.json"))


def load_navigation_design_payload() -> dict[str, Any]:
    return _load_json_dict_file(_architect_resolve_path("/designs/navigation_design.json"))


def load_architect_page_payloads() -> list[dict[str, Any]]:
    pages_dir = _architect_resolve_path("/designs/pages")
    if not pages_dir.exists() or not pages_dir.is_dir():
        return []
    return [_load_json_dict_file(p) for p in sorted(pages_dir.glob("*.json"))]


def load_architect_design_payload() -> dict[str, Any]:
    """
    Backward-compatible aggregated architect payload for coder consumption.

    New source of truth:
    - page index: /designs/page_merge_index.json
    - navigation: /designs/navigation_design.json
    - page files: /designs/pages/*.json
    """
    _require_architect_stage3_complete()
    navigation_design = load_navigation_design_payload()
    return {
        "page_merge_index": load_page_merge_index_payload(),
        "navigation_design": navigation_design,
        "pages": load_architect_page_payloads(),
        "index": navigation_design,
    }


def load_tester_report_payload() -> dict[str, Any]:
    return _load_json_dict_file(resolve_workspace_path("/logs/tester/latest_tester_report.json"))


# ---------------------------------------------------------------------------
# Coder artifact helpers
# ---------------------------------------------------------------------------


def _coder_page_results_path() -> Path:
    return resolve_workspace_path("/logs/coder/page_worker_results.json")


def _coder_integration_report_path() -> Path:
    return resolve_workspace_path("/logs/coder/integration_report.json")


def _coder_page_results_exist() -> bool:
    path = _coder_page_results_path()
    return path.exists() and path.is_file()


def _coder_integration_report_exists() -> bool:
    path = _coder_integration_report_path()
    return path.exists() and path.is_file()


def _coder_integration_success() -> bool:
    if not _coder_integration_report_exists():
        return False
    try:
        payload = load_coder_integration_report_payload()
    except Exception:  # noqa: BLE001
        return False
    return str(payload.get("compile_status") or "").strip().upper() == "SUCCESS"


# ---------------------------------------------------------------------------
# Coder skeleton stage
# ---------------------------------------------------------------------------


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
        force_tool_choice=False,
    )
    tool_args = extract_tool_call_args(llm_response, tool_name)
    if tool_args is not None:
        return _normalize_coder_skeleton_tool_args(tool_args)

    parsed_json = _extract_json_dict_from_response(llm_response)
    if parsed_json is not None:
        return _fallback_coder_skeleton_payload(parsed_json)

    parsed_summary = _extract_json_dict_from_response(agent_summary)
    return _fallback_coder_skeleton_payload(parsed_summary)


def run_coder_skeleton_stage(
    *,
    architect_payload: dict,
    task_type: Literal["implementation", "fix_from_test"],
    runtime: ToolRuntime,
) -> tuple[dict, str]:
    result = _invoke_subagent(
        get_coder_skeleton_worker(),
        build_coder_skeleton_planning_prompt(
            architect_payload=architect_payload, task_type=task_type
        ),
        runtime,
    )
    agent_summary = _result_text(result)

    structured = _extract_structured_response(result)
    if (
        structured is not None
        and isinstance(structured, dict)
        and (structured.get("tasks") or structured.get("page_tasks"))
    ):
        payload = _normalize_coder_skeleton_tool_args(structured)
        return payload, agent_summary

    payload = invoke_coder_skeleton_result_formatter(
        architect_payload=architect_payload,
        task_type=task_type,
        agent_summary=agent_summary,
    )
    return payload, agent_summary


# ---------------------------------------------------------------------------
# Coder page worker stage
# ---------------------------------------------------------------------------


def invoke_coder_page_result_formatter(
    task_payload: dict, modified_files: list[str], agent_summary: str
) -> dict:
    tool_name = "CoderPageWorkerResult"
    llm_response = invoke_with_tool(
        base_model,
        [
            SystemMessage(content=_CODER_PAGE_SYSTEM_PROMPT),
            HumanMessage(
                content=_build_page_result_prompt(task_payload, modified_files, agent_summary)
            ),
        ],
        tool_name,
        normalize_tool_schema(CoderPageWorkerResult.model_json_schema()),
        force_tool_choice=False,
    )
    tool_args = extract_tool_call_args(llm_response, tool_name)
    if tool_args is not None:
        return tool_args

    parsed_json = _extract_json_dict_from_response(llm_response)
    if parsed_json is not None:
        return _fallback_page_worker_result(
            task_payload=task_payload,
            modified_files=modified_files,
            agent_summary=agent_summary,
            partial=parsed_json,
        )

    parsed_summary = _extract_json_dict_from_response(agent_summary)
    return _fallback_page_worker_result(
        task_payload=task_payload,
        modified_files=modified_files,
        agent_summary=agent_summary,
        partial=parsed_summary,
    )


def _hash_file(path: str) -> str | None:
    target = resolve_workspace_path(path)
    if not target.exists() or not target.is_file():
        return None
    return hashlib.sha256(target.read_bytes()).hexdigest()


def _snapshot_allowed_paths(paths: list[str]) -> dict[str, str | None]:
    return {p: _hash_file(p) for p in paths}


def _detect_modified_files(
    paths: list[str], before: dict[str, str | None]
) -> list[str]:
    return [
        p
        for p in paths
        if (after := _hash_file(p)) is not None and before.get(p) != after
    ]


def _run_single_page_worker(
    task_payload: dict,
    runtime: ToolRuntime,
    task_type: Literal["implementation", "fix_from_test"],
    tester_report_payload: dict | None = None,
) -> dict:
    before = _snapshot_allowed_paths(list(task_payload.get("allowed_write_paths") or []))
    result = _invoke_subagent(
        build_coder_page_worker(),
        _build_page_task_prompt(
            task_payload=task_payload,
            task_type=task_type,
            tester_report_payload=tester_report_payload,
        ),
        runtime,
    )
    modified_files = _detect_modified_files(
        list(task_payload.get("allowed_write_paths") or []), before
    )
    return invoke_coder_page_result_formatter(
        task_payload=task_payload,
        modified_files=modified_files,
        agent_summary=_result_text(result),
    )


def _select_page_tasks(
    task_bundle: dict,
    tester_report_payload: dict | None = None,
) -> list[dict]:
    tasks = list(task_bundle.get("tasks") or [])
    if not tester_report_payload:
        return tasks
    haystack = json.dumps(tester_report_payload, ensure_ascii=False)
    selected = [t for t in tasks if str(t.get("page_name") or "") in haystack]
    return selected or tasks


def dispatch_page_coders(
    *,
    task_type: Literal["implementation", "fix_from_test"],
    skeleton_payload: dict,
    task_bundle: dict,
    architect_payload: dict,
    runtime: ToolRuntime,
    tester_report_payload: dict | None = None,
) -> dict:
    # Note:
    # Page workers are dispatched concurrently.
    # session_context must remain thread-local / context-local.
    project_name = _resolve_project_name_from_payloads(
        skeleton_payload=skeleton_payload,
        task_bundle=task_bundle,
        architect_payload=architect_payload,
    )
    selected_tasks = _select_page_tasks(task_bundle, tester_report_payload=tester_report_payload)
    results: list[dict] = []

    if not selected_tasks:
        bundle = {"project_name": project_name, "results": results}
        save_coder_page_worker_results_payload(bundle)
        return bundle

    max_workers = min(4, max(1, len(selected_tasks)))
    with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
        future_to_task = {
            executor.submit(
                _run_single_page_worker,
                task_payload=task,
                runtime=runtime,
                task_type=task_type,
                tester_report_payload=tester_report_payload,
            ): task
            for task in selected_tasks
        }

        for future in concurrent.futures.as_completed(future_to_task):
            task = future_to_task[future]
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
                        "blockers": [
                            {
                                "blocker_type": "worker_execution_error",
                                "description": str(exc),
                            }
                        ],
                        "summary": "page worker failed before returning a structured result",
                    }
                )

    bundle = {"project_name": project_name, "results": results}
    save_coder_page_worker_results_payload(bundle)
    return bundle


# ---------------------------------------------------------------------------
# Coder integration stage
# ---------------------------------------------------------------------------


def invoke_coder_integration_report_formatter(
    project_name: str, compile_output: str, worker_summaries: list[str]
) -> dict:
    tool_name = "CoderIntegrationReport"
    llm_response = invoke_with_tool(
        base_model,
        [
            SystemMessage(content=_CODER_INTEGRATION_SYSTEM_PROMPT),
            HumanMessage(
                content=_build_integration_report_prompt(
                    project_name, compile_output, worker_summaries
                )
            ),
        ],
        tool_name,
        normalize_tool_schema(CoderIntegrationReport.model_json_schema()),
        force_tool_choice=False,
    )
    tool_args = extract_tool_call_args(llm_response, tool_name)
    if tool_args is not None:
        return tool_args

    parsed_json = _extract_json_dict_from_response(llm_response)
    if parsed_json is not None:
        parsed = _parse_compile_output(compile_output)
        success = parsed["compile_status"] == "SUCCESS"
        return {
            "compile_status": parsed_json.get("compile_status") or parsed["compile_status"],
            "project_name": parsed_json.get("project_name") or parsed["project_name"] or project_name,
            "project_path": parsed_json.get("project_path") or parsed["project_path"] or f"/projects/{project_name}",
            "ready_for_tester": (
                parsed_json.get("ready_for_tester")
                if isinstance(parsed_json.get("ready_for_tester"), bool)
                else success
            ),
            "fixes_applied": list(parsed_json.get("fixes_applied") or [s for s in worker_summaries if s]),
            "remaining_errors": list(parsed_json.get("remaining_errors") or parsed["key_errors"]),
            "blocker": str(
                parsed_json.get("blocker")
                or ("none" if success else (parsed["key_errors"][0] if parsed["key_errors"] else "compile failed"))
            ),
            "next_recommended_agent": parsed_json.get("next_recommended_agent") or ("tester" if success else "coder"),
        }

    parsed = _parse_compile_output(compile_output)
    success = parsed["compile_status"] == "SUCCESS"
    return {
        "compile_status": parsed["compile_status"],
        "project_name": parsed["project_name"] or project_name,
        "project_path": parsed["project_path"] or f"/projects/{project_name}",
        "ready_for_tester": success,
        "fixes_applied": [s for s in worker_summaries if s],
        "remaining_errors": parsed["key_errors"],
        "blocker": (
            "none"
            if success
            else (parsed["key_errors"][0] if parsed["key_errors"] else "compile failed")
        ),
        "next_recommended_agent": "tester" if success else "coder",
    }


def run_coder_integration(
    *,
    task_type: Literal["implementation", "fix_from_test"],
    skeleton_payload: dict,
    page_results_payload: dict,
    runtime: ToolRuntime,
    tester_report_payload: dict | None = None,
) -> dict:
    project_name = _resolve_project_name_from_payloads(skeleton_payload=skeleton_payload)
    worker_summaries: list[str] = []
    attempt_records: list[dict[str, Any]] = []
    modified_files = sorted(
        {
            path
            for r in list(page_results_payload.get("results") or [])
            for path in list(r.get("modified_files") or [])
        }
    )

    prev_fingerprint: dict[str, Any] | None = None
    stall_count = 0
    compile_feedback = ""
    parsed_compile: dict[str, Any] = {
        "compile_status": "FAILED",
        "project_name": "",
        "project_path": "",
        "key_errors": [],
    }

    for round_idx in range(1, _INTEGRATION_MAX_ROUNDS + 1):
        result = _invoke_subagent(
            get_coder_integration_worker(),
            _build_integration_prompt(
                task_type=task_type,
                tester_report_payload=tester_report_payload,
                prev_compile_feedback=compile_feedback if round_idx > 1 else None,
                round_idx=round_idx,
            ),
            runtime,
        )
        raw_summary = _result_text(result).strip()
        if raw_summary:
            worker_summaries.append(_strip_compile_output_block(raw_summary))

        compile_feedback = _extract_final_compile_output(raw_summary)
        parsed_compile = _parse_compile_output(compile_feedback)
        fingerprint = _build_compile_fingerprint(compile_feedback)

        attempt = build_coder_compile_fix_attempt_payload(
            attempt_index=round_idx,
            task_type=task_type,
            project_name=project_name,
            compile_status=parsed_compile["compile_status"],
            error_signature=json.dumps(fingerprint, ensure_ascii=False, sort_keys=True),
            key_errors=parsed_compile["key_errors"],
            worker_summary=_strip_compile_output_block(raw_summary) or "integration worker executed",
            worker_summaries_so_far=[s for s in worker_summaries if s],
            modified_files=modified_files,
            fixes_applied=[s for s in worker_summaries if s],
            skills_referenced=[
                "/skills/arkts-syntax-assistant/SKILL.md",
                "/skills/harmony-next/SKILL.md",
            ],
        )
        append_coder_compile_fix_attempt(attempt)
        attempt_records.append(attempt)

        if parsed_compile["compile_status"] == "SUCCESS":
            break

        if _compile_fingerprint_stalled(prev_fingerprint, fingerprint):
            stall_count += 1
            if stall_count >= _INTEGRATION_STALL_THRESHOLD:
                break
        else:
            stall_count = 0
        prev_fingerprint = fingerprint

    final_success = parsed_compile["compile_status"] == "SUCCESS"
    for idx, attempt in enumerate(attempt_records):
        updated = dict(attempt)
        updated["final_success"] = final_success
        if idx + 1 < len(attempt_records):
            nxt = attempt_records[idx + 1]
            updated["resolved_in_next_attempt"] = (
                nxt.get("compile_status") == "SUCCESS"
                or nxt.get("error_signature") != attempt.get("error_signature")
            )
        else:
            updated["resolved_in_next_attempt"] = None
        attempt_records[idx] = updated

    save_coder_compile_fix_trace_payload(
        {
            "project_name": project_name,
            "task_type": task_type,
            "attempts": attempt_records,
            "final_compile_status": parsed_compile["compile_status"],
            "final_success": final_success,
        }
    )

    report = invoke_coder_integration_report_formatter(
        project_name=project_name,
        compile_output=compile_feedback or "",
        worker_summaries=worker_summaries,
    )
    save_coder_integration_report_payload(report)
    return report


# ---------------------------------------------------------------------------
# Pipeline entry point
# ---------------------------------------------------------------------------


def run_coder_pipeline(
    *,
    task_type: Literal["implementation", "fix_from_test"],
    runtime: ToolRuntime,
) -> dict:
    architect_payload = load_architect_design_payload()
    tester_report_payload = (
        load_tester_report_payload() if task_type == "fix_from_test" else None
    )

    if _coder_integration_success():
        return load_coder_integration_report_payload()

    task_bundle: dict | None = None
    tasks_path = resolve_workspace_path("/designs/coder_page_tasks.json")
    if tasks_path.exists():
        try:
            task_bundle = load_coder_page_task_bundle_payload()
        except (json.JSONDecodeError, ValueError):
            task_bundle = None

    if task_bundle is None:
        skeleton_payload, _ = run_coder_skeleton_stage(
            architect_payload=architect_payload,
            task_type=task_type,
            runtime=runtime,
        )

        # Strong validation: skeleton stage must have persisted canonical task bundle.
        if not _coder_page_tasks_path().exists():
            raise RuntimeError(
                "coder skeleton stage completed but /designs/coder_page_tasks.json was not persisted"
            )

        task_bundle = load_coder_page_task_bundle_payload()
        skeleton_payload = dict(task_bundle)
    else:
        skeleton_payload = dict(task_bundle)

    if _coder_page_results_exist():
        page_results_payload = load_coder_page_worker_results_payload()
    else:
        page_results_payload = dispatch_page_coders(
            task_type=task_type,
            skeleton_payload=skeleton_payload,
            task_bundle=task_bundle,
            architect_payload=architect_payload,
            runtime=runtime,
            tester_report_payload=tester_report_payload,
        )

    return run_coder_integration(
        task_type=task_type,
        skeleton_payload=skeleton_payload,
        page_results_payload=page_results_payload,
        runtime=runtime,
        tester_report_payload=tester_report_payload,
    )


# ---------------------------------------------------------------------------
# Public tool definitions
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Architect stage
# ---------------------------------------------------------------------------


@tool
def dispatch_architect(runtime: ToolRuntime) -> Command:
    """Dispatch the architect stage with artifact-aware resume: stage1 observation extraction, stage2 final page set, then stage3 navigation inference."""
    if not runtime.tool_call_id:
        raise ValueError("Tool call ID is required for architect dispatch")

    session_token = set_current_session_id(_runtime_thread_id(runtime))
    try:
        artifact_status = _architect_artifact_status()
        stage1_complete = _stage_status(artifact_status.get("stage1"))
        stage2_complete = _stage_status(artifact_status.get("stage2"))
        stage3_complete = _stage_status(artifact_status.get("stage3"))

        if stage3_complete:
            final_message = json.dumps(
                {
                    "status": "SUCCESS",
                    "message": "architect artifacts already complete; resume skipped",
                    "artifact_status": artifact_status,
                },
                ensure_ascii=False,
                indent=2,
            )
            return _command_from_result(
                {"messages": [], "structured_response": artifact_status.get("stage3")},
                runtime.tool_call_id,
                final_message_override=final_message,
            )

        stage1_result = ""
        stage2_message = ""
        stage2_structured = None

        if not stage1_complete:
            stage1_result = batch_extract_page_drafts()

            if not _stage1_result_is_success(stage1_result):
                return _command_from_result(
                    {"messages": [], "structured_response": None},
                    runtime.tool_call_id,
                    final_message_override=(
                        "architect stage failed during stage1 observation extraction\n\n"
                        f"{stage1_result}"
                    ),
                )

            stage1_check = _parse_json_text_or_empty_dict(check_stage1_artifacts())
            if not _stage_status(stage1_check):
                return _command_from_result(
                    {"messages": [], "structured_response": stage1_check},
                    runtime.tool_call_id,
                    final_message_override=json.dumps(
                        {
                            "status": "FAILED",
                            "message": "stage1 finished but artifacts are incomplete",
                            "stage1_check": stage1_check,
                        },
                        ensure_ascii=False,
                        indent=2,
                    ),
                )
        else:
            stage1_result = "status: SUCCESS\nresume: reused existing stage1 artifacts"

        if not stage2_complete:
            stage2_result = _invoke_subagent(
                get_architect_page_merger(),
                "\n\n".join(
                    [
                        build_architect_dispatch_description(),
                        "【阶段一已完成或已存在可复用 artifacts，不要重复执行单图观察提取】",
                        "你现在只执行阶段二：最终页面集合归并与页面定稿。",
                        "请先使用 read_page_drafts_index 读取 /designs/page_drafts_index.json。",
                        "必须先基于 observation drafts 的轻量摘要完成页面归属判断，先识别哪些截图属于同一页面，再区分状态变体、overlay 变体和独立页面。",
                        "不要一次性读取所有完整草稿；只在归并决策需要时按需使用 read_page_draft 读取必要草稿。",
                        "你要重点利用 page_identity、page_overview、ui_tree、structural_blocks、key_content、interaction_clues、merge_hints、overlay_hints、state_hints、subpage_hints、raw_preservation 等信息进行归并。",
                        "本阶段的目标是确定最终页面集合，并输出可供后续实现使用的页面终稿。",
                        "必须尽量保留 merged ui_tree、frame_blocks、key_texts、key_controls、interactions、state_variants、overlay_summaries、implementation_hints、visual_style_hints 等实现相关信息。",
                        "本阶段不负责最终全局导航关系定稿，可以保留 target_page_hint 等线索，但不要输出最终导航图。",
                        "当某个最终页面边界稳定后，可立即调用 save_merged_page 保存该页面文件。"
                        "全部页面完成归属后，必须调用 save_page_merge_result 保存 /designs/page_merge_index.json。"
                        f"阶段一结果：\n{stage1_result}",
                    ]
                ),
                runtime,
            )

            stage2_message = _result_text(stage2_result).strip()
            stage2_structured = _extract_structured_response(stage2_result)

            stage2_check = _parse_json_text_or_empty_dict(check_stage2_artifacts())
            if not _stage_status(stage2_check):
                final_message = json.dumps(
                    {
                        "status": "FAILED",
                        "message": "architect stage failed after stage2: page merge artifacts are incomplete",
                        "architect_workspace_root": str(_architect_workspace_root()),
                        "stage1_result": stage1_result,
                        "stage2_message": stage2_message or "(empty)",
                        "stage2_check": stage2_check,
                    },
                    ensure_ascii=False,
                    indent=2,
                )
                return _command_from_result(
                    {"messages": [], "structured_response": stage2_structured},
                    runtime.tool_call_id,
                    final_message_override=final_message,
                )
        else:
            stage2_message = "status: SUCCESS\nresume: reused existing stage2 artifacts"

        stage3_result = _invoke_subagent(
            get_architect_navigation_planner(),
            "\n\n".join(
                [
                    build_architect_dispatch_description(),
                    "【阶段一已完成或已存在可复用 artifacts，不要重复执行单图观察提取】",
                    "【阶段二已完成并已落盘 page merge 结果，不要重新归并页面】",
                    "你现在只执行阶段三：页面层级推断、导航关系定稿、全局校验。",
                    "请先使用 read_page_merge_index 读取 /designs/page_merge_index.json。",
                    "只在必要时按需使用 read_page_file 读取具体页面文件。",
                    "你需要基于已归并页面集合，推断主页面、子页面、详情页、设置页、结果页等层级角色，并补全最终导航关系。",
                    "本阶段重点是 entry_page_id、page_hierarchy、relations 和全局一致性，不要重新做页面归并。",
                    "不要把 tab 切换、同页状态变化、overlay 开关、局部展开收起误判为页面跳转。",
                    "不要改写阶段二已定稿的页面文件。",
                    "完成页面层级、导航关系与全局校验后，必须调用 save_navigation_design 落盘 /designs/navigation_design.json。",
                    f"阶段一结果：\n{stage1_result}",
                    f"阶段二结果：\n{stage2_message or '(empty)'}",
                ]
            ),
            runtime,
        )

        structured = _extract_structured_response(stage3_result)
        final_message = _result_text(stage3_result).strip()

        stage3_check = _parse_json_text_or_empty_dict(check_stage3_artifacts())
        if not _stage_status(stage3_check):
            final_message = json.dumps(
                {
                    "status": "FAILED",
                    "message": "architect stage finished but stage3 navigation artifact is incomplete",
                    "architect_workspace_root": str(_architect_workspace_root()),
                    "stage1_result": stage1_result,
                    "stage2_result": stage2_message or "(empty)",
                    "stage3_worker_message": final_message or "(empty)",
                    "stage3_check": stage3_check,
                },
                ensure_ascii=False,
                indent=2,
            )

        return _command_from_result(
            {"messages": [], "structured_response": structured},
            runtime.tool_call_id,
            final_message_override=final_message or "architect stage completed",
        )
    finally:
        reset_current_session_id(session_token)


@tool
def dispatch_coder_skeleton(
    task_type: Literal["implementation", "fix_from_test"] = "implementation",
    runtime: ToolRuntime = None,
) -> Command:
    """Run the coder skeleton stage and let the skeleton worker own project bootstrap work."""
    if runtime is None or not runtime.tool_call_id:
        raise ValueError("Tool call ID is required for coder skeleton dispatch")

    session_token = set_current_session_id(_runtime_thread_id(runtime))
    try:
        _require_architect_stage3_complete()
        architect_payload = load_architect_design_payload()
        skeleton_payload, worker_summary = run_coder_skeleton_stage(
            architect_payload=architect_payload,
            task_type=task_type,
            runtime=runtime,
        )

        skeleton_plan_saved = _coder_page_tasks_path().exists()
        if not skeleton_plan_saved:
            raise RuntimeError(
                "coder skeleton worker finished but /designs/coder_page_tasks.json was not persisted"
            )

        final_task_bundle = load_coder_page_task_bundle_payload()
        project_name = _resolve_project_name_from_payloads(
            skeleton_payload=final_task_bundle,
            architect_payload=architect_payload,
        )

        final_message = json.dumps(
            {
                "project_name": project_name,
                "skeleton_plan_saved": skeleton_plan_saved,
                "worker_execution_summary": worker_summary,
            },
            ensure_ascii=False,
            indent=2,
        )
        return _command_from_result(
            {"messages": [], "structured_response": final_task_bundle},
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
    """Run page worker tasks from the materialized skeleton artifacts."""
    if runtime is None or not runtime.tool_call_id:
        raise ValueError("Tool call ID is required for page coder dispatch")

    session_token = set_current_session_id(_runtime_thread_id(runtime))
    try:
        _require_architect_stage3_complete()
        task_bundle = load_coder_page_task_bundle_payload()
        architect_payload = load_architect_design_payload()
        tester_report_payload = (
            load_tester_report_payload() if task_type == "fix_from_test" else None
        )
        page_results_payload = dispatch_page_coders(
            task_type=task_type,
            skeleton_payload=task_bundle,
            task_bundle=task_bundle,
            architect_payload=architect_payload,
            runtime=runtime,
            tester_report_payload=tester_report_payload,
        )
        return _command_from_result(
            {"messages": [], "structured_response": page_results_payload},
            runtime.tool_call_id,
            final_message_override=json.dumps(
                page_results_payload, ensure_ascii=False, indent=2
            ),
        )
    finally:
        reset_current_session_id(session_token)


@tool
def dispatch_coder_integration(
    task_type: Literal["implementation", "fix_from_test"] = "implementation",
    runtime: ToolRuntime = None,
) -> Command:
    """Run the integration stage and persist the final integration report."""
    if runtime is None or not runtime.tool_call_id:
        raise ValueError("Tool call ID is required for coder integration dispatch")

    session_token = set_current_session_id(_runtime_thread_id(runtime))
    try:
        _require_architect_stage3_complete()
        skeleton_payload = load_coder_page_task_bundle_payload()
        page_results_payload = load_coder_page_worker_results_payload()
        tester_report_payload = (
            load_tester_report_payload() if task_type == "fix_from_test" else None
        )
        integration_report = run_coder_integration(
            task_type=task_type,
            skeleton_payload=skeleton_payload,
            page_results_payload=page_results_payload,
            runtime=runtime,
            tester_report_payload=tester_report_payload,
        )
        return _command_from_result(
            {"messages": [], "structured_response": integration_report},
            runtime.tool_call_id,
            final_message_override=json.dumps(
                integration_report, ensure_ascii=False, indent=2
            ),
        )
    finally:
        reset_current_session_id(session_token)


@tool
def dispatch_coder(
    task_type: Literal["implementation", "fix_from_test"] = "implementation",
    runtime: ToolRuntime = None,
) -> Command:
    """Dispatch the coder stage with a fixed implementation or fix contract."""
    if runtime is None or not runtime.tool_call_id:
        raise ValueError("Tool call ID is required for coder dispatch")

    _require_architect_stage3_complete()
    result = _invoke_subagent(
        get_coder_orchestrator(),
        build_coder_dispatch_description(task_type=task_type),
        runtime,
    )
    try:
        integration_report = load_coder_integration_report_payload()
        final_message_override = json.dumps(
            integration_report, ensure_ascii=False, indent=2
        )
    except Exception:  # noqa: BLE001
        final_message_override = None
    return _command_from_result(
        result, runtime.tool_call_id, final_message_override=final_message_override
    )


@tool
def dispatch_tester(runtime: ToolRuntime) -> Command:
    """Dispatch the tester stage with a fixed validation contract."""
    if not runtime.tool_call_id:
        raise ValueError("Tool call ID is required for tester dispatch")

    result = _invoke_subagent(
        get_tester_agent(), build_tester_dispatch_description(), runtime
    )
    try:
        report_payload = load_tester_report_payload()
        final_message_override = json.dumps(report_payload, ensure_ascii=False, indent=2)
    except Exception:  # noqa: BLE001
        final_message_override = None
    return _command_from_result(
        result, runtime.tool_call_id, final_message_override=final_message_override
    )


# ---------------------------------------------------------------------------
# Tool registries
# ---------------------------------------------------------------------------

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