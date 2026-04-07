from __future__ import annotations

import json
from pathlib import Path

from langchain_core.messages import BaseMessage, HumanMessage

from utils.session_workspace import session_description_md_path, session_user_input_dir, session_user_input_meta_path

USER_INPUT_INSTRUCTION_PREFIX = "用户输入资料都在 /user_input 目录下，请只将该目录内容视为用户输入并开始工作。"

def normalize_message_text(msg: BaseMessage) -> str:
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


def load_user_input_metadata_payload(project_root: Path, session_id: str) -> dict:
    metadata_path = session_user_input_meta_path(project_root, session_id)
    if not metadata_path.is_file():
        return {"files": {}}

    try:
        data = json.loads(metadata_path.read_text(encoding="utf-8"))
    except Exception:
        return {"files": {}}

    if not isinstance(data, dict):
        return {"files": {}}

    raw_files = data.get("files", {})
    files: dict[str, dict] = {}
    if isinstance(raw_files, dict):
        for file_name, raw_meta in raw_files.items():
            if not isinstance(file_name, str):
                continue
            if not isinstance(raw_meta, dict):
                raw_meta = {}
            name = str(raw_meta.get("name") or file_name)
            path = str(raw_meta.get("path") or f"/user_input/{name}")
            content_type = str(raw_meta.get("content_type") or "")
            description_raw = raw_meta.get("description")
            description = None
            if isinstance(description_raw, str) and description_raw.strip():
                description = description_raw.strip()
            files[file_name] = {
                "name": name,
                "description": description,
                "path": path,
                "content_type": content_type,
            }

    return {"files": files}


def save_user_input_metadata_payload(project_root: Path, session_id: str, payload: dict) -> None:
    raw_files = payload.get("files", {})
    normalized_files: dict[str, dict] = {}
    if isinstance(raw_files, dict):
        for file_name, raw_meta in raw_files.items():
            if not isinstance(file_name, str):
                continue
            if not isinstance(raw_meta, dict):
                raw_meta = {}
            name = str(raw_meta.get("name") or file_name)
            path = str(raw_meta.get("path") or f"/user_input/{name}")
            content_type = str(raw_meta.get("content_type") or "")
            description_raw = raw_meta.get("description")
            description = None
            if isinstance(description_raw, str) and description_raw.strip():
                description = description_raw.strip()
            normalized_files[file_name] = {
                "name": name,
                "description": description,
                "path": path,
                "content_type": content_type,
            }

    normalized_payload = {"files": normalized_files}
    metadata_path = session_user_input_meta_path(project_root, session_id)
    metadata_path.parent.mkdir(parents=True, exist_ok=True)
    metadata_path.write_text(
        json.dumps(normalized_payload, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )


def persist_test_description(project_root: Path, session_id: str, content: str) -> None:
    user_input_dir = session_user_input_dir(project_root, session_id)
    description_path = session_description_md_path(project_root, session_id)
    user_input_dir.mkdir(parents=True, exist_ok=True)
    description_path.write_text(content, encoding="utf-8")

def refresh_user_input_artifacts(project_root: Path, session_id: str) -> None:
    user_input_dir = session_user_input_dir(project_root, session_id)
    user_input_dir.mkdir(parents=True, exist_ok=True)
    metadata_payload = load_user_input_metadata_payload(project_root, session_id)
    save_user_input_metadata_payload(project_root, session_id, metadata_payload)


def build_user_input_prompt_text(user_text: str) -> str:
    return (
        f"{USER_INPUT_INSTRUCTION_PREFIX}\n\n"
        "请先读取以下稳定输入工件，再理解当前用户请求：\n"
        "- /user_input/user_input_metadata.json\n\n"
        "以下是用户在主聊天框中的本次输入：\n"
        f"{user_text or '(empty)'}"
    )


def prepend_user_input_instruction(
    project_root: Path,
    msgs: list[BaseMessage],
    session_id: str,
) -> list[BaseMessage]:
    merged = list(msgs)
    for idx in range(len(merged) - 1, -1, -1):
        msg = merged[idx]
        if isinstance(msg, HumanMessage):
            user_text = normalize_message_text(msg).strip()
            combined_text = build_user_input_prompt_text(user_text)
            merged[idx] = HumanMessage(content=combined_text)
            return merged

    fallback_text = build_user_input_prompt_text("")
    return [HumanMessage(content=fallback_text), *merged]
