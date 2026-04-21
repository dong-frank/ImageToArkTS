#比v12增加了分屏幕测试组件，而不是一次性记录长屏幕所有内容
# test_deep_interactions_v12.py
import subprocess
import time
import os
import re
import json
import argparse
from datetime import datetime
import shutil
from collections import defaultdict
from typing import Any, Dict, List, Tuple, Optional

HDC_WINDOWS_EXE = "/mnt/d/Program Files (x86)/htc/command-line-tools/sdk/default/openharmony/toolchains/hdc.exe"

try:
    from PIL import Image, ImageDraw
    PIL_AVAILABLE = True
except ImportError:
    PIL_AVAILABLE = False
    print("⚠️ Pillow 库未安装，无法生成标注图。如需此功能，请运行: pip install Pillow")

# 页面签名到稳定ID的运行期映射（避免使用哈希）
PAGE_SIGNATURE_TO_ID: Dict[Tuple[str, ...], str] = {}
PAGE_ID_COUNTER = 0


def _convert_mnt_to_windows(path_value: str) -> str:
    text = str(path_value or "").strip()
    normalized = text.replace("\\", "/")
    # 强制匹配纯正的 /mnt/d/ 格式
    match = re.search(r"^/?mnt/([a-zA-Z])/(.*)$", normalized)
    if match:
        suffix = match.group(2).replace("/", "\\")
        return f"{match.group(1).upper()}:\\{suffix}"
    return text

def _normalize_host_path(path_value: str) -> str:
    text = str(path_value or "").strip()
    if not text:
        return text
    
    # 1. 暴力切断：只要字符串里包含 /mnt/，直接扔掉它前面的所有乱码
    normalized = text.replace("\\", "/")
    mixed_match = re.search(r"(/mnt/[a-zA-Z]/.*)$", normalized)
    if mixed_match:
        text = mixed_match.group(1)
        
    if os.name == "nt": 
        return _convert_mnt_to_windows(text)
    else: 
        win_match = re.search(r"^([a-zA-Z]):/(.*)$", text)
        if win_match:
            return f"/mnt/{win_match.group(1).lower()}/{win_match.group(2)}"
        return text

def _normalize_local_path_for_hdc(path_value: str) -> str:
    """专门为 HDC 准备的终极清洗函数"""
    clean_path = _normalize_host_path(path_value)
    clean_path = clean_path.replace("\\", "/")
    
    mnt_match = re.search(r"^/?mnt/([a-zA-Z])/(.*)$", clean_path)
    if mnt_match:
        suffix = mnt_match.group(2).replace("/", "\\")
        return f"{mnt_match.group(1).upper()}:\\{suffix}"
        
    return clean_path.replace("/", "\\")

def run_cmd(cmd, check=True):
    """执行命令并打印输出，check=True 时失败抛出异常"""
    print(f"▶️ 执行: {' '.join(cmd)}")
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"❌ 错误: {result.stderr.strip()}")
        if check:
            raise RuntimeError(f"Command failed: {' '.join(cmd)}")
    else:
        out = result.stdout.strip()
        if out:
            print(f"✅ 输出: {out[:200]}...")
    return result

def parse_bounds(bounds_str):
    """解析 bounds 字符串，返回 (left, top, right, bottom) 或 None"""
    nums = list(map(int, re.findall(r"\d+", bounds_str)))
    if len(nums) == 4:
        return tuple(nums)
    return None

def get_center(bounds_tuple):
    """根据 (left, top, right, bottom) 计算中心点 (x, y)"""
    left, top, right, bottom = bounds_tuple
    return (left + right) // 2, (top + bottom) // 2

def _find_app_node_attrs(node):
    attrs = node.get("attributes", {})
    current_bundle = str(attrs.get("bundleName", ""))
    current_ability = str(attrs.get("abilityName", ""))

    expected_bundle = str(globals().get("bundle_name", "")).strip()
    if expected_bundle:
        if current_bundle == expected_bundle and current_ability:
            return attrs
    else:
        if current_ability:
            return attrs

    for child in node.get("children", []):
        found = _find_app_node_attrs(child)
        if found:
            return found
    return None


def _find_first_bundle_name(node):
    if not isinstance(node, dict):
        return ""

    attrs = node.get("attributes", {})
    if isinstance(attrs, dict):
        bundle = str(attrs.get("bundleName", "")).strip()
        if bundle:
            return bundle

    for child in node.get("children", []):
        found = _find_first_bundle_name(child)
        if found:
            return found

    overlay = node.get("overlay")
    if isinstance(overlay, dict):
        found = _find_first_bundle_name(overlay)
        if found:
            return found
    return ""


def _collect_signature_tokens(node, tokens, max_tokens=120):
    if len(tokens) >= max_tokens:
        return

    attrs = node.get("attributes", {})
    node_type = str(attrs.get("type", ""))
    text = str(attrs.get("text", "")).strip().replace("|", "/")[:24]
    bounds = str(attrs.get("bounds", ""))
    clickable = str(attrs.get("clickable", ""))
    scrollable = str(attrs.get("scrollable", ""))
    enabled = str(attrs.get("enabled", ""))
    token = f"{node_type}|{text}|{bounds}|c={clickable}|s={scrollable}|e={enabled}"
    tokens.append(token)

    for child in node.get("children", []):
        if len(tokens) >= max_tokens:
            break
        _collect_signature_tokens(child, tokens, max_tokens=max_tokens)


def _estimate_status_bar_bottom(layout_data: Any) -> int:
    root_attrs = layout_data.get("attributes", {}) if isinstance(layout_data, dict) else {}
    root_bounds = parse_bounds(root_attrs.get("bounds", "")) if isinstance(root_attrs, dict) else None
    if not root_bounds:
        return 120

    root_top = root_bounds[1]
    root_height = max(1, root_bounds[3] - root_bounds[1])
    default_cutoff = root_top + max(60, int(root_height * 0.04))
    top_scan_limit = root_top + int(root_height * 0.12)
    expected_bundle = str(globals().get("bundle_name", "")).strip()

    max_system_bottom = default_cutoff

    def walk(node):
        nonlocal max_system_bottom
        if not isinstance(node, dict):
            return
        attrs = node.get("attributes", {})
        if isinstance(attrs, dict):
            bounds = parse_bounds(attrs.get("bounds", ""))
            if bounds and bounds[1] <= top_scan_limit:
                node_bundle = str(attrs.get("bundleName", "")).strip()
                node_type = str(attrs.get("type", "")).strip().lower()
                is_system_node = (
                    (node_bundle and expected_bundle and node_bundle != expected_bundle)
                    or "status" in node_type
                    or "systemui" in node_type
                )
                if is_system_node:
                    max_system_bottom = max(max_system_bottom, bounds[3])

        for child in node.get("children", []):
            walk(child)
        overlay = node.get("overlay")
        if isinstance(overlay, dict):
            walk(overlay)

    walk(layout_data)
    return max_system_bottom


def _build_layout_compare_snapshot(node: Any, ignore_top_y: int) -> Any:
    if not isinstance(node, dict):
        return None

    attrs = node.get("attributes", {})
    if not isinstance(attrs, dict):
        attrs = {}

    bounds = parse_bounds(attrs.get("bounds", ""))
    if bounds and bounds[3] <= ignore_top_y:
        return None

    keep_keys = (
        "type", "text", "bounds", "enabled", "clickable",
        "longClickable", "scrollable", "checkable", "focusable",
        "bundleName", "abilityName", "pagePath"
    )
    kept_attrs = {key: attrs.get(key) for key in keep_keys if key in attrs}

    children_snapshots = []
    for child in node.get("children", []):
        child_snapshot = _build_layout_compare_snapshot(child, ignore_top_y)
        if child_snapshot is not None:
            children_snapshots.append(child_snapshot)

    overlay_snapshot = None
    overlay = node.get("overlay")
    if isinstance(overlay, dict):
        overlay_snapshot = _build_layout_compare_snapshot(overlay, ignore_top_y)

    return {
        "attributes": kept_attrs,
        "children": children_snapshots,
        "overlay": overlay_snapshot,
    }


def _is_layout_effectively_same(before_layout: Any, after_layout: Any) -> bool:
    ignore_top_y = max(_estimate_status_bar_bottom(before_layout), _estimate_status_bar_bottom(after_layout))
    before_snapshot = _build_layout_compare_snapshot(before_layout, ignore_top_y)
    after_snapshot = _build_layout_compare_snapshot(after_layout, ignore_top_y)
    return before_snapshot == after_snapshot


def _get_or_allocate_page_id(signature_tokens):
    global PAGE_ID_COUNTER
    key = tuple(signature_tokens)
    if key not in PAGE_SIGNATURE_TO_ID:
        PAGE_ID_COUNTER += 1
        PAGE_SIGNATURE_TO_ID[key] = f"unknown_page_{PAGE_ID_COUNTER:03d}"
    return PAGE_SIGNATURE_TO_ID[key]


def get_page_context(json_data):
    app_attrs = _find_app_node_attrs(json_data)
    if app_attrs:
        ability = str(app_attrs.get("abilityName", "")).strip()
        page_path = str(app_attrs.get("pagePath", "")).strip()
        bundle = str(app_attrs.get("bundleName", "")).strip()
        if ability or page_path:
            page_id = f"ability={ability or '<none>'}|page={page_path or '<none>'}"
            return {
                "page_id": page_id,
                "bundle_name": bundle,
                "ability_name": ability,
                "page_path": page_path,
                "id_source": "ability_page",
                "signature_preview": []
            }

    tokens = []
    _collect_signature_tokens(json_data, tokens, max_tokens=120)
    page_id = _get_or_allocate_page_id(tokens)
    return {
        "page_id": page_id,
        "bundle_name": "",
        "ability_name": "",
        "page_path": "",
        "id_source": "layout_signature",
        "signature_preview": tokens[:12]
    }


def get_page_id(json_data):
    page_context = get_page_context(json_data)
    page_id = page_context["page_id"]
    print(f"🔍 get_page_id: {page_id} (source={page_context['id_source']})")
    return page_id


def safe_page_dir_name(page_id):
    sanitized = re.sub(r"[^A-Za-z0-9._-]+", "_", str(page_id)).strip("_")
    if not sanitized:
        sanitized = "page"
    return sanitized[:96]

def collect_interactive_elements(json_data, include_details=True):
    """
    递归遍历节点，收集所有可交互元素。
    返回列表，每个元素为字典（若 include_details 为 True 则包含完整属性，否则只包含 id,type,bounds,text）
    """
    elements = []
    def traverse(node):
        attrs = node.get("attributes", {})
        enabled = attrs.get("enabled", "true") == "true"
        if not enabled:
            for child in node.get("children", []):
                traverse(child)
            return

        clickable = attrs.get("clickable") == "true"
        long_clickable = attrs.get("longClickable") == "true"
        scrollable = attrs.get("scrollable") == "true"
        checkable = attrs.get("checkable") == "true"
        focusable = attrs.get("focusable") == "true"

        if clickable or long_clickable or scrollable or checkable or focusable:
            text = attrs.get("text", "")
            elem_type = attrs.get("type", "unknown")
            bounds = attrs.get("bounds", "")
            if text:
                elem_id = f"text:{text}"
            else:
                elem_id = f"{elem_type}:{bounds}"

            if include_details:
                elements.append({
                    'id': elem_id,
                    'text': text,
                    'type': elem_type,
                    'bounds': bounds,
                    'clickable': clickable,
                    'longClickable': long_clickable,
                    'scrollable': scrollable,
                    'checkable': checkable,
                    'focusable': focusable,
                })
            else:
                elements.append({
                    'id': elem_id,
                    'type': elem_type,
                    'bounds': bounds,
                    'text': text
                })

        for child in node.get("children", []):
            traverse(child)

    traverse(json_data)
    return elements

def find_node_by_id(json_data, elem_id, original_bounds=None, elem_type=None, elem_text=None):
    """
    根据 elem_id 查找当前布局中匹配的节点。
    如果精确匹配失败，则尝试根据类型和文本模糊匹配，若有多个同类型无文本节点，选择与原始 bounds 最接近的。
    返回 attributes 字典或 None。
    """
    candidates = []  # 存储所有可能的匹配节点及其 bounds
    text_candidates = []  # 文本节点候选（用于文本重复时按位置回退）

    def match(node):
        attrs = node.get("attributes", {})
        text = attrs.get("text", "")
        node_type = attrs.get("type", "unknown")
        bounds = attrs.get("bounds", "")

        # 精确匹配（基于 id 和原始 bounds）
        if elem_id.startswith("text:"):
            target_text = elem_id[5:]
            if target_text == text:
                if original_bounds and bounds == original_bounds:
                    return attrs, True
                # 文本重复时先缓存，后续按与原始位置最近回退
                text_candidates.append((attrs, bounds))
                return None, False
        else:
            parts = elem_id.split(":", 1)
            if len(parts) == 2:
                target_type = parts[0]
                if target_type == node_type and bounds == original_bounds:
                    return attrs, True

        # 模糊匹配：基于类型和文本
        if elem_type and node_type == elem_type:
            if elem_text and elem_text == text:
                # 精确文本匹配，直接返回
                return attrs, False
            elif not elem_text and not text:
                # 无文本且类型匹配，加入候选列表
                candidates.append((attrs, bounds))
        return None, False

    def search(node):
        res, exact = match(node)
        if res:
            return res, exact
        for child in node.get("children", []):
            res, exact = search(child)
            if res:
                return res, exact
        return None, False

    # 先尝试精确匹配（包括基于原始 bounds 的匹配）
    result, exact = search(json_data)
    if result:
        return result

    # 文本元素：如果无精确匹配，按与原始位置最近回退
    if text_candidates:
        if original_bounds:
            orig = parse_bounds(original_bounds)
            if orig:
                orig_cx = (orig[0] + orig[2]) // 2
                orig_cy = (orig[1] + orig[3]) // 2
                best_candidate = None
                best_dist = float('inf')
                for attrs, bounds_str in text_candidates:
                    bounds = parse_bounds(bounds_str)
                    if bounds:
                        cx = (bounds[0] + bounds[2]) // 2
                        cy = (bounds[1] + bounds[3]) // 2
                        dist = ((cx - orig_cx) ** 2 + (cy - orig_cy) ** 2) ** 0.5
                        if dist < best_dist:
                            best_dist = dist
                            best_candidate = attrs
                if best_candidate:
                    return best_candidate
        # 没有原始位置时返回第一个文本候选
        return text_candidates[0][0]

    # 如果没有精确匹配，但有候选，选择与原始 bounds 最接近的
    if candidates and original_bounds:
        orig = parse_bounds(original_bounds)
        if orig:
            orig_cx = (orig[0] + orig[2]) // 2
            orig_cy = (orig[1] + orig[3]) // 2
            best_candidate = None
            best_dist = float('inf')
            for attrs, bounds_str in candidates:
                bounds = parse_bounds(bounds_str)
                if bounds:
                    cx = (bounds[0] + bounds[2]) // 2
                    cy = (bounds[1] + bounds[3]) // 2
                    dist = (cx - orig_cx)**2 + (cy - orig_cy)**2
                    if dist < best_dist:
                        best_dist = dist
                        best_candidate = attrs
            if best_candidate:
                return best_candidate
    elif candidates:
        # 没有原始bounds，返回第一个
        return candidates[0][0]

    return None


def _build_text_dedup_key(elem, bucket_size):
    """构建文本元素去重键，避免仅按文本去重导致漏测同文案不同按钮。"""
    elem_type = elem.get('type', '')
    text = elem.get('text', '')
    bounds = parse_bounds(elem.get('bounds', ''))
    if not bounds:
        return f"{elem_type}:{text}"
    cx = (bounds[0] + bounds[2]) // 2
    cy = (bounds[1] + bounds[3]) // 2
    bx = cx // bucket_size
    by = cy // bucket_size
    return f"{elem_type}:{text}:{bx}:{by}"

def restart_app(bundle_name, ability_name):
    """重启应用至指定 Ability"""
    run_cmd([HDC_WINDOWS_EXE, "shell", "aa", "force-stop", bundle_name], check=False)
    time.sleep(1)
    run_cmd([HDC_WINDOWS_EXE, "shell", "aa", "start", "-b", bundle_name, "-a", ability_name])
    time.sleep(3)

def go_back():
    """发送返回键事件"""
    run_cmd([HDC_WINDOWS_EXE, "shell", "uitest", "uiInput", "keyEvent", "Back"], check=False)
    time.sleep(2)

def take_screenshot(save_path, max_retries=3):
    """截图并保存到指定路径，最多重试 max_retries 次，返回是否成功"""
    remote_jpeg = "/data/local/tmp/screen.jpeg"
    for attempt in range(max_retries):
        # 先删除远程文件，确保新截图
        run_cmd([HDC_WINDOWS_EXE, "shell", "rm", "-f", remote_jpeg], check=False)
        # 执行截图命令
        result1 = run_cmd([HDC_WINDOWS_EXE, "shell", "snapshot_display", "-f", remote_jpeg], check=False)
        if result1.returncode != 0:
            print(f"⚠️ 截图命令失败 (尝试 {attempt+1}/{max_retries})")
            time.sleep(1)
            continue
        # 传输文件到本地
        local_save_path = _normalize_local_path_for_hdc(save_path)
        result2 = run_cmd([HDC_WINDOWS_EXE, "file", "recv", remote_jpeg, local_save_path], check=False)
        if result2.returncode != 0:
            print(f"⚠️ 文件传输失败 (尝试 {attempt+1}/{max_retries})")
            time.sleep(1)
            continue
        if os.path.exists(save_path) and os.path.getsize(save_path) > 0:
            print(f"✅ 截图已保存: {save_path}")
            return True
        else:
            print(f"⚠️ 截图文件不存在或为空 (尝试 {attempt+1}/{max_retries})")
            time.sleep(1)
    print(f"❌ 截图保存失败: {save_path}")
    return False


def dump_layout(save_path, auto_recover=True, _has_recovered=False):
    """获取布局并保存（自动格式化），返回是否成功"""
    remote_layout = "/data/local/tmp/layout.json"
    run_cmd([HDC_WINDOWS_EXE, "shell", "uitest", "dumpLayout", "-p", remote_layout])
    local_save_path = _normalize_local_path_for_hdc(save_path)
    run_cmd([HDC_WINDOWS_EXE, "file", "recv", remote_layout, local_save_path])
    if os.path.exists(save_path):
        try:
            with open(save_path, "r", encoding="utf-8") as f:
                data = json.load(f)

            expected_bundle = str(globals().get("bundle_name", "")).strip()
            current_bundle = _find_first_bundle_name(data)
            if auto_recover and expected_bundle and current_bundle and current_bundle != expected_bundle:
                print(f"⚠️ 检测到当前 bundle 已切换为 {current_bundle}，预期为 {expected_bundle}，准备重启应用恢复")
                if _has_recovered:
                    print("❌ 自动恢复后 bundle 仍不匹配，放弃本次布局抓取")
                    return False

                expected_ability = str(globals().get("ability_name", "")).strip()
                if not expected_ability:
                    print("❌ 未配置 ability_name，无法自动恢复")
                    return False

                restart_app(expected_bundle, expected_ability)
                return dump_layout(save_path, auto_recover=auto_recover, _has_recovered=True)

            with open(save_path, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2, ensure_ascii=False)
            return True
        except:
            return False
    return False

def perform_action(elem_info, layout_file, direction='forward'):
    """
    根据 elem_info 执行点击或滑动操作。
    direction: 'forward' 表示正向滑动，'backward' 表示反向滑动（用于复位）。
    对于点击操作，direction 参数无效。
    返回操作是否成功。
    """
    with open(layout_file, "r", encoding="utf-8") as f:
        data = json.load(f)
    attrs = find_node_by_id(data, elem_info['id'], elem_info.get('bounds'), elem_info.get('type'), elem_info.get('text'))
    if not attrs:
        print(f"⚠️ 无法在布局中找到元素 {elem_info['id']}")
        return False

    bounds_str = attrs.get("bounds", "")
    bounds = parse_bounds(bounds_str)
    if not bounds:
        return False

    left, top, right, bottom = bounds
    width = right - left
    height = bottom - top
    cx, cy = get_center(bounds)
    offset = 50      # 起始偏移量
    distance = 100   # 滑动距离

    if elem_info.get('scrollable'):
        # 判断滑动方向：如果宽度大于高度*1.2，认为是水平滑动；否则垂直滑动
        if width > height * 1.2:  # 水平滚动
            if direction == 'forward':
                # 正向：向左滑动（显示右侧内容）
                from_x = right - offset
                to_x = from_x - distance
                if to_x < left:
                    to_x = left + offset
                print(f"🖱️ 执行水平滑动（向左）: ({from_x},{cy}) -> ({to_x},{cy})")
            else:
                # 反向：向右滑动（复位）
                from_x = left + offset
                to_x = from_x + distance
                if to_x > right:
                    to_x = right - offset
                print(f"🖱️ 执行水平滑动（向右复位）: ({from_x},{cy}) -> ({to_x},{cy})")
            cmd = [HDC_WINDOWS_EXE, "shell", "uitest", "uiInput", "swipe", str(from_x), str(cy), str(to_x), str(cy)]
        else:  # 垂直滚动
            if direction == 'forward':
                # 正向：向上滑动（显示下方内容）
                from_y = bottom - offset
                to_y = from_y - distance
                if to_y < top:
                    to_y = top + offset
                print(f"🖱️ 执行垂直滑动（向上）: ({cx},{from_y}) -> ({cx},{to_y})")
                cmd = [HDC_WINDOWS_EXE, "shell", "uitest", "uiInput", "swipe", str(cx), str(from_y), str(cx), str(to_y)]
            else:
                # 反向：向下滑动（复位）
                from_y = top + offset
                to_y = from_y + distance
                if to_y > bottom:
                    to_y = bottom - offset
                print(f"🖱️ 执行垂直滑动（向下复位）: ({cx},{from_y}) -> ({cx},{to_y})")
                cmd = [HDC_WINDOWS_EXE, "shell", "uitest", "uiInput", "swipe", str(cx), str(from_y), str(cx), str(to_y)]
        result = run_cmd(cmd, check=False)
        return result.returncode == 0
    else:
        # 点击操作
        cmd = [HDC_WINDOWS_EXE, "shell", "uitest", "uiInput", "click", str(cx), str(cy)]
        print(f"🖱️ 执行点击: ({cx},{cy})")
        result = run_cmd(cmd, check=False)
        return result.returncode == 0

def ensure_element_visible(elem_info, layout_path, output_dir, page_dir, depth, elem_index):
    """
    确保元素在屏幕可视区域内，如果不在则滚动其滚动容器使其可见。
    返回 (是否可见, 新的布局路径)  # 如果滚动成功，新的布局路径是滚动后的布局文件；否则原路径。
    """
    max_attempts = 5
    attempt = 0
    current_layout = layout_path

    while attempt < max_attempts:
        with open(current_layout, "r", encoding="utf-8") as f:
            data = json.load(f)

        # 获取屏幕尺寸（从根节点）
        root_attrs = data.get("attributes", {})
        screen_bounds = root_attrs.get("bounds", "")
        screen = parse_bounds(screen_bounds)
        if not screen:
            print("⚠️ 无法获取屏幕尺寸，假设元素可见")
            return True, current_layout
        screen_left, screen_top, screen_right, screen_bottom = screen

        # 查找元素当前节点
        attrs = find_node_by_id(data, elem_info['id'], elem_info['bounds'])
        if not attrs:
            print(f"⚠️ 无法在布局中找到元素 {elem_info['id']}")
            return False, current_layout
        bounds_str = attrs.get("bounds", "")
        bounds = parse_bounds(bounds_str)
        if not bounds:
            return False, current_layout
        left, top, right, bottom = bounds
        cx = (left + right) // 2
        cy = (top + bottom) // 2

        # 检查是否在屏幕内
        if screen_left <= cx <= screen_right and screen_top <= cy <= screen_bottom:
            print(f"✅ 元素 {elem_info['id']} 已在可视区域内")
            return True, current_layout

        # 需要滚动，找到包含该元素的可滚动容器
        def find_container(node, target_bounds):
            node_attrs = node.get("attributes", {})
            node_bounds = parse_bounds(node_attrs.get("bounds", ""))
            if not node_bounds:
                return None
            # 检查该节点是否包含目标元素（粗略：目标bounds在节点bounds内）
            if (node_bounds[0] <= left and node_bounds[2] >= right and
                node_bounds[1] <= top and node_bounds[3] >= bottom):
                if node_attrs.get("scrollable") == "true":
                    return node, node_bounds
                for child in node.get("children", []):
                    res = find_container(child, target_bounds)
                    if res:
                        return res
            return None

        container_info = find_container(data, bounds)
        if not container_info:
            print(f"⚠️ 未找到包含元素 {elem_info['id']} 的可滚动容器")
            return False, current_layout

        container_node, container_bounds = container_info
        cl, ct, cr, cb = container_bounds
        c_cx = (cl + cr) // 2
        c_cy = (ct + cb) // 2

        # 决定滑动方向
        if cy < screen_top:  # 元素在屏幕上方
            # 需要向下滑动（将元素拉下来）
            from_y = ct + 50
            to_y = from_y + 200
            if to_y > cb:
                to_y = cb - 50
            cmd = [HDC_WINDOWS_EXE, "shell", "uitest", "uiInput", "swipe", str(c_cx), str(from_y), str(c_cx), str(to_y)]
            print(f"🖱️ 向下滑动容器 ({c_cx},{from_y}) -> ({c_cx},{to_y}) 以显示上方元素")
        elif cy > screen_bottom:  # 元素在屏幕下方
            # 需要向上滑动（将元素拉上来）
            from_y = cb - 50
            to_y = from_y - 200
            if to_y < ct:
                to_y = ct + 50
            cmd = [HDC_WINDOWS_EXE, "shell", "uitest", "uiInput", "swipe", str(c_cx), str(from_y), str(c_cx), str(to_y)]
            print(f"🖱️ 向上滑动容器 ({c_cx},{from_y}) -> ({c_cx},{to_y}) 以显示下方元素")
        else:
            # 左右方向暂不处理（可扩展）
            print(f"⚠️ 未知滚动方向，跳过")
            return False, current_layout

        result = run_cmd(cmd, check=False)
        if result.returncode != 0:
            print("❌ 滑动命令执行失败")
            return False, current_layout
        time.sleep(1.5)  # 等待动画完成

        # 滑动后获取新布局
        temp_layout = os.path.join(output_dir, f"temp_scroll_depth{depth}_elem{elem_index}.json")
        if dump_layout(temp_layout):
            # 更新当前布局路径
            current_layout = temp_layout
        else:
            print("❌ 无法获取滑动后布局")
            return False, current_layout

        attempt += 1

    print(f"❌ 达到最大尝试次数，元素 {elem_info['id']} 仍不可见")
    return False, current_layout

def draw_markers_on_screenshot(screenshot_path, elements_with_index, output_path):
    """
    在截图基础上绘制醒目的红色圆点标注可交互组件的位置，并添加文本标签（如 elem1）。
    elements_with_index: 列表，每个元素为字典，必须包含 'bounds' 和 'index' 字段。
    """
    if not PIL_AVAILABLE:
        print("⚠️ Pillow 不可用，跳过标注图生成")
        return False
    try:
        img = Image.open(screenshot_path)
        draw = ImageDraw.Draw(img)
        radius = 12
        font_size = 20
        # 尝试加载一个好看的字体，如果失败则使用默认字体
        try:
            from PIL import ImageFont
            font = ImageFont.truetype("arial.ttf", font_size)
        except:
            font = ImageFont.load_default()
        for elem in elements_with_index:
            bounds_str = elem.get('bounds', '')
            bounds = parse_bounds(bounds_str)
            if bounds:
                left, top, right, bottom = bounds
                cx = (left + right) // 2
                cy = (top + bottom) // 2
                # 绘制红色大圆点
                draw.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), fill='red', outline='darkred', width=2)
                # 中心加小白点
                draw.ellipse((cx - 3, cy - 3, cx + 3, cy + 3), fill='white')
                # 在圆点下方添加文本
                text = f"elem{elem['index']}"
                # 计算文本尺寸以便居中
                text_bbox = draw.textbbox((0, 0), text, font=font)
                text_width = text_bbox[2] - text_bbox[0]
                text_height = text_bbox[3] - text_bbox[1]
                text_x = cx - text_width // 2
                text_y = cy + radius + 5
                draw.text((text_x, text_y), text, fill='red', font=font)
        img.save(output_path)
        print(f"✅ 标注图已保存: {output_path}")
        return True
    except Exception as e:
        print(f"❌ 生成标注图失败: {e}")
        return False

def explore_page(current_layout_path, visited_pages, depth, max_depth, output_dir, results_list, page_dir=None, retry_count=0, is_recovery=False, entry_info=None, scroll_count=0):
    """
    递归探索当前页面（分屏测试策略，带滚动位置记忆）。
    current_layout_path: 当前页面的布局文件路径（已保存的布局文件）
    visited_pages: 已访问页面的ID集合
    depth: 当前深度
    max_depth: 最大深度限制
    output_dir: 输出根目录
    results_list: 收集测试结果的列表
    page_dir: 当前页面的专用目录（若为None则自动创建）
    retry_count: 当前页面恢复尝试次数
    is_recovery: 是否为恢复调用
    entry_info: 进入当前页面所用的入口信息
    scroll_count: 当前已向下滑动的次数（用于恢复后重新定位）
    """
    MAX_RETRY = 3
    MAX_SCROLLS = 10  # 最大滑动次数，防止无限循环
    if depth > max_depth:
        print(f"⛔ 达到最大深度 {max_depth}，停止递归")
        return

    if retry_count > MAX_RETRY:
        print(f"⚠️ 页面 {current_layout_path} 恢复尝试次数过多，放弃该页面剩余测试")
        return

    # 加载当前布局
    with open(current_layout_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    page_context = get_page_context(data)
    page_id = page_context["page_id"]
    current_page_ability = page_context.get("ability_name", "")

    # å¦‚æžœä¸æ˜¯æ¢å¤è°ƒç”¨ï¼Œæ£€æŸ¥æ˜¯å¦å·²è®¿é—®è¿‡è¯¥é¡µé¢ï¼ˆé˜²æ­¢å¾ªçŽ¯ï¼‰
    if not is_recovery and page_id in visited_pages:
        print(f"â­ï¸ é¡µé¢ {page_id} å·²è®¿é—®è¿‡ï¼Œè·³è¿‡")
        return
    if not is_recovery:
        visited_pages.add(page_id)

    # ç¡®ä¿é¡µé¢ç›®å½•å­˜åœ¨ï¼ˆå¦‚æžœæœªä¼ å…¥ï¼Œåˆ™åˆ›å»ºï¼‰
    if page_dir is None:
        safe_page_id = safe_page_dir_name(page_id)
        page_dir = os.path.join(output_dir, safe_page_id)
        os.makedirs(page_dir, exist_ok=True)
        print(f"ðŸ“ åˆ›å»ºé¡µé¢ç›®å½•: {page_dir}")
    else:
        os.makedirs(page_dir, exist_ok=True)

    # 如果不是恢复模式，保存页面初始截图
    if not is_recovery:
        init_screenshot_path = os.path.join(page_dir, "init_screen.jpeg")
        if take_screenshot(init_screenshot_path):
            print(f"✅ 初始截图已保存: {init_screenshot_path}")
        else:
            print(f"❌ 初始截图失败，将无法生成标注图")

    print(f"\n📄 进入页面 {page_id} (深度 {depth})" + (" [恢复模式]" if is_recovery else ""))

    # 获取屏幕高度
    root_attrs = data.get("attributes", {})
    screen_bounds = root_attrs.get("bounds", "")
    screen = parse_bounds(screen_bounds)
    screen_height = screen[3] - screen[1] if screen else 2832
    print(f"📏 屏幕高度: {screen_height}px")

    # 查找可滚动容器（用于后续滑动）
    scroll_container = None
    scroll_container_id = None
    elements = collect_interactive_elements(data)
    for elem in elements:
        if elem.get('scrollable'):
            scroll_container = elem
            break
    if scroll_container:
        scroll_container_id = scroll_container['id']
        print(f"🔄 发现可滚动容器: {scroll_container_id}")
    else:
        print("⚠️ 未找到可滚动容器，将不会进行滑动测试")

    # 用于记录当前页面所有已发现元素的稳定键（仅针对有文本元素），避免重复测试
    all_element_keys = set()
    # 用于记录已测无文本元素的位置（用于有滚动容器时的去重）
    tested_no_text_positions = []
    position_threshold = screen_height * 0.1  # 距离阈值（屏幕高度的10%）
    text_bucket_size = max(1, int(screen_height * 0.08))

    # 待测元素队列，每个元素是 (elem_info, 来源布局路径)
    test_queue = []

    # 初始化：将当前屏幕的所有元素加入队列
    if scroll_container is None:
        # 无滚动容器：无文本元素全部加入，有文本元素去重
        for elem in elements:
            if elem.get('text'):
                key = _build_text_dedup_key(elem, text_bucket_size)
                if key not in all_element_keys:
                    all_element_keys.add(key)
                    test_queue.append((elem, current_layout_path))
            else:
                test_queue.append((elem, current_layout_path))
    else:
        # 有滚动容器：有文本元素去重，无文本元素基于位置去重
        for elem in elements:
            if elem.get('text'):
                key = _build_text_dedup_key(elem, text_bucket_size)
                if key not in all_element_keys:
                    all_element_keys.add(key)
                    test_queue.append((elem, current_layout_path))
            else:
                bounds = parse_bounds(elem['bounds'])
                if bounds:
                    cx = (bounds[0] + bounds[2]) // 2
                    cy = (bounds[1] + bounds[3]) // 2
                    is_new = True
                    for (tx, ty) in tested_no_text_positions:
                        if abs(cx - tx) < position_threshold and abs(cy - ty) < position_threshold:
                            is_new = False
                            break
                    if is_new:
                        test_queue.append((elem, current_layout_path))
                        tested_no_text_positions.append((cx, cy))

    # 如果不是恢复模式，生成初始屏幕标注图
    if not is_recovery:
        init_screenshot_path = os.path.join(page_dir, "init_screen.jpeg")
        if os.path.exists(init_screenshot_path):
            # 为标注图添加索引（1-based），注意这里用 elements（初始屏幕所有元素）进行标注
            elements_with_index = []
            for idx, elem in enumerate(elements, start=1):
                elem_copy = elem.copy()
                elem_copy['index'] = idx
                elements_with_index.append(elem_copy)
            annotated_path = os.path.join(page_dir, "init_annotated.jpeg")
            draw_markers_on_screenshot(init_screenshot_path, elements_with_index, annotated_path)
        else:
            print(f"⚠️ 未找到页面截图 {init_screenshot_path}，跳过初始标注图生成")

    # 开始测试循环
    current_layout = current_layout_path
    current_scroll_count = scroll_count  # 当前已向下滑动的次数（恢复时可能>0）
    page_elem_count = 0  # 当前页面已成功测试元素计数（用于独立编号）

    while test_queue and current_scroll_count <= MAX_SCROLLS:
        # 取出一个待测元素
        elem_info, elem_layout = test_queue.pop(0)
        elem_index = None  # 暂不分配序号，成功后再分配

        print(f"\n--- 准备测试元素: {elem_info['id']} ---")

        # 确保当前布局是最新的（可能因之前的操作而改变）
        with open(current_layout, "r", encoding="utf-8") as f:
            data = json.load(f)

        # 在当前布局中查找元素最新节点
        attrs = find_node_by_id(data, elem_info['id'], elem_info.get('bounds'), elem_info.get('type'), elem_info.get('text'))
        if not attrs:
            print(f"⚠️ 无法在布局中找到元素 {elem_info['id']}，跳过")
            continue

        # 获取最新 bounds 并更新 elem_info
        bounds_str = attrs.get("bounds", "")
        bounds = parse_bounds(bounds_str)
        if not bounds:
            print(f"⚠️ 无法解析元素 {elem_info['id']} 的 bounds，跳过")
            continue
        elem_info['bounds'] = bounds_str

        # 确保元素在可视区域内（可能会更新 current_layout）
        visible, new_layout = ensure_element_visible(elem_info, current_layout, output_dir, page_dir, depth, page_elem_count+1)
        if not visible:
            print(f"❌ 元素 {elem_info['id']} 无法显示，跳过测试")
            continue
        if new_layout != current_layout:
            current_layout = new_layout
            # 重新获取元素最新 bounds
            with open(current_layout, "r", encoding="utf-8") as f:
                data = json.load(f)
            attrs = find_node_by_id(data, elem_info['id'], elem_info.get('bounds'), elem_info.get('type'), elem_info.get('text'))
            if attrs:
                elem_info['bounds'] = attrs.get("bounds", "")
            else:
                print(f"⚠️ 元素 {elem_info['id']} 在滚动后丢失，跳过")
                continue

        # 至此，元素可测试，分配序号
        page_elem_count += 1
        elem_index = page_elem_count
        print(f"--- 测试元素 {elem_index}: {elem_info['id']} ---")

        # 为当前元素创建子目录
        elem_dir = os.path.join(page_dir, f"elem{elem_index}")
        os.makedirs(elem_dir, exist_ok=True)

        # 操作前先落盘当前页面证据（layout + screenshot），后续仅基于 before/after 对比过滤
        before_layout_path = os.path.join(elem_dir, "before_layout.json")
        before_click_screenshot = os.path.join(elem_dir, "before.jpeg")
        if not dump_layout(before_layout_path):
            print("❌ 无法获取操作前布局，跳过该元素")
            if os.path.isdir(elem_dir):
                shutil.rmtree(elem_dir, ignore_errors=True)
            page_elem_count -= 1
            continue
        take_screenshot(before_click_screenshot)

        with open(before_layout_path, "r", encoding="utf-8") as f:
            before_data = json.load(f)

        # 执行操作（正向）
        op_success = perform_action(elem_info, before_layout_path, direction='forward')
        time.sleep(2)

        # 操作后截图
        after_click_screenshot = os.path.join(elem_dir, "after.jpeg")
        take_screenshot(after_click_screenshot)

        # 如果是滑动元素，立即复位
        if elem_info.get('scrollable'):
            print("↩️ 复位滚动位置...")
            reset_success = perform_action(elem_info, current_layout, direction='backward')
            time.sleep(1)
            if reset_success:
                print("✅ 滚动位置已复位")
            else:
                print("⚠️ 滚动位置复位失败")

        # 获取操作后布局（用于判断页面变化）
        after_layout_path = os.path.join(elem_dir, "after_layout.json")
        after_page_id = None
        after_page_context = None
        after_data = None
        new_page_dir = None
        new_layout_path = None

        if not dump_layout(after_layout_path):
            print("âŒ æ— æ³•èŽ·å–æ“ä½œåŽå¸ƒå±€")
        else:
            with open(after_layout_path, "r", encoding="utf-8") as f:
                after_data = json.load(f)
            after_page_context = get_page_context(after_data)
            after_page_id = after_page_context["page_id"]
            if after_page_id != page_id and after_page_id not in visited_pages:
                new_page_dir = os.path.join(output_dir, safe_page_dir_name(after_page_id))
                os.makedirs(new_page_dir, exist_ok=True)
                new_layout_path = os.path.join(new_page_dir, "layout.json")
                shutil.copy2(after_layout_path, new_layout_path)

        # 过滤无效点击：忽略系统状态栏后，before/after 主布局无变化则跳过。
        if after_data is not None and _is_layout_effectively_same(before_data, after_data):
            print(f"⏭️ 跳过无效点击（主布局无变化）: {elem_info['id']}")
            if os.path.isdir(elem_dir):
                shutil.rmtree(elem_dir, ignore_errors=True)
            page_elem_count -= 1
            continue

        page_changed = (after_page_id != page_id) if after_page_id else False

        element_snapshot = json.loads(json.dumps(elem_info, ensure_ascii=False))
        result_item = {
            'depth': depth,
            'timestamp': datetime.now().isoformat(timespec='seconds'),
            'page_before': page_id,
            'page_before_context': page_context,
            'element_index': elem_index,
            'element': element_snapshot,
            'action_type': 'scroll' if elem_info.get('scrollable') else 'click',
            'action_success': op_success,
            'page_after': after_page_id,
            'page_after_context': after_page_context,
            'page_changed': page_changed,
            'return_success': None,
            'evidence': {
                'element_dir': elem_dir,
                'before_layout': before_layout_path,
                'before_screenshot': before_click_screenshot,
                'after_screenshot': after_click_screenshot,
                'after_layout': after_layout_path if os.path.exists(after_layout_path) else None,
                'source_layout': current_layout,
                'new_page_layout': new_layout_path
            }
        }
        results_list.append(result_item)

        if page_changed:
            if after_page_id not in visited_pages:
                # 跳转到新页面，递归进入，传递当前滚动次数（子页面不关心，但保持参数一致）
                explore_page(new_layout_path, visited_pages, depth+1, max_depth, output_dir, results_list,
                             page_dir=new_page_dir, entry_info={'parent_page_id': page_id, 'element': elem_info, 'parent_layout_path': current_layout},
                             scroll_count=0)  # 新页面初始滚动次数为0

                # 从新页面返回原页面
                print("🔙 尝试返回原页面...")
                go_back()
                time.sleep(2)

                # 返回后截图
                after_return_screenshot = os.path.join(elem_dir, "return.jpeg")
                take_screenshot(after_return_screenshot)

                # éªŒè¯è¿”å›žæ˜¯å¦æˆåŠŸ
                return_layout_path = os.path.join(elem_dir, "return_layout.json")
                result_item["evidence"]["return_screenshot"] = after_return_screenshot
                result_item["evidence"]["return_layout"] = return_layout_path

                return_success = False
                if dump_layout(return_layout_path):
                    with open(return_layout_path, "r", encoding="utf-8") as f:
                        check_data = json.load(f)
                    current_page_id = get_page_id(check_data)
                    if current_page_id == page_id:
                        return_success = True
                        print("âœ… æˆåŠŸè¿”å›žåŽŸé¡µé¢")
                    else:
                        print(f"âŒ è¿”å›žå¤±è´¥ï¼Œå½“å‰é¡µé¢ {current_page_id}ï¼ŒæœŸæœ› {page_id}")
                else:
                    print("âš ï¸ æ— æ³•èŽ·å–è¿”å›žåŽå¸ƒå±€ï¼Œå‡å®šè¿”å›žå¤±è´¥")

                # æ›´æ–°ç»“æžœé¡¹çš„è¿”å›žæˆåŠŸå­—æ®µ
                for item in reversed(results_list):
                    if item['page_changed'] and item['return_success'] is None and item['page_before'] == page_id and item['page_after'] == after_page_id:
                        item['return_success'] = return_success
                        break

                # 如果返回失败，尝试恢复
                if not return_success:
                    print("🔄 返回失败，尝试恢复状态...")
                    restart_app(bundle_name, ability_name)
                    time.sleep(3)

                    # 尝试重新进入当前页面
                    if current_page_ability:
                        run_cmd([HDC_WINDOWS_EXE, "shell", "aa", "start", "-b", bundle_name, "-a", current_page_ability], check=False)
                        time.sleep(3)
                    else:
                        restart_app(bundle_name, ability_name)

                    # 获取新的布局，保存在页面目录
                    recovery_layout = os.path.join(page_dir, f"recovery_layout.json")
                    if dump_layout(recovery_layout):
                        with open(recovery_layout, "r", encoding="utf-8") as f:
                            new_data = json.load(f)
                        new_page_id = get_page_id(new_data)
                        if new_page_id == page_id:
                            print("✅ 成功恢复页面状态，准备重新定位到之前屏幕...")
                            # 重新滑动到之前记录的次数
                            if scroll_container and current_scroll_count > 0:
                                print(f"↩️ 重新执行 {current_scroll_count} 次正向滑动，以回到之前位置")
                                for s in range(current_scroll_count):
                                    # 执行一次向下滑动（整屏）
                                    with open(recovery_layout, "r", encoding="utf-8") as f:
                                        data = json.load(f)
                                    container_attrs = find_node_by_id(data, scroll_container['id'], scroll_container.get('bounds'), scroll_container.get('type'), scroll_container.get('text'))
                                    if container_attrs:
                                        container_bounds = parse_bounds(container_attrs.get("bounds", ""))
                                        if container_bounds:
                                            cl, ct, cr, cb = container_bounds
                                            container_center_x = (cl + cr) // 2
                                        else:
                                            container_center_x = 500
                                            ct, cb = 0, screen_height
                                    else:
                                        container_center_x = 500
                                        ct, cb = 0, screen_height
                                    scroll_distance = int(screen_height * 0.8)
                                    from_y = cb - 50
                                    to_y = from_y - scroll_distance
                                    if to_y < ct:
                                        to_y = ct + 50
                                    cmd = [HDC_WINDOWS_EXE, "shell", "uitest", "uiInput", "swipe", str(container_center_x), str(from_y), str(container_center_x), str(to_y)]
                                    run_cmd(cmd, check=False)
                                    time.sleep(2)
                                    # 每次滑动后更新布局，临时文件放入页面目录
                                    temp_scroll_layout = os.path.join(page_dir, f"recovery_scroll_{s+1}.json")
                                    if dump_layout(temp_scroll_layout):
                                        recovery_layout = temp_scroll_layout
                                    else:
                                        print("❌ 滑动后无法获取布局，恢复失败")
                                        return
                                print("✅ 已滑动到之前屏幕位置")
                            # 使用恢复后的布局作为当前布局，继续测试下一个元素
                            current_layout = recovery_layout
                            # 继续循环（下一个元素）
                            continue
                        else:
                            print(f"❌ 恢复失败，当前页面 {new_page_id}，期望 {page_id}")
                            return
                    else:
                        print("❌ 无法获取恢复后布局，放弃当前页面测试")
                        return
            else:
                # 跳转到已访问页面（通常是父页）
                print(f"↩️ 元素 {elem_index} 跳转至已访问页面 {after_page_id}（可能是返回操作）")
                # 如果当前页面还有剩余元素，先尝试返回原页面
                if test_queue:
                    print(f"当前页面还有 {len(test_queue)} 个元素未测试，尝试返回原页面...")
                    go_back()
                    time.sleep(2)

                    # 验证返回，临时布局放入页面目录
                    return_from_visited_layout = os.path.join(elem_dir, "return_from_visited_layout.json")
                    if dump_layout(return_from_visited_layout):
                        with open(return_from_visited_layout, "r", encoding="utf-8") as f:
                            return_data = json.load(f)
                        returned_page_id = get_page_id(return_data)
                        if returned_page_id == page_id:
                            print("✅ 成功返回原页面，继续测试下一个元素")
                            current_layout = return_from_visited_layout
                            continue
                        else:
                            print(f"❌ 返回失败，当前页面 {returned_page_id}，期望 {page_id}")
                            # 返回失败，尝试恢复
                            print("🔄 返回失败，尝试恢复状态...")
                            restart_app(bundle_name, ability_name)
                            time.sleep(3)
                            # 重新进入当前页面
                            if current_page_ability:
                                run_cmd([HDC_WINDOWS_EXE, "shell", "aa", "start", "-b", bundle_name, "-a", current_page_ability], check=False)
                                time.sleep(3)
                            else:
                                restart_app(bundle_name, ability_name)
                            recovery_layout = os.path.join(page_dir, f"recovery_from_visited.json")
                            if dump_layout(recovery_layout):
                                with open(recovery_layout, "r", encoding="utf-8") as f:
                                    new_data = json.load(f)
                                new_page_id = get_page_id(new_data)
                                if new_page_id == page_id:
                                    print("✅ 成功恢复页面状态，准备重新定位到之前屏幕...")
                                    if scroll_container and current_scroll_count > 0:
                                        print(f"↩️ 重新执行 {current_scroll_count} 次正向滑动，以回到之前位置")
                                        for s in range(current_scroll_count):
                                            with open(recovery_layout, "r", encoding="utf-8") as f:
                                                data = json.load(f)
                                            container_attrs = find_node_by_id(data, scroll_container['id'], scroll_container.get('bounds'), scroll_container.get('type'), scroll_container.get('text'))
                                            if container_attrs:
                                                container_bounds = parse_bounds(container_attrs.get("bounds", ""))
                                                if container_bounds:
                                                    cl, ct, cr, cb = container_bounds
                                                    container_center_x = (cl + cr) // 2
                                                else:
                                                    container_center_x = 500
                                                    ct, cb = 0, screen_height
                                            else:
                                                container_center_x = 500
                                                ct, cb = 0, screen_height
                                            scroll_distance = int(screen_height * 0.8)
                                            from_y = cb - 50
                                            to_y = from_y - scroll_distance
                                            if to_y < ct:
                                                to_y = ct + 50
                                            cmd = [HDC_WINDOWS_EXE, "shell", "uitest", "uiInput", "swipe", str(container_center_x), str(from_y), str(container_center_x), str(to_y)]
                                            run_cmd(cmd, check=False)
                                            time.sleep(2)
                                            temp_scroll_layout = os.path.join(page_dir, f"recovery_scroll_{s+1}.json")
                                            if dump_layout(temp_scroll_layout):
                                                recovery_layout = temp_scroll_layout
                                            else:
                                                print("❌ 滑动后无法获取布局，恢复失败")
                                                return
                                    print("✅ 已滑动到之前屏幕位置")
                                    current_layout = recovery_layout
                                    continue
                                else:
                                    print(f"❌ 恢复失败，当前页面 {new_page_id}，放弃测试")
                                    return
                            else:
                                print("❌ 无法获取恢复后布局，放弃当前页面测试")
                                return
                    else:
                        print("⚠️ 无法获取返回后布局，假定返回失败，尝试恢复...")
                        restart_app(bundle_name, ability_name)
                        time.sleep(3)
                        recovery_layout = os.path.join(page_dir, f"recovery_from_visited.json")
                        if dump_layout(recovery_layout):
                            with open(recovery_layout, "r", encoding="utf-8") as f:
                                new_data = json.load(f)
                            new_page_id = get_page_id(new_data)
                            if new_page_id == page_id:
                                print("✅ 成功恢复页面状态，准备重新定位到之前屏幕...")
                                if scroll_container and current_scroll_count > 0:
                                    print(f"↩️ 重新执行 {current_scroll_count} 次正向滑动，以回到之前位置")
                                    for s in range(current_scroll_count):
                                        with open(recovery_layout, "r", encoding="utf-8") as f:
                                            data = json.load(f)
                                        container_attrs = find_node_by_id(data, scroll_container['id'], scroll_container.get('bounds'), scroll_container.get('type'), scroll_container.get('text'))
                                        if container_attrs:
                                            container_bounds = parse_bounds(container_attrs.get("bounds", ""))
                                            if container_bounds:
                                                cl, ct, cr, cb = container_bounds
                                                container_center_x = (cl + cr) // 2
                                            else:
                                                container_center_x = 500
                                                ct, cb = 0, screen_height
                                        else:
                                            container_center_x = 500
                                            ct, cb = 0, screen_height
                                        scroll_distance = int(screen_height * 0.8)
                                        from_y = cb - 50
                                        to_y = from_y - scroll_distance
                                        if to_y < ct:
                                            to_y = ct + 50
                                        cmd = [HDC_WINDOWS_EXE, "shell", "uitest", "uiInput", "swipe", str(container_center_x), str(from_y), str(container_center_x), str(to_y)]
                                        run_cmd(cmd, check=False)
                                        time.sleep(2)
                                        temp_scroll_layout = os.path.join(page_dir, f"recovery_scroll_{s+1}.json")
                                        if dump_layout(temp_scroll_layout):
                                            recovery_layout = temp_scroll_layout
                                        else:
                                            print("❌ 滑动后无法获取布局，恢复失败")
                                            return
                                print("✅ 已滑动到之前屏幕位置")
                                current_layout = recovery_layout
                                continue
                            else:
                                print(f"❌ 恢复失败，当前页面 {new_page_id}，放弃测试")
                                return
                        else:
                            print("❌ 无法获取恢复后布局，放弃当前页面测试")
                            return
                else:
                    print("当前页面元素已全部测试完毕，无需返回")
                    return

        # 如果当前元素测试完毕且未跳转，继续下一个元素

        # 检查是否还有剩余元素，如果没有且可以滑动，则滑动加载新屏幕
        if not test_queue and scroll_container and current_scroll_count < MAX_SCROLLS:
            print("🔄 当前屏幕元素已测试完，尝试滑动到下一屏幕...")
            # 执行向下滑动一整屏（距离为屏幕高度的80%）
            with open(current_layout, "r", encoding="utf-8") as f:
                data = json.load(f)
            container_attrs = find_node_by_id(data, scroll_container['id'], scroll_container.get('bounds'), scroll_container.get('type'), scroll_container.get('text'))
            if container_attrs:
                container_bounds = parse_bounds(container_attrs.get("bounds", ""))
                if container_bounds:
                    cl, ct, cr, cb = container_bounds
                    container_center_x = (cl + cr) // 2
                else:
                    container_center_x = 500
                    ct, cb = 0, screen_height
            else:
                container_center_x = 500
                ct, cb = 0, screen_height

            scroll_distance = int(screen_height * 0.8)  # 滑动屏幕高度的80%
            from_y = cb - 50
            to_y = from_y - scroll_distance
            if to_y < ct:
                to_y = ct + 50
            cmd = [HDC_WINDOWS_EXE, "shell", "uitest", "uiInput", "swipe", str(container_center_x), str(from_y), str(container_center_x), str(to_y)]
            run_cmd(cmd, check=False)
            time.sleep(2)  # 等待滑动动画

            # 为新屏幕截图
            screen_shot_path = os.path.join(page_dir, f"scroll_{current_scroll_count+1}_screen.jpeg")
            take_screenshot(screen_shot_path)

            # 获取新布局，保存到页面目录
            new_layout = os.path.join(page_dir, f"scroll_{current_scroll_count+1}.json")
            if not dump_layout(new_layout):
                print("❌ 无法获取滑动后布局，停止滑动")
                break

            # 从新布局中提取元素（用于后续测试和标注）
            with open(new_layout, "r", encoding="utf-8") as f:
                new_data = json.load(f)
            new_elements = collect_interactive_elements(new_data)

            # 为新屏幕生成标注图
            if new_elements:
                elements_with_index = []
                for idx, ne in enumerate(new_elements, start=1):
                    ne_copy = ne.copy()
                    ne_copy['index'] = idx
                    elements_with_index.append(ne_copy)
                annotated_path = os.path.join(page_dir, f"scroll_{current_scroll_count+1}_annotated.jpeg")
                draw_markers_on_screenshot(screen_shot_path, elements_with_index, annotated_path)

            # 将新元素中未出现过的加入待测队列（根据是否有滚动容器决定去重策略）
            new_count = 0
            if scroll_container is None:
                # 无滚动容器，全部加入
                for ne in new_elements:
                    if ne.get('text'):
                        key = _build_text_dedup_key(ne, text_bucket_size)
                        if key not in all_element_keys:
                            all_element_keys.add(key)
                            test_queue.append((ne, new_layout))
                            new_count += 1
                    else:
                        test_queue.append((ne, new_layout))
                        new_count += 1
            else:
                # 有滚动容器，有文本去重，无文本基于位置去重
                for ne in new_elements:
                    if ne.get('text'):
                        key = _build_text_dedup_key(ne, text_bucket_size)
                        if key not in all_element_keys:
                            all_element_keys.add(key)
                            test_queue.append((ne, new_layout))
                            new_count += 1
                    else:
                        bounds = parse_bounds(ne['bounds'])
                        if bounds:
                            cx = (bounds[0] + bounds[2]) // 2
                            cy = (bounds[1] + bounds[3]) // 2
                            is_new = True
                            for (tx, ty) in tested_no_text_positions:
                                if abs(cx - tx) < position_threshold and abs(cy - ty) < position_threshold:
                                    is_new = False
                                    break
                            if is_new:
                                test_queue.append((ne, new_layout))
                                tested_no_text_positions.append((cx, cy))
                                new_count += 1

            print(f"📱 新屏幕发现 {new_count} 个新元素，加入测试队列")
            if new_count == 0:
                print("⚠️ 无新元素，停止滑动")
                break

            # 更新当前布局和新布局
            current_layout = new_layout
            current_scroll_count += 1
        elif not test_queue:
            print("✅ 所有屏幕元素测试完成")
            break

def generate_report(results, report_path):
    """生成分层测试报告，包含页面跳转路径"""
    lines = []
    lines.append("=" * 80)
    lines.append("UI 自动化测试报告 - 深度遍历测试（分层统计）")
    lines.append(f"生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    lines.append(f"应用包名: {bundle_name}")
    lines.append("=" * 80)

    # 按深度和页面ID分组
    page_groups = defaultdict(list)  # key: (depth, page_id)
    for r in results:
        key = (r['depth'], r['page_before'])
        page_groups[key].append(r)

    # 总体统计
    total_tests = len(results)
    success_actions = sum(1 for r in results if r['action_success'])
    total_jumps = sum(1 for r in results if r['page_changed'])
    total_returns = sum(1 for r in results if r['return_success'] is not None and r['return_success'])
    total_return_attempts = sum(1 for r in results if r['return_success'] is not None)

    lines.append(f"\n📊 总体统计")
    lines.append(f"测试元素总数: {total_tests}")
    
    # 修复除零错误：先判断 total_tests 是否大于 0
    if total_tests > 0:
        lines.append(f"操作成功数: {success_actions} ({success_actions/total_tests*100:.1f}%)")
    else:
        lines.append(f"操作成功数: 0 (0.0%)")
        
    lines.append(f"触发页面跳转数: {total_jumps}")
    lines.append(f"\n📊 总体统计")
    lines.append(f"测试元素总数: {total_tests}")
    lines.append(f"操作成功数: {success_actions} ({success_actions/total_tests*100:.1f}%)")
    lines.append(f"触发页面跳转数: {total_jumps}")
    if total_return_attempts > 0:
        lines.append(f"返回成功数: {total_returns} ({total_returns/total_return_attempts*100:.1f}%)")
    else:
        lines.append(f"返回成功数: 0 (无跳转测试)")

    # 按页面分层统计
    lines.append("\n" + "=" * 80)
    lines.append("📂 按页面分层统计")
    sorted_keys = sorted(page_groups.keys())
    for depth, page_id in sorted_keys:
        group = page_groups[(depth, page_id)]
        page_tests = len(group)
        page_success = sum(1 for r in group if r['action_success'])
        page_jumps = sum(1 for r in group if r['page_changed'])
        page_returns_attempts = sum(1 for r in group if r['return_success'] is not None)
        page_returns_success = sum(1 for r in group if r['return_success'] is not None and r['return_success'])

        level = "一级页面" if depth == 0 else f"{depth+1}级页面"
        lines.append(f"\n--- {level}: {page_id} ---")
        lines.append(f"  元素总数: {page_tests}")
        lines.append(f"  操作成功: {page_success} ({page_success/page_tests*100:.1f}%)")
        lines.append(f"  跳转次数: {page_jumps}")
        if page_returns_attempts > 0:
            lines.append(f"  返回成功率: {page_returns_success}/{page_returns_attempts} ({page_returns_success/page_returns_attempts*100:.1f}%)")
        if page_tests <= 20:
            for i, r in enumerate(group, 1):
                elem = r['element']
                status = "✅" if r['action_success'] else "❌"
                jump = "↪️" if r['page_changed'] else ""
                lines.append(f"    {i}. {elem['id']} {status} {jump}")
        else:
            lines.append(f"   (共 {page_tests} 个元素，列表省略)")

    # 页面跳转路径记录
    lines.append("\n" + "=" * 80)
    lines.append("🔗 页面跳转路径记录")
    jumps = [r for r in results if r['page_changed'] and r['page_after'] is not None]
    if jumps:
        seen = set()
        unique_jumps = []
        for j in jumps:
            key = (j['page_before'], j['page_after'], j['element']['id'])
            if key not in seen:
                seen.add(key)
                unique_jumps.append(j)
        lines.append(f"共 {len(unique_jumps)} 条独特跳转路径：")
        for i, j in enumerate(unique_jumps, 1):
            elem = j['element']
            elem_desc = elem['id']
            if elem.get('text'):
                elem_desc += f" (文本: {elem['text']})"
            lines.append(f"  {i}. {j['page_before']} → {j['page_after']}  [触发元素: {elem_desc}]")
    else:
        lines.append("无页面跳转发生。")

    lines.append("\n" + "=" * 80)
    with open(report_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print(f"📄 测试报告已保存: {report_path}")

def build_transition_records(results):
    transitions = []
    for item in results:
        if not item.get("page_changed"):
            continue

        element = item.get("element", {})
        transitions.append({
            "depth": item.get("depth"),
            "timestamp": item.get("timestamp"),
            "from_page": item.get("page_before"),
            "to_page": item.get("page_after"),
            "from_page_context": item.get("page_before_context"),
            "to_page_context": item.get("page_after_context"),
            "trigger": {
                "element_index": item.get("element_index"),
                "id": element.get("id"),
                "type": element.get("type"),
                "text": element.get("text"),
                "bounds": element.get("bounds"),
                "action_type": item.get("action_type"),
                "action_success": item.get("action_success")
            },
            "return_success": item.get("return_success"),
            "evidence": item.get("evidence", {})
        })
    return transitions


def write_detailed_outputs(results, output_dir, report_path, max_depth):
    transitions = build_transition_records(results)

    page_stats = defaultdict(lambda: {
        "actions": 0,
        "success_actions": 0,
        "jump_actions": 0,
        "return_attempts": 0,
        "return_successes": 0
    })

    for item in results:
        page_key = item.get("page_before") or "<unknown>"
        stats = page_stats[page_key]
        stats["actions"] += 1
        if item.get("action_success"):
            stats["success_actions"] += 1
        if item.get("page_changed"):
            stats["jump_actions"] += 1
        if item.get("return_success") is not None:
            stats["return_attempts"] += 1
            if item.get("return_success"):
                stats["return_successes"] += 1

    output_payload = {
        "generated_at": datetime.now().isoformat(timespec="seconds"),
        "bundle_name": bundle_name,
        "entry_ability": ability_name,
        "max_depth": max_depth,
        "report_path": report_path,
        "total_actions": len(results),
        "total_transitions": len(transitions),
        "page_stats": dict(page_stats),
        "results": results,
        "transitions": transitions
    }

    detailed_path = os.path.join(output_dir, "review_detailed_output.json")
    with open(detailed_path, "w", encoding="utf-8") as f:
        json.dump(output_payload, f, ensure_ascii=False, indent=2)

    transitions_path = os.path.join(output_dir, "jump_transition_candidates.json")
    with open(transitions_path, "w", encoding="utf-8") as f:
        json.dump(transitions, f, ensure_ascii=False, indent=2)

    print(f"📄 详细结果已保存: {detailed_path}")
    print(f"📄 跳转候选已保存: {transitions_path}")
    return detailed_path, transitions_path


def _load_json(path: str) -> Any:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def _normalize_page_path(raw_value: Any) -> str:
    text = str(raw_value or "").strip()
    if not text:
        return ""
    text = text.replace("\\", "/")
    if "page=" in text:
        text = text.split("page=", 1)[1]
    text = text.strip().strip("/")
    if text.startswith("pages/"):
        text = text[len("pages/"):]
    return text.strip("/")


def _leaf_page_name(raw_value: Any) -> str:
    normalized = _normalize_page_path(raw_value)
    if not normalized:
        return ""
    return normalized.split("/")[-1]


def _normalize_trigger_text(raw_value: Any) -> str:
    text = str(raw_value or "").strip().lower()
    if not text:
        return ""
    return re.sub(r"\s+", "", text)


def _first_non_empty(values: List[Any]) -> str:
    for value in values:
        text = str(value or "").strip()
        if text:
            return text
    return ""


def _walk_ui_nodes(node: Any, path_parts: Optional[List[Any]] = None):
    if not isinstance(node, dict):
        return
    current_path = list(path_parts or [])
    yield node, current_path

    children = node.get("children", [])
    if isinstance(children, list):
        for idx, child in enumerate(children):
            child_path = current_path + [idx]
            yield from _walk_ui_nodes(child, child_path)

    overlay = node.get("overlay")
    if isinstance(overlay, dict):
        overlay_path = current_path + ["overlay"]
        yield from _walk_ui_nodes(overlay, overlay_path)


def _format_node_path(path_parts: List[Any]) -> str:
    if not path_parts:
        return "root"
    return "/".join(str(part) for part in path_parts)


def _extract_expected_jump_actions(architect_payload: Dict[str, Any]) -> List[Dict[str, Any]]:
    final_state = architect_payload.get("final_state", {}) if isinstance(architect_payload, dict) else {}
    extracted_ui_data = final_state.get("extracted_ui_data", [])
    if not isinstance(extracted_ui_data, list):
        return []

    expected_actions: List[Dict[str, Any]] = []
    for page in extracted_ui_data:
        if not isinstance(page, dict):
            continue

        source_folder = str(page.get("source_folder", "")).strip()
        source_page = _leaf_page_name(source_folder)
        father_folder = str(page.get("father_folder", "")).strip()
        children_folders = page.get("children_folders", [])
        ui_tree = page.get("ui_tree", {})

        for node, node_path in _walk_ui_nodes(ui_tree):
            jump_action = node.get("jump_action")
            if not isinstance(jump_action, dict):
                continue

            target_folder = str(jump_action.get("target_folder", "")).strip()
            target_page = _leaf_page_name(target_folder)
            trigger_text = _first_non_empty([
                jump_action.get("trigger_text"),
                node.get("text"),
                node.get("name"),
                node.get("description"),
            ])
            action_type = str(jump_action.get("action_type", "")).strip()

            expected_actions.append({
                "expected_id": f"E{len(expected_actions) + 1:03d}",
                "source_folder": source_folder,
                "source_page": source_page,
                "target_folder": target_folder,
                "target_page": target_page,
                "action_type": action_type,
                "trigger_text": trigger_text,
                "trigger_key": _normalize_trigger_text(trigger_text),
                "source_father_folder": father_folder,
                "source_children_folders": children_folders if isinstance(children_folders, list) else [],
                "node_path": _format_node_path(node_path),
                "node_snapshot": {
                    "type": node.get("type"),
                    "name": node.get("name"),
                    "text": node.get("text"),
                    "description": node.get("description"),
                    "bound_data_field": node.get("bound_data_field"),
                },
                "jump_action_raw": jump_action
            })
    return expected_actions


def _extract_text_from_trigger_id(trigger_id: Any) -> str:
    text = str(trigger_id or "").strip()
    if text.startswith("text:"):
        return text[len("text:"):].strip()
    return ""


def _extract_observed_jump_actions(transitions_payload: Any) -> List[Dict[str, Any]]:
    transitions: List[Dict[str, Any]] = []
    if isinstance(transitions_payload, dict):
        raw_transitions = transitions_payload.get("transitions", [])
    elif isinstance(transitions_payload, list):
        raw_transitions = transitions_payload
    else:
        raw_transitions = []

    if not isinstance(raw_transitions, list):
        return []

    for item in raw_transitions:
        if not isinstance(item, dict):
            continue

        from_context = item.get("from_page_context", {})
        to_context = item.get("to_page_context", {})
        trigger = item.get("trigger", {})
        if not isinstance(from_context, dict):
            from_context = {}
        if not isinstance(to_context, dict):
            to_context = {}
        if not isinstance(trigger, dict):
            trigger = {}

        source_path = _first_non_empty([
            from_context.get("page_path"),
            item.get("from_page")
        ])
        target_path = _first_non_empty([
            to_context.get("page_path"),
            item.get("to_page")
        ])

        trigger_text = _first_non_empty([
            trigger.get("text"),
            _extract_text_from_trigger_id(trigger.get("id"))
        ])
        action_type = str(trigger.get("action_type", "")).strip()

        transitions.append({
            "observed_id": f"O{len(transitions) + 1:03d}",
            "source_path": source_path,
            "source_page": _leaf_page_name(source_path),
            "target_path": target_path,
            "target_page": _leaf_page_name(target_path),
            "trigger_id": trigger.get("id"),
            "trigger_type": trigger.get("type"),
            "trigger_text": trigger_text,
            "trigger_key": _normalize_trigger_text(trigger_text),
            "trigger_bounds": trigger.get("bounds"),
            "action_type": action_type,
            "action_success": trigger.get("action_success"),
            "depth": item.get("depth"),
            "timestamp": item.get("timestamp"),
            "evidence": item.get("evidence", {}),
        })
    return transitions


def _select_best_observed_index(
    expected_item: Dict[str, Any],
    candidate_indices: List[int],
    observed_actions: List[Dict[str, Any]]
) -> Optional[int]:
    if not candidate_indices:
        return None

    def _score(index: int) -> Tuple[int, int]:
        observed = observed_actions[index]
        score = 0
        trigger_match = 0

        expected_trigger = expected_item.get("trigger_key", "")
        observed_trigger = observed.get("trigger_key", "")
        if expected_trigger and observed_trigger and expected_trigger == observed_trigger:
            score += 3
            trigger_match = 1
        elif not expected_trigger:
            score += 1

        expected_action = str(expected_item.get("action_type", "")).strip().lower()
        observed_action = str(observed.get("action_type", "")).strip().lower()
        if expected_action and observed_action and expected_action == observed_action:
            score += 1
        return score, trigger_match

    return sorted(candidate_indices, key=_score, reverse=True)[0]


def compare_jump_actions(
    architect_output_path: str,
    transitions_path: str,
    output_dir: str
) -> Tuple[Optional[str], Optional[str]]:
    if not os.path.exists(architect_output_path):
        print(f"?? architect ???????? jump_action ??: {architect_output_path}")
        return None, None
    if not os.path.exists(transitions_path):
        print(f"?? review transitions ?????? jump_action ??: {transitions_path}")
        return None, None

    architect_payload = _load_json(architect_output_path)
    transitions_payload = _load_json(transitions_path)
    expected_actions = _extract_expected_jump_actions(architect_payload)
    observed_actions = _extract_observed_jump_actions(transitions_payload)

    unmatched_observed_indices = set(range(len(observed_actions)))
    matched: List[Dict[str, Any]] = []
    wrong_target: List[Dict[str, Any]] = []
    missing: List[Dict[str, Any]] = []

    pending_expected: List[Dict[str, Any]] = []
    for expected_item in expected_actions:
        source_page = expected_item.get("source_page", "")
        target_page = expected_item.get("target_page", "")
        direct_candidates = [
            idx for idx in unmatched_observed_indices
            if observed_actions[idx].get("source_page") == source_page
            and observed_actions[idx].get("target_page") == target_page
        ]
        best_idx = _select_best_observed_index(expected_item, direct_candidates, observed_actions)
        if best_idx is not None:
            matched.append({
                "expected": expected_item,
                "observed": observed_actions[best_idx]
            })
            unmatched_observed_indices.remove(best_idx)
        else:
            pending_expected.append(expected_item)

    for expected_item in pending_expected:
        source_page = expected_item.get("source_page", "")
        expected_trigger = expected_item.get("trigger_key", "")
        same_source_candidates = [
            idx for idx in unmatched_observed_indices
            if observed_actions[idx].get("source_page") == source_page
        ]

        wrong_idx = None
        if expected_trigger:
            exact_trigger_candidates = [
                idx for idx in same_source_candidates
                if observed_actions[idx].get("trigger_key") == expected_trigger
            ]
            if exact_trigger_candidates:
                wrong_idx = exact_trigger_candidates[0]

        if wrong_idx is not None:
            wrong_target.append({
                "expected": expected_item,
                "observed": observed_actions[wrong_idx],
                "reason": "same source page and trigger, but target mismatch"
            })
            unmatched_observed_indices.remove(wrong_idx)
        else:
            missing.append({
                "expected": expected_item,
                "reason": "no matching observed transition"
            })

    extra = [
        {"observed": observed_actions[idx], "reason": "not declared in architect jump_action"}
        for idx in sorted(unmatched_observed_indices)
    ]

    expected_edges = sorted({
        f"{item.get('source_page', '<unknown>')} -> {item.get('target_page', '<unknown>')}"
        for item in expected_actions
    })
    observed_edges = sorted({
        f"{item.get('source_page', '<unknown>')} -> {item.get('target_page', '<unknown>')}"
        for item in observed_actions
    })

    diff_payload = {
        "generated_at": datetime.now().isoformat(timespec="seconds"),
        "architect_output_path": os.path.abspath(architect_output_path),
        "review_transitions_path": os.path.abspath(transitions_path),
        "summary": {
            "expected_actions": len(expected_actions),
            "observed_transitions": len(observed_actions),
            "matched": len(matched),
            "missing": len(missing),
            "wrong_target": len(wrong_target),
            "extra": len(extra)
        },
        "matching_rules": [
            "match by source_page + target_page first",
            "if no direct match, detect wrong target by source_page + trigger_text",
            "trigger match uses normalized text (lowercase, no spaces)",
            "no hash-based matching is used"
        ],
        "edge_summary": {
            "expected_edges": expected_edges,
            "observed_edges": observed_edges,
            "missing_edges": sorted(list(set(expected_edges) - set(observed_edges))),
            "extra_edges": sorted(list(set(observed_edges) - set(expected_edges)))
        },
        "matched": matched,
        "missing": missing,
        "wrong_target": wrong_target,
        "extra": extra,
        "expected_actions_detailed": expected_actions,
        "observed_transitions_detailed": observed_actions
    }

    diff_path = os.path.join(output_dir, "jump_action_diff.json")
    with open(diff_path, "w", encoding="utf-8") as f:
        json.dump(diff_payload, f, ensure_ascii=False, indent=2)

    summary_lines = [
        "# Jump Action Compare Summary",
        "",
        f"- generated_at: {diff_payload['generated_at']}",
        f"- architect_output: {diff_payload['architect_output_path']}",
        f"- review_transitions: {diff_payload['review_transitions_path']}",
        "",
        "## Counts",
        f"- expected_actions: {diff_payload['summary']['expected_actions']}",
        f"- observed_transitions: {diff_payload['summary']['observed_transitions']}",
        f"- matched: {diff_payload['summary']['matched']}",
        f"- missing: {diff_payload['summary']['missing']}",
        f"- wrong_target: {diff_payload['summary']['wrong_target']}",
        f"- extra: {diff_payload['summary']['extra']}",
        "",
        "## Missing Edges",
    ]
    if diff_payload["edge_summary"]["missing_edges"]:
        summary_lines.extend([f"- {edge}" for edge in diff_payload["edge_summary"]["missing_edges"]])
    else:
        summary_lines.append("- none")

    summary_lines.append("")
    summary_lines.append("## Extra Edges")
    if diff_payload["edge_summary"]["extra_edges"]:
        summary_lines.extend([f"- {edge}" for edge in diff_payload["edge_summary"]["extra_edges"]])
    else:
        summary_lines.append("- none")

    summary_lines.append("")
    summary_lines.append("## Wrong Target Details")
    if wrong_target:
        for idx, item in enumerate(wrong_target, 1):
            expected_item = item["expected"]
            observed_item = item["observed"]
            summary_lines.append(
                f"{idx}. source={expected_item.get('source_page')} "
                f"expected={expected_item.get('target_page')} "
                f"observed={observed_item.get('target_page')} "
                f"trigger={expected_item.get('trigger_text') or '<empty>'}"
            )
    else:
        summary_lines.append("none")

    summary_path = os.path.join(output_dir, "jump_action_summary.md")
    with open(summary_path, "w", encoding="utf-8") as f:
        f.write("\n".join(summary_lines))

    print(f"[jump-compare] detail saved: {diff_path}")
    print(f"[jump-compare] summary saved: {summary_path}")
    return diff_path, summary_path

def run_review_workflow(
    hap_path: str,
    bundle_name_value: str,
    ability_name_value: str = "EntryAbility",
    max_depth: int = 5,
    output_root: str = "output",
    architect_output_path: str = os.path.join("designs", "architect.json"),
    run_jump_compare: bool = True,
    install_hap: bool = True,
) -> Dict[str, Any]:
    global bundle_name, ability_name, PAGE_SIGNATURE_TO_ID, PAGE_ID_COUNTER

    normalized_hap_path = _normalize_host_path(str(hap_path or "").strip())
    resolved_hap_path = os.path.abspath(normalized_hap_path)
    if not resolved_hap_path or not os.path.isfile(resolved_hap_path):
        raise FileNotFoundError(f"HAP file not found: {resolved_hap_path or hap_path}")

    bundle_name = str(bundle_name_value or "").strip()
    if not bundle_name:
        raise ValueError("bundle_name_value is required")

    ability_name = str(ability_name_value or "").strip() or "EntryAbility"
    depth_limit = max(1, int(max_depth or 1))
    PAGE_SIGNATURE_TO_ID = {}
    PAGE_ID_COUNTER = 0

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    normalized_output_root = _normalize_host_path(str(output_root or "output"))
    output_base_dir = os.path.abspath(normalized_output_root)
    os.makedirs(output_base_dir, exist_ok=True)
    output_dir = os.path.join(output_base_dir, timestamp)
    os.makedirs(output_dir, exist_ok=True)
    print(f"output root dir: {os.path.abspath(output_dir)}")

    if install_hap:
        print("installing HAP...")
        hdc_hap_path = _normalize_local_path_for_hdc(resolved_hap_path)
        run_cmd([HDC_WINDOWS_EXE, "install", hdc_hap_path])

    restart_app(bundle_name, ability_name)

    temp_layout = os.path.join(output_dir, "temp_init_layout.json")
    if not dump_layout(temp_layout):
        raise RuntimeError("failed to dump initial layout")

    with open(temp_layout, "r", encoding="utf-8") as f:
        init_data = json.load(f)
    init_page_context = get_page_context(init_data)
    init_page_id = init_page_context["page_id"]
    safe_init_id = safe_page_dir_name(init_page_id)
    init_page_dir = os.path.join(output_dir, safe_init_id)
    os.makedirs(init_page_dir, exist_ok=True)
    init_layout_path = os.path.join(init_page_dir, "layout.json")
    shutil.move(temp_layout, init_layout_path)

    all_results = []
    visited_pages = set()
    explore_page(
        init_layout_path,
        visited_pages,
        depth=0,
        max_depth=depth_limit,
        output_dir=output_dir,
        results_list=all_results,
        page_dir=init_page_dir,
    )

    report_path = os.path.join(output_dir, "report.txt")
    generate_report(all_results, report_path)
    detailed_path, transitions_path = write_detailed_outputs(
        all_results,
        output_dir,
        report_path,
        depth_limit,
    )

    compare_detail_path = None
    compare_summary_path = None
    normalized_architect_path = _normalize_host_path(str(architect_output_path))
    resolved_architect_path = os.path.abspath(normalized_architect_path)
    if run_jump_compare:
        compare_detail_path, compare_summary_path = compare_jump_actions(
            architect_output_path=resolved_architect_path,
            transitions_path=transitions_path,
            output_dir=output_dir,
        )

    return {
        "status": "SUCCESS",
        "hap_path": resolved_hap_path,
        "bundle_name": bundle_name,
        "ability_name": ability_name,
        "max_depth": depth_limit,
        "output_dir": os.path.abspath(output_dir),
        "report_path": os.path.abspath(report_path),
        "review_detailed_output_path": os.path.abspath(detailed_path),
        "jump_transition_candidates_path": os.path.abspath(transitions_path),
        "architect_output_path": resolved_architect_path,
        "jump_action_diff_path": os.path.abspath(compare_detail_path) if compare_detail_path else "",
        "jump_action_summary_path": os.path.abspath(compare_summary_path) if compare_summary_path else "",
    }


def _extract_bundle_name_from_appscope(app_json_path: str) -> str:
    if not app_json_path or not os.path.isfile(app_json_path):
        return ""

    try:
        with open(app_json_path, "r", encoding="utf-8") as f:
            raw = f.read()
    except Exception:
        return ""

    try:
        parsed = json.loads(raw)
        if isinstance(parsed, dict):
            app = parsed.get("app")
            if isinstance(app, dict):
                value = str(app.get("bundleName", "")).strip()
                if value:
                    return value
    except Exception:
        pass

    match = re.search(r'"bundleName"\s*:\s*"([^"]+)"', raw)
    if match:
        return match.group(1).strip()
    return ""


def _find_best_hap_under(outputs_dir: str) -> str:
    if not outputs_dir or not os.path.isdir(outputs_dir):
        return ""

    hap_files: List[str] = []
    for root, _, files in os.walk(outputs_dir):
        for name in files:
            if name.lower().endswith(".hap"):
                hap_files.append(os.path.join(root, name))

    if not hap_files:
        return ""

    def _score(path: str) -> Tuple[int, float]:
        name = os.path.basename(path).lower()
        unsigned_bonus = 1 if "unsigned" in name else 0
        mtime = os.path.getmtime(path)
        return unsigned_bonus, mtime

    return sorted(hap_files, key=_score, reverse=True)[0]


def _build_cli_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Run review node workflow from CLI")
    parser.add_argument("--project-dir", default="", help="Project root path, e.g. .../projects/calculator_app")
    parser.add_argument("--hap-path", default="", help="Path to .hap file")
    parser.add_argument("--bundle-name", default="", help="Bundle name; auto-read from AppScope/app.json5 if omitted")
    parser.add_argument("--ability-name", default="EntryAbility", help="Entry ability name")
    parser.add_argument("--max-depth", type=int, default=5, help="Max recursive depth")
    parser.add_argument("--output-root", default="output", help="Output root directory")
    parser.add_argument(
        "--architect-output-path",
        default=os.path.join("designs", "architect.json"),
        help="Architect JSON path",
    )
    parser.add_argument("--run-jump-compare", dest="run_jump_compare", action="store_true", help="Enable jump compare")
    parser.add_argument("--no-run-jump-compare", dest="run_jump_compare", action="store_false", help="Disable jump compare")
    parser.add_argument("--install-hap", dest="install_hap", action="store_true", help="Install hap before review")
    parser.add_argument("--no-install-hap", dest="install_hap", action="store_false", help="Skip hap install")
    parser.add_argument("--print-json", action="store_true", help="Print final result JSON")
    parser.set_defaults(run_jump_compare=True, install_hap=True)
    return parser


def main():
    parser = _build_cli_parser()
    args = parser.parse_args()

    project_dir = _normalize_host_path(str(args.project_dir or "").strip())
    hap_path = _normalize_host_path(str(args.hap_path or "").strip())
    bundle_name_cli = str(args.bundle_name or "").strip()

    if not hap_path:
        if not project_dir:
            parser.error("Either --hap-path or --project-dir must be provided")
        outputs_dir = os.path.join(project_dir, "entry", "build", "default", "outputs", "default")
        best_hap = _find_best_hap_under(outputs_dir)
        if not best_hap:
            parser.error(f"No .hap found under expected output dir: {outputs_dir}")
        hap_path = best_hap

    if not bundle_name_cli:
        if project_dir:
            app_json_path = os.path.join(project_dir, "AppScope", "app.json5")
            bundle_name_cli = _extract_bundle_name_from_appscope(app_json_path)
        if not bundle_name_cli:
            parser.error("--bundle-name is required when bundleName cannot be inferred from AppScope/app.json5")

    result = run_review_workflow(
        hap_path=hap_path,
        bundle_name_value=bundle_name_cli,
        ability_name_value=str(args.ability_name or "").strip() or "EntryAbility",
        max_depth=max(1, int(args.max_depth or 1)),
        output_root=str(args.output_root or "output"),
        architect_output_path=str(args.architect_output_path or os.path.join("designs", "architect.json")),
        run_jump_compare=bool(args.run_jump_compare),
        install_hap=bool(args.install_hap),
    )

    if args.print_json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print("status: SUCCESS")
        print(f"hap_path: {result.get('hap_path', '')}")
        print(f"bundle_name: {result.get('bundle_name', '')}")
        print(f"ability_name: {result.get('ability_name', '')}")
        print(f"output_dir: {result.get('output_dir', '')}")
        print(f"report_path: {result.get('report_path', '')}")
        print(f"review_detailed_output_path: {result.get('review_detailed_output_path', '')}")
        print(f"jump_transition_candidates_path: {result.get('jump_transition_candidates_path', '')}")
        print(f"jump_action_diff_path: {result.get('jump_action_diff_path', '')}")
        print(f"jump_action_summary_path: {result.get('jump_action_summary_path', '')}")

if __name__ == "__main__":
    main()
