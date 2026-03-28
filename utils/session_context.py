from __future__ import annotations

from contextvars import ContextVar, Token

from utils.session_workspace import DEFAULT_SESSION_ID, normalize_session_id

_CURRENT_SESSION_ID: ContextVar[str] = ContextVar("current_session_id", default=DEFAULT_SESSION_ID)


def get_current_session_id() -> str:
    return _CURRENT_SESSION_ID.get()


def set_current_session_id(session_id: str | None) -> Token[str]:
    normalized = normalize_session_id(session_id)
    return _CURRENT_SESSION_ID.set(normalized)


def reset_current_session_id(token: Token[str]) -> None:
    _CURRENT_SESSION_ID.reset(token)
