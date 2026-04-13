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

_LEGACY_PAGE_PREFIXES = (
    "entry/src/main/ets/pages/",
    "/entry/src/main/ets/pages/",
)


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


def _default_uni_page_relative_path(page_name: str = "", route: str = "") -> str:
    normalized_route = str(route or "").strip().replace("\\", "/").lstrip("/")
    if normalized_route.startswith("pages/"):
        return f"src/{normalized_route}.vue"

    normalized_page_name = str(page_name or "").strip()
    fallback_name = normalized_page_name or "Index"
    return f"src/pages/{fallback_name}.vue"


def normalize_project_page_path(project_name: str, raw_path: str, *, page_name: str = "", route: str = "") -> str:
    raw = str(raw_path or "").strip().replace("\\", "/")
    project_prefix = f"/projects/{project_name}/"

    if not raw:
        return f"/projects/{project_name}/{_default_uni_page_relative_path(page_name=page_name, route=route)}"

    relative = raw
    if raw.startswith(project_prefix):
        relative = raw[len(project_prefix) :]
    elif raw.startswith(f"/projects/{project_name}"):
        relative = raw[len(f"/projects/{project_name}") :].lstrip("/")
    elif raw.startswith("/projects/"):
        return raw
    elif raw.startswith("/"):
        relative = raw.lstrip("/")

    for legacy_prefix in _LEGACY_PAGE_PREFIXES:
        if relative.startswith(legacy_prefix.lstrip("/")):
            relative = "src/pages/" + relative[len(legacy_prefix.lstrip("/")) :]
            break

    if relative.startswith("src/pages/") or relative.startswith("src/views/"):
        if relative.endswith(".ets"):
            relative = relative[: -len(".ets")] + ".vue"
        return f"/projects/{project_name}/{relative}"

    if relative.endswith(".ets") and relative.startswith("pages/"):
        relative = f"src/{relative[: -len('.ets')]}.vue"
        return f"/projects/{project_name}/{relative}"

    return f"/projects/{project_name}/{relative}"


def normalize_page_task_payload(payload: dict[str, Any]) -> dict[str, Any]:
    normalized = dict(payload)
    project_name = str(normalized.get("project_name") or "").strip()
    if not project_name:
        return normalized

    tasks = []
    for task in normalized.get("page_tasks", []) or normalized.get("tasks", []) or []:
        item = dict(task)
        page_name = str(item.get("page_name") or "")
        route = str(item.get("route") or "")
        item["page_file"] = normalize_project_page_path(
            project_name,
            str(item.get("page_file") or ""),
            page_name=page_name,
            route=route,
        )
        item["allowed_write_paths"] = [
            normalize_project_page_path(project_name, str(path), page_name=page_name, route=route)
            for path in (item.get("allowed_write_paths") or [item["page_file"]])
        ]
        tasks.append(item)

    if "page_tasks" in normalized:
        normalized["page_tasks"] = tasks
    if "tasks" in normalized:
        normalized["tasks"] = tasks
    return normalized


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
        "import AppTabBar from '../components/AppTabBar.vue';\n"
        "import { usePageNavigation } from '../composables/usePageNavigation';\n\n"
    )


def _render_navigation_usage(page_name: str, include_navigation: bool) -> str:
    if not include_navigation:
        return ""
    return (
        f"const navigation = usePageNavigation('{page_name}')\n"
    )


def _render_page_placeholder(page_name: str, responsibilities: str, app_display_name: str, include_navigation: bool = False) -> str:
    title = responsibilities or f"{page_name} page"
    navigation_setup = _render_navigation_usage(page_name, include_navigation)
    return f"""<script setup>
{_render_navigation_import_block(include_navigation)}definePageConfig({{
  navigationBarTitleText: '{app_display_name}'
}})
{navigation_setup if include_navigation else ''}</script>

<template>
  <view class="page-shell">
    <view class="page-copy">
      <text class="page-title">{app_display_name}</text>
      <text class="page-subtitle">{title}</text>
    </view>
    <AppTabBar
      v-if="{str(include_navigation).lower()}"
      :current-page="navigation.currentPage"
      :tabs="navigation.tabs"
    />
  </view>
</template>

<style scoped>
.page-shell {{
  min-height: 100vh;
  padding: 32rpx;
  display: flex;
  flex-direction: column;
  gap: 24rpx;
  background: #f7f8fa;
}}

.page-copy {{
  display: flex;
  flex-direction: column;
  gap: 12rpx;
}}

.page-title {{
  font-size: 40rpx;
  font-weight: 700;
  color: #111827;
}}

.page-subtitle {{
  font-size: 28rpx;
  color: #6b7280;
}}
</style>
"""


def _render_entry_page(page_name: str, responsibilities: str, app_display_name: str, include_navigation: bool = False) -> str:
    return _render_page_placeholder(page_name, responsibilities, app_display_name, include_navigation=include_navigation)


def _render_shared_component(name: str, description: str) -> str:
    component_name = _page_component_name(name)
    text = description or name
    if component_name == "AppTabBar":
        return """<script setup>
defineProps({
  currentPage: {
    type: String,
    default: ''
  },
  tabs: {
    type: Array,
    default: () => []
  }
})
</script>

<template>
  <view class="tab-bar">
    <view
      v-for="tab in tabs"
      :key="tab.name"
      class="tab-item"
      :class="{ active: currentPage === tab.name }"
    >
      <text>{{ tab.label || tab.name }}</text>
    </view>
  </view>
</template>

<style scoped>
.tab-bar {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(120rpx, 1fr));
  gap: 16rpx;
  padding: 16rpx;
  background: #ffffff;
  border-radius: 24rpx;
}

.tab-item {
  padding: 18rpx 12rpx;
  text-align: center;
  border-radius: 18rpx;
  color: #6b7280;
  background: #f3f4f6;
}

.tab-item.active {
  color: #111827;
  background: #dbeafe;
  font-weight: 600;
}
</style>
"""
    return f"""<template>
  <view class="{component_name.lower()}">
    <text>{text}</text>
  </view>
</template>

<style scoped>
.{component_name.lower()} {{
  width: 100%;
}}
</style>
"""


def _render_service_interface(name: str, description: str) -> str:
    interface_name = _page_component_name(name)
    text = description or name
    if interface_name == "UsePageNavigation":
        return _render_navigation_service([])
    return f"""export function {interface_name[0].lower()}{interface_name[1:]}() {{
  return {{
    summary: '{text}'
  }}
}}
"""


def _render_navigation_service(route_table: list[dict[str, Any]]) -> str:
    tabs = [str(item.get("page_name") or "") for item in route_table if str(item.get("page_name") or "").strip()]
    unique_tabs: list[str] = []
    for tab in tabs:
        if tab not in unique_tabs:
            unique_tabs.append(tab)
    tab_lines = ",\n".join(
        f"    {{ name: '{tab}', label: '{tab}', route: '{next((str(item.get('route') or '') for item in route_table if str(item.get('page_name') or '') == tab), f'pages/{tab}')}' }}"
        for tab in unique_tabs
    ) or "    { name: 'Index', label: 'Index', route: 'pages/Index' }"
    return f"""const tabs = [
{tab_lines}
]

export function usePageNavigation(currentPage = 'Index') {{
  return {{
    currentPage,
    tabs
  }}
}}
"""


def _render_store_file(store_name: str, state: list[str], actions: list[str], responsibilities: str) -> str:
    state_lines = "\n".join(f"    {name}: ''" for name in state) or "    status: ''"
    action_lines = "\n".join(
        f"  function {action}(value) {{\n    state.{state[0] if state else 'status'} = value\n  }}"
        for action in actions
    ) or "  function setStatus(value) {\n    state.status = value\n  }"
    return f"""import {{ reactive }} from 'vue'

const state = reactive({{
{state_lines}
}})

export function {store_name}() {{
{action_lines}
  return {{
    state,
    responsibilities: '{responsibilities or "manage shared state"}',
    {', '.join(actions) if actions else 'setStatus'}
  }}
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
    normalized = normalize_page_task_payload(_coerce_payload(payload))
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
