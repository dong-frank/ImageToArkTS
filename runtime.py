from contextlib import asynccontextmanager
from pathlib import Path
import subprocess
import shutil
from typing import AsyncIterator, List
from uuid import uuid4

from agentscope_runtime.engine import AgentApp
from agentscope_runtime.engine.schemas.agent_schemas import AgentRequest
from fastapi import File, Form, UploadFile
from fastapi.responses import JSONResponse
from langchain_core.messages import AIMessage, BaseMessage

from agent import graph

PROJECT_ROOT = Path(__file__).resolve().parent
AGENT_WORKSPACE_DIR = PROJECT_ROOT / "agent_workspace"
USER_INPUT_DIR = PROJECT_ROOT / "agent_workspace" / "user_input"
RESET_SCRIPT_PATH = PROJECT_ROOT / "scripts" / "reset_agent_workspace.sh"


@asynccontextmanager
async def lifespan(app):
    app.agent = graph
    if getattr(app, "_runner", None) is not None:
        app._runner.agent = graph
    AGENT_WORKSPACE_DIR.mkdir(parents=True, exist_ok=True)
    USER_INPUT_DIR.mkdir(parents=True, exist_ok=True)
    yield


agent_app = AgentApp(
    app_name="ImageToArkTS-DeepAgents",
    app_description="A DeepAgents-based HarmonyOS prototype generator runtime.",
    lifespan=lifespan,
)


@agent_app.query(framework="langgraph")
async def query_func(
    self,
    msgs: List[BaseMessage],
    request: AgentRequest = None,
    **kwargs,
) -> AsyncIterator[tuple[BaseMessage, bool]]:
    runtime_agent = getattr(self, "agent", graph)
    config = None
    if request and request.session_id:
        config = {"configurable": {"thread_id": request.session_id}}

    async for chunk, _meta_data in runtime_agent.astream(
        input={"messages": msgs},
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
):
    USER_INPUT_DIR.mkdir(parents=True, exist_ok=True)

    if clear_existing:
        for item in USER_INPUT_DIR.iterdir():
            if item.is_file():
                item.unlink()

    saved_files = []
    for upload in files:
        safe_name = _sanitize_filename(upload.filename)
        target_path = USER_INPUT_DIR / safe_name

        if target_path.exists():
            stem = target_path.stem
            suffix = target_path.suffix
            target_path = USER_INPUT_DIR / f"{stem}_{uuid4().hex[:8]}{suffix}"

        with target_path.open("wb") as output:
            shutil.copyfileobj(upload.file, output)

        saved_files.append(
            {
                "name": target_path.name,
                "path": f"/user_input/{target_path.name}",
                "content_type": upload.content_type,
                "size": target_path.stat().st_size,
            }
        )

    return {
        "saved_count": len(saved_files),
        "files": saved_files,
    }


@agent_app.endpoint("/user-input/files", methods=["GET"])
async def list_user_input_files():
    USER_INPUT_DIR.mkdir(parents=True, exist_ok=True)

    files = []
    for item in sorted(USER_INPUT_DIR.iterdir()):
        if not item.is_file():
            continue
        files.append(
            {
                "name": item.name,
                "path": f"/user_input/{item.name}",
                "size": item.stat().st_size,
            }
        )

    return {
        "count": len(files),
        "files": files,
    }


@agent_app.endpoint("/workspace/tree", methods=["GET"])
async def get_workspace_tree():
    AGENT_WORKSPACE_DIR.mkdir(parents=True, exist_ok=True)
    tree = _build_tree_node(AGENT_WORKSPACE_DIR, AGENT_WORKSPACE_DIR)
    return {
        "root": tree,
    }


@agent_app.endpoint("/reset", methods=["POST"])
async def reset_agent_workspace():
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
    agent_app.run(host="127.0.0.1", port=8080, web_ui=False)
