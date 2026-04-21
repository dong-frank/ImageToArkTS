from __future__ import annotations

import json
import re
import shutil
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from langchain.tools import tool
from pydantic import BaseModel

from schemas import (
    CoderCompileFixAttempt,
    CoderCompileFixTrace,
)
from tools.common import PROJECT_ROOT, resolve_workspace_path, workspace_root
from tools.project_tools import TEMPLATE_IGNORE_PATTERNS, TEMPLATE_PROJECT_DIR
from utils.session_context import get_current_session_id

# ---------------------------------------------------------------------------
# Session-scoped path helpers
# ---------------------------------------------------------------------------


def _resolve_session_path(raw_path: str, project_root: Path | None = None) -> Path:
    if project_root is None:
        return resolve_workspace_path(raw_path)
    return (
        project_root
        / "agent_workspace"
        / "sessions"
        / get_current_session_id()
        / raw_path.lstrip("/")
    )


def _coder_page_tasks_path(project_root: Path | None = None) -> Path:
    return _resolve_session_path("/designs/coder_page_tasks.json", project_root=project_root)


def _coder_page_worker_results_path(project_root: Path | None = None) -> Path:
    return _resolve_session_path(
        "/logs/coder/page_worker_results.json", project_root=project_root
    )


def _coder_integration_report_path(project_root: Path | None = None) -> Path:
    return _resolve_session_path(
        "/logs/coder/integration_report.json", project_root=project_root
    )


def _coder_compile_fix_history_path(project_root: Path | None = None) -> Path:
    return _resolve_session_path(
        "/logs/coder/compile_fix_history.jsonl", project_root=project_root
    )


def _coder_latest_compile_fix_trace_path(project_root: Path | None = None) -> Path:
    return _resolve_session_path(
        "/logs/coder/latest_compile_fix_trace.json", project_root=project_root
    )


def _architect_index_path(project_root: Path | None = None) -> Path:
    return _resolve_session_path("/designs/architect_index.json", project_root=project_root)


def _architect_pages_dir(project_root: Path | None = None) -> Path:
    return _resolve_session_path("/designs/pages", project_root=project_root)


def _workspace_root(project_root: Path | None = None) -> Path:
    if project_root is None:
        return workspace_root()
    return (
        project_root / "agent_workspace" / "sessions" / get_current_session_id()
    )


def _projects_root(project_root: Path | None = None) -> Path:
    return _workspace_root(project_root) / "projects"


def _ensure_parent(path: Path) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    return path


# ---------------------------------------------------------------------------
# Generic payload coercion
# ---------------------------------------------------------------------------


def _coerce_payload(payload: Any) -> dict[str, Any]:
    if isinstance(payload, BaseModel):
        return payload.model_dump(mode="json", exclude_none=True)
    if isinstance(payload, str):
        payload = json.loads(payload)
    if isinstance(payload, dict):
        return payload
    raise ValueError(f"Unsupported payload type: {type(payload).__name__}")


# ---------------------------------------------------------------------------
# Identifier / route helpers
# ---------------------------------------------------------------------------


def _safe_project_name(value: str | None) -> str:
    raw = (value or "").strip().lower()
    raw = re.sub(r"[^a-z0-9_]+", "_", raw)
    raw = re.sub(r"_+", "_", raw).strip("_")
    if not raw:
        return "app_project"
    if not re.match(r"^[a-z]", raw):
        raw = f"app_{raw}"
    return raw[:200]


def _safe_identifier(value: str | None, fallback: str = "page") -> str:
    raw = (value or "").strip().lower()
    raw = re.sub(r"[^a-z0-9_]+", "_", raw)
    raw = re.sub(r"_+", "_", raw).strip("_")
    return raw or fallback


def _page_component_name(page_name: str) -> str:
    words = re.split(r"[^A-Za-z0-9]+", str(page_name or "Page"))
    cleaned = [w for w in words if w]
    return "".join(word[:1].upper() + word[1:] for word in cleaned) or "Page"


def _route_to_component_name(route: str | None, fallback_page_name: str) -> str:
    raw = str(route or "").strip()
    if not raw:
        return _page_component_name(fallback_page_name)
    tail = raw.split("/")[-1]
    return _page_component_name(tail)


def _normalize_route(route: str | None, page_name: str, page_id: str) -> str:
    """
    Normalize an architect-provided route value into a valid HarmonyOS page route.

    Rules (kept in sync with routing_tools._normalize_route):
    - Must start with "pages/"
    - Tail must be a valid identifier; PascalCase is preferred
    - Leading slashes are stripped
    - Fallback: derive PascalCase name from page_id or page_name
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


def _design_page_file_path(page_id: str) -> str:
    return f"/designs/pages/{page_id}.json"


def _code_page_file_path(project_name: str, component_name: str) -> str:
    return f"/projects/{project_name}/entry/src/main/ets/pages/{component_name}.ets"


# ---------------------------------------------------------------------------
# Payload persistence helpers
# ---------------------------------------------------------------------------


def save_coder_page_task_bundle_payload(
    payload: Any, project_root: Path | None = None
) -> str:
    normalized = _coerce_payload(payload)
    path = _ensure_parent(_coder_page_tasks_path(project_root=project_root))
    path.write_text(json.dumps(normalized, ensure_ascii=False, indent=2), encoding="utf-8")
    return f"coder page task bundle saved to {path}"


def save_coder_page_worker_results_payload(
    payload: Any, project_root: Path | None = None
) -> str:
    normalized = _coerce_payload(payload)
    path = _ensure_parent(_coder_page_worker_results_path(project_root=project_root))
    path.write_text(json.dumps(normalized, ensure_ascii=False, indent=2), encoding="utf-8")
    return f"coder page worker results saved to {path}"


def save_coder_integration_report_payload(
    payload: Any, project_root: Path | None = None
) -> str:
    normalized = _coerce_payload(payload)
    path = _ensure_parent(_coder_integration_report_path(project_root=project_root))
    path.write_text(json.dumps(normalized, ensure_ascii=False, indent=2), encoding="utf-8")
    return f"coder integration report saved to {path}"


def load_coder_page_task_bundle_payload(
    project_root: Path | None = None,
) -> dict[str, Any]:
    payload = json.loads(
        _coder_page_tasks_path(project_root=project_root).read_text(encoding="utf-8")
    )
    # Unified read: "tasks" is the canonical key; "page_tasks" is the legacy fallback.
    if "tasks" not in payload:
        if "page_tasks" in payload:
            payload["tasks"] = list(payload["page_tasks"] or [])
        else:
            payload["tasks"] = []
    else:
        payload["tasks"] = list(payload["tasks"] or [])
    return payload


def load_coder_page_worker_results_payload(
    project_root: Path | None = None,
) -> dict[str, Any]:
    return json.loads(
        _coder_page_worker_results_path(project_root=project_root).read_text(
            encoding="utf-8"
        )
    )


def load_coder_integration_report_payload(
    project_root: Path | None = None,
) -> dict[str, Any]:
    return json.loads(
        _coder_integration_report_path(project_root=project_root).read_text(
            encoding="utf-8"
        )
    )


def append_coder_compile_fix_attempt(
    payload: Any, project_root: Path | None = None
) -> str:
    normalized = _coerce_payload(payload)
    path = _ensure_parent(_coder_compile_fix_history_path(project_root=project_root))
    with path.open("a", encoding="utf-8") as fp:
        fp.write(json.dumps(normalized, ensure_ascii=False) + "\n")
    return f"coder compile fix attempt appended to {path}"


def save_coder_compile_fix_trace_payload(
    payload: Any, project_root: Path | None = None
) -> str:
    normalized = _coerce_payload(payload)
    path = _ensure_parent(_coder_latest_compile_fix_trace_path(project_root=project_root))
    path.write_text(json.dumps(normalized, ensure_ascii=False, indent=2), encoding="utf-8")
    return f"coder compile fix trace saved to {path}"


def load_coder_compile_fix_trace_payload(
    project_root: Path | None = None,
) -> dict[str, Any]:
    return json.loads(
        _coder_latest_compile_fix_trace_path(project_root=project_root).read_text(
            encoding="utf-8"
        )
    )


def load_coder_compile_fix_history_payload(
    project_root: Path | None = None,
) -> list[dict[str, Any]]:
    path = _coder_compile_fix_history_path(project_root=project_root)
    if not path.exists():
        return []
    lines = [
        line.strip()
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]
    return [json.loads(line) for line in lines]


def load_architect_index_payload(
    project_root: Path | None = None,
) -> dict[str, Any]:
    return json.loads(
        _architect_index_path(project_root=project_root).read_text(encoding="utf-8")
    )


def load_architect_pages_payload(
    project_root: Path | None = None,
) -> list[dict[str, Any]]:
    pages_dir = _architect_pages_dir(project_root=project_root)
    if not pages_dir.exists():
        return []
    return [
        json.loads(p.read_text(encoding="utf-8"))
        for p in sorted(pages_dir.glob("*.json"))
    ]


# ---------------------------------------------------------------------------
# Compile output helpers (kept in sync with routing_tools)
# ---------------------------------------------------------------------------


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

    for raw_line in str(compile_output).splitlines():
        line = raw_line.strip()
        if line.startswith("compile_status:"):
            compile_status = line.split(":", 1)[1].strip()
        elif line.startswith("project_name:"):
            project_name = line.split(":", 1)[1].strip()
        elif line.startswith("project_path:"):
            project_path = line.split(":", 1)[1].strip()
        elif line == "key_errors:":
            in_errors = True
        elif line in ("recent_log_tail:", "") and in_errors:  # guard: only exit when inside errors block
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
    2. Raw text that contains a "compile_status:" line
    3. Synthetic FAILED placeholder
    """
    text = str(agent_summary or "")

    match = re.search(
        r"<<FINAL_COMPILE_OUTPUT>>\s*(.*?)\s*<<END_FINAL_COMPILE_OUTPUT>>",
        text,
        re.DOTALL,
    )
    if match:
        return match.group(1).strip()

    if "compile_status:" in text:
        return text.strip()

    return (
        "compile_status: FAILED\n"
        "key_errors:\n"
        "- integration worker did not return a compile output block\n"
    )


# ---------------------------------------------------------------------------
# Compile fix attempt record builder
# ---------------------------------------------------------------------------


def build_coder_compile_fix_attempt_payload(
    *,
    attempt_index: int,
    task_type: str,
    project_name: str,
    compile_status: str,
    error_signature: str,
    key_errors: list[str],
    worker_summary: str,
    worker_summaries_so_far: list[str],
    modified_files: list[str],
    fixes_applied: list[str],
    skills_referenced: list[str],
    resolved_in_next_attempt: bool | None = None,
    final_success: bool | None = None,
) -> dict[str, Any]:
    return {
        "attempt_index": attempt_index,
        "timestamp": datetime.now(timezone.utc).isoformat(timespec="milliseconds"),
        "task_type": task_type,
        "project_name": project_name,
        "compile_status": compile_status,
        "error_signature": error_signature or "unknown",
        "key_errors": list(key_errors or []),
        "worker_summary": worker_summary or "",
        "worker_summaries_so_far": list(worker_summaries_so_far or []),
        "modified_files": list(modified_files or []),
        "fixes_applied": list(fixes_applied or []),
        "skills_referenced": list(skills_referenced or []),
        "resolved_in_next_attempt": resolved_in_next_attempt,
        "final_success": final_success,
    }


# ---------------------------------------------------------------------------
# Project template helpers
# ---------------------------------------------------------------------------


def _copy_template_project(
    project_name: str, project_root: Path | None = None
) -> Path:
    target_dir = _projects_root(project_root) / project_name
    if target_dir.exists():
        return target_dir
    target_dir.parent.mkdir(parents=True, exist_ok=True)
    shutil.copytree(TEMPLATE_PROJECT_DIR, target_dir, ignore=TEMPLATE_IGNORE_PATTERNS)
    return target_dir


def _update_app_strings(project_dir: Path, app_display_name: str) -> None:
    string_path = project_dir / "AppScope/resources/base/element/string.json"
    if not string_path.exists():
        return
    data = json.loads(string_path.read_text(encoding="utf-8"))
    entries = data.setdefault("string", [])
    for entry in entries:
        if entry.get("name") == "app_name":
            entry["value"] = app_display_name
            break
    else:
        entries.append({"name": "app_name", "value": app_display_name})
    string_path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")


def _write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


# ---------------------------------------------------------------------------
# ArkTS skeleton template renderers
# ---------------------------------------------------------------------------


def _render_navigation_import_block(include_navigation: bool) -> str:
    if not include_navigation:
        return ""
    return (
        "import { BottomNavBar } from '../common/components/BottomNavBar';\n"
        "import { NavigationService } from '../common/services/NavigationService';\n\n"
    )


def _render_navigation_usage(page_name: str, include_navigation: bool) -> str:
    if not include_navigation:
        return ""
    return (
        "      Blank()\n"
        "      BottomNavBar({\n"
        f"        currentPage: '{page_name}',\n"
        "        tabs: NavigationService.primaryPageNames()\n"
        "      })\n"
    )


def _render_page_placeholder(
    page_name: str,
    responsibilities: str,
    app_display_name: str,
    include_navigation: bool = False,
) -> str:
    component_name = _page_component_name(page_name)
    title = responsibilities or f"{page_name} page"
    return (
        f"{_render_navigation_import_block(include_navigation)}"
        f"@Component\n"
        f"struct {component_name} {{\n"
        f"  build() {{\n"
        f"    Column({{ space: 12 }}) {{\n"
        f"      Text('{app_display_name}')\n"
        f"        .fontSize(24)\n"
        f"        .fontWeight(FontWeight.Bold)\n"
        f"      Text('{title}')\n"
        f"        .fontSize(16)\n"
        f"        .fontColor('#666666')\n"
        f"{_render_navigation_usage(page_name, include_navigation)}"
        f"    }}\n"
        f"    .width('100%')\n"
        f"    .height('100%')\n"
        f"    .padding(16)\n"
        f"    .justifyContent(FlexAlign.Start)\n"
        f"  }}\n"
        f"}}\n"
    )


def _render_entry_page(
    page_name: str,
    responsibilities: str,
    app_display_name: str,
    include_navigation: bool = False,
) -> str:
    component_name = _page_component_name(page_name)
    title = responsibilities or f"{page_name} page"
    return (
        f"{_render_navigation_import_block(include_navigation)}"
        f"@Entry\n"
        f"@Component\n"
        f"struct {component_name} {{\n"
        f"  build() {{\n"
        f"    Column({{ space: 12 }}) {{\n"
        f"      Text('{app_display_name}')\n"
        f"        .fontSize(24)\n"
        f"        .fontWeight(FontWeight.Bold)\n"
        f"      Text('{title}')\n"
        f"        .fontSize(16)\n"
        f"        .fontColor('#666666')\n"
        f"{_render_navigation_usage(page_name, include_navigation)}"
        f"    }}\n"
        f"    .width('100%')\n"
        f"    .height('100%')\n"
        f"    .padding(16)\n"
        f"    .justifyContent(FlexAlign.Start)\n"
        f"  }}\n"
        f"}}\n"
    )


def _render_shared_component(name: str, description: str) -> str:
    component_name = _page_component_name(name)
    if component_name == "BottomNavBar":
        return (
            "@Component\n"
            "export struct BottomNavBar {\n"
            "  @Prop currentPage: string = '';\n"
            "  @Prop tabs: string[] = [];\n"
            "\n"
            "  build() {\n"
            "    Row({ space: 8 }) {\n"
            "      ForEach(this.tabs, (tab: string) => {\n"
            "        Text(tab)\n"
            "          .fontSize(14)\n"
            "          .fontWeight(this.currentPage === tab ? FontWeight.Bold : FontWeight.Regular)\n"
            "          .fontColor(this.currentPage === tab ? '#111111' : '#888888')\n"
            "      })\n"
            "    }\n"
            "    .width('100%')\n"
            "    .justifyContent(FlexAlign.SpaceAround)\n"
            "    .padding({ top: 12, bottom: 12 })\n"
            "  }\n"
            "}\n"
        )
    text = description or name
    return (
        f"@Component\n"
        f"export struct {component_name} {{\n"
        f"  build() {{\n"
        f"    Row() {{\n"
        f"      Text('{text}')\n"
        f"        .fontSize(18)\n"
        f"        .fontWeight(FontWeight.Medium)\n"
        f"    }}\n"
        f"    .width('100%')\n"
        f"  }}\n"
        f"}}\n"
    )


def _render_navigation_service(route_table: list[dict[str, Any]]) -> str:
    tabs = [
        str(item.get("page_name") or "")
        for item in route_table
        if str(item.get("page_name") or "").strip()
    ]
    unique_tabs: list[str] = []
    for tab in tabs:
        if tab not in unique_tabs:
            unique_tabs.append(tab)

    tab_lines = (
        ",\n".join(f"      '{tab}'" for tab in unique_tabs)
        if unique_tabs
        else "      'Index'"
    )
    cases = "\n".join(
        f"      case '{str(item.get('page_name') or '')}':\n"
        f"        return '{str(item.get('route') or '')}';"
        for item in route_table
        if str(item.get("page_name") or "").strip()
        and str(item.get("route") or "").strip()
    )
    if not cases:
        cases = "      default:\n        return 'pages/index'"

    return (
        "export class NavigationService {\n"
        "  static primaryPageNames(): string[] {\n"
        "    return [\n"
        f"{tab_lines}\n"
        "    ];\n"
        "  }\n"
        "\n"
        "  static routeFor(pageName: string): string {\n"
        "    switch (pageName) {\n"
        f"{cases}\n"
        "      default:\n"
        "        return 'pages/index';\n"
        "    }\n"
        "  }\n"
        "}\n"
    )


def _render_store_file(
    store_name: str,
    state: list[str],
    actions: list[str],
    responsibilities: str,
) -> str:
    state_lines = (
        "\n".join(f"  @State {name}: string = '';" for name in state)
        if state
        else "  @State status: string = '';"
    )
    action_lines = (
        "\n".join(
            f"  {action}(value: string): void {{\n"
            f"    this.{state[0] if state else 'status'} = value;\n"
            f"  }}"
            for action in actions
        )
        if actions
        else "  setStatus(value: string): void {\n    this.status = value;\n  }"
    )
    desc = responsibilities or "manage shared state"
    return (
        f"@Observed\n"
        f"export class {store_name} {{\n"
        f"{state_lines}\n"
        f"\n"
        f"  readonly responsibilities: string = '{desc}';\n"
        f"\n"
        f"{action_lines}\n"
        f"}}\n"
    )


def _render_data_model_file(models: list[dict[str, Any]]) -> str:
    lines = ["export interface AppDataModel {"]
    if not models:
        lines.append("  placeholder?: string;")
    else:
        for item in models:
            field = str(item.get("field") or "value")
            field_type = str(item.get("type") or "string")
            lines.append(f"  {field}: {field_type};")
    lines.append("}")
    lines.append("")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Route table + entry task helpers
# ---------------------------------------------------------------------------


def _route_table_from_page_tasks(
    page_tasks: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    return [
        {
            "page_id": str(task.get("page_id") or ""),
            "page_name": str(task.get("page_name") or ""),
            "route": str(
                task.get("route")
                or f"pages/{_safe_identifier(task.get('page_id') or task.get('page_name'), fallback='index')}"
            ),
            "page_file": str(task.get("page_file") or ""),
        }
        for task in page_tasks
    ]


# Entry role / route constants — kept in sync with routing_tools
_ENTRY_ROLES: frozenset[str] = frozenset({"entry"})
_ENTRY_ROUTES: frozenset[str] = frozenset(
    {"pages/index", "pages/home", "pages/homepage", "pages/main"}
)


def _infer_entry_task(
    page_tasks: list[dict[str, Any]],
) -> dict[str, Any] | None:
    """
    Select the entry page task from a list of page tasks.

    Priority (kept in sync with routing_tools._infer_entry_task):
    1. role == "entry"  (Schema-defined canonical value only)
    2. route matches known entry route patterns
    3. First task as final fallback
    """
    if not page_tasks:
        return None

    for task in page_tasks:
        if str(task.get("role") or "").strip().lower() in _ENTRY_ROLES:
            return task

    for task in page_tasks:
        if str(task.get("route") or "").strip().lower() in _ENTRY_ROUTES:
            return task

    return page_tasks[0]


# ---------------------------------------------------------------------------
# Project file writers
# ---------------------------------------------------------------------------


def _write_main_pages_json(
    project_dir: Path, route_table: list[dict[str, Any]]
) -> None:
    path = project_dir / "entry/src/main/resources/base/profile/main_pages.json"
    payload = {
        "src": [str(item.get("route") or "pages/index") for item in route_table]
    }
    _write_text(path, json.dumps(payload, ensure_ascii=False, indent=2))


def _write_navigation_scaffold(
    project_dir: Path, route_table: list[dict[str, Any]]
) -> list[str]:
    component_dir = project_dir / "entry/src/main/ets/common/components"
    service_dir = project_dir / "entry/src/main/ets/common/services"

    bottom_nav_path = component_dir / "BottomNavBar.ets"
    nav_service_path = service_dir / "NavigationService.ets"

    _write_text(
        bottom_nav_path,
        _render_shared_component("BottomNavBar", "Shared bottom navigation"),
    )
    _write_text(nav_service_path, _render_navigation_service(route_table))

    return [str(bottom_nav_path), str(nav_service_path)]


def _write_page_placeholders(
    project_dir: Path,
    page_tasks: list[dict[str, Any]],
    app_display_name: str,
) -> list[str]:
    written: list[str] = []
    entry_task = _infer_entry_task(page_tasks)
    include_navigation = len(page_tasks) > 1

    for task in page_tasks:
        page_name = str(task.get("page_name") or task.get("page_id") or "Page")
        responsibilities = str(
            task.get("summary") or task.get("responsibilities") or ""
        )
        page_file = str(task.get("page_file") or "").strip()
        if not page_file:
            continue

        # Derive the path relative to the project root
        relative = page_file.replace("/projects/", "", 1)
        project_relative = relative.split("/", 1)[1] if "/" in relative else relative
        file_path = project_dir / project_relative

        if entry_task is not None and task is entry_task:
            content = _render_entry_page(
                page_name=page_name,
                responsibilities=responsibilities,
                app_display_name=app_display_name,
                include_navigation=include_navigation,
            )
        else:
            content = _render_page_placeholder(
                page_name=page_name,
                responsibilities=responsibilities,
                app_display_name=app_display_name,
                include_navigation=include_navigation,
            )

        _write_text(file_path, content)
        written.append(str(file_path))

    return written


# ---------------------------------------------------------------------------
# Skeleton seed builder (from architect design files)
# ---------------------------------------------------------------------------


def build_coder_skeleton_seed_from_architect(
    project_root: Path | None = None,
) -> dict[str, Any]:
    architect_index_payload = load_architect_index_payload(project_root=project_root)
    architect_pages_payload = load_architect_pages_payload(project_root=project_root)

    index = architect_index_payload.get("index", architect_index_payload)
    project_name = _safe_project_name(index.get("project_name") or "app_project")
    app_display_name = str(index.get("app_display_name") or project_name)

    # Build a lookup from page_id → page_index item for route/role supplementation
    page_index_lookup: dict[str, dict[str, Any]] = {}
    for item in list(index.get("page_index") or []):
        pid = str(item.get("page_id") or "").strip()
        if pid:
            page_index_lookup[pid] = item

    tasks: list[dict[str, Any]] = []
    for page in architect_pages_payload:
        page_id = _safe_identifier(str(page.get("page_id") or ""), fallback="page")
        idx_item = page_index_lookup.get(page_id, {})

        page_name = str(
            page.get("page_name") or idx_item.get("page_name") or page_id
        ).strip()
        route = _normalize_route(
            page.get("route") or idx_item.get("route"), page_name, page_id
        )
        role = str(page.get("role") or idx_item.get("role") or "").strip()
        summary = str(page.get("summary") or idx_item.get("summary") or "").strip()
        # responsibilities falls back to summary then page_name — must never be empty
        responsibilities = str(
            page.get("responsibilities")
            or idx_item.get("responsibilities")
            or summary
            or page_name
        ).strip()

        component_name = _route_to_component_name(route, page_name)
        page_file = _code_page_file_path(project_name, component_name)
        design_file = str(
            page.get("page_file_path")
            or idx_item.get("file_path")
            or _design_page_file_path(page_id)
        )

        tasks.append(
            {
                "page_id": page_id,
                "page_name": page_name,
                "route": route,
                "role": role,
                "summary": summary,
                "responsibilities": responsibilities,
                "design_file": design_file,
                "page_file": page_file,
                "allowed_write_paths": [page_file],
                "shared_dependencies": [],
                "primary_actions": [],
                "state_notes": None,
            }
        )

    if not tasks:
        fallback_file = _code_page_file_path(project_name, "Index")
        tasks.append(
            {
                "page_id": "index",
                "page_name": "Index",
                "route": "pages/Index",
                "role": "entry",
                "summary": "Default entry page placeholder",
                "responsibilities": "Default entry page placeholder",
                "design_file": _design_page_file_path("index"),
                "page_file": fallback_file,
                "allowed_write_paths": [fallback_file],
                "shared_dependencies": [],
                "primary_actions": [],
                "state_notes": None,
            }
        )

    return {
        "project_name": project_name,
        "app_display_name": app_display_name,
        "page_tasks": tasks,
    }


# ---------------------------------------------------------------------------
# Skeleton materialization entry point
# ---------------------------------------------------------------------------


def materialize_coder_skeleton(
    payload: Any, project_root: Path | None = None
) -> str:
    normalized = _coerce_payload(payload) if payload is not None else {}

    # Fall back to architect design files when payload is incomplete
    if not normalized.get("project_name") or not normalized.get("page_tasks"):
        inferred = build_coder_skeleton_seed_from_architect(project_root=project_root)
        merged = {**inferred, **normalized}
        if not normalized.get("page_tasks"):
            merged["page_tasks"] = inferred["page_tasks"]
        normalized = merged

    project_name = _safe_project_name(normalized["project_name"])
    app_display_name = str(normalized.get("app_display_name") or project_name)
    page_tasks = list(normalized.get("page_tasks") or [])
    route_table = _route_table_from_page_tasks(page_tasks)

    project_dir = _copy_template_project(project_name, project_root=project_root)
    _update_app_strings(project_dir, app_display_name)
    _write_main_pages_json(project_dir, route_table)

    shared_written: list[str] = []
    if len(page_tasks) > 1:
        shared_written = _write_navigation_scaffold(project_dir, route_table)

    page_files_written = _write_page_placeholders(
        project_dir=project_dir,
        page_tasks=page_tasks,
        app_display_name=app_display_name,
    )

    # "tasks" is the canonical key; no legacy "page_tasks" duplication
    page_task_bundle = {
        "project_name": project_name,
        "app_display_name": app_display_name,
        "tasks": page_tasks,
        "generated_route_table": route_table,
        "generated_files": {
            "shared": shared_written,
            "pages": page_files_written,
            "main_pages_json": str(
                project_dir
                / "entry/src/main/resources/base/profile/main_pages.json"
            ),
        },
    }
    save_coder_page_task_bundle_payload(page_task_bundle, project_root=project_root)

    return "\n".join(
        [
            "status: SUCCESS",
            f"project_name: {project_name}",
            f"project_path: /projects/{project_name}",
            f"route_count: {len(route_table)}",
            f"page_task_count: {len(page_tasks)}",
            f"shared_file_count: {len(shared_written)}",
            f"page_file_count: {len(page_files_written)}",
        ]
    )


# ---------------------------------------------------------------------------
# Public tool
# ---------------------------------------------------------------------------


@tool
def materialize_coder_skeleton_artifacts(payload: dict[str, Any]) -> str:
    """
    Materialize the planned skeleton into project files, including page
    registration and shared scaffolding.

    Supports fallback generation from:
    - /designs/architect_index.json
    - /designs/pages/*.json
    """
    return materialize_coder_skeleton(payload)