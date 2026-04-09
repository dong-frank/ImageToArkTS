from __future__ import annotations

import json
import shutil
from pathlib import Path
from typing import Any

from pydantic import BaseModel, ValidationError

from schemas import (
    CoderIntegrationReport,
    CoderPageTaskBundle,
    CoderPageWorkerResultBundle,
    CoderSkeletonOutput,
)
from tools.common import PROJECT_ROOT, resolve_workspace_path, workspace_root
from tools.project_tools import TEMPLATE_IGNORE_PATTERNS, TEMPLATE_PROJECT_DIR
from utils.session_context import get_current_session_id


def _resolve_session_path(raw_path: str, project_root: Path | None = None) -> Path:
    if project_root is None:
        return resolve_workspace_path(raw_path)
    return project_root / "agent_workspace" / "sessions" / get_current_session_id() / raw_path.lstrip("/")


def _coder_skeleton_plan_path(project_root: Path | None = None) -> Path:
    return _resolve_session_path("/designs/coder_skeleton_plan.json", project_root=project_root)


def _coder_page_tasks_path(project_root: Path | None = None) -> Path:
    return _resolve_session_path("/designs/coder_page_tasks.json", project_root=project_root)


def _coder_page_worker_results_path(project_root: Path | None = None) -> Path:
    return _resolve_session_path("/logs/coder/page_worker_results.json", project_root=project_root)


def _coder_integration_report_path(project_root: Path | None = None) -> Path:
    return _resolve_session_path("/logs/coder/integration_report.json", project_root=project_root)


def _workspace_root(project_root: Path | None = None) -> Path:
    if project_root is None:
        return workspace_root()
    return project_root / "agent_workspace" / "sessions" / get_current_session_id()


def _projects_root(project_root: Path | None = None) -> Path:
    return _workspace_root(project_root) / "projects"


def _ensure_parent(path: Path) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    return path


def _normalize_payload(payload: Any, model_type: type[BaseModel]) -> dict[str, Any]:
    if isinstance(payload, model_type):
        return payload.model_dump(mode="json", exclude_none=True)
    if isinstance(payload, str):
        payload = json.loads(payload)
    if isinstance(payload, dict):
        return model_type.model_validate(payload).model_dump(mode="json", exclude_none=True)
    raise ValidationError.from_exception_data(model_type.__name__, [])


def save_coder_skeleton_plan_payload(payload: Any, project_root: Path | None = None) -> str:
    normalized = _normalize_payload(payload, CoderSkeletonOutput)
    path = _ensure_parent(_coder_skeleton_plan_path(project_root=project_root))
    path.write_text(json.dumps(normalized, ensure_ascii=False, indent=2), encoding="utf-8")
    return f"coder skeleton plan saved to {path}"


def save_coder_page_task_bundle_payload(payload: Any, project_root: Path | None = None) -> str:
    normalized = _normalize_payload(payload, CoderPageTaskBundle)
    path = _ensure_parent(_coder_page_tasks_path(project_root=project_root))
    path.write_text(json.dumps(normalized, ensure_ascii=False, indent=2), encoding="utf-8")
    return f"coder page task bundle saved to {path}"


def save_coder_page_worker_results_payload(payload: Any, project_root: Path | None = None) -> str:
    normalized = _normalize_payload(payload, CoderPageWorkerResultBundle)
    path = _ensure_parent(_coder_page_worker_results_path(project_root=project_root))
    path.write_text(json.dumps(normalized, ensure_ascii=False, indent=2), encoding="utf-8")
    return f"coder page worker results saved to {path}"


def save_coder_integration_report_payload(payload: Any, project_root: Path | None = None) -> str:
    normalized = _normalize_payload(payload, CoderIntegrationReport)
    path = _ensure_parent(_coder_integration_report_path(project_root=project_root))
    path.write_text(json.dumps(normalized, ensure_ascii=False, indent=2), encoding="utf-8")
    return f"coder integration report saved to {path}"


def load_coder_skeleton_plan_payload(project_root: Path | None = None) -> dict[str, Any]:
    return json.loads(_coder_skeleton_plan_path(project_root=project_root).read_text(encoding="utf-8"))


def load_coder_page_task_bundle_payload(project_root: Path | None = None) -> dict[str, Any]:
    return json.loads(_coder_page_tasks_path(project_root=project_root).read_text(encoding="utf-8"))


def load_coder_page_worker_results_payload(project_root: Path | None = None) -> dict[str, Any]:
    return json.loads(_coder_page_worker_results_path(project_root=project_root).read_text(encoding="utf-8"))


def load_coder_integration_report_payload(project_root: Path | None = None) -> dict[str, Any]:
    return json.loads(_coder_integration_report_path(project_root=project_root).read_text(encoding="utf-8"))


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


def _render_page_placeholder(page_name: str, responsibilities: str, app_display_name: str) -> str:
    component_name = _page_component_name(page_name)
    title = responsibilities or f"{page_name} page"
    return f"""@Component
struct {component_name} {{
  build() {{
    Column({{ space: 12 }}) {{
      Text('{app_display_name}')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
      Text('{title}')
        .fontSize(16)
        .fontColor('#666666')
    }}
    .width('100%')
    .height('100%')
    .padding(16)
    .justifyContent(FlexAlign.Start)
  }}
}}
"""


def _render_entry_page(page_name: str, responsibilities: str, app_display_name: str) -> str:
    component_name = _page_component_name(page_name)
    title = responsibilities or f"{page_name} page"
    return f"""@Entry
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
    return f"""export class {interface_name} {{
  summary(): string {{
    return '{text}';
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


def materialize_coder_skeleton(payload: Any, project_root: Path | None = None) -> str:
    normalized = _normalize_payload(payload, CoderSkeletonOutput)
    project_name = normalized["project_name"]
    app_display_name = normalized["app_display_name"]
    project_dir = _copy_template_project(project_name, project_root=project_root)
    _update_app_strings(project_dir, app_display_name)

    pages_dir = project_dir / "entry/src/main/ets/pages"
    shared_components_dir = project_dir / "entry/src/main/ets/common/components"
    shared_services_dir = project_dir / "entry/src/main/ets/common/services"
    shared_store_dir = project_dir / "entry/src/main/ets/common/store"
    shared_models_dir = project_dir / "entry/src/main/ets/common/models"
    pages_dir.mkdir(parents=True, exist_ok=True)
    shared_components_dir.mkdir(parents=True, exist_ok=True)
    shared_services_dir.mkdir(parents=True, exist_ok=True)
    shared_store_dir.mkdir(parents=True, exist_ok=True)
    shared_models_dir.mkdir(parents=True, exist_ok=True)

    route_entries: list[str] = []
    for index, route_item in enumerate(normalized.get("route_table", [])):
        route = str(route_item.get("route") or f"pages/{route_item.get('page_name')}")
        route_entries.append(route)
        page_file_path = _resolve_session_path(str(route_item.get("page_file") or f"/projects/{project_name}/entry/src/main/ets/{route}.ets"), project_root=project_root)
        page_name = str(route_item.get("page_name") or Path(route).name)
        page_task = next(
            (task for task in normalized.get("page_tasks", []) if str(task.get("page_name")) == page_name),
            {},
        )
        content = (
            _render_entry_page(page_name, str(page_task.get("responsibilities") or ""), app_display_name)
            if index == 0
            else _render_page_placeholder(page_name, str(page_task.get("responsibilities") or ""), app_display_name)
        )
        _write_text(page_file_path, content)

    main_pages_path = project_dir / "entry/src/main/resources/base/profile/main_pages.json"
    _write_text(main_pages_path, json.dumps({"src": route_entries}, ensure_ascii=False, indent=2))

    for component in normalized.get("shared_components", []):
        target = _resolve_session_path(str(component.get("file_path")), project_root=project_root)
        _write_text(target, _render_shared_component(str(component.get("name") or "SharedComponent"), str(component.get("description") or "")))

    for interface in normalized.get("public_interfaces", []):
        target = _resolve_session_path(str(interface.get("file_path")), project_root=project_root)
        _write_text(target, _render_service_interface(str(interface.get("name") or "SharedService"), str(interface.get("description") or "")))

    state_management = normalized.get("state_management", {})
    state_target = _resolve_session_path(str(state_management.get("file_path")), project_root=project_root)
    _write_text(
        state_target,
        _render_store_file(
            str(state_management.get("store_name") or "AppStore"),
            list(state_management.get("exposed_state") or []),
            list(state_management.get("exposed_actions") or []),
            str(state_management.get("responsibilities") or ""),
        ),
    )

    model_target = shared_models_dir / "AppDataModel.ets"
    _write_text(model_target, _render_data_model_file(list(normalized.get("shared_data_models") or [])))

    page_task_bundle = {
        "project_name": project_name,
        "tasks": normalized.get("page_tasks", []),
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
