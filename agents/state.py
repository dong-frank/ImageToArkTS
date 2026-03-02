from typing import TypedDict, Optional
from langchain_core.messages import BaseMessage
from langgraph.graph import add_messages
from typing import Annotated

# 导入子 Agent 的状态定义
from agents.architect.architect_state import ArchitectNodeState

class CustomAgentState(TypedDict):
    """
    全局 Agent 的状态定义。
    它不仅包含基础的对话消息，还包含了各个子 Agent (如 Architect) 的状态。
    """
    messages: Annotated[list[BaseMessage], add_messages]
    
    # 将 Architect Agent 的状态作为一个字段包含进来
    architect_state: Optional[ArchitectNodeState]

