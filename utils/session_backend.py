from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path
from threading import Lock
from typing import Any

from deepagents.backends import CompositeBackend, FilesystemBackend
from deepagents.backends.protocol import BackendProtocol
from langchain.tools import ToolRuntime

from utils.session_workspace import (
    DEFAULT_SESSION_ID,
    normalize_session_id,
    session_workspace_dir,
)


def _extract_thread_id(runtime: ToolRuntime[Any, Any]) -> str:
    config = getattr(runtime, "config", None)
    if not isinstance(config, dict):
        return DEFAULT_SESSION_ID

    configurable = config.get("configurable")
    if not isinstance(configurable, dict):
        return DEFAULT_SESSION_ID

    return normalize_session_id(configurable.get("thread_id"))


@dataclass
class SessionBackendManager:
    project_root: Path
    provider: str = "filesystem"

    def __post_init__(self) -> None:
        self._lock = Lock()
        self._cache: dict[str, BackendProtocol] = {}

    def get_backend(self, session_id: str) -> BackendProtocol:
        session_key = normalize_session_id(session_id)
        with self._lock:
            cached = self._cache.get(session_key)
            if cached is not None:
                return cached

            backend = self._build_backend(session_key)
            self._cache[session_key] = backend
            return backend

    def _build_backend(self, session_id: str) -> BackendProtocol:
        provider = str(self.provider or "filesystem").strip().lower()
        if provider in {"filesystem", "local"}:
            session_root = session_workspace_dir(self.project_root, session_id)
            session_root.mkdir(parents=True, exist_ok=True)
            session_backend = FilesystemBackend(root_dir=session_root, virtual_mode=True)

            shared_skills_root = self.project_root / "agent_workspace" / "skills"
            if shared_skills_root.exists():
                skills_backend = FilesystemBackend(root_dir=shared_skills_root, virtual_mode=True)
                return CompositeBackend(
                    default=session_backend,
                    routes={"/skills/": skills_backend},
                )

            return session_backend

        raise ValueError(
            f"Unsupported SANDBOX_PROVIDER: {provider}. "
            "Supported values right now: filesystem/local."
        )


PROJECT_ROOT = Path(__file__).resolve().parent.parent
_MANAGER = SessionBackendManager(
    project_root=PROJECT_ROOT,
    provider=os.getenv("SANDBOX_PROVIDER", "filesystem"),
)


def backend_factory(runtime: ToolRuntime[Any, Any]) -> BackendProtocol:
    thread_id = _extract_thread_id(runtime)
    return _MANAGER.get_backend(thread_id)


def get_backend_for_session(session_id: str | None) -> BackendProtocol:
    return _MANAGER.get_backend(normalize_session_id(session_id))


def ensure_session_backend_initialized(session_id: str | None) -> None:
    _MANAGER.get_backend(normalize_session_id(session_id))


def sync_local_user_input_to_backend(session_id: str | None) -> None:
    # Local filesystem backend uses the same session workspace as runtime uploads,
    # so no explicit sync is required.
    return


def sync_backend_outputs_to_local(
    session_id: str | None,
    roots: tuple[str, ...] = ("/projects", "/logs", "/designs", "/user_input"),
) -> None:
    # Local filesystem backend writes directly into session workspace,
    # so no explicit sync is required.
    return
