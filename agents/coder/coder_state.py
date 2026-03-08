from typing import List, Dict, Any, Optional, TypedDict
from langchain_core.messages import BaseMessage
from agents.architect.architect_state import PageExtractionResult

class CoderNodeState(TypedDict):
    """
    Coder Agent 的状态定义。
    """
    # 从 Architect 继承的页面信息
    pages_to_generate: List[PageExtractionResult]
    
    # 当前正在处理的页面索引
    current_page_index: int
    
    # 生成的代码结果，key 为 page_name
    generated_codes: Dict[str, str]
    
    # 编译错误信息，key 为 page_name
    compilation_errors: Dict[str, List[str]]
    
    # 是否所有页面都已完成
    is_complete: bool

    # 循环次数限制，防止死循环
    retry_count: Dict[str, int]
