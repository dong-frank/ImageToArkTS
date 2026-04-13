from __future__ import annotations

import json
import re
import shutil
import subprocess
from pathlib import Path
from typing import List

from langchain.tools import tool

from tools.common import PROJECT_ROOT, projects_root

PROJECT_NAME_PATTERN = re.compile(r"^[a-z][a-z0-9_]{0,199}$")
TEMPLATE_ROOT = PROJECT_ROOT / "template"
TEMPLATE_PROJECT_DIR = TEMPLATE_ROOT / "MyApplication"
CREATE_PROJECT_SCRIPT = PROJECT_ROOT / "scripts" / "create_project.sh"
INSTALL_DEPENDENCIES_SCRIPT = PROJECT_ROOT / "scripts" / "install_dependencies.sh"
COMPILE_SCRIPT = PROJECT_ROOT / "scripts" / "compile.sh"
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


def _run_create_project_script(project_name: str, target_root: Path) -> tuple[int, str]:
    result = subprocess.run(
        ["bash", str(CREATE_PROJECT_SCRIPT), project_name],
        cwd=target_root,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="ignore",
    )
    output = "\n".join(part for part in [result.stdout, result.stderr] if part).strip()
    return result.returncode, output


def _run_npm_install_package(target_dir: Path, package_name: str, dev_dependency: bool) -> tuple[int, str]:
    cmd = ["npm", "install"]
    if dev_dependency:
        cmd.append("-D")
    cmd.append(package_name)
    result = subprocess.run(
        cmd,
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
    Create a project through the unified CLI bootstrap script.
    """
    print("start creating project via unified create script")
    if not PROJECT_NAME_PATTERN.fullmatch(project_name):
        return (
            "项目名不合法。必须以小写字母开头，只能包含小写字母、数字和下划线(_)；长度 1-200。"
            "合法示例: calculator_app；非法示例: calc-app、my app、计算器、CalculatorApp。"
        )

    root = projects_root()
    target_dir = root / project_name
    if target_dir.exists():
        return f"项目创建失败：目标目录已存在 /projects/{project_name}。请更换项目名或先清理目录。"

    if not CREATE_PROJECT_SCRIPT.exists():
        return "项目创建失败：未找到统一创建脚本。请确认目录存在：/scripts/create_project.sh"

    root.mkdir(parents=True, exist_ok=True)
    create_exit_code, create_output = _run_create_project_script(project_name, root)
    if create_exit_code != 0:
        create_tail = "\n".join(create_output.splitlines()[-20:]) if create_output else "(no output)"
        return (
            f"项目创建失败：统一脚本执行异常 /projects/{project_name}\n"
            f"create_exit_code: {create_exit_code}\n"
            "recent_create_log_tail:\n"
            f"{create_tail}"
        )

    return (
        f"项目创建完成，路径为: /projects/{project_name}\n"
        f"project_path: /projects/{project_name}\n"
        "create_mode: script\n"
        "template_source: /template/uni-preset-vue-vite\n"
        "runtime_shell_template: /template/uni-harmony-shell-template\n"
        "dependencies: pending (run npm install manually)\n"
        "build_flow: npm run build:harmony:cli"
    )


@tool
def compile_project(project_name: str) -> str:
    """
    Compile a HarmonyOS project and return a summarized output.
    """
    print("start compiling project by hdc build")
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


@tool
def add_project_dependency(project_name: str, package_name: str, dev_dependency: bool = True) -> str:
    """
    Add a specific npm dependency inside a project so integration can resolve missing packages on demand.
    """
    print("start adding project npm dependency")
    project_dir = projects_root() / project_name
    if not project_dir.exists():
        return f"依赖添加失败：项目目录不存在 /projects/{project_name}"

    package_json = project_dir / "package.json"
    if not package_json.exists():
        return f"依赖添加失败：未找到 package.json /projects/{project_name}/package.json"

    package_name = str(package_name or "").strip()
    if not package_name:
        return "依赖添加失败：package_name 不能为空"

    exit_code, output = _run_npm_install_package(project_dir, package_name, dev_dependency)
    install_tail = "\n".join(output.splitlines()[-30:]) if output else "(no output)"
    status = "SUCCESS" if exit_code == 0 else "FAILED"
    return "\n".join(
        [
            f"dependency_add_status: {status}",
            f"project_name: {project_name}",
            f"project_path: /projects/{project_name}",
            f"package_name: {package_name}",
            f"dependency_scope: {'devDependency' if dev_dependency else 'dependency'}",
            f"exit_code: {exit_code}",
            "recent_dependency_log_tail:",
            install_tail,
        ]
    )


CODER_TOOLS = [
    create_project,
    add_project_dependency,
    compile_project,
]


def coder_tool_names() -> list[str]:
    return [tool.name for tool in CODER_TOOLS]
