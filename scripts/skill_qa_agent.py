from __future__ import annotations

import argparse
import sys
from pathlib import Path
from uuid import uuid4

REPO_ROOT = Path(__file__).resolve().parent.parent
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from deepagents.backends import FilesystemBackend
from deepagents import create_deep_agent

from models import base_model
from tools.human_guidance import request_human_guidance
from utils.checkpointing import get_checkpointer


def build_skill_qa_agent_spec() -> dict:
    return {
        "name": "skill_qa_agent",
        "model": base_model,
        "system_prompt": (
            "你是一个最小化问答 Agent。"
            "你的主要目标是回答关于 Harmony Next / HarmonyOS / ArkTS 的问题。"
            "优先利用已注入的 skills 获取结构化参考。"
            "保持回答简洁、准确。"
        ),
        "skills": ["/skills"],
        "tools": [request_human_guidance],
    }


def build_skill_qa_backend() -> FilesystemBackend:
    return FilesystemBackend(root_dir=REPO_ROOT / "agent_workspace", virtual_mode=True)


def build_skill_qa_agent():
    spec = build_skill_qa_agent_spec()
    return create_deep_agent(
        model=spec["model"],
        system_prompt=spec["system_prompt"],
        tools=spec["tools"],
        skills=spec["skills"],
        backend=build_skill_qa_backend(),
        checkpointer=get_checkpointer(),
        name=spec["name"],
    )


def ask(question: str) -> dict:
    agent = build_skill_qa_agent()
    return agent.invoke(
        {"messages": [{"role": "user", "content": question}]},
        config={"configurable": {"thread_id": f"skill-qa-agent-{uuid4()}"}},
    )


def main() -> None:
    parser = argparse.ArgumentParser(description="Minimal QA agent with /skills/harmony-next")
    parser.add_argument("question", help="Question to ask the agent")
    args = parser.parse_args()

    result = ask(args.question)
    messages = result.get("messages") or []
    if messages:
        final_message = messages[-1]
        content = getattr(final_message, "content", "")
        print(content)


if __name__ == "__main__":
    main()
