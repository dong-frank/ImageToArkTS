import os
import sys
import json
import re
import time
from typing import List, Dict, Any, Optional
from dotenv import load_dotenv
from openai import OpenAI

# 添加项目根目录到 sys.path，确保可以导入其他模块
current_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(os.path.dirname(current_dir))
if project_root not in sys.path:
    sys.path.append(project_root)

from agents.coder.coder_state import CoderNodeState
from agents.architect.architect_state import PageExtractionResult
from rag.rag_engine import RAGManager
from coder_tools import generate_code_llm, mock_compile_check
from langgraph.graph import END, START, StateGraph

# 加载 .env
load_dotenv(os.path.join(project_root, '.env'))

# 初始化 OpenAI/DeepSeek 客户端
# 注意：这里根据 Demo_0203 的配置，优先使用 DeepSeek 或兼容的 OpenAI 接口
API_KEY = os.environ.get("DEEPSEEK_API_KEY") or os.environ.get("OPENAI_API_KEY")
BASE_URL = os.environ.get("DEEPSEEK_BASE_URL", "https://api.deepseek.com")

if not API_KEY:
    # Fallback for demo purposes if no key found (mocking or warning)
    print("Warning: No API Key found in environment variables.")

client = OpenAI(api_key=API_KEY, base_url=BASE_URL)

# 系统资源列表 (从 DeepSeekVisitor_dynamic.py 获取)
SYS_MEDIA_LIST =  [
  "ai_recognize", "huawei_id_logo_red", "huawei_id_logo_white", "huawei_id_logo_red_margin",
  "huawei_id_logo_white_margin", "AI_circle_viewfinder", "AI_keyboard", "AI_lightbulb_max",
  "AI_panels", "AI_pause", "AI_phone", "AI_phone_doc", "AI_play", "AI_playing",
  "AI_read_aloud", "AI_retouch", "AI_screenshot", "AI_search", "AI_subtitles",
  "AI_translate", "AI_translation", "arrowshape_3_triangle_path", "ohos_ic_public_share",
  "balloon_fill", "battery_bolt_fill", "calendar_badge_play", "car_fill", "Celia",
  "Celia_fill", "cheers", "cup_fill", "figure_running", "fork_knife_fill",
  "hobbyhorse_fill", "lamp_ceiling", "leave_home_fill", "light_flashlight_on_fill",
  "local_and_figure_run", "local_and_figure_run_leave", "media_sound", "mic_sound",
  "moon_z_fill", "person_badge_waveform", "person_shield", "phone_arrow_down_left_circle_fill",
  "rectangle_and_line_horizontal_and_rectangle_filled", "rectangle_filled_and_line_horizontal_and_rectangle",
  "return_home_fill", "textformat_size_square_fill", "thermometer_fill", "waveform_folder_fill",
  "wifi_router_fill", "lamp_ceiling_light", "AI_form", "ic_public_voice_filled",
  "anahs_notification_icon"
]

# 全局单例 RAG Manager，避免反复初始化
_rag_manager_instance = None

def get_rag_manager():
    global _rag_manager_instance
    if _rag_manager_instance is None:
        try:
            print("Initializing RAG Manager...")
            _rag_manager_instance = RAGManager()
            print("RAG Manager initialized successfully.")
        except Exception as e:
            print(f"Warning: Failed to initialize RAG Manager. Will proceed without RAG. Error: {e}")
            _rag_manager_instance = False # 标记为失败，避免重复尝试
    return _rag_manager_instance if _rag_manager_instance else None


# -------------------------------------------------------------------------
# Subgraph Nodes
# -------------------------------------------------------------------------

def _init_state(state: CoderNodeState):
    """初始化必要的 State 字段"""
    if 'current_page_index' not in state:
        state['current_page_index'] = 0
    if 'generated_codes' not in state:
        state['generated_codes'] = {}
    if 'compilation_errors' not in state:
        state['compilation_errors'] = {}
    if 'retry_count' not in state:
        state['retry_count'] = {}
    if 'is_complete' not in state:
        state['is_complete'] = False

def generate_code_node(state: CoderNodeState) -> CoderNodeState:
    """
    节点1：生成代码 (Initial Generation)
    """
    _init_state(state)
    pages = state.get('pages_to_generate', [])
    idx = state['current_page_index']
    
    if idx >= len(pages):
        state['is_complete'] = True
        return state
        
    current_page = pages[idx]
    page_name = current_page.page_name
    
    
    print(f"--- [Generate Node] Generating code for {{page_name}} ---")
    
    
    # 2. Generate
    code = generate_code_llm.invoke()
    
    state['generated_codes'][page_name] = code
    
    # 初始化重试计数
    if page_name not in state['retry_count']:
        state['retry_count'][page_name] = 0
        
    return state

def compile_code_node(state: CoderNodeState) -> CoderNodeState:
    """
    节点2：编译检查
    """
    _init_state(state)
    pages = state.get('pages_to_generate', [])
    idx = state['current_page_index']
    
    if idx >= len(pages):
        state['is_complete'] = True
        return state
        
    current_page = pages[idx]
    page_name = current_page.page_name
    code = state['generated_codes'].get(page_name, "")
    
    print(f"--- [Compile Node] Checking code for {{page_name}} ---")
    
    errors = mock_compile_check.invoke(code)
    
    state['compilation_errors'][page_name] = errors
    
    if errors:
        print(f"Compile failed: {{len(errors)}} errors found.")
        # 失败不增加 index，等待 Fix
    else:
        print("Compile success!")
        # 成功，移动到下一页
        state['current_page_index'] += 1
        
    state['is_complete'] = (state['current_page_index'] >= len(pages))
    return state

def fix_code_node(state: CoderNodeState) -> CoderNodeState:
    """
    节点3：修复代码
    """
    _init_state(state)
    pages = state.get('pages_to_generate', [])
    idx = state['current_page_index']
    
    # 如果 index 越界，说明已完成，直接返回
    if idx >= len(pages):
        return state
        
    current_page = pages[idx]
    page_name = current_page.page_name
    
    errors = state['compilation_errors'].get(page_name, [])
    if not errors:
        return state
        
    current_retries = state['retry_count'].get(page_name, 0)
    
    # 最大重试限制
    if current_retries >= 3:
        print(f"Max retries ({{current_retries}}) reached for {{page_name}}. Skipping fix.")
        # 放弃修复，强制跳过该页面
        state['current_page_index'] += 1
        return state
        
    print(f"--- [Fix Node] Fixing code for {{page_name}} (Attempt {{current_retries + 1}}) ---")
    
    
    
    error_feedback = "\\n".join(errors)
    new_code = generate_code_llm.invoke(current_page, error_feedback)
    
    state['generated_codes'][page_name] = new_code
    state['retry_count'][page_name] = current_retries + 1
    
    return state

def build_graph():
    builder = StateGraph(CoderNodeState)
    builder.add_node("generate_code_node", generate_code_node)
    builder.add_node("compile_code_node", compile_code_node)
    builder.add_node("fix_code_node", fix_code_node)

    # 1. Start -> Generate
    builder.add_edge(START, "generate_code_node")
    
    # 2. Generate -> Compile (Check synthesized code)
    builder.add_edge("generate_code_node", "compile_code_node")

    # 3. Compile -> Condition (Error? -> Fix; Success? -> Next/End)
    def check_compile_outcome(state: CoderNodeState):
        if state.get("is_complete"):
            return END
            
        # 检查当前指向的页面是否有错误
        # 注意: Compile Node 如果成功，会 current_page_index += 1
        # 所以如果这里检测到 errors 且 index 没变，说明是当前页失败
        idx = state.get('current_page_index', 0)
        pages = state.get('pages_to_generate', [])
        
        if idx >= len(pages):
            return END
            
        current_page = pages[idx]
        page_name = current_page.page_name
        
        errors = state.get('compilation_errors', {}).get(page_name)
        
        if errors:
            return "fix_code_node"
        else:
            # 没有错误（或者 Compile Node 成功移动到了新页面），继续生成
            return "generate_code_node"

    builder.add_conditional_edges(
        "compile_code_node",
        check_compile_outcome
    )

    # 4. Fix -> Condition (Fixed? -> Compile; Gave up? -> Next/End)
    def check_fix_outcome(state: CoderNodeState):
        idx = state.get('current_page_index', 0)
        pages = state.get('pages_to_generate', [])
        
        if idx >= len(pages):
            return END
            
        current_page = pages[idx]
        page_name = current_page.page_name
        
        # 如果当前页有已生成的代码，说明我们进行了修复（重试），需要重新编译检查
        # 如果 Fix Node 决定跳过（give up），它会增加 index，
        # 此时新页面的代码还不在 generated_codes 中，所以去 generate_code_node
        if page_name in state.get('generated_codes', {}):
             return "compile_code_node"
        else:
             return "generate_code_node"

    builder.add_conditional_edges(
        "fix_code_node",
        check_fix_outcome
    )

    return builder.compile()