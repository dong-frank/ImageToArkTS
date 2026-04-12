from __future__ import annotations

import json
from pathlib import Path

from langchain.tools import tool

from tools.common import resolve_workspace_path
from utils.session_context import get_current_session_id


def _resolve_json_path(path: str, project_root: Path | None = None) -> Path:
    if project_root is None:
        return resolve_workspace_path(path)
    return project_root / "agent_workspace" / "sessions" / get_current_session_id() / path.lstrip("/")


def _validate_json_syntax(path: str, project_root: Path | None = None) -> str:
    target = _resolve_json_path(path, project_root=project_root)
    if not target.exists():
        return "\n".join(
            [
                "status: MISSING",
                f"path: {path}",
                "error: file not found",
            ]
        )
    if not target.is_file():
        return "\n".join(
            [
                "status: INVALID",
                f"path: {path}",
                "error: target is not a file",
            ]
        )

    try:
        parsed = json.loads(target.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        return "\n".join(
            [
                "status: INVALID",
                f"path: {path}",
                f"line: {exc.lineno}",
                f"column: {exc.colno}",
                f"error: {exc.msg}",
            ]
        )

    json_type = type(parsed).__name__
    if isinstance(parsed, dict):
        json_type = "object"
    elif isinstance(parsed, list):
        json_type = "array"

    return "\n".join(
        [
            "status: VALID",
            f"path: {path}",
            f"json_type: {json_type}",
        ]
    )


@tool
def validate_json_syntax(path: str) -> str:
    """
    Validate whether a JSON file has correct JSON syntax.
    """
    return _validate_json_syntax(path)
