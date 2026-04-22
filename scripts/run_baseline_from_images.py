#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import mimetypes
import shutil
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, BinaryIO, Iterable
from urllib import error, request

PROJECT_ROOT = Path(__file__).resolve().parents[1]

if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from utils.session_workspace import (  # noqa: E402
    normalize_session_id,
    session_user_input_dir,
    session_user_input_meta_path,
    session_workspace_dir,
)

IMAGE_EXTENSIONS = {
    ".png",
    ".jpg",
    ".jpeg",
    ".webp",
    ".bmp",
    ".gif",
    ".heic",
    ".heif",
    ".svg",
}
DEFAULT_PROMPT = "User input artifacts are under /user_input. Start the coding workflow."


@dataclass
class ImageCase:
    case_name: str
    files: list[Path]


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Read images from a folder, prepare session user_input, "
            "and run baseline full flow via /process-simple."
        )
    )
    parser.add_argument("--images-root", required=True, help="Root folder containing images or case subfolders.")
    parser.add_argument(
        "--mode",
        choices=("file", "dir"),
        default="file",
        help="file: each image is one session. dir: each first-level subfolder is one session.",
    )
    parser.add_argument("--recursive", action="store_true", help="Recursively discover images inside folders.")
    parser.add_argument("--session-prefix", default="baseline", help="Prefix for generated session ids.")
    parser.add_argument("--start-index", type=int, default=1, help="Start index for generated session ids.")
    parser.add_argument("--max-cases", type=int, default=0, help="Limit number of cases to run. 0 means no limit.")
    parser.add_argument("--image-description", default="", help="Optional description written for each image metadata.")
    parser.add_argument("--prompt", default="", help="User text sent to /process-simple.")
    parser.add_argument("--prompt-file", default="", help="Optional prompt file.")
    parser.add_argument("--base-url", default="http://127.0.0.1:8080", help="Runtime base URL.")
    parser.add_argument("--show-events", action="store_true", help="Print streamed text/tool events.")
    parser.add_argument("--show-debug-events", action="store_true", help="Print status_update/debug events too.")
    parser.add_argument("--summary-json", default="", help="Optional path to save run summary JSON.")
    parser.add_argument("--dry-run", action="store_true", help="Only prepare/plan sessions, do not call runtime.")
    return parser


def is_image_file(path: Path) -> bool:
    return path.is_file() and path.suffix.lower() in IMAGE_EXTENSIONS


def discover_images(root: Path, recursive: bool) -> list[Path]:
    iterator = root.rglob("*") if recursive else root.glob("*")
    files = [item for item in iterator if is_image_file(item)]
    return sorted(files, key=lambda p: p.as_posix().lower())


def discover_cases(images_root: Path, mode: str, recursive: bool) -> list[ImageCase]:
    if mode == "file":
        images = discover_images(images_root, recursive=recursive)
        return [ImageCase(case_name=image.stem, files=[image]) for image in images]

    # mode == "dir"
    cases: list[ImageCase] = []
    subdirs = [item for item in sorted(images_root.iterdir(), key=lambda p: p.name.lower()) if item.is_dir()]
    for subdir in subdirs:
        images = discover_images(subdir, recursive=recursive)
        if not images:
            continue
        cases.append(ImageCase(case_name=subdir.name, files=images))
    return cases


def _safe_file_name(raw_name: str) -> str:
    sanitized = "".join(ch if ch.isalnum() or ch in {".", "_", "-"} else "_" for ch in raw_name)
    return sanitized or "image.bin"


def _dedup_file_name(name: str, used: set[str]) -> str:
    if name not in used:
        used.add(name)
        return name

    stem = Path(name).stem
    suffix = Path(name).suffix
    idx = 2
    while True:
        candidate = f"{stem}_{idx}{suffix}"
        if candidate not in used:
            used.add(candidate)
            return candidate
        idx += 1


def build_session_id(prefix: str, index: int, case_name: str, used_ids: set[str]) -> str:
    base = normalize_session_id(f"{prefix}_{index:04d}_{case_name}")
    if not base or base == "default":
        base = normalize_session_id(f"{prefix}_{index:04d}") or f"{prefix}_{index:04d}"

    candidate = base
    suffix = 2
    while candidate in used_ids:
        candidate = normalize_session_id(f"{base}_{suffix}") or f"{base}_{suffix}"
        suffix += 1
    used_ids.add(candidate)
    return candidate


def prepare_user_input(
    *,
    session_id: str,
    files: list[Path],
    image_description: str,
) -> list[dict[str, Any]]:
    user_input_dir = session_user_input_dir(PROJECT_ROOT, session_id)
    meta_path = session_user_input_meta_path(PROJECT_ROOT, session_id)
    user_input_dir.mkdir(parents=True, exist_ok=True)

    # Clean only files in user_input to avoid stale test inputs.
    for existing in user_input_dir.iterdir():
        if existing.is_file():
            existing.unlink()

    used_names: set[str] = set()
    metadata_files: dict[str, dict[str, Any]] = {}
    copied: list[dict[str, Any]] = []

    for src in files:
        safe_name = _dedup_file_name(_safe_file_name(src.name), used_names)
        target = user_input_dir / safe_name
        shutil.copy2(src, target)

        content_type = mimetypes.guess_type(str(target))[0] or "application/octet-stream"
        description = image_description.strip() or None
        metadata_files[safe_name] = {
            "name": safe_name,
            "description": description,
            "path": f"/user_input/{safe_name}",
            "content_type": content_type,
        }
        copied.append(
            {
                "source": str(src),
                "name": safe_name,
                "path": f"/user_input/{safe_name}",
            }
        )

    meta_payload = {"files": metadata_files}
    meta_path.write_text(json.dumps(meta_payload, ensure_ascii=False, indent=2), encoding="utf-8")
    return copied


def load_prompt_text(prompt: str, prompt_file: str) -> str:
    file_value = str(prompt_file or "").strip()
    if file_value:
        return Path(file_value).read_text(encoding="utf-8")
    return str(prompt or "").strip() or DEFAULT_PROMPT


def build_process_simple_payload(session_id: str, prompt: str) -> dict[str, Any]:
    return {
        "session_id": normalize_session_id(session_id),
        "input": [
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": prompt,
                    }
                ],
            }
        ],
    }


def iter_sse_events(stream: BinaryIO) -> Iterable[dict[str, Any]]:
    for raw_line in stream:
        line = raw_line.decode("utf-8", errors="replace").strip()
        if not line or not line.startswith("data:"):
            continue
        payload = line[len("data:") :].strip()
        if not payload:
            continue
        try:
            data = json.loads(payload)
        except json.JSONDecodeError:
            continue
        if isinstance(data, dict):
            yield data


def render_event(event: dict[str, Any], *, show_debug_events: bool) -> None:
    kind = str(event.get("kind") or "").strip()
    if kind == "status_update" and not show_debug_events:
        return

    if kind == "tool":
        name = str(event.get("name") or "tool").strip()
        args = event.get("args")
        args_text = json.dumps(args, ensure_ascii=False) if args is not None else ""
        print(f"[tool] {name}" + (f" {args_text}" if args_text else ""))
        return

    if kind == "error":
        print(f"[error] {event.get('text', '')}")
        return

    if kind == "hitl":
        print("[hitl]")
        print(json.dumps(event.get("payload"), ensure_ascii=False, indent=2))
        return

    if kind == "done":
        print("[done]")
        return

    text = event.get("text")
    if isinstance(text, str) and text:
        print(text)
        return

    print(json.dumps(event, ensure_ascii=False))


def post_process_simple(base_url: str, payload: dict[str, Any]) -> Iterable[dict[str, Any]]:
    endpoint = base_url.rstrip("/") + "/process-simple"
    req = request.Request(
        endpoint,
        data=json.dumps(payload, ensure_ascii=False).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with request.urlopen(req) as response:
        yield from iter_sse_events(response)


def experiment_metrics_path(session_id: str) -> Path:
    normalized = normalize_session_id(session_id)
    return session_workspace_dir(PROJECT_ROOT, normalized) / "logs" / "experiment_metrics" / f"{normalized}.json"


def read_metrics_json(session_id: str) -> dict[str, Any]:
    metrics_path = experiment_metrics_path(session_id)
    if not metrics_path.exists():
        return {}
    try:
        return json.loads(metrics_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return {}


def run_one_session(
    *,
    session_id: str,
    prompt: str,
    base_url: str,
    show_events: bool,
    show_debug_events: bool,
) -> tuple[str, str]:
    payload = build_process_simple_payload(session_id=session_id, prompt=prompt)
    status = "ok"
    error_text = ""

    try:
        for event in post_process_simple(base_url, payload):
            if show_events or (show_debug_events and event.get("kind") == "status_update"):
                render_event(event, show_debug_events=show_debug_events)
            if event.get("kind") == "error":
                status = "error"
                error_text = str(event.get("text") or "")
    except error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        status = "http_error"
        error_text = f"HTTP {exc.code}: {body}"
    except error.URLError as exc:
        status = "request_error"
        error_text = str(exc)

    return status, error_text


def print_summary(rows: list[dict[str, Any]]) -> None:
    print("\n=== Baseline Batch Summary ===")
    for row in rows:
        print(
            f"{row['session_id']}: status={row['status']} "
            f"inputs={row.get('input_count')} "
            f"compile_count={row.get('compile_count')} "
            f"elapsed={row.get('total_elapsed_seconds')} "
            f"total_tokens={row.get('total_tokens')}"
            + (f" error={row['error']}" if row.get("error") else "")
        )


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    images_root = Path(args.images_root).resolve()
    if not images_root.exists() or not images_root.is_dir():
        print(f"images root not found: {images_root}")
        return 1

    prompt = load_prompt_text(args.prompt, args.prompt_file)
    cases = discover_cases(images_root, mode=args.mode, recursive=bool(args.recursive))
    if args.max_cases and args.max_cases > 0:
        cases = cases[: args.max_cases]

    if not cases:
        print(f"no image cases found under: {images_root}")
        return 1

    rows: list[dict[str, Any]] = []
    used_ids: set[str] = set()

    for idx, case in enumerate(cases, start=args.start_index):
        session_id = build_session_id(args.session_prefix, idx, case.case_name, used_ids)
        copied = prepare_user_input(
            session_id=session_id,
            files=case.files,
            image_description=args.image_description,
        )

        print(f"\n[{idx - args.start_index + 1}/{len(cases)}] session_id={session_id}")
        print(f"case={case.case_name} input_images={len(copied)}")

        status = "prepared"
        error_text = ""
        if not args.dry_run:
            status, error_text = run_one_session(
                session_id=session_id,
                prompt=prompt,
                base_url=args.base_url,
                show_events=bool(args.show_events),
                show_debug_events=bool(args.show_debug_events),
            )

        metrics = read_metrics_json(session_id)
        token_usage = metrics.get("token_usage", {}) if isinstance(metrics, dict) else {}
        compile_count = metrics.get("compile_count", 0) if isinstance(metrics, dict) else 0
        try:
            compile_count = int(compile_count)
        except (TypeError, ValueError):
            compile_count = 0
        rows.append(
            {
                "session_id": session_id,
                "case_name": case.case_name,
                "input_count": len(copied),
                "status": status,
                "compile_count": max(0, compile_count),
                "total_elapsed_seconds": metrics.get("total_elapsed_seconds"),
                "total_tokens": token_usage.get("total_tokens"),
                "error": error_text,
                "inputs": copied,
            }
        )

    print_summary(rows)

    if str(args.summary_json or "").strip():
        target = Path(args.summary_json)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(json.dumps(rows, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"\nsummary_json: {target}")

    if args.dry_run:
        return 0

    failed = [row for row in rows if row.get("status") != "ok"]
    return 0 if not failed else 1


if __name__ == "__main__":
    raise SystemExit(main())
