from tools.architect_tools import ARCHITECT_TOOLS
from tools.human_guidance import request_human_guidance
from tools.project_tools import CODER_TOOLS
from tools.tester_tools import TESTER_TOOLS

ARCHITECT_SUBAGENT_TOOLS = [request_human_guidance]
CODER_SUBAGENT_TOOLS = [*CODER_TOOLS, request_human_guidance]
TESTER_SUBAGENT_TOOLS = [*TESTER_TOOLS, request_human_guidance]
MAIN_AGENT_TOOLS = [*ARCHITECT_TOOLS, request_human_guidance]
