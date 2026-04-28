from __future__ import annotations

import base64
import json
import mimetypes
import re
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from typing import Any

from langchain_core.messages import HumanMessage

from models import architect_vision_model


# ---------------------------------------------------------------------------
# Session-scoped path helpers
# ---------------------------------------------------------------------------


def _get_workspace_root(project_root: Path | None = None) -> Path:
    """
    Return the canonical session workspace root.

    Accepts either:
    - repository root
    - an already-resolved session workspace root
    """
    from utils.session_context import get_current_session_id

    session_id = get_current_session_id()
    if not session_id:
        raise ValueError("current session id is missing")

    base = (
        project_root.resolve()
        if project_root is not None
        else Path(__file__).resolve().parents[1]
    )

    if (
        base.name == session_id
        and base.parent.name == "sessions"
        and base.parent.parent.name == "agent_workspace"
    ):
        return base

    return (base / "agent_workspace" / "sessions" / session_id).resolve()


def _resolve_path(root: Path, raw_path: str) -> Path:
    """
    Resolve a project-canonical path under a precomputed workspace root.
    """
    return (root / raw_path.lstrip("/")).resolve()


# ---------------------------------------------------------------------------
# JSON helpers
# ---------------------------------------------------------------------------


def _deep_load_json(value: Any) -> Any:
    """Recursively deserialize nested JSON strings into native Python objects."""
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


def _extract_text_from_model_response(response: Any) -> str:
    """Best-effort extraction of text content from a LangChain-style model response."""
    if response is None:
        return ""

    content = getattr(response, "content", None)

    if isinstance(content, str):
        return content

    if isinstance(content, list):
        parts: list[str] = []
        for item in content:
            if isinstance(item, str):
                parts.append(item)
            elif isinstance(item, dict):
                text_val = item.get("text")
                if isinstance(text_val, str):
                    parts.append(text_val)
            else:
                text_val = getattr(item, "text", None)
                if isinstance(text_val, str):
                    parts.append(text_val)
        return "\n".join(part for part in parts if part)

    if isinstance(response, str):
        return response

    return str(response)


def _strip_code_fence(text: str) -> str:
    stripped = text.strip()
    if stripped.startswith("```"):
        stripped = re.sub(r"^```[a-zA-Z0-9_-]*\s*", "", stripped)
        stripped = re.sub(r"\s*```$", "", stripped)
    return stripped.strip()


def _replace_smart_quotes(text: str) -> str:
    return (
        text.replace("“", '"')
        .replace("”", '"')
        .replace("‘", "'")
        .replace("’", "'")
    )


def _remove_json_trailing_commas(text: str) -> str:
    text = re.sub(r",\s*}", "}", text)
    text = re.sub(r",\s*]", "]", text)
    return text


def _cleanup_json_like_text(text: str) -> str:
    text = _strip_code_fence(text)
    text = _replace_smart_quotes(text)
    text = text.replace("\ufeff", "")
    text = re.sub(r"[\x00-\x08\x0b\x0c\x0e-\x1f]", "", text)
    return text.strip()


def _extract_balanced_json_object_candidate(text: str) -> str | None:
    """
    Extract the first balanced top-level JSON object candidate from text.
    Ignores braces inside quoted strings.
    """
    start = text.find("{")
    if start < 0:
        return None

    depth = 0
    in_string = False
    escape = False

    for idx in range(start, len(text)):
        ch = text[idx]

        if in_string:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
                in_string = False
            continue

        if ch == '"':
            in_string = True
            continue

        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return text[start : idx + 1]

    return None


def _try_parse_json_object(text: str) -> dict[str, Any] | None:
    try:
        parsed = json.loads(text)
        if isinstance(parsed, dict):
            return parsed
    except Exception:
        return None
    return None


def _try_repair_json_text(text: str) -> str:
    repaired = text.strip()

    first_brace = repaired.find("{")
    if first_brace >= 0:
        repaired = repaired[first_brace:]

    repaired = _remove_json_trailing_commas(repaired)

    candidate = _extract_balanced_json_object_candidate(repaired)
    if candidate:
        repaired = candidate

    return repaired.strip()


def _extract_json_object_from_text(text: str) -> tuple[dict[str, Any], str]:
    """
    Extract the first valid JSON object from text.

    Returns:
    - parsed_dict
    - parse_mode: success | repaired
    """
    cleaned = _cleanup_json_like_text(text)

    parsed = _try_parse_json_object(cleaned)
    if parsed is not None:
        return parsed, "success"

    candidate = _extract_balanced_json_object_candidate(cleaned)
    if candidate:
        parsed = _try_parse_json_object(candidate)
        if parsed is not None:
            return parsed, "success"

        repaired_candidate = _try_repair_json_text(candidate)
        parsed = _try_parse_json_object(repaired_candidate)
        if parsed is not None:
            return parsed, "repaired"

    repaired = _try_repair_json_text(cleaned)
    parsed = _try_parse_json_object(repaired)
    if parsed is not None:
        return parsed, "repaired"

    raise ValueError("failed to parse JSON object from model response")


def _ensure_list(value: Any) -> list[Any]:
    if value is None:
        return []
    if isinstance(value, list):
        return value
    return [value]


def _ensure_list_of_strings(value: Any) -> list[str]:
    if value is None:
        return []
    if isinstance(value, list):
        result: list[str] = []
        for item in value:
            if isinstance(item, str):
                text = item.strip()
                if text:
                    result.append(text)
        return result
    if isinstance(value, str):
        text = value.strip()
        return [text] if text else []
    return []


def _safe_str(value: Any, default: str = "") -> str:
    if value is None:
        return default
    text = str(value).strip()
    return text if text else default


def _safe_dict(value: Any) -> dict[str, Any]:
    return value if isinstance(value, dict) else {}


def _normalize_id(value: Any, fallback: str) -> str:
    text = _safe_str(value, fallback).lower()
    text = re.sub(r"[^a-z0-9_]+", "_", text)
    text = re.sub(r"_+", "_", text).strip("_")
    return text or fallback


def _normalize_ui_tree(value: Any) -> dict[str, Any]:
    """Normalize a merged page ui_tree while preserving user-provided structure."""
    value = _deep_load_json(value)
    if not isinstance(value, dict):
        return {
            "type": "UnknownContainer",
            "id": "page_root",
            "children": [],
        }

    node = dict(value)
    node.setdefault("type", "UnknownContainer")
    node.setdefault("id", "page_root")

    children = node.get("children")
    if not isinstance(children, list):
        node["children"] = []

    return node


def _safe_json_load_file(path: Path) -> tuple[dict[str, Any] | None, str | None]:
    try:
        content = path.read_text(encoding="utf-8")
    except Exception as exc:  # noqa: BLE001
        return None, f"读取失败：{exc}"

    try:
        data = json.loads(content)
    except json.JSONDecodeError as exc:
        return None, f"不是合法 JSON：{exc}"

    if not isinstance(data, dict):
        return None, "JSON 顶层不是 object"

    return data, None


# ---------------------------------------------------------------------------
# Stage 1 draft normalization
# ---------------------------------------------------------------------------


def _sanitize_stage1_draft(
    raw: Any,
    draft_index: int,
    image_path: str,
    image_name: str,
) -> dict[str, Any]:
    """
    Lightweight normalization for the new Stage 1 draft format.
    Only does minimal structural filling, no hard schema validation.
    """
    if not isinstance(raw, dict):
        raw = {}

    data = _deep_load_json(raw)
    if not isinstance(data, dict):
        data = {}

    data.setdefault("observation_meta", {})
    data.setdefault("page_identity", {})
    data.setdefault("page_overview", {})
    data.setdefault("ui_tree", {})
    data.setdefault("structural_blocks", [])
    data.setdefault("key_content", {})
    data.setdefault("interaction_clues", [])
    data.setdefault("navigation_hints", {})
    data.setdefault("state_hints", {})
    data.setdefault("overlay_hints", {})
    data.setdefault("merge_hints", {})
    data.setdefault("subpage_hints", {})
    data.setdefault("implementation_semantics", {})
    data.setdefault("raw_preservation", {})

    observation_meta = _safe_dict(data["observation_meta"])
    data["observation_meta"] = observation_meta
    observation_meta["stage"] = "architect_stage1_single_image_observation"
    observation_meta["schema_version"] = "stage1.v1"
    observation_meta["draft_index"] = draft_index
    observation_meta["image_path"] = image_path
    observation_meta["image_name"] = image_name

    status = _safe_str(observation_meta.get("observation_status"), "success")
    if status not in {"success", "repaired", "partial", "failed"}:
        status = "success"
    observation_meta["observation_status"] = status

    page_identity = _safe_dict(data["page_identity"])
    data["page_identity"] = page_identity
    page_identity.setdefault("candidate_page_name", image_name or f"page_{draft_index}")
    page_identity.setdefault("candidate_page_id", f"page_{draft_index}")
    page_identity.setdefault("page_role_hint", "unknown")
    page_identity["title_texts"] = _ensure_list_of_strings(page_identity.get("title_texts"))
    page_identity["distinguishing_texts"] = _ensure_list_of_strings(
        page_identity.get("distinguishing_texts")
    )
    page_identity.setdefault("page_goal_summary", None)
    page_identity.setdefault("primary_content_summary", None)

    page_overview = _safe_dict(data["page_overview"])
    data["page_overview"] = page_overview
    page_overview.setdefault("layout_summary", "")
    page_overview.setdefault("visual_semantics", {})

    ui_tree = _safe_dict(data["ui_tree"])
    data["ui_tree"] = ui_tree
    ui_tree.setdefault("type", "UnknownContainer")
    ui_tree.setdefault("id", "page_root")
    ui_tree.setdefault("children", [])

    if not isinstance(data["structural_blocks"], list):
        data["structural_blocks"] = []

    key_content = _safe_dict(data["key_content"])
    data["key_content"] = key_content
    key_content["visible_texts"] = _ensure_list_of_strings(key_content.get("visible_texts"))
    key_content["key_controls"] = _ensure_list_of_strings(key_content.get("key_controls"))

    if not isinstance(data["interaction_clues"], list):
        data["interaction_clues"] = []

    navigation_hints = _safe_dict(data["navigation_hints"])
    data["navigation_hints"] = navigation_hints
    navigation_hints.setdefault("has_back", False)
    navigation_hints.setdefault("has_close", False)
    navigation_hints["primary_ctas"] = _ensure_list_of_strings(
        navigation_hints.get("primary_ctas")
    )
    navigation_hints["likely_entry_points"] = _ensure_list_of_strings(
        navigation_hints.get("likely_entry_points")
    )
    navigation_hints["likely_exit_points"] = _ensure_list_of_strings(
        navigation_hints.get("likely_exit_points")
    )
    navigation_hints.setdefault("navigation_summary", None)

    state_hints = _safe_dict(data["state_hints"])
    data["state_hints"] = state_hints
    state_hints["tab_labels"] = _ensure_list_of_strings(state_hints.get("tab_labels"))
    state_hints["segment_labels"] = _ensure_list_of_strings(state_hints.get("segment_labels"))
    state_hints["filter_hints"] = _ensure_list_of_strings(state_hints.get("filter_hints"))
    state_hints["page_state_tags"] = _ensure_list_of_strings(
        state_hints.get("page_state_tags")
    )
    state_hints.setdefault("active_tab_hint", None)
    state_hints.setdefault("active_segment_hint", None)
    state_hints.setdefault("state_summary", None)

    overlay_hints = _safe_dict(data["overlay_hints"])
    data["overlay_hints"] = overlay_hints
    overlay_hints.setdefault("has_overlay", False)
    if not isinstance(overlay_hints.get("overlay_candidates"), list):
        overlay_hints["overlay_candidates"] = []

    merge_hints = _safe_dict(data["merge_hints"])
    data["merge_hints"] = merge_hints
    merge_hints.setdefault("variant_kind", "unknown")
    merge_hints.setdefault("merge_confidence", "medium")
    merge_hints["same_page_anchor_signals"] = _ensure_list_of_strings(
        merge_hints.get("same_page_anchor_signals")
    )
    merge_hints["distinguishing_state_signals"] = _ensure_list_of_strings(
        merge_hints.get("distinguishing_state_signals")
    )
    merge_hints["independent_page_signals"] = _ensure_list_of_strings(
        merge_hints.get("independent_page_signals")
    )
    merge_hints.setdefault("merge_summary", None)

    subpage_hints = _safe_dict(data["subpage_hints"])
    data["subpage_hints"] = subpage_hints
    subpage_hints["possible_parent_page_hints"] = _ensure_list_of_strings(
        subpage_hints.get("possible_parent_page_hints")
    )
    if not isinstance(subpage_hints.get("possible_child_page_hints"), list):
        subpage_hints["possible_child_page_hints"] = []
    subpage_hints.setdefault("hierarchy_summary", None)

    implementation_semantics = _safe_dict(data["implementation_semantics"])
    data["implementation_semantics"] = implementation_semantics
    implementation_semantics["important_visual_blocks"] = _ensure_list_of_strings(
        implementation_semantics.get("important_visual_blocks")
    )
    implementation_semantics["style_notes"] = _ensure_list_of_strings(
        implementation_semantics.get("style_notes")
    )
    implementation_semantics.setdefault("layout_pattern_hint", None)

    raw_preservation = _safe_dict(data["raw_preservation"])
    data["raw_preservation"] = raw_preservation
    raw_preservation["notable_elements"] = _ensure_list_of_strings(
        raw_preservation.get("notable_elements")
    )
    raw_preservation["uncertainties"] = _ensure_list_of_strings(
        raw_preservation.get("uncertainties")
    )
    raw_preservation.setdefault("raw_observation", None)

    return data


def _build_stage1_prompt(entry: dict[str, Any], draft_index: int, image_path: str) -> str:
    return f"""
你是 `ImageToArkTS` 的 `Architect Single-Image Observer`。
你的任务是：针对单张 UI 截图，提取后续页面归并与实现参考所需的关键信息，输出一个合法 JSON observation draft。

核心要求：
- 忠实描述当前截图中可见事实；
- 判断这张图更像什么页面；
- 提取页面框架、关键结构、关键文本、关键控件；
- 提取关键交互线索、导航线索、状态线索、overlay 线索、归并线索；
- 保留对后续实现有帮助的高层视觉语义；
- 不生成代码；
- 不编造截图中不存在的页面、状态、交互、overlay 或深层结构。

输出字段应尽量包含：
- `observation_meta`
- `page_identity`
- `page_overview`
- `ui_tree`
- `structural_blocks`
- `key_content`
- `interaction_clues`
- `navigation_hints`
- `state_hints`
- `overlay_hints`
- `merge_hints`
- `subpage_hints`
- `implementation_semantics`
- `raw_preservation`

字段要求：
- `page_identity`：页面名称候选、页面 id 候选、页面角色、标题文本、区分性文本、页面用途摘要。
- `page_overview`：页面整体布局摘要和高层视觉语义。
- `ui_tree`：当前截图中可见的 UI 结构；必须是单个根节点对象，不是数组。
- `structural_blocks`：比 `ui_tree` 更粗粒度、更稳定的页面结构块。
- `key_content`：关键可见文本和关键控件。
- `interaction_clues`：返回、关闭、详情入口、更多入口、tab/筛选切换、流程推进、overlay 开关等关键交互事实。
- `navigation_hints`：返回路径、退出路径、主 CTA、可能进入点和离开点。
- `state_hints`：tab、segment、filter、selected 状态，以及页面状态标签。
- `overlay_hints`：是否有 overlay、overlay 类型、触发来源、关闭方式、内容概述。
- `merge_hints`：同页锚点、状态差异证据、独立页面信号。
- `subpage_hints`：潜在父页面、潜在子页面、下钻入口等线索。
- `implementation_semantics`：高层布局模式、重要视觉块、样式提示。
- `raw_preservation`：显著元素、关键事实、不确定性。

提取原则：
- 优先保留页面身份、关键交互、状态/overlay 线索、归并线索。
- 尽量还原当前截图可见结构，但不要伪造不可确认的深层 UI 节点。
- 交互目标不确定时，保留 clue，不要编造明确目标页。
- 如果截图更像 tab 切换、筛选切换、overlay 打开或状态变化，不要轻易误判成独立页面。
- 局部结构不确定时，可使用 `Section`、`ListArea`、`GridArea`、`CardGroup`、`UnknownContainer` 等稳妥节点类型。
- 将不确定性写入 `raw_preservation.uncertainties`。

禁止：
- 编造不存在的页面、交互、状态、overlay。
- 伪造完整精细 UI 树。
- 输出 Markdown、代码块、注释或解释文字。
- 输出旧 schema 字段，如 `root`、`UINode`、`overlays`、`state_variants`、`outbound_navigation`、`route`、`page_file_path`。
- 不要输出省略号，不要在 JSON 前后附加说明文字。

输出要求：
- 最终输出必须是一个合法 JSON object。
- 不确定字段请使用 `[]`、`{{}}` 或 `null`，不要为了凑字段编造内容。
- 无内容数组优先输出 `[]`。

当前输入信息：
- 图片路径：{image_path}
- 文件名：{entry.get("name") or Path(image_path).name}
- 元数据描述：{entry.get("description") or "(none)"}
- draft_index：{draft_index}
""".strip()


def _minimal_observation_draft(
    *,
    draft_index: int,
    image_path: str,
    image_name: str,
    reason: str,
) -> dict[str, Any]:
    return {
        "observation_meta": {
            "stage": "architect_stage1_single_image_observation",
            "schema_version": "stage1.v1",
            "draft_index": draft_index,
            "image_path": image_path,
            "image_name": image_name,
            "observation_status": "failed",
        },
        "page_identity": {
            "candidate_page_name": image_name or "unknown",
            "candidate_page_id": f"page_{draft_index}",
            "page_role_hint": "unknown",
            "title_texts": [],
            "distinguishing_texts": [],
            "page_goal_summary": None,
            "primary_content_summary": None,
        },
        "page_overview": {
            "layout_summary": "fact extraction failed",
            "visual_semantics": {},
        },
        "ui_tree": {
            "type": "UnknownContainer",
            "id": "page_root",
            "children": [],
        },
        "structural_blocks": [],
        "key_content": {
            "visible_texts": [],
            "key_controls": [],
        },
        "interaction_clues": [],
        "navigation_hints": {
            "has_back": False,
            "has_close": False,
            "primary_ctas": [],
            "likely_entry_points": [],
            "likely_exit_points": [],
            "navigation_summary": None,
        },
        "state_hints": {
            "tab_labels": [],
            "active_tab_hint": None,
            "segment_labels": [],
            "active_segment_hint": None,
            "filter_hints": [],
            "page_state_tags": [],
            "state_summary": None,
        },
        "overlay_hints": {
            "has_overlay": False,
            "overlay_candidates": [],
        },
        "merge_hints": {
            "variant_kind": "unknown",
            "merge_confidence": "low",
            "same_page_anchor_signals": [],
            "distinguishing_state_signals": [],
            "independent_page_signals": [],
            "merge_summary": None,
        },
        "subpage_hints": {
            "possible_parent_page_hints": [],
            "possible_child_page_hints": [],
            "hierarchy_summary": None,
        },
        "implementation_semantics": {
            "layout_pattern_hint": None,
            "important_visual_blocks": [],
            "style_notes": [],
        },
        "raw_preservation": {
            "notable_elements": [],
            "raw_observation": None,
            "uncertainties": [reason],
            "error": reason,
        },
    }


def _extract_possible_text_items(text: str, limit: int = 12) -> list[str]:
    lines = [line.strip(" -•\t\r\n") for line in text.splitlines()]
    cleaned: list[str] = []
    for line in lines:
        if not line:
            continue
        if len(line) > 120:
            continue
        if line.startswith("{") or line.startswith("}") or line.startswith('"'):
            continue
        cleaned.append(line)
        if len(cleaned) >= limit:
            break
    return cleaned


def _build_partial_observation_draft(
    *,
    draft_index: int,
    image_path: str,
    image_name: str,
    raw_text: str,
    reason: str,
) -> dict[str, Any]:
    visible_texts = _extract_possible_text_items(raw_text, limit=12)

    draft = {
        "observation_meta": {
            "stage": "architect_stage1_single_image_observation",
            "schema_version": "stage1.v1",
            "draft_index": draft_index,
            "image_path": image_path,
            "image_name": image_name,
            "observation_status": "partial",
        },
        "page_identity": {
            "candidate_page_name": image_name or f"page_{draft_index}",
            "candidate_page_id": f"page_{draft_index}",
            "page_role_hint": "unknown",
            "title_texts": [],
            "distinguishing_texts": visible_texts[:3],
            "page_goal_summary": None,
            "primary_content_summary": None,
        },
        "page_overview": {
            "layout_summary": "partial observation recovered from non-parseable model output",
            "visual_semantics": {},
        },
        "ui_tree": {
            "type": "UnknownContainer",
            "id": "page_root",
            "children": [],
        },
        "structural_blocks": [],
        "key_content": {
            "visible_texts": visible_texts,
            "key_controls": [],
        },
        "interaction_clues": [],
        "navigation_hints": {
            "has_back": False,
            "has_close": False,
            "primary_ctas": [],
            "likely_entry_points": [],
            "likely_exit_points": [],
            "navigation_summary": None,
        },
        "state_hints": {
            "tab_labels": [],
            "active_tab_hint": None,
            "segment_labels": [],
            "active_segment_hint": None,
            "filter_hints": [],
            "page_state_tags": [],
            "state_summary": None,
        },
        "overlay_hints": {
            "has_overlay": False,
            "overlay_candidates": [],
        },
        "merge_hints": {
            "variant_kind": "unknown",
            "merge_confidence": "low",
            "same_page_anchor_signals": [],
            "distinguishing_state_signals": [],
            "independent_page_signals": [],
            "merge_summary": None,
        },
        "subpage_hints": {
            "possible_parent_page_hints": [],
            "possible_child_page_hints": [],
            "hierarchy_summary": None,
        },
        "implementation_semantics": {
            "layout_pattern_hint": None,
            "important_visual_blocks": [],
            "style_notes": [],
        },
        "raw_preservation": {
            "notable_elements": [],
            "raw_observation": raw_text,
            "uncertainties": [reason],
            "error": reason,
        },
    }

    return _sanitize_stage1_draft(
        draft,
        draft_index=draft_index,
        image_path=image_path,
        image_name=image_name,
    )


# ---------------------------------------------------------------------------
# Image encoding
# ---------------------------------------------------------------------------


def _encode_image_as_data_url(image_path: Path) -> str:
    mime, _ = mimetypes.guess_type(str(image_path))
    if not mime:
        mime = "image/png"
    b64 = base64.b64encode(image_path.read_bytes()).decode("ascii")
    return f"data:{mime};base64,{b64}"


# ---------------------------------------------------------------------------
# Metadata loading
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
            ".png",
            ".jpg",
            ".jpeg",
            ".webp",
            ".bmp",
            ".gif",
        }
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


# ---------------------------------------------------------------------------
# Stage 1: single-image extraction with retry
# ---------------------------------------------------------------------------

_SINGLE_DRAFT_MAX_ATTEMPTS = 3


def _failed_draft(
    *,
    entry: dict[str, Any],
    draft_index: int,
    image_path: str,
    reason: str,
) -> dict[str, Any]:
    return _minimal_observation_draft(
        draft_index=draft_index,
        image_path=image_path,
        image_name=str(entry.get("name") or Path(image_path).stem),
        reason=reason,
    )


def _extract_single_page_draft_once(
    entry: dict[str, Any],
    draft_index: int,
    root: Path,
) -> dict[str, Any]:
    image_path = str(entry.get("path") or "")
    image_name = str(entry.get("name") or Path(image_path).stem)
    resolved = _resolve_path(root, image_path)

    if not resolved.exists() or not resolved.is_file():
        return _minimal_observation_draft(
            draft_index=draft_index,
            image_path=image_path,
            image_name=image_name,
            reason=f"image file missing: {image_path}",
        )

    data_url = _encode_image_as_data_url(resolved)
    prompt = _build_stage1_prompt(entry=entry, draft_index=draft_index, image_path=image_path)

    response = architect_vision_model.invoke(
        [
            HumanMessage(
                content=[
                    {"type": "text", "text": prompt},
                    {"type": "image_url", "image_url": {"url": data_url}},
                ]
            )
        ]
    )

    text = _extract_text_from_model_response(response)

    try:
        parsed, parse_mode = _extract_json_object_from_text(text)
        parsed = _deep_load_json(parsed)
        if not isinstance(parsed, dict):
            raise ValueError("parsed model result is not a dict")

        parsed.setdefault("observation_meta", {})
        observation_meta = _safe_dict(parsed["observation_meta"])
        observation_meta["observation_status"] = "repaired" if parse_mode == "repaired" else "success"
        parsed["observation_meta"] = observation_meta

        parsed.setdefault("raw_preservation", {})
        raw_preservation = _safe_dict(parsed["raw_preservation"])
        raw_preservation.setdefault("raw_observation", text)
        if parse_mode == "repaired":
            uncertainties = _ensure_list_of_strings(raw_preservation.get("uncertainties"))
            uncertainties.append("json_repaired_from_model_output")
            raw_preservation["uncertainties"] = uncertainties
        parsed["raw_preservation"] = raw_preservation

        sanitized = _sanitize_stage1_draft(
            parsed,
            draft_index=draft_index,
            image_path=image_path,
            image_name=image_name,
        )
        return sanitized
    except Exception as exc:  # noqa: BLE001
        return _build_partial_observation_draft(
            draft_index=draft_index,
            image_path=image_path,
            image_name=image_name,
            raw_text=text,
            reason=f"non-parseable model output preserved for stage2 fallback: {exc}",
        )


def _extract_single_page_draft(
    entry: dict[str, Any],
    draft_index: int,
    root: Path,
) -> dict[str, Any]:
    image_path = str(entry.get("path") or "")
    image_name = str(entry.get("name") or Path(image_path).stem)

    last_error: Exception | None = None
    for attempt in range(1, _SINGLE_DRAFT_MAX_ATTEMPTS + 1):
        try:
            draft = _extract_single_page_draft_once(
                entry=entry,
                draft_index=draft_index,
                root=root,
            )

            observation_meta = draft.get("observation_meta", {})
            status = (
                observation_meta.get("observation_status")
                if isinstance(observation_meta, dict)
                else None
            )

            if status in {"success", "repaired", "partial"}:
                if attempt > 1:
                    raw_preservation = _safe_dict(draft.setdefault("raw_preservation", {}))
                    uncertainties = _ensure_list_of_strings(
                        raw_preservation.get("uncertainties")
                    )
                    uncertainties.append(f"recovered_after_retry: attempt={attempt}")
                    raw_preservation["uncertainties"] = uncertainties
                    draft["raw_preservation"] = raw_preservation
                return draft

            last_error = RuntimeError(
                f"observation_status returned unusable status: {status}"
            )
        except Exception as exc:  # noqa: BLE001
            last_error = exc

    return _minimal_observation_draft(
        draft_index=draft_index,
        image_path=image_path,
        image_name=image_name,
        reason=(
            f"fact extraction failed after {_SINGLE_DRAFT_MAX_ATTEMPTS} attempts: {last_error}"
            if last_error
            else f"fact extraction failed after {_SINGLE_DRAFT_MAX_ATTEMPTS} attempts"
        ),
    )


# ---------------------------------------------------------------------------
# Stage 1: persistence helpers
# ---------------------------------------------------------------------------


def _write_page_draft_file(
    draft: dict[str, Any],
    root: Path,
) -> str:
    drafts_dir = _resolve_path(root, "/designs/page_drafts")
    drafts_dir.mkdir(parents=True, exist_ok=True)

    observation_meta = draft.get("observation_meta", {}) if isinstance(draft, dict) else {}
    draft_index = 0
    if isinstance(observation_meta, dict):
        try:
            draft_index = int(observation_meta.get("draft_index", 0))
        except Exception:
            draft_index = 0

    file_name = f"page_draft_{draft_index}.json"
    draft_file_path = drafts_dir / file_name
    canonical_path = f"/designs/page_drafts/{file_name}"

    draft_file_path.write_text(
        json.dumps(draft, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    return canonical_path


def _build_draft_summary(
    draft: dict[str, Any],
    draft_file: str,
) -> dict[str, Any]:
    observation_meta = draft.get("observation_meta", {}) if isinstance(draft, dict) else {}
    page_identity = draft.get("page_identity", {}) if isinstance(draft, dict) else {}
    page_overview = draft.get("page_overview", {}) if isinstance(draft, dict) else {}
    overlay_hints = draft.get("overlay_hints", {}) if isinstance(draft, dict) else {}
    merge_hints = draft.get("merge_hints", {}) if isinstance(draft, dict) else {}
    interaction_clues = draft.get("interaction_clues", []) if isinstance(draft, dict) else {}
    ui_tree = draft.get("ui_tree", {}) if isinstance(draft, dict) else {}

    return {
        "draft_index": observation_meta.get("draft_index"),
        "image_path": observation_meta.get("image_path"),
        "image_name": observation_meta.get("image_name"),
        "observation_status": observation_meta.get("observation_status"),
        "candidate_page_id": page_identity.get("candidate_page_id"),
        "candidate_page_name": page_identity.get("candidate_page_name"),
        "page_role_hint": page_identity.get("page_role_hint"),
        "layout_summary": page_overview.get("layout_summary"),
        "draft_file": draft_file,
        "has_ui_tree": isinstance(ui_tree, dict) and bool(ui_tree),
        "has_overlay": bool(overlay_hints.get("has_overlay"))
        if isinstance(overlay_hints, dict)
        else False,
        "interaction_count": len(interaction_clues) if isinstance(interaction_clues, list) else 0,
        "merge_variant_hint": merge_hints.get("variant_kind")
        if isinstance(merge_hints, dict)
        else None,
    }


# ---------------------------------------------------------------------------
# Stage 1: batch extraction entrypoint
# ---------------------------------------------------------------------------


def batch_extract_page_drafts(
    metadata_path: str = "/user_input/user_input_metadata.json",
    max_images: int = 35,
    project_root: Path | None = None,
) -> str:
    """
    Stage 1:
    - Extract per-image observation drafts concurrently
    - Persist each completed draft immediately on the main thread
    - Persist a lightweight drafts index at the end

    Outputs:
      - /designs/page_drafts/page_draft_{i}.json
      - /designs/page_drafts_index.json
    """
    root = _get_workspace_root(project_root)
    entries = _load_metadata_entries(metadata_path, project_root=project_root)
    processed_entries = entries[: max(0, max_images)]
    total_image_count = len(entries)

    _resolve_path(root, "/designs/page_drafts").mkdir(parents=True, exist_ok=True)

    index_to_summary: dict[int, dict[str, Any]] = {}
    success_count = 0
    repaired_count = 0
    partial_count = 0
    failed_count = 0
    recovered_after_retry_count = 0

    with ThreadPoolExecutor(
        max_workers=min(4, max(1, len(processed_entries) or 1))
    ) as executor:
        future_to_index = {
            executor.submit(_extract_single_page_draft, entry, idx, root): idx
            for idx, entry in enumerate(processed_entries)
        }

        for future in as_completed(future_to_index):
            idx = future_to_index[future]
            entry = processed_entries[idx]

            try:
                draft = future.result()
            except Exception as exc:  # noqa: BLE001
                draft = _failed_draft(
                    entry=entry,
                    draft_index=idx,
                    image_path=str(entry.get("path") or ""),
                    reason=f"worker crashed unexpectedly: {exc}",
                )

            canonical_path = _write_page_draft_file(draft, root=root)
            summary = _build_draft_summary(draft, canonical_path)
            index_to_summary[idx] = summary

            observation_meta = draft.get("observation_meta", {})
            observation_status = (
                observation_meta.get("observation_status")
                if isinstance(observation_meta, dict)
                else None
            )
            if observation_status == "success":
                success_count += 1
            elif observation_status == "repaired":
                repaired_count += 1
            elif observation_status == "partial":
                partial_count += 1
            else:
                failed_count += 1

            raw_preservation = draft.get("raw_preservation", {})
            uncertainties = _ensure_list_of_strings(
                raw_preservation.get("uncertainties")
                if isinstance(raw_preservation, dict)
                else []
            )
            if any("recovered_after_retry:" in str(item) for item in uncertainties):
                recovered_after_retry_count += 1

    summaries = [index_to_summary[idx] for idx in range(len(processed_entries))]

    index = {
        "schema_version": "stage1_index.v1",
        "drafts": summaries,
        "draft_files": [item.get("draft_file") for item in summaries if item.get("draft_file")],
        "draft_file_count": len(
            [item.get("draft_file") for item in summaries if item.get("draft_file")]
        ),
        "total_image_count": total_image_count,
        "processed_count": len(processed_entries),
        "success_count": success_count,
        "repaired_count": repaired_count,
        "partial_count": partial_count,
        "failed_count": failed_count,
    }

    index_path = _resolve_path(root, "/designs/page_drafts_index.json")
    index_path.parent.mkdir(parents=True, exist_ok=True)
    index_path.write_text(
        json.dumps(index, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    return "\n".join(
        [
            "status: SUCCESS",
            "index_path: /designs/page_drafts_index.json",
            f"workspace_root: {root}",
            f"total_image_count: {total_image_count}",
            f"processed_count: {len(processed_entries)}",
            f"success_count: {success_count}",
            f"repaired_count: {repaired_count}",
            f"partial_count: {partial_count}",
            f"failed_count: {failed_count}",
            f"recovered_after_retry_count: {recovered_after_retry_count}",
            f"max_attempts_per_image: {_SINGLE_DRAFT_MAX_ATTEMPTS}",
        ]
    )


# ---------------------------------------------------------------------------
# Stage 1 helper tool: save one observation draft
# ---------------------------------------------------------------------------


def save_page_draft(
    draft: dict[str, Any],
    project_root: Path | None = None,
) -> str:
    """Normalize and persist one stage1 single-image observation draft JSON file."""
    root = _get_workspace_root(project_root)
    draft = _deep_load_json(draft)

    if not isinstance(draft, dict):
        return "保存失败：draft 必须是 JSON object"

    observation_meta = draft.get("observation_meta", {})
    if not isinstance(observation_meta, dict):
        observation_meta = {}
        draft["observation_meta"] = observation_meta

    draft_index = observation_meta.get("draft_index", 0)
    image_path = str(observation_meta.get("image_path") or "")
    image_name = str(
        observation_meta.get("image_name") or Path(image_path or f"page_{draft_index}.png").stem
    )

    draft = _sanitize_stage1_draft(
        draft,
        draft_index=int(draft_index or 0),
        image_path=image_path,
        image_name=image_name,
    )

    canonical_path = _write_page_draft_file(draft, root=root)

    page_identity = draft.get("page_identity", {})

    return "\n".join(
        [
            "status: SUCCESS",
            f"workspace_root: {root}",
            f"draft_file: {canonical_path}",
            f"draft_index: {draft.get('observation_meta', {}).get('draft_index')}",
            f"candidate_page_id: {page_identity.get('candidate_page_id') if isinstance(page_identity, dict) else ''}",
            f"observation_status: {draft.get('observation_meta', {}).get('observation_status')}",
        ]
    )


def save_page_drafts_index(
    index: dict[str, Any],
    project_root: Path | None = None,
) -> str:
    """Persist the stage1 page drafts index JSON file."""
    root = _get_workspace_root(project_root)
    index = _deep_load_json(index)

    if not isinstance(index, dict):
        return "保存失败：index 必须是 JSON object"

    drafts = index.get("drafts")
    if drafts is None:
        index["drafts"] = []
    elif not isinstance(drafts, list):
        return "保存失败：index.drafts 必须是数组"

    draft_files = index.get("draft_files")
    if draft_files is None:
        index["draft_files"] = []
    elif not isinstance(draft_files, list):
        return "保存失败：index.draft_files 必须是数组"

    index["schema_version"] = _safe_str(index.get("schema_version"), "stage1_index.v1")

    for field in (
        "total_image_count",
        "processed_count",
        "success_count",
        "repaired_count",
        "partial_count",
        "failed_count",
        "draft_file_count",
    ):
        value = index.get(field, 0)
        try:
            index[field] = int(value)
        except Exception:
            index[field] = 0

    output_path = _resolve_path(root, "/designs/page_drafts_index.json")
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(
        json.dumps(index, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    return "\n".join(
        [
            "status: SUCCESS",
            f"workspace_root: {root}",
            "index_path: /designs/page_drafts_index.json",
            f"total_image_count: {index.get('total_image_count', 0)}",
            f"processed_count: {index.get('processed_count', 0)}",
            f"success_count: {index.get('success_count', 0)}",
            f"repaired_count: {index.get('repaired_count', 0)}",
            f"partial_count: {index.get('partial_count', 0)}",
            f"failed_count: {index.get('failed_count', 0)}",
            f"draft_count: {len(index.get('drafts', []))}",
            f"draft_file_count: {len(index.get('draft_files', []))}",
        ]
    )


# ---------------------------------------------------------------------------
# Stage 2 tool: read lightweight drafts index
# ---------------------------------------------------------------------------


def read_page_drafts_index(
    project_root: Path | None = None,
) -> str:
    """Read the persisted stage1 page drafts index JSON file."""
    root = _get_workspace_root(project_root)
    resolved = _resolve_path(root, "/designs/page_drafts_index.json")
    if not resolved.exists() or not resolved.is_file():
        return "读取失败：草稿索引文件不存在：/designs/page_drafts_index.json"

    try:
        content = resolved.read_text(encoding="utf-8")
        json.loads(content)
        return content
    except json.JSONDecodeError as exc:
        return f"读取失败：草稿索引文件不是合法 JSON：{exc}"
    except Exception as exc:  # noqa: BLE001
        return f"读取失败：{exc}"


def read_page_draft(
    draft_file: str,
    project_root: Path | None = None,
) -> str:
    """Read one persisted stage1 page draft JSON file by canonical draft path."""
    root = _get_workspace_root(project_root)
    resolved = _resolve_path(root, draft_file)

    if not resolved.exists() or not resolved.is_file():
        return f"读取失败：草稿文件不存在：{draft_file}"

    try:
        content = resolved.read_text(encoding="utf-8")
        json.loads(content)
        return content
    except json.JSONDecodeError as exc:
        return f"读取失败：草稿文件不是合法 JSON：{exc}"
    except Exception as exc:  # noqa: BLE001
        return f"读取失败：{exc}"


# ---------------------------------------------------------------------------
# Stage 2 and Stage 3 normalization helpers
# ---------------------------------------------------------------------------


_STAGE2_FORBIDDEN_PAGE_TOP_LEVEL_FIELDS = {
    "child_page_ids",
    "parent_page_id",
    "incoming_relations",
    "outgoing_relations",
    "page_role_in_app",
    "navigation_context",
}


def _normalize_interactions(value: Any) -> list[dict[str, Any]]:
    items = _ensure_list(value)
    results: list[dict[str, Any]] = []
    for idx, item in enumerate(items):
        if not isinstance(item, dict):
            continue
        row = dict(item)
        row["interaction_id"] = _normalize_id(
            row.get("interaction_id"), f"interaction_{idx}"
        )
        if "source_label" in row:
            row["source_label"] = _safe_str(row.get("source_label"))
        if "interaction_type" in row:
            row["interaction_type"] = _safe_str(row.get("interaction_type"))
        results.append(row)
    return results


def _normalize_frame_blocks(value: Any) -> list[dict[str, Any]]:
    items = _ensure_list(value)
    results: list[dict[str, Any]] = []
    for idx, item in enumerate(items):
        if not isinstance(item, dict):
            continue
        row = dict(item)
        row["block_id"] = _normalize_id(row.get("block_id"), f"block_{idx}")
        if "block_role" in row:
            row["block_role"] = _safe_str(row.get("block_role"))
        if "summary" in row:
            row["summary"] = _safe_str(row.get("summary"))
        results.append(row)
    return results


def _validate_stage2_page_top_level_fields(page: dict[str, Any]) -> tuple[bool, str | None]:
    forbidden = sorted(
        field for field in _STAGE2_FORBIDDEN_PAGE_TOP_LEVEL_FIELDS if field in page
    )
    if forbidden:
        return (
            False,
            "阶段2页面顶层包含不允许字段: " + ", ".join(forbidden),
        )
    return True, None


def _normalize_page(page: Any, fallback_index: int = 0) -> dict[str, Any]:
    """Normalize one final stage2 page artifact while preserving rich page content."""
    page = _deep_load_json(page)
    if not isinstance(page, dict):
        page = {}

    page_id = _normalize_id(page.get("page_id"), f"page_{fallback_index}")
    page_name = _safe_str(page.get("page_name"), page_id)
    page_role = _safe_str(page.get("page_role"), "unknown")
    page_summary = _safe_str(page.get("page_summary"), "summary unavailable")

    normalized = dict(page)
    normalized["page_id"] = page_id
    normalized["page_name"] = page_name
    normalized["page_role"] = page_role
    normalized["page_summary"] = page_summary
    normalized["schema_version"] = _safe_str(page.get("schema_version"), "stage2_page.v1")
    normalized["derived_from_images"] = _ensure_list_of_strings(page.get("derived_from_images"))
    normalized["source_draft_files"] = _ensure_list_of_strings(page.get("source_draft_files"))
    normalized["source_draft_indexes"] = _ensure_list(page.get("source_draft_indexes"))
    normalized["merge_decision"] = _safe_dict(page.get("merge_decision"))
    normalized["ui_tree"] = _normalize_ui_tree(page.get("ui_tree"))
    normalized["frame_blocks"] = _normalize_frame_blocks(page.get("frame_blocks"))
    normalized["key_texts"] = _ensure_list_of_strings(page.get("key_texts"))
    normalized["key_controls"] = _ensure_list_of_strings(page.get("key_controls"))
    normalized["interactions"] = _normalize_interactions(page.get("interactions"))
    normalized["state_variants"] = _ensure_list(page.get("state_variants"))
    normalized["overlay_ids"] = _ensure_list_of_strings(page.get("overlay_ids"))
    normalized["overlay_summaries"] = _ensure_list(page.get("overlay_summaries"))
    normalized["implementation_hints"] = _safe_dict(page.get("implementation_hints"))
    normalized["visual_style_hints"] = _safe_dict(page.get("visual_style_hints"))
    normalized["notes"] = _ensure_list_of_strings(page.get("notes"))
    normalized["page_semantic_role"] = _safe_str(page.get("page_semantic_role"))
    normalized["target_page_hints"] = _ensure_list_of_strings(page.get("target_page_hints"))
    normalized["possible_parent_page_hints"] = _ensure_list_of_strings(
        page.get("possible_parent_page_hints")
    )
    normalized["possible_child_page_hints"] = _ensure_list_of_strings(
        page.get("possible_child_page_hints")
    )

    for forbidden_key in _STAGE2_FORBIDDEN_PAGE_TOP_LEVEL_FIELDS:
        normalized.pop(forbidden_key, None)

    return normalized


def _is_valid_page_dict(page: dict[str, Any]) -> tuple[bool, str | None]:
    page_id = _safe_str(page.get("page_id"))
    if not page_id:
        return False, "存在空 page_id"

    top_level_ok, top_level_error = _validate_stage2_page_top_level_fields(page)
    if not top_level_ok:
        return False, top_level_error

    has_blocks = len(_ensure_list(page.get("frame_blocks"))) > 0
    has_summary = bool(_safe_str(page.get("page_summary")))
    has_interactions = len(_ensure_list(page.get("interactions"))) > 0
    has_key_texts = len(_ensure_list_of_strings(page.get("key_texts"))) > 0
    has_ui_tree = isinstance(page.get("ui_tree"), dict) and bool(page.get("ui_tree"))

    if not (has_blocks or has_summary or has_interactions or has_key_texts or has_ui_tree):
        return False, f"page {page_id} 缺少最小可用页面内容"

    return True, None


def _load_existing_stage2_page(page_id: str, root: Path) -> dict[str, Any] | None:
    page_file_path = _resolve_path(root, f"/designs/pages/{page_id}.json")
    if not page_file_path.exists() or not page_file_path.is_file():
        return None

    data, error = _safe_json_load_file(page_file_path)
    if error or not data:
        raise ValueError(f"已存在页面文件损坏：/designs/pages/{page_id}.json error={error}")

    file_page_id = _normalize_id(data.get("page_id"), "")
    if file_page_id != page_id:
        raise ValueError(
            f"已存在页面文件 page_id 不一致：expected={page_id} actual={file_page_id or '(empty)'}"
        )

    normalized = _normalize_page(data, 0)
    ok, validation_error = _is_valid_page_dict(normalized)
    if not ok:
        raise ValueError(
            f"已存在页面文件不合法：/designs/pages/{page_id}.json error={validation_error}"
        )
    return normalized


def _normalize_page_index_item(
    item: Any,
    pages_by_id: dict[str, dict[str, Any]],
    fallback_index: int = 0,
) -> dict[str, Any] | None:
    item = _deep_load_json(item)
    if not isinstance(item, dict):
        return None

    pid = _normalize_id(item.get("page_id"), f"page_{fallback_index}")
    page = pages_by_id.get(pid, {})

    return {
        "page_id": pid,
        "page_name": _safe_str(item.get("page_name"), _safe_str(page.get("page_name"), pid)),
        "page_file_path": f"/designs/pages/{pid}.json",
        "page_role": _safe_str(item.get("page_role"), _safe_str(page.get("page_role")) or None),
        "page_summary": _safe_str(
            item.get("page_summary"),
            _safe_str(page.get("page_summary")) or None,
        ),
        "source_images": _ensure_list_of_strings(
            item.get("source_images") or page.get("derived_from_images")
        ),
        "source_draft_indexes": _ensure_list(
            item.get("source_draft_indexes") or page.get("source_draft_indexes")
        ),
        "source_draft_count": (
            int(item.get("source_draft_count"))
            if str(item.get("source_draft_count", "")).isdigit()
            else len(_ensure_list(item.get("source_draft_indexes") or page.get("source_draft_indexes")))
        ),
        "merge_summary": _safe_str(item.get("merge_summary")),
        "merge_variant_type": _safe_str(item.get("merge_variant_type")),
        "page_semantic_role": _safe_str(
            item.get("page_semantic_role"),
            _safe_str(page.get("page_semantic_role")),
        ),
        "interaction_summary": _ensure_list_of_strings(item.get("interaction_summary")),
        "navigation_clue_summary": _ensure_list_of_strings(
            item.get("navigation_clue_summary")
        ),
        "target_page_hints": _ensure_list_of_strings(
            item.get("target_page_hints") or page.get("target_page_hints")
        ),
        "possible_parent_page_hints": _ensure_list_of_strings(
            item.get("possible_parent_page_hints") or page.get("possible_parent_page_hints")
        ),
        "possible_child_page_hints": _ensure_list_of_strings(
            item.get("possible_child_page_hints") or page.get("possible_child_page_hints")
        ),
        "entry_candidate_hint": _safe_str(item.get("entry_candidate_hint"), "unknown"),
        "has_state_variants": bool(item.get("has_state_variants"))
        if item.get("has_state_variants") is not None
        else bool(_ensure_list(page.get("state_variants"))),
        "state_variant_summary": _ensure_list_of_strings(item.get("state_variant_summary")),
        "has_overlays": bool(item.get("has_overlays"))
        if item.get("has_overlays") is not None
        else bool(_ensure_list(page.get("overlay_summaries")) or _ensure_list_of_strings(page.get("overlay_ids"))),
        "overlay_summary": _ensure_list_of_strings(item.get("overlay_summary")),
    }


def _normalize_navigation_hierarchy_item(
    item: Any,
    valid_page_ids: set[str],
) -> dict[str, Any] | None:
    item = _deep_load_json(item)
    if not isinstance(item, dict):
        return None

    page_id = _normalize_id(item.get("page_id"), "")
    if not page_id or page_id not in valid_page_ids:
        return None

    parent_page_id = _normalize_id(item.get("parent_page_id"), "") or None
    if parent_page_id and parent_page_id not in valid_page_ids:
        parent_page_id = None

    child_page_ids = [
        pid for pid in _ensure_list_of_strings(item.get("child_page_ids"))
        if pid in valid_page_ids and pid != page_id
    ]

    return {
        "page_id": page_id,
        "page_role_in_app": _safe_str(item.get("page_role_in_app"), "unknown"),
        "parent_page_id": parent_page_id,
        "child_page_ids": sorted(set(child_page_ids)),
        "reasoning": _safe_str(item.get("reasoning")),
    }


def _normalize_relation(relation: Any, fallback_index: int = 0) -> dict[str, Any] | None:
    relation = _deep_load_json(relation)
    if not isinstance(relation, dict):
        return None

    source_page_id = _normalize_id(relation.get("source_page_id"), "")
    target_page_id = _normalize_id(relation.get("target_page_id"), "")
    relation_id = _normalize_id(relation.get("relation_id"), f"relation_{fallback_index}")

    return {
        "relation_id": relation_id,
        "source_page_id": source_page_id,
        "relation_type": _safe_str(relation.get("relation_type"), "unknown"),
        "trigger_label": relation.get("trigger_label"),
        "trigger_interaction_id": _safe_str(relation.get("trigger_interaction_id"), "") or None,
        "target_page_id": target_page_id or None,
        "confidence": relation.get("confidence"),
        "reasoning": relation.get("reasoning"),
    }


def _normalize_unresolved_relation_hint(
    hint: Any,
    valid_page_ids: set[str],
    fallback_index: int = 0,
) -> tuple[dict[str, Any] | None, str | None]:
    hint = _deep_load_json(hint)
    if not isinstance(hint, dict):
        return None, f"ignored unresolved_relation_hint_{fallback_index}: not an object"

    source_page_id = _normalize_id(hint.get("source_page_id"), "")
    if not source_page_id or source_page_id not in valid_page_ids:
        return None, (
            f"ignored unresolved_relation_hint_{fallback_index}: "
            "source_page_id missing or not in stage2 pages"
        )

    normalized = {
        "source_page_id": source_page_id,
        "trigger_label": hint.get("trigger_label"),
        "trigger_interaction_id": _safe_str(hint.get("trigger_interaction_id"), "") or None,
        "target_page_hint": _safe_str(hint.get("target_page_hint"), "") or None,
        "reasoning": _safe_str(hint.get("reasoning")),
    }
    return normalized, None


def _filter_relations_against_pages(
    relations: list[dict[str, Any]],
    valid_page_ids: set[str],
) -> tuple[list[dict[str, Any]], list[str]]:
    kept: list[dict[str, Any]] = []
    warnings: list[str] = []

    for rel in relations:
        source_page_id = _safe_str(rel.get("source_page_id"))
        target_page_id = _safe_str(rel.get("target_page_id"))

        if source_page_id not in valid_page_ids:
            warnings.append(
                f"removed relation {rel.get('relation_id')} because source_page_id does not exist"
            )
            continue

        if target_page_id and target_page_id not in valid_page_ids:
            warnings.append(
                f"removed relation {rel.get('relation_id')} because target_page_id does not exist"
            )
            continue

        kept.append(rel)

    return kept, warnings


def _load_stage2_pages_from_merge_index(
    root: Path,
) -> tuple[list[str], set[str], list[str]]:
    merge_index_path = _resolve_path(root, "/designs/page_merge_index.json")
    if not merge_index_path.exists() or not merge_index_path.is_file():
        raise ValueError("页面归并索引不存在：/designs/page_merge_index.json")

    merge_index = json.loads(merge_index_path.read_text(encoding="utf-8"))
    raw_page_index = _ensure_list(merge_index.get("page_index"))

    page_ids: list[str] = []
    warnings: list[str] = []

    for item in raw_page_index:
        if not isinstance(item, dict):
            continue
        page_id = _normalize_id(item.get("page_id"), "")
        if not page_id:
            continue

        page_file_path = _resolve_path(root, f"/designs/pages/{page_id}.json")
        if not page_file_path.exists() or not page_file_path.is_file():
            raise ValueError(f"阶段二页面文件缺失：/designs/pages/{page_id}.json")

        page_data, page_error = _safe_json_load_file(page_file_path)
        if page_error:
            raise ValueError(
                f"阶段二页面文件损坏：/designs/pages/{page_id}.json error={page_error}"
            )

        file_page_id = _normalize_id(page_data.get("page_id"), "")
        if file_page_id != page_id:
            raise ValueError(
                f"阶段二页面索引与页面文件不一致：index={page_id} file={file_page_id or '(empty)'}"
            )

        page_ids.append(page_id)

    if not page_ids:
        raise ValueError("阶段二页面集合为空，无法保存导航设计")

    return page_ids, set(page_ids), warnings


def _normalize_navigation_design(
    payload: Any,
    root: Path,
) -> tuple[dict[str, Any], list[str]]:
    """
    Normalize a stage3 navigation-only artifact against stage2 persisted page files.
    """
    payload = _deep_load_json(payload)
    if not isinstance(payload, dict):
        raise ValueError(f"输出类型不受支持：{type(payload).__name__}")

    page_ids, valid_page_ids, structural_warnings = _load_stage2_pages_from_merge_index(root)

    global_notes = _ensure_list_of_strings(payload.get("global_notes"))
    global_notes.extend(structural_warnings)

    original_entry_page_id = _safe_str(payload.get("entry_page_id"))
    entry_page_id = _normalize_id(
        original_entry_page_id,
        page_ids[0] if page_ids else "page_0",
    )
    if entry_page_id not in valid_page_ids:
        corrected_entry = page_ids[0]
        global_notes.append(
            f"entry_page_id corrected from {original_entry_page_id or '(empty)'} to {corrected_entry} "
            "because original entry_page_id is not in stage2 pages"
        )
        entry_page_id = corrected_entry

    raw_hierarchy = _ensure_list(payload.get("page_hierarchy"))
    hierarchy: list[dict[str, Any]] = []
    seen_hierarchy_ids: set[str] = set()
    for item in raw_hierarchy:
        row = _normalize_navigation_hierarchy_item(item, valid_page_ids)
        if not row:
            continue
        if row["page_id"] in seen_hierarchy_ids:
            continue
        hierarchy.append(row)
        seen_hierarchy_ids.add(row["page_id"])

    for pid in page_ids:
        if pid not in seen_hierarchy_ids:
            hierarchy.append(
                {
                    "page_id": pid,
                    "page_role_in_app": "unknown",
                    "parent_page_id": None,
                    "child_page_ids": [],
                    "reasoning": "",
                }
            )
            global_notes.append(
                f"page_hierarchy item auto-filled for page_id={pid} because it was missing in payload"
            )

    raw_relations = _ensure_list(payload.get("relations"))
    normalized_relations: list[dict[str, Any]] = []
    for idx, item in enumerate(raw_relations):
        rel = _normalize_relation(item, idx)
        if rel is None or not rel["source_page_id"]:
            continue
        normalized_relations.append(rel)

    filtered_relations, relation_warnings = _filter_relations_against_pages(
        normalized_relations,
        valid_page_ids,
    )
    global_notes.extend(relation_warnings)

    raw_unresolved_relation_hints = _ensure_list(payload.get("unresolved_relation_hints"))
    unresolved_relation_hints: list[dict[str, Any]] = []
    for idx, item in enumerate(raw_unresolved_relation_hints):
        normalized_hint, warning = _normalize_unresolved_relation_hint(
            item,
            valid_page_ids,
            idx,
        )
        if warning:
            global_notes.append(warning)
            continue
        if normalized_hint:
            unresolved_relation_hints.append(normalized_hint)

    normalized = {
        "schema_version": "stage3_navigation.v1",
        "entry_page_id": entry_page_id,
        "page_ids": page_ids,
        "page_hierarchy": hierarchy,
        "relations": filtered_relations,
        "unresolved_relation_hints": unresolved_relation_hints,
        "global_notes": global_notes,
    }
    return normalized, relation_warnings


# ---------------------------------------------------------------------------
# Stage 2 tool: save one merged page
# ---------------------------------------------------------------------------


def _persist_single_stage2_page(
    page: dict[str, Any],
    root: Path,
    fallback_index: int = 0,
) -> tuple[dict[str, Any], str]:
    normalized = _normalize_page(page, fallback_index)
    ok, error = _is_valid_page_dict(normalized)
    if not ok:
        raise ValueError(error or "invalid stage2 page")

    pages_dir = _resolve_path(root, "/designs/pages")
    pages_dir.mkdir(parents=True, exist_ok=True)

    page_id = normalized["page_id"]
    canonical_path = f"/designs/pages/{page_id}.json"
    page_file_path = pages_dir / f"{page_id}.json"

    page_file_path.write_text(
        json.dumps(normalized, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    if not page_file_path.exists():
        raise ValueError(f"页面文件未成功写入：{canonical_path}")

    return normalized, canonical_path


def save_merged_page(
    page: dict[str, Any],
    project_root: Path | None = None,
) -> str:
    """Normalize and persist one stage2 merged page JSON file."""
    root = _get_workspace_root(project_root)
    try:
        normalized, canonical_path = _persist_single_stage2_page(page, root, 0)
        return "\n".join(
            [
                "status: SUCCESS",
                f"workspace_root: {root}",
                f"page_file: {canonical_path}",
                f"page_id: {normalized.get('page_id')}",
                f"page_name: {normalized.get('page_name')}",
                f"page_role: {normalized.get('page_role')}",
                f"source_draft_count: {len(_ensure_list(normalized.get('source_draft_indexes')))}",
            ]
        )
    except Exception as exc:  # noqa: BLE001
        return f"保存失败：workspace_root={root} error={exc}"


# ---------------------------------------------------------------------------
# Stage 2 tool: save merged pages result
# ---------------------------------------------------------------------------


def save_page_merge_result(
    payload: dict[str, Any],
    project_root: Path | None = None,
) -> str:
    """Persist the stage2 page merge index without overwriting already-saved page files."""
    root = _get_workspace_root(project_root)
    try:
        return _normalize_and_persist_page_merge(payload, root)
    except Exception as exc:  # noqa: BLE001
        return f"保存失败：workspace_root={root} error={exc}"


def _normalize_and_persist_page_merge(
    payload: Any,
    root: Path,
) -> str:
    payload = _deep_load_json(payload)
    if not isinstance(payload, dict):
        return f"保存失败：输出类型不受支持：{type(payload).__name__}"

    if isinstance(payload.get("pages"), dict):
        payload["pages"] = [payload["pages"]]
    if isinstance(payload.get("page_index"), dict):
        payload["page_index"] = [payload["page_index"]]

    raw_pages = _ensure_list(payload.get("pages"))
    normalized_pages: list[dict[str, Any]] = []
    page_ids_seen: set[str] = set()

    for idx, page in enumerate(raw_pages):
        normalized = _normalize_page(page, idx)
        ok, error = _is_valid_page_dict(normalized)
        if not ok:
            return f"保存失败：{error}"

        if normalized["page_id"] in page_ids_seen:
            return f"保存失败：存在重复 page_id: {normalized['page_id']}"
        page_ids_seen.add(normalized["page_id"])

        existing = _load_existing_stage2_page(normalized["page_id"], root)
        if existing is not None:
            normalized_pages.append(existing)
        else:
            return (
                "保存失败：page_merge_result 不会再重写页面文件，"
                f"但页面文件不存在：/designs/pages/{normalized['page_id']}.json"
            )

    pages_by_id = {p["page_id"]: p for p in normalized_pages}

    raw_page_index = _ensure_list(payload.get("page_index"))
    corrected_page_index: list[dict[str, Any]] = []
    existing_pids: set[str] = set()

    validation_summary = _safe_dict(payload.get("validation_summary"))
    validation_summary["schema_version"] = _safe_str(
        validation_summary.get("schema_version"),
        "stage2_validation.v1",
    )
    warnings = _ensure_list_of_strings(validation_summary.get("warnings"))

    draft_disposition_map = _ensure_list(payload.get("draft_disposition_map"))

    for idx, item in enumerate(raw_page_index):
        normalized_item = _normalize_page_index_item(item, pages_by_id, idx)
        if not normalized_item:
            warnings.append(f"ignored invalid page_index item at position {idx}")
            continue

        pid = normalized_item["page_id"]
        page_file_path = _resolve_path(root, f"/designs/pages/{pid}.json")
        if not page_file_path.exists() or not page_file_path.is_file():
            return f"保存失败：page_index 引用了不存在的页面文件：/designs/pages/{pid}.json"

        if pid in existing_pids:
            warnings.append(f"ignored duplicate page_index item for page_id={pid}")
            continue

        corrected_page_index.append(normalized_item)
        existing_pids.add(pid)

    for page in normalized_pages:
        pid = page["page_id"]
        if pid not in existing_pids:
            corrected_page_index.append(
                {
                    "page_id": pid,
                    "page_name": page["page_name"],
                    "page_file_path": f"/designs/pages/{pid}.json",
                    "page_role": page["page_role"],
                    "page_summary": page["page_summary"],
                    "source_images": list(page.get("derived_from_images") or []),
                    "source_draft_indexes": list(page.get("source_draft_indexes") or []),
                    "source_draft_count": len(page.get("source_draft_indexes") or []),
                    "merge_summary": _safe_str(
                        _safe_dict(page.get("merge_decision")).get("decision_summary")
                    ),
                    "merge_variant_type": _safe_str(
                        _safe_dict(page.get("merge_decision")).get("variant_type")
                    ),
                    "page_semantic_role": _safe_str(page.get("page_semantic_role")),
                    "interaction_summary": [],
                    "navigation_clue_summary": [],
                    "target_page_hints": list(page.get("target_page_hints") or []),
                    "possible_parent_page_hints": list(
                        page.get("possible_parent_page_hints") or []
                    ),
                    "possible_child_page_hints": list(
                        page.get("possible_child_page_hints") or []
                    ),
                    "entry_candidate_hint": "unknown",
                    "has_state_variants": bool(page.get("state_variants")),
                    "state_variant_summary": [],
                    "has_overlays": bool(page.get("overlay_summaries") or page.get("overlay_ids")),
                    "overlay_summary": [],
                }
            )
            existing_pids.add(pid)
            warnings.append(
                f"page_index item auto-added for page_id={pid} because it was missing in payload.page_index"
            )

        for draft_file in _ensure_list_of_strings(page.get("source_draft_files")):
            draft_resolved = _resolve_path(root, draft_file)
            if not draft_resolved.exists() or not draft_resolved.is_file():
                warnings.append(
                    f"source_draft_file missing for page_id={pid}: {draft_file}"
                )

    validation_summary["page_count"] = len(normalized_pages)
    validation_summary["page_index_count"] = len(corrected_page_index)
    validation_summary["drafts_with_disposition_count"] = len(draft_disposition_map)
    validation_summary.setdefault("used_draft_indexes", [])
    validation_summary.setdefault("unused_draft_indexes", [])
    validation_summary["warnings"] = warnings

    merge_index_path = _resolve_path(root, "/designs/page_merge_index.json")
    merge_index_path.parent.mkdir(parents=True, exist_ok=True)

    merge_index_data = {
        "schema_version": "stage2_index.v1",
        "page_index": corrected_page_index,
        "draft_disposition_map": draft_disposition_map,
        "validation_summary": validation_summary,
    }

    merge_index_path.write_text(
        json.dumps(merge_index_data, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    missing_files: list[str] = []
    if not merge_index_path.exists():
        missing_files.append("/designs/page_merge_index.json")
    for pid in existing_pids:
        page_path = f"/designs/pages/{pid}.json"
        if not _resolve_path(root, page_path).exists():
            missing_files.append(page_path)

    if missing_files:
        return f"保存失败：以下文件未成功写入：{', '.join(missing_files)}"

    return "\n".join(
        [
            "status: SUCCESS",
            f"workspace_root: {root}",
            "page_merge_index_path: /designs/page_merge_index.json",
            f"page_count: {len(existing_pids)}",
            "page_paths:",
            *[f"/designs/pages/{pid}.json" for pid in sorted(existing_pids)],
        ]
    )


# ---------------------------------------------------------------------------
# Stage 3 tool: read merged page index / page files
# ---------------------------------------------------------------------------


def read_page_merge_index(
    project_root: Path | None = None,
) -> str:
    """Read the persisted stage2 page merge index JSON file."""
    root = _get_workspace_root(project_root)
    resolved = _resolve_path(root, "/designs/page_merge_index.json")
    if not resolved.exists() or not resolved.is_file():
        return "读取失败：页面归并索引文件不存在：/designs/page_merge_index.json"

    try:
        content = resolved.read_text(encoding="utf-8")
        json.loads(content)
        return content
    except json.JSONDecodeError as exc:
        return f"读取失败：页面归并索引文件不是合法 JSON：{exc}"
    except Exception as exc:  # noqa: BLE001
        return f"读取失败：{exc}"


def read_page_file(
    page_file: str,
    project_root: Path | None = None,
) -> str:
    """Read one persisted stage2 page JSON file by canonical page path."""
    root = _get_workspace_root(project_root)
    resolved = _resolve_path(root, page_file)

    if not resolved.exists() or not resolved.is_file():
        return f"读取失败：页面文件不存在：{page_file}"

    try:
        content = resolved.read_text(encoding="utf-8")
        json.loads(content)
        return content
    except json.JSONDecodeError as exc:
        return f"读取失败：页面文件不是合法 JSON：{exc}"
    except Exception as exc:  # noqa: BLE001
        return f"读取失败：{exc}"


def read_navigation_design(
    project_root: Path | None = None,
) -> str:
    """Read the persisted stage3 navigation design JSON file."""
    root = _get_workspace_root(project_root)
    resolved = _resolve_path(root, "/designs/navigation_design.json")

    if not resolved.exists() or not resolved.is_file():
        return "读取失败：导航设计文件不存在：/designs/navigation_design.json"

    try:
        content = resolved.read_text(encoding="utf-8")
        json.loads(content)
        return content
    except json.JSONDecodeError as exc:
        return f"读取失败：导航设计文件不是合法 JSON：{exc}"
    except Exception as exc:  # noqa: BLE001
        return f"读取失败：{exc}"


# ---------------------------------------------------------------------------
# Stage 3 tool: save navigation-only design
# ---------------------------------------------------------------------------


def save_navigation_design(
    payload: dict[str, Any],
    project_root: Path | None = None,
) -> str:
    """Normalize and persist the stage3 navigation-only design JSON file."""
    root = _get_workspace_root(project_root)
    try:
        normalized, _warnings = _normalize_navigation_design(payload, root)
        output_path = _resolve_path(root, "/designs/navigation_design.json")
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(
            json.dumps(normalized, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )

        if not output_path.exists():
            return "保存失败：/designs/navigation_design.json 未成功写入"

        return "\n".join(
            [
                "status: SUCCESS",
                f"workspace_root: {root}",
                "navigation_design_path: /designs/navigation_design.json",
                f"entry_page_id: {normalized.get('entry_page_id')}",
                f"page_count: {len(normalized.get('page_ids', []))}",
                f"relation_count: {len(normalized.get('relations', []))}",
            ]
        )
    except Exception as exc:  # noqa: BLE001
        return f"保存失败：workspace_root={root} error={exc}"


# ---------------------------------------------------------------------------
# Artifact inspection helpers for resume / recovery
# ---------------------------------------------------------------------------


def check_stage1_artifacts(
    project_root: Path | None = None,
) -> str:
    root = _get_workspace_root(project_root)
    index_path = _resolve_path(root, "/designs/page_drafts_index.json")

    result: dict[str, Any] = {
        "stage": "stage1",
        "workspace_root": str(root),
        "exists": False,
        "is_complete": False,
        "index_exists": False,
        "draft_count": 0,
        "missing_draft_files": [],
        "invalid_draft_files": [],
        "errors": [],
    }

    if not index_path.exists() or not index_path.is_file():
        result["errors"].append("missing /designs/page_drafts_index.json")
        return json.dumps(result, ensure_ascii=False, indent=2)

    result["exists"] = True
    result["index_exists"] = True

    index_data, index_error = _safe_json_load_file(index_path)
    if index_error:
        result["errors"].append(f"invalid page_drafts_index.json: {index_error}")
        return json.dumps(result, ensure_ascii=False, indent=2)

    drafts = _ensure_list(index_data.get("drafts"))
    result["draft_count"] = len(drafts)

    for item in drafts:
        if not isinstance(item, dict):
            result["errors"].append("drafts contains non-object item")
            continue

        draft_file = _safe_str(item.get("draft_file"))
        if not draft_file:
            result["missing_draft_files"].append("(empty draft_file)")
            continue

        draft_path = _resolve_path(root, draft_file)
        if not draft_path.exists() or not draft_path.is_file():
            result["missing_draft_files"].append(draft_file)
            continue

        _draft_data, draft_error = _safe_json_load_file(draft_path)
        if draft_error:
            result["invalid_draft_files"].append(f"{draft_file}: {draft_error}")

    result["is_complete"] = (
        result["index_exists"]
        and len(result["errors"]) == 0
        and len(result["missing_draft_files"]) == 0
        and len(result["invalid_draft_files"]) == 0
        and result["draft_count"] > 0
    )

    return json.dumps(result, ensure_ascii=False, indent=2)


def check_stage2_artifacts(
    project_root: Path | None = None,
) -> str:
    root = _get_workspace_root(project_root)
    merge_index_path = _resolve_path(root, "/designs/page_merge_index.json")

    result: dict[str, Any] = {
        "stage": "stage2",
        "workspace_root": str(root),
        "exists": False,
        "is_complete": False,
        "page_merge_index_exists": False,
        "page_count": 0,
        "missing_page_files": [],
        "invalid_page_files": [],
        "inconsistent_page_ids": [],
        "errors": [],
    }

    if not merge_index_path.exists() or not merge_index_path.is_file():
        result["errors"].append("missing /designs/page_merge_index.json")
        return json.dumps(result, ensure_ascii=False, indent=2)

    result["exists"] = True
    result["page_merge_index_exists"] = True

    merge_index_data, merge_index_error = _safe_json_load_file(merge_index_path)
    if merge_index_error:
        result["errors"].append(f"invalid page_merge_index.json: {merge_index_error}")
        return json.dumps(result, ensure_ascii=False, indent=2)

    page_index = _ensure_list(merge_index_data.get("page_index"))
    result["page_count"] = len(page_index)

    seen_ids: set[str] = set()
    for item in page_index:
        if not isinstance(item, dict):
            result["errors"].append("page_index contains non-object item")
            continue

        page_id = _normalize_id(item.get("page_id"), "")
        if not page_id:
            result["errors"].append("page_index contains empty page_id")
            continue

        if page_id in seen_ids:
            result["errors"].append(f"duplicate page_id in page_index: {page_id}")
            continue
        seen_ids.add(page_id)

        page_file = _safe_str(item.get("page_file_path"), f"/designs/pages/{page_id}.json")
        page_path = _resolve_path(root, page_file)

        if not page_path.exists() or not page_path.is_file():
            result["missing_page_files"].append(page_file)
            continue

        page_data, page_error = _safe_json_load_file(page_path)
        if page_error:
            result["invalid_page_files"].append(f"{page_file}: {page_error}")
            continue

        file_page_id = _normalize_id(page_data.get("page_id"), "")
        if file_page_id != page_id:
            result["inconsistent_page_ids"].append(
                {
                    "index_page_id": page_id,
                    "file_page_id": file_page_id,
                    "page_file_path": page_file,
                }
            )

    result["is_complete"] = (
        result["page_merge_index_exists"]
        and len(result["errors"]) == 0
        and len(result["missing_page_files"]) == 0
        and len(result["invalid_page_files"]) == 0
        and len(result["inconsistent_page_ids"]) == 0
        and result["page_count"] > 0
    )

    return json.dumps(result, ensure_ascii=False, indent=2)


def check_stage3_artifacts(
    project_root: Path | None = None,
) -> str:
    root = _get_workspace_root(project_root)
    nav_path = _resolve_path(root, "/designs/navigation_design.json")

    result: dict[str, Any] = {
        "stage": "stage3",
        "workspace_root": str(root),
        "exists": False,
        "is_complete": False,
        "navigation_design_exists": False,
        "entry_page_id": None,
        "page_count": 0,
        "relation_count": 0,
        "errors": [],
    }

    if not nav_path.exists() or not nav_path.is_file():
        result["errors"].append("missing /designs/navigation_design.json")
        return json.dumps(result, ensure_ascii=False, indent=2)

    result["exists"] = True
    result["navigation_design_exists"] = True

    nav_data, nav_error = _safe_json_load_file(nav_path)
    if nav_error:
        result["errors"].append(f"invalid navigation_design.json: {nav_error}")
        return json.dumps(result, ensure_ascii=False, indent=2)

    page_ids = set(_ensure_list_of_strings(nav_data.get("page_ids")))
    entry_page_id = _safe_str(nav_data.get("entry_page_id")) or None
    relations = _ensure_list(nav_data.get("relations"))

    result["entry_page_id"] = entry_page_id
    result["page_count"] = len(page_ids)
    result["relation_count"] = len(relations)

    if not entry_page_id:
        result["errors"].append("entry_page_id is missing")
    elif entry_page_id not in page_ids:
        result["errors"].append("entry_page_id not in page_ids")

    for idx, rel in enumerate(relations):
        if not isinstance(rel, dict):
            result["errors"].append(f"relation at index {idx} is not an object")
            continue

        source_page_id = _safe_str(rel.get("source_page_id"))
        target_page_id = _safe_str(rel.get("target_page_id"))

        if source_page_id and source_page_id not in page_ids:
            result["errors"].append(
                f"relation {rel.get('relation_id') or idx} source_page_id not in page_ids"
            )
        if target_page_id and target_page_id not in page_ids:
            result["errors"].append(
                f"relation {rel.get('relation_id') or idx} target_page_id not in page_ids"
            )

    result["is_complete"] = (
        result["navigation_design_exists"]
        and len(result["errors"]) == 0
        and result["page_count"] > 0
        and entry_page_id is not None
    )

    return json.dumps(result, ensure_ascii=False, indent=2)


def inspect_architect_artifacts(
    project_root: Path | None = None,
) -> str:
    stage1 = json.loads(check_stage1_artifacts(project_root))
    stage2 = json.loads(check_stage2_artifacts(project_root))
    stage3 = json.loads(check_stage3_artifacts(project_root))

    latest_completed_stage = None
    if stage3.get("is_complete"):
        latest_completed_stage = "stage3"
    elif stage2.get("is_complete"):
        latest_completed_stage = "stage2"
    elif stage1.get("is_complete"):
        latest_completed_stage = "stage1"

    result = {
        "workspace_root": stage1.get("workspace_root"),
        "latest_completed_stage": latest_completed_stage,
        "stage1": stage1,
        "stage2": stage2,
        "stage3": stage3,
    }
    return json.dumps(result, ensure_ascii=False, indent=2)