from tools.architect_tools import ARCHITECT_TOOLS
from tools.human_guidance import request_human_guidance
from tools.project_tools import CODER_TOOLS
from tools.tester_tools import (
    TESTER_TOOLS,
    collect_reference_and_runtime_screenshots,
    compare_ui_pair_with_mini_agent,
    pair_reference_pages_with_runtime,
    resolve_review_target,
    run_review_node_with_inputs,
    run_visual_review_with_inputs,
    save_tester_report,
    summarize_review_features_by_page,
)

ARCHITECT_SUBAGENT_TOOLS = [request_human_guidance]
CODER_SUBAGENT_TOOLS = [*CODER_TOOLS, request_human_guidance]
TESTER_SUBAGENT_TOOLS = [*TESTER_TOOLS, request_human_guidance]

REVIEW_EXECUTOR_SUBAGENT_TOOLS = [
    resolve_review_target,
    run_review_node_with_inputs,
    request_human_guidance,
]


FLOW_SUMMARY_SUBAGENT_TOOLS = [
    summarize_review_features_by_page,
    request_human_guidance,
]


VISUAL_REVIEW_SUBAGENT_TOOLS = [
    run_visual_review_with_inputs,
    request_human_guidance,
]


MAIN_AGENT_TOOLS = [*ARCHITECT_TOOLS, request_human_guidance]
