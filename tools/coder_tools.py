from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from langchain.tools import tool
from pydantic import BaseModel

from tools.common import resolve_workspace_path, workspace_root
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


def _page_merge_index_path(project_root: Path | None = None) -> Path:
    return _resolve_session_path("/designs/page_merge_index.json", project_root=project_root)


def _navigation_design_path(project_root: Path | None = None) -> Path:
    return _resolve_session_path("/designs/navigation_design.json", project_root=project_root)


def _architect_pages_dir(project_root: Path | None = None) -> Path:
    return _resolve_session_path("/designs/pages", project_root=project_root)


def _workspace_root(project_root: Path | None = None) -> Path:
    if project_root is None:
        return workspace_root()
    return project_root / "agent_workspace" / "sessions" / get_current_session_id()


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
        text = payload.strip()
        try:
            payload = json.loads(text)
        except json.JSONDecodeError:
            start = text.find("{")
            end = text.rfind("}")
            if start >= 0 and end > start:
                try:
                    payload = json.loads(text[start : end + 1])
                except json.JSONDecodeError as exc:
                    raise ValueError(f"Invalid JSON payload string: {exc}") from exc
            else:
                raise ValueError("Invalid JSON payload string: no JSON object found")

    if isinstance(payload, dict):
        return payload

    raise ValueError(f"Unsupported payload type: {type(payload).__name__}")


def _load_json_payload(path: Path) -> dict[str, Any]:
    text = path.read_text(encoding="utf-8")
    try:
        payload = json.loads(text)
    except json.JSONDecodeError:
        start = text.find("{")
        end = text.rfind("}")
        if start < 0 or end <= start:
            raise
        payload = json.loads(text[start : end + 1])

    if not isinstance(payload, dict):
        raise ValueError(f"JSON payload in {path} must be an object")
    return payload


def _safe_json_load(path: Path) -> tuple[dict[str, Any] | None, str | None]:
    if not path.exists() or not path.is_file():
        return None, "file does not exist"
    try:
        payload = _load_json_payload(path)
        return payload, None
    except Exception as exc:  # noqa: BLE001
        return None, str(exc)


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


def _design_page_file_path(page_id: str) -> str:
    return f"/designs/pages/{page_id}.json"


def _code_page_file_path(project_name: str, component_name: str) -> str:
    return f"/projects/{project_name}/entry/src/main/ets/pages/{component_name}.ets"


def _ensure_string_list(value: Any) -> list[str]:
    if value is None:
        return []
    if isinstance(value, list):
        result: list[str] = []
        for item in value:
            text = str(item or "").strip()
            if text:
                result.append(text)
        return result
    text = str(value or "").strip()
    return [text] if text else []


def _normalize_project_relative_path(project_name: str, raw_path: str) -> str:
    raw = str(raw_path or "").strip().replace("\\", "/")
    if not raw:
        return raw
    if raw.startswith("/projects/"):
        return raw
    if raw.startswith("/"):
        return f"/projects/{project_name}{raw}"
    return f"/projects/{project_name}/{raw.lstrip('/')}"


def _normalize_coder_task(
    task: dict[str, Any], project_name: str, index: int = 0
) -> dict[str, Any]:
    raw = dict(task or {})

    page_id = _safe_identifier(
        str(raw.get("page_id") or raw.get("page_name") or ""),
        fallback=f"page_{index}",
    )
    page_name = str(raw.get("page_name") or page_id).strip() or page_id
    route = _normalize_route(raw.get("route"), page_name, page_id)
    component_name = _route_to_component_name(route, page_name)

    page_file = str(raw.get("page_file") or "").strip()
    if not page_file:
        page_file = _code_page_file_path(project_name, component_name)
    else:
        page_file = _normalize_project_relative_path(project_name, page_file)

    design_file = str(raw.get("design_file") or "").strip()
    if not design_file:
        design_file = _design_page_file_path(page_id)

    allowed_write_paths = _ensure_string_list(raw.get("allowed_write_paths"))
    if not allowed_write_paths:
        allowed_write_paths = [page_file]
    else:
        allowed_write_paths = [
            _normalize_project_relative_path(project_name, path)
            for path in allowed_write_paths
        ]
        if page_file not in allowed_write_paths:
            allowed_write_paths.append(page_file)

    return {
        "page_id": page_id,
        "page_name": page_name,
        "route": route,
        "role": str(raw.get("role") or "unknown").strip() or "unknown",
        "summary": str(raw.get("summary") or "").strip(),
        "responsibilities": str(
            raw.get("responsibilities") or raw.get("summary") or page_name
        ).strip(),
        "design_file": design_file,
        "page_file": page_file,
        "allowed_write_paths": allowed_write_paths,
        "shared_dependencies": _ensure_string_list(raw.get("shared_dependencies")),
        "primary_actions": _ensure_string_list(raw.get("primary_actions")),
        "state_notes": raw.get("state_notes"),
    }


def _normalize_coder_task_bundle(payload: dict[str, Any]) -> dict[str, Any]:
    normalized = dict(payload)

    if "tasks" not in normalized and "page_tasks" in normalized:
        normalized["tasks"] = list(normalized.get("page_tasks") or [])
    else:
        normalized["tasks"] = list(normalized.get("tasks") or [])

    # 自动检测唯一非app_project项目名
    if not normalized.get("project_name") or not str(normalized.get("project_name")).strip():
        # 获取当前 session 的 projects 目录
        try:
            projects_dir = _projects_root()
            if projects_dir.exists() and projects_dir.is_dir():
                project_names = [
                    p.name for p in projects_dir.iterdir()
                    if p.is_dir() and p.name != "app_project"
                ]
                if len(project_names) == 1:
                    normalized["project_name"] = _safe_project_name(project_names[0])
                else:
                    normalized["project_name"] = "app_project"
            else:
                normalized["project_name"] = "app_project"
        except Exception:
            normalized["project_name"] = "app_project"
    else:
        normalized["project_name"] = _safe_project_name(str(normalized.get("project_name")))

    if normalized.get("app_display_name") is None:
        normalized["app_display_name"] = normalized["project_name"]
    else:
        normalized["app_display_name"] = str(
            normalized.get("app_display_name") or normalized["project_name"]
        )

    shared_navigation = normalized.get("shared_navigation")
    if isinstance(shared_navigation, dict):
        normalized["shared_navigation"] = {
            "enabled": bool(shared_navigation.get("enabled", False)),
            "type": str(shared_navigation.get("type") or "bottom_nav"),
        }
    else:
        normalized["shared_navigation"] = {
            "enabled": False,
            "type": "bottom_nav",
        }

    normalized["schema_version"] = str(
        normalized.get("schema_version") or "coder_task_bundle.v1"
    )

    normalized["tasks"] = [
        _normalize_coder_task(task, normalized["project_name"], idx)
        for idx, task in enumerate(normalized["tasks"])
        if isinstance(task, dict)
    ]

    normalized.pop("page_tasks", None)
    return normalized


# ---------------------------------------------------------------------------
# Shared navigation helpers
# ---------------------------------------------------------------------------

def _should_create_navigation_scaffold(tasks: list[dict[str, Any]]) -> bool:
    return len(tasks) > 1


def _task_dep_names(task: dict[str, Any]) -> set[str]:
    return {
        str(dep).strip()
        for dep in list(task.get("shared_dependencies") or [])
        if str(dep).strip()
    }


def _needs_shared_navigation(
    tasks: list[dict[str, Any]],
    shared_navigation: dict[str, Any] | None = None,
) -> bool:
    if isinstance(shared_navigation, dict) and bool(shared_navigation.get("enabled", False)):
        return True

    required = {"BottomNavBar", "NavigationService"}
    for task in tasks:
        if _task_dep_names(task) & required:
            return True

    return False


# ---------------------------------------------------------------------------
# Payload persistence helpers
# ---------------------------------------------------------------------------


def save_coder_page_task_bundle_payload(
    payload: Any, project_root: Path | None = None
) -> str:
    normalized = _normalize_coder_task_bundle(_coerce_payload(payload))
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
    payload = _load_json_payload(_coder_page_tasks_path(project_root=project_root))
    return _normalize_coder_task_bundle(payload)


def load_coder_page_worker_results_payload(
    project_root: Path | None = None,
) -> dict[str, Any]:
    return _load_json_payload(_coder_page_worker_results_path(project_root=project_root))


def load_coder_integration_report_payload(
    project_root: Path | None = None,
) -> dict[str, Any]:
    return _load_json_payload(_coder_integration_report_path(project_root=project_root))


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
    return _load_json_payload(_coder_latest_compile_fix_trace_path(project_root=project_root))


def load_coder_compile_fix_history_payload(
    project_root: Path | None = None,
) -> list[dict[str, Any]]:
    path = _coder_compile_fix_history_path(project_root=project_root)
    if not path.exists():
        return []

    payloads: list[dict[str, Any]] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            parsed = json.loads(line)
        except json.JSONDecodeError:
            start = line.find("{")
            end = line.rfind("}")
            if start < 0 or end <= start:
                continue
            parsed = json.loads(line[start : end + 1])
        if isinstance(parsed, dict):
            payloads.append(parsed)
    return payloads


def load_page_merge_index_payload(
    project_root: Path | None = None,
) -> dict[str, Any]:
    return _load_json_payload(_page_merge_index_path(project_root=project_root))


def load_navigation_design_payload(
    project_root: Path | None = None,
) -> dict[str, Any]:
    return _load_json_payload(_navigation_design_path(project_root=project_root))


def load_architect_pages_payload(
    project_root: Path | None = None,
) -> list[dict[str, Any]]:
    pages_dir = _architect_pages_dir(project_root=project_root)
    if not pages_dir.exists():
        return []
    return [_load_json_payload(p) for p in sorted(pages_dir.glob("*.json"))]


# ---------------------------------------------------------------------------
# Compile fix attempt record builder
# Optional reporting helper for integration tracing / orchestration.
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
# Project file helpers
# ---------------------------------------------------------------------------


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


def _render_index_jump_page(entry_route: str) -> str:
    safe_route = str(entry_route or "pages/Index").strip() or "pages/Index"
    return (
        "import router from '@ohos.router';\n\n"
        "@Entry\n"
        "@Component\n"
        "struct Index {\n"
        "  aboutToAppear() {\n"
        f"    router.replaceUrl({{ url: '{safe_route}' }})\n"
        "  }\n"
        "  build() {\n"
        "    Column()\n"
        "      .width('100%')\n"
        "      .height('100%')\n"
        "      .backgroundColor('#FFFFFF')\n"
        "  }\n"
        "}\n"
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
        and str(item.get("route") or "").strip().lower() != "pages/index"
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
        and str(item.get("route") or "").strip().lower() != "pages/index"
    )
    if not cases:
        cases = "      default:\n        return 'pages/Index';"

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
        "        return 'pages/Index';\n"
        "    }\n"
        "  }\n"
        "}\n"
    )


# ---------------------------------------------------------------------------
# Route table + entry task helpers
# ---------------------------------------------------------------------------


def _route_table_from_tasks(tasks: list[dict[str, Any]]) -> list[dict[str, Any]]:
    normalized: list[dict[str, Any]] = [
        {
            "page_id": str(task.get("page_id") or ""),
            "page_name": str(task.get("page_name") or ""),
            "route": str(
                task.get("route")
                or f"pages/{_safe_identifier(task.get('page_id') or task.get('page_name'), fallback='index')}"
            ),
            "page_file": str(task.get("page_file") or ""),
        }
        for task in tasks
    ]

    # Inject Harmony fixed launcher route for registration.
    # This is a system launcher page, not a design task page.
    has_index = any(
        str(item.get("route") or "").strip().lower() == "pages/index"
        for item in normalized
    )
    if not has_index:
        normalized.insert(
            0,
            {
                "page_id": "index",
                "page_name": "Index",
                "route": "pages/Index",
                "page_file": "",
            },
        )
    return normalized


_ENTRY_ROLES: frozenset[str] = frozenset({"entry"})
_ENTRY_ROUTES: frozenset[str] = frozenset(
    {"pages/index", "pages/home", "pages/homepage", "pages/main"}
)


def _infer_entry_task(tasks: list[dict[str, Any]]) -> dict[str, Any] | None:
    if not tasks:
        return None

    for task in tasks:
        if str(task.get("role") or "").strip().lower() in _ENTRY_ROLES:
            return task

    for task in tasks:
        if str(task.get("route") or "").strip().lower() in _ENTRY_ROUTES:
            return task

    return tasks[0]


# ---------------------------------------------------------------------------
# Project file writers
# ---------------------------------------------------------------------------


def _write_main_pages_json(project_dir: Path, route_table: list[dict[str, Any]]) -> None:
    path = project_dir / "entry/src/main/resources/base/profile/main_pages.json"
    payload = {"src": [str(item.get("route") or "pages/Index") for item in route_table]}
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


def _write_entry_index_page(project_dir: Path, entry_route: str) -> str:
    index_path = project_dir / "entry/src/main/ets/pages/Index.ets"
    _write_text(index_path, _render_index_jump_page(entry_route))
    return str(index_path)


def _write_page_placeholders(
    project_dir: Path,
    tasks: list[dict[str, Any]],
    app_display_name: str,
    include_navigation: bool,
) -> list[str]:
    written: list[str] = []

    for task in tasks:
        page_name = str(task.get("page_name") or task.get("page_id") or "Page")
        responsibilities = str(task.get("summary") or task.get("responsibilities") or "")
        page_file = str(task.get("page_file") or "").strip()
        if not page_file:
            continue

        relative = page_file.replace("/projects/", "", 1)
        project_relative = relative.split("/", 1)[1] if "/" in relative else relative
        file_path = project_dir / project_relative

        task_include_navigation = include_navigation and bool(
            _task_dep_names(task) & {"BottomNavBar", "NavigationService"}
        )

        content = _render_page_placeholder(
            page_name=page_name,
            responsibilities=responsibilities,
            app_display_name=app_display_name,
            include_navigation=task_include_navigation,
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
    page_merge_index_payload = load_page_merge_index_payload(project_root=project_root)
    navigation_design_payload = load_navigation_design_payload(project_root=project_root)
    architect_pages_payload = load_architect_pages_payload(project_root=project_root)

    raw_page_index = list(page_merge_index_payload.get("page_index") or [])
    entry_page_id = str(navigation_design_payload.get("entry_page_id") or "").strip()

    project_name = _safe_project_name(
        page_merge_index_payload.get("project_name")
        or navigation_design_payload.get("project_name")
        or "app_project"
    )
    app_display_name = str(
        page_merge_index_payload.get("app_display_name")
        or navigation_design_payload.get("app_display_name")
        or project_name
    )

    page_payload_lookup: dict[str, dict[str, Any]] = {}
    for page in architect_pages_payload:
        if not isinstance(page, dict):
            continue
        pid = str(page.get("page_id") or "").strip()
        if pid:
            page_payload_lookup[pid] = page

    tasks: list[dict[str, Any]] = []

    for idx, item in enumerate(raw_page_index):
        if not isinstance(item, dict):
            continue

        page_id = _safe_identifier(str(item.get("page_id") or ""), fallback=f"page_{idx}")
        page = page_payload_lookup.get(page_id, {})

        page_name = str(page.get("page_name") or item.get("page_name") or page_id).strip()
        route = _normalize_route(item.get("route") or page.get("route"), page_name, page_id)

        page_role = str(page.get("page_role") or item.get("page_role") or "").strip()
        role = "entry" if entry_page_id and page_id == entry_page_id else (page_role or "unknown")

        summary = str(page.get("page_summary") or item.get("page_summary") or "").strip()
        responsibilities = str(page.get("responsibilities") or summary or page_name).strip()

        interactions = list(page.get("interactions") or [])
        primary_actions: list[str] = []
        for interaction in interactions:
            if not isinstance(interaction, dict):
                continue
            label = str(
                interaction.get("source_label")
                or interaction.get("effect_summary")
                or interaction.get("interaction_type")
                or ""
            ).strip()
            if label and label not in primary_actions:
                primary_actions.append(label)

        component_name = _route_to_component_name(route, page_name)
        page_file = _code_page_file_path(project_name, component_name)

        tasks.append(
            {
                "page_id": page_id,
                "page_name": page_name,
                "route": route,
                "role": role,
                "summary": summary,
                "responsibilities": responsibilities,
                "design_file": _design_page_file_path(page_id),
                "page_file": page_file,
                "allowed_write_paths": [page_file],
                "shared_dependencies": [],
                "primary_actions": primary_actions,
                "state_notes": None,
            }
        )

    if not tasks:
        fallback_file = _code_page_file_path(project_name, "HomePage")
        tasks.append(
            {
                "page_id": "home",
                "page_name": "Home",
                "route": "pages/HomePage",
                "role": "entry",
                "summary": "Default entry page placeholder",
                "responsibilities": "Default entry page placeholder",
                "design_file": _design_page_file_path("home"),
                "page_file": fallback_file,
                "allowed_write_paths": [fallback_file],
                "shared_dependencies": [],
                "primary_actions": [],
                "state_notes": None,
            }
        )

    return {
        "schema_version": "coder_task_bundle.v1",
        "task_bundle_source": "fallback_from_architect",
        "project_name": project_name,
        "app_display_name": app_display_name,
        "shared_navigation": {
            "enabled": False,
            "type": "bottom_nav",
        },
        "tasks": tasks,
    }


# ---------------------------------------------------------------------------
# Skeleton materialization entry point
# ---------------------------------------------------------------------------


def materialize_coder_skeleton(payload: Any, project_root: Path | None = None) -> str:
    raw_payload = _coerce_payload(payload) if payload is not None else {}
    normalized = _normalize_coder_task_bundle(raw_payload)

    task_bundle_source = "worker_payload"

    if not normalized.get("tasks"):
        inferred = build_coder_skeleton_seed_from_architect(project_root=project_root)
        merged = {**inferred, **normalized}
        if not normalized.get("tasks"):
            merged["tasks"] = list(inferred.get("tasks") or [])
        if "shared_navigation" not in raw_payload:
            merged["shared_navigation"] = inferred.get("shared_navigation")
        normalized = _normalize_coder_task_bundle(merged)
        task_bundle_source = "fallback_from_architect"

    project_name = _safe_project_name(normalized.get("project_name"))
    app_display_name = str(normalized.get("app_display_name") or project_name)
    tasks = list(normalized.get("tasks") or [])
    shared_navigation = normalized.get("shared_navigation") or {}

    needs_shared_navigation = _needs_shared_navigation(tasks, shared_navigation)
    navigation_type = str(shared_navigation.get("type") or "bottom_nav")

    route_table = _route_table_from_tasks(tasks)

    project_dir = _projects_root(project_root) / project_name
    if not project_dir.exists():
        return "\n".join(
            [
                "status: FAILED",
                f"project_name: {project_name}",
                f"project_path: /projects/{project_name}",
                "error: project does not exist; create_project must be called before materialize_coder_skeleton_artifacts",
            ]
        )

    _update_app_strings(project_dir, app_display_name)
    _write_main_pages_json(project_dir, route_table)

    should_create_navigation_scaffold = _should_create_navigation_scaffold(tasks)

    shared_written: list[str] = []
    if should_create_navigation_scaffold:
        shared_written = _write_navigation_scaffold(project_dir, route_table)

        if len(shared_written) == 0:
            return "\n".join(
                [
                    "status: FAILED",
                    f"project_name: {project_name}",
                    f"project_path: /projects/{project_name}",
                    "error: navigation scaffold was expected but no shared files were created",
                ]
            )

    page_files_written = _write_page_placeholders(
        project_dir=project_dir,
        tasks=tasks,
        app_display_name=app_display_name,
        include_navigation=False,
    )

    entry_task = _infer_entry_task(tasks)
    entry_route = str(entry_task.get("route") or "pages/Index") if entry_task else "pages/Index"
    index_file_written = _write_entry_index_page(project_dir, entry_route)

    page_task_bundle = {
        "schema_version": "coder_task_bundle.v1",
        "task_bundle_source": task_bundle_source,
        "project_name": project_name,
        "app_display_name": app_display_name,
        "shared_navigation": {
            "enabled": needs_shared_navigation,
            "type": navigation_type,
            "scaffold_created": should_create_navigation_scaffold,
        },
        "tasks": tasks,
        "generated_route_table": route_table,
        "generated_files": {
            "shared": shared_written,
            "pages": page_files_written,
            "index_page": index_file_written,
            "main_pages_json": str(
                project_dir / "entry/src/main/resources/base/profile/main_pages.json"
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
            f"page_task_count: {len(tasks)}",
            f"shared_navigation_enabled: {str(needs_shared_navigation)}",
            f"navigation_scaffold_created: {str(should_create_navigation_scaffold)}",
            f"shared_file_count: {len(shared_written)}",
            f"page_file_count: {len(page_files_written)}",
            f"task_bundle_source: {task_bundle_source}",
        ]
    )


# ---------------------------------------------------------------------------
# Artifact inspection helpers
# Optional inspection / reporting helpers for orchestration and debugging.
# ---------------------------------------------------------------------------


def check_coder_skeleton_artifacts(project_root: Path | None = None) -> str:
    path = _coder_page_tasks_path(project_root=project_root)
    result: dict[str, Any] = {
        "stage": "coder_skeleton",
        "workspace_root": str(_workspace_root(project_root)),
        "exists": False,
        "is_complete": False,
        "project_name": "",
        "task_count": 0,
        "missing_fields": [],
        "errors": [],
    }

    payload, error = _safe_json_load(path)
    if error:
        result["errors"].append(f"missing or invalid /designs/coder_page_tasks.json: {error}")
        return json.dumps(result, ensure_ascii=False, indent=2)

    payload = _normalize_coder_task_bundle(payload)
    result["exists"] = True
    result["project_name"] = str(payload.get("project_name") or "")
    tasks = list(payload.get("tasks") or [])
    result["task_count"] = len(tasks)

    if not result["project_name"]:
        result["missing_fields"].append("project_name")

    if not tasks:
        result["missing_fields"].append("tasks")

    for idx, task in enumerate(tasks):
        if not isinstance(task, dict):
            result["errors"].append(f"task at index {idx} is not an object")
            continue

        for field in ("page_id", "page_name", "route", "page_file"):
            if not str(task.get(field) or "").strip():
                result["missing_fields"].append(f"tasks[{idx}].{field}")

        allowed_write_paths = task.get("allowed_write_paths")
        if not isinstance(allowed_write_paths, list) or not allowed_write_paths:
            result["missing_fields"].append(f"tasks[{idx}].allowed_write_paths")

    result["is_complete"] = (
        result["exists"]
        and len(result["errors"]) == 0
        and len(result["missing_fields"]) == 0
        and result["task_count"] > 0
    )

    return json.dumps(result, ensure_ascii=False, indent=2)


def check_coder_page_worker_results(project_root: Path | None = None) -> str:
    path = _coder_page_worker_results_path(project_root=project_root)
    result: dict[str, Any] = {
        "stage": "coder_page_workers",
        "workspace_root": str(_workspace_root(project_root)),
        "exists": False,
        "is_complete": False,
        "project_name": "",
        "result_count": 0,
        "status_summary": {},
        "missing_fields": [],
        "errors": [],
    }

    payload, error = _safe_json_load(path)
    if error:
        result["errors"].append(f"missing or invalid /logs/coder/page_worker_results.json: {error}")
        return json.dumps(result, ensure_ascii=False, indent=2)

    result["exists"] = True
    result["project_name"] = str(payload.get("project_name") or "")
    rows = payload.get("results")
    if not isinstance(rows, list):
        result["errors"].append("results must be a list")
        return json.dumps(result, ensure_ascii=False, indent=2)

    result["result_count"] = len(rows)
    status_summary: dict[str, int] = {}

    for idx, row in enumerate(rows):
        if not isinstance(row, dict):
            result["errors"].append(f"results[{idx}] is not an object")
            continue

        page_name = str(row.get("page_name") or "").strip()
        status = str(row.get("status") or "").strip()

        if not page_name:
            result["missing_fields"].append(f"results[{idx}].page_name")
        if not status:
            result["missing_fields"].append(f"results[{idx}].status")

        if status:
            status_summary[status] = status_summary.get(status, 0) + 1

    result["status_summary"] = status_summary
    result["is_complete"] = (
        result["exists"]
        and len(result["errors"]) == 0
        and len(result["missing_fields"]) == 0
        and result["result_count"] > 0
    )

    return json.dumps(result, ensure_ascii=False, indent=2)


def check_coder_integration_report(project_root: Path | None = None) -> str:
    path = _coder_integration_report_path(project_root=project_root)
    result: dict[str, Any] = {
        "stage": "coder_integration",
        "workspace_root": str(_workspace_root(project_root)),
        "exists": False,
        "is_complete": False,
        "compile_status": "",
        "project_name": "",
        "project_path": "",
        "ready_for_tester": None,
        "missing_fields": [],
        "errors": [],
    }

    payload, error = _safe_json_load(path)
    if error:
        result["errors"].append(f"missing or invalid /logs/coder/integration_report.json: {error}")
        return json.dumps(result, ensure_ascii=False, indent=2)

    result["exists"] = True
    result["compile_status"] = str(payload.get("compile_status") or "")
    result["project_name"] = str(payload.get("project_name") or "")
    result["project_path"] = str(payload.get("project_path") or "")
    result["ready_for_tester"] = payload.get("ready_for_tester")

    for field in ("compile_status", "project_name", "project_path"):
        if not str(payload.get(field) or "").strip():
            result["missing_fields"].append(field)

    result["is_complete"] = (
        result["exists"]
        and len(result["errors"]) == 0
        and len(result["missing_fields"]) == 0
    )

    return json.dumps(result, ensure_ascii=False, indent=2)


def inspect_coder_artifacts(project_root: Path | None = None) -> str:
    skeleton = json.loads(check_coder_skeleton_artifacts(project_root=project_root))
    page_workers = json.loads(check_coder_page_worker_results(project_root=project_root))
    integration = json.loads(check_coder_integration_report(project_root=project_root))

    latest_completed_stage = None
    if integration.get("is_complete"):
        latest_completed_stage = "coder_integration"
    elif page_workers.get("is_complete"):
        latest_completed_stage = "coder_page_workers"
    elif skeleton.get("is_complete"):
        latest_completed_stage = "coder_skeleton"

    result = {
        "workspace_root": str(_workspace_root(project_root)),
        "latest_completed_stage": latest_completed_stage,
        "coder_skeleton": skeleton,
        "coder_page_workers": page_workers,
        "coder_integration": integration,
    }
    return json.dumps(result, ensure_ascii=False, indent=2)


# ---------------------------------------------------------------------------
# Public tool
# ---------------------------------------------------------------------------


@tool
def materialize_coder_skeleton_artifacts(payload: dict[str, Any]) -> str:
    """
    Materialize the coder skeleton into an existing project and persist the
    canonical /designs/coder_page_tasks.json bundle.

    Prerequisite:
    - create_project(project_name) must already have created /projects/<project_name>

    Shared navigation behavior:
    - Not created automatically just because there are multiple pages
    - Created only when payload.shared_navigation.enabled = true
      or tasks explicitly depend on BottomNavBar / NavigationService
    - Page-level shared navigation usage is not inferred by the tool; it must
      be explicitly declared in task.shared_dependencies

    Supports fallback generation from:
    - /designs/page_merge_index.json
    - /designs/navigation_design.json
    - /designs/pages/*.json
    """
    return materialize_coder_skeleton(payload)