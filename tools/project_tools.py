from __future__ import annotations

import json
import re
import shutil
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import List

from langchain.tools import tool

from tools.common import PROJECT_ROOT, projects_root

PROJECT_NAME_PATTERN = re.compile(r"^[a-z][a-z0-9_]{0,199}$")
TEMPLATE_ROOT = PROJECT_ROOT / "template"
TEMPLATE_PROJECT_DIR = TEMPLATE_ROOT / "MyApplication"
INSTALL_DEPENDENCIES_SCRIPT = PROJECT_ROOT / "scripts" / "install_dependencies.sh"
COMPILE_SCRIPT = PROJECT_ROOT / "scripts" / "compile.sh"
PROJECT_MANIFEST_RELATIVE_PATH = Path("logs") / "coder" / "project_manifest.json"
TEMPLATE_IGNORE_PATTERNS = shutil.ignore_patterns(
    ".git",
    ".idea",
    ".hvigor",
    "oh_modules",
    "build",
    "node_modules",
    "local.properties",
    "oh-package-lock.json5",
    "*.log",
)


def _summarize_compile_output(project_name: str, project_path: str, output: str, exit_code: int) -> str:
    lines = [line.rstrip() for line in output.splitlines() if line.strip()]

    failed_step = None
    for line in lines:
        if line.startswith("[compile] FAIL "):
            failed_step = line[len("[compile] FAIL ") :]
            break

    error_pattern = re.compile(
        r"(error|fail|exception|arkts|typescript|module not found|cannot find|syntax)", re.IGNORECASE
    )
    error_lines: List[str] = []
    seen = set()
    for line in lines:
        if error_pattern.search(line):
            normalized = line.strip()
            if normalized not in seen:
                seen.add(normalized)
                error_lines.append(normalized)
        if len(error_lines) >= 12:
            break

    tail_lines = lines[-40:] if lines else []
    status = "SUCCESS" if exit_code == 0 else "FAILED"

    parts = [
        f"compile_status: {status}",
        f"project_name: {project_name}",
        f"project_path: /projects/{project_name}",
        f"exit_code: {exit_code}",
    ]

    if failed_step:
        parts.append(f"failed_step: {failed_step}")

    if error_lines:
        parts.append("key_errors:")
        parts.extend(f"- {line}" for line in error_lines)
    else:
        parts.append("key_errors:")
        parts.append("- No concise error line was extracted. Check the recent log tail below.")

    parts.append("recent_log_tail:")
    if tail_lines:
        parts.extend(tail_lines)
    else:
        parts.append("(no output)")

    return "\n".join(parts)


def _load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def _write_json(path: Path, data: dict) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")


def project_manifest_path() -> Path:
    return projects_root().parent / PROJECT_MANIFEST_RELATIVE_PATH


def session_project_names() -> list[str]:
    root = projects_root()
    if not root.exists():
        return []
    return sorted(
        path.name
        for path in root.iterdir()
        if path.is_dir() and not path.name.startswith(".")
    )


def load_project_manifest() -> dict:
    path = project_manifest_path()
    if not path.exists():
        return {}
    try:
        payload = _load_json(path)
    except Exception:
        return {}
    if not isinstance(payload, dict):
        return {}
    project_name = str(payload.get("project_name") or "").strip()
    if not PROJECT_NAME_PATTERN.fullmatch(project_name):
        return {}
    return payload


def save_project_manifest(project_name: str, source: str = "create_project") -> None:
    path = project_manifest_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    _write_json(
        path,
        {
            "schema_version": "project_manifest.v1",
            "project_name": project_name,
            "project_path": f"/projects/{project_name}",
            "source": source,
            "updated_at": datetime.now(timezone.utc).isoformat(),
        },
    )


def get_canonical_project_name() -> str:
    manifest = load_project_manifest()
    project_name = str(manifest.get("project_name") or "").strip()
    if project_name:
        return project_name

    names = session_project_names()
    if len(names) == 1:
        return names[0]
    return ""


def _configure_project_metadata(project_name: str, target_dir: Path) -> None:
    app_json_path = target_dir / "AppScope" / "app.json5"
    if app_json_path.exists():
        app_json = _load_json(app_json_path)
        app_config = app_json.setdefault("app", {})
        app_config["bundleName"] = f"com.example.{project_name}"
        _write_json(app_json_path, app_json)


def _install_project_dependencies(target_dir: Path) -> tuple[int, str]:
    result = subprocess.run(
        ["bash", str(INSTALL_DEPENDENCIES_SCRIPT), str(target_dir)],
        cwd=target_dir,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="ignore",
    )
    output = "\n".join(part for part in [result.stdout, result.stderr] if part).strip()
    return result.returncode, output


@tool
def create_project(project_name: str) -> str:
    """
    Create a HarmonyOS project by copying from local template.
    """
    print("start creating project from template")
    if not PROJECT_NAME_PATTERN.fullmatch(project_name):
        return (
            "status: FAILED\n"
            f"project_name: {project_name}\n"
            "error: invalid project_name; use snake_case starting with a lowercase letter, "
            "letters/numbers/underscore only, max 200 chars\n"
            "example: calculator_app"
        )

    root = projects_root()
    root.mkdir(parents=True, exist_ok=True)
    target_dir = root / project_name

    manifest = load_project_manifest()
    manifest_project = str(manifest.get("project_name") or "").strip()
    if manifest_project:
        if manifest_project != project_name:
            return (
                "status: BLOCKED\n"
                f"requested_project_name: {project_name}\n"
                f"canonical_project_name: {manifest_project}\n"
                f"canonical_project_path: /projects/{manifest_project}\n"
                "error: this session already has a canonical project; reuse it instead of creating a second project"
            )
        if target_dir.exists():
            return (
                "status: SUCCESS\n"
                f"project_name: {project_name}\n"
                f"project_path: /projects/{project_name}\n"
                "create_mode: reuse-existing\n"
                "canonical_project: true"
            )

    existing_projects = session_project_names()
    if not manifest_project and len(existing_projects) > 1:
        return (
            "status: BLOCKED\n"
            f"requested_project_name: {project_name}\n"
            f"existing_projects: {', '.join(existing_projects)}\n"
            "error: multiple projects already exist and no canonical manifest is present; choose one project before continuing"
        )

    if not manifest_project and len(existing_projects) == 1:
        existing_project = existing_projects[0]
        if existing_project != project_name:
            save_project_manifest(existing_project, source="adopt_existing_single_project")
            return (
                "status: BLOCKED\n"
                f"requested_project_name: {project_name}\n"
                f"canonical_project_name: {existing_project}\n"
                f"canonical_project_path: /projects/{existing_project}\n"
                "error: this session already contains one project; reuse the canonical project instead of creating a second project"
            )
        save_project_manifest(project_name, source="adopt_existing_single_project")
        return (
            "status: SUCCESS\n"
            f"project_name: {project_name}\n"
            f"project_path: /projects/{project_name}\n"
            "create_mode: reuse-existing\n"
            "canonical_project: true"
        )

    if not TEMPLATE_PROJECT_DIR.exists():
        return (
            "status: FAILED\n"
            f"project_name: {project_name}\n"
            "error: template project not found at template/MyApplication"
        )

    if target_dir.exists():
        save_project_manifest(project_name, source="adopt_existing_target")
        return (
            "status: SUCCESS\n"
            f"project_name: {project_name}\n"
            f"project_path: /projects/{project_name}\n"
            "create_mode: reuse-existing\n"
            "canonical_project: true"
        )

    shutil.copytree(TEMPLATE_PROJECT_DIR, target_dir, ignore=TEMPLATE_IGNORE_PATTERNS)
    _configure_project_metadata(project_name, target_dir)
    save_project_manifest(project_name, source="create_project")

    install_exit_code, install_output = _install_project_dependencies(target_dir)
    if install_exit_code != 0:
        install_tail = "\n".join(install_output.splitlines()[-20:]) if install_output else "(no output)"
        return (
            "status: FAILED\n"
            f"project_name: {project_name}\n"
            f"project_path: /projects/{project_name}\n"
            "create_mode: template-copy\n"
            "canonical_project: true\n"
            f"install_exit_code: {install_exit_code}\n"
            "recent_install_log_tail:\n"
            f"{install_tail}"
        )

    return (
        "status: SUCCESS\n"
        f"project_name: {project_name}\n"
        f"project_path: /projects/{project_name}\n"
        "create_mode: template-copy\n"
        "template_source: /template/MyApplication\n"
        "canonical_project: true\n"
        "dependencies: installed with ohpm install --all"
    )

    if not PROJECT_NAME_PATTERN.fullmatch(project_name):
        return (
            "项目名不合法。必须以小写字母开头，只能包含小写字母、数字和下划线(_)；长度 1-200。"
            "合法示例: calculator_app；非法示例: calc-app、my app、计算器、CalculatorApp。"
        )

    if not TEMPLATE_PROJECT_DIR.exists():
        return "项目创建失败：未找到模板工程。请确认目录存在：/template/MyApplication"

    root = projects_root()
    target_dir = root / project_name
    if target_dir.exists():
        return f"项目创建失败：目标目录已存在 /projects/{project_name}。请更换项目名或先清理目录。"

    root.mkdir(parents=True, exist_ok=True)
    shutil.copytree(TEMPLATE_PROJECT_DIR, target_dir, ignore=TEMPLATE_IGNORE_PATTERNS)
    _configure_project_metadata(project_name, target_dir)

    install_exit_code, install_output = _install_project_dependencies(target_dir)
    if install_exit_code != 0:
        install_tail = "\n".join(install_output.splitlines()[-20:]) if install_output else "(no output)"
        return (
            f"项目模板已复制到 /projects/{project_name}，但依赖安装失败。\n"
            f"install_exit_code: {install_exit_code}\n"
            "recent_install_log_tail:\n"
            f"{install_tail}"
        )

    return (
        f"项目创建完成，路径为: /projects/{project_name}\n"
        "create_mode: template-copy\n"
        "template_source: /template/MyApplication\n"
        "dependencies: installed with ohpm install --all"
    )


@tool
def compile_project(project_name: str) -> str:
    """
    Compile a HarmonyOS project and return a summarized output.
    """
    print("start compiling project by hdc build")
    requested_project_name = str(project_name or "").strip()
    canonical_project_name = get_canonical_project_name()
    if canonical_project_name:
        if requested_project_name and requested_project_name != canonical_project_name:
            return (
                "compile_status: FAILED\n"
                f"project_name: {canonical_project_name}\n"
                f"project_path: /projects/{canonical_project_name}\n"
                "exit_code: 1\n"
                "key_errors:\n"
                f"- Requested project '{requested_project_name}' does not match canonical project '{canonical_project_name}'."
            )
        project_name = canonical_project_name
    elif not requested_project_name:
        return (
            "compile_status: FAILED\n"
            "project_name: \n"
            "project_path: \n"
            "exit_code: 1\n"
            "key_errors:\n"
            "- No project_name was provided and no canonical project exists."
        )
    else:
        names = session_project_names()
        if len(names) > 1:
            return (
                "compile_status: FAILED\n"
                "project_name: \n"
                "project_path: \n"
                "exit_code: 1\n"
                "key_errors:\n"
                f"- Multiple projects exist without a canonical manifest: {', '.join(names)}."
            )
        project_name = requested_project_name

    project_path = str((projects_root() / project_name).resolve())
    result = subprocess.run(
        ["bash", str(COMPILE_SCRIPT), project_path],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="ignore",
    )
    combined_output = "\n".join(part for part in [result.stdout, result.stderr] if part)
    return _summarize_compile_output(
        project_name=project_name,
        project_path=project_path,
        output=combined_output,
        exit_code=result.returncode,
    )


CODER_TOOLS = [
    create_project,
    compile_project,
]


def coder_tool_names() -> list[str]:
    return [tool.name for tool in CODER_TOOLS]
