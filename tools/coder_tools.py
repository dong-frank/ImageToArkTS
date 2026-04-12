from __future__ import annotations

import json
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


def _resolve_session_path(raw_path: str, project_root: Path | None = None) -> Path:
    if project_root is None:
        return resolve_workspace_path(raw_path)
    return project_root / "agent_workspace" / "sessions" / get_current_session_id() / raw_path.lstrip("/")


def _coder_page_tasks_path(project_root: Path | None = None) -> Path:
    return _resolve_session_path("/designs/coder_page_tasks.json", project_root=project_root)


def _coder_page_worker_results_path(project_root: Path | None = None) -> Path:
    return _resolve_session_path("/logs/coder/page_worker_results.json", project_root=project_root)


def _coder_integration_report_path(project_root: Path | None = None) -> Path:
    return _resolve_session_path("/logs/coder/integration_report.json", project_root=project_root)


def _coder_compile_fix_history_path(project_root: Path | None = None) -> Path:
    return _resolve_session_path("/logs/coder/compile_fix_history.jsonl", project_root=project_root)


def _coder_latest_compile_fix_trace_path(project_root: Path | None = None) -> Path:
    return _resolve_session_path("/logs/coder/latest_compile_fix_trace.json", project_root=project_root)


def _workspace_root(project_root: Path | None = None) -> Path:
    if project_root is None:
        return workspace_root()
    return project_root / "agent_workspace" / "sessions" / get_current_session_id()


def _projects_root(project_root: Path | None = None) -> Path:
    return _workspace_root(project_root) / "projects"


def _ensure_parent(path: Path) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    return path


def _coerce_payload(payload: Any) -> dict[str, Any]:
    if isinstance(payload, BaseModel):
        return payload.model_dump(mode="json", exclude_none=True)
    if isinstance(payload, str):
        payload = json.loads(payload)
    if isinstance(payload, dict):
        return payload
    raise ValueError(f"Unsupported payload type: {type(payload).__name__}")


def save_coder_page_task_bundle_payload(payload: Any, project_root: Path | None = None) -> str:
    normalized = _coerce_payload(payload)
    path = _ensure_parent(_coder_page_tasks_path(project_root=project_root))
    path.write_text(json.dumps(normalized, ensure_ascii=False, indent=2), encoding="utf-8")
    return f"coder page task bundle saved to {path}"


def save_coder_page_worker_results_payload(payload: Any, project_root: Path | None = None) -> str:
    normalized = _coerce_payload(payload)
    path = _ensure_parent(_coder_page_worker_results_path(project_root=project_root))
    path.write_text(json.dumps(normalized, ensure_ascii=False, indent=2), encoding="utf-8")
    return f"coder page worker results saved to {path}"


def save_coder_integration_report_payload(payload: Any, project_root: Path | None = None) -> str:
    normalized = _coerce_payload(payload)
    path = _ensure_parent(_coder_integration_report_path(project_root=project_root))
    path.write_text(json.dumps(normalized, ensure_ascii=False, indent=2), encoding="utf-8")
    return f"coder integration report saved to {path}"


def load_coder_page_task_bundle_payload(project_root: Path | None = None) -> dict[str, Any]:
    payload = json.loads(_coder_page_tasks_path(project_root=project_root).read_text(encoding="utf-8"))
    if "tasks" in payload:
        payload["tasks"] = list(payload.get("tasks") or [])
    elif "page_tasks" in payload:
        payload = {
            **payload,
            "tasks": list(payload.get("page_tasks") or []),
        }
    else:
        payload["tasks"] = []
    return payload


def load_coder_page_worker_results_payload(project_root: Path | None = None) -> dict[str, Any]:
    return json.loads(_coder_page_worker_results_path(project_root=project_root).read_text(encoding="utf-8"))


def load_coder_integration_report_payload(project_root: Path | None = None) -> dict[str, Any]:
    return json.loads(_coder_integration_report_path(project_root=project_root).read_text(encoding="utf-8"))


def append_coder_compile_fix_attempt(payload: Any, project_root: Path | None = None) -> str:
    normalized = _coerce_payload(payload)
    path = _ensure_parent(_coder_compile_fix_history_path(project_root=project_root))
    with path.open("a", encoding="utf-8") as fp:
        fp.write(json.dumps(normalized, ensure_ascii=False) + "\n")
    return f"coder compile fix attempt appended to {path}"


def save_coder_compile_fix_trace_payload(payload: Any, project_root: Path | None = None) -> str:
    normalized = _coerce_payload(payload)
    path = _ensure_parent(_coder_latest_compile_fix_trace_path(project_root=project_root))
    path.write_text(json.dumps(normalized, ensure_ascii=False, indent=2), encoding="utf-8")
    return f"coder compile fix trace saved to {path}"


def load_coder_compile_fix_trace_payload(project_root: Path | None = None) -> dict[str, Any]:
    return json.loads(_coder_latest_compile_fix_trace_path(project_root=project_root).read_text(encoding="utf-8"))


def load_coder_compile_fix_history_payload(project_root: Path | None = None) -> list[dict[str, Any]]:
    path = _coder_compile_fix_history_path(project_root=project_root)
    if not path.exists():
        return []
    lines = [line.strip() for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
    return [json.loads(line) for line in lines]


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


def _copy_template_project(project_name: str, project_root: Path | None = None) -> Path:
    target_dir = _projects_root(project_root) / project_name
    if target_dir.exists():
        return target_dir

    target_dir.parent.mkdir(parents=True, exist_ok=True)
    shutil.copytree(TEMPLATE_PROJECT_DIR, target_dir, ignore=TEMPLATE_IGNORE_PATTERNS)
    return target_dir


def _update_app_strings(project_dir: Path, app_display_name: str) -> None:
    app_scope_string_path = project_dir / "AppScope/resources/base/element/string.json"
    if app_scope_string_path.exists():
        data = json.loads(app_scope_string_path.read_text(encoding="utf-8"))
        string_entries = data.setdefault("string", [])
        for entry in string_entries:
            if entry.get("name") == "app_name":
                entry["value"] = app_display_name
                break
        else:
            string_entries.append({"name": "app_name", "value": app_display_name})
        app_scope_string_path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")


def _write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def _page_component_name(page_name: str) -> str:
    return "".join(part for part in str(page_name or "Page").split() if part) or "Page"


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


def _render_page_placeholder(page_name: str, responsibilities: str, app_display_name: str, include_navigation: bool = False) -> str:
    component_name = _page_component_name(page_name)
    title = responsibilities or f"{page_name} page"
    return f"""{_render_navigation_import_block(include_navigation)}@Component
struct {component_name} {{
  build() {{
    Column({{ space: 12 }}) {{
      Text('{app_display_name}')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
      Text('{title}')
        .fontSize(16)
        .fontColor('#666666')
{_render_navigation_usage(page_name, include_navigation)}\
    }}
    .width('100%')
    .height('100%')
    .padding(16)
    .justifyContent(FlexAlign.Start)
  }}
}}
"""


def _render_entry_page(page_name: str, responsibilities: str, app_display_name: str, include_navigation: bool = False) -> str:
    component_name = _page_component_name(page_name)
    title = responsibilities or f"{page_name} page"
    return f"""{_render_navigation_import_block(include_navigation)}@Entry
@Component
struct {component_name} {{
  build() {{
    Column({{ space: 12 }}) {{
      Text('{app_display_name}')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
      Text('{title}')
        .fontSize(16)
        .fontColor('#666666')
{_render_navigation_usage(page_name, include_navigation)}\
    }}
    .width('100%')
    .height('100%')
    .padding(16)
    .justifyContent(FlexAlign.Start)
  }}
}}
"""


def _render_shared_component(name: str, description: str) -> str:
    component_name = _page_component_name(name)
    text = description or name
    if component_name == "BottomNavBar":
        return """@Component
export struct BottomNavBar {
  @Prop currentPage: string = '';
  @Prop tabs: string[] = [];

  build() {
    Row({ space: 8 }) {
      ForEach(this.tabs, (tab: string) => {
        Text(tab)
          .fontSize(14)
          .fontWeight(this.currentPage === tab ? FontWeight.Bold : FontWeight.Regular)
          .fontColor(this.currentPage === tab ? '#111111' : '#888888')
      })
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceAround)
    .padding({ top: 12, bottom: 12 })
  }
}
"""
    return f"""@Component
export struct {component_name} {{
  build() {{
    Row() {{
      Text('{text}')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
    }}
    .width('100%')
  }}
}}
"""


def _render_service_interface(name: str, description: str) -> str:
    interface_name = _page_component_name(name)
    text = description or name
    if interface_name == "NavigationService":
        return _render_navigation_service([])
    return f"""export class {interface_name} {{
  summary(): string {{
    return '{text}';
  }}
}}
"""


def _render_navigation_service(route_table: list[dict[str, Any]]) -> str:
    tabs = [str(item.get("page_name") or "") for item in route_table if str(item.get("page_name") or "").strip()]
    unique_tabs: list[str] = []
    for tab in tabs:
        if tab not in unique_tabs:
            unique_tabs.append(tab)
    tab_lines = ",\n".join(f"      '{tab}'" for tab in unique_tabs) or "      'Index'"
    cases = "\n".join(
        f"      case '{str(item.get('page_name') or '')}':\n        return '{str(item.get('route') or '')}';"
        for item in route_table
        if str(item.get("page_name") or "").strip() and str(item.get("route") or "").strip()
    ) or "      default:\n        return 'pages/Index';"
    return f"""export class NavigationService {{
  static primaryPageNames(): string[] {{
    return [
{tab_lines}
    ];
  }}

  static routeFor(pageName: string): string {{
    switch (pageName) {{
{cases}
      default:
        return 'pages/Index';
    }}
  }}
}}
"""


def _render_store_file(store_name: str, state: list[str], actions: list[str], responsibilities: str) -> str:
    state_lines = "\n".join(f"  @State {name}: string = '';" for name in state) or "  @State status: string = '';"
    action_lines = "\n".join(
        f"  {action}(value: string): void {{\n    this.{state[0] if state else 'status'} = value;\n  }}"
        for action in actions
    ) or "  setStatus(value: string): void {\n    this.status = value;\n  }"
    return f"""@Observed
export class {store_name} {{
{state_lines}

  readonly responsibilities: string = '{responsibilities or "manage shared state"}';

{action_lines}
}}
"""


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


def _route_table_from_page_tasks(page_tasks: list[dict[str, Any]]) -> list[dict[str, Any]]:
    route_table: list[dict[str, Any]] = []
    for task in page_tasks:
        route_table.append(
            {
                "page_name": str(task.get("page_name") or ""),
                "route": str(task.get("route") or f"pages/{task.get('page_name')}"),
                "page_file": str(task.get("page_file") or ""),
            }
        )
    return route_table


def materialize_coder_skeleton(payload: Any, project_root: Path | None = None) -> str:
    normalized = _coerce_payload(payload)
    project_name = normalized["project_name"]
    page_tasks = list(normalized.get("page_tasks") or [])
    route_table = _route_table_from_page_tasks(page_tasks)
    route_entries: list[str] = [
        str(route_item.get("route") or f"pages/{route_item.get('page_name')}") for route_item in route_table
    ]

    page_task_bundle = {
        "project_name": project_name,
        "tasks": page_tasks,
    }
    save_coder_page_task_bundle_payload(page_task_bundle, project_root=project_root)

    return "\n".join(
        [
            "status: SUCCESS",
            f"project_name: {project_name}",
            f"project_path: /projects/{project_name}",
            f"route_count: {len(route_entries)}",
            f"page_task_count: {len(page_task_bundle['tasks'])}",
        ]
    )


@tool
def materialize_coder_skeleton_artifacts(payload: dict[str, Any]) -> str:
    """
    Materialize the planned skeleton into project files, including page registration and shared scaffolding.
    """
    return materialize_coder_skeleton(payload)
