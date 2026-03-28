from __future__ import annotations

import re
from pathlib import Path

DEFAULT_SESSION_ID = "default"
_SESSION_ID_SAFE_PATTERN = re.compile(r"[^a-zA-Z0-9._-]+")


def normalize_session_id(raw_session_id: str | None) -> str:
    raw = str(raw_session_id or "").strip()
    if not raw:
        return DEFAULT_SESSION_ID

    normalized = _SESSION_ID_SAFE_PATTERN.sub("_", raw).strip("._-")
    if not normalized:
        return DEFAULT_SESSION_ID

    # Keep directory names compact and predictable.
    return normalized[:80]


def session_workspace_dir(project_root: Path, session_id: str | None) -> Path:
    normalized = normalize_session_id(session_id)
    return project_root / "agent_workspace" / "sessions" / normalized


def session_user_input_dir(project_root: Path, session_id: str | None) -> Path:
    return session_workspace_dir(project_root, session_id) / "user_input"


def session_user_input_meta_path(project_root: Path, session_id: str | None) -> Path:
    return session_user_input_dir(project_root, session_id) / "user_input_metadata.json"


def session_description_md_path(project_root: Path, session_id: str | None) -> Path:
    return session_user_input_dir(project_root, session_id) / "description.md"
