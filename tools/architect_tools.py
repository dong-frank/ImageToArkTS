from __future__ import annotations

import json
from typing import Any

from langchain.tools import tool
from pydantic import BaseModel, ValidationError

from schemas import ArchitectOutput
from tools.common import workspace_root


def _architect_design_path():
    return workspace_root() / "designs" / "architect.json"


def _normalize_architect_payload(payload: Any) -> dict:
    if isinstance(payload, ArchitectOutput):
        return payload.model_dump(mode="json", exclude_none=True)

    if isinstance(payload, BaseModel):
        validated = ArchitectOutput.model_validate(payload.model_dump(mode="json"))
        return validated.model_dump(mode="json", exclude_none=True)

    if isinstance(payload, dict):
        validated = ArchitectOutput.model_validate(payload)
        return validated.model_dump(mode="json", exclude_none=True)

    if isinstance(payload, str):
        try:
            parsed = json.loads(payload)
        except json.JSONDecodeError as exc:
            raise ValueError(f"architect 输出不是合法 JSON。错误：{exc}") from exc
        validated = ArchitectOutput.model_validate(parsed)
        return validated.model_dump(mode="json", exclude_none=True)

    raise ValueError(f"architect 输出类型不受支持：{type(payload).__name__}")


def save_architect_design_payload(payload: Any) -> str:
    try:
        normalized = _normalize_architect_payload(payload)
    except ValidationError as exc:
        return f"保存失败：architect 输出不符合 ArchitectOutput Schema。错误：{exc}"
    except ValueError as exc:
        return f"保存失败：{exc}"

    design_path = _architect_design_path()
    design_path.parent.mkdir(parents=True, exist_ok=True)
    design_path.write_text(
        json.dumps(normalized, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    return "architect 设计已保存到 /designs/architect.json"


def save_architect_design_content(content: str) -> str:
    return save_architect_design_payload(content)


@tool
def save_architect_design(content: str) -> str:
    """
    Save architect structured output JSON to /designs/architect.json.
    """
    print("start saving architect design")
    return save_architect_design_content(content)


ARCHITECT_TOOLS = [
    save_architect_design,
]


def architect_tool_names() -> list[str]:
    return [tool.name for tool in ARCHITECT_TOOLS]
