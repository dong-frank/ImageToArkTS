from __future__ import annotations

import atexit
import os
from pathlib import Path
from typing import Any

from langgraph.checkpoint.memory import InMemorySaver

PROJECT_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_SQLITE_PATH = PROJECT_ROOT / "agent_workspace" / ".checkpoints" / "deepagents.sqlite"

_checkpointer_ctx = None
_checkpointer = None


def _normalize_backend_name(name: str | None) -> str:
    return str(name or "sqlite").strip().lower()


def get_checkpointer() -> Any:
    global _checkpointer_ctx, _checkpointer

    if _checkpointer is not None:
        return _checkpointer

    backend = _normalize_backend_name(os.getenv("DEEPAGENTS_CHECKPOINTER_BACKEND"))

    if backend == "memory":
        _checkpointer = InMemorySaver()
        return _checkpointer

    if backend == "postgres":
        raise NotImplementedError(
            "Postgres checkpointer is not configured yet. "
            "Set DEEPAGENTS_CHECKPOINTER_BACKEND=sqlite (default) for now."
        )

    if backend != "sqlite":
        raise ValueError(
            f"Unsupported checkpointer backend: {backend}. "
            "Supported values: sqlite, memory, postgres."
        )

    sqlite_path = Path(os.getenv("DEEPAGENTS_CHECKPOINTER_SQLITE_PATH", str(DEFAULT_SQLITE_PATH)))
    sqlite_path.parent.mkdir(parents=True, exist_ok=True)

    from langgraph.checkpoint.sqlite import SqliteSaver

    _checkpointer_ctx = SqliteSaver.from_conn_string(str(sqlite_path))
    _checkpointer = _checkpointer_ctx.__enter__()
    return _checkpointer


def close_checkpointer() -> None:
    global _checkpointer_ctx, _checkpointer

    if _checkpointer_ctx is not None:
        _checkpointer_ctx.__exit__(None, None, None)
        _checkpointer_ctx = None
    _checkpointer = None


atexit.register(close_checkpointer)
