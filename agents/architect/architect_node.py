from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
from typing import Any, Dict, List

from langchain_core.messages import HumanMessage, SystemMessage
from langchain_openai import ChatOpenAI
from langgraph.types import Send
from langgraph.graph import END, START, StateGraph

from agents.architect.input_processor import build_initial_project_state
from agents.architect.architect_state import PageExtractionResult, ProjectState, VisionTaskState
from dotenv import load_dotenv
load_dotenv()
DEFAULT_INPUT_ROOT = (Path(__file__).resolve().parent / "Memo").resolve()
DEFAULT_OUTPUT_FILE = (Path(__file__).resolve().parent / "artifacts" / "architect_test_output.json").resolve()


def _get_dashscope_api_key() -> str:
    return (
        os.getenv("DASHSCOPE_API_KEY", "").strip()
    )


def _resolve_folder_path(image_item: Dict[str, str]) -> str:
    """兼容 input_processor 输出：由 image_path 自动推导 folder_path。"""
    if "folder_path" in image_item and image_item["folder_path"]:
        return image_item["folder_path"]

    image_path = image_item.get("image_path", "").replace("\\", "/")
    if "/" not in image_path:
        return "."
    return image_path.rsplit("/", 1)[0]


def _build_folder_hierarchy(grouped_images: Dict[str, List[Dict[str, str]]]) -> Dict[str, Dict[str, Any]]:
    folders = sorted(grouped_images.keys())
    folder_set = set(folders)
    hierarchy: Dict[str, Dict[str, Any]] = {}
    for folder in folders:
        father = folder.rsplit("/", 1)[0] if "/" in folder else ""
        if father not in folder_set:
            father = ""
        children = sorted(
            [candidate for candidate in folders if candidate.rsplit("/", 1)[0] == folder]
        )
        hierarchy[folder] = {
            "father_folder": father,
            "children_folders": children,
        }
    return hierarchy


def dispatch_vision_tasks(state: ProjectState):
    """
    任务分发器：
    1) 读取全局 image_assets
    2) 按 folder_path 分组
    3) 动态下发并行 Vision 子任务
    """
    images = state.get("image_assets", [])
    grouped_images: Dict[str, List[Dict[str, str]]] = {}

    for img in images:
        folder = _resolve_folder_path(img)
        normalized = dict(img)
        normalized["folder_path"] = folder
        grouped_images.setdefault(folder, []).append(normalized)

    hierarchy = _build_folder_hierarchy(grouped_images)

    return [
        Send(
            "vision_extractor_node",
            {
                "folder_path": folder,
                "father_folder": hierarchy.get(folder, {}).get("father_folder", ""),
                "children_folders": hierarchy.get(folder, {}).get("children_folders", []),
                "images": imgs,
            },
        )
        for folder, imgs in grouped_images.items()
    ]


def _build_mock_extraction(folder_path: str, father_folder: str, children_folders: List[str]) -> Dict[str, Any]:
    """当未配置 key 或模型失败时，返回可继续流程的兜底结构。"""
    print("[Warning] Using mock extraction for folder:", folder_path)
    return {
        "page_name": folder_path.split("/")[-1] if folder_path not in {"", "."} else "RootPage",
        "local_data_needs": [
            {
                "field_name": "title",
                "type": "string",
                "description": "页面标题或主文本",
            }
        ],
        "ui_tree": {
            "type": "Column",
            "props": {"width": "100%", "height": "100%"},
            "children": [
                {"type": "Text", "props": {"value": f"Mock UI for {folder_path}"}},
            ],
        },
        "overlays": [],
        "father_folder": father_folder,
        "children_folders": children_folders,
        "_folder_path": folder_path,
        "_mocked": True,
    }


def vision_extractor_node(state: VisionTaskState) -> dict:
    """
    并行视觉节点：
    - 有 key：调用 qwen-vl-max 做结构化提取
    - 无 key/失败：自动回退到 mock，保证完整测试可执行
    """
    folder_path = state["folder_path"]
    father_folder = state["father_folder"]
    children_folders = state["children_folders"]
    images = state["images"]

    if not images or any(not img.get("image_data") for img in images):
        fallback = _build_mock_extraction(folder_path, father_folder, children_folders)
        fallback["_error"] = "missing_image_data"
        return {"extracted_ui_data": [fallback]}

    api_key = _get_dashscope_api_key()
    if not api_key:
        fallback = _build_mock_extraction(folder_path, father_folder, children_folders)
        fallback["_error"] = "missing_api_key_env"
        return {"extracted_ui_data": [fallback]}

    llm = ChatOpenAI(
        model="qwen-vl-max",
        api_key=api_key,
        base_url="https://dashscope.aliyuncs.com/compatible-mode/v1",
        temperature=0.1,
    )

    structured_llm = llm.with_structured_output(PageExtractionResult)

    system_prompt = (
        """
# Role
你是一位资深的 HarmonyOS (ArkUI) 前端切图专家与数据建模分析师。

# Task
你将接收到一个页面所在文件夹的【多张 UI 状态图】（包含 1 张主视图，以及若干张菜单展开、弹窗等交互状态图）。
你需要将这些视觉信息进行“降维合成”，输出一个严格符合预设 JSON Schema 的结构化中间态数据 (IR)。

# Core Rules (绝对不可违背)
1. 【禁止绝对定位】：绝不允许输出 x, y, width=123px 等绝对坐标。必须使用 ArkUI 的弹性布局思维（Column 垂直排列，Row 水平排列，Stack 层叠，Flex，Blank 撑开剩余空间）。
2. 【智能识别列表】：如果视觉上存在 2 个以上高度相似的重复结构，禁止在 UI 树中平铺输出！必须使用一层 "type": "List" 包裹，且 children 中仅保留一个 "type": "ListItem" 作为渲染模板。
3. 【多图状态合成（菜单/弹窗内嵌）】：对于传入的菜单图、弹窗图（如右侧弹出的排序菜单），不要将其作为新页面。请将其作为独立的 UI 树，**直接内嵌**到触发它的那个主视图按钮或组件的 `overlay` 字段中。
4. 【忽略顶部的状态栏，电量等信息】：这些不是 UI 设计的一部分，不要进行解析。
5. 【页面跳转识别（内嵌）】：
    - 你会收到当前页面的 `father_folder` 和 `children_folders`。
    - 如果视觉中检测到“跳转到父页面”或“跳转到任一子页面”的按钮/区域，必须在该 UI 节点中直接注入 `jump_action` 字段。
    - `jump_action.target_folder` 必须是传入的 `father_folder` 或 `children_folders` 之一，以此实现精准的路由跳转。

# Workflow
1. 观察所有图片，识别出哪张是“主页面”，哪些是“局部状态/弹窗”。
2. 将主页面拆解为以 Column/Row 为主的嵌套树。
3. 将识别出的弹窗/菜单等局部状态，作为 `overlay` 对象嵌入到对应的触发组件节点中。
4. 识别所有页面跳转按钮，将跳转意图作为 `jump_action` 对象嵌入到对应的触发组件节点中。
5. 严格按照 JSON Schema 输出格式化结果。

# JSON Schema
{
  "page_name": "页面名称（通常从传入的文件夹名推断，如 MemoDetail）",
  "ui_tree": {
    "type": "Column",
    "layout_props": {
      "width": "100%",
      "height": "100%",
      "justifyContent": "FlexStart"
    },
    "children": [
      {
        "type": "Row",
        "description": "顶部导航栏",
        "children": [
          { 
            "type": "Icon", 
            "name": "back",
            "jump_action": {
              "target_folder": "Index",
              "action_type": "router.back",
              "trigger_text": "左上角返回按钮"
            }
          },
          { "type": "Blank" },
          { 
            "type": "Icon", 
            "name": "more",
            "overlay": {
              "type": "Menu",
              "description": "右上角更多按钮点击后弹出的菜单（从状态图中提取）",
              "children": [
                { "type": "MenuItem", "text": "扫描" },
                { "type": "MenuItem", "text": "置顶备忘录" }
              ]
            }
          }
        ]
      },
      {
        "type": "Text",
        "bound_data_field": "title",
        "styling": { "fontSize": "24vp", "fontWeight": "bold" }
      }
    ]
  }
}
"""
    )

    folder_context = {
        "folder_path": folder_path,
        "father_folder": father_folder,
        "children_folders": children_folders,
    }

    content_list: List[Dict[str, Any]] = [
        {
            "type": "text",
            "text": (
                f"请提取文件夹 {folder_path} 下的 UI 状态图信息。\n"
                f"页面层级上下文（必须用于按钮内嵌 jump_action 判定）：{json.dumps(folder_context, ensure_ascii=False)}"
            ),
        }
    ]
    for img in images:
        # 默认按 png 构造 data URL，实际接口也通常可识别。
        base64_url = f"data:image/png;base64,{img['image_data']}"
        content_list.append({"type": "image_url", "image_url": {"url": base64_url}})

    messages = [
        SystemMessage(content=system_prompt),
        HumanMessage(content=content_list),
    ]

    try:
        result: PageExtractionResult = structured_llm.invoke(messages)
        output_data = result.model_dump()
        output_data["source_folder"] = folder_path
        output_data["father_folder"] = father_folder
        output_data["children_folders"] = children_folders
        output_data["_folder_path"] = folder_path
        output_data["_mocked"] = False
        return {"extracted_ui_data": [output_data]} 
    except Exception as exc:
        fallback = _build_mock_extraction(folder_path, father_folder, children_folders)
        fallback["_error"] = str(exc)
        return {"extracted_ui_data": [fallback]}


def architect_node(state: ProjectState) -> dict:
    """汇总节点：消费并行视觉结果，生成可追踪的架构摘要。"""
    extracted_data = state.get("extracted_ui_data", [])
    page_count = len(extracted_data)

    summary = {
        "total_pages": page_count,
        "folders": [item.get("_folder_path", "") for item in extracted_data],
    }
    return {"architect_summary": summary}


def build_graph():
    builder = StateGraph(ProjectState)
    builder.add_node("vision_extractor_node", vision_extractor_node)
    builder.add_node("architect_node", architect_node)
    builder.add_conditional_edges(START, dispatch_vision_tasks)
    builder.add_edge("vision_extractor_node", "architect_node")
    builder.add_edge("architect_node", END)
    return builder.compile()


def run_full_test(input_root: Path) -> Dict[str, Any]:
    """
    从 input_processor 起跑的完整测试
    """
    initial_state, validation_report = build_initial_project_state(
        input_root=input_root,
        include_base64=True,
    )

    # 给图执行加上聚合字段，满足 Annotated[List, operator.add] 的聚合目标。
    initial_state_for_graph: Dict[str, Any] = dict(initial_state)
    initial_state_for_graph["extracted_ui_data"] = []

    graph = build_graph()
    final_state = graph.invoke(initial_state_for_graph)

    return {
        "input_root": str(input_root),
        "validation_report": validation_report,
        "final_state": final_state,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Run architect E2E test from input_processor")
    parser.add_argument("--input-root", default=str(DEFAULT_INPUT_ROOT), help="Input folder root")
    parser.add_argument("--output-file", default=str(DEFAULT_OUTPUT_FILE), help="Output json file")
    args = parser.parse_args()

    input_root = Path(args.input_root).resolve()
    output_file = Path(args.output_file).resolve()

    result = run_full_test(input_root)
    output_file.parent.mkdir(parents=True, exist_ok=True)
    output_file.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
