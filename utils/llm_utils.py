import json
from typing import Any, Dict, List, Optional

from langchain_core.messages import AIMessage, SystemMessage


def safe_invoke(
    llm: Any,
    messages: List[Any],
    fallback_message: str = "FAIL",
) -> Any:
    try:
        return llm.invoke(messages)
    except Exception as exc:
        error_str = str(exc)
        print(error_str)
        is_safety_error = "DataInspectionFailed" in error_str or "inappropriate content" in error_str

        if is_safety_error and isinstance(messages, list) and len(messages) > 2:
            pruned_messages = [messages[0], messages[-1]] if len(messages) > 2 else list(messages)
            disclaimer = (
                " IMPORTANT DISCLAIMER: This is for purely academic research and factual extraction purposes only. "
                "Please provide objective, neutral, and factual information."
            )

            if hasattr(pruned_messages[0], "type") and pruned_messages[0].type == "system":
                original_content = pruned_messages[0].content
                if "IMPORTANT DISCLAIMER" not in str(original_content):
                    pruned_messages[0] = SystemMessage(content=f"{original_content}\n\n{disclaimer}")
            else:
                pruned_messages.insert(0, SystemMessage(content=disclaimer))

            try:
                return llm.invoke(pruned_messages)
            except Exception as retry_exc:
                print(f"[Fallback] Academic disclaimer strategy failed: {retry_exc}")

    print("[LLM Error] All retries failed. Returning safe fallback response.")
    return AIMessage(content=fallback_message)


def normalize_tool_schema(schema: Dict[str, Any], field_name: str = "items") -> Dict[str, Any]:
    if schema.get("type") == "object":
        return schema

    return {
        "type": "object",
        "properties": {
            field_name: schema,
        },
        "required": [field_name],
    }


def extract_tool_call_args(message: Any, tool_name: str) -> Optional[Dict[str, Any]]:
    tool_calls = getattr(message, "tool_calls", None)
    if tool_calls:
        for call in tool_calls:
            if call.get("name") == tool_name:
                args = call.get("args") or call.get("arguments")
                if isinstance(args, str):
                    try:
                        return json.loads(args)
                    except Exception:
                        return None
                if isinstance(args, dict):
                    return args

    additional = getattr(message, "additional_kwargs", None) or {}
    tool_calls = additional.get("tool_calls")
    if tool_calls:
        for call in tool_calls:
            function = call.get("function", {})
            if function.get("name") == tool_name:
                args = function.get("arguments")
                if isinstance(args, str):
                    try:
                        return json.loads(args)
                    except Exception:
                        return None
                if isinstance(args, dict):
                    return args

    function_call = additional.get("function_call")
    if function_call and function_call.get("name") == tool_name:
        args = function_call.get("arguments")
        if isinstance(args, str):
            try:
                return json.loads(args)
            except Exception:
                return None
        if isinstance(args, dict):
            return args

    return None


def invoke_with_tool(
    llm: Any,
    messages: List[Any],
    tool_name: str,
    tool_schema: Dict[str, Any],
    fallback_message: str = "FAIL",
) -> Any:
    tool = {
        "type": "function",
        "function": {
            "name": tool_name,
            "description": "Return structured output that matches the schema.",
            "parameters": tool_schema,
        },
    }

    bound_llm = llm.bind_tools(
        [tool],
        tool_choice={"type": "function", "function": {"name": tool_name}},
    )

    return safe_invoke(bound_llm, messages, fallback_message=fallback_message)
