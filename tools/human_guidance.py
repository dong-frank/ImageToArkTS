from __future__ import annotations

import json

from langchain.tools import tool
from langgraph.types import interrupt


@tool
def request_human_guidance(
    problem_summary: str,
    recent_errors: str = "",
    ask: str = "请提供修复建议或额外约束，然后继续。",
) -> str:
    """
    Pause execution for human guidance and continue with the provided input.
    """
    payload = {
        "type": "human_guidance",
        "problem_summary": str(problem_summary or "").strip(),
        "recent_errors": str(recent_errors or "").strip(),
        "ask": str(ask or "").strip() or "请提供修复建议或额外约束，然后继续。",
    }
    decision = interrupt(payload)

    if isinstance(decision, dict):
        for key in ("guidance", "text", "message", "resume", "answer"):
            value = decision.get(key)
            if value is not None:
                return str(value)
        return json.dumps(decision, ensure_ascii=False)

    if isinstance(decision, str):
        return decision

    return str(decision)
