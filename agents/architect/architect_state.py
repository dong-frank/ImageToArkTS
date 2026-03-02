import operator
from typing import List, Dict, Any, Annotated, TypedDict
from pydantic import BaseModel, Field
from langchain_core.messages import HumanMessage, SystemMessage
from langchain_openai import ChatOpenAI
from langgraph.graph import StateGraph, START, END
from langgraph.constants import Send
from langchain.agents import AgentState

## TODO 抽离出一个state给全局agent
class ArchitectNodeState(AgentState):
    pass

# ================= 1. Pydantic 结构化输出模型 =================、
# 请忽略，暂不需要
# class DataNeed(BaseModel):
#     field_name: str = Field(description="推测的数据字段名，如 title, createTime")
#     type: str = Field(description="数据类型，如 string, boolean, Array<Image>")
#     description: str = Field(description="该字段在 UI 上的具体作用描述")

class PageExtractionResult(BaseModel):
    page_name: str = Field(description="页面或模块名称")
    # local_data_needs: List[DataNeed] = Field(description="该页面所有需要动态绑定的数据字段") # 暂不需要
    ui_tree: Dict[str, Any] = Field(description="主页面的 ArkUI 弹性布局 JSON 树")

# ================= 2. 状态定义 (State) =================
class ProjectState(TypedDict):
    global_description: str
    folder_tree: Dict[str, Any]
    image_assets: List[Dict[str, str]] # 包含 image_path, image_data(base64)
    extracted_ui_data: Annotated[List[Dict[str, Any]], operator.add] 
    global_data_models: List[Dict[str, Any]]
    
# 并行子任务的局部状态 (每个 Vision Node 只接收自己那个文件夹的图片)
class VisionTaskState(TypedDict):
    folder_path: str
    father_folder: str
    children_folders: List[str]
    images: List[Dict[str, str]]