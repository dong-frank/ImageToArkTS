from tools.human_guidance import request_human_guidance
from tools.json_tools import validate_json_syntax
from tools.project_tools import CODER_TOOLS
from tools.review_flow_tools import (
    run_review_node_with_inputs,
    run_visual_review_with_inputs,
    summarize_review_features_by_page,
)
from tools.routing_tools import ROUTING_TOOLS
from tools.tester_tools import TESTER_TOOLS

ARCHITECT_SUBAGENT_TOOLS = [validate_json_syntax, request_human_guidance]
CODER_SKELETON_WORKER_TOOLS = [validate_json_syntax, request_human_guidance]
CODER_PAGE_WORKER_TOOLS = [validate_json_syntax, request_human_guidance]
CODER_INTEGRATION_WORKER_TOOLS = [*CODER_TOOLS, validate_json_syntax, request_human_guidance]
TESTER_SUBAGENT_TOOLS = [*TESTER_TOOLS, validate_json_syntax, request_human_guidance]
REVIEW_EXECUTOR_SUBAGENT_TOOLS = [run_review_node_with_inputs, validate_json_syntax, request_human_guidance]
FLOW_SUMMARY_SUBAGENT_TOOLS = [summarize_review_features_by_page, validate_json_syntax, request_human_guidance]
VISUAL_REVIEW_SUBAGENT_TOOLS = [run_visual_review_with_inputs, validate_json_syntax, request_human_guidance]
ORCHESTRATOR_AGENT_TOOLS = [*ROUTING_TOOLS, validate_json_syntax, request_human_guidance]
