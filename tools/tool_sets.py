from tools.human_guidance import request_human_guidance
from tools.json_tools import validate_json_syntax
from tools.project_tools import CODER_TOOLS
from tools.routing_tools import ROUTING_TOOLS
from tools.tester_tools import TESTER_TOOLS

ARCHITECT_SUBAGENT_TOOLS = [validate_json_syntax, request_human_guidance]
CODER_SKELETON_WORKER_TOOLS = [validate_json_syntax, request_human_guidance]
CODER_PAGE_WORKER_TOOLS = [validate_json_syntax, request_human_guidance]
CODER_INTEGRATION_WORKER_TOOLS = [*CODER_TOOLS, validate_json_syntax, request_human_guidance]
TESTER_SUBAGENT_TOOLS = [*TESTER_TOOLS, validate_json_syntax, request_human_guidance]
ORCHESTRATOR_AGENT_TOOLS = [*ROUTING_TOOLS, validate_json_syntax, request_human_guidance]
