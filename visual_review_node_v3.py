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
from typing import Any, Dict, List, Optional, Tuple

import numpy as np
import open_clip
import torch
from PIL import Image
from skimage.metrics import structural_similarity as ssim

try:
    from dotenv import load_dotenv
except Exception:
    load_dotenv = None


WEIGHT_SSIM = 0.45
WEIGHT_CLIP = 0.55
DEFAULT_VLM_MODEL = "qwen-vl-max"
IMAGE_SUFFIXES = {".png", ".jpg", ".jpeg", ".webp", ".bmp"}


@dataclass
class ImageAsset:
    path: str
    b64: str
    image_rgb: Image.Image
    gray: np.ndarray
    clip_embedding: Optional[np.ndarray] = None


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
    script_env = Path(__file__).resolve().parent / ".env"
    root_env = Path(__file__).resolve().parent.parent / ".env"

    if cwd_env.exists():
        load_dotenv(dotenv_path=cwd_env, override=False)
    elif script_env.exists():
        load_dotenv(dotenv_path=script_env, override=False)
    elif root_env.exists():
        load_dotenv(dotenv_path=root_env, override=False)
    else:
        load_dotenv(override=False)


_load_env_vars()


def _clamp01(value: float) -> float:
    return max(0.0, min(1.0, float(value)))


@lru_cache(maxsize=1)
def _get_clip_components() -> Tuple[Any, Any]:
    model, _, preprocess = open_clip.create_model_and_transforms(
        "ViT-B-32", pretrained="laion2b_s34b_b79k"
    )
    model = model.to(_device).eval()
    return model, preprocess


def _load_image_asset(path: Path) -> ImageAsset:
    raw = path.read_bytes()
    b64 = base64.b64encode(raw).decode("ascii")
    image_rgb = Image.open(io.BytesIO(raw)).convert("RGB")
    gray = np.array(image_rgb.convert("L"))
    return ImageAsset(path=str(path), b64=b64, image_rgb=image_rgb, gray=gray)


def _collect_images(root: Path) -> List[Path]:
    if not root.exists() or not root.is_dir():
        return []
    return sorted(
        [
            item
            for item in root.rglob("*")
            if item.is_file() and item.suffix.lower() in IMAGE_SUFFIXES
        ],
        key=lambda p: str(p).lower(),
    )


def _is_runtime_image_selected(path: Path) -> bool:
    normalized = str(path).replace("\\", "/").lower()
    normalized = normalized.replace("_", " ").replace("-", " ")

    if "before" in normalized or "return" in normalized:
        return False

    return ("after" in normalized) or ("init screen" in normalized) or ("initscreen" in normalized)


def _ssim_score(img_a: np.ndarray, img_b: np.ndarray, img_a_rgb: Image.Image, img_b_rgb: Image.Image) -> float:
    arr_a = img_a
    arr_b = img_b

    if arr_a.shape != arr_b.shape:
        size = (min(arr_a.shape[1], arr_b.shape[1]), min(arr_a.shape[0], arr_b.shape[0]))
        arr_a = np.array(img_a_rgb.resize(size, Image.Resampling.LANCZOS).convert("L"))
        arr_b = np.array(img_b_rgb.resize(size, Image.Resampling.LANCZOS).convert("L"))

    return _clamp01(float(ssim(arr_a, arr_b, data_range=255)))


def _compute_clip_embeddings(assets: List[ImageAsset], progress: ProgressPrinter, label: str) -> None:
    if not assets:
        return

    model, preprocess = _get_clip_components()

    with torch.no_grad():
        total = len(assets)
        for idx, asset in enumerate(assets, start=1):
            image = preprocess(asset.image_rgb).unsqueeze(0).to(_device)
            emb = model.encode_image(image)
            emb = emb / emb.norm(dim=-1, keepdim=True)
            asset.clip_embedding = emb.squeeze(0).detach().cpu().numpy().astype(np.float32)
            progress.update(idx, total, f"{label} {Path(asset.path).name}")


def _clip_similarity_from_embeddings(reference: ImageAsset, runtime: ImageAsset) -> float:
    if reference.clip_embedding is None or runtime.clip_embedding is None:
        raise ValueError("CLIP embedding is missing.")
    cosine = float(np.dot(reference.clip_embedding, runtime.clip_embedding))
    return _clamp01((cosine + 1.0) / 2.0)


def _weighted_similarity_score(reference: ImageAsset, runtime: ImageAsset) -> Dict[str, float]:
    ssim_value = _ssim_score(reference.gray, runtime.gray, reference.image_rgb, runtime.image_rgb)
    clip_value = _clip_similarity_from_embeddings(reference, runtime)
    final_score = WEIGHT_SSIM * ssim_value + WEIGHT_CLIP * clip_value

    return {
        "final": round(_clamp01(final_score), 6),
        "ssim": round(_clamp01(ssim_value), 6),
        "clip": round(_clamp01(clip_value), 6),
    }


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

    class VisualPairFeedback(BaseModel):
        overall: str = Field(description="PASS / FAIL")
        similarity_score: float = Field(description="0-100")
        differences: List[Dict[str, Any]] = Field(description="Difference items with impact/category")
        summary: str = Field(description="A short summary in Chinese")
        suggestions: str = Field(description="Actionable suggestions for improving consistency")

    api_key = str(os.getenv("DASHSCOPE_API_KEY", "")).strip()
    if not api_key:
        raise ValueError("DASHSCOPE_API_KEY is missing.")

    llm = ChatOpenAI(
        model=model_name,
        api_key=api_key,
        base_url="https://dashscope.aliyuncs.com/compatible-mode/v1",
        temperature=0.0,
    )
    return llm.with_structured_output(VisualPairFeedback)


def _vlm_compare_pair(
    llm: Any,
    runtime_image_path: str,
    runtime_b64: str,
    reference_image_path: str,
    reference_b64: str,
    score_payload: Dict[str, float],
) -> Dict[str, Any]:
    try:
        messages_module = importlib.import_module("langchain_core.messages")
    except Exception as exc:
        raise RuntimeError("langchain-core is missing for VLM invocation.") from exc

    HumanMessage = getattr(messages_module, "HumanMessage")
    SystemMessage = getattr(messages_module, "SystemMessage")

    prompt = (
        "你是移动端 UI 快速验收助手。"
        "只判断是否“大致相似”，不要做像素级或过度细节分析。"
        "判定标准：\n"
        "1) 页面主结构是否一致（头部/主体/底部、主要分区）。\n"
        "2) 关键组件是否存在（核心按钮、输入区、列表/卡片）。\n"
        "3) 主要文案语义是否一致。\n"
        "4) 顶部的系统信号、时间、电量等信息不是 UI 设计的一部分，坚决不要进行解析和输出。\n"
        "5) 图标不要求完全一致，只要语义和功能一致即可。\n"
        "可忽略：小间距、小字号差异、轻微颜色偏差、圆角细节、顶部状态栏。\n"
        "输出严格 JSON："
        '{"overall":"PASS|FAIL","similarity_score":0-100,'
        '"differences":[{"item":"...","impact":"high|medium|low","category":"layout|component|text|style"}],'
        '"summary":"...",'
        '"suggestions":"..."}\n'
        "当 similarity_score >= 70 时给 PASS，否则 FAIL。"
    )

    content = [
        {
            "type": "text",
            "text": (
                "算法分数(仅参考): "
                f"final={score_payload.get('final', 0)}, "
                f"ssim={score_payload.get('ssim', 0)}, "
                f"clip={score_payload.get('clip', 0)}"
            ),
        },
        {"type": "text", "text": f"[Runtime] {runtime_image_path}"},
        {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{runtime_b64}"}},
        {"type": "text", "text": f"[Reference] {reference_image_path}"},
        {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{reference_b64}"}},
    ]

    result: Any = llm.invoke([SystemMessage(content=prompt), HumanMessage(content=content)])
    if hasattr(result, "model_dump"):
        return result.model_dump()
    if isinstance(result, dict):
        return result
    return {"raw": str(result)}


def _relative_paths(path_value: Path, root: Path) -> str:
    try:
        return path_value.resolve().relative_to(root.resolve()).as_posix()
    except Exception:
        return str(path_value)


def _build_user_markdown(report: Dict[str, Any]) -> str:
    stats = report.get("stats", {}) if isinstance(report, dict) else {}
    rows = report.get("pair_results", []) if isinstance(report, dict) else []

    lines: List[str] = [
        "# Visual Review Summary",
        "",
        f"- runtime_image_count: {stats.get('runtime_image_count', 0)}",
        f"- reference_image_count: {stats.get('reference_image_count', 0)}",
        f"- matched_count: {stats.get('matched_count', 0)}",
        f"- avg_top1_score: {stats.get('avg_top1_score', 0)}",
        "",
        "## Top1 Matches",
    ]

    if not rows:
        lines.append("- No matches found")
        lines.append("")
        return "\n".join(lines)

    for row in rows:
        reference_path = str(row.get("reference_image_path_rel") or row.get("reference_image_path") or "")
        runtime_path = str(row.get("runtime_image_path_rel") or row.get("runtime_image_path") or "")
        score = row.get("score", {}) if isinstance(row.get("score"), dict) else {}
        final_score = score.get("final", 0)
        lines.append(f"- {reference_path} -> {runtime_path} (score={final_score})")

        feedback = row.get("visual_feedback", {}) if isinstance(row.get("visual_feedback"), dict) else {}
        if feedback.get("status") == "ok":
            review = feedback.get("review", {}) if isinstance(feedback.get("review"), dict) else {}
            summary = str(review.get("summary", "")).strip()
            suggestions = str(review.get("suggestions", "")).strip()
            verdict = str(review.get("overall", "")).strip() or str(review.get("verdict", "")).strip() or "UNKNOWN"
            sim_score = review.get("similarity_score", None)
            if summary:
                if sim_score is None:
                    lines.append(f"  overall={verdict}; {summary}")
                else:
                    lines.append(f"  overall={verdict}; similarity_score={sim_score}; {summary}")
            if suggestions:
                lines.append(f"  suggestions={suggestions}")

    lines.append("")
    return "\n".join(lines)


def run_visual_review_page_elem(
    review_output_dir: Path,
    output_json_path: Path,
    user_input_dir: Path,
    show_progress: bool = True,
    use_llm: bool = True,
    llm_model: str = DEFAULT_VLM_MODEL,
    architect_output_path: Optional[Path] = None,
) -> Dict[str, Any]:
    _ = architect_output_path
    t0 = time.perf_counter()
    progress = ProgressPrinter(enabled=show_progress)
    prepare_t0 = time.perf_counter()

    progress.stage("Collecting images")
    runtime_paths_all = _collect_images(review_output_dir)
    runtime_paths = [path for path in runtime_paths_all if _is_runtime_image_selected(path)]
    runtime_filtered_out_count = max(0, len(runtime_paths_all) - len(runtime_paths))
    reference_paths = _collect_images(user_input_dir)

    if not runtime_paths:
        raise ValueError(
            "No runtime images found after filtering (only init screen/after, excluding before/return) "
            f"under: {review_output_dir}"
        )
    if not reference_paths:
        raise ValueError(f"No user input images found under: {user_input_dir}")

    progress.stage("Loading images")
    runtime_assets: List[ImageAsset] = []
    for idx, path in enumerate(runtime_paths, start=1):
        runtime_assets.append(_load_image_asset(path))
        progress.update(idx, len(runtime_paths), f"loading runtime {path.name}")

    reference_assets: List[ImageAsset] = []
    for idx, path in enumerate(reference_paths, start=1):
        reference_assets.append(_load_image_asset(path))
        progress.update(idx, len(reference_paths), f"loading reference {path.name}")

    progress.stage("Computing CLIP embeddings")
    _compute_clip_embeddings(reference_assets, progress, "embedding reference")
    _compute_clip_embeddings(runtime_assets, progress, "embedding runtime")
    prepare_seconds = round(time.perf_counter() - prepare_t0, 3)

    llm_requested = bool(use_llm)
    llm_used = False
    llm_error = ""
    llm = None
    if llm_requested:
        progress.stage(f"Initializing VLM reviewer ({llm_model})")
        try:
            llm = _build_vlm(llm_model)
            llm_used = True
        except Exception as exc:
            llm_error = str(exc)

    progress.stage("Matching user input images to runtime top1 (1:1)")
    pair_results: List[Dict[str, Any]] = []
    score_sum = 0.0
    scoring_t0 = time.perf_counter()

    # Build all pair scores first, then assign greedily by highest score to enforce 1:1 mapping.
    score_records: List[Tuple[float, int, int, Dict[str, float]]] = []
    total_pairs = len(reference_assets) * len(runtime_assets)
    pair_counter = 0
    for ref_idx, reference in enumerate(reference_assets):
        for run_idx, runtime in enumerate(runtime_assets):
            score = _weighted_similarity_score(reference, runtime)
            score_records.append((float(score.get("final", 0.0)), ref_idx, run_idx, score))
            pair_counter += 1
            progress.update(pair_counter, total_pairs, f"scoring {Path(reference.path).name}")

    scoring_seconds = round(time.perf_counter() - scoring_t0, 3)

    score_records.sort(key=lambda item: item[0], reverse=True)

    assigned_ref_indices = set()
    assigned_run_indices = set()
    selected_pairs: List[Tuple[int, int, Dict[str, float]]] = []

    for _, ref_idx, run_idx, score in score_records:
        if ref_idx in assigned_ref_indices or run_idx in assigned_run_indices:
            continue
        assigned_ref_indices.add(ref_idx)
        assigned_run_indices.add(run_idx)
        selected_pairs.append((ref_idx, run_idx, score))
        if len(assigned_ref_indices) >= len(reference_assets):
            break
        if len(assigned_run_indices) >= len(runtime_assets):
            break

    progress.stage("Running pair review for selected matches")
    llm_t0 = time.perf_counter()
    total_selected = len(selected_pairs)
    for idx, (ref_idx, run_idx, best_score) in enumerate(selected_pairs, start=1):
        reference = reference_assets[ref_idx]
        runtime = runtime_assets[run_idx]

        score_sum += max(0.0, float(best_score.get("final", 0.0)))

        visual_feedback: Dict[str, Any] = {"status": "skipped", "reason": "llm_not_enabled"}
        if llm_requested and not llm_used:
            visual_feedback = {"status": "skipped", "reason": llm_error or "llm_not_available"}
        elif llm_used and llm is not None:
            try:
                review = _vlm_compare_pair(
                    llm=llm,
                    runtime_image_path=runtime.path,
                    runtime_b64=runtime.b64,
                    reference_image_path=reference.path,
                    reference_b64=reference.b64,
                    score_payload=best_score,
                )
                visual_feedback = {"status": "ok", "review": review}
            except Exception as exc:  # noqa: BLE001
                visual_feedback = {"status": "failed", "reason": str(exc)}

        pair_results.append(
            {
                "runtime_image_path": runtime.path,
                "reference_image_path": reference.path,
                "score": best_score,
                "visual_feedback": visual_feedback,
            }
        )
        progress.update(idx, total_selected, f"reviewing {Path(reference.path).name}")

    llm_review_seconds = round(time.perf_counter() - llm_t0, 3)

    progress.finish("Image matching completed")

    elapsed_seconds = round(time.perf_counter() - t0, 3)
    matched_count = len(pair_results)
    avg_score = round(score_sum / matched_count, 6) if matched_count else 0.0

    report = {
        "review_output_dir": str(review_output_dir),
        "user_input_dir": str(user_input_dir),
        "generated_at": time.strftime("%Y-%m-%dT%H:%M:%S"),
        "stats": {
            "runtime_image_total_count": len(runtime_paths_all),
            "runtime_image_count": len(runtime_assets),
            "runtime_image_filtered_out_count": runtime_filtered_out_count,
            "reference_image_count": len(reference_assets),
            "matched_count": matched_count,
            "reference_unmatched_count": max(0, len(reference_assets) - matched_count),
            "runtime_ignored_count": max(0, len(runtime_assets) - matched_count),
            "avg_top1_score": avg_score,
            "llm_requested": llm_requested,
            "llm_used": llm_used,
            "llm_model": llm_model if llm_requested else None,
            "image_prepare_seconds": prepare_seconds,
            "scoring_seconds": scoring_seconds,
            "llm_review_seconds": llm_review_seconds,
            "elapsed_seconds": elapsed_seconds,
        },
        "pair_results": pair_results,
        "llm_error": llm_error,
    }

    output_json_path.parent.mkdir(parents=True, exist_ok=True)

    project_root = Path(__file__).resolve().parent
    for row in pair_results:
        runtime_path = Path(str(row.get("runtime_image_path", "")))
        reference_path = Path(str(row.get("reference_image_path", "")))
        row["runtime_image_path_rel"] = _relative_paths(runtime_path, project_root)
        row["reference_image_path_rel"] = _relative_paths(reference_path, project_root)

    output_json_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")

    user_md_path = output_json_path.with_name(output_json_path.stem + "_user.md")
    user_md_path.write_text(_build_user_markdown(report), encoding="utf-8")

    report["machine_report_path"] = str(output_json_path)
    report["user_report_path"] = str(user_md_path)
    return report


def main() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Visual review: user-input-primary one-to-one matching. "
            "Find best runtime screenshot for each user input image using SSIM+CLIP, "
            "ignore extra runtime screenshots, then optionally run VLM pair comparison."
        )
    )
    parser.add_argument(
        "--review-output-dir",
        required=True,
        help="Directory containing runtime images (typically a report run folder).",
    )
    parser.add_argument(
        "--user-input-dir",
        required=True,
        help="Directory containing user input reference images.",
    )
    parser.add_argument(
        "--output-json",
        default="artifacts/visual_review_output.json",
        help="Path to save machine-readable review report JSON.",
    )
    parser.add_argument(
        "--architect-output",
        default="",
        help="Deprecated. Kept only for backward compatibility; ignored.",
    )
    parser.add_argument(
        "--no-progress",
        action="store_true",
        help="Disable progress output in terminal.",
    )
    parser.add_argument(
        "--disable-llm",
        action="store_true",
        help="Disable optional VLM pair comparison.",
    )
    parser.add_argument(
        "--llm-model",
        default=DEFAULT_VLM_MODEL,
        help=f"VLM model name (default: {DEFAULT_VLM_MODEL})",
    )
    args = parser.parse_args()

    report = run_visual_review_page_elem(
        review_output_dir=Path(args.review_output_dir).resolve(),
        output_json_path=Path(args.output_json).resolve(),
        user_input_dir=Path(args.user_input_dir).resolve(),
        show_progress=not args.no_progress,
        use_llm=not args.disable_llm,
        llm_model=args.llm_model,
        architect_output_path=Path(args.architect_output).resolve() if str(args.architect_output).strip() else None,
    )

    print(
        json.dumps(
            {
                "machine_report": report.get("machine_report_path", ""),
                "user_report": report.get("user_report_path", ""),
                "runtime_image_count": report.get("stats", {}).get("runtime_image_count", 0),
                "reference_image_count": report.get("stats", {}).get("reference_image_count", 0),
                "matched_count": report.get("stats", {}).get("matched_count", 0),
                "avg_top1_score": report.get("stats", {}).get("avg_top1_score", 0),
                "llm_used": report.get("stats", {}).get("llm_used", False),
                "elapsed_seconds": report.get("stats", {}).get("elapsed_seconds", None),
            },
            ensure_ascii=False,
            indent=2,
        )
    )


if __name__ == "__main__":
    main()
