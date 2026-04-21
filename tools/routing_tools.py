from __future__ import annotations

import concurrent.futures
import hashlib
import json
import re
from typing import Any, Literal

from langchain.tools import ToolRuntime, tool
from langchain_core.messages import HumanMessage, SystemMessage, ToolMessage
from langgraph.types import Command
from tools.architect_tools import batch_extract_page_drafts
from contracts.agent_contracts import (
    ARCHITECT_DISPATCH_CONTRACT,
    TESTER_DISPATCH_CONTRACT,
    build_coder_dispatch_contract,
)
from models import base_model
from schemas import (
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
    get_flow_summary_agent,
    get_review_executor_agent,
    get_tester_agent,
    get_visual_review_agent,
)
from tools.architect_tools import (
    ArchitectPersistPayload,
    save_page_draft,
    save_page_drafts_index,
    read_page_draft,
    save_architect_design,
)
from tools.coder_tools import (
    _coder_page_tasks_path,
    append_coder_compile_fix_attempt,
    build_coder_compile_fix_attempt_payload,
    load_coder_integration_report_payload,
    load_coder_page_task_bundle_payload,
    load_coder_page_worker_results_payload,
    save_coder_compile_fix_trace_payload,
    save_coder_integration_report_payload,
    save_coder_page_worker_results_payload,
)
from tools.common import resolve_workspace_path
from utils.llm_utils import extract_tool_call_args, invoke_with_tool, normalize_tool_schema
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

_ARCHITECT_SYSTEM_PROMPT = load_prompt("architect_system_prompt.md")
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
    """
    Normalize an architect-provided route value into a valid HarmonyOS page route.

    Rules:
    - Must start with "pages/" (case-insensitive prefix is accepted and corrected)
    - Tail after "pages/" must be a valid identifier (PascalCase preferred)
    - Leading slashes are stripped
    - Fallback: derive from page_id or page_name using PascalCase
    """
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

    # Fallback: derive PascalCase name from page_id or page_name
    base = _safe_identifier(page_id or page_name, fallback="index")
    pascal = "".join(w.capitalize() for w in base.split("_") if w)
    return f"pages/{pascal}"


def _infer_entry_task(page_tasks: list[dict[str, Any]]) -> dict[str, Any] | None:
    """
    Select the entry page task from a list of page tasks.

    Priority:
    1. role == "entry"  (Schema-defined canonical value)
    2. route matches known entry route patterns
    3. First task as final fallback
    """
    if not page_tasks:
        return None

    for task in page_tasks:
        role = str(task.get("role") or "").strip().lower()
        if role in _ENTRY_ROLES:
            return task

    for task in page_tasks:
        route = str(task.get("route") or "").strip().lower()
        if route in _ENTRY_ROUTES:
            return task

    return page_tasks[0]


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


def _normalize_coder_skeleton_paths(payload: dict) -> dict:
    normalized = dict(payload)
    project_name = str(normalized.get("project_name") or "").strip()
    if not project_name:
        return normalized

    page_tasks = []
    for task in normalized.get("page_tasks", []) or []:
        item = dict(task)
        if item.get("page_file"):
            item["page_file"] = _normalize_project_relative_path(
                project_name, str(item["page_file"])
            )
        item["allowed_write_paths"] = [
            _normalize_project_relative_path(project_name, str(p))
            for p in (item.get("allowed_write_paths") or [])
        ]
        page_tasks.append(item)
    normalized["page_tasks"] = page_tasks
    return normalized


def _ensure_navigation_scaffold(payload: dict) -> dict:
    """
    Inject shared navigation dependencies into every page task when the project
    has more than one page.  Skeleton owns shared navigation; page workers only
    consume it.
    """
    normalized = dict(payload)
    page_tasks = list(normalized.get("page_tasks") or [])
    if len(page_tasks) <= 1:
        return normalized

    normalized_tasks = []
    for task in page_tasks:
        item = dict(task)
        shared_deps = list(item.get("shared_dependencies") or [])
        for dep in ("BottomNavBar", "NavigationService"):
            if dep not in shared_deps:
                shared_deps.append(dep)
        item["shared_dependencies"] = shared_deps
        normalized_tasks.append(item)
    normalized["page_tasks"] = normalized_tasks
    return normalized


def _normalize_coder_skeleton_tool_args(tool_args: dict) -> dict:
    result = dict(tool_args)
    result = _normalize_coder_skeleton_paths(result)
    result = _ensure_navigation_scaffold(result)
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


def _compile_status_signature(compile_output: str) -> str:
    """
    Derive a stable one-line signature from compile output for stall detection.
    Priority: failed_step line > first error bullet > first non-empty line.
    """
    text = str(compile_output or "")
    m = re.search(r"^failed_step:\s*(.+)$", text, re.MULTILINE)
    if m:
        return m.group(1).strip()
    m = re.search(r"^- (.+)$", text, re.MULTILINE)
    if m:
        return m.group(1).strip()
    first_line = text.strip().splitlines()[0] if text.strip() else ""
    return first_line or "unknown"


def _parse_compile_output(compile_output: str) -> dict[str, Any]:
    """
    Parse a structured compile output block into a typed dict.
    Handles empty input gracefully.
    """
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
    """
    Extract the compile output block from an integration worker summary.

    Fallback levels:
    1. Standard <<FINAL_COMPILE_OUTPUT>> ... <<END_FINAL_COMPILE_OUTPUT>> block
    2. Raw text that contains "compile_status:" line
    3. Synthetic FAILED placeholder
    """
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
    return ARCHITECT_DISPATCH_CONTRACT.render()


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
            "- if repeated compile errors do not change => need_human_guidance",
            "- if task mismatch => wrong_agent",
        ]
    )


def build_tester_dispatch_description() -> str:
    return TESTER_DISPATCH_CONTRACT.render()


def build_review_executor_dispatch_description() -> str:
    return "\n".join(
        [
            "Run execute-test stage right after coder integration is successful.",
            "Input roots:",
            "- /user_input",
            "- /projects",
            "Requirements:",
            "- infer bundle_name from /projects/<project>/AppScope/app.json5 when not provided",
            "- infer ability_name from /projects/<project>/entry/src/main/module.json5 when possible",
            "- infer hap path under /projects/<project>/entry/build/default/outputs/default when not provided",
            "- must call run_review_node_with_inputs(...)",
            "Expected output:",
            "- /reports/test_result.json",
        ]
    )


def build_flow_summary_dispatch_description() -> str:
    return "\n".join(
        [
            "Run flow summary stage from latest review outputs.",
            "Requirements:",
            "- must call summarize_review_features_by_page(review_output_dir='/reports')",
            "- summarize per-page features first, then navigation/jump features from report.txt",
            "Expected output:",
            "- summary markdown path under latest review output directory",
        ]
    )


def build_visual_review_dispatch_description() -> str:
    return "\n".join(
        [
            "Run visual review stage after flow summary.",
            "Requirements:",
            "- must call run_visual_review_with_inputs(review_output_dir='/reports', architect_output_path='/designs/architect.json', user_input_dir='/user_input')",
            "- prefer expected assets from architect image_assets, fallback to rebuilding from /user_input",
            "Expected output:",
            "- visual review json path under latest review output directory",
        ]
    )


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
            "trigger: architect_design_ready",
            "inputs:",
            "- /designs/architect_index.json",
            "- /designs/pages/<page_id>.json  # replace <page_id> with each actual page id",
            "required_outputs:",
            "- /designs/coder_page_tasks.json",
            "done_criteria:",
            "- skeleton stage owns project bootstrap, page registration, and page-task planning",
            "- save /designs/coder_page_tasks.json before page implementation begins",
            "fallback:",
            "- if task mismatch => wrong_agent",
            "- if missing critical skeleton inputs => need_human_guidance",
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
            "Read required input files yourself:",
            "- /designs/architect_index.json",
            "- /designs/pages/<page_id>.json  # replace <page_id> with each actual page id from architect_index",
        ]
    )


def _build_coder_skeleton_result_prompt(
    architect_payload: dict,
    task_type: Literal["implementation", "fix_from_test"],
    agent_summary: str,
) -> str:
    return "\n".join(
        [
            "Summarize the skeleton worker result into structured CoderSkeletonOutput.",
            "Use /designs/architect_index.json and /designs/pages/<page_id>.json as the source of truth for pages and product structure.",
            "Preserve unified navigation scaffolding for multi-page projects.",
            "",
            f"task_type: {task_type}",
            "",
            "Read required input files yourself:",
            "- /designs/architect_index.json",
            "- /designs/pages/<page_id>.json  # replace <page_id> with each actual page id",
            "",
            "Skeleton worker summary:",
            agent_summary or "(empty)",
        ]
    )


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
    page_id = str(task_payload.get("page_id") or "")
    sections = [
        build_coder_dispatch_description(task_type=task_type),
        "",
        "You are executing one page implementation task only.",
        f"target_page_name: {str(task_payload.get('page_name') or '')}",
        f"target_page_id: {page_id}",
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
        "- /designs/architect_index.json",
        f"- /designs/pages/{page_id}.json  # your assigned page design file",
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
    prev_compile_feedback: str | None = None,
    round_idx: int = 1,
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
        f"integration_round: {round_idx}",
        "You are executing the integration stage only.",
        "Skill usage is mandatory before fixing ArkTS / ArkUI engineering issues.",
        "Resolve shared contract mismatches, import/export issues, route registration gaps, and naming inconsistencies.",
        "You own the compile-fix loop in this stage.",
        "Run compile_project yourself first. If compile fails, fix the issue and compile again until success or until the main error stops changing.",
        "Your final response must include a short human summary and a final compile output block "
        "wrapped exactly with <<FINAL_COMPILE_OUTPUT>> and <<END_FINAL_COMPILE_OUTPUT>>.",
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
        "- /designs/architect_index.json",
        "- /designs/pages/<page_id>.json  # replace <page_id> with each actual page id",
    ]
    if tester_report_payload is not None:
        sections.extend(
            [
                "",
                "Optional input path:",
                "- /logs/tester/latest_tester_report.json",
            ]
        )
    if prev_compile_feedback:
        sections.extend(
            [
                "",
                f"Previous round ({round_idx - 1}) compile output (fix these errors in this round):",
                "```",
                prev_compile_feedback,
                "```",
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
# Payload loaders
# ---------------------------------------------------------------------------



def load_architect_index_payload() -> dict:
    return json.loads(
        resolve_workspace_path("/designs/architect_index.json").read_text(encoding="utf-8")
    )


def load_architect_page_payloads() -> list[dict]:
    pages_dir = resolve_workspace_path("/designs/pages")
    if not pages_dir.exists() or not pages_dir.is_dir():
        return []
    return [
        json.loads(p.read_text(encoding="utf-8"))
        for p in sorted(pages_dir.glob("*.json"))
    ]


def load_architect_design_payload() -> dict:
    return {
        "index": load_architect_index_payload(),
        "pages": load_architect_page_payloads(),
    }


def load_tester_report_payload() -> dict:
    return json.loads(
        resolve_workspace_path("/logs/tester/latest_tester_report.json").read_text(
            encoding="utf-8"
        )
    )

# ---------------------------------------------------------------------------
# Coder skeleton stage
# ---------------------------------------------------------------------------

def invoke_coder_skeleton_result_formatter(
    architect_payload: dict,
    task_type: Literal["implementation", "fix_from_test"],
    agent_summary: str,
) -> dict:
    """
    Fallback: re-format a skeleton worker text summary into CoderSkeletonOutput.
    Only called when the agent did not emit a structured_response.
    """
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
    """
    Run the skeleton worker subagent and return (skeleton_payload, agent_summary).

    Structured response from the agent is preferred over a secondary LLM
    re-formatting call to avoid information loss and unnecessary token spend.
    """
    result = _invoke_subagent(
        get_coder_skeleton_worker(),
        build_coder_skeleton_planning_prompt(
            architect_payload=architect_payload, task_type=task_type
        ),
        runtime,
    )
    agent_summary = _result_text(result)

    # Prefer the structured tool-call output emitted by the agent
    structured = _extract_structured_response(result)
    if (
        structured is not None
        and isinstance(structured, dict)
        and structured.get("page_tasks")
    ):
        payload = _normalize_coder_skeleton_tool_args(structured)
        return payload, agent_summary

    # Fallback: derive structured output from the text summary via a second LLM call
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
    )
    tool_args = extract_tool_call_args(llm_response, tool_name)
    if tool_args is not None:
        return tool_args
    raise ValueError(
        "Coder page worker result requires tool-call output from CoderPageWorkerResult"
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


def _page_slice_for_task(architect_payload: dict, page_name: str) -> dict:
    for page in architect_payload.get("pages", []) or []:
        if str(page.get("page_name") or "") == page_name:
            return page
        if str(page.get("page_id") or "") == page_name:
            return page
        if str(page.get("name") or "") == page_name:
            return page
    return {"page_name": page_name}


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
            architect_page_payload=_page_slice_for_task(
                architect_payload, str(task_payload.get("page_name") or "")
            ),
            skeleton_payload=skeleton_payload,
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
    task_bundle: dict, tester_report_payload: dict | None = None
) -> list[dict]:
    tasks = list(task_bundle.get("tasks") or task_bundle.get("page_tasks") or [])
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
    selected_tasks = _select_page_tasks(task_bundle, tester_report_payload=tester_report_payload)
    results: list[dict] = []

    if not selected_tasks:
        bundle = {"project_name": skeleton_payload["project_name"], "results": results}
        save_coder_page_worker_results_payload(bundle)
        return bundle

    max_workers = min(4, max(1, len(selected_tasks)))
    with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = {
            executor.submit(
                _run_single_page_worker,
                task_payload=task,
                skeleton_payload=skeleton_payload,
                architect_payload=architect_payload,
                runtime=runtime,
                task_type=task_type,
                tester_report_payload=tester_report_payload,
            ): task
            for task in selected_tasks
        }
        for future, task in futures.items():
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
    )
    tool_args = extract_tool_call_args(llm_response, tool_name)
    if tool_args is not None:
        return tool_args

    # Fallback: synthesize report from parsed compile output
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
        "next_recommended_agent": "tester" if success else "human",
    }


def run_coder_integration(
    *,
    task_type: Literal["implementation", "fix_from_test"],
    skeleton_payload: dict,
    page_results_payload: dict,
    runtime: ToolRuntime,
    tester_report_payload: dict | None = None,
) -> dict:
    """
    Run the integration worker with an outer compile-fix loop.

    Termination conditions (first satisfied wins):
    1. compile_status == SUCCESS
    2. Error signature unchanged for STALL_THRESHOLD consecutive rounds
    3. Round count reaches MAX_ROUNDS
    """
    worker_summaries: list[str] = []
    attempt_records: list[dict[str, Any]] = []
    modified_files = sorted(
        {
            path
            for r in list(page_results_payload.get("results") or [])
            for path in list(r.get("modified_files") or [])
        }
    )

    prev_signature: str | None = None
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
                skeleton_payload=skeleton_payload,
                page_results_payload=page_results_payload,
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
        signature = _compile_status_signature(compile_feedback)

        attempt = build_coder_compile_fix_attempt_payload(
            attempt_index=round_idx,
            task_type=task_type,
            project_name=skeleton_payload["project_name"],
            compile_status=parsed_compile["compile_status"],
            error_signature=signature,
            key_errors=parsed_compile["key_errors"],
            worker_summary=_strip_compile_output_block(raw_summary) or "integration worker executed",
            worker_summaries_so_far=[s for s in worker_summaries if s],
            modified_files=modified_files,
            fixes_applied=[s for s in worker_summaries if s],
            skills_referenced=["/skills/harmony-next/SKILL.md"],
        )
        append_coder_compile_fix_attempt(attempt)
        attempt_records.append(attempt)

        if parsed_compile["compile_status"] == "SUCCESS":
            break

        if signature == prev_signature:
            stall_count += 1
            if stall_count >= _INTEGRATION_STALL_THRESHOLD:
                break
        else:
            stall_count = 0
        prev_signature = signature

    # Back-fill resolved_in_next_attempt and final_success
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
            "project_name": skeleton_payload["project_name"],
            "task_type": task_type,
            "attempts": attempt_records,
            "final_compile_status": parsed_compile["compile_status"],
            "final_success": final_success,
        }
    )

    report = invoke_coder_integration_report_formatter(
        project_name=skeleton_payload["project_name"],
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

    # Distinguish missing file (re-run skeleton) from corrupted file (hard error)
    task_bundle: dict | None = None
    tasks_path = resolve_workspace_path("/designs/coder_page_tasks.json")
    if tasks_path.exists():
        try:
            task_bundle = load_coder_page_task_bundle_payload()
        except json.JSONDecodeError as exc:
            raise RuntimeError(
                f"coder_page_tasks.json exists but contains invalid JSON: {exc}"
            ) from exc

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


#j旧版串行得多轮调用，现改为单轮调用，工具内完成串行逻辑
"""
@tool
def dispatch_architect(runtime: ToolRuntime) -> Command:
    #Dispatch the architect stage: stage 1 (per-image UI tree drafts) then stage 2 (merge + navigation).
    if not runtime.tool_call_id:
        raise ValueError("Tool call ID is required for architect dispatch")

    session_token = set_current_session_id(_runtime_thread_id(runtime))
    try:
        result = _invoke_subagent(
            get_architect_agent(),
            build_architect_dispatch_description(),
            runtime,
        )

        structured = _extract_structured_response(result)
        final_message = _result_text(result).strip()

        return _command_from_result(
            {"messages": [], "structured_response": structured},
            runtime.tool_call_id,
            final_message_override=final_message or "architect stage completed",
        )
    finally:
        reset_current_session_id(session_token)

"""
@tool
def dispatch_architect(runtime: ToolRuntime) -> Command:
    """Dispatch the architect stage: stage 1 (per-image UI tree drafts) then stage 2 (merge + navigation)."""
    if not runtime.tool_call_id:
        raise ValueError("Tool call ID is required for architect dispatch")

    session_token = set_current_session_id(_runtime_thread_id(runtime))
    try:
        # ---- 阶段一：代码并发提取，不经过 Agent ----
        stage1_result = batch_extract_page_drafts()

        # ---- 阶段二：Agent 驱动归并 ----
        result = _invoke_subagent(
            get_architect_agent(),
            "\n\n".join([
                build_architect_dispatch_description(),
                "【阶段一已由代码完成，请直接执行阶段二】",
                "读取 /designs/page_drafts_index.json，完成页面归并和导航推断，调用 save_architect_design 落盘。",
                f"阶段一结果：\n{stage1_result}",
            ]),
            runtime,
        )

        structured = _extract_structured_response(result)
        final_message = _result_text(result).strip()

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
        architect_payload = load_architect_design_payload()
        skeleton_payload, worker_summary = run_coder_skeleton_stage(
            architect_payload=architect_payload,
            task_type=task_type,
            runtime=runtime,
        )
        skeleton_plan_saved = _coder_page_tasks_path().exists()
        final_message = json.dumps(
            {
                "project_name": skeleton_payload["project_name"],
                "skeleton_plan_saved": skeleton_plan_saved,
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
    """Run page worker tasks from the materialized skeleton artifacts."""
    if runtime is None or not runtime.tool_call_id:
        raise ValueError("Tool call ID is required for page coder dispatch")

    session_token = set_current_session_id(_runtime_thread_id(runtime))
    try:
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

    result = _invoke_subagent(
        get_coder_orchestrator(),
        build_coder_dispatch_description(task_type=task_type),
        runtime,
    )
    try:
        integration_report = load_coder_integration_report_payload()
        final_message_override = json.dumps(integration_report, ensure_ascii=False, indent=2)
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


@tool
def dispatch_review_executor(runtime: ToolRuntime) -> Command:
    """Dispatch execute-test stage using deepagents review executor logic."""
    if not runtime.tool_call_id:
        raise ValueError("Tool call ID is required for review executor dispatch")

    result = _invoke_subagent(
        get_review_executor_agent(),
        build_review_executor_dispatch_description(),
        runtime,
    )
    return _command_from_result(result, runtime.tool_call_id)


@tool
def dispatch_flow_summary(runtime: ToolRuntime) -> Command:
    """Dispatch flow summary stage based on latest review outputs."""
    if not runtime.tool_call_id:
        raise ValueError("Tool call ID is required for flow summary dispatch")

    result = _invoke_subagent(
        get_flow_summary_agent(),
        build_flow_summary_dispatch_description(),
        runtime,
    )
    return _command_from_result(result, runtime.tool_call_id)


@tool
def dispatch_visual_review(runtime: ToolRuntime) -> Command:
    """Dispatch visual review stage based on latest review outputs."""
    if not runtime.tool_call_id:
        raise ValueError("Tool call ID is required for visual review dispatch")

    result = _invoke_subagent(
        get_visual_review_agent(),
        build_visual_review_dispatch_description(),
        runtime,
    )
    return _command_from_result(result, runtime.tool_call_id)


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
    dispatch_review_executor,
    dispatch_flow_summary,
    dispatch_visual_review,
]
