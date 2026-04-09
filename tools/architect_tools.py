from __future__ import annotations

import json

from langchain.tools import tool

from tools.common import workspace_root


def _architect_design_path():
    return workspace_root() / "designs" / "architect.json"


@tool
def save_architect_design(content: str) -> str:
    """
    Save architect structured output JSON to /designs/architect.json.
    """
    print("start saving architect design")

    try:
        parsed = json.loads(content)
    except json.JSONDecodeError as exc:
        return f"保存失败：architect 输出不是合法 JSON。错误：{exc}"

    design_path = _architect_design_path()
    design_path.parent.mkdir(parents=True, exist_ok=True)
    design_path.write_text(
        json.dumps(parsed, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    return "architect 设计已保存到 /designs/architect.json"


ARCHITECT_TOOLS = [
    save_architect_design,
]


def architect_tool_names() -> list[str]:
    return [tool.name for tool in ARCHITECT_TOOLS]
