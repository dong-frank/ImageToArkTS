from langchain.tools import tool
import json
from pathlib import Path
import re
import shutil
import subprocess

PROJECT_NAME_PATTERN = re.compile(r"^[a-z][a-z0-9_]{0,199}$")
PROJECT_ROOT = Path(__file__).resolve().parent
ARCHITECT_DESIGN_PATH = PROJECT_ROOT / "agent_workspace" / "designs" / "architect.json"
PROJECTS_ROOT = PROJECT_ROOT / "agent_workspace" / "projects"
TEMPLATE_ROOT = PROJECT_ROOT / "template"
TEMPLATE_PROJECT_DIR = TEMPLATE_ROOT / "MyApplication"
INSTALL_DEPENDENCIES_SCRIPT = PROJECT_ROOT / "scripts" / "install_dependencies.sh"
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
            failed_step = line[len("[compile] FAIL "):]
            break

    error_pattern = re.compile(
        r"(error|fail|exception|arkts|typescript|module not found|cannot find|syntax)", re.IGNORECASE
    )
    error_lines = []
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


@tool
def create_project(project_name: str) -> str:
    """
    基于本地模板复制创建标准 HarmonyOS 项目。
    项目名称必须以字母开头，只能包含小写字母、数字和下划线(_)，长度1-200。
    Args:
        project_name (str): 项目名称
    """

    if not PROJECT_NAME_PATTERN.fullmatch(project_name):
        return (
            "项目名不合法。必须以小写字母开头，只能包含小写字母、数字和下划线(_)，"
            "长度1-200。合法示例：calculator_app。非法示例：calc-app、my app、计算器、CalculatorApp。"
        )

    if not TEMPLATE_PROJECT_DIR.exists():
        return (
            "项目创建失败：未找到模板工程。"
            "请确认模板目录存在：/template/MyApplication"
        )

    target_dir = PROJECTS_ROOT / project_name
    if target_dir.exists():
        return f"项目创建失败：目标目录已存在 /projects/{project_name}。请更换项目名或先清理目录。"

    PROJECTS_ROOT.mkdir(parents=True, exist_ok=True)
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
    编译鸿蒙项目，并返回所有日志输出
    Args:
        project_name (str): 项目名称
    """

    project_path = f"agent_workspace/projects/{project_name}"
    result = subprocess.run(
        ["bash", "scripts/compile.sh", project_path],
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
def save_architect_design(content: str) -> str:
    """
    将 architect 子Agent的结构化输出保存到固定路径 /designs/architect.json。
    Args:
        content (str): architect 输出的 JSON 字符串
    """

    try:
        parsed = json.loads(content)
    except json.JSONDecodeError as exc:
        return f"保存失败：architect 输出不是合法 JSON。错误：{exc}"

    ARCHITECT_DESIGN_PATH.parent.mkdir(parents=True, exist_ok=True)
    ARCHITECT_DESIGN_PATH.write_text(
        json.dumps(parsed, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    return "architect 设计已保存到 /designs/architect.json"
