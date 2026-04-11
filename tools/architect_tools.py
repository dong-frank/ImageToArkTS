from __future__ import annotations

import json
import mimetypes
from collections import Counter
from pathlib import Path
from typing import Any

from langchain_core.messages import HumanMessage
from pydantic import BaseModel, ValidationError

from models import architect_vision_model
from schemas import ArchitectImageFactsBundle, ArchitectImageFactsOutput, ArchitectOutput
from tools.common import resolve_workspace_path, workspace_root
from utils.session_context import get_current_session_id
from utils.llm_utils import extract_tool_call_args, invoke_with_tool, normalize_tool_schema


def _architect_design_path():
    return workspace_root() / "designs" / "architect.json"


def _architect_image_facts_path() -> Path:
    return workspace_root() / "designs" / "architect_image_facts.json"


def _encode_image_as_data_url(image_path: Path) -> str:
    mime, _ = mimetypes.guess_type(str(image_path))
    if not mime:
        mime = "image/png"
    binary = image_path.read_bytes()
    import base64

    b64 = base64.b64encode(binary).decode("ascii")
    return f"data:{mime};base64,{b64}"


def _resolve_session_path(raw_path: str, project_root: Path | None = None) -> Path:
    if project_root is None:
        return resolve_workspace_path(raw_path)
    return project_root / "agent_workspace" / "sessions" / get_current_session_id() / raw_path.lstrip("/")


def _load_metadata_entries(metadata_path: str, project_root: Path | None = None) -> list[dict[str, Any]]:
    resolved = _resolve_session_path(metadata_path, project_root=project_root)
    if not resolved.exists() or not resolved.is_file():
        raise ValueError(f"metadata file not found: {metadata_path}")
    data = json.loads(resolved.read_text(encoding="utf-8"))
    raw_files = data.get("files", {}) if isinstance(data, dict) else {}
    entries: list[dict[str, Any]] = []
    if not isinstance(raw_files, dict):
        return entries
    for file_name, meta in raw_files.items():
        if not isinstance(meta, dict):
            meta = {}
        path = str(meta.get("path") or f"/user_input/{file_name}")
        content_type = str(meta.get("content_type") or "")
        suffix = Path(path).suffix.lower()
        is_image = content_type.startswith("image/") or suffix in {".png", ".jpg", ".jpeg", ".webp", ".bmp", ".gif"}
        if not is_image:
            continue
        entries.append(
            {
                "name": str(meta.get("name") or file_name),
                "path": path,
                "content_type": content_type,
                "description": str(meta.get("description") or "").strip(),
            }
        )
    return entries


def _extract_architect_image_facts_for_image(
    image_path: str,
    *,
    metadata_name: str = "",
    metadata_description: str = "",
    project_root: Path | None = None,
) -> dict[str, Any]:
    resolved = _resolve_session_path(image_path, project_root=project_root)
    if not resolved.exists() or not resolved.is_file():
        return {
            "image_path": image_path,
            "image_role": "unknown",
            "visible_texts": [],
            "layout_summary": "image file missing",
            "key_sections": [],
            "interactive_hints": [],
            "uncertainties": [f"image file missing: {image_path}"],
        }

    data_url = _encode_image_as_data_url(resolved)
    prompt = (
        "你是移动端 UI 事实提取助手。"
        "你的任务是从单张图片里提取可观察事实，不要生成产品设计结论，不要推断跨页面关系。"
        f"当前图片路径必须写为：{image_path}\n"
        f"文件名：{metadata_name or Path(image_path).name}\n"
        f"元数据描述：{metadata_description or '(none)'}\n"
        "要求：\n"
        "1) 只写这张图中可见、可验证的事实。\n"
        "2) image_role 只能根据当前图判断；不确定时写 unknown。\n"
        "3) key_sections 和 interactive_hints 只写从图中能看出来的内容。\n"
        "4) uncertainties 必须记录不确定项，禁止把猜测写成确定事实。"
    )
    response = invoke_with_tool(
        architect_vision_model,
        [
            HumanMessage(
                content=[
                    {"type": "text", "text": prompt},
                    {"type": "image_url", "image_url": {"url": data_url}},
                ]
            )
        ],
        "ArchitectImageFactsOutput",
        normalize_tool_schema(ArchitectImageFactsOutput.model_json_schema()),
    )
    normalized = extract_tool_call_args(response, "ArchitectImageFactsOutput")
    if normalized is None:
        raw_text = getattr(response, "content", "")
        if isinstance(raw_text, str) and raw_text.strip():
            normalized = json.loads(raw_text.strip())
        else:
            raise ValueError("Architect image facts extraction requires tool-call output")
    normalized["image_path"] = image_path
    return ArchitectImageFactsOutput.model_validate(normalized).model_dump(mode="json", exclude_none=True)


def _build_shared_patterns_and_conflicts(facts: list[dict[str, Any]], omitted_images: list[str]) -> tuple[list[str], list[str]]:
    shared_patterns: list[str] = []
    conflicts: list[str] = []

    role_counter = Counter(
        fact.get("image_role")
        for fact in facts
        if str(fact.get("image_role") or "").strip() and fact.get("image_role") != "unknown"
    )
    for role, count in role_counter.items():
        if count >= 2:
            shared_patterns.append(f"multiple images suggest role={role}")
    if role_counter.get("entry", 0) > 1:
        conflicts.append("multiple images are marked as entry; page ordering may be ambiguous")

    section_counter = Counter()
    for fact in facts:
        for section in fact.get("key_sections", []) or []:
            section_counter[str(section).strip().lower()] += 1
        for item in fact.get("uncertainties", []) or []:
            conflicts.append(f"{fact.get('image_path')}: {item}")

    for section, count in section_counter.items():
        if section and count >= 2:
            shared_patterns.append(f"shared section: {section}")

    if omitted_images:
        conflicts.append(f"{len(omitted_images)} images omitted from direct visual extraction due to budget")

    seen = set()
    dedup_conflicts = []
    for item in conflicts:
        if item not in seen:
            dedup_conflicts.append(item)
            seen.add(item)
    return shared_patterns, dedup_conflicts


def build_architect_image_facts_bundle_payload(
    metadata_path: str = "/user_input/user_input_metadata.json",
    output_path: str = "/designs/architect_image_facts.json",
    max_images: int = 8,
    project_root: Path | None = None,
) -> str:
    entries = _load_metadata_entries(metadata_path, project_root=project_root)
    total_image_count = len(entries)
    processed_entries = entries[: max(0, max_images)]
    omitted_entries = entries[len(processed_entries) :]
    omitted_images = [str(entry.get("path") or "") for entry in omitted_entries if str(entry.get("path") or "").strip()]

    facts: list[dict[str, Any]] = []
    failed_image_count = 0
    for entry in processed_entries:
        try:
            facts.append(
                _extract_architect_image_facts_for_image(
                    str(entry.get("path") or ""),
                    metadata_name=str(entry.get("name") or ""),
                    metadata_description=str(entry.get("description") or ""),
                    project_root=project_root,
                )
            )
        except Exception as exc:  # noqa: BLE001
            failed_image_count += 1
            facts.append(
                {
                    "image_path": str(entry.get("path") or ""),
                    "image_role": "unknown",
                    "visible_texts": [],
                    "layout_summary": "fact extraction failed",
                    "key_sections": [],
                    "interactive_hints": [],
                    "uncertainties": [f"fact extraction failed: {exc}"],
                }
            )

    shared_patterns, conflicts = _build_shared_patterns_and_conflicts(facts, omitted_images)
    coverage_summary = {
        "total_image_count": total_image_count,
        "processed_image_count": len(processed_entries),
        "omitted_image_count": len(omitted_entries),
        "failed_image_count": failed_image_count,
        "strategy": "limited_to_budget" if omitted_entries else "all_images_processed",
        "notes": "final architect generation should consume this facts bundle instead of all raw images",
    }
    bundle = ArchitectImageFactsBundle.model_validate(
        {
            "facts": facts,
            "shared_patterns": shared_patterns,
            "conflicts": conflicts,
            "coverage_summary": coverage_summary,
            "omitted_images": omitted_images,
        }
    ).model_dump(mode="json", exclude_none=True)

    base_path = _resolve_session_path(output_path, project_root=project_root)
    base_path.parent.mkdir(parents=True, exist_ok=True)
    base_path.write_text(json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")

    return "\n".join(
        [
            "status: SUCCESS",
            f"bundle_path: {base_path}",
            f"processed_image_count: {coverage_summary['processed_image_count']}",
            f"omitted_image_count: {coverage_summary['omitted_image_count']}",
            f"failed_image_count: {coverage_summary['failed_image_count']}",
        ]
    )


def _normalize_architect_payload(payload: Any) -> dict:
    def _maybe_load_nested_json(value: Any, expected_type: type):
        if not isinstance(value, str):
            return value
        text = value.strip()
        if not text:
            return value
        try:
            parsed = json.loads(text)
        except json.JSONDecodeError:
            return value
        if isinstance(parsed, expected_type):
            return parsed
        return value

    def _coerce_nested_json_fields(data: dict) -> dict:
        normalized = dict(data)
        nested_field_types: dict[str, type] = {
            "visual_style": dict,
            "navigation": list,
        }
        for field_name, expected_type in nested_field_types.items():
            if field_name not in normalized:
                continue
            normalized[field_name] = _maybe_load_nested_json(normalized[field_name], expected_type)
        return normalized

    if isinstance(payload, ArchitectOutput):
        return payload.model_dump(mode="json", exclude_none=True)

    if isinstance(payload, BaseModel):
        validated = ArchitectOutput.model_validate(_coerce_nested_json_fields(payload.model_dump(mode="json")))
        return validated.model_dump(mode="json", exclude_none=True)

    if isinstance(payload, dict):
        validated = ArchitectOutput.model_validate(_coerce_nested_json_fields(payload))
        return validated.model_dump(mode="json", exclude_none=True)

    if isinstance(payload, str):
        try:
            parsed = json.loads(payload)
        except json.JSONDecodeError as exc:
            raise ValueError(f"architect 输出不是合法 JSON。错误：{exc}") from exc
        if isinstance(parsed, dict):
            parsed = _coerce_nested_json_fields(parsed)
        validated = ArchitectOutput.model_validate(parsed)
        return validated.model_dump(mode="json", exclude_none=True)

    raise ValueError(f"architect 输出类型不受支持：{type(payload).__name__}")


def save_architect_design_payload(payload: Any) -> str:
    try:
        normalized = _normalize_architect_payload(payload)
    except ValidationError as exc:
        return f"保存失败：architect 输出不符合 ArchitectOutput Schema。错误：{exc}"
    except ValueError as exc:
        return f"保存失败：{exc}"

    design_path = _architect_design_path()
    design_path.parent.mkdir(parents=True, exist_ok=True)
    design_path.write_text(
        json.dumps(normalized, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    return "architect 设计已保存到 /designs/architect.json"
