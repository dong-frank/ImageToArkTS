from __future__ import annotations

import json
from copy import deepcopy
from datetime import datetime, timezone
from pathlib import Path
from threading import Lock
from typing import Any

from langchain_core.messages import BaseMessage

from utils.session_context import get_current_session_id
from utils.session_workspace import normalize_session_id, session_workspace_dir

PROJECT_ROOT = Path(__file__).resolve().parent.parent
_METRICS_LOCK = Lock()

_ZERO_TOKEN_USAGE = {
    "input_tokens": 0,
    "output_tokens": 0,
    "total_tokens": 0,
    "reasoning_tokens": 0,
    "cache_read_tokens": 0,
    "cache_write_tokens": 0,
}

_EMPTY_METRICS_TEMPLATE = {
    "session_id": "",
    "phase_scope": "full_run_until_coding_end",
    "started_at": None,
    "finished_at": None,
    "total_elapsed_seconds": None,
    "compile_count": 0,
    "token_usage": _ZERO_TOKEN_USAGE,
}

_TOKEN_ALIASES = {
    "input_tokens": ("input_tokens", "prompt_tokens"),
    "output_tokens": ("output_tokens", "completion_tokens"),
    "total_tokens": ("total_tokens",),
    "reasoning_tokens": ("reasoning_tokens", "output_token_details.reasoning"),
    "cache_read_tokens": ("cache_read_tokens", "input_token_details.cache_read"),
    "cache_write_tokens": ("cache_write_tokens", "input_token_details.cache_creation"),
}


def _utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="milliseconds")


def _parse_iso(raw: Any) -> datetime | None:
    text = str(raw or "").strip()
    if not text:
        return None
    try:
        return datetime.fromisoformat(text)
    except ValueError:
        return None


def _metrics_dir(session_id: str | None = None) -> Path:
    normalized = normalize_session_id(session_id or get_current_session_id())
    return session_workspace_dir(PROJECT_ROOT, normalized) / "logs" / "experiment_metrics"


def experiment_metrics_path(session_id: str | None = None) -> Path:
    normalized = normalize_session_id(session_id or get_current_session_id())
    return _metrics_dir(normalized) / f"{normalized}.json"


def _new_metrics(session_id: str) -> dict[str, Any]:
    metrics = deepcopy(_EMPTY_METRICS_TEMPLATE)
    metrics["session_id"] = normalize_session_id(session_id)
    return metrics


def _load_metrics_locked(session_id: str) -> dict[str, Any]:
    path = experiment_metrics_path(session_id)
    if not path.exists():
        return _new_metrics(session_id)

    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return _new_metrics(session_id)

    metrics = _new_metrics(session_id)
    if isinstance(data, dict):
        metrics.update({k: v for k, v in data.items() if k in metrics})
        token_usage = data.get("token_usage")
        if isinstance(token_usage, dict):
            merged_usage = deepcopy(_ZERO_TOKEN_USAGE)
            for key in merged_usage:
                merged_usage[key] = _coerce_non_negative_int(token_usage.get(key))
            metrics["token_usage"] = merged_usage
    return metrics


def _save_metrics_locked(session_id: str, metrics: dict[str, Any]) -> dict[str, Any]:
    path = experiment_metrics_path(session_id)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(metrics, ensure_ascii=False, indent=2), encoding="utf-8")
    return metrics


def load_metrics(session_id: str | None = None) -> dict[str, Any]:
    normalized = normalize_session_id(session_id or get_current_session_id())
    with _METRICS_LOCK:
        return deepcopy(_load_metrics_locked(normalized))


def reset_metrics_for_new_run(session_id: str | None = None, *, started_at: str | None = None) -> dict[str, Any]:
    normalized = normalize_session_id(session_id or get_current_session_id())
    metrics = _new_metrics(normalized)
    metrics["started_at"] = started_at or _utc_now_iso()
    with _METRICS_LOCK:
        return deepcopy(_save_metrics_locked(normalized, metrics))


def ensure_metrics_file(session_id: str | None = None) -> dict[str, Any]:
    normalized = normalize_session_id(session_id or get_current_session_id())
    with _METRICS_LOCK:
        metrics = _load_metrics_locked(normalized)
        return deepcopy(_save_metrics_locked(normalized, metrics))


def mark_run_finished(session_id: str | None = None, *, finished_at: str | None = None) -> dict[str, Any]:
    normalized = normalize_session_id(session_id or get_current_session_id())
    finished = finished_at or _utc_now_iso()
    with _METRICS_LOCK:
        metrics = _load_metrics_locked(normalized)
        metrics["finished_at"] = finished

        started = _parse_iso(metrics.get("started_at"))
        ended = _parse_iso(finished)
        if started is not None and ended is not None:
            metrics["total_elapsed_seconds"] = max(0.0, round((ended - started).total_seconds(), 3))

        return deepcopy(_save_metrics_locked(normalized, metrics))


def increment_compile_count(session_id: str | None = None) -> dict[str, Any]:
    normalized = normalize_session_id(session_id or get_current_session_id())
    with _METRICS_LOCK:
        metrics = _load_metrics_locked(normalized)
        metrics["compile_count"] = _coerce_non_negative_int(metrics.get("compile_count")) + 1
        return deepcopy(_save_metrics_locked(normalized, metrics))


def _coerce_non_negative_int(value: Any) -> int:
    if isinstance(value, bool):
        return int(value)
    try:
        parsed = int(value)
    except (TypeError, ValueError):
        return 0
    return max(0, parsed)


def _extract_nested_value(data: dict[str, Any], path: str) -> Any:
    current: Any = data
    for part in path.split("."):
        if not isinstance(current, dict):
            return None
        current = current.get(part)
    return current


def _extract_usage_from_mapping(data: dict[str, Any]) -> dict[str, int]:
    usage = deepcopy(_ZERO_TOKEN_USAGE)
    found = False
    for key, aliases in _TOKEN_ALIASES.items():
        for alias in aliases:
            value = _extract_nested_value(data, alias)
            if value is None:
                continue
            usage[key] = _coerce_non_negative_int(value)
            found = True
            break
    return usage if found else {}


def _usage_candidates(container: Any) -> list[dict[str, Any]]:
    if not isinstance(container, dict):
        return []

    candidates = [container]
    for key in ("usage_metadata", "usage", "token_usage"):
        value = container.get(key)
        if isinstance(value, dict):
            candidates.append(value)

    return candidates


def extract_token_usage(payload: Any) -> dict[str, int]:
    if isinstance(payload, BaseMessage):
        containers = [
            getattr(payload, "usage_metadata", None),
            getattr(payload, "response_metadata", None),
            getattr(payload, "additional_kwargs", None),
        ]
    else:
        containers = [payload]

    merged: dict[str, int] = {}
    for container in containers:
        for candidate in _usage_candidates(container):
            usage = _extract_usage_from_mapping(candidate)
            if not usage:
                continue
            for key, value in usage.items():
                merged[key] = _coerce_non_negative_int(value)
    return merged


def merge_token_usage(token_usage: Any, session_id: str | None = None) -> dict[str, Any]:
    usage = extract_token_usage(token_usage)
    if not usage:
        return load_metrics(session_id)

    normalized = normalize_session_id(session_id or get_current_session_id())
    with _METRICS_LOCK:
        metrics = _load_metrics_locked(normalized)
        merged_usage = metrics.get("token_usage") or deepcopy(_ZERO_TOKEN_USAGE)
        for key in _ZERO_TOKEN_USAGE:
            merged_usage[key] = _coerce_non_negative_int(merged_usage.get(key)) + _coerce_non_negative_int(usage.get(key))
        metrics["token_usage"] = merged_usage
        return deepcopy(_save_metrics_locked(normalized, metrics))


def merge_token_usage_from_result(result: Any, session_id: str | None = None) -> dict[str, Any]:
    for usage in iter_token_usage(result):
        merge_token_usage(usage, session_id)
    return load_metrics(session_id)


def iter_token_usage(payload: Any) -> list[dict[str, int]]:
    collected: list[dict[str, int]] = []

    def _walk(value: Any) -> None:
        usage = extract_token_usage(value)
        if usage:
            collected.append(usage)

        if isinstance(value, BaseMessage):
            content = getattr(value, "content", None)
            if isinstance(content, list):
                for item in content:
                    _walk(item)
            return

        if isinstance(value, dict):
            for item in value.values():
                _walk(item)
            return

        if isinstance(value, (list, tuple, set)):
            for item in value:
                _walk(item)

    _walk(payload)
    return collected
