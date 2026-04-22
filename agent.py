from deepagents import create_deep_agent

from models import base_model
from tools.project_tools import CODER_TOOLS
from utils.checkpointing import get_checkpointer
from utils.experiment_metrics import mark_run_finished, merge_token_usage_from_result, reset_metrics_for_new_run
from utils.session_backend import backend_factory
from utils.utils import load_prompt


CODE_SUBAGENT_TOOLS = [*CODER_TOOLS]
MAIN_AGENT_TOOLS = []

code_subagent = {
    "name": "code",
    "description": "Build the HarmonyOS project from /user_input and compile until success.",
    "model": base_model,
    "system_prompt": load_prompt("coder_system_prompt.md"),
    "skills": ["/skills"],
    "tools": CODE_SUBAGENT_TOOLS,
}

agent = create_deep_agent(
    model=base_model,
    system_prompt=load_prompt("system_prompt.md"),
    subagents=[code_subagent],
    backend=backend_factory,
    tools=MAIN_AGENT_TOOLS,
    checkpointer=get_checkpointer(),
)

graph = agent


def run_agent():
    reset_metrics_for_new_run()
    try:
        result = agent.invoke(
            {
                "messages": [
                    {
                        "role": "user",
                        "content": "User input artifacts are under /user_input. Start the coding workflow.",
                    }
                ]
            }
        )
        merge_token_usage_from_result(result)
        return result
    finally:
        mark_run_finished()


if __name__ == "__main__":
    run_agent()
