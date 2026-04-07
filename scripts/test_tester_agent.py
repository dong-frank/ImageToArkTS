#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any, Iterable, Optional

PROJECT_ROOT = Path(__file__).resolve().parents[1]
WORKSPACE_ROOT = PROJECT_ROOT / "agent_workspace"

# Ensure project-root modules (e.g. models.py, tools.py) are importable
# when running this script via "python scripts/test_tester_agent.py".
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))


def _infer_project_name() -> Optional[str]:
    projects_root = _projects_root(None)
    if not projects_root.exists():
        return None
    dirs = sorted([p for p in projects_root.iterdir() if p.is_dir()])
    if len(dirs) == 1:
        return dirs[0].name
    return None


def _session_workspace_root(session_id: Optional[str]) -> Path:
    from utils.session_workspace import session_workspace_dir

    return session_workspace_dir(PROJECT_ROOT, session_id)


def _projects_root(session_id: Optional[str]) -> Path:
    return _session_workspace_root(session_id) / "projects"


def _build_default_prompt(project_name: str) -> str:
    return (
        "请你作为独立 tester 子代理执行一次完整验收。\n"
        f"待测项目路径：/projects/{project_name}\n"
        "严格按照 tester 系统提示里的流程执行工具调用，并输出符合 TesterReportOutput 的 JSON 结果。\n"
        "若未显式给出 bundleName，请先从 /projects/<project_name>/AppScope/app.json5 读取后再启动应用。"
    )


def _content_to_text(content: Any) -> str:
    if content is None:
        return ""
    if isinstance(content, str):
        return content
    if isinstance(content, dict):
        value = content.get("text")
        return value if isinstance(value, str) else json.dumps(content, ensure_ascii=False)
    if isinstance(content, Iterable) and not isinstance(content, (str, bytes)):
        chunks: list[str] = []
        for item in content:
            if isinstance(item, str):
                chunks.append(item)
            elif isinstance(item, dict):
                maybe_text = item.get("text")
                if isinstance(maybe_text, str):
                    chunks.append(maybe_text)
            else:
                chunks.append(str(item))
        return "".join(chunks)
    return str(content)


def _extract_last_assistant_text(result: Any) -> str:
    if isinstance(result, dict):
        messages = result.get("messages")
        if isinstance(messages, list):
            for message in reversed(messages):
                role = getattr(message, "type", None) or getattr(message, "role", None)
                if role in {"ai", "assistant"}:
                    return _content_to_text(getattr(message, "content", ""))
                if isinstance(message, dict) and message.get("role") == "assistant":
                    return _content_to_text(message.get("content", ""))
        output = result.get("output")
        if output is not None:
            return _content_to_text(output)

    if hasattr(result, "content"):
        return _content_to_text(getattr(result, "content", ""))

    return str(result)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Run tester agent in isolation.")
    parser.add_argument(
        "--session-id",
        default="default",
        help="Session id under /agent_workspace/sessions/<session_id>.",
    )
    parser.add_argument(
        "--project-name",
        default="",
        help="Project folder under /agent_workspace/sessions/<session_id>/projects. Auto-infer if omitted and only one project exists.",
    )
    parser.add_argument(
        "--prompt",
        default="",
        help="Custom user prompt to tester agent. If omitted, a default tester prompt is generated.",
    )
    parser.add_argument(
        "--save-output",
        default="",
        help="Optional workspace-relative output file path, e.g. /logs/tester/standalone_tester_output.md",
    )
    parser.add_argument(
        "--print-raw",
        action="store_true",
        help="Print raw invoke result after the extracted assistant text.",
    )
    parser.add_argument(
        "--architect-json-path",
        default="/designs/architect.json",
        help="Workspace-relative architect json path to inject into tester input.",
    )
    parser.add_argument(
        "--architect-json-max-chars",
        type=int,
        default=120000,
        help="Max chars of architect json injected into prompt.",
    )
    parser.add_argument(
        "--no-architect-json",
        action="store_true",
        help="Disable injecting architect json content into tester user message.",
    )
    return parser


def _normalize_workspace_path(path_value: str) -> Path:
    return _normalize_workspace_path_for_session(path_value, None)


def _normalize_workspace_path_for_session(path_value: str, session_id: Optional[str]) -> Path:
    normalized = path_value.replace("\\", "/").strip()
    if normalized.startswith("/"):
        return _session_workspace_root(session_id) / normalized.lstrip("/")
    return PROJECT_ROOT / normalized


def _compose_prompt_with_architect_json(
    base_prompt: str,
    architect_json_path: Path,
    max_chars: int,
) -> str:
    if not architect_json_path.exists():
        return (
            base_prompt
            + "\n\n[Architect JSON Input]\n"
            + f"path: {architect_json_path}\n"
            + "status: NOT_FOUND"
        )
    if not architect_json_path.is_file():
        return (
            base_prompt
            + "\n\n[Architect JSON Input]\n"
            + f"path: {architect_json_path}\n"
            + "status: INVALID_PATH"
        )

    raw = architect_json_path.read_text(encoding="utf-8", errors="ignore")
    content = raw[:max_chars] if max_chars > 0 else raw
    if len(raw) > len(content):
        content += f"\n\n... [TRUNCATED total={len(raw)} chars]"

    return (
        base_prompt
        + "\n\n[Architect JSON Input]\n"
        + f"path: {architect_json_path}\n"
        + "status: OK\n"
        + "content:\n"
        + content
    )


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    from utils.session_context import reset_current_session_id, set_current_session_id
    from utils.session_workspace import normalize_session_id

    session_id = normalize_session_id(args.session_id)

    try:
        from deepagents import create_deep_agent
        from deepagents.backends import FilesystemBackend

        from models import vision_model
        from tools import TESTER_TOOLS
        from utils.utils import load_prompt
    except ModuleNotFoundError as exc:
        print(
            "Missing dependency for tester runner. "
            "Please install project dependencies first (for example: `uv sync`)."
        )
        print(f"import error: {exc}")
        return 2

    projects_root = _projects_root(session_id)
    project_name = args.project_name.strip()
    if not project_name:
        if not projects_root.exists():
            project_name = None
        else:
            dirs = sorted([p for p in projects_root.iterdir() if p.is_dir()])
            project_name = dirs[0].name if len(dirs) == 1 else None

    if not project_name:
        print(
            "Cannot determine project_name. Please pass --project-name explicitly, "
            "or keep exactly one project under /agent_workspace/sessions/<session_id>/projects."
        )
        return 2

    project_dir = projects_root / project_name
    if not project_dir.is_dir():
        print(f"Project directory not found: {project_dir}")
        return 2

    user_prompt = args.prompt.strip() or _build_default_prompt(project_name)
    if not args.no_architect_json:
        architect_json_path = _normalize_workspace_path_for_session(args.architect_json_path, session_id)
        user_prompt = _compose_prompt_with_architect_json(
            base_prompt=user_prompt,
            architect_json_path=architect_json_path,
            max_chars=args.architect_json_max_chars,
        )

    session_token = set_current_session_id(session_id)
    tester_agent = create_deep_agent(
        model=vision_model,
        system_prompt=load_prompt("tester_system_prompt.md"),
        backend=FilesystemBackend(root_dir=_session_workspace_root(session_id), virtual_mode=True),
        tools=TESTER_TOOLS,
    )

    try:
        result = tester_agent.invoke(
            {
                "messages": [
                    {
                        "role": "user",
                        "content": user_prompt,
                    }
                ]
            }
        )
    except Exception as exc:  # noqa: BLE001
        print(f"tester invoke failed: {exc}")
        return 1
    finally:
        reset_current_session_id(session_token)

    assistant_text = _extract_last_assistant_text(result)
    print("=== Tester Output ===")
    print(assistant_text or "(empty)")

    if args.print_raw:
        print("\n=== Raw Result ===")
        print(result)

    if args.save_output.strip():
        target = _normalize_workspace_path_for_session(args.save_output, session_id)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(assistant_text or "(empty)\n", encoding="utf-8")
        print(f"\nSaved output to: {target}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
