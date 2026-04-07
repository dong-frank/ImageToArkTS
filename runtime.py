from contextlib import asynccontextmanager
import json
from pathlib import Path
import subprocess
import shutil
from typing import Any, AsyncIterator, List
from uuid import uuid4

from agentscope_runtime.engine import AgentApp
from agentscope_runtime.engine.schemas.agent_schemas import AgentRequest
from fastapi import File, Form, UploadFile
from fastapi.responses import JSONResponse
from langchain_core.messages import AIMessage, BaseMessage, HumanMessage
from langgraph.types import Command

from agent import graph
from utils.session_backend import sync_backend_outputs_to_local, sync_local_user_input_to_backend
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
HITL_EVENT_PREFIX = "__HITL_REQUIRED__:"
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
    if resume_value is None:
        refresh_user_input_artifacts(PROJECT_ROOT, session_id)
        graph_input = {"messages": prepend_user_input_instruction(PROJECT_ROOT, msgs, session_id)}
    sync_local_user_input_to_backend(session_id)
    try:
        for chunk, _meta_data in runtime_agent.stream(
            input=graph_input,
            stream_mode="messages",
            config=config,
        ):
            is_last_chunk = bool(getattr(chunk, "chunk_position", "") == "last")
            if chunk is None:
                continue
            if not getattr(chunk, "content", None):
                if is_last_chunk:
                    yield chunk, True
                    continue
                continue
            yield chunk, is_last_chunk

        pending_hitl = await _extract_pending_hitl_event(runtime_agent, config)
        if pending_hitl:
            payload = f"{HITL_EVENT_PREFIX}{json.dumps(pending_hitl, ensure_ascii=False)}"
            yield AIMessage(content=payload), True
    finally:
        sync_backend_outputs_to_local(session_id)
        reset_current_session_id(session_token)


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


@agent_app.endpoint("/workspace/tree", methods=["GET"])
async def get_workspace_tree(session_id: str = DEFAULT_SESSION_ID):
    session_dir = session_workspace_dir(PROJECT_ROOT, _resolve_session_id(session_id))
    session_dir.mkdir(parents=True, exist_ok=True)
    tree = _build_tree_node(session_dir, session_dir)
    return {
        "root": tree,
    }


@agent_app.endpoint("/reset", methods=["POST"])
async def reset_agent_workspace(session_id: str = Form(DEFAULT_SESSION_ID)):
    normalized_session_id = _resolve_session_id(session_id)
    if normalized_session_id != DEFAULT_SESSION_ID:
        session_dir = session_workspace_dir(PROJECT_ROOT, normalized_session_id)
        if session_dir.exists():
            shutil.rmtree(session_dir)
        session_user_input_dir(PROJECT_ROOT, normalized_session_id).mkdir(parents=True, exist_ok=True)
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
