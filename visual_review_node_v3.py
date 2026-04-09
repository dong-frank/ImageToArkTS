from __future__ import annotations

import argparse
import base64
import importlib
import io
import json
import os
import sys
import time
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path
from typing import Any, Dict, List, Optional, Set, Tuple

import lpips
import numpy as np
import open_clip
import torch
from PIL import Image
from skimage.metrics import structural_similarity as ssim

try:
    from dotenv import load_dotenv
except Exception:
    load_dotenv = None


WEIGHT_SSIM = 0.32
WEIGHT_CLIP = 0.36
WEIGHT_LPIPS = 0.32

NAVIGATION_SCORE_THRESHOLD = 0.62
NAVIGATION_MARGIN = 0.03
DEFAULT_VLM_MODEL = "qwen-vl-max"


@dataclass
class ExpectedImage:
    page_key: str
    image_path: str
    image_data: str
    is_interaction: bool


@dataclass
class ActualInteraction:
    elem_dir: str
    after_path: str
    after_data: str
    before_path: Optional[str]
    before_data: Optional[str]
    return_path: Optional[str]
    return_data: Optional[str]


@dataclass
class ActualPage:
    page_dir: str
    page_key: str
    init_path: str
    init_data: str
    interactions: List[ActualInteraction]


class ProgressPrinter:
    def __init__(self, enabled: bool = True, width: int = 28) -> None:
        self.enabled = enabled
        self.width = width
        self._line_open = False

    def stage(self, message: str) -> None:
        if not self.enabled:
            return
        if self._line_open:
            sys.stdout.write("\n")
            self._line_open = False
        print(f"[Stage] {message}", flush=True)

    def update(self, current: int, total: int, label: str) -> None:
        if not self.enabled:
            return
        safe_total = max(1, total)
        cur = min(max(current, 0), safe_total)
        ratio = cur / safe_total
        fill = int(self.width * ratio)
        bar = "#" * fill + "-" * (self.width - fill)
        text = f"\r[{bar}] {cur}/{total if total > 0 else 0} {ratio * 100:6.2f}% | {label}"
        sys.stdout.write(text)
        sys.stdout.flush()
        self._line_open = True

    def finish(self, message: Optional[str] = None) -> None:
        if not self.enabled:
            return
        if self._line_open:
            sys.stdout.write("\n")
            self._line_open = False
        if message:
            print(f"[Done] {message}", flush=True)


_device = torch.device("cuda" if torch.cuda.is_available() else "cpu")


def _load_env_vars() -> None:
    if load_dotenv is None:
        return

    cwd_env = Path.cwd() / ".env"
    script_env = Path(__file__).resolve().parents[3] / ".env"

    if cwd_env.exists():
        load_dotenv(dotenv_path=cwd_env, override=False)
    elif script_env.exists():
        load_dotenv(dotenv_path=script_env, override=False)
    else:
        load_dotenv(override=False)


_load_env_vars()


def _clamp01(value: float) -> float:
    return max(0.0, min(1.0, float(value)))


@lru_cache(maxsize=1)
def _get_lpips_model() -> Any:
    return lpips.LPIPS(net="alex").to(_device).eval()


@lru_cache(maxsize=1)
def _get_clip_components() -> Tuple[Any, Any]:
    model, _, preprocess = open_clip.create_model_and_transforms(
        "ViT-B-32", pretrained="laion2b_s34b_b79k"
    )
    model = model.to(_device).eval()
    return model, preprocess


def _read_json(path: Path) -> Dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _get_dashscope_api_key() -> str:
    return os.getenv("DASHSCOPE_API_KEY", "").strip()


def _extract_state_from_architect_payload(payload: Dict[str, Any]) -> Dict[str, Any]:
    if isinstance(payload.get("final_state"), dict):
        return payload["final_state"]
    if isinstance(payload.get("state"), dict):
        return payload["state"]
    return payload


def _normalize_path(path_like: str) -> str:
    return path_like.replace("\\", "/").strip("/")


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


def _read_image_b64(path: Path) -> str:
    return base64.b64encode(path.read_bytes()).decode("utf-8")


def _scan_actual_pages(review_output_dir: Path) -> List[ActualPage]:
    pages: List[ActualPage] = []
    if not review_output_dir.exists():
        return pages

    for page_dir in sorted(review_output_dir.iterdir(), key=lambda p: p.name.lower()):
        if not page_dir.is_dir():
            continue

        init_path = page_dir / "init_screen.jpeg"
        if not init_path.exists():
            continue

        interactions: List[ActualInteraction] = []
        for child in sorted(page_dir.iterdir(), key=lambda p: p.name.lower()):
            if not child.is_dir() or not child.name.lower().startswith("elem"):
                continue

            after_path = child / "after.jpeg"
            if not after_path.exists():
                continue

            before_path = child / "before.jpeg"
            return_path = child / "return.jpeg"

            interactions.append(
                ActualInteraction(
                    elem_dir=child.name,
                    after_path=str(after_path),
                    after_data=_read_image_b64(after_path),
                    before_path=str(before_path) if before_path.exists() else None,
                    before_data=_read_image_b64(before_path) if before_path.exists() else None,
                    return_path=str(return_path) if return_path.exists() else None,
                    return_data=_read_image_b64(return_path) if return_path.exists() else None,
                )
            )

        pages.append(
            ActualPage(
                page_dir=page_dir.name,
                page_key=_extract_page_key_from_review_dir_name(page_dir.name),
                init_path=str(init_path),
                init_data=_read_image_b64(init_path),
                interactions=interactions,
            )
        )

    return pages


def _infer_page_key_from_expected_path(image_path: str, actual_page_keys: Set[str]) -> str:
    normalized = _normalize_path(image_path)
    parts = [p for p in normalized.split("/") if p]
    if not parts:
        return "."

    # Prefer exact segment matches with actual page keys, choosing the deepest segment.
    matching_segments = [seg for seg in parts if seg in actual_page_keys]
    if matching_segments:
        return matching_segments[-1]

    stem = Path(parts[-1]).stem
    if stem in actual_page_keys:
        return stem

    # Heuristic: file names such as MemoDetail_menu_xxx.png should map to MemoDetail_menu.
    for key in sorted(actual_page_keys, key=len, reverse=True):
        if stem == key or stem.startswith(f"{key}_"):
            return key

    # If no strong signal, use parent directory as fallback.
    if len(parts) >= 2:
        return parts[-2]
    return stem


def _extract_expected_images(
    state: Dict[str, Any],
    actual_page_keys: Set[str],
) -> List[ExpectedImage]:
    expected: List[ExpectedImage] = []
    assets = state.get("image_assets", [])
    if not isinstance(assets, list):
        return expected

    for item in assets:
        if not isinstance(item, dict):
            continue

        image_path = str(item.get("image_path", "")).strip()
        image_data = str(item.get("image_data", "")).strip()
        if not image_path or not image_data:
            continue

        normalized = _normalize_path(image_path)
        parts = normalized.split("/") if normalized else []
        is_interaction = any(part == "Interaction" for part in parts)

        page_key = _infer_page_key_from_expected_path(image_path, actual_page_keys)
        expected.append(
            ExpectedImage(
                page_key=page_key,
                image_path=image_path,
                image_data=image_data,
                is_interaction=is_interaction,
            )
        )

    return expected


def _split_expected_images(
    expected_images: List[ExpectedImage],
) -> Tuple[Dict[str, List[ExpectedImage]], Dict[str, List[ExpectedImage]], List[ExpectedImage], List[ExpectedImage]]:
    base_by_page: Dict[str, List[ExpectedImage]] = {}
    interaction_by_page: Dict[str, List[ExpectedImage]] = {}
    base_all: List[ExpectedImage] = []
    interaction_all: List[ExpectedImage] = []

    for item in expected_images:
        if item.is_interaction:
            interaction_by_page.setdefault(item.page_key, []).append(item)
            interaction_all.append(item)
        else:
            base_by_page.setdefault(item.page_key, []).append(item)
            base_all.append(item)

    return base_by_page, interaction_by_page, base_all, interaction_all


def _index_expected_images_by_path(expected_images: List[ExpectedImage]) -> Dict[str, ExpectedImage]:
    return {item.image_path: item for item in expected_images}


def _decode_base64_image(image_b64: str) -> Image.Image:
    raw = base64.b64decode(image_b64)
    return Image.open(io.BytesIO(raw)).convert("RGB")


def _pil_to_tensor(img: Image.Image) -> torch.Tensor:
    img = img.convert("RGB").resize((224, 224), Image.Resampling.BICUBIC)
    img_np = np.array(img).astype(np.float32) / 127.5 - 1.0
    return torch.from_numpy(img_np).permute(2, 0, 1).unsqueeze(0).to(_device)


def _ssim_score(img_a: Image.Image, img_b: Image.Image) -> float:
    arr_a = np.array(img_a.convert("L"))
    arr_b = np.array(img_b.convert("L"))

    if arr_a.shape != arr_b.shape:
        size = (min(arr_a.shape[1], arr_b.shape[1]), min(arr_a.shape[0], arr_b.shape[0]))
        arr_a = np.array(img_a.resize(size, Image.Resampling.LANCZOS).convert("L"))
        arr_b = np.array(img_b.resize(size, Image.Resampling.LANCZOS).convert("L"))

    return _clamp01(float(ssim(arr_a, arr_b, data_range=255)))


def _lpips_score(img_a: Image.Image, img_b: Image.Image) -> float:
    tensor_a = _pil_to_tensor(img_a)
    tensor_b = _pil_to_tensor(img_b)
    model = _get_lpips_model()
    with torch.no_grad():
        dist = model(tensor_a, tensor_b)
    return float(dist.item())


def _clip_similarity(img_a: Image.Image, img_b: Image.Image) -> float:
    model, preprocess = _get_clip_components()
    image_a = preprocess(img_a).unsqueeze(0).to(_device)
    image_b = preprocess(img_b).unsqueeze(0).to(_device)

    with torch.no_grad():
        emb_a = model.encode_image(image_a)
        emb_b = model.encode_image(image_b)
        emb_a = emb_a / emb_a.norm(dim=-1, keepdim=True)
        emb_b = emb_b / emb_b.norm(dim=-1, keepdim=True)
        cosine = (emb_a * emb_b).sum().item()

    return _clamp01((cosine + 1.0) / 2.0)


def _weighted_similarity_score(expected_b64: str, actual_b64: str) -> Dict[str, float]:
    exp_img = _decode_base64_image(expected_b64)
    act_img = _decode_base64_image(actual_b64)

    ssim_value = _ssim_score(exp_img, act_img)
    lpips_distance = max(0.0, _lpips_score(exp_img, act_img))
    clip_value = _clip_similarity(exp_img, act_img)

    lpips_good = 1.0 / (1.0 + lpips_distance)
    final_score = WEIGHT_SSIM * ssim_value + WEIGHT_CLIP * clip_value + WEIGHT_LPIPS * lpips_good

    return {
        "final": round(_clamp01(final_score), 6),
        "ssim": round(_clamp01(ssim_value), 6),
        "clip": round(_clamp01(clip_value), 6),
        "lpips": round(_clamp01(lpips_good), 6),
    }


def _best_match(
    actual_b64: str,
    expected_candidates: List[ExpectedImage],
    top_k: int = 3,
) -> Dict[str, Any]:
    if not expected_candidates:
        return {
            "best": None,
            "top_candidates": [],
        }

    scored: List[Dict[str, Any]] = []
    for exp in expected_candidates:
        metrics = _weighted_similarity_score(exp.image_data, actual_b64)
        scored.append(
            {
                "expected_page_key": exp.page_key,
                "expected_image_path": exp.image_path,
                "score": metrics["final"],
                "component_scores": {
                    "ssim": metrics["ssim"],
                    "clip": metrics["clip"],
                    "lpips": metrics["lpips"],
                },
            }
        )

    scored.sort(key=lambda item: item["score"], reverse=True)
    top = scored[:top_k]

    return {
        "best": top[0] if top else None,
        "top_candidates": top,
    }


def _classify_interaction_transition(
    best_interaction_score: float,
    best_global_page_score: float,
) -> str:
    if (
        best_global_page_score >= NAVIGATION_SCORE_THRESHOLD
        and best_global_page_score >= best_interaction_score + NAVIGATION_MARGIN
    ):
        return "navigation_or_return"
    if best_interaction_score > 0.0:
        return "in_page_interaction"
    return "unknown"


def _build_vlm(model_name: str) -> Any:
    try:
        chatopenai_module = importlib.import_module("langchain_openai")
        pydantic_module = importlib.import_module("pydantic")
    except Exception as exc:
        raise RuntimeError(
            "LLM dependencies are missing. Install langchain-openai, langchain-core, and pydantic."
        ) from exc

    ChatOpenAI = getattr(chatopenai_module, "ChatOpenAI")
    BaseModel = getattr(pydantic_module, "BaseModel")
    Field = getattr(pydantic_module, "Field")

    class VisualPageFeedback(BaseModel):
        verdict: str = Field(description="PASS / WARN / FAIL")
        confidence: float = Field(description="0-1 confidence")
        summary: str = Field(description="A short summary in Chinese")
        matched_points: List[str] = Field(description="Matched visual points")
        differences: List[str] = Field(description="Key visual differences")
        suggestions: List[str] = Field(description="Actionable suggestions")

    class VisualInteractionFeedback(BaseModel):
        operation_type: str = Field(
            description="Inferred action type, such as navigation, scroll, click, input, toggle, return, unknown"
        )
        operation_target: str = Field(description="Likely target control or area that triggered the interaction")
        expected_result: str = Field(description="What result the interaction appears to be aiming for")
        result_correct: bool = Field(description="Whether the actual result matches the expected behavior")
        verdict: str = Field(description="PASS / WARN / FAIL")
        confidence: float = Field(description="0-1 confidence")
        summary: str = Field(description="A short summary in Chinese")
        matched_points: List[str] = Field(description="Matched visual points")
        differences: List[str] = Field(description="Key visual differences")
        suggestions: List[str] = Field(description="Actionable suggestions")

    api_key = _get_dashscope_api_key()
    if not api_key:
        raise ValueError("DASHSCOPE_API_KEY is missing.")

    llm = ChatOpenAI(
        model=model_name,
        api_key=api_key,
        base_url="https://dashscope.aliyuncs.com/compatible-mode/v1",
        temperature=0.0,
    )
    return {
        "page": llm.with_structured_output(VisualPageFeedback),
        "interaction": llm.with_structured_output(VisualInteractionFeedback),
    }


def _vlm_compare_page(
    llm: Any,
    page_key: str,
    actual_init_b64: str,
    actual_init_path: str,
    expected_page: ExpectedImage,
    similarity_top_candidates: List[Dict[str, Any]],
) -> Dict[str, Any]:
    try:
        messages_module = importlib.import_module("langchain_core.messages")
    except Exception as exc:
        raise RuntimeError("langchain-core is missing for VLM invocation.") from exc

    HumanMessage = getattr(messages_module, "HumanMessage")
    SystemMessage = getattr(messages_module, "SystemMessage")

    expected_ext = Path(expected_page.image_path).suffix.lower()
    expected_mime = "image/png" if expected_ext == ".png" else "image/jpeg"

    system_prompt = (
        "你是移动端 UI 视觉评审专家。"
        "请对比主页面原图和生成的页面截图，判断页面是否生成正确。"
        "重点关注页面结构、关键组件、文案语义、层级关系、布局位置和缺失元素。"
        "请输出结构化结论，并指出差异与修复建议。"
    )

    content: List[Dict[str, Any]] = [
        {
            "type": "text",
            "text": (
                f"page_key={page_key}\n"
                "以下是算法召回结果（SSIM+CLIP+LPIPS，仅作参考）：\n"
                f"page_top_candidates={json.dumps(similarity_top_candidates, ensure_ascii=False)}\n"
                "请以图片为主判断生成页面是否正确。"
            ),
        },
        {
            "type": "text",
            "text": f"[Original-Page] path={expected_page.image_path}",
        },
        {
            "type": "image_url",
            "image_url": {"url": f"data:{expected_mime};base64,{expected_page.image_data}"},
        },
        {
            "type": "text",
            "text": f"[Generated-Init] path={actual_init_path}",
        },
        {
            "type": "image_url",
            "image_url": {"url": f"data:image/jpeg;base64,{actual_init_b64}"},
        },
    ]

    result: Any = llm.invoke([SystemMessage(content=system_prompt), HumanMessage(content=content)])
    if hasattr(result, "model_dump"):
        return result.model_dump()
    if isinstance(result, dict):
        return result
    return {"raw": str(result)}


def _vlm_compare_interaction(
    llm: Any,
    page_key: str,
    elem_dir: str,
    current_page_b64: str,
    current_page_path: str,
    actual_after_b64: str,
    actual_after_path: str,
    expected_target: Optional[ExpectedImage],
    transition_type: str,
    interaction_top_candidates: List[Dict[str, Any]],
    global_page_top_candidates: List[Dict[str, Any]],
) -> Dict[str, Any]:
    try:
        messages_module = importlib.import_module("langchain_core.messages")
    except Exception as exc:
        raise RuntimeError("langchain-core is missing for VLM invocation.") from exc

    HumanMessage = getattr(messages_module, "HumanMessage")
    SystemMessage = getattr(messages_module, "SystemMessage")

    system_prompt = (
        "你是移动端 UI 视觉评审专家。"
        "你会看到交互前的当前页面截图和交互后的页面截图。"
        "请先根据两张图的变化推断发生了什么操作，例如点击按钮、滚动、返回、跳转、展开收起、输入等。"
        "如果还提供了 after 可能对应的目标原图，请进一步判断 after 是否达到了这个目标结果。"
        "重点关注交互对象、滚动位置、页面跳转、状态变化，以及错误跳转或无效操作。"
    )

    content: List[Dict[str, Any]] = [
        {
            "type": "text",
            "text": (
                f"页面 page_key={page_key}，交互元素 {elem_dir}。\n"
                f"第一阶段判断的 transition_type={transition_type}。\n"
                "以下是算法召回结果（SSIM+CLIP+LPIPS，仅作参考）：\n"
                f"same_page_interaction_top={json.dumps(interaction_top_candidates, ensure_ascii=False)}\n"
                f"global_page_top={json.dumps(global_page_top_candidates, ensure_ascii=False)}\n"
                "请先从当前页面到 after 的变化中推断操作类型与操作对象；"
                "最后判断操作结果是否正确。"
            ),
        },
        {
            "type": "text",
            "text": f"[Current-Page-Before] path={current_page_path}",
        },
        {
            "type": "image_url",
            "image_url": {"url": f"data:image/jpeg;base64,{current_page_b64}"},
        },
        {
            "type": "text",
            "text": f"[Actual-After] path={actual_after_path}",
        },
        {
            "type": "image_url",
            "image_url": {"url": f"data:image/jpeg;base64,{actual_after_b64}"},
        },
    ]

    if expected_target is not None:
        target_ext = Path(expected_target.image_path).suffix.lower()
        target_mime = "image/png" if target_ext == ".png" else "image/jpeg"
        content.extend(
            [
                {
                    "type": "text",
                    "text": f"[Original-Target-Candidate] page_key={expected_target.page_key} path={expected_target.image_path}",
                },
                {
                    "type": "image_url",
                    "image_url": {"url": f"data:{target_mime};base64,{expected_target.image_data}"},
                },
            ]
        )

    result: Any = llm.invoke(
        [
            SystemMessage(content=system_prompt),
            HumanMessage(content=content),
        ]
    )
    if hasattr(result, "model_dump"):
        return result.model_dump()
    if isinstance(result, dict):
        return result
    return {"raw": str(result)}


def run_visual_review_page_elem(
    architect_output_path: Path,
    review_output_dir: Path,
    output_json_path: Path,
    show_progress: bool = True,
    use_llm: bool = True,
    llm_model: str = DEFAULT_VLM_MODEL,
) -> Dict[str, Any]:
    t0 = time.perf_counter()
    progress = ProgressPrinter(enabled=show_progress)

    progress.stage("Loading architect JSON")
    payload = _read_json(architect_output_path)
    state = _extract_state_from_architect_payload(payload)

    progress.stage("Scanning actual output pages")
    actual_pages = _scan_actual_pages(review_output_dir)
    if not actual_pages:
        raise ValueError("No page folders with init_screen.jpeg were found under review output dir.")

    progress.stage("Indexing expected images")
    actual_page_keys = {page.page_key for page in actual_pages}
    expected_images = _extract_expected_images(state, actual_page_keys)
    if not expected_images:
        raise ValueError("No expected image_assets(base64) found in architect JSON.")

    expected_by_path = _index_expected_images_by_path(expected_images)
    base_by_page, interaction_by_page, base_all, interaction_all = _split_expected_images(expected_images)
    if not base_all:
        raise ValueError("No base expected images (non-Interaction) found in architect JSON.")

    page_reports: List[Dict[str, Any]] = []
    page_index_pairs: List[Dict[str, Any]] = []
    interaction_image_pairs: List[Dict[str, Any]] = []
    page_name_hit = 0
    interaction_count = 0
    interaction_nav_like = 0
    missing_expected_index_pages = 0
    missing_expected_interaction_pages = 0
    llm_requested = bool(use_llm)
    llm_used = False
    llm_error = ""
    page_feedback_ok = 0
    page_feedback_failed = 0
    page_feedback_skipped = 0
    llm_feedback_ok = 0
    llm_feedback_skipped = 0
    llm_feedback_failed = 0
    vlm = None

    if use_llm:
        progress.stage(f"Initializing VLM reviewer ({llm_model})")
        try:
            vlm = _build_vlm(llm_model)
            llm_used = True
        except Exception as exc:
            llm_error = str(exc)

    total_pages = len(actual_pages)
    total_interactions = sum(len(page.interactions) for page in actual_pages)
    done_interactions = 0

    progress.stage(f"Matching pages ({total_pages}) and interactions ({total_interactions})")

    for page_index, page in enumerate(actual_pages, start=1):
        page_base_candidates = base_by_page.get(page.page_key, [])
        if not page_base_candidates:
            missing_expected_index_pages += 1
        page_init_match = _best_match(page.init_data, page_base_candidates, top_k=5)

        progress.update(
            page_index,
            total_pages,
            f"page init matching: {page.page_key}",
        )

        init_best = page_init_match.get("best")
        main_page_expected = None
        if isinstance(init_best, dict):
            main_page_expected = expected_by_path.get(str(init_best.get("expected_image_path", "")).strip())
        top1_name_match = bool(init_best and init_best.get("expected_page_key", "").lower() == page.page_key.lower())
        if top1_name_match:
            page_name_hit += 1

        page_index_pairs.append(
            {
                "page_key": page.page_key,
                "page_dir": page.page_dir,
                "original_index_image": init_best.get("expected_image_path") if isinstance(init_best, dict) else None,
                "generated_index_image": page.init_path,
                "similarity_score": init_best.get("score") if isinstance(init_best, dict) else None,
            }
        )

        page_vlm_feedback: Dict[str, Any] = {
            "status": "skipped",
            "reason": "llm_not_enabled",
        }
        if llm_requested and not llm_used:
            page_vlm_feedback = {
                "status": "skipped",
                "reason": llm_error or "llm_not_available",
            }
            page_feedback_skipped += 1
        elif llm_used and vlm is not None:
            if main_page_expected is None:
                page_vlm_feedback = {
                    "status": "skipped",
                    "reason": "main_page_original_not_found",
                }
                page_feedback_skipped += 1
            else:
                try:
                    review = _vlm_compare_page(
                        llm=vlm["page"],
                        page_key=page.page_key,
                        actual_init_b64=page.init_data,
                        actual_init_path=page.init_path,
                        expected_page=main_page_expected,
                        similarity_top_candidates=page_init_match.get("top_candidates", []),
                    )
                    page_vlm_feedback = {
                        "status": "ok",
                        "review": review,
                    }
                    page_feedback_ok += 1
                except Exception as exc:
                    page_vlm_feedback = {
                        "status": "failed",
                        "reason": str(exc),
                    }
                    page_feedback_failed += 1

        interaction_reports: List[Dict[str, Any]] = []
        for interaction in page.interactions:
            interaction_count += 1

            same_page_interaction_candidates = interaction_by_page.get(page.page_key, [])
            if not same_page_interaction_candidates:
                missing_expected_interaction_pages += 1
            same_page_interaction_match = _best_match(
                interaction.after_data,
                same_page_interaction_candidates,
                top_k=5,
            )

            global_page_match = _best_match(interaction.after_data, base_all, top_k=5)

            before_page_match = None
            if interaction.before_data:
                before_page_match = _best_match(interaction.before_data, page_base_candidates, top_k=3)

            return_page_match = None
            if interaction.return_data:
                return_page_match = _best_match(interaction.return_data, page_base_candidates, top_k=3)

            interaction_best = same_page_interaction_match.get("best")
            global_page_best = global_page_match.get("best")

            interaction_score = float(interaction_best.get("score", 0.0)) if interaction_best else 0.0
            global_page_score = float(global_page_best.get("score", 0.0)) if global_page_best else 0.0

            transition_type = _classify_interaction_transition(interaction_score, global_page_score)
            if transition_type == "navigation_or_return":
                interaction_nav_like += 1

            expected_target = None
            expected_target_selection = {
                "selected_kind": "none",
                "selected_expected_image_path": None,
                "selected_score": None,
            }
            if transition_type == "navigation_or_return" and isinstance(global_page_best, dict):
                expected_target_selection = {
                    "selected_kind": "base_page",
                    "selected_expected_image_path": global_page_best.get("expected_image_path"),
                    "selected_score": global_page_best.get("score"),
                }
                expected_target = expected_by_path.get(str(global_page_best.get("expected_image_path", "")).strip())
            elif isinstance(interaction_best, dict):
                expected_target_selection = {
                    "selected_kind": "interaction",
                    "selected_expected_image_path": interaction_best.get("expected_image_path"),
                    "selected_score": interaction_best.get("score"),
                }
                expected_target = expected_by_path.get(str(interaction_best.get("expected_image_path", "")).strip())

            vlm_review: Dict[str, Any] = {
                "status": "skipped",
                "reason": "llm_not_enabled",
            }
            if llm_requested and not llm_used:
                vlm_review = {
                    "status": "skipped",
                    "reason": llm_error or "llm_not_available",
                }
                llm_feedback_skipped += 1
            elif llm_used and vlm is not None:
                if not interaction.before_data or not interaction.before_path:
                    vlm_review = {
                        "status": "skipped",
                        "reason": "before_image_missing",
                    }
                    llm_feedback_skipped += 1
                elif main_page_expected is None:
                    vlm_review = {
                        "status": "skipped",
                        "reason": "main_page_original_not_found",
                    }
                    llm_feedback_skipped += 1
                else:
                    try:
                        review = _vlm_compare_interaction(
                            llm=vlm["interaction"],
                            page_key=page.page_key,
                            elem_dir=interaction.elem_dir,
                            current_page_b64=interaction.before_data,
                            current_page_path=interaction.before_path,
                            actual_after_b64=interaction.after_data,
                            actual_after_path=interaction.after_path,
                            expected_target=expected_target,
                            transition_type=transition_type,
                            interaction_top_candidates=same_page_interaction_match.get("top_candidates", []),
                            global_page_top_candidates=global_page_match.get("top_candidates", []),
                        )
                        vlm_review = {
                            "status": "ok",
                            "selected_expected_target": expected_target_selection,
                            "review": review,
                        }
                        llm_feedback_ok += 1
                    except Exception as exc:
                        llm_feedback_failed += 1
                        vlm_review = {
                            "status": "failed",
                            "selected_expected_target": expected_target_selection,
                            "reason": str(exc),
                        }

            interaction_image_pairs.append(
                {
                    "page_key": page.page_key,
                    "elem_dir": interaction.elem_dir,
                    "original_interaction_image": interaction_best.get("expected_image_path") if isinstance(interaction_best, dict) else None,
                    "generated_interaction_after_image": interaction.after_path,
                    "similarity_score": interaction_best.get("score") if isinstance(interaction_best, dict) else None,
                    "original_index_image": init_best.get("expected_image_path") if isinstance(init_best, dict) else None,
                    "generated_index_image": page.init_path,
                }
            )

            done_interactions += 1
            progress.update(
                done_interactions,
                total_interactions,
                f"interaction matching: {page.page_key}/{interaction.elem_dir}",
            )

            interaction_reports.append(
                {
                    "elem_dir": interaction.elem_dir,
                    "after_image_path": interaction.after_path,
                    "before_image_path": interaction.before_path,
                    "return_image_path": interaction.return_path,
                    "transition_type": transition_type,
                    "after_vs_expected_interaction": same_page_interaction_match,
                    "after_vs_expected_page_global": global_page_match,
                    "selected_expected_target": expected_target_selection,
                    "before_vs_current_page": before_page_match,
                    "return_vs_current_page": return_page_match,
                    "vlm_feedback": vlm_review,
                }
            )

        page_reports.append(
            {
                "actual_page_dir": page.page_dir,
                "actual_page_key": page.page_key,
                "actual_init_screen_path": page.init_path,
                "top1_name_match": top1_name_match,
                "init_vs_expected_page": page_init_match,
                "vlm_feedback": page_vlm_feedback,
                "interactions": interaction_reports,
            }
        )

    progress.finish("Similarity matching completed")

    elapsed_seconds = round(time.perf_counter() - t0, 3)

    report = {
        "architect_output_path": str(architect_output_path),
        "review_output_dir": str(review_output_dir),
        "stats": {
            "actual_pages": len(actual_pages),
            "expected_images": len(expected_images),
            "expected_base_images": len(base_all),
            "expected_interaction_images": len(interaction_all),
            "missing_expected_index_pages": missing_expected_index_pages,
            "missing_expected_interaction_pages": missing_expected_interaction_pages,
            "page_top1_name_match": page_name_hit,
            "page_top1_name_total": len(actual_pages),
            "page_top1_name_match_accuracy": round(page_name_hit / len(actual_pages), 4) if actual_pages else 0.0,
            "interaction_total": interaction_count,
            "interaction_navigation_or_return": interaction_nav_like,
            "interaction_in_page_or_unknown": interaction_count - interaction_nav_like,
            "llm_requested": llm_requested,
            "llm_used": llm_used,
            "llm_model": llm_model if llm_requested else None,
            "page_feedback_ok": page_feedback_ok,
            "page_feedback_skipped": page_feedback_skipped,
            "page_feedback_failed": page_feedback_failed,
            "llm_feedback_ok": llm_feedback_ok,
            "llm_feedback_skipped": llm_feedback_skipped,
            "llm_feedback_failed": llm_feedback_failed,
            "similarity_weights": {
                "ssim": WEIGHT_SSIM,
                "clip": WEIGHT_CLIP,
                "lpips": WEIGHT_LPIPS,
            },
            "transition_thresholds": {
                "navigation_score_threshold": NAVIGATION_SCORE_THRESHOLD,
                "navigation_margin": NAVIGATION_MARGIN,
            },
            "elapsed_seconds": elapsed_seconds,
        },
        "page_index_pairs": page_index_pairs,
        "interaction_image_pairs": interaction_image_pairs,
        "page_reports": page_reports,
        "llm_error": llm_error,
    }

    progress.stage("Writing report JSON")
    output_json_path.parent.mkdir(parents=True, exist_ok=True)
    output_json_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    progress.finish(f"Report written: {output_json_path} | elapsed={elapsed_seconds}s")
    return report


def main() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Visual review for page-level init_screen and elem-level after screenshots. "
            "Reads expected images from architect JSON and compares against output page folders."
        )
    )
    parser.add_argument(
        "--architect-output",
        required=True,
        help="Path to architect output JSON (must contain final_state/state.image_assets with base64)",
    )
    parser.add_argument(
        "--review-output-dir",
        required=True,
        help="Output directory containing page folders with init_screen.jpeg and elem*/after.jpeg",
    )
    parser.add_argument(
        "--output-json",
        default="artifacts/visual_review_page_elem_output.json",
        help="Path to save the review report JSON",
    )
    parser.add_argument(
        "--no-progress",
        action="store_true",
        help="Disable progress output in terminal",
    )
    parser.add_argument(
        "--disable-llm",
        action="store_true",
        help="Disable optional VLM review stage",
    )
    parser.add_argument(
        "--llm-model",
        default=DEFAULT_VLM_MODEL,
        help=f"VLM model name (default: {DEFAULT_VLM_MODEL})",
    )
    args = parser.parse_args()

    report = run_visual_review_page_elem(
        architect_output_path=Path(args.architect_output).resolve(),
        review_output_dir=Path(args.review_output_dir).resolve(),
        output_json_path=Path(args.output_json).resolve(),
        show_progress=not args.no_progress,
        use_llm=not args.disable_llm,
        llm_model=args.llm_model,
    )

    print(
        json.dumps(
            {
                "report": str(Path(args.output_json).resolve()),
                "actual_pages": report["stats"]["actual_pages"],
                "interaction_total": report["stats"]["interaction_total"],
                "page_top1_name_match_accuracy": report["stats"]["page_top1_name_match_accuracy"],
                "llm_used": report["stats"]["llm_used"],
                "llm_error": report.get("llm_error", ""),
                "elapsed_seconds": report["stats"].get("elapsed_seconds", None),
            },
            ensure_ascii=False,
            indent=2,
        )
    )


if __name__ == "__main__":
    main()
