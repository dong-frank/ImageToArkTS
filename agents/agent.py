from agentscope_runtime.engine import AgentApp
from langgraph.graph import StateGraph, START, END

from agents.state import CustomAgentState

from agents.architect.architect_node import build_graph as build_architect_graph

agent_app = AgentApp(
    app_name="ImageToArkTS",
    app_description="An agent working on Image to ArkTS",
)

class SubgraphNode:
    """
    通用子图节点包装器。
    用于将子图（如 Architect, Coder 等）集成到主图中。
    它负责从全局状态中提取特定子图的输入状态，调用子图，并将结果写回全局状态。
    """
    def __init__(self, subgraph, state_key: str):
        """
        Args:
            subgraph: 已编译的 LangGraph 子图对象 (CompiledGraph)。
            state_key (str): 在全局 CustomAgentState 中对应的字段名 (例如 "architect_state")。
        """
        self.subgraph = subgraph
        self.state_key = state_key

    def __call__(self, state: CustomAgentState) -> dict:
        # 1. 从全局状态提取子图所需的输入状态
        input_state = state.get(self.state_key)
        
        # 2. 检查状态是否存在
        if input_state is None:
            # 如果没有初始化，这里简单返回 None，或者您可以添加日志/错误处理
            return {self.state_key: None}

        # 3. 调用子图
        result = self.subgraph.invoke(input_state)
        
        # 4. 将子图的输出结果封装回全局状态对应的字段
        return {self.state_key: result}


@agent_app.init
async def initialize(self):
    # TODO set llm

    graph = StateGraph(CustomAgentState)
    
    # 1. 构建子图
    architect_graph = build_architect_graph()
    
    # 2. 使用通用包装器创建节点
    architect_node = SubgraphNode(architect_graph, "architect_state")
    graph.add_node("architect", architect_node)

    # 3. 设置入口点
    graph.add_edge(START, "architect")
    
    # 4. 设置结束点
    graph.add_edge("architect", END)
    
    return graph


