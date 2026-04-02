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
    latest_path = base_dir / f"latest_{safe_name}"
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
        "ä½ æ˜¯ä¸€ä¸ªæµ‹è¯•ç”¨ä¾‹æå–å™¨ã€‚"
        "è¯·ä»Žä»¥ä¸‹äº§å“æè¿°ä¸­æå–å¾…æµ‹è¯•åŠŸèƒ½ç‚¹ï¼Œå¹¶ä¸¥æ ¼è¾“å‡º JSON å¯¹è±¡ï¼Œä¸è¦è¾“å‡ºå…¶ä»–æ–‡å­—ã€‚"
        "JSON ç»“æž„å¿…é¡»æ˜¯ï¼š"
        '{"items":[{"description":"...","action_type":"assert|click|navigate|switch|back|input|scroll|long_press","expected_keywords":["..."]}]}'  # noqa: E501
        "ã€‚"
        "è¦æ±‚ï¼š"
        "1) description ç®€æ´å…·ä½“ï¼›"
        "2) action_type å¿…é¡»åœ¨ç»™å®šæžšä¸¾å†…ï¼›"
        "3) expected_keywords ç”¨äºŽæ–‡æœ¬æ–­è¨€ï¼Œ1-6 ä¸ªï¼›"
        "4) ä¸èƒ½è™šæž„ï¼Œåªèƒ½åŸºäºŽè¾“å…¥ã€‚\n\n"
        f"äº§å“æè¿°ï¼š\n{user_text}"
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
    primary_user_text = _extract_primary_user_input_text(desc_text)

    description_points, extractor = _extract_description_points_with_small_model(primary_user_text)
    if not description_points:
        description_points = _extract_description_points(primary_user_text)
        extractor = "rule_fallback"

    merged_cases: List[Dict[str, Any]] = []
    for item in description_points:
        merged_cases.append(
            {
                "id": item.get("id"),
                "source": item.get("source"),
                "category": "description_case",
                "description": item.get("description", ""),
                "action_type": item.get("action_type", ""),
                "expected_keywords": item.get("expected_keywords", []),
            }
        )

    payload = {
        "description_path": str(desc_path),
        "description_available": bool(primary_user_text.strip()),
        "raw_description_available": bool(desc_text.strip()),
        "extractor": extractor,
        "description_items": description_points,
        "merged_cases": merged_cases,
    }
    return "\n".join(
        [
            "status: SUCCESS",
            f"description_available: {payload['description_available']}",
            f"extractor: {payload['extractor']}",
            f"merged_case_count: {len(merged_cases)}",
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
    image_suffixes = {".png", ".jpg", ".jpeg", ".webp", ".bmp"}
    ref_root = resolve_workspace_path(reference_dir)
    runtime_root = resolve_workspace_path(runtime_dir)

    def _collect_images(root: Path) -> List[Path]:
        if not root.exists():
            return []
        return sorted(
            [
                path
                for path in root.rglob("*")
                if path.is_file() and path.suffix.lower() in image_suffixes
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
        f"当前页面/模块名：{page_name or 'unknown'}。\n"
        "判定标准：\n"
        "1) 页面主结构是否一致（头部/主体/底部、主要分区）。\n"
        "2) 关键组件是否存在（核心按钮、输入区、列表/卡片）。\n"
        "3) 主要文案语义是否一致。\n"
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
    compare_ui_pair_with_mini_agent,
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
