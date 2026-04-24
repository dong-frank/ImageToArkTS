from tools.architect_tools import (
    read_navigation_design,
    read_page_draft,
    read_page_drafts_index,
    read_page_file,
    read_page_merge_index,
    save_navigation_design,
    save_page_merge_result,
)
from tools.human_guidance import request_human_guidance
from tools.json_tools import validate_json_syntax
from tools.project_tools import CODER_TOOLS
from tools.routing_tools import ROUTING_TOOLS
from tools.tester_tools import TESTER_TOOLS

ARCHITECT_SUBAGENT_TOOLS = [
    read_page_drafts_index,
    read_page_draft,
    save_page_merge_result,
    read_page_merge_index,
    read_page_file,
    read_navigation_design,
    save_navigation_design,
    validate_json_syntax,
    request_human_guidance,
]

CODER_SKELETON_WORKER_TOOLS = [
    *CODER_TOOLS,
    validate_json_syntax,
    request_human_guidance,
]

CODER_PAGE_WORKER_TOOLS = [
    *CODER_TOOLS,
    validate_json_syntax,
    request_human_guidance,
]

CODER_INTEGRATION_WORKER_TOOLS = [
    *CODER_TOOLS,
    validate_json_syntax,
    request_human_guidance,
]

TESTER_SUBAGENT_TOOLS = [
    *TESTER_TOOLS,
    validate_json_syntax,
    request_human_guidance,
]

ORCHESTRATOR_AGENT_TOOLS = [
    *ROUTING_TOOLS,
    validate_json_syntax,
    request_human_guidance,
]