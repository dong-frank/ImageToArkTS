from deepagents import create_deep_agent

from models import architect_vision_model, base_model, vision_model
from tools.tool_sets import (
    ARCHITECT_SUBAGENT_TOOLS,
    CODER_SUBAGENT_TOOLS,
    FLOW_SUMMARY_SUBAGENT_TOOLS,
    MAIN_AGENT_TOOLS,
    REVIEW_EXECUTOR_SUBAGENT_TOOLS,
    VISUAL_REVIEW_SUBAGENT_TOOLS,
)
from utils.checkpointing import get_checkpointer
from utils.session_backend import backend_factory
from utils.utils import load_prompt


architect_subagent = {
    "name": "architect",
    "description": "Generate a structured implementation design from user input materials.",
    "model": architect_vision_model,
    "system_prompt": load_prompt("architect_system_prompt.md"),
    "tools": ARCHITECT_SUBAGENT_TOOLS,
}

coding_subagent = {
    "name": "coder",
    "description": "Implement the HarmonyOS project from the saved architecture design.",
    "model": base_model,
    "system_prompt": load_prompt("coder_system_prompt.md"),
    "skills": ["/skills"],
    "tools": CODER_SUBAGENT_TOOLS,
}

review_executor_subagent = {
    "name": "review_executor",
    "description": "Run review node full-flow testing right after coder finishes.",
    "model": vision_model,
    "system_prompt": load_prompt("review_executor_system_prompt.md"),
    "tools": REVIEW_EXECUTOR_SUBAGENT_TOOLS,
}

flow_summary_subagent = {
    "name": "flow_summary",
    "description": "Summarize implemented popup/state-change behaviors and implemented navigation paths from review outputs.",
    "model": vision_model,
    "system_prompt": load_prompt("flow_summary_system_prompt.md"),
    "tools": FLOW_SUMMARY_SUBAGENT_TOOLS,
}

visual_review_subagent = {
    "name": "visual_review",
    "description": "Run visual matching between user input references and runtime screenshots after flow summary.",
    "model": vision_model,
    "system_prompt": load_prompt("visual_review_system_prompt.md"),
    "tools": VISUAL_REVIEW_SUBAGENT_TOOLS,
}

subagents = [
    architect_subagent,
    coding_subagent,
    review_executor_subagent,
    flow_summary_subagent,
    visual_review_subagent,
]

agent = create_deep_agent(
    model=base_model,
    system_prompt=load_prompt("system_prompt.md"),
    subagents=subagents,
    backend=backend_factory,
    tools=MAIN_AGENT_TOOLS,
    checkpointer=get_checkpointer(),
)

graph = agent


def run_agent():
    return agent.invoke(
        {
            "messages": [
                {
                    "role": "user",
                    "content": "User input artifacts are under /user_input. Start the orchestration workflow.",
                }
            ]
        }
    )


if __name__ == "__main__":
    run_agent()
