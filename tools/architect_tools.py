from __future__ import annotations

import base64
import json
import mimetypes
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from typing import Any, List

from langchain_core.messages import HumanMessage
from pydantic import BaseModel, Field

from models import architect_vision_model
from schemas import (
    ArchitectIndexOutput,
    ArchitectPageDraft,
    ArchitectPageDraftSummary,
    ArchitectPageDraftsIndex,
    ArchitectPageFile,
)
from tools.common import resolve_workspace_path, workspace_root
from utils.llm_utils import extract_tool_call_args, invoke_with_tool, normalize_tool_schema

# ---------------------------------------------------------------------------
# Schema
# ---------------------------------------------------------------------------


class ArchitectPersistPayload(BaseModel):
    index: ArchitectIndexOutput = Field(
        ..., description="Project-level architect index output."
    )
    pages: List[ArchitectPageFile] = Field(
        default_factory=list, description="Per-page architect files."
    )


# ---------------------------------------------------------------------------
# Session-scoped path helpers
# ---------------------------------------------------------------------------


def _get_workspace_root(project_root: Path | None = None) -> Path:
    """
    主线程调用，返回当前 session 的工作区根目录。
    project_root 仅供测试注入使用；生产环境传 None，走 workspace_root()。
    """
    if project_root is not None:
        from utils.session_context import get_current_session_id
        return project_root / "agent_workspace" / "sessions" / get_current_session_id()
    return workspace_root()


def _resolve_path(root: Path, raw_path: str) -> Path:
    """
    用已算好的 root 直接拼路径，不再动态调用任何 ContextVar。
    子线程安全。
    """
    return root / raw_path.lstrip("/")


# ---------------------------------------------------------------------------
# JSON helpers
# ---------------------------------------------------------------------------


def _deep_load_json(value: Any) -> Any:
    """递归将所有 JSON 字符串字段反序列化为原生类型。"""
    if isinstance(value, str):
        text = value.strip()
        if text.startswith(("{", "[")):
            try:
                value = json.loads(text)
            except json.JSONDecodeError:
                return value
        else:
            return value
    if isinstance(value, dict):
        return {k: _deep_load_json(v) for k, v in value.items()}
    if isinstance(value, list):
        return [_deep_load_json(item) for item in value]
    return value


# ---------------------------------------------------------------------------
# 图片编码
# ---------------------------------------------------------------------------


def _encode_image_as_data_url(image_path: Path) -> str:
    mime, _ = mimetypes.guess_type(str(image_path))
    if not mime:
        mime = "image/png"
    b64 = base64.b64encode(image_path.read_bytes()).decode("ascii")
    return f"data:{mime};base64,{b64}"


# ---------------------------------------------------------------------------
# metadata 加载（从旧版迁移，供 batch_extract_page_drafts 使用）
# ---------------------------------------------------------------------------


def _load_metadata_entries(
    metadata_path: str,
    project_root: Path | None = None,
) -> list[dict[str, Any]]:
    root = _get_workspace_root(project_root)
    resolved = _resolve_path(root, metadata_path)
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
        is_image = content_type.startswith("image/") or suffix in {
            ".png", ".jpg", ".jpeg", ".webp", ".bmp", ".gif"
        }
        if not is_image:
            continue
        entries.append({
            "name": str(meta.get("name") or file_name),
            "path": path,
            "content_type": content_type,
            "description": str(meta.get("description") or "").strip(),
        })
    return entries


# ---------------------------------------------------------------------------
# 阶段一：单图提取（子线程调用，纯函数，不访问任何 ContextVar）
# ---------------------------------------------------------------------------


def _extract_single_page_draft(
    entry: dict[str, Any],
    draft_index: int,
    root: Path,
) -> ArchitectPageDraft:
    """单张图提取，子线程调用，纯函数，不访问任何 ContextVar。"""
    image_path = str(entry.get("path") or "")
    resolved = _resolve_path(root, image_path)

    if not resolved.exists() or not resolved.is_file():
        return ArchitectPageDraft(
            draft_index=draft_index,
            image_path=image_path,
            image_name=str(entry.get("name") or Path(image_path).name),
            draft_status="failed",
            candidate_page_id=f"page_{draft_index}",
            candidate_page_name="unknown",
            layout_summary="image file missing",
            key_sections=[],
            has_overlay=False,
            ui_tree={},
            uncertainties=[f"image file missing: {image_path}"],
        )

    data_url = _encode_image_as_data_url(resolved)
    prompt = (
        "你是移动端 UI 草稿提取助手。"
        "从单张图片提取完整 UI 树草稿，不要推断跨页面关系。\n"
        f"图片路径：{image_path}\n"
        f"文件名：{entry.get('name') or Path(image_path).name}\n"
        f"元数据描述：{entry.get('description') or '(none)'}\n"
        f"draft_index：{draft_index}\n"
    )

    try:
        response = invoke_with_tool(
            architect_vision_model,
            [
                HumanMessage(content=[
                    {"type": "text", "text": prompt},
                    {"type": "image_url", "image_url": {"url": data_url}},
                ])
            ],
            "ArchitectPageDraft",
            normalize_tool_schema(ArchitectPageDraft.model_json_schema()),
        )
        normalized = extract_tool_call_args(response, "ArchitectPageDraft")
        if normalized is None:
            raise ValueError("LLM 未返回 tool call 输出")
        normalized["draft_index"] = draft_index
        normalized["image_path"] = image_path
        normalized["draft_status"] = "success"
        return ArchitectPageDraft.model_validate(normalized)

    except Exception as exc:  # noqa: BLE001
        return ArchitectPageDraft(
            draft_index=draft_index,
            image_path=image_path,
            image_name=str(entry.get("name") or Path(image_path).name),
            draft_status="failed",
            candidate_page_id=f"page_{draft_index}",
            candidate_page_name="unknown",
            layout_summary="fact extraction failed",
            key_sections=[],
            has_overlay=False,
            ui_tree={},
            uncertainties=[f"fact extraction failed: {exc}"],
        )


# ---------------------------------------------------------------------------
# 阶段一：批量并发入口（代码驱动，供 dispatch_architect 调用）
# ---------------------------------------------------------------------------


def batch_extract_page_drafts(
    metadata_path: str = "/user_input/user_input_metadata.json",
    max_images: int = 8,
    project_root: Path | None = None,
) -> str:
    """
    阶段一：并发提取所有图的 UI 树草稿，保存草稿文件和轻量索引。
    代码驱动，不经过 Agent，子线程安全。

    输出：
      - /designs/page_drafts/page_draft_{i}.json  每张图的完整草稿
      - /designs/page_drafts_index.json           所有图的轻量摘要索引
    """
    root = _get_workspace_root(project_root)
    entries = _load_metadata_entries(metadata_path, project_root=project_root)
    processed_entries = entries[:max(0, max_images)]
    total_image_count = len(entries)

    # ---- 并发提取 ----
    index_to_draft: dict[int, ArchitectPageDraft] = {}
    with ThreadPoolExecutor(max_workers=4) as executor:
        future_to_index = {
            executor.submit(_extract_single_page_draft, entry, idx, root): idx
            for idx, entry in enumerate(processed_entries)
        }
        for future in as_completed(future_to_index):
            idx = future_to_index[future]
            index_to_draft[idx] = future.result()

    # ---- 按顺序保存草稿文件 ----
    drafts_dir = _resolve_path(root, "/designs/page_drafts")
    drafts_dir.mkdir(parents=True, exist_ok=True)

    summaries: list[ArchitectPageDraftSummary] = []
    success_count = 0
    failed_count = 0

    for idx in range(len(processed_entries)):
        draft = index_to_draft[idx]
        file_name = f"page_draft_{idx}.json"
        draft_file_path = drafts_dir / file_name
        canonical_path = f"/designs/page_drafts/{file_name}"

        draft_file_path.write_text(
            json.dumps(
                draft.model_dump(mode="json", exclude_none=True),
                ensure_ascii=False,
                indent=2,
            ),
            encoding="utf-8",
        )

        if draft.draft_status == "success":
            success_count += 1
        else:
            failed_count += 1

        summaries.append(ArchitectPageDraftSummary(
            draft_index=idx,
            image_path=draft.image_path,
            image_name=draft.image_name,
            draft_status=draft.draft_status,
            candidate_page_id=draft.candidate_page_id,
            candidate_page_name=draft.candidate_page_name,
            layout_summary=draft.layout_summary,
            key_sections=draft.key_sections,
            has_overlay=draft.has_overlay,
            overlay_hint=getattr(draft, "overlay_hint", None),
            draft_file=canonical_path,
        ))

    # ---- 保存轻量索引 ----
    index = ArchitectPageDraftsIndex(
        drafts=summaries,
        total_image_count=total_image_count,
        success_count=success_count,
        failed_count=failed_count,
    )
    index_path = _resolve_path(root, "/designs/page_drafts_index.json")
    index_path.write_text(
        json.dumps(
            index.model_dump(mode="json", exclude_none=True),
            ensure_ascii=False,
            indent=2,
        ),
        encoding="utf-8",
    )

    return "\n".join([
        "status: SUCCESS",
        "index_path: /designs/page_drafts_index.json",
        f"total_image_count: {total_image_count}",
        f"processed_count: {len(processed_entries)}",
        f"success_count: {success_count}",
        f"failed_count: {failed_count}",
    ])


# ---------------------------------------------------------------------------
# 阶段一工具：保存单图完整草稿（保留，供测试或手动调用）
# ---------------------------------------------------------------------------


def save_page_draft(
    draft: dict[str, Any],
    project_root: Path | None = None,
) -> str:
    """
    将单图完整 UI 树草稿保存为独立文件。
    新版阶段一由 batch_extract_page_drafts 代码驱动，此函数保留供测试使用。

    输出路径：/designs/page_drafts/page_draft_{draft_index}.json
    """
    root = _get_workspace_root(project_root)

    draft = _deep_load_json(draft)

    try:
        validated = ArchitectPageDraft.model_validate(draft)
    except Exception as exc:
        return f"保存失败：draft 校验错误：{exc}"

    drafts_dir = _resolve_path(root, "/designs/page_drafts")
    drafts_dir.mkdir(parents=True, exist_ok=True)

    file_name = f"page_draft_{validated.draft_index}.json"
    draft_file_path = drafts_dir / file_name
    canonical_path = f"/designs/page_drafts/{file_name}"

    draft_data = validated.model_dump(mode="json", exclude_none=True)
    draft_file_path.write_text(
        json.dumps(draft_data, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    return "\n".join([
        "status: SUCCESS",
        f"draft_file: {canonical_path}",
        f"draft_index: {validated.draft_index}",
        f"candidate_page_id: {validated.candidate_page_id}",
    ])


# ---------------------------------------------------------------------------
# 阶段一工具：保存轻量摘要索引（保留，供测试或手动调用）
# ---------------------------------------------------------------------------


def save_page_drafts_index(
    index: dict[str, Any],
    project_root: Path | None = None,
) -> str:
    """
    将所有图的轻量摘要保存为索引文件，供阶段二归并决策消费。
    新版阶段一由 batch_extract_page_drafts 代码驱动，此函数保留供测试使用。

    输出路径：/designs/page_drafts_index.json
    """
    root = _get_workspace_root(project_root)

    index = _deep_load_json(index)

    try:
        validated = ArchitectPageDraftsIndex.model_validate(index)
    except Exception as exc:
        return f"保存失败：index 校验错误：{exc}"

    output_path = _resolve_path(root, "/designs/page_drafts_index.json")
    output_path.parent.mkdir(parents=True, exist_ok=True)

    output_path.write_text(
        json.dumps(
            validated.model_dump(mode="json", exclude_none=True),
            ensure_ascii=False,
            indent=2,
        ),
        encoding="utf-8",
    )

    return "\n".join([
        "status: SUCCESS",
        "index_path: /designs/page_drafts_index.json",
        f"total_image_count: {validated.total_image_count}",
        f"success_count: {validated.success_count}",
        f"failed_count: {validated.failed_count}",
        f"draft_count: {len(validated.drafts)}",
    ])


# ---------------------------------------------------------------------------
# 阶段二工具：按需读取单个完整草稿
# ---------------------------------------------------------------------------


def read_page_draft(
    draft_file: str,
    project_root: Path | None = None,
) -> str:
    """
    Agent 归并阶段按需调用。
    读取指定完整草稿文件，返回其 JSON 内容字符串。

    参数：
        draft_file: 草稿文件路径，如 /designs/page_drafts/page_draft_0.json
    """
    root = _get_workspace_root(project_root)

    resolved = _resolve_path(root, draft_file)
    if not resolved.exists() or not resolved.is_file():
        return f"读取失败：草稿文件不存在：{draft_file}"

    try:
        content = resolved.read_text(encoding="utf-8")
        json.loads(content)  # 验证是合法 JSON
        return content
    except json.JSONDecodeError as exc:
        return f"读取失败：草稿文件不是合法 JSON：{exc}"
    except Exception as exc:
        return f"读取失败：{exc}"


# ---------------------------------------------------------------------------
# 阶段二工具：保存最终架构结果
# ---------------------------------------------------------------------------


def save_architect_design(
    payload: dict[str, Any],
    project_root: Path | None = None,
) -> str:
    """
    Agent 归并完成后调用一次。
    将最终的 index + pages 结构落盘为：
      - /designs/architect_index.json
      - /designs/pages/{page_id}.json
    """
    root = _get_workspace_root(project_root)
    return _normalize_and_persist(payload, root)


# ---------------------------------------------------------------------------
# 内部：normalize + 落盘
# ---------------------------------------------------------------------------


def _normalize_and_persist(
    payload: Any,
    root: Path,
) -> str:
    if isinstance(payload, ArchitectPersistPayload):
        normalized = payload
    else:
        if isinstance(payload, BaseModel):
            payload = payload.model_dump(mode="json")

        payload = _deep_load_json(payload)

        if not isinstance(payload, dict):
            return f"保存失败：输出类型不受支持：{type(payload).__name__}"

        for field in ("pages", "index"):
            val = payload.get(field)
            if isinstance(val, str):
                stripped = val.strip()
                if stripped:
                    try:
                        payload[field] = json.loads(stripped)
                    except json.JSONDecodeError:
                        pass

        if isinstance(payload.get("pages"), dict):
            payload["pages"] = [payload["pages"]]

        try:
            normalized = ArchitectPersistPayload.model_validate(payload)
        except Exception as exc:
            return f"保存失败：{exc}"

    # 写盘
    index_path = _resolve_path(root, "/designs/architect_index.json")
    pages_dir = _resolve_path(root, "/designs/pages")

    index_path.parent.mkdir(parents=True, exist_ok=True)
    pages_dir.mkdir(parents=True, exist_ok=True)

    page_paths: list[str] = []
    page_ids_seen: set[str] = set()

    for page in normalized.pages:
        page_id = page.page_id.strip()
        if not page_id:
            return "保存失败：存在空 page_id"
        if page_id in page_ids_seen:
            return f"保存失败：存在重复 page_id: {page_id}"
        page_ids_seen.add(page_id)

        canonical_path = f"/designs/pages/{page_id}.json"
        page_file_path = pages_dir / f"{page_id}.json"
        page_data = page.model_dump(mode="json", exclude_none=True)
        page_data["page_file_path"] = canonical_path
        page_file_path.write_text(
            json.dumps(page_data, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )
        page_paths.append(canonical_path)

    # 回写 index.page_index 的 page_file_path
    index_data = normalized.index.model_dump(mode="json", exclude_none=True)
    page_index = index_data.get("page_index") or []
    corrected_page_index: list[dict[str, Any]] = []
    for item in page_index:
        item = dict(item)
        pid = str(item.get("page_id") or "").strip()
        if pid:
            item["page_file_path"] = f"/designs/pages/{pid}.json"
        corrected_page_index.append(item)

    existing_pids = {str(i.get("page_id") or "") for i in corrected_page_index}
    for page in normalized.pages:
        pid = page.page_id.strip()
        if pid and pid not in existing_pids:
            corrected_page_index.append({
                "page_id": pid,
                "page_name": page.page_name,
                "route": page.route or "",
                "page_file_path": f"/designs/pages/{pid}.json",
                "role": page.role or "",
                "summary": page.summary or "",
            })
            existing_pids.add(pid)

    index_data["page_index"] = corrected_page_index
    index_path.write_text(
        json.dumps(index_data, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    # 验证写盘结果
    missing_files: list[str] = []
    if not index_path.exists():
        missing_files.append("/designs/architect_index.json")
    for page_path in page_paths:
        if not _resolve_path(root, page_path).exists():
            missing_files.append(page_path)

    if missing_files:
        return f"保存失败：以下文件未成功写入：{', '.join(missing_files)}"

    return "\n".join([
        "status: SUCCESS",
        "index_path: /designs/architect_index.json",
        f"page_count: {len(page_paths)}",
        "page_paths:",
        *page_paths,
    ])