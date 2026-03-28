from deepagents import create_deep_agent

from models import base_model, vision_model
from schemas import ArchitectOutput
from tools import (
    assert_state,
    build_test_plan_from_inputs,
    capture_app_screenshot,
    click_element,
    compare_ui_pair_with_mini_agent,
    collect_reference_and_runtime_screenshots,
    compile_project,
    create_project,
    dump_app_layout,
    install_harmony_app,
    press_back,
    request_human_guidance,
    read_description_baseline,
    save_architect_design,
    save_tester_report,
    start_harmony_app,
    swipe_screen,
    wait_for_ui_stable,
)
from utils.checkpointing import get_checkpointer
from utils.session_backend import backend_factory
from utils.utils import load_prompt


architect_subagent = {
    "name": "architect",
    "description": "架构师 Agent，负责拆解用户意图并生成结构化设计方案。",
    "model": vision_model,
    "system_prompt": load_prompt("architect_system_prompt.md"),
    "response_format": ArchitectOutput,
    "tools": [request_human_guidance],
}

coding_subagent = {
    "name": "coder",
    "description": "编码 Agent，负责将架构方案转化为可编译的项目实现。",
    "model": base_model,
    "system_prompt": load_prompt("coder_system_prompt.md"),
    "skills": ["/skills"],
    "tools": [create_project, compile_project, request_human_guidance],
}

test_subagent = {
    "name": "tester",
    "description": "测试验收 Agent，负责启动 app、按坐标点击验证流程并基于 description 做功能与静态 UI 完整性验收。",
    "model": vision_model,
    "system_prompt": load_prompt("tester_system_prompt.md"),
    "tools": [
        request_human_guidance,
        read_description_baseline,
        build_test_plan_from_inputs,
        install_harmony_app,
        start_harmony_app,
        dump_app_layout,
        click_element,
        wait_for_ui_stable,
        assert_state,
        capture_app_screenshot,
        press_back,
        swipe_screen,
        collect_reference_and_runtime_screenshots,
        compare_ui_pair_with_mini_agent,
        save_tester_report,
    ],
}

subagents = [architect_subagent, coding_subagent, test_subagent]

agent = create_deep_agent(
    model=base_model,
    system_prompt=load_prompt("system_prompt.md"),
    subagents=subagents,
    backend=backend_factory,
    tools=[save_architect_design, request_human_guidance],
    checkpointer=get_checkpointer(),
)

graph = agent


def run_agent():
    return agent.invoke(
        {
            "messages": [
                {
                    "role": "user",
                    "content": "用户输入资料都在 /user_input 目录下，请只将该目录内容视为用户输入并开始工作。",
                }
            ]
        }
    )


if __name__ == "__main__":
    run_agent()
