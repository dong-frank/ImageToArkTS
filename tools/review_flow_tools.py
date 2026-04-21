from __future__ import annotations

import base64
import difflib
import json
import mimetypes
import os
import re
import time
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

from langchain.tools import tool
from langchain_core.messages import HumanMessage

from models import small_model, vision_model
from tools.common import (
    PROJECT_ROOT,
    ensure_directory,
    format_cmd_result,
    is_wsl,
    projects_root,
    resolve_hdc_executable,
    resolve_workspace_path,
    run_cmd,
    to_windows_path_if_needed,
)

try:
    from PIL import Image

    PIL_AVAILABLE = True
except Exception:  # noqa: BLE001
    PIL_AVAILABLE = False

TESTER_SCRIPTS_DIR = PROJECT_ROOT / "scripts" / "tester"
IMAGE_SUFFIXES = {".png", ".jpg", ".jpeg", ".webp", ".bmp"}
ALLOWED_ACTION_TYPES = {
    "assert",
    "click",
    "navigate",
    "switch",
    "back",
    "input",
    "scroll",
    "long_press",
}


def _tester_script_path(script_name: str) -> Path:
    return TESTER_SCRIPTS_DIR / script_name


def _hdc_uses_windows_binary(hdc_executable: str) -> bool:
    lowered = str(hdc_executable or "").lower()
    if lowered.endswith(".exe"):
        return True
    return bool(is_wsl() and os.getenv("HDC_WINDOWS_EXE"))


def _adapt_local_path_for_hdc(local_path: Path | str, hdc_executable: str) -> str:
    raw = str(local_path)
    if _hdc_uses_windows_binary(hdc_executable):
        return to_windows_path_if_needed(raw)
    return raw


def _run_tester_script(script_name: str, args: List[str], timeout: int = 60, target: str = ""):
    script_path = _tester_script_path(script_name)
    if not script_path.exists():
        return run_cmd(["bash", str(script_path), *args], check=False, timeout=timeout)

    hdc_executable = resolve_hdc_executable()
    return run_cmd(
        ["bash", str(script_path), hdc_executable, str(target or ""), *[str(item) for item in args]],
        check=False,
        timeout=timeout,
    )


def _parse_hdc_targets(raw: str) -> List[str]:
    targets: List[str] = []
    for raw_line in str(raw or "").splitlines():
        line = raw_line.strip()
        if not line:
            continue
        lowered = line.lower()
        if "empty" in lowered or "no target" in lowered:
            continue
        if line.startswith("*"):
            line = line.lstrip("*").strip()
        if line:
            targets.append(line)
    return targets


def _list_hdc_targets() -> Tuple[List[str], str]:
    result = _run_tester_script("hdc_list_targets.sh", [], timeout=20)
    output = "\n".join(part for part in [result.stdout, result.stderr] if part).strip()
    if result.returncode != 0:
        return [], output
    return _parse_hdc_targets(result.stdout), output


def _pick_target_from_list(targets: List[str]) -> Tuple[str, str]:
    preferred = str(os.getenv("HDC_TARGET", "")).strip()
    if preferred:
        if preferred in targets:
            return preferred, ""
        return "", f"HDC_TARGET not found in connected targets: {preferred}"
    if not targets:
        return "", "no hdc target available"
    return targets[0], ""


def _ensure_target_ready(timeout_seconds: int = 90, poll_interval_seconds: float = 3.0, auto_start: bool = False) -> Tuple[str, str]:
    targets, raw_output = _list_hdc_targets()
    target, pick_error = _pick_target_from_list(targets)
    if target:
        return target, ""

    if not auto_start:
        return "", pick_error or f"hdc list targets output:\n{raw_output or '(empty)'}"

    start_result = _run_tester_script("start_emulator.sh", [], timeout=30)
    start_log = format_cmd_result(start_result)
    if start_result.returncode != 0:
        return "", f"auto start emulator failed\n{start_log}"

    timeout = max(10, int(timeout_seconds))
    interval = max(0.5, float(poll_interval_seconds))
    started_at = time.time()
    while time.time() - started_at <= timeout:
        targets, _ = _list_hdc_targets()
        target, pick_error = _pick_target_from_list(targets)
        if target:
            return target, ""
        time.sleep(interval)

    return "", f"emulator target not ready before timeout ({timeout}s); last_reason: {pick_error or 'unknown'}"


@tool
def ensure_emulator_ready(
    timeout_seconds: int = 90,
    poll_interval_seconds: float = 3.0,
    auto_start: bool = False,
) -> str:
    """
    Ensure at least one hdc target is available. Optionally auto-start emulator when no target exists.
    """
    print("start ensuring emulator ready")
    target, error = _ensure_target_ready(
        timeout_seconds=timeout_seconds,
        poll_interval_seconds=poll_interval_seconds,
        auto_start=bool(auto_start),
    )
    if not target:
        return "\n".join(
            [
                "status: FAILED",
                f"reason: {error or 'no available target'}",
                "hint: set HDC_TARGET to a connected target or set HARMONY_EMULATOR_START_CMD for auto-start",
            ]
        )

    targets, _ = _list_hdc_targets()
    return "\n".join(
        [
            "status: SUCCESS",
            f"selected_target: {target}",
            f"target_count: {len(targets)}",
            "targets:",
            *[f"- {item}" for item in targets],
        ]
    )

def _encode_image_as_data_url(image_path: Path) -> str:
    mime, _ = mimetypes.guess_type(str(image_path))
    if not mime:
        mime = "image/png"
    binary = image_path.read_bytes()
    b64 = base64.b64encode(binary).decode("ascii")
    return f"data:{mime};base64,{b64}"


def _extract_message_text(content: Any) -> str:
    if isinstance(content, str):
        return content.strip()
    if isinstance(content, list):
        parts: List[str] = []
        for item in content:
            if isinstance(item, str):
                parts.append(item)
                continue
            if isinstance(item, dict):
                text = item.get("text")
                if isinstance(text, str):
                    parts.append(text)
                    continue
            parts.append(str(item))
        return "\n".join(part for part in parts if part).strip()
    return str(content).strip()


def _extract_json_like_object(raw_text: str) -> Optional[Dict[str, Any]]:
    text = str(raw_text or "").strip()
    if not text:
        return None

    fenced = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", text, re.DOTALL | re.IGNORECASE)
    candidates = [fenced.group(1)] if fenced else []
    greedy = re.search(r"(\{.*\})", text, re.DOTALL)
    if greedy:
        candidates.append(greedy.group(1))

    for candidate in candidates:
        try:
            parsed = json.loads(candidate)
            if isinstance(parsed, dict):
                return parsed
        except Exception:  # noqa: BLE001
            continue
    return None


def _collect_layout_summary(node: Dict[str, Any], texts: List[str], types: Dict[str, int], max_texts: int = 20) -> None:
    attrs = node.get("attributes", {})
    node_type = str(attrs.get("type", "")).strip()
    if node_type:
        types[node_type] = types.get(node_type, 0) + 1

    text = str(attrs.get("text", "")).strip()
    if text and len(texts) < max_texts and text not in texts:
        texts.append(text)

    for child in node.get("children", []):
        if isinstance(child, dict):
            _collect_layout_summary(child, texts, types, max_texts=max_texts)


def _extract_layout_preview(layout_payload: Dict[str, Any]) -> str:
    texts: List[str] = []
    type_counter: Dict[str, int] = {}
    _collect_layout_summary(layout_payload, texts, type_counter)

    top_types = sorted(type_counter.items(), key=lambda item: item[1], reverse=True)[:12]
    lines = ["layout_preview:"]
    lines.append("visible_texts:")
    if texts:
        lines.extend(f"- {value}" for value in texts)
    else:
        lines.append("- (no visible text found)")

    lines.append("top_component_types:")
    if top_types:
        lines.extend(f"- {comp_type}: {count}" for comp_type, count in top_types)
    else:
        lines.append("- (no component type found)")
    return "\n".join(lines)


@tool
def read_description_baseline(path: str = "/user_input/description.md") -> str:
    """
    Read the product requirement baseline text for tester validation.
    """
    print("start reading description baseline")
    target_path = resolve_workspace_path(path)
    if not target_path.exists():
        return f"description_status: NOT_FOUND\npath: {target_path}"
    if not target_path.is_file():
        return f"description_status: INVALID_PATH\npath: {target_path}"
    content = target_path.read_text(encoding="utf-8", errors="ignore")
    return "\n".join(
        [
            "description_status: OK",
            f"path: {target_path}",
            "content:",
            content if content else "(empty file)",
        ]
    )


@tool
def save_tester_report(
    content: str,
    output_dir: str = "/logs/tester",
    file_name: str = "tester_report.md",
) -> str:
    """
    Save tester final output content to logs directory.
    """
    print("start save tester report")
    text = str(content or "").strip()
    if not text:
        return "status: FAILED\nreason: empty report content"

    base_dir = ensure_directory(resolve_workspace_path(output_dir))
    safe_name = Path(file_name).name or "tester_report.md"
    if not safe_name.lower().endswith((".md", ".txt", ".json")):
        safe_name = f"{safe_name}.md"

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    report_path = base_dir / f"{timestamp}_{safe_name}"
    latest_path = base_dir / (safe_name if safe_name.startswith("latest_") else f"latest_{safe_name}")
    report_path.write_text(text, encoding="utf-8")
    latest_path.write_text(text, encoding="utf-8")

    return "\n".join(
        [
            "status: SUCCESS",
            f"report_path: {report_path}",
            f"latest_report_path: {latest_path}",
            f"output_dir: {base_dir}",
        ]
    )


def _workspace_relative_display(path_value: Path) -> str:
    normalized = Path(path_value).resolve()
    marker = "/agent_workspace/sessions/"
    text = str(normalized).replace("\\", "/")
    marker_index = text.find(marker)
    if marker_index >= 0:
        tail = text[marker_index + len(marker) :]
        parts = tail.split("/", 1)
        if len(parts) == 2:
            return f"/{parts[1]}"
    return str(normalized)


def _extract_bundle_name_from_appscope(app_json_path: Path) -> str:
    if not app_json_path.exists() or not app_json_path.is_file():
        return ""
    raw = app_json_path.read_text(encoding="utf-8", errors="ignore")
    try:
        parsed = json.loads(raw)
        if isinstance(parsed, dict):
            app = parsed.get("app")
            if isinstance(app, dict):
                value = str(app.get("bundleName", "")).strip()
                if value:
                    return value
    except Exception:  # noqa: BLE001
        pass

    match = re.search(r'"bundleName"\s*:\s*"([^"]+)"', raw)
    if match:
        return match.group(1).strip()
    return ""


def _find_best_hap_under(outputs_dir: Path) -> Path | None:
    if not outputs_dir.exists() or not outputs_dir.is_dir():
        return None
    hap_files = [path for path in outputs_dir.rglob("*.hap") if path.is_file()]
    if not hap_files:
        return None

    def _score(path: Path) -> tuple[int, float]:
        name = path.name.lower()
        unsigned_bonus = 1 if "unsigned" in name else 0
        return unsigned_bonus, path.stat().st_mtime

    return sorted(hap_files, key=_score, reverse=True)[0]


def _infer_single_project_name() -> tuple[str, str]:
    root = projects_root()
    if not root.exists():
        return "", f"projects root not found: {root}"
    dirs = sorted(path for path in root.iterdir() if path.is_dir())
    if not dirs:
        return "", f"no project found under: {root}"
    if len(dirs) > 1:
        names = ", ".join(path.name for path in dirs)
        return "", f"multiple projects found, pass project_name explicitly: {names}"
    return dirs[0].name, ""


@tool
def resolve_review_target(
    project_name: str = "",
    bundle_name: str = "",
    hap_path: str = "",
) -> str:
    """
    Resolve project_name / bundle_name / hap_path for review execution.
    Default rule: bundle_name uses project_name when not provided.
    """
    print("start resolving review target")

    resolved_project = str(project_name or "").strip()
    if not resolved_project:
        inferred, infer_error = _infer_single_project_name()
        if infer_error:
            return f"status: FAILED\nreason: {infer_error}"
        resolved_project = inferred

    project_dir = projects_root() / resolved_project
    if not project_dir.exists() or not project_dir.is_dir():
        return f"status: FAILED\nreason: project not found: {project_dir}"

    outputs_dir = project_dir / "entry" / "build" / "default" / "outputs" / "default"
    resolved_hap = str(hap_path or "").strip()
    if resolved_hap:
        target_hap = resolve_workspace_path(resolved_hap)
    else:
        best = _find_best_hap_under(outputs_dir)
        if best is None:
            return (
                "status: FAILED\n"
                "reason: hap file not found under expected output directory\n"
                f"expected_dir: {outputs_dir}"
            )
        target_hap = best

    if not target_hap.exists() or not target_hap.is_file():
        return f"status: FAILED\nreason: hap file not found: {target_hap}"

    appscope_bundle = _extract_bundle_name_from_appscope(project_dir / "AppScope" / "app.json5")
    resolved_bundle = str(bundle_name or "").strip() or resolved_project

    payload = {
        "project_name": resolved_project,
        "bundle_name": resolved_bundle,
        "bundle_name_from_appscope": appscope_bundle,
        "hap_path": str(target_hap.resolve()),
        "expected_hap_dir": str(outputs_dir.resolve()),
        "project_dir": str(project_dir.resolve()),
    }
    return "\n".join(
        [
            "status: SUCCESS",
            f"project_name: {resolved_project}",
            f"bundle_name: {resolved_bundle}",
            f"bundle_name_from_appscope: {appscope_bundle or '(empty)'}",
            f"hap_path: {target_hap.resolve()}",
            f"expected_hap_dir: {outputs_dir.resolve()}",
            "resolved_json:",
            json.dumps(payload, ensure_ascii=False),
        ]
    )


def _parse_key_value_lines(raw_text: str) -> Dict[str, str]:
    values: Dict[str, str] = {}
    for raw_line in str(raw_text or "").splitlines():
        line = raw_line.strip()
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        values[key.strip()] = value.strip()
    return values


@tool
def run_review_node_with_inputs(
    project_name: str = "",
    bundle_name: str = "",
    hap_path: str = "",
    ability_name: str = "EntryAbility",
    max_depth: int = 5,
    output_root: str = "/output",
    architect_output_path: str = "/designs/architect.json",
    run_jump_compare: bool = True,
    install_hap: bool = True,
) -> str:
    """
    Execute review_node.run_review_workflow with resolved project target.
    """
    print("start running review node workflow")

    resolved_text = resolve_review_target.invoke(
        {"project_name": project_name, "bundle_name": bundle_name, "hap_path": hap_path}
    )
    if "status: FAILED" in resolved_text:
        return resolved_text

    resolved_values = _parse_key_value_lines(resolved_text)
    resolved_project_name = resolved_values.get("project_name", "").strip()
    resolved_bundle_name = resolved_values.get("bundle_name", "").strip()
    resolved_hap_path = resolved_values.get("hap_path", "").strip()
    if not resolved_bundle_name or not resolved_hap_path:
        return (
            "status: FAILED\n"
            "reason: resolve_review_target did not produce bundle_name/hap_path\n"
            f"raw_resolve_output:\n{resolved_text}"
        )

    review_output_root = resolve_workspace_path(output_root)
    architect_json_path = resolve_workspace_path(architect_output_path)

    try:
        from review_node import run_review_workflow
    except Exception as exc:  # noqa: BLE001
        return f"status: FAILED\nreason: import review_node failed\nerror: {exc}"

    try:
        result = run_review_workflow(
            hap_path=resolved_hap_path,
            bundle_name_value=resolved_bundle_name,
            ability_name_value=str(ability_name or "").strip() or "EntryAbility",
            max_depth=max_depth,
            output_root=str(review_output_root),
            architect_output_path=str(architect_json_path),
            run_jump_compare=bool(run_jump_compare),
            install_hap=bool(install_hap),
        )
    except Exception as exc:  # noqa: BLE001
        return (
            "status: FAILED\n"
            "reason: run_review_workflow execution failed\n"
            f"project_name: {resolved_project_name}\n"
            f"bundle_name: {resolved_bundle_name}\n"
            f"hap_path: {resolved_hap_path}\n"
            f"error: {exc}"
        )

    output_dir = Path(str(result.get("output_dir", "")).strip()) if isinstance(result, dict) else None
    report_path = Path(str(result.get("report_path", "")).strip()) if isinstance(result, dict) else None
    detailed_path = Path(str(result.get("review_detailed_output_path", "")).strip()) if isinstance(result, dict) else None

    output_display = _workspace_relative_display(output_dir) if output_dir else ""
    report_display = _workspace_relative_display(report_path) if report_path else ""
    detailed_display = _workspace_relative_display(detailed_path) if detailed_path else ""

    payload = result if isinstance(result, dict) else {"status": "UNKNOWN"}
    return "\n".join(
        [
            f"status: {payload.get('status', 'UNKNOWN')}",
            f"project_name: {resolved_project_name}",
            f"bundle_name: {resolved_bundle_name}",
            f"ability_name: {payload.get('ability_name', ability_name)}",
            f"hap_path: {resolved_hap_path}",
            f"output_dir: {payload.get('output_dir', '')}",
            f"output_dir_rel: {output_display}",
            f"report_path: {payload.get('report_path', '')}",
            f"report_path_rel: {report_display}",
            f"review_detailed_output_path: {payload.get('review_detailed_output_path', '')}",
            f"review_detailed_output_path_rel: {detailed_display}",
            f"jump_transition_candidates_path: {payload.get('jump_transition_candidates_path', '')}",
            f"jump_action_diff_path: {payload.get('jump_action_diff_path', '')}",
            f"jump_action_summary_path: {payload.get('jump_action_summary_path', '')}",
            "result_json:",
            json.dumps(payload, ensure_ascii=False),
        ]
    )


def _safe_load_json_path(path: Path) -> Optional[Dict[str, Any]]:
    if not path.exists() or not path.is_file():
        return None
    try:
        data = json.loads(path.read_text(encoding="utf-8", errors="ignore"))
        if isinstance(data, dict):
            return data
    except Exception:  # noqa: BLE001
        return None
    return None


def _split_lines_for_cases(text: str) -> List[str]:
    lines = []
    for raw in str(text or "").splitlines():
        line = raw.strip()
        if not line:
            continue
        line = re.sub(r"^[\-\*\d\.\)\(、\s]+", "", line).strip()
        if line:
            lines.append(line)
    return lines


def _pick_expected_keywords(text: str) -> List[str]:
    chunks = re.split(r"[，,。；;、\s]+", str(text or ""))
    keywords = []
    for item in chunks:
        t = item.strip()
        if len(t) < 2:
            continue
        if t in {"点击", "进入", "切换", "页面", "按钮", "返回"}:
            continue
        keywords.append(t)
    unique = []
    seen = set()
    for k in keywords:
        if k not in seen:
            seen.add(k)
            unique.append(k)
    return unique[:6]


def _extract_description_points(text: str) -> List[Dict[str, Any]]:
    lines = _split_lines_for_cases(text)
    points: List[Dict[str, Any]] = []
    for idx, line in enumerate(lines, start=1):
        lowered = line.lower()
        action_type = "assert"
        if "点击" in line or "click" in lowered:
            action_type = "click"
        elif "进入" in line or "打开" in line or "open" in lowered:
            action_type = "navigate"
        elif "切换" in line or "switch" in lowered:
            action_type = "switch"
        elif "返回" in line or "back" in lowered:
            action_type = "back"

        points.append(
            {
                "id": f"DESC_{idx:03d}",
                "source": "description",
                "action_type": action_type,
                "description": line,
                "expected_keywords": _pick_expected_keywords(line),
            }
        )
    return points


def _normalize_action_type(raw: str) -> str:
    value = str(raw or "").strip().lower()
    if value in ALLOWED_ACTION_TYPES:
        return value
    return "assert"


def _normalize_expected_keywords(raw: Any) -> List[str]:
    tokens: List[str] = []
    if isinstance(raw, list):
        tokens = [str(item).strip() for item in raw if str(item).strip()]
    elif isinstance(raw, str):
        tokens = [part.strip() for part in re.split(r"[ï¼Œ,ã€‚ï¼›;ã€\s]+", raw) if part.strip()]

    unique: List[str] = []
    seen = set()
    for token in tokens:
        if len(token) < 2:
            continue
        if token in {"ç‚¹å‡»", "è¿›å…¥", "åˆ‡æ¢", "é¡µé¢", "æŒ‰é’®", "è¿”å›ž"}:
            continue
        if token in seen:
            continue
        seen.add(token)
        unique.append(token)
        if len(unique) >= 6:
            break
    return unique


def _extract_description_points_with_small_model(text: str) -> Tuple[List[Dict[str, Any]], str]:
    source_text = str(text or "").strip()
    if not source_text:
        return [], "empty_description"

    max_chars = 12000
    truncated = len(source_text) > max_chars
    user_text = source_text[:max_chars]

    prompt = (
        "你是一个测试用例提取器。\n"
        "请从以下产品描述中提取待测试功能点，并严格按序号列表输出，绝对不要输出任何前言、总结或解释性文字。\n"
        "输出格式示例：\n"
        "1. 验证用户登录功能\n"
        "2. 检查密码输入错误时的提示\n"
        "要求：\n"
        "1) 描述必须简洁具体；\n"
        "2) 不能虚构内容，只能基于输入的产品描述进行提取。\n\n"
        f"产品描述：\n{user_text}"
    )

    try:
        response = small_model.invoke([HumanMessage(content=prompt)])
    except Exception as exc:  # noqa: BLE001
        return [], f"small_model_error: {exc}"

    raw_text = _extract_message_text(getattr(response, "content", ""))
    parsed = _extract_json_like_object(raw_text)
    if parsed is None:
        try:
            direct = json.loads(raw_text)
            parsed = direct if isinstance(direct, dict) else None
        except Exception:  # noqa: BLE001
            parsed = None

    if not isinstance(parsed, dict):
        return [], "small_model_invalid_json"

    raw_items = parsed.get("items")
    if not isinstance(raw_items, list):
        return [], "small_model_missing_items"

    points: List[Dict[str, Any]] = []
    for idx, item in enumerate(raw_items, start=1):
        if not isinstance(item, dict):
            continue

        description = str(item.get("description", "")).strip()
        if not description:
            continue

        action_type = _normalize_action_type(str(item.get("action_type", "")))
        expected_keywords = _normalize_expected_keywords(item.get("expected_keywords", []))
        if not expected_keywords:
            expected_keywords = _pick_expected_keywords(description)

        points.append(
            {
                "id": f"DESC_{idx:03d}",
                "source": "description",
                "action_type": action_type,
                "description": description,
                "expected_keywords": expected_keywords,
            }
        )

    if not points:
        return [], "small_model_empty_items"

    extractor = "small_model"
    if truncated:
        extractor = "small_model_truncated_input"
    return points, extractor


def _extract_primary_user_input_text(desc_text: str) -> str:
    marker = "以下是用户在主聊天框中的本次输入："
    raw = str(desc_text or "")
    idx = raw.find(marker)
    if idx < 0:
        return raw
    return raw[idx + len(marker) :].strip()


def _extract_primary_user_input_text_v2(desc_text: str) -> str:
    raw = str(desc_text or "")
    markers = [
        "以下是用户在主聊天框中的本次输入：",
        "以下是用户在主聊天框中的本次输入:",
        "main chat input:",
    ]
    for marker in markers:
        idx = raw.find(marker)
        if idx >= 0:
            return raw[idx + len(marker) :].strip()
    return raw.strip()


def _extract_balanced_json_object_v2(raw_text: str, start_idx: int) -> str:
    if start_idx < 0 or start_idx >= len(raw_text) or raw_text[start_idx] != "{":
        return ""

    depth = 0
    in_string = False
    escaped = False
    for index in range(start_idx, len(raw_text)):
        char = raw_text[index]
        if in_string:
            if escaped:
                escaped = False
                continue
            if char == "\\":
                escaped = True
                continue
            if char == '"':
                in_string = False
            continue

        if char == '"':
            in_string = True
            continue
        if char == "{":
            depth += 1
            continue
        if char == "}":
            depth -= 1
            if depth == 0:
                return raw_text[start_idx : index + 1]
    return ""


def _extract_user_input_metadata_v2(desc_text: str) -> Tuple[Optional[Dict[str, Any]], str]:
    raw = str(desc_text or "")
    marker_match = re.search(r"user_input_metadata\.json\s*[:：]", raw, re.IGNORECASE)
    if not marker_match:
        return None, "metadata_marker_not_found"

    brace_index = raw.find("{", marker_match.end())
    if brace_index < 0:
        return None, "metadata_json_not_found"

    json_text = _extract_balanced_json_object_v2(raw, brace_index)
    if not json_text:
        return None, "metadata_json_unbalanced"

    try:
        payload = json.loads(json_text)
    except Exception as exc:  # noqa: BLE001
        return None, f"metadata_json_parse_failed: {exc}"

    if not isinstance(payload, dict):
        return None, "metadata_json_not_object"
    return payload, "metadata_ok"


def _normalize_page_name_v2(raw: str, fallback: str) -> str:
    token = str(raw or "").strip().lower()
    token = re.sub(r"[^a-zA-Z0-9]+", "_", token)
    token = re.sub(r"_+", "_", token).strip("_")
    if token:
        return token
    return fallback


def _guess_action_type_v2(description: str) -> str:
    lowered = str(description or "").lower()
    if any(token in lowered for token in ["click", "tap", "press", "点击"]):
        return "click"
    if any(token in lowered for token in ["navigate", "open", "enter", "进入", "打开"]):
        return "navigate"
    if "switch" in lowered or "切换" in lowered:
        return "switch"
    if "back" in lowered or "返回" in lowered:
        return "back"
    return "assert"


def _extract_metadata_points_v2(metadata_payload: Optional[Dict[str, Any]]) -> Tuple[List[Dict[str, Any]], List[Dict[str, Any]]]:
    if not isinstance(metadata_payload, dict):
        return [], []

    files = metadata_payload.get("files")
    if not isinstance(files, dict):
        return [], []

    metadata_cases: List[Dict[str, Any]] = []
    expected_pages: List[Dict[str, Any]] = []
    page_index = 0
    case_index = 0

    for file_key, file_value in files.items():
        if not isinstance(file_value, dict):
            continue

        file_name = str(file_value.get("name") or file_key or "").strip()
        raw_path = str(file_value.get("path") or "").strip()
        content_type = str(file_value.get("content_type") or "").strip().lower()
        description = str(file_value.get("description") or "").strip()
        fallback_path = f"/user_input/{file_name}" if file_name else ""
        reference_path = raw_path or fallback_path
        suffix = Path(file_name or reference_path).suffix.lower()
        is_image = suffix in IMAGE_SUFFIXES or content_type.startswith("image/")

        if description:
            case_index += 1
            metadata_cases.append(
                {
                    "id": f"META_{case_index:03d}",
                    "source": "metadata_description",
                    "action_type": _guess_action_type_v2(description),
                    "description": description,
                    "expected_keywords": _pick_expected_keywords(description),
                    "file_name": file_name,
                    "reference_image_path": reference_path if is_image else "",
                }
            )

        if not is_image:
            continue

        page_index += 1
        page_stem = Path(file_name or f"page_{page_index}").stem
        page_name = _normalize_page_name_v2(page_stem, f"page_{page_index:03d}")
        page_keywords = _pick_expected_keywords(f"{page_name} {description}".strip())
        if not page_keywords:
            page_keywords = [page_name]

        expected_pages.append(
            {
                "id": f"PAGE_{page_index:03d}",
                "source": "metadata_image",
                "page_name": page_name,
                "file_name": file_name,
                "reference_image_path": reference_path,
                "description": description,
                "expected_keywords": page_keywords,
            }
        )

    return metadata_cases, expected_pages


def _deduplicate_cases_v2(cases: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    merged: List[Dict[str, Any]] = []
    seen = set()
    for case in cases:
        description = str(case.get("description") or "").strip().lower()
        action_type = str(case.get("action_type") or "assert").strip().lower()
        source = str(case.get("source") or "").strip().lower()
        if not description:
            continue
        key = (description, action_type, source)
        if key in seen:
            continue
        seen.add(key)
        merged.append(case)
    return merged


def _deduplicate_pages_v2(pages: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    merged: List[Dict[str, Any]] = []
    seen = set()
    for page in pages:
        page_name = str(page.get("page_name") or "").strip().lower()
        reference_image_path = str(page.get("reference_image_path") or "").strip().lower()
        if not page_name and not reference_image_path:
            continue
        key = (page_name, reference_image_path)
        if key in seen:
            continue
        seen.add(key)
        merged.append(page)
    return merged


def _compose_test_plan_seed_text_v2(
    raw_description_text: str,
    primary_user_text: str,
    metadata_payload: Optional[Dict[str, Any]],
) -> str:
    chunks: List[str] = []
    if primary_user_text.strip():
        chunks.append(primary_user_text.strip())

    files = metadata_payload.get("files") if isinstance(metadata_payload, dict) else None
    if isinstance(files, dict):
        for file_key, file_value in files.items():
            if not isinstance(file_value, dict):
                continue
            name = str(file_value.get("name") or file_key or "").strip()
            description = str(file_value.get("description") or "").strip()
            if description:
                chunks.append(f"[file={name}] {description}")

    if not chunks and raw_description_text.strip():
        chunks.append(raw_description_text.strip())
    return "\n".join(chunks)


@tool
def build_test_plan_from_inputs(
    description_path: str = "/user_input/description.md",
) -> str:
    """
    Build test plan from description.md only.
    """
    print("start building test plan from description")
    desc_path = resolve_workspace_path(description_path)
    desc_text = desc_path.read_text(encoding="utf-8", errors="ignore") if desc_path.exists() and desc_path.is_file() else ""
    primary_user_text = _extract_primary_user_input_text_v2(desc_text)
    metadata_payload, metadata_status = _extract_user_input_metadata_v2(desc_text)
    metadata_cases, expected_pages_from_metadata = _extract_metadata_points_v2(metadata_payload)
    plan_seed_text = _compose_test_plan_seed_text_v2(
        raw_description_text=desc_text,
        primary_user_text=primary_user_text,
        metadata_payload=metadata_payload,
    )

    description_points, extractor = _extract_description_points_with_small_model(plan_seed_text)
    if not description_points:
        description_points = _extract_description_points(plan_seed_text)
        extractor = "rule_fallback"

    merged_case_items = _deduplicate_cases_v2([*metadata_cases, *description_points])
    expected_pages = _deduplicate_pages_v2(expected_pages_from_metadata)

    if not expected_pages and merged_case_items:
        expected_pages = [
            {
                "id": "PAGE_001",
                "source": "fallback_inference",
                "page_name": "main_page",
                "file_name": "",
                "reference_image_path": "",
                "description": "No reference page image found in description metadata.",
                "expected_keywords": _pick_expected_keywords(primary_user_text) or ["main"],
            }
        ]

    for case_idx, case_item in enumerate(merged_case_items, start=1):
        case_item["id"] = f"CASE_{case_idx:03d}"

    merged_cases: List[Dict[str, Any]] = []
    for item in merged_case_items:
        merged_cases.append(
            {
                "id": item.get("id"),
                "source": item.get("source"),
                "category": "metadata_case" if str(item.get("source")) == "metadata_description" else "description_case",
                "description": item.get("description", ""),
                "action_type": item.get("action_type", ""),
                "expected_keywords": item.get("expected_keywords", []),
                "reference_image_path": item.get("reference_image_path", ""),
                "file_name": item.get("file_name", ""),
            }
        )

    payload = {
        "description_path": str(desc_path),
        "description_available": bool(plan_seed_text.strip()),
        "raw_description_available": bool(desc_text.strip()),
        "primary_user_input_available": bool(primary_user_text.strip()),
        "metadata_available": bool(metadata_payload),
        "metadata_status": metadata_status,
        "extractor": extractor,
        "description_items": description_points,
        "metadata_items": metadata_cases,
        "merged_cases": merged_cases,
        "expected_pages": expected_pages,
        "coverage_targets": {
            "expected_case_count": len(merged_cases),
            "expected_page_count": len(expected_pages),
        },
    }
    return "\n".join(
        [
            "status: SUCCESS",
            f"description_available: {payload['description_available']}",
            f"metadata_available: {payload['metadata_available']}",
            f"extractor: {payload['extractor']}",
            f"merged_case_count: {len(merged_cases)}",
            f"expected_page_count: {len(expected_pages)}",
            "plan_json:",
            json.dumps(payload, ensure_ascii=False),
        ]
    )


@tool
def install_harmony_app(
    project_name: str,
    hap_path: str = "",
    reinstall: bool = True,
    uninstall_first: bool = False,
) -> str:
    """
    Install HarmonyOS hap to device for a given project.
    - If hap_path is empty, auto-discover newest .hap under /projects/<project_name>.
    """
    print("start installing harmony app to device")
    selected_target, target_error = _ensure_target_ready()
    if not selected_target:
        return f"status: FAILED\nreason: {target_error}"

    name = str(project_name or "").strip()
    if not name:
        return "status: FAILED\nreason: project_name is required"

    project_dir = projects_root() / name
    if not project_dir.exists() or not project_dir.is_dir():
        return f"status: FAILED\nreason: project directory not found: /projects/{name}"

    if hap_path:
        selected_hap = resolve_workspace_path(hap_path)
    else:
        candidates = [path for path in project_dir.rglob("*.hap") if path.is_file()]
        if not candidates:
            return "\n".join(
                [
                    "status: FAILED",
                    "reason: no .hap found under project directory",
                    f"project_path: /projects/{name}",
                    "hint: compile project first and ensure signed hap is generated",
                ]
            )

        def _candidate_score(path: Path) -> Tuple[int, float]:
            lowered = str(path).lower()
            signed_score = 1 if "signed" in lowered else 0
            return signed_score, path.stat().st_mtime

        candidates.sort(key=_candidate_score, reverse=True)
        selected_hap = candidates[0]

    if not selected_hap.exists() or not selected_hap.is_file():
        return "\n".join(
            [
                "status: FAILED",
                f"reason: hap file not found: {selected_hap}",
                f"project_path: /projects/{name}",
            ]
        )

    app_json_path = project_dir / "AppScope" / "app.json5"
    bundle_name = ""
    app_payload = _safe_load_json_path(app_json_path)
    if app_payload:
        bundle_name = str((app_payload.get("app", {}) or {}).get("bundleName", "")).strip()

    hdc_executable = resolve_hdc_executable()
    selected_hap_for_hdc = _adapt_local_path_for_hdc(selected_hap, hdc_executable)

    uninstall_result = None
    if uninstall_first and bundle_name:
        uninstall_result = _run_tester_script("hdc_uninstall.sh", [bundle_name], timeout=60, target=selected_target)

    install_result = _run_tester_script(
        "hdc_install_hap.sh",
        [selected_hap_for_hdc, "1" if reinstall else "0"],
        timeout=180,
        target=selected_target,
    )

    status = "SUCCESS" if install_result.returncode == 0 else "FAILED"
    lines = [
        f"status: {status}",
        f"project_name: {name}",
        f"project_path: /projects/{name}",
        f"hap_path: {selected_hap}",
        f"bundle_name: {bundle_name or '(unknown)'}",
        f"target: {selected_target}",
        f"reinstall: {bool(reinstall)}",
        f"uninstall_first: {bool(uninstall_first)}",
    ]
    if uninstall_result is not None:
        lines.extend(
            [
                "uninstall_result:",
                format_cmd_result(uninstall_result),
            ]
        )
    lines.extend(
        [
            "install_result:",
            format_cmd_result(install_result),
        ]
    )
    return "\n".join(lines)


@tool
def start_harmony_app(bundle_name: str, ability_name: str) -> str:
    """
    Force-stop and then start a HarmonyOS app by bundle and ability name.
    """
    print("start starting harmony app on device")
    selected_target, target_error = _ensure_target_ready()
    if not selected_target:
        return f"status: FAILED\nreason: {target_error}"

    bundle = str(bundle_name or "").strip()
    ability = str(ability_name or "").strip()
    if not bundle or not ability:
        return "status: FAILED\nreason: bundle_name and ability_name are required"

    stop_result = _run_tester_script("hdc_force_stop_app.sh", [bundle], timeout=30, target=selected_target)
    time.sleep(1)
    start_result = _run_tester_script("hdc_start_app.sh", [bundle, ability], timeout=30, target=selected_target)
    time.sleep(3)

    status = "SUCCESS" if start_result.returncode == 0 else "FAILED"
    return "\n".join(
        [
            f"status: {status}",
            f"bundle_name: {bundle}",
            f"ability_name: {ability}",
            f"target: {selected_target}",
            "force_stop:",
            format_cmd_result(stop_result),
            "start_result:",
            format_cmd_result(start_result),
        ]
    )


@tool
def capture_app_screenshot(
    file_name: str = "app_screen.jpeg",
    output_dir: str = "/logs/tester",
    max_retries: int = 3,
) -> str:
    """
    Capture a current device screenshot with hdc and save to tester logs.
    """
    print("start capturing app screenshot from device")
    selected_target, target_error = _ensure_target_ready()
    if not selected_target:
        return f"status: FAILED\nreason: {target_error}"

    base_dir = ensure_directory(resolve_workspace_path(output_dir))
    safe_name = Path(file_name).name or "app_screen.jpeg"
    if not safe_name.lower().endswith((".jpg", ".jpeg", ".png")):
        safe_name = f"{safe_name}.jpeg"
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    local_path = base_dir / f"{timestamp}_{safe_name}"
    remote_jpeg = "/data/local/tmp/screen.jpeg"

    retries = max(1, int(max_retries))
    attempt_logs: List[str] = []
    hdc_executable = resolve_hdc_executable()
    local_path_for_hdc = _adapt_local_path_for_hdc(local_path, hdc_executable)

    for attempt in range(1, retries + 1):
        _run_tester_script("hdc_rm_remote_file.sh", [remote_jpeg], timeout=15, target=selected_target)
        screenshot_result = _run_tester_script(
            "hdc_snapshot_display.sh",
            [remote_jpeg],
            timeout=30,
            target=selected_target,
        )
        recv_result = _run_tester_script(
            "hdc_recv_file.sh",
            [remote_jpeg, local_path_for_hdc],
            timeout=30,
            target=selected_target,
        )
        attempt_logs.append(
            "\n".join(
                [
                    f"attempt: {attempt}/{retries}",
                    "snapshot_cmd:",
                    format_cmd_result(screenshot_result),
                    "recv_cmd:",
                    format_cmd_result(recv_result),
                ]
            )
        )
        if (
            screenshot_result.returncode == 0
            and recv_result.returncode == 0
            and local_path.exists()
            and local_path.stat().st_size > 0
        ):
            return "\n".join(
                [
                    "status: SUCCESS",
                    f"screenshot_path: {local_path}",
                    f"target: {selected_target}",
                    "attempt_logs:",
                    "\n\n".join(attempt_logs),
                ]
            )
        time.sleep(1)

    return "\n".join(
        [
            "status: FAILED",
            f"target_path: {local_path}",
            "attempt_logs:",
            "\n\n".join(attempt_logs) if attempt_logs else "(no attempts recorded)",
        ]
    )


@tool
def dump_app_layout(file_name: str = "layout.json", output_dir: str = "/logs/tester") -> str:
    """
    Dump the current app UI layout via hdc uitest and save as formatted JSON.
    """
    print("start dumping app layout")
    selected_target, target_error = _ensure_target_ready()
    if not selected_target:
        return f"status: FAILED\nreason: {target_error}"

    base_dir = ensure_directory(resolve_workspace_path(output_dir))
    safe_name = Path(file_name).name or "layout.json"
    if not safe_name.lower().endswith(".json"):
        safe_name = f"{safe_name}.json"
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    local_path = base_dir / f"{timestamp}_{safe_name}"
    remote_layout = "/data/local/tmp/layout.json"

    hdc_executable = resolve_hdc_executable()
    local_path_for_hdc = _adapt_local_path_for_hdc(local_path, hdc_executable)

    dump_result = _run_tester_script("hdc_dump_layout.sh", [remote_layout], timeout=45, target=selected_target)
    recv_result = _run_tester_script(
        "hdc_recv_file.sh",
        [remote_layout, local_path_for_hdc],
        timeout=45,
        target=selected_target,
    )
    if dump_result.returncode != 0 or recv_result.returncode != 0 or not local_path.exists():
        return "\n".join(
            [
                "status: FAILED",
                f"layout_path: {local_path}",
                "dump_cmd:",
                format_cmd_result(dump_result),
                "recv_cmd:",
                format_cmd_result(recv_result),
            ]
        )

    try:
        payload = json.loads(local_path.read_text(encoding="utf-8", errors="ignore"))
        local_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    except Exception as exc:  # noqa: BLE001
        return "\n".join(
            [
                "status: PARTIAL_SUCCESS",
                f"layout_path: {local_path}",
                f"reason: layout json parse failed: {exc}",
            ]
        )

    return "\n".join(
        [
                "status: SUCCESS",
                f"layout_path: {local_path}",
                f"target: {selected_target}",
                _extract_layout_preview(payload),
            ]
        )


@tool
def collect_reference_and_runtime_screenshots(
    reference_dir: str = "/user_input",
    runtime_dir: str = "/logs",
) -> str:
    """
    Collect reference screenshots from user input and runtime screenshots from logs.
    """
    print("start collecting reference and runtime screenshots")
    ref_root = resolve_workspace_path(reference_dir)
    runtime_root = resolve_workspace_path(runtime_dir)

    def _collect_images(root: Path) -> List[Path]:
        if not root.exists():
            return []
        return sorted(
            [
                path
                for path in root.rglob("*")
                if path.is_file() and path.suffix.lower() in IMAGE_SUFFIXES
            ]
        )

    refs = _collect_images(ref_root)
    runtime = _collect_images(runtime_root)

    lines = [
        f"reference_dir: {ref_root}",
        f"runtime_dir: {runtime_root}",
        f"reference_image_count: {len(refs)}",
    ]
    if refs:
        lines.extend(f"- {path}" for path in refs[:100])
    else:
        lines.append("- (none)")

    lines.append(f"runtime_image_count: {len(runtime)}")
    if runtime:
        lines.extend(f"- {path}" for path in runtime[:200])
    else:
        lines.append("- (none)")

    return "\n".join(lines)


def _collect_images_under(root: Path) -> List[Path]:
    if not root.exists():
        return []
    return sorted(
        [
            path
            for path in root.rglob("*")
            if path.is_file() and path.suffix.lower() in IMAGE_SUFFIXES
        ]
    )


def _extract_plan_payload(plan_json: str) -> Optional[Dict[str, Any]]:
    text = str(plan_json or "").strip()
    if not text:
        return None

    if "plan_json:" in text:
        text = text.split("plan_json:", 1)[1].strip()

    parsed = _extract_json_like_object(text)
    if parsed is None:
        try:
            raw = json.loads(text)
            parsed = raw if isinstance(raw, dict) else None
        except Exception:  # noqa: BLE001
            parsed = None
    return parsed if isinstance(parsed, dict) else None


def _normalize_match_key(raw: str) -> str:
    return re.sub(r"[^a-z0-9]+", "", str(raw or "").lower())


def _score_path_match(page_name: str, reference_path: Path, runtime_path: Path) -> float:
    page_key = _normalize_match_key(page_name)
    ref_key = _normalize_match_key(reference_path.stem)
    run_key = _normalize_match_key(runtime_path.stem)
    a = page_key or ref_key
    b = run_key
    return difflib.SequenceMatcher(None, a, b).ratio()


def _image_ahash_bits(image_path: Path, size: int = 16) -> Optional[List[int]]:
    if not PIL_AVAILABLE:
        return None
    try:
        with Image.open(image_path) as image:
            grayscale = image.convert("L").resize((size, size))
            pixels = list(grayscale.getdata())
    except Exception:  # noqa: BLE001
        return None

    if not pixels:
        return None
    avg = sum(pixels) / len(pixels)
    return [1 if pixel >= avg else 0 for pixel in pixels]


def _image_similarity_score(reference_path: Path, runtime_path: Path) -> Optional[float]:
    bits_a = _image_ahash_bits(reference_path)
    bits_b = _image_ahash_bits(runtime_path)
    if not bits_a or not bits_b or len(bits_a) != len(bits_b):
        return None
    distance = sum(1 for left, right in zip(bits_a, bits_b) if left != right)
    return 1.0 - (distance / len(bits_a))


def _pair_similarity_score(
    page_name: str,
    reference_path: Path,
    runtime_path: Path,
    path_weight: float = 0.35,
    image_weight: float = 0.65,
) -> Dict[str, float]:
    path_similarity = _score_path_match(page_name=page_name, reference_path=reference_path, runtime_path=runtime_path)
    image_similarity = _image_similarity_score(reference_path, runtime_path)
    if image_similarity is None:
        image_similarity = path_similarity
    combined = (path_similarity * float(path_weight)) + (image_similarity * float(image_weight))
    return {
        "path_similarity": round(path_similarity, 3),
        "image_similarity": round(image_similarity, 3),
        "combined_similarity": round(combined, 3),
    }


@tool
def pair_reference_pages_with_runtime(
    plan_json: str = "",
    reference_dir: str = "/user_input",
    runtime_dir: str = "/logs",
    output_dir: str = "/logs/tester",
    min_similarity: float = 0.35,
) -> str:
    """
    Pair expected reference pages with runtime screenshots for later UI comparison.
    """
    print("start pairing reference pages with runtime screenshots")
    ref_root = resolve_workspace_path(reference_dir)
    runtime_root = resolve_workspace_path(runtime_dir)
    refs = _collect_images_under(ref_root)
    runtime = _collect_images_under(runtime_root)
    plan_payload = _extract_plan_payload(plan_json)

    expected_pages_raw = plan_payload.get("expected_pages", []) if isinstance(plan_payload, dict) else []
    expected_pages: List[Dict[str, Any]] = []
    if isinstance(expected_pages_raw, list):
        for idx, item in enumerate(expected_pages_raw, start=1):
            if not isinstance(item, dict):
                continue
            page_name = str(item.get("page_name") or "").strip()
            reference_image_path = str(item.get("reference_image_path") or "").strip()
            expected_pages.append(
                {
                    "id": str(item.get("id") or f"PAGE_{idx:03d}"),
                    "page_name": page_name or f"page_{idx:03d}",
                    "reference_image_path": reference_image_path,
                }
            )

    if not expected_pages:
        for idx, path in enumerate(refs, start=1):
            expected_pages.append(
                {
                    "id": f"PAGE_{idx:03d}",
                    "page_name": _normalize_page_name_v2(path.stem, f"page_{idx:03d}"),
                    "reference_image_path": str(path),
                }
            )

    used_runtime: set[str] = set()
    pairs: List[Dict[str, Any]] = []
    unmatched_pages: List[Dict[str, Any]] = []

    for page in expected_pages:
        page_name = str(page.get("page_name") or "").strip()
        reference_image_path = str(page.get("reference_image_path") or "").strip()
        reference_path: Optional[Path] = None
        if reference_image_path:
            resolved = resolve_workspace_path(reference_image_path)
            if resolved.exists() and resolved.is_file():
                reference_path = resolved

        if reference_path is None and refs:
            best_ref = max(
                refs,
                key=lambda candidate: difflib.SequenceMatcher(
                    None,
                    _normalize_match_key(page_name),
                    _normalize_match_key(candidate.stem),
                ).ratio(),
            )
            reference_path = best_ref

        if reference_path is None:
            unmatched_pages.append(
                {
                    "page_name": page_name,
                    "reason": "reference_not_found",
                    "reference_image_path": reference_image_path,
                }
            )
            continue

        best_runtime: Optional[Path] = None
        best_pair_scores: Dict[str, float] = {}
        best_score = -1.0
        for runtime_path in runtime:
            key = str(runtime_path)
            if key in used_runtime:
                continue
            score_payload = _pair_similarity_score(
                page_name=page_name,
                reference_path=reference_path,
                runtime_path=runtime_path,
            )
            score = score_payload["combined_similarity"]
            if score > best_score:
                best_score = score
                best_runtime = runtime_path
                best_pair_scores = score_payload

        if best_runtime is None or best_score < float(min_similarity):
            unmatched_pages.append(
                {
                    "page_name": page_name,
                    "reason": "runtime_not_matched",
                    "reference_image_path": str(reference_path),
                    "best_score": round(best_score, 3) if best_score >= 0 else None,
                    "best_pair_scores": best_pair_scores,
                }
            )
            continue

        used_runtime.add(str(best_runtime))
        pairs.append(
            {
                "page_name": page_name,
                "reference_image_path": str(reference_path),
                "runtime_image_path": str(best_runtime),
                "score": round(best_score, 3),
                "path_similarity": best_pair_scores.get("path_similarity"),
                "image_similarity": best_pair_scores.get("image_similarity"),
            }
        )

    unmatched_runtime = [str(path) for path in runtime if str(path) not in used_runtime]
    payload = {
        "reference_dir": str(ref_root),
        "runtime_dir": str(runtime_root),
        "pair_count": len(pairs),
        "expected_page_count": len(expected_pages),
        "unmatched_page_count": len(unmatched_pages),
        "unmatched_runtime_count": len(unmatched_runtime),
        "pairs": pairs,
        "unmatched_pages": unmatched_pages,
        "unmatched_runtime_images": unmatched_runtime,
    }

    out_dir = ensure_directory(resolve_workspace_path(output_dir))
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    pair_path = out_dir / f"{ts}_page_pairs.json"
    pair_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")

    return "\n".join(
        [
            "status: SUCCESS",
            f"pair_path: {pair_path}",
            f"expected_page_count: {len(expected_pages)}",
            f"pair_count: {len(pairs)}",
            f"unmatched_page_count: {len(unmatched_pages)}",
            f"unmatched_runtime_count: {len(unmatched_runtime)}",
            "pair_json:",
            json.dumps(payload, ensure_ascii=False),
        ]
    )


@tool
def compare_ui_pair_with_mini_agent(
    reference_image_path: str,
    runtime_image_path: str,
    page_name: str = "",
    output_dir: str = "/logs/tester/ui_compare",
) -> str:
    """
    Compare one reference image and one runtime screenshot with a dedicated
    vision mini-agent prompt, and return similarities / differences.
    """
    print("start comparing ui images with mini agent")
    ref_path = resolve_workspace_path(reference_image_path)
    run_path = resolve_workspace_path(runtime_image_path)

    if not ref_path.exists() or not ref_path.is_file():
        return f"status: FAILED\nreason: reference image not found\nreference_image_path: {ref_path}"
    if not run_path.exists() or not run_path.is_file():
        return f"status: FAILED\nreason: runtime image not found\nruntime_image_path: {run_path}"

    try:
        ref_data_url = _encode_image_as_data_url(ref_path)
        run_data_url = _encode_image_as_data_url(run_path)
    except Exception as exc:  # noqa: BLE001
        return f"status: FAILED\nreason: encode image failed: {exc}"

    compare_prompt = (
        "你是移动端 UI 快速验收助手。"
        "只判断是否“大致相似”，不要做像素级或过度细节分析。"
        "判定标准：\n"
        "1) 页面主结构是否一致（头部/主体/底部、主要分区）。\n"
        "2) 关键组件是否存在（核心按钮、输入区、列表/卡片）。\n"
        "3) 主要文案语义是否一致。\n"
        "4) 忽略状态栏信息。\n"
        "可忽略：小间距、小字号差异、轻微颜色偏差、圆角细节。\n"
        "输出严格 JSON："
        '{"overall":"PASS|FAIL","similarity_score":0-100,'
        '"similarities":["..."],'
        '"differences":[{"item":"...","impact":"high|medium|low","category":"layout|component|text|style"}],'
        '"summary":"..."}'
        "当 similarity_score >= 70 时给 PASS，否则 FAIL。"
    )

    try:
        response = vision_model.invoke(
            [
                HumanMessage(
                    content=[
                        {"type": "text", "text": compare_prompt},
                        {"type": "image_url", "image_url": {"url": ref_data_url}},
                        {"type": "image_url", "image_url": {"url": run_data_url}},
                    ]
                )
            ]
        )
    except Exception as exc:  # noqa: BLE001
        return (
            "status: FAILED\n"
            "reason: mini agent compare request failed\n"
            f"error: {exc}\n"
            f"reference_image_path: {ref_path}\n"
            f"runtime_image_path: {run_path}"
        )

    raw_text = _extract_message_text(getattr(response, "content", ""))
    parsed = _extract_json_like_object(raw_text)

    out_dir = ensure_directory(resolve_workspace_path(output_dir))
    safe_page = re.sub(r"[^a-zA-Z0-9_-]+", "_", page_name.strip()) or "page"
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    analysis_path = out_dir / f"{ts}_{safe_page}_ui_compare.json"
    analysis_payload: Dict[str, Any] = {
        "page_name": page_name,
        "reference_image_path": str(ref_path),
        "runtime_image_path": str(run_path),
        "raw_response": raw_text,
        "parsed_response": parsed,
    }
    analysis_path.write_text(json.dumps(analysis_payload, ensure_ascii=False, indent=2), encoding="utf-8")

    if not parsed:
        return "\n".join(
            [
                "status: PARTIAL_SUCCESS",
                "reason: mini agent did not return valid json",
                f"analysis_path: {analysis_path}",
                f"page_name: {page_name or '(unknown)'}",
                f"reference_image_path: {ref_path}",
                f"runtime_image_path: {run_path}",
                "raw_response:",
                raw_text or "(empty)",
            ]
        )

    overall = str(parsed.get("overall", "UNKNOWN")).upper()
    score = parsed.get("similarity_score", "UNKNOWN")
    similarities = parsed.get("similarities", [])
    differences = parsed.get("differences", [])
    summary = str(parsed.get("summary", "")).strip()

    lines = [
        "status: SUCCESS",
        f"analysis_path: {analysis_path}",
        f"page_name: {page_name or '(unknown)'}",
        f"reference_image_path: {ref_path}",
        f"runtime_image_path: {run_path}",
        f"overall: {overall}",
        f"similarity_score: {score}",
        "similarities:",
    ]
    if isinstance(similarities, list) and similarities:
        lines.extend(f"- {str(item)}" for item in similarities[:10])
    else:
        lines.append("- (none)")

    lines.append("differences:")
    if isinstance(differences, list) and differences:
        for item in differences[:15]:
            if isinstance(item, dict):
                lines.append(
                    "- "
                    f"item={item.get('item', '')}; "
                    f"impact={item.get('impact', 'unknown')}; "
                    f"category={item.get('category', 'other')}"
                )
            else:
                lines.append(f"- {item}")
    else:
        lines.append("- (none)")

    lines.append(f"summary: {summary or '(empty)'}")
    return "\n".join(lines)


def _resolve_review_output_dir(review_output_dir: str) -> tuple[Optional[Path], str]:
    root = resolve_workspace_path(review_output_dir)
    if not root.exists():
        return None, f"review output dir not found: {root}"
    if not root.is_dir():
        return None, f"review output path is not directory: {root}"

    if (root / "report.txt").exists() or (root / "review_detailed_output.json").exists():
        return root, ""

    candidates = [path for path in root.iterdir() if path.is_dir() and (path / "report.txt").exists()]
    if not candidates:
        return None, (
            "cannot find review run directory with report.txt under: "
            f"{root}. pass exact review output dir (for example /output/<timestamp>)."
        )
    latest = sorted(candidates, key=lambda path: path.stat().st_mtime, reverse=True)[0]
    return latest, ""


def _extract_page_key_from_review_dir_name(name: str) -> str:
    markers = [
        "EntryAbility_page_pages_",
        "EntryAbility_pages_",
        "_pages_",
    ]
    for marker in markers:
        if marker in name:
            return name.split(marker, 1)[-1]
    return name


def _scan_runtime_page_keys(review_output_dir: Path) -> List[str]:
    keys: List[str] = []
    for path in sorted(review_output_dir.iterdir(), key=lambda item: item.name.lower()):
        if not path.is_dir():
            continue
        init_candidates = [
            path / "init_screen.jpeg",
            path / "init_screen.jpg",
            path / "init_screen.png",
            path / "init_screen.webp",
        ]
        if not any(candidate.exists() for candidate in init_candidates):
            continue
        page_key = _extract_page_key_from_review_dir_name(path.name).strip()
        if page_key and page_key not in keys:
            keys.append(page_key)
    return keys


def _infer_page_key_for_reference(image_stem: str, runtime_page_keys: List[str]) -> str:
    keys = [str(item).strip() for item in runtime_page_keys if str(item).strip()]
    if not keys:
        return image_stem

    stem_norm = _normalize_match_key(image_stem)
    if not stem_norm:
        return keys[0]

    for key in keys:
        key_norm = _normalize_match_key(key)
        if stem_norm == key_norm or stem_norm in key_norm or key_norm in stem_norm:
            return key

    scored = sorted(
        keys,
        key=lambda key: difflib.SequenceMatcher(None, stem_norm, _normalize_match_key(key)).ratio(),
        reverse=True,
    )
    return scored[0]


def _looks_like_overlay_reference(file_name: str, description: str) -> bool:
    text = f"{file_name} {description}".lower()
    overlay_keywords = [
        "弹窗",
        "菜单",
        "下拉",
        "浮层",
        "popup",
        "overlay",
        "dialog",
        "sheet",
        "menu",
        "list",
    ]
    return any(keyword in text for keyword in overlay_keywords)


def _load_user_input_metadata(user_input_dir: Path) -> Dict[str, Any]:
    metadata_path = user_input_dir / "user_input_metadata.json"
    if not metadata_path.exists() or not metadata_path.is_file():
        return {}
    try:
        payload = json.loads(metadata_path.read_text(encoding="utf-8", errors="ignore"))
    except Exception:  # noqa: BLE001
        return {}
    return payload if isinstance(payload, dict) else {}


def _extract_state_from_architect_payload(payload: Dict[str, Any]) -> Dict[str, Any]:
    if isinstance(payload.get("final_state"), dict):
        return payload["final_state"]
    if isinstance(payload.get("state"), dict):
        return payload["state"]
    return payload


def _architect_has_image_assets(architect_path: Path) -> bool:
    if not architect_path.exists() or not architect_path.is_file():
        return False
    try:
        payload = json.loads(architect_path.read_text(encoding="utf-8", errors="ignore"))
    except Exception:  # noqa: BLE001
        return False
    if not isinstance(payload, dict):
        return False
    state = _extract_state_from_architect_payload(payload)
    assets = state.get("image_assets", []) if isinstance(state, dict) else []
    if not isinstance(assets, list):
        return False
    for item in assets:
        if not isinstance(item, dict):
            continue
        image_data = str(item.get("image_data", "")).strip()
        image_path = str(item.get("image_path", "")).strip()
        if image_data and image_path:
            return True
    return False


def _build_visual_expected_assets_from_user_input(
    user_input_dir: Path,
    runtime_page_keys: List[str],
) -> Tuple[List[Dict[str, str]], List[str]]:
    metadata = _load_user_input_metadata(user_input_dir)
    file_metas = metadata.get("files", {}) if isinstance(metadata, dict) else {}
    if not isinstance(file_metas, dict):
        file_metas = {}

    entries: List[Dict[str, str]] = []
    debug_lines: List[str] = []
    image_files = sorted(
        [
            path
            for path in user_input_dir.iterdir()
            if path.is_file() and path.suffix.lower() in IMAGE_SUFFIXES
        ],
        key=lambda path: path.name.lower(),
    )

    for image_path in image_files:
        raw_meta = file_metas.get(image_path.name, {}) if isinstance(file_metas, dict) else {}
        if not isinstance(raw_meta, dict):
            raw_meta = {}
        description = str(raw_meta.get("description", "")).strip()
        page_key = _infer_page_key_for_reference(image_path.stem, runtime_page_keys)
        is_overlay = _looks_like_overlay_reference(image_path.name, description)
        logical_path = (
            f"pages/{page_key}/Interaction/{image_path.name}"
            if is_overlay
            else f"pages/{page_key}/{image_path.name}"
        )

        image_b64 = base64.b64encode(image_path.read_bytes()).decode("ascii")
        entries.append(
            {
                "image_path": logical_path,
                "image_data": image_b64,
            }
        )
        debug_lines.append(
            f"- {image_path.name} => {logical_path} (overlay={str(is_overlay).lower()}, desc={'yes' if description else 'no'})"
        )

    return entries, debug_lines


def _build_derived_architect_payload_file(
    review_output_dir: Path,
    user_input_dir: Path,
    runtime_page_keys: List[str],
) -> Tuple[Optional[Path], str, List[str]]:
    assets, debug_lines = _build_visual_expected_assets_from_user_input(
        user_input_dir=user_input_dir,
        runtime_page_keys=runtime_page_keys,
    )
    if not assets:
        return None, "no image files found under user_input", debug_lines

    payload = {
        "state": {
            "image_assets": assets,
        }
    }
    target_path = review_output_dir / "visual_review_expected_assets.generated.json"
    target_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    return target_path, "", debug_lines


def _select_summary_images(image_paths: List[Path], max_images: int) -> List[Path]:
    if not image_paths:
        return []

    def _priority(path: Path) -> tuple[int, float]:
        name = path.name.lower()
        rank = 5
        if "init_screen" in name:
            rank = 0
        elif "after" in name:
            rank = 1
        elif "before" in name:
            rank = 2
        elif "return" in name:
            rank = 3
        return rank, -path.stat().st_mtime

    ranked = sorted(image_paths, key=_priority)
    selected = ranked[: max(1, int(max_images))]
    return sorted(selected, key=lambda path: str(path))


def _describe_screenshot_for_summary(image_path: Path) -> str:
    try:
        image_data_url = _encode_image_as_data_url(image_path)
    except Exception as exc:  # noqa: BLE001
        return f"(image_read_failed: {exc})"

    prompt = (
        "You are summarizing mobile app test evidence. "
        "Describe in ONE short sentence what end-user capability is visible in this screenshot. "
        "Focus on user actions, not pixel details."
    )
    try:
        response = vision_model.invoke(
            [
                HumanMessage(
                    content=[
                        {"type": "text", "text": prompt},
                        {"type": "image_url", "image_url": {"url": image_data_url}},
                    ]
                )
            ]
        )
    except Exception as exc:  # noqa: BLE001
        return f"(vision_summary_failed: {exc})"

    text = _extract_message_text(getattr(response, "content", ""))
    first_line = str(text or "").strip().splitlines()[0] if str(text or "").strip() else ""
    return first_line or "(empty_vision_summary)"


def _normalize_external_evidence_path(raw_path: str) -> Optional[Path]:
    text = str(raw_path or "").strip()
    if not text:
        return None

    # Convert WSL style paths from review artifacts to local Windows paths when needed.
    mount_match = re.match(r"^/mnt/([a-zA-Z])/(.*)$", text)
    if mount_match:
        drive = mount_match.group(1).upper()
        tail = mount_match.group(2).replace("/", "\\")
        candidate = Path(f"{drive}:\\{tail}")
        if candidate.exists():
            return candidate

    direct = Path(text)
    if direct.is_absolute() and direct.exists():
        return direct

    resolved = resolve_workspace_path(text)
    if resolved.exists():
        return resolved
    return None


def _safe_first_image_in_dir(page_dir: Path) -> Optional[Path]:
    for name in ["init_screen.jpeg", "init_screen.jpg", "init_screen.png", "init_screen.webp"]:
        path = page_dir / name
        if path.exists() and path.is_file():
            return path
    images = sorted(path for path in page_dir.glob("*") if path.is_file() and path.suffix.lower() in IMAGE_SUFFIXES)
    return images[0] if images else None


def _folder_name_from_page_id(page_id: str) -> str:
    token = re.sub(r"[^a-zA-Z0-9]+", "_", str(page_id or "").strip())
    token = re.sub(r"_+", "_", token).strip("_")
    return token


def _extract_jump_lines_from_report(report_text: str) -> List[str]:
    lines: List[str] = []
    for raw_line in str(report_text or "").splitlines():
        line = raw_line.strip()
        if "→" in line and "触发元素" in line:
            line = re.sub(r"^\d+[\.、]\s*", "", line)
            lines.append(line)
    deduped: List[str] = []
    seen = set()
    for item in lines:
        if item in seen:
            continue
        seen.add(item)
        deduped.append(item)
    return deduped


def _fallback_feature_name_from_action(action: Dict[str, Any]) -> str:
    element = action.get("element", {}) if isinstance(action, dict) else {}
    element_type = str(element.get("type", "")).strip()
    element_text = str(element.get("text", "")).strip()
    action_type = str(action.get("action_type", "click")).strip().lower()
    if action_type == "input":
        return "支持输入内容并更新界面状态"
    if action_type in {"switch", "click"} and element_text:
        return f"支持点击“{element_text}”触发界面状态变化"
    if action_type in {"switch", "click"} and element_type:
        return f"支持点击{element_type}组件触发界面状态变化"
    return "支持交互操作后更新当前页面状态"


def _vision_infer_feature_from_images(
    page_id: str,
    action: Dict[str, Any],
    init_image: Optional[Path],
    before_image: Optional[Path],
    after_image: Optional[Path],
) -> Dict[str, Any]:
    element = action.get("element", {}) if isinstance(action, dict) else {}
    page_changed = bool(action.get("page_changed", False))
    prompt = (
        "你是移动端验收总结助手。"
        "请根据同一页面的截图对比，判断本次操作实现了什么用户可感知功能。"
        "重点观察 init_screen 与 elem 的 before/after 变化。"
        "如果变化本质是页面跳转，请标记 is_navigation=true 并不要输出页面功能。"
        "输出严格 JSON: "
        '{"feature":"...","confidence":"high|medium|low","is_navigation":true|false,"reason":"..."}'
        "。feature 用中文短句，面向用户。"
        f"\npage_id={page_id}"
        f"\naction_type={action.get('action_type', '')}"
        f"\npage_changed={page_changed}"
        f"\nelement_type={element.get('type', '')}"
        f"\nelement_text={element.get('text', '')}"
        f"\nelement_id={element.get('id', '')}"
    )

    content_items: List[Dict[str, Any]] = [{"type": "text", "text": prompt}]
    for tag, image_path in [("init", init_image), ("before", before_image), ("after", after_image)]:
        if not image_path:
            continue
        try:
            data_url = _encode_image_as_data_url(image_path)
        except Exception:  # noqa: BLE001
            continue
        content_items.append({"type": "text", "text": f"image_tag={tag}"})
        content_items.append({"type": "image_url", "image_url": {"url": data_url}})

    try:
        response = vision_model.invoke([HumanMessage(content=content_items)])
    except Exception as exc:  # noqa: BLE001
        return {
            "feature": _fallback_feature_name_from_action(action),
            "confidence": "low",
            "is_navigation": page_changed,
            "reason": f"vision_invoke_failed: {exc}",
            "source": "fallback",
        }

    raw = _extract_message_text(getattr(response, "content", ""))
    parsed = _extract_json_like_object(raw)
    if not isinstance(parsed, dict):
        return {
            "feature": _fallback_feature_name_from_action(action),
            "confidence": "low",
            "is_navigation": page_changed,
            "reason": "vision_output_invalid_json",
            "source": "fallback",
        }

    feature = str(parsed.get("feature", "")).strip() or _fallback_feature_name_from_action(action)
    confidence = str(parsed.get("confidence", "medium")).strip().lower()
    if confidence not in {"high", "medium", "low"}:
        confidence = "medium"
    is_navigation = bool(parsed.get("is_navigation", False))
    reason = str(parsed.get("reason", "")).strip()
    return {
        "feature": feature,
        "confidence": confidence,
        "is_navigation": is_navigation,
        "reason": reason,
        "source": "vision",
    }


@tool
def summarize_review_features_by_page(
    review_output_dir: str = "/reports",
    output_file_name: str = "flow_summary_user.md",
) -> str:
    """
    Summarize review output into two sections:
    1) page features inferred from init_screen vs elem screenshots (ignore navigation),
    2) navigation features extracted from report.txt.
    """
    print("start summarizing review features by page")
    resolved_dir, resolve_error = _resolve_review_output_dir(review_output_dir)
    if resolve_error or not resolved_dir:
        return f"status: FAILED\nreason: {resolve_error or 'review output dir resolve failed'}"

    detail_path = resolved_dir / "review_detailed_output.json"
    report_txt_path = resolved_dir / "report.txt"
    detail_payload = _safe_load_json_path(detail_path)
    if not detail_payload:
        return f"status: FAILED\nreason: review_detailed_output.json not found or invalid\npath: {detail_path}"

    raw_results = detail_payload.get("results", []) if isinstance(detail_payload, dict) else []
    if not isinstance(raw_results, list):
        raw_results = []

    actions_by_page: Dict[str, List[Dict[str, Any]]] = {}
    for item in raw_results:
        if not isinstance(item, dict):
            continue
        if not bool(item.get("action_success", False)):
            continue
        page_id = str(item.get("page_before", "")).strip() or "unknown_page"
        actions_by_page.setdefault(page_id, []).append(item)

    page_feature_rows: List[Dict[str, Any]] = []
    for page_id in sorted(actions_by_page.keys()):
        page_dir = resolved_dir / _folder_name_from_page_id(page_id)
        init_image = _safe_first_image_in_dir(page_dir) if page_dir.exists() else None

        inferred_features: List[Dict[str, str]] = []
        seen_feature = set()
        for action in actions_by_page.get(page_id, []):
            evidence = action.get("evidence", {}) if isinstance(action.get("evidence"), dict) else {}
            before_image = _normalize_external_evidence_path(str(evidence.get("before_screenshot", "")))
            after_image = _normalize_external_evidence_path(str(evidence.get("after_screenshot", "")))

            inference = _vision_infer_feature_from_images(
                page_id=page_id,
                action=action,
                init_image=init_image,
                before_image=before_image,
                after_image=after_image,
            )

            if bool(action.get("page_changed", False)) or bool(inference.get("is_navigation", False)):
                continue

            feature = str(inference.get("feature", "")).strip()
            if not feature or feature in seen_feature:
                continue
            seen_feature.add(feature)
            inferred_features.append(
                {
                    "feature": feature,
                    "confidence": str(inference.get("confidence", "medium")),
                    "reason": str(inference.get("reason", "")).strip(),
                }
            )

        page_feature_rows.append(
            {
                "page_id": page_id,
                "feature_count": len(inferred_features),
                "features": inferred_features,
                "note": "未观察到可确认的非跳转交互功能" if not inferred_features else "",
            }
        )

    report_text = report_txt_path.read_text(encoding="utf-8", errors="ignore") if report_txt_path.exists() else ""
    jump_features = _extract_jump_lines_from_report(report_text)

    md_lines: List[str] = ["# 功能总结", "", "## 页面功能"]
    for row in page_feature_rows:
        md_lines.append(f"### {row['page_id']}")
        features = row.get("features", [])
        if isinstance(features, list) and features:
            for feature_item in features:
                confidence = str(feature_item.get("confidence", "medium"))
                md_lines.append(f"- {feature_item.get('feature', '')}（置信度: {confidence}）")
        else:
            md_lines.append("- 未观察到可确认的非跳转交互功能")
        md_lines.append("")

    md_lines.append("## 跳转功能")
    if jump_features:
        for item in jump_features:
            md_lines.append(f"- {item}")
    else:
        md_lines.append("- 未从 report.txt 提取到跳转路径")
    md_lines.append("")

    markdown = "\n".join(md_lines).strip() + "\n"

    safe_name = Path(output_file_name).name or "flow_summary_user.md"
    if not safe_name.lower().endswith(".md"):
        safe_name = f"{safe_name}.md"
    summary_md_path = resolved_dir / safe_name
    summary_json_path = resolved_dir / (Path(safe_name).stem + ".json")

    summary_payload = {
        "review_output_dir": str(resolved_dir),
        "generated_at": datetime.now().isoformat(timespec="seconds"),
        "page_features": page_feature_rows,
        "jump_features": jump_features,
        "summary_markdown_path": str(summary_md_path),
    }

    summary_md_path.write_text(markdown, encoding="utf-8")
    summary_json_path.write_text(json.dumps(summary_payload, ensure_ascii=False, indent=2), encoding="utf-8")

    return "\n".join(
        [
            "status: SUCCESS",
            f"review_output_dir: {resolved_dir}",
            f"summary_markdown_path: {summary_md_path}",
            f"summary_json_path: {summary_json_path}",
            f"page_count: {len(page_feature_rows)}",
            f"jump_feature_count: {len(jump_features)}",
            "summary_markdown:",
            markdown,
        ]
    )


@tool
def run_visual_review_with_inputs(
    review_output_dir: str = "/reports",
    architect_output_path: str = "/designs/architect.json",
    user_input_dir: str = "/user_input",
    output_file_name: str = "visual_review_output.json",
    use_llm: bool = True,
    llm_model: str = "qwen-vl-max",
    show_progress: bool = False,
    force_rebuild_expected_assets: bool = False,
) -> str:
    """
    Run visual review by matching each runtime screenshot to top1 user_input reference image.
    New logic does not rely on architect image_assets.
    """
    print("start running visual review")

    resolved_review_dir, resolve_error = _resolve_review_output_dir(review_output_dir)
    if resolve_error or not resolved_review_dir:
        return f"status: FAILED\nreason: {resolve_error or 'review output dir resolve failed'}"

    _ = architect_output_path
    _ = force_rebuild_expected_assets
    resolved_user_input_dir = resolve_workspace_path(user_input_dir)
    if not resolved_user_input_dir.exists() or not resolved_user_input_dir.is_dir():
        return f"status: FAILED\nreason: user_input dir not found: {resolved_user_input_dir}"

    safe_name = Path(output_file_name).name or "visual_review_page_elem_output.json"
    if not safe_name.lower().endswith(".json"):
        safe_name = f"{safe_name}.json"
    output_json_path = resolved_review_dir / safe_name

    try:
        from visual_review_node_v3 import run_visual_review_page_elem
    except Exception as exc:  # noqa: BLE001
        return (
            "status: FAILED\n"
            "reason: import visual_review_node_v3 failed\n"
            f"error: {exc}"
        )

    try:
        report = run_visual_review_page_elem(
            review_output_dir=resolved_review_dir,
            output_json_path=output_json_path,
            user_input_dir=resolved_user_input_dir,
            show_progress=bool(show_progress),
            use_llm=bool(use_llm),
            llm_model=str(llm_model or "qwen-vl-max").strip() or "qwen-vl-max",
            architect_output_path=None,
        )
    except Exception as exc:  # noqa: BLE001
        return (
            "status: FAILED\n"
            "reason: run_visual_review_page_elem execution failed\n"
            f"review_output_dir: {resolved_review_dir}\n"
            f"user_input_dir: {resolved_user_input_dir}\n"
            f"error: {exc}"
        )

    stats = report.get("stats", {}) if isinstance(report, dict) else {}
    machine_report_path = str(report.get("machine_report_path", output_json_path))
    user_report_path = str(report.get("user_report_path", "")).strip()

    lines = [
        "status: SUCCESS",
        f"review_output_dir: {resolved_review_dir}",
        f"review_output_dir_rel: {_workspace_relative_display(resolved_review_dir)}",
        f"visual_review_machine_json_path: {machine_report_path}",
        f"visual_review_machine_json_path_rel: {_workspace_relative_display(Path(machine_report_path))}",
        f"visual_review_user_path: {user_report_path or '(none)'}",
        f"runtime_image_count: {stats.get('runtime_image_count', 0)}",
        f"reference_image_count: {stats.get('reference_image_count', 0)}",
        f"matched_count: {stats.get('matched_count', 0)}",
        f"avg_top1_score: {stats.get('avg_top1_score', 0)}",
        f"llm_used: {stats.get('llm_used', False)}",
        f"elapsed_seconds: {stats.get('elapsed_seconds', 0)}",
    ]
    return "\n".join(lines)




@tool
def evaluate_test_coverage(
    plan_json: str,
    visited_pages: str = "",
    executed_case_ids: str = "",
    compared_pages: str = "",
) -> str:
    """
    Evaluate whether all planned pages/cases have been covered by execution records.
    """
    print("start evaluating tester coverage")
    payload = _extract_plan_payload(plan_json)
    if not payload:
        return "status: FAILED\nreason: invalid plan_json input"

    expected_pages_raw = payload.get("expected_pages", [])
    expected_cases_raw = payload.get("merged_cases", [])

    expected_pages = []
    if isinstance(expected_pages_raw, list):
        for item in expected_pages_raw:
            if isinstance(item, dict):
                value = str(item.get("page_name") or "").strip()
                if value:
                    expected_pages.append(value)

    expected_case_ids = []
    if isinstance(expected_cases_raw, list):
        for item in expected_cases_raw:
            if isinstance(item, dict):
                value = str(item.get("id") or "").strip()
                if value:
                    expected_case_ids.append(value)

    def _parse_items(raw: str) -> List[str]:
        text = str(raw or "").strip()
        if not text:
            return []
        try:
            parsed = json.loads(text)
            if isinstance(parsed, list):
                values = [str(item).strip() for item in parsed if str(item).strip()]
                return values
        except Exception:  # noqa: BLE001
            pass
        return [part.strip() for part in re.split(r"[,\n|;]+", text) if part.strip()]

    visited = _parse_items(visited_pages)
    executed = _parse_items(executed_case_ids)
    compared = _parse_items(compared_pages)

    visited_norm = {_normalize_match_key(item): item for item in visited}
    compared_norm = {_normalize_match_key(item): item for item in compared}
    executed_norm = {str(item).strip().upper() for item in executed}

    missing_pages_visit = [
        page for page in expected_pages if _normalize_match_key(page) not in visited_norm
    ]
    missing_pages_compare = [
        page for page in expected_pages if _normalize_match_key(page) not in compared_norm
    ]
    missing_cases = [
        case_id for case_id in expected_case_ids if case_id.strip().upper() not in executed_norm
    ]

    passed = not missing_pages_visit and not missing_pages_compare and not missing_cases
    result_payload = {
        "expected_page_count": len(expected_pages),
        "expected_case_count": len(expected_case_ids),
        "visited_page_count": len(visited),
        "executed_case_count": len(executed),
        "compared_page_count": len(compared),
        "missing_pages_by_visit": missing_pages_visit,
        "missing_pages_by_compare": missing_pages_compare,
        "missing_case_ids": missing_cases,
    }

    return "\n".join(
        [
            f"status: {'PASS' if passed else 'FAIL'}",
            f"expected_page_count: {len(expected_pages)}",
            f"expected_case_count: {len(expected_case_ids)}",
            f"visited_page_count: {len(visited)}",
            f"executed_case_count: {len(executed)}",
            f"compared_page_count: {len(compared)}",
            f"missing_pages_by_visit_count: {len(missing_pages_visit)}",
            f"missing_pages_by_compare_count: {len(missing_pages_compare)}",
            f"missing_case_count: {len(missing_cases)}",
            "coverage_json:",
            json.dumps(result_payload, ensure_ascii=False),
        ]
    )


def _parse_bounds(bounds_str: str) -> Optional[Tuple[int, int, int, int]]:
    nums = [int(part) for part in re.findall(r"\d+", str(bounds_str or ""))]
    if len(nums) == 4:
        return nums[0], nums[1], nums[2], nums[3]
    return None


def _center(bounds: Tuple[int, int, int, int]) -> Tuple[int, int]:
    left, top, right, bottom = bounds
    return (left + right) // 2, (top + bottom) // 2


def _walk_layout_nodes(node: Dict[str, Any]):
    if not isinstance(node, dict):
        return
    yield node
    for child in node.get("children", []):
        if isinstance(child, dict):
            yield from _walk_layout_nodes(child)


def _collect_layout_elements(layout_payload: Dict[str, Any]) -> List[Dict[str, Any]]:
    elements: List[Dict[str, Any]] = []
    for node in _walk_layout_nodes(layout_payload):
        attrs = node.get("attributes", {})
        bounds = _parse_bounds(str(attrs.get("bounds", "")))
        if not bounds:
            continue
        text = str(attrs.get("text", "")).strip()
        node_type = str(attrs.get("type", "")).strip()
        element_id = str(attrs.get("id", "")).strip()
        clickable = str(attrs.get("clickable", "false")) == "true"
        long_clickable = str(attrs.get("longClickable", "false")) == "true"
        focusable = str(attrs.get("focusable", "false")) == "true"
        enabled = str(attrs.get("enabled", "true")) != "false"
        checkable = str(attrs.get("checkable", "false")) == "true"
        scrollable = str(attrs.get("scrollable", "false")) == "true"
        cx, cy = _center(bounds)
        elements.append(
            {
                "id": element_id,
                "text": text,
                "type": node_type,
                "bounds": bounds,
                "center": (cx, cy),
                "clickable": clickable,
                "long_clickable": long_clickable,
                "focusable": focusable,
                "checkable": checkable,
                "scrollable": scrollable,
                "enabled": enabled,
            }
        )
    return elements


def _screen_bounds(layout_payload: Dict[str, Any], elements: List[Dict[str, Any]]) -> Optional[Tuple[int, int, int, int]]:
    root_bounds = _parse_bounds(str(layout_payload.get("attributes", {}).get("bounds", "")))
    if root_bounds:
        return root_bounds
    if not elements:
        return None
    left = min(elem["bounds"][0] for elem in elements)
    top = min(elem["bounds"][1] for elem in elements)
    right = max(elem["bounds"][2] for elem in elements)
    bottom = max(elem["bounds"][3] for elem in elements)
    return left, top, right, bottom


def _extract_key_value(output_text: str, key: str) -> str:
    prefix = f"{key}:"
    for raw_line in str(output_text or "").splitlines():
        line = raw_line.strip()
        if line.startswith(prefix):
            return line[len(prefix) :].strip()
    return ""


def _load_layout_from_path(layout_path: str) -> Tuple[Optional[Path], Optional[Dict[str, Any]], Optional[str]]:
    target = resolve_workspace_path(layout_path)
    if not target.exists():
        return None, None, f"layout not found: {target}"
    if not target.is_file():
        return None, None, f"layout path is not file: {target}"
    try:
        payload = json.loads(target.read_text(encoding="utf-8", errors="ignore"))
    except Exception as exc:  # noqa: BLE001
        return None, None, f"layout json parse failed: {exc}"
    return target, payload, None


def _is_interactive(element: Dict[str, Any]) -> bool:
    return bool(
        element.get("enabled")
        and (
            element.get("clickable")
            or element.get("long_clickable")
            or element.get("focusable")
            or element.get("checkable")
        )
    )


def _select_top_right_candidate(
    interactive_elements: List[Dict[str, Any]],
    screen_bounds: Tuple[int, int, int, int],
    target_hint: str,
) -> Optional[Dict[str, Any]]:
    left, top, right, bottom = screen_bounds
    width = max(1, right - left)
    height = max(1, bottom - top)
    right_threshold = left + int(width * 0.55)
    top_threshold = top + int(height * 0.30)

    top_right = [
        elem
        for elem in interactive_elements
        if elem["center"][0] >= right_threshold and elem["center"][1] <= top_threshold
    ]
    if not top_right:
        return None

    sorted_by_x = sorted(top_right, key=lambda item: (item["center"][0], item["center"][1]))
    hint = str(target_hint or "").strip().lower()

    if hint in {"top_right_menu_button", "menu", "three_dots", "more"}:
        return sorted_by_x[-1]
    if hint in {"top_right_middle_button", "middle", "center"}:
        if len(sorted_by_x) >= 2:
            return sorted_by_x[-2]
        return sorted_by_x[-1]
    if hint in {"top_right_left_button", "left"}:
        return sorted_by_x[0]
    return sorted_by_x[-1]


def _layout_signature(layout_payload: Dict[str, Any], max_tokens: int = 120) -> Tuple[str, ...]:
    tokens: List[str] = []
    for node in _walk_layout_nodes(layout_payload):
        attrs = node.get("attributes", {})
        token = "|".join(
            [
                str(attrs.get("type", "")),
                str(attrs.get("text", "")).strip()[:24],
                str(attrs.get("bounds", "")),
                f"c={attrs.get('clickable', '')}",
                f"s={attrs.get('scrollable', '')}",
                f"e={attrs.get('enabled', '')}",
            ]
        )
        tokens.append(token)
        if len(tokens) >= max_tokens:
            break
    return tuple(tokens)


def _safe_split_values(raw: str) -> List[str]:
    return [part.strip() for part in re.split(r"[,\n|;]+", str(raw or "")) if part.strip()]


def _collect_visible_texts(layout_payload: Dict[str, Any]) -> List[str]:
    texts: List[str] = []
    for node in _walk_layout_nodes(layout_payload):
        text = str(node.get("attributes", {}).get("text", "")).strip()
        if text:
            texts.append(text)
    return texts


@tool
def click_element(
    layout_path: str,
    target: str,
    match_mode: str = "hint",
) -> str:
    """
    Click UI element by coordinate resolved from dumped layout.
    match_mode supports: hint | text_exact | text_contains | id_exact.
    For hint, supported target includes: top_right_middle_button, top_right_menu_button.
    """
    print("start clicking element by layout")
    resolved_layout_path, payload, error = _load_layout_from_path(layout_path)
    if error:
        return f"status: FAILED\nreason: {error}"

    elements = _collect_layout_elements(payload or {})
    interactive = [elem for elem in elements if _is_interactive(elem)]
    if not interactive:
        return f"status: FAILED\nreason: no interactive element found in layout\nlayout_path: {resolved_layout_path}"

    mode = str(match_mode or "hint").strip().lower()
    chosen: Optional[Dict[str, Any]] = None

    if mode == "text_exact":
        chosen = next((elem for elem in interactive if elem.get("text") == target), None)
    elif mode == "text_contains":
        key = str(target or "").strip().lower()
        chosen = next((elem for elem in interactive if key and key in str(elem.get("text", "")).lower()), None)
    elif mode == "id_exact":
        chosen = next((elem for elem in interactive if elem.get("id") == target), None)
    else:
        screen = _screen_bounds(payload or {}, elements)
        if screen:
            chosen = _select_top_right_candidate(interactive, screen, target)

    if not chosen:
        return (
            "status: FAILED\n"
            f"reason: cannot resolve target element\n"
            f"layout_path: {resolved_layout_path}\n"
            f"target: {target}\n"
            f"match_mode: {mode}"
        )

    click_x, click_y = chosen["center"]
    selected_target, target_error = _ensure_target_ready()
    if not selected_target:
        return f"status: FAILED\nreason: {target_error}"

    result = _run_tester_script(
        "hdc_ui_click.sh",
        [str(click_x), str(click_y)],
        timeout=20,
        target=selected_target,
    )

    status = "SUCCESS" if result.returncode == 0 else "FAILED"
    bounds = chosen["bounds"]
    return "\n".join(
        [
            f"status: {status}",
            f"layout_path: {resolved_layout_path}",
            f"match_mode: {mode}",
            f"target: {target}",
            f"matched_text: {chosen.get('text', '')}",
            f"matched_id: {chosen.get('id', '')}",
            f"matched_type: {chosen.get('type', '')}",
            f"matched_bounds: [{bounds[0]},{bounds[1]}][{bounds[2]},{bounds[3]}]",
            f"click_x: {click_x}",
            f"click_y: {click_y}",
            f"target: {selected_target}",
            "cmd_result:",
            format_cmd_result(result),
        ]
    )


@tool
def swipe_screen(
    start_x: int,
    start_y: int,
    end_x: int,
    end_y: int,
) -> str:
    """
    Swipe on screen using absolute coordinates.
    """
    print("start swiping screen by coordinates")
    selected_target, target_error = _ensure_target_ready()
    if not selected_target:
        return f"status: FAILED\nreason: {target_error}"

    result = _run_tester_script(
        "hdc_ui_swipe.sh",
        [str(int(start_x)), str(int(start_y)), str(int(end_x)), str(int(end_y))],
        timeout=20,
        target=selected_target,
    )
    status = "SUCCESS" if result.returncode == 0 else "FAILED"
    return "\n".join(
        [
            f"status: {status}",
            f"start: ({int(start_x)}, {int(start_y)})",
            f"end: ({int(end_x)}, {int(end_y)})",
            f"target: {selected_target}",
            "cmd_result:",
            format_cmd_result(result),
        ]
    )


@tool
def press_back() -> str:
    """
    Trigger system back key event.
    """
    print("start pressing back key")
    selected_target, target_error = _ensure_target_ready()
    if not selected_target:
        return f"status: FAILED\nreason: {target_error}"

    result = _run_tester_script("hdc_ui_back.sh", [], timeout=20, target=selected_target)
    status = "SUCCESS" if result.returncode == 0 else "FAILED"
    return "\n".join(
        [
            f"status: {status}",
            "key: Back",
            f"target: {selected_target}",
            "cmd_result:",
            format_cmd_result(result),
        ]
    )


@tool
def wait_for_ui_stable(
    timeout_seconds: int = 8,
    interval_seconds: float = 0.8,
    stable_rounds: int = 2,
    output_dir: str = "/logs/tester",
) -> str:
    """
    Poll layout snapshots until UI signature remains stable for N rounds.
    """
    print("start waiting for UI stable by polling layout")
    timeout = max(1, int(timeout_seconds))
    interval = max(0.2, float(interval_seconds))
    stable_need = max(1, int(stable_rounds))
    start = time.time()
    same_count = 0
    previous_signature: Optional[Tuple[str, ...]] = None
    last_layout_path = ""
    rounds = 0

    while time.time() - start <= timeout:
        rounds += 1
        dump_result = dump_app_layout.invoke(
            {"file_name": f"stable_probe_{rounds}.json", "output_dir": output_dir}
        )
        if "status: FAILED" in dump_result:
            return "\n".join(
                [
                    "status: FAILED",
                    f"reason: dump layout failed during wait round {rounds}",
                    "dump_result:",
                    dump_result,
                ]
            )

        layout_path = _extract_key_value(dump_result, "layout_path")
        if not layout_path:
            return "\n".join(
                [
                    "status: FAILED",
                    f"reason: cannot get layout_path from dump result in round {rounds}",
                    "dump_result:",
                    dump_result,
                ]
            )
        last_layout_path = layout_path
        _, payload, error = _load_layout_from_path(layout_path)
        if error:
            return f"status: FAILED\nreason: {error}"

        signature = _layout_signature(payload or {})
        if signature == previous_signature:
            same_count += 1
        else:
            same_count = 1
            previous_signature = signature

        if same_count >= stable_need:
            return "\n".join(
                [
                    "status: SUCCESS",
                    f"stable_rounds_observed: {same_count}",
                    f"rounds_total: {rounds}",
                    f"last_layout_path: {last_layout_path}",
                ]
            )
        time.sleep(interval)

    return "\n".join(
        [
            "status: TIMEOUT",
            f"rounds_total: {rounds}",
            f"last_layout_path: {last_layout_path or '(none)'}",
            f"required_stable_rounds: {stable_need}",
        ]
    )


@tool
def assert_state(
    expected_texts: str = "",
    forbidden_texts: str = "",
    page_keyword: str = "",
    layout_path: str = "",
    output_dir: str = "/logs/tester",
) -> str:
    """
    Assert current UI state from layout evidence.
    - expected_texts: split by comma/line/pipe
    - forbidden_texts: split by comma/line/pipe
    - page_keyword: optional keyword matched against ability/page path
    """
    print("start asserting UI state by layout analysis")
    effective_layout_path = str(layout_path or "").strip()
    if not effective_layout_path:
        dump_result = dump_app_layout.invoke(
            {"file_name": "assert_state.json", "output_dir": output_dir}
        )
        if "status: FAILED" in dump_result:
            return "\n".join(["status: FAILED", "reason: cannot dump layout for assert_state", dump_result])
        effective_layout_path = _extract_key_value(dump_result, "layout_path")
        if not effective_layout_path:
            return "\n".join(["status: FAILED", "reason: dump layout succeeded but no layout_path found", dump_result])

    resolved_layout_path, payload, error = _load_layout_from_path(effective_layout_path)
    if error:
        return f"status: FAILED\nreason: {error}"

    texts = _collect_visible_texts(payload or {})
    lowered_texts = [item.lower() for item in texts]

    expected_list = _safe_split_values(expected_texts)
    forbidden_list = _safe_split_values(forbidden_texts)

    expected_missing = [
        item for item in expected_list if item.lower() not in lowered_texts and not any(item.lower() in x for x in lowered_texts)
    ]
    forbidden_hit = [
        item for item in forbidden_list if item.lower() in lowered_texts or any(item.lower() in x for x in lowered_texts)
    ]

    page_context = ""
    for node in _walk_layout_nodes(payload or {}):
        attrs = node.get("attributes", {})
        bundle_name = str(attrs.get("bundleName", "")).strip()
        ability_name = str(attrs.get("abilityName", "")).strip()
        page_path = str(attrs.get("pagePath", "")).strip()
        if bundle_name or ability_name or page_path:
            page_context = f"bundle={bundle_name}|ability={ability_name}|page={page_path}"
            break
    page_key = str(page_keyword or "").strip().lower()
    page_ok = True
    if page_key:
        page_ok = page_key in page_context.lower()

    passed = not expected_missing and not forbidden_hit and page_ok
    status = "PASS" if passed else "FAIL"

    lines = [
        f"status: {status}",
        f"layout_path: {resolved_layout_path}",
        f"page_context: {page_context or '(empty)'}",
        f"expected_total: {len(expected_list)}",
        f"forbidden_total: {len(forbidden_list)}",
        "missing_expected:",
    ]
    lines.extend(f"- {item}" for item in expected_missing or ["- (none)"])
    lines.append("forbidden_found:")
    lines.extend(f"- {item}" for item in forbidden_hit or ["- (none)"])
    lines.append(f"page_keyword: {page_keyword or '(none)'}")
    lines.append(f"page_keyword_match: {page_ok}")
    lines.append("visible_text_preview:")
    preview = texts[:30]
    lines.extend(f"- {item}" for item in preview or ["- (none)"])
    return "\n".join(lines)


TESTER_TOOLS = [
    resolve_review_target,
    run_review_node_with_inputs,
    ensure_emulator_ready,
    read_description_baseline,
    build_test_plan_from_inputs,
    install_harmony_app,
    start_harmony_app,
    dump_app_layout,
    click_element,
    wait_for_ui_stable,
    assert_state,
    capture_app_screenshot,
    press_back,
    swipe_screen,
    collect_reference_and_runtime_screenshots,
    pair_reference_pages_with_runtime,
    compare_ui_pair_with_mini_agent,
    evaluate_test_coverage,
    run_visual_review_with_inputs,
    save_tester_report,
]

TESTER_SCRIPT_EXECUTION_TOOLS = [
    ensure_emulator_ready,
    install_harmony_app,
    start_harmony_app,
    dump_app_layout,
    click_element,
    capture_app_screenshot,
    press_back,
    swipe_screen,
]


def tester_tool_names() -> list[str]:
    return [tool.name for tool in TESTER_TOOLS]


def tester_script_execution_tool_names() -> list[str]:
    return [tool.name for tool in TESTER_SCRIPT_EXECUTION_TOOLS]
