from contextlib import asynccontextmanager
import base64
from collections import deque
from datetime import datetime, timezone
from itertools import count
import json
import mimetypes
from pathlib import Path
import subprocess
import shutil
from threading import Lock
from typing import Any, AsyncIterator, List
from uuid import uuid4

from agentscope_runtime.engine import AgentApp
from agentscope_runtime.engine.schemas.agent_schemas import AgentRequest
from fastapi import Body, File, Form, Request, UploadFile
from fastapi.responses import JSONResponse, StreamingResponse
from langchain_core.messages import AIMessage, AIMessageChunk, BaseMessage, HumanMessage
from langgraph.types import Command

from agent import graph
from utils.session_backend import (
    ensure_session_backend_initialized,
    sync_backend_outputs_to_local,
    sync_local_user_input_to_backend,
)
from utils.session_context import reset_current_session_id, set_current_session_id
from utils.user_input_preparation import (
    load_user_input_metadata_payload,
    prepend_user_input_instruction,
    refresh_user_input_artifacts,
    save_user_input_metadata_payload,
)
from utils.session_workspace import (
    DEFAULT_SESSION_ID,
    normalize_session_id,
    session_user_input_dir,
    session_workspace_dir,
)

PROJECT_ROOT = Path(__file__).resolve().parent
AGENT_WORKSPACE_DIR = PROJECT_ROOT / "agent_workspace"
RESET_SCRIPT_PATH = PROJECT_ROOT / "scripts" / "reset_agent_workspace.sh"
LOG_DIR = PROJECT_ROOT / "logs"
STREAM_TIMING_LOG_PATH = LOG_DIR / "runtime_stream_timing.log"
STREAM_TIMING_LOG_PREFIX = "runtime_stream_timing"
HITL_EVENT_PREFIX = "__HITL_REQUIRED__:"
RUNTIME_VERBOSE_STREAM_EVENTS = False
RUNTIME_VERBOSE_TOOL_ARGS_LOG = True

_RUNTIME_STATUS_LOCK = Lock()
_RUNTIME_STATUS_SEQ = count(1)
_RUNTIME_STATUS_EVENTS: dict[str, deque[dict[str, Any]]] = {}
_RUNTIME_STATUS_MAX_EVENTS = 1200
_STREAM_TIMING_LOG_LOCK = Lock()
_SESSION_STREAM_TIMING_LOG_PATHS: dict[str, Path] = {}


def _new_stream_timing_log_path(session_id: str) -> Path:
    ts = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S_%f")
    short_session = session_id[:8] if session_id else "default"
    return LOG_DIR / f"{STREAM_TIMING_LOG_PREFIX}_{ts}_{short_session}.log"


def _resolve_stream_timing_log_path(session_id: str, stage: str) -> Path:
    with _STREAM_TIMING_LOG_LOCK:
        if stage in {"query_start", "simple_query_start"}:
            log_path = _new_stream_timing_log_path(session_id)
            _SESSION_STREAM_TIMING_LOG_PATHS[session_id] = log_path
            return log_path

        log_path = _SESSION_STREAM_TIMING_LOG_PATHS.get(session_id)
        if log_path is None:
            log_path = _new_stream_timing_log_path(session_id)
            _SESSION_STREAM_TIMING_LOG_PATHS[session_id] = log_path

        if stage in {"query_end", "simple_query_end"}:
            _SESSION_STREAM_TIMING_LOG_PATHS.pop(session_id, None)

        return log_path


def _append_stream_timing_log(session_id: str, stage: str, details: str = "") -> None:
    try:
        LOG_DIR.mkdir(parents=True, exist_ok=True)
        session_log_path = _resolve_stream_timing_log_path(session_id, stage)
        timestamp = datetime.now(timezone.utc).isoformat(timespec="milliseconds")
        line = f"{timestamp} session={session_id} stage={stage}"
        if details:
            line = f"{line} {details}"
        with STREAM_TIMING_LOG_PATH.open("a", encoding="utf-8") as fp:
            fp.write(f"{line}\n")
        with session_log_path.open("a", encoding="utf-8") as fp:
            fp.write(f"{line}\n")
    except Exception:
        pass


def _runtime_status_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="milliseconds")


def _record_runtime_status_event(
    session_id: str,
    *,
    stage: str,
    reason: str,
    forward: bool,
    preview: str,
    meta_data: Any,
) -> dict[str, Any]:
    event: dict[str, Any] = {
        "seq": next(_RUNTIME_STATUS_SEQ),
        "timestamp": _runtime_status_now_iso(),
        "session_id": session_id,
        "stage": stage,
        "reason": reason,
        "forward": forward,
        "preview": preview,
        "meta": {},
    }

    if isinstance(meta_data, dict):
        compact_meta: dict[str, Any] = {}
        for key in ("langgraph_node", "langgraph_step", "name", "event", "type", "run_id", "response_id"):
            value = meta_data.get(key)
            if isinstance(value, (str, int, float, bool)) and str(value):
                compact_meta[key] = value
        if not compact_meta:
            for key, value in meta_data.items():
                if isinstance(value, (str, int, float, bool)) and str(value):
                    compact_meta[key] = value
                if len(compact_meta) >= 6:
                    break
        event["meta"] = compact_meta

    with _RUNTIME_STATUS_LOCK:
        bucket = _RUNTIME_STATUS_EVENTS.get(session_id)
        if bucket is None:
            bucket = deque(maxlen=_RUNTIME_STATUS_MAX_EVENTS)
            _RUNTIME_STATUS_EVENTS[session_id] = bucket
        bucket.append(event)

    return event
@asynccontextmanager
async def lifespan(app):
    app.agent = graph
    if getattr(app, "_runner", None) is not None:
        app._runner.agent = graph
    AGENT_WORKSPACE_DIR.mkdir(parents=True, exist_ok=True)
    session_user_input_dir(PROJECT_ROOT, DEFAULT_SESSION_ID).mkdir(parents=True, exist_ok=True)
    yield


agent_app = AgentApp(
    app_name="ImageToArkTS-DeepAgents",
    app_description="A DeepAgents-based HarmonyOS prototype generator runtime.",
    lifespan=lifespan,
)


def _extract_resume_value(request: AgentRequest | None) -> Any:
    if request is None:
        return None
    resume = getattr(request, "resume", None)
    if resume is not None:
        return resume
    model_extra = getattr(request, "model_extra", None)
    if isinstance(model_extra, dict):
        return model_extra.get("resume")
    return None


def _resolve_session_id(raw: str | None) -> str:
    return normalize_session_id(raw)


def _normalize_message_text(msg: BaseMessage) -> str:
    content = getattr(msg, "content", "")
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts: list[str] = []
        for item in content:
            if isinstance(item, str):
                parts.append(item)
                continue
            if isinstance(item, dict):
                text_value = item.get("text")
                if isinstance(text_value, str):
                    parts.append(text_value)
        return "\n".join(part for part in parts if part)
    return str(content or "")


def _extract_chunk_text(chunk: BaseMessage) -> str:
    return _normalize_message_text(chunk).strip()


def _should_forward_chunk_to_frontend(chunk: BaseMessage) -> tuple[bool, str, str]:
    text = _extract_chunk_text(chunk)
    preview = text[:120]
    if not text:
        return False, "empty_content", ""
    return True, "forward_all", preview


def _summarize_stream_meta(meta_data: Any) -> str:
    if not isinstance(meta_data, dict):
        return "meta=none"

    parts: list[str] = []
    for key in ("langgraph_node", "langgraph_step", "name", "event", "type", "run_id", "response_id"):
        value = meta_data.get(key)
        if isinstance(value, (str, int, float, bool)) and str(value):
            parts.append(f"{key}={value}")
    if not parts:
        for key, value in meta_data.items():
            if isinstance(value, (str, int, float, bool)) and str(value):
                parts.append(f"{key}={value}")
            if len(parts) >= 4:
                break
    if not parts:
        return "meta=empty"
    return "meta=" + ",".join(parts)


def _summarize_chunk_shape(chunk: BaseMessage) -> str:
    parts: list[str] = [f"class={chunk.__class__.__name__}"]

    for field_name in ("id", "role", "type", "status", "chunk_position"):
        value = getattr(chunk, field_name, None)
        if isinstance(value, str) and value:
            parts.append(f"{field_name}={value}")

    content = getattr(chunk, "content", None)
    if isinstance(content, str):
        parts.append("content_kind=str")
        parts.append(f"content_len={len(content)}")
    elif isinstance(content, list):
        parts.append("content_kind=list")
        parts.append(f"content_items={len(content)}")
    elif content is None:
        parts.append("content_kind=none")
    else:
        parts.append(f"content_kind={type(content).__name__}")

    return " ".join(parts)


def _format_sse_event(payload: dict[str, Any]) -> str:
    return f"data: {json.dumps(payload, ensure_ascii=False)}\n\n"


def _classify_stream_event_kind(chunk: BaseMessage, meta_data: Any) -> str:
    class_name = chunk.__class__.__name__.lower()

    chunk_tool_calls = getattr(chunk, "tool_calls", None)
    if isinstance(chunk_tool_calls, list) and chunk_tool_calls:
        return "tool_call_update"

    chunk_tool_call_chunks = getattr(chunk, "tool_call_chunks", None)
    if isinstance(chunk_tool_call_chunks, list) and chunk_tool_call_chunks:
        return "tool_call_update"

    if "tool" in class_name:
        return "tool_call_update"

    if isinstance(meta_data, dict):
        candidates = [
            str(meta_data.get("event") or "").lower(),
            str(meta_data.get("type") or "").lower(),
            str(meta_data.get("name") or "").lower(),
            str(meta_data.get("langgraph_node") or "").lower(),
        ]
        joined = " ".join(part for part in candidates if part)

        if any(token in joined for token in ("tool", "tool_call", "function_call", "action")):
            return "tool_call_update"

        if any(token in joined for token in ("status", "progress", "state", "step", "interrupt")):
            return "status_update"

    return "assistant_text"


def _extract_tool_event_payload(chunk: BaseMessage, meta_data: Any) -> dict[str, Any] | None:
    tool_name = ""
    tool_args: Any = None

    tool_calls = getattr(chunk, "tool_calls", None)
    if isinstance(tool_calls, list) and tool_calls:
        first = tool_calls[0]
        if isinstance(first, dict):
            name_candidate = first.get("name")
            if isinstance(name_candidate, str) and name_candidate:
                tool_name = name_candidate
            tool_args = first.get("args")

    if not tool_name:
        tool_call_chunks = getattr(chunk, "tool_call_chunks", None)
        if isinstance(tool_call_chunks, list) and tool_call_chunks:
            first_chunk = tool_call_chunks[0]
            if isinstance(first_chunk, dict):
                name_candidate = first_chunk.get("name")
                if isinstance(name_candidate, str) and name_candidate:
                    tool_name = name_candidate
                tool_args = first_chunk.get("args", tool_args)
            else:
                name_candidate = getattr(first_chunk, "name", None)
                if isinstance(name_candidate, str) and name_candidate:
                    tool_name = name_candidate
                args_candidate = getattr(first_chunk, "args", None)
                if args_candidate is not None:
                    tool_args = args_candidate

    if not tool_name and isinstance(meta_data, dict):
        name_candidate = meta_data.get("name")
        if isinstance(name_candidate, str) and name_candidate:
            tool_name = name_candidate

    if not tool_name and tool_args is None:
        return None

    return {
        "name": tool_name or "tool",
        "args": tool_args,
    }


def _task_interrupts(task: Any) -> list[Any]:
    interrupts = getattr(task, "interrupts", None)
    if interrupts is None and isinstance(task, dict):
        interrupts = task.get("interrupts")
    if not interrupts:
        return []
    return list(interrupts)


def _build_hitl_payload(interrupt_value: Any) -> dict[str, Any]:
    payload: dict[str, Any] = {"hitl_required": True}

    if isinstance(interrupt_value, dict):
        prompt = interrupt_value.get("ask") or interrupt_value.get("description")
        if not prompt and interrupt_value.get("action_requests"):
            first_action = interrupt_value["action_requests"][0]
            if isinstance(first_action, dict):
                prompt = first_action.get("description")
        payload["prompt"] = str(prompt or "Agent paused and needs human guidance.")
        payload["context"] = interrupt_value
        return payload

    payload["prompt"] = "Agent paused and needs human guidance."
    payload["context"] = {"raw": str(interrupt_value)}
    return payload


async def _extract_pending_hitl_event(runtime_agent: Any, config: dict | None) -> dict[str, Any] | None:
    if config is None:
        return None
    try:
        if hasattr(runtime_agent, "get_state"):
            state = runtime_agent.get_state(config=config)
        elif hasattr(runtime_agent, "aget_state"):
            state = await runtime_agent.aget_state(config=config)
        else:
            return None
    except Exception:
        return None

    tasks = getattr(state, "tasks", None) or []
    for task in tasks:
        for interrupt in _task_interrupts(task):
            value = getattr(interrupt, "value", None)
            if value is None and isinstance(interrupt, dict):
                value = interrupt.get("value")
            if value is None:
                continue
            return _build_hitl_payload(value)
    return None


@agent_app.query(framework="langgraph")
async def query_func(
    self,
    msgs: List[BaseMessage],
    request: AgentRequest = None,
    **kwargs,
) -> AsyncIterator[tuple[BaseMessage, bool]]:
    runtime_agent = getattr(self, "agent", graph)
    session_id = _resolve_session_id(getattr(request, "session_id", None))
    config = {"configurable": {"thread_id": session_id}}
    session_token = set_current_session_id(session_id)
    resume_value = _extract_resume_value(request)
    graph_input: Any = Command(resume=resume_value) if resume_value is not None else {"messages": msgs}
    ensure_session_backend_initialized(session_id)
    if resume_value is None:
        refresh_user_input_artifacts(PROJECT_ROOT, session_id)
        graph_input = {"messages": prepend_user_input_instruction(PROJECT_ROOT, msgs, session_id)}
    sync_local_user_input_to_backend(session_id)
    _append_stream_timing_log(session_id, "query_start", f"resume={resume_value is not None}")
    _record_runtime_status_event(
        session_id,
        stage="query_start",
        reason="stream_start",
        forward=False,
        preview="",
        meta_data={"resume": bool(resume_value is not None)},
    )
    try:
        for chunk, _meta_data in runtime_agent.stream(
            input=graph_input,
            stream_mode="messages",
            config=config,
        ):
            is_last_chunk = bool(getattr(chunk, "chunk_position", "") == "last")
            if chunk is None:
                _append_stream_timing_log(session_id, "stream_chunk_skipped", "reason=chunk_none")
                _record_runtime_status_event(
                    session_id,
                    stage="chunk",
                    reason="chunk_none",
                    forward=False,
                    preview="",
                    meta_data=_meta_data,
                )
                continue
            should_forward, reason, preview = _should_forward_chunk_to_frontend(chunk)
            _record_runtime_status_event(
                session_id,
                stage="chunk",
                reason=reason,
                forward=should_forward,
                preview=preview,
                meta_data=_meta_data,
            )
            _append_stream_timing_log(
                session_id,
                "stream_chunk_decision",
                f"reason={reason} forward={should_forward} preview={preview} {_summarize_stream_meta(_meta_data)}",
            )
            _append_stream_timing_log(
                session_id,
                "stream_chunk_inspect",
                f"forward={should_forward} reason={reason} {_summarize_chunk_shape(chunk)}",
            )
            if not should_forward:
                if is_last_chunk:
                    yield chunk, True
                continue
            yield chunk, is_last_chunk

        pending_hitl = await _extract_pending_hitl_event(runtime_agent, config)
        if pending_hitl:
            payload = f"{HITL_EVENT_PREFIX}{json.dumps(pending_hitl, ensure_ascii=False)}"
            yield AIMessage(content=payload), True
    except Exception as exc:
        error_text = str(exc)
        _append_stream_timing_log(session_id, "stream_error", error_text)
        _record_runtime_status_event(
            session_id,
            stage="stream_error",
            reason="exception",
            forward=False,
            preview=error_text[:240],
            meta_data={},
        )
        raise
    finally:
        sync_backend_outputs_to_local(session_id)
        reset_current_session_id(session_token)
        _append_stream_timing_log(session_id, "query_end")
        _record_runtime_status_event(
            session_id,
            stage="query_end",
            reason="stream_end",
            forward=False,
            preview="",
            meta_data={},
        )


def _sanitize_filename(filename: str | None) -> str:
    raw_name = Path(filename or "").name
    if not raw_name:
        return f"upload_{uuid4().hex}.bin"

    sanitized = "".join(char if char.isalnum() or char in {".", "_", "-"} else "_" for char in raw_name)
    return sanitized or f"upload_{uuid4().hex}.bin"


def _build_tree_node(path: Path, root: Path) -> dict:
    relative_path = "/" if path == root else f"/{path.relative_to(root).as_posix()}"

    if path.is_dir():
        children = sorted(path.iterdir(), key=lambda item: (not item.is_dir(), item.name.lower()))
        return {
            "name": path.name,
            "path": relative_path,
            "type": "directory",
            "children": [_build_tree_node(child, root) for child in children],
        }

    return {
        "name": path.name,
        "path": relative_path,
        "type": "file",
        "size": path.stat().st_size,
    }


@agent_app.endpoint("/user-input/upload", methods=["POST"])
async def upload_user_input(
    files: List[UploadFile] = File(...),
    clear_existing: bool = Form(False),
    image_description: str = Form(""),
    session_id: str = Form(DEFAULT_SESSION_ID),
):
    normalized_session_id = _resolve_session_id(session_id)
    user_input_dir = session_user_input_dir(PROJECT_ROOT, normalized_session_id)
    user_input_dir.mkdir(parents=True, exist_ok=True)
    ensure_session_backend_initialized(normalized_session_id)
    metadata_payload = load_user_input_metadata_payload(PROJECT_ROOT, normalized_session_id)
    files_metadata = metadata_payload.get("files", {})
    if not isinstance(files_metadata, dict):
        files_metadata = {}

    if clear_existing:
        for item in user_input_dir.iterdir():
            if item.is_file():
                item.unlink()
        files_metadata = {}

    normalized_description = image_description.strip()

    saved_files = []
    for upload in files:
        safe_name = _sanitize_filename(upload.filename)
        target_path = user_input_dir / safe_name

        if target_path.exists():
            stem = target_path.stem
            suffix = target_path.suffix
            target_path = user_input_dir / f"{stem}_{uuid4().hex[:8]}{suffix}"

        with target_path.open("wb") as output:
            shutil.copyfileobj(upload.file, output)

        content_type = upload.content_type or ""
        is_image = content_type.startswith("image/") or target_path.suffix.lower() in {
            ".png",
            ".jpg",
            ".jpeg",
            ".gif",
            ".webp",
            ".bmp",
            ".svg",
            ".heic",
        }

        file_path = f"/user_input/{target_path.name}"
        description_value = normalized_description if (is_image and normalized_description) else None
        # Preserve previous description if current upload doesn't provide one.
        previous_meta = files_metadata.get(target_path.name)
        if not description_value and isinstance(previous_meta, dict):
            previous_description = previous_meta.get("description")
            if isinstance(previous_description, str) and previous_description.strip():
                description_value = previous_description.strip()

        metadata_entry = {
            "name": target_path.name,
            "description": description_value,
            "path": file_path,
            "content_type": content_type,
        }
        response_entry = {
            "name": target_path.name,
            "path": file_path,
            "content_type": content_type,
            "size": target_path.stat().st_size,
            "description": description_value,
        }

        saved_files.append(response_entry)
        files_metadata[target_path.name] = metadata_entry

    save_user_input_metadata_payload(
        PROJECT_ROOT,
        normalized_session_id,
        {
            "files": files_metadata,
        }
    )
    refresh_user_input_artifacts(PROJECT_ROOT, normalized_session_id)

    return {
        "saved_count": len(saved_files),
        "files": saved_files,
    }


@agent_app.endpoint("/user-input/files", methods=["GET"])
async def list_user_input_files(session_id: str = DEFAULT_SESSION_ID):
    normalized_session_id = _resolve_session_id(session_id)
    user_input_dir = session_user_input_dir(PROJECT_ROOT, normalized_session_id)
    user_input_dir.mkdir(parents=True, exist_ok=True)
    ensure_session_backend_initialized(normalized_session_id)
    metadata_payload = load_user_input_metadata_payload(PROJECT_ROOT, normalized_session_id)
    files_metadata = metadata_payload.get("files", {})
    if not isinstance(files_metadata, dict):
        files_metadata = {}

    files = []
    for item in sorted(user_input_dir.iterdir()):
        if not item.is_file():
            continue
        base_info = {
            "name": item.name,
            "path": f"/user_input/{item.name}",
            "size": item.stat().st_size,
            "description": None,
        }
        existing_meta = files_metadata.get(item.name)
        if isinstance(existing_meta, dict):
            merged = dict(existing_meta)
            merged.update(base_info)
            files.append(merged)
        else:
            files.append(base_info)

    return {
        "count": len(files),
        "files": files,
    }


@agent_app.endpoint("/user-input/files/{file_name}", methods=["DELETE"])
async def delete_user_input_file(file_name: str, session_id: str = DEFAULT_SESSION_ID):
    normalized_session_id = _resolve_session_id(session_id)
    user_input_dir = session_user_input_dir(PROJECT_ROOT, normalized_session_id)
    user_input_dir.mkdir(parents=True, exist_ok=True)
    ensure_session_backend_initialized(normalized_session_id)

    safe_name = Path(file_name).name
    if safe_name != file_name:
        return JSONResponse(
            status_code=400,
            content={"ok": False, "error": "Invalid file name"},
        )

    target = user_input_dir / safe_name
    if not target.is_file():
        return JSONResponse(
            status_code=404,
            content={"ok": False, "error": "File not found"},
        )

    target.unlink()

    metadata_payload = load_user_input_metadata_payload(PROJECT_ROOT, normalized_session_id)
    files_metadata = metadata_payload.get("files", {})
    if not isinstance(files_metadata, dict):
        files_metadata = {}

    changed = False
    if safe_name in files_metadata:
        files_metadata.pop(safe_name, None)
        changed = True
    if changed:
        save_user_input_metadata_payload(
            PROJECT_ROOT,
            normalized_session_id,
            {
                "files": files_metadata,
            }
        )
    refresh_user_input_artifacts(PROJECT_ROOT, normalized_session_id)

    return {
        "ok": True,
        "deleted": safe_name,
    }


def _build_file_preview_payload(target: Path, display_name: str) -> dict[str, Any]:
    guessed_type, _ = mimetypes.guess_type(str(target))
    content_type = guessed_type or "application/octet-stream"
    raw_bytes = target.read_bytes()

    if content_type.startswith("image/"):
        encoded = base64.b64encode(raw_bytes).decode("ascii")
        return {
            "ok": True,
            "name": display_name,
            "kind": "image",
            "content_type": content_type,
            "size": len(raw_bytes),
            "data_url": f"data:{content_type};base64,{encoded}",
        }

    text_like_suffixes = {
        ".txt", ".md", ".json", ".yaml", ".yml", ".xml", ".csv", ".log",
        ".py", ".js", ".ts", ".tsx", ".jsx", ".css", ".html", ".arkts",
    }
    is_text_like = content_type.startswith("text/") or target.suffix.lower() in text_like_suffixes
    if is_text_like:
        decoded = raw_bytes.decode("utf-8", errors="replace")
        max_chars = 180_000
        truncated = len(decoded) > max_chars
        return {
            "ok": True,
            "name": display_name,
            "kind": "text",
            "content_type": content_type,
            "size": len(raw_bytes),
            "truncated": truncated,
            "text": decoded[:max_chars],
        }

    return {
        "ok": True,
        "name": display_name,
        "kind": "binary",
        "content_type": content_type,
        "size": len(raw_bytes),
        "message": "当前仅支持文本和图片预览。",
    }


@agent_app.endpoint("/runtime/status", methods=["GET"])
async def get_runtime_status(
    session_id: str = DEFAULT_SESSION_ID,
    since_seq: int = 0,
    limit: int = 200,
):
    normalized_session_id = _resolve_session_id(session_id)
    safe_since_seq = max(0, int(since_seq or 0))
    safe_limit = max(1, min(800, int(limit or 200)))

    with _RUNTIME_STATUS_LOCK:
        bucket = _RUNTIME_STATUS_EVENTS.get(normalized_session_id)
        items = list(bucket) if bucket else []

    newer = [item for item in items if int(item.get("seq", 0)) > safe_since_seq]
    sliced = newer[:safe_limit]
    latest_seq = int(items[-1]["seq"]) if items else safe_since_seq

    return {
        "ok": True,
        "session_id": normalized_session_id,
        "since_seq": safe_since_seq,
        "latest_seq": latest_seq,
        "count": len(sliced),
        "events": sliced,
    }


@agent_app.endpoint("/process-simple", methods=["POST"])
async def process_simple(request: Request, payload: dict[str, Any] = Body(default_factory=dict)):
    runtime_agent = getattr(agent_app, "agent", graph)

    session_id = _resolve_session_id(payload.get("session_id"))
    session_token = set_current_session_id(session_id)
    resume_raw = payload.get("resume")
    has_resume = resume_raw is not None

    raw_input = payload.get("input")
    msgs: list[BaseMessage] = []
    if isinstance(raw_input, list):
        for item in raw_input:
            if not isinstance(item, dict):
                continue
            role = str(item.get("role") or "user")
            if role != "user":
                continue
            content = item.get("content")
            text = ""
            if isinstance(content, list):
                for block in content:
                    if not isinstance(block, dict):
                        continue
                    if block.get("type") != "text":
                        continue
                    candidate_text = block.get("text")
                    if isinstance(candidate_text, str):
                        text += candidate_text
            if text:
                msgs.append(HumanMessage(content=text))

    if not msgs and not has_resume:
        return JSONResponse(status_code=400, content={"ok": False, "error": "No input message provided"})

    config = {"configurable": {"thread_id": session_id}}
    graph_input: Any = Command(resume=resume_raw) if has_resume else {"messages": msgs}
    ensure_session_backend_initialized(session_id)
    if not has_resume:
        refresh_user_input_artifacts(PROJECT_ROOT, session_id)
        graph_input = {"messages": prepend_user_input_instruction(PROJECT_ROOT, msgs, session_id)}
    sync_local_user_input_to_backend(session_id)
    _append_stream_timing_log(session_id, "simple_query_start", f"resume={has_resume}")
    _record_runtime_status_event(
        session_id,
        stage="simple_query_start",
        reason="stream_start",
        forward=False,
        preview="",
        meta_data={"resume": bool(has_resume)},
    )

    async def event_generator():
        client_disconnected = False
        try:
            for chunk, meta_data in runtime_agent.stream(
                input=graph_input,
                stream_mode="messages",
                config=config,
            ):
                if await request.is_disconnected():
                    client_disconnected = True
                    _append_stream_timing_log(session_id, "simple_stream_break", "reason=client_disconnected")
                    break

                if chunk is None:
                    _append_stream_timing_log(session_id, "simple_chunk_skip", "reason=chunk_none")
                    continue

                if not isinstance(chunk, (AIMessage, AIMessageChunk)):
                    _append_stream_timing_log(
                        session_id,
                        "simple_chunk_skip",
                        f"reason=non_ai_chunk class={chunk.__class__.__name__}",
                    )
                    continue

                msg_id = getattr(chunk, "id", None)
                msg_id_text = msg_id if isinstance(msg_id, str) and msg_id else None
                text_kind = _classify_stream_event_kind(chunk, meta_data)
                should_forward, reason, preview = _should_forward_chunk_to_frontend(chunk)
                if text_kind == "tool_call_update":
                    should_forward = True
                    if reason == "empty_content":
                        reason = "forward_structured_tool"

                _record_runtime_status_event(
                    session_id,
                    stage="simple_chunk",
                    reason=reason,
                    forward=should_forward,
                    preview=preview,
                    meta_data=meta_data,
                )
                _append_stream_timing_log(
                    session_id,
                    "simple_chunk_decision",
                    f"reason={reason} forward={should_forward} preview={preview} {_summarize_stream_meta(meta_data)} {_summarize_chunk_shape(chunk)} kind={text_kind}",
                )

                if RUNTIME_VERBOSE_STREAM_EVENTS:
                    yield _format_sse_event({
                        "kind": "status_update",
                        "msg_id": msg_id_text,
                        "text": f"debug: reason={reason} forward={should_forward} preview={preview}",
                    })

                if not should_forward:
                    continue

                text = _extract_chunk_text(chunk)
                if text_kind == "tool_call_update":
                    tool_payload = _extract_tool_event_payload(chunk, meta_data) or {"name": "tool", "args": None}
                    if RUNTIME_VERBOSE_TOOL_ARGS_LOG:
                        try:
                            serialized_args = json.dumps(tool_payload.get("args"), ensure_ascii=False)
                        except Exception:
                            serialized_args = str(tool_payload.get("args"))
                        _append_stream_timing_log(
                            session_id,
                            "simple_yield_tool",
                            f"msg_id={msg_id_text or 'none'} tool={tool_payload.get('name', 'tool')} args={serialized_args[:1200]}",
                        )
                    yield _format_sse_event({
                        "kind": "tool",
                        "msg_id": msg_id_text,
                        "name": tool_payload.get("name"),
                        "args": tool_payload.get("args"),
                    })
                    continue

                if not text:
                    continue

                _append_stream_timing_log(
                    session_id,
                    "simple_yield_text",
                    f"msg_id={msg_id_text or 'none'} content_len={len(text)} preview={text[:120]}",
                )
                yield _format_sse_event({
                    "kind": text_kind,
                    "msg_id": msg_id_text,
                    "text": text,
                })

            pending_hitl = await _extract_pending_hitl_event(runtime_agent, config)
            if pending_hitl:
                _append_stream_timing_log(session_id, "simple_yield_hitl", "forward=True")
                yield _format_sse_event({"kind": "hitl", "payload": pending_hitl})

        except Exception as exc:
            error_text = str(exc)
            _append_stream_timing_log(session_id, "simple_stream_error", error_text)
            _record_runtime_status_event(
                session_id,
                stage="simple_stream_error",
                reason="exception",
                forward=False,
                preview=error_text[:240],
                meta_data={},
            )
            yield _format_sse_event({"kind": "error", "text": error_text})
        finally:
            sync_backend_outputs_to_local(session_id)
            try:
                reset_current_session_id(session_token)
            except ValueError:
                _append_stream_timing_log(session_id, "simple_session_token_reset_skipped", "reason=context_mismatch")
            _append_stream_timing_log(session_id, "simple_query_end")
            _record_runtime_status_event(
                session_id,
                stage="simple_query_end",
                reason="stream_end",
                forward=False,
                preview="",
                meta_data={},
            )
            if not client_disconnected:
                yield _format_sse_event({"kind": "done"})

    return StreamingResponse(event_generator(), media_type="text/event-stream")


@agent_app.endpoint("/user-input/files/{file_name}/preview", methods=["GET"])
async def preview_user_input_file(file_name: str, session_id: str = DEFAULT_SESSION_ID):
    normalized_session_id = _resolve_session_id(session_id)
    user_input_dir = session_user_input_dir(PROJECT_ROOT, normalized_session_id)
    user_input_dir.mkdir(parents=True, exist_ok=True)
    ensure_session_backend_initialized(normalized_session_id)

    safe_name = Path(file_name).name
    if safe_name != file_name:
        return JSONResponse(
            status_code=400,
            content={"ok": False, "error": "Invalid file name"},
        )

    target = user_input_dir / safe_name
    if not target.is_file():
        return JSONResponse(
            status_code=404,
            content={"ok": False, "error": "File not found"},
        )

    return _build_file_preview_payload(target, safe_name)


@agent_app.endpoint("/workspace/tree", methods=["GET"])
async def get_workspace_tree(session_id: str = DEFAULT_SESSION_ID):
    normalized_session_id = _resolve_session_id(session_id)
    session_dir = session_workspace_dir(PROJECT_ROOT, normalized_session_id)
    session_dir.mkdir(parents=True, exist_ok=True)
    ensure_session_backend_initialized(normalized_session_id)
    tree = _build_tree_node(session_dir, session_dir)
    return {
        "root": tree,
    }


@agent_app.endpoint("/workspace/files/preview", methods=["GET"])
async def preview_workspace_file(workspace_path: str, session_id: str = DEFAULT_SESSION_ID):
    normalized_session_id = _resolve_session_id(session_id)
    session_dir = session_workspace_dir(PROJECT_ROOT, normalized_session_id)
    session_dir.mkdir(parents=True, exist_ok=True)
    ensure_session_backend_initialized(normalized_session_id)

    normalized_path = (workspace_path or "").strip()
    if not normalized_path or normalized_path == "/":
        return JSONResponse(
            status_code=400,
            content={"ok": False, "error": "Invalid workspace path"},
        )

    relative = normalized_path.lstrip("/")
    target = (session_dir / relative).resolve()
    try:
        target.relative_to(session_dir.resolve())
    except ValueError:
        return JSONResponse(
            status_code=400,
            content={"ok": False, "error": "Invalid workspace path"},
        )

    if not target.is_file():
        return JSONResponse(
            status_code=404,
            content={"ok": False, "error": "Workspace file not found"},
        )

    return _build_file_preview_payload(target, target.name)


@agent_app.endpoint("/reset", methods=["POST"])
async def reset_agent_workspace(session_id: str = Form(DEFAULT_SESSION_ID)):
    normalized_session_id = _resolve_session_id(session_id)
    if normalized_session_id != DEFAULT_SESSION_ID:
        session_dir = session_workspace_dir(PROJECT_ROOT, normalized_session_id)
        if session_dir.exists():
            shutil.rmtree(session_dir)
        session_user_input_dir(PROJECT_ROOT, normalized_session_id).mkdir(parents=True, exist_ok=True)
        ensure_session_backend_initialized(normalized_session_id)
        return {
            "ok": True,
            "code": 0,
            "stdout": f"Session workspace reset: {normalized_session_id}",
            "stderr": "",
        }

    if not RESET_SCRIPT_PATH.is_file():
        return JSONResponse(
            status_code=500,
            content={
                "ok": False,
                "error": f"Reset script not found: {RESET_SCRIPT_PATH}",
            },
        )

    result = subprocess.run(
        [str(RESET_SCRIPT_PATH)],
        cwd=PROJECT_ROOT,
        capture_output=True,
        text=True,
    )

    response = {
        "ok": result.returncode == 0,
        "code": result.returncode,
        "stdout": result.stdout.strip(),
        "stderr": result.stderr.strip(),
    }

    if result.returncode != 0:
        return JSONResponse(status_code=500, content=response)

    return response


app = agent_app


if __name__ == "__main__":
    agent_app.run(host="0.0.0.0", port=8080, web_ui=False)
