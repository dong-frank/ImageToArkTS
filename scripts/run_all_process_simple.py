#!/usr/bin/env python3
from __future__ import annotations

import argparse
import importlib.util
import json
import sys
import time
from pathlib import Path
from typing import Any
from urllib import error

PROJECT_ROOT = Path(__file__).resolve().parents[1]
SESSIONS_ROOT = PROJECT_ROOT / "agent_workspace" / "sessions"
RUNNER_PATH = PROJECT_ROOT / "scripts" / "run_process_simple.py"

if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))


def _load_runner_module():
    spec = importlib.util.spec_from_file_location("run_process_simple", RUNNER_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load runner module from {RUNNER_PATH}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


RUNNER = _load_runner_module()


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Run /process-simple for all existing session directories.")
    parser.add_argument("--prompt", default="", help="Shared prompt for every session.")
    parser.add_argument("--prompt-file", default="", help="Optional prompt file for every session.")
    parser.add_argument("--base-url", default="http://127.0.0.1:8080", help="Runtime base URL.")
    parser.add_argument("--sessions-root", default=str(SESSIONS_ROOT), help="Session root directory to scan.")
    parser.add_argument("--include-default", action="store_true", help="Include the default session directory.")
    parser.add_argument("--session-ids", nargs="*", default=[], help="Optional explicit session ids to run.")
    parser.add_argument("--start-from", default="", help="Run only session ids >= this value.")
    parser.add_argument("--end-at", default="", help="Run only session ids <= this value.")
    parser.add_argument("--show-events", action="store_true", help="Print streamed text/tool events for each session.")
    parser.add_argument("--show-debug-events", action="store_true", help="Print status_update/debug SSE events too.")
    parser.add_argument("--summary-json", default="", help="Optional path to save the batch summary JSON.")
    return parser


def discover_session_ids(sessions_root: Path) -> list[str]:
    if not sessions_root.exists():
        return []
    session_ids: list[str] = []
    for item in sorted(sessions_root.iterdir(), key=lambda path: path.name):
        if not item.is_dir():
            continue
        if item.name.startswith("."):
            continue
        session_ids.append(item.name)
    return session_ids


def select_session_ids(
    *,
    sessions_root: Path,
    explicit_ids: list[str],
    include_default: bool,
    start_from: str,
    end_at: str,
) -> list[str]:
    if explicit_ids:
        session_ids = [RUNNER.normalize_session_id(item) for item in explicit_ids if str(item).strip()]
    else:
        session_ids = discover_session_ids(sessions_root)

    selected: list[str] = []
    for session_id in session_ids:
        if session_id == "default" and not include_default:
            continue
        if start_from and session_id < start_from:
            continue
        if end_at and session_id > end_at:
            continue
        selected.append(session_id)
    return selected


def format_duration_seconds(seconds: float) -> str:
    if seconds < 60:
        return f"{seconds:.2f}s"
    minutes, remainder = divmod(seconds, 60)
    return f"{int(minutes)}m{remainder:.2f}s"


def build_summary_row(session_id: str, status: str, elapsed_seconds: float, error_text: str = "") -> dict[str, Any]:
    return {
        "session_id": session_id,
        "status": status,
        "elapsed_seconds": elapsed_seconds,
        "error": error_text,
    }


def run_one_session(
    *,
    session_id: str,
    prompt: str,
    base_url: str,
    show_events: bool,
    show_debug_events: bool,
) -> dict[str, Any]:
    payload = RUNNER.build_process_simple_payload(session_id=session_id, prompt=prompt)
    error_text = ""
    status = "ok"
    started_at = time.perf_counter()

    try:
        for event in RUNNER.post_process_simple(base_url, payload):
            if show_events or (show_debug_events and event.get("kind") == "status_update"):
                RUNNER.render_event(event, show_debug_events=show_debug_events)
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

    elapsed_seconds = time.perf_counter() - started_at
    return build_summary_row(session_id=session_id, status=status, elapsed_seconds=elapsed_seconds, error_text=error_text)


def print_summary(rows: list[dict[str, Any]], total_elapsed_seconds: float) -> None:
    print("\n=== Batch Summary ===")
    for row in rows:
        print(
            f"{row['session_id']}: status={row['status']} "
            f"elapsed={format_duration_seconds(float(row.get('elapsed_seconds') or 0.0))}"
            + (f" error={row['error']}" if row.get("error") else "")
        )

    print("\n=== Timing ===")
    print(f"sessions={len(rows)} total_elapsed={format_duration_seconds(total_elapsed_seconds)}")


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    prompt = RUNNER.load_prompt_text(args.prompt, args.prompt_file)
    sessions_root = Path(args.sessions_root)
    session_ids = select_session_ids(
        sessions_root=sessions_root,
        explicit_ids=list(args.session_ids),
        include_default=args.include_default,
        start_from=str(args.start_from or "").strip(),
        end_at=str(args.end_at or "").strip(),
    )

    if not session_ids:
        print(f"no session ids found under: {sessions_root}")
        return 1

    batch_started_at = time.perf_counter()
    rows: list[dict[str, Any]] = []
    for index, session_id in enumerate(session_ids, start=1):
        print(f"\n[{index}/{len(session_ids)}] session_id={session_id}")
        row = run_one_session(
            session_id=session_id,
            prompt=prompt,
            base_url=args.base_url,
            show_events=args.show_events,
            show_debug_events=args.show_debug_events,
        )
        rows.append(row)

    total_elapsed_seconds = time.perf_counter() - batch_started_at
    print_summary(rows, total_elapsed_seconds=total_elapsed_seconds)

    if str(args.summary_json or "").strip():
        target = Path(args.summary_json)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(json.dumps(rows, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"\nsummary_json: {target}")

    failed = [row for row in rows if row.get("status") != "ok"]
    return 0 if not failed else 1


if __name__ == "__main__":
    raise SystemExit(main())