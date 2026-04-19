#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path
from typing import Any, BinaryIO, Iterable
from urllib import error, request

PROJECT_ROOT = Path(__file__).resolve().parents[1]

if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from utils.session_workspace import normalize_session_id  # noqa: E402

DEFAULT_PROMPT = "User input artifacts are under /user_input. Start the orchestration workflow."


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Call /process-simple for an existing session user_input set.")
    parser.add_argument("--session-id", required=True, help="Existing session id under agent_workspace/sessions/<session_id>.")
    parser.add_argument("--prompt", default="", help="User text sent to /process-simple. Defaults to the orchestration prompt.")
    parser.add_argument("--prompt-file", default="", help="Optional text file whose contents will be used as the prompt.")
    parser.add_argument("--base-url", default="http://127.0.0.1:8080", help="Runtime base URL.")
    parser.add_argument("--show-debug-events", action="store_true", help="Print status_update/debug SSE events.")
    return parser


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


def format_duration_seconds(seconds: float) -> str:
    if seconds < 60:
        return f"{seconds:.2f}s"
    minutes, remainder = divmod(seconds, 60)
    return f"{int(minutes)}m{remainder:.2f}s"


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    session_id = normalize_session_id(args.session_id)
    prompt = load_prompt_text(args.prompt, args.prompt_file)
    payload = build_process_simple_payload(session_id=session_id, prompt=prompt)

    print(f"session_id: {session_id}")
    print(f"base_url: {args.base_url}")
    print("requesting /process-simple ...")

    request_start = time.perf_counter()
    try:
        for event in post_process_simple(args.base_url, payload):
            render_event(event, show_debug_events=args.show_debug_events)
    except error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        print(f"HTTP {exc.code}: {body}")
        print(f"elapsed: {format_duration_seconds(time.perf_counter() - request_start)}")
        return 1
    except error.URLError as exc:
        print(f"request failed: {exc}")
        print(f"elapsed: {format_duration_seconds(time.perf_counter() - request_start)}")
        return 1

    print(f"elapsed: {format_duration_seconds(time.perf_counter() - request_start)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())