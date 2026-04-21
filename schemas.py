from __future__ import annotations

from typing import Any, Dict, List, Optional, Literal
from pydantic import BaseModel, ConfigDict, Field


class ArchitectBaseModel(BaseModel):
    model_config = ConfigDict(extra="forbid")


class VisualStyle(ArchitectBaseModel):
    design_tone: str = Field(..., description="整体视觉调性，如简洁、卡片化、科技感、拟物化")
    primary_color: Optional[str] = Field(None, description="主色，如 #007DFF")
    background_color: Optional[str] = Field(None, description="主背景色，如 #F5F5F5")
    accent_colors: Optional[List[str]] = Field(None, description="辅助色列表")
    typography_notes: Optional[str] = Field(None, description="字体层级、字号倾向、字重说明")
    spacing_notes: Optional[str] = Field(None, description="整体留白、圆角、阴影、卡片间距等说明")
    style_tokens: Optional[Dict[str, str]] = Field(
        None,
        description="可直接编码的全局样式键值，如 {'grid_gap': '12', 'row_spacing': '16', 'border_radius': '12'}",
    )


class UIStyle(ArchitectBaseModel):
    background_color: Optional[str] = Field(None, description="背景色，如 #FFFFFF")
    font_color: Optional[str] = Field(None, description="字体颜色，如 #333333")
    border_color: Optional[str] = Field(None, description="边框颜色，如 #E5E5E5")
    border_radius: Optional[str] = Field(None, description="圆角，如 12 或 12vp")
    font_size: Optional[str] = Field(None, description="字号，如 16fp")
    font_weight: Optional[str] = Field(None, description="字重，如 Medium、Bold、700")
    text_align: Optional[Literal["start", "center", "end", "justify"]] = Field(
        None, description="文本对齐方式"
    )
    padding: Optional[str] = Field(None, description="内边距，如 16vp 20vp")
    margin: Optional[str] = Field(None, description="外边距，如 12vp 16vp")
    gap: Optional[str] = Field(None, description="子元素间距，如 8vp")
    width: Optional[str] = Field(None, description="相对宽度表达，如 match_parent、80%、auto")
    height: Optional[str] = Field(None, description="相对高度表达，如 auto、56vp")
    opacity: Optional[str] = Field(None, description="透明度，如 0.6")
    style_tokens: Optional[Dict[str, str]] = Field(
        None,
        description="补充样式键值，如 {'shadow': 'soft', 'divider_color': '#F2F2F2'}",
    )


class UINavigationAction(ArchitectBaseModel):
    action_type: Literal[
        "router_back",
        "navigate",
        "open_overlay",
        "dismiss_overlay",
        "switch_tab",
        "switch_segment",
        "switch_state",
    ] = Field(..., description="纯 UI 交互类型")
    target: Optional[str] = Field(None, description="目标 page_id、overlay_id 或 state_id；router_back 场景可为空")
    target_type: Optional[Literal["page", "overlay", "state", "back"]] = Field(
        None, description="目标类型"
    )
    evidence_from: List[str] = Field(default_factory=list, description="证据来源，如图片路径或 facts 引用")
    confidence: Literal["strong", "medium", "weak"] = Field(..., description="证据强度")
    trigger_hint: Optional[str] = Field(None, description="触发说明，如 点击排序按钮、点击返回箭头")
    notes: Optional[str] = Field(None, description="仅描述可见 UI 反馈，不涉及业务逻辑")


class UIOverlay(ArchitectBaseModel):
    overlay_id: str = Field(..., description="弹层唯一标识，如 sort_menu_overlay")
    name: Optional[str] = Field(None, description="弹层名称，如 排序菜单、筛选底部弹窗")
    overlay_type: Literal[
        "menu",
        "dialog",
        "bottom_sheet",
        "drawer",
        "popover",
        "dropdown",
        "tooltip",
        "context_menu",
    ] = Field(..., description="弹层类型")
    summary: Optional[str] = Field(None, description="弹层视觉摘要")
    source_images: Optional[List[int]] = Field(None, description="该弹层关联的图片下标列表")
    trigger_node_id: Optional[str] = Field(None, description="触发该弹层的节点 id")
    layout_tree: "UINode" = Field(..., description="弹层内部的递归 UI 树")


class UIStateVariant(ArchitectBaseModel):
    state_id: str = Field(..., description="状态唯一标识，如 message_tab_selected")
    name: Optional[str] = Field(None, description="状态名称")
    summary: Optional[str] = Field(None, description="状态变化摘要")
    source_images: Optional[List[int]] = Field(None, description="该状态关联的图片下标列表")
    trigger_node_id: Optional[str] = Field(None, description="触发切换该状态的节点 id")
    difference_summary: Optional[str] = Field(None, description="与默认态相比的差异摘要")


class UINode(ArchitectBaseModel):
    node_id: str = Field(..., description="节点唯一标识，如 top_back_button、product_card")
    name: Optional[str] = Field(None, description="节点名称，如 顶部栏、商品卡片")
    component_type: str = Field(..., description="ArkUI 语义组件类型，如 Column、Row、Text、Image、Button、List")
    layout: Optional[Literal["column", "row", "stack", "flex", "grid", "list", "tabs", "scroll", "none"]] = Field(
        None, description="节点自身对子节点的布局方式"
    )
    semantic_role: Optional[str] = Field(None, description="视觉语义角色，如 header、hero、tab_bar、list_item")
    text: Optional[str] = Field(None, description="节点上的可见文本")
    icon: Optional[str] = Field(None, description="图标或 emoji，如 ←、⋯、⭐")
    image_ref: Optional[str] = Field(None, description="图片引用名或素材标识")
    summary: Optional[str] = Field(None, description="节点视觉摘要")
    style: Optional[UIStyle] = Field(None, description="节点样式")
    interactive_affordance: Optional[bool] = Field(
        None, description="仅表示有可点击暗示，但证据不足以生成明确 action"
    )
    affordance_reason: Optional[str] = Field(None, description="弱交互证据原因")
    evidence_from: Optional[List[str]] = Field(None, description="该节点的证据来源")
    action: Optional[UINavigationAction] = Field(None, description="由当前节点触发的明确交互")
    children: List["UINode"] = Field(default_factory=list, description="子节点列表")


class ArchitectPageFile(ArchitectBaseModel):
    page_id: str = Field(..., description="页面唯一标识，如 home_page、detail_page")
    page_name: str = Field(..., description="页面名称")
    summary: str = Field(..., description="页面视觉摘要")
    role: Optional[Literal["entry", "primary", "secondary", "detail", "modal", "popup"]] = Field(
        None, description="页面在产品中的角色"
    )
    route: Optional[str] = Field(None, description="页面路由标识，如 pages/Home")
    source_images: Optional[List[int]] = Field(None, description="该页面关联的图片下标列表")
    layout_summary: Optional[str] = Field(None, description="页面整体布局摘要，如 顶部栏 + 列表区 + 底部 Tab")
    root: UINode = Field(..., description="页面主视图的递归 UI 树")
    overlays: List[UIOverlay] = Field(default_factory=list, description="本页 overlay 列表")
    state_variants: List[UIStateVariant] = Field(default_factory=list, description="本页状态变体列表")
    outbound_navigation: List[UINavigationAction] = Field(
        default_factory=list,
        description="从本页发出的交互摘要；跳转信息写在发起页",
    )
    page_file_path: Optional[str] = Field(
        None, description="页面文件路径，如 /designs/pages/home_page.json"
    )


class ArchitectPageIndexItem(ArchitectBaseModel):
    page_id: str = Field(..., description="页面唯一标识")
    page_name: str = Field(..., description="页面名称")
    route: Optional[str] = Field(None, description="页面路由")
    page_file_path: str = Field(..., description="页面文件路径")
    role: Optional[str] = Field(None, description="页面角色")
    summary: Optional[str] = Field(None, description="页面摘要")


class NavigationGraphEdge(ArchitectBaseModel):
    from_page: str = Field(..., description="起始页面 page_id")
    trigger_node_id: Optional[str] = Field(None, description="触发节点 id")
    action_type: Literal[
        "router_back",
        "navigate",
        "open_overlay",
        "dismiss_overlay",
        "switch_tab",
        "switch_segment",
        "switch_state",
    ] = Field(..., description="动作类型")
    target: Optional[str] = Field(None, description="目标 page_id、overlay_id 或 state_id")
    target_type: Optional[Literal["page", "overlay", "state", "back"]] = Field(
        None, description="目标类型"
    )
    confidence: Literal["strong", "medium", "weak"] = Field(..., description="证据强度")


class ArchitectValidationSummary(ArchitectBaseModel):
    all_files_valid_json: bool = Field(..., description="所有文件是否为合法 JSON")
    page_file_count: int = Field(..., description="页面文件数量")
    duplicate_page_ids: List[str] = Field(default_factory=list, description="重复的 page_id")
    missing_page_targets: List[str] = Field(default_factory=list, description="缺失的页面跳转目标")
    missing_overlay_targets: List[str] = Field(default_factory=list, description="缺失的本页 overlay 目标")
    missing_state_targets: List[str] = Field(default_factory=list, description="缺失的本页 state 目标")
    orphan_page_files: List[str] = Field(default_factory=list, description="未纳入索引的页面文件")
    notes: List[str] = Field(default_factory=list, description="额外校验说明")
    validation_passed: bool = Field(..., description="全局校验是否通过")


class ArchitectIndexOutput(ArchitectBaseModel):
    project_name: str = Field(
        ...,
        pattern=r"^[a-z][a-z0-9_]{0,199}$",
        description="项目文件夹名称，必须以小写字母开头，只能包含小写字母、数字和下划线，如 calculator_app",
    )
    app_display_name: str = Field(..., description="用户可见的应用名称，优先使用英文展示名")
    visual_style: Optional[VisualStyle] = Field(None, description="全局视觉风格说明")
    page_index: List[ArchitectPageIndexItem] = Field(default_factory=list, description="页面索引列表")
    navigation_graph: List[NavigationGraphEdge] = Field(
        default_factory=list, description="页面间与页面内关键交互摘要"
    )
    validation_summary: ArchitectValidationSummary = Field(..., description="全局校验结果")


class DataModelField(BaseModel):
    field: str = Field(..., description="数据字段名")
    type: str = Field(..., description="字段类型")
    description: str = Field(..., description="字段说明")


UIOverlay.model_rebuild()
UINode.model_rebuild()
ArchitectPageFile.model_rebuild()
ArchitectIndexOutput.model_rebuild()


class CoderRouteSpec(BaseModel):
    page_name: str = Field(..., description="Page name.")
    route: str = Field(..., description="Harmony page route such as pages/Index.")
    page_file: str = Field(..., description="Workspace-relative page file path.")


class CoderSharedArtifact(BaseModel):
    name: str = Field(..., description="Shared artifact name.")
    file_path: str = Field(..., description="Workspace-relative file path.")
    description: str = Field(..., description="Artifact responsibility summary.")


class CoderStateConvention(BaseModel):
    store_name: str = Field(..., description="Primary shared store name.")
    file_path: str = Field(..., description="Workspace-relative store file path.")
    responsibilities: str = Field(..., description="What the store manages.")
    exposed_state: List[str] = Field(default_factory=list, description="Shared state keys exposed to pages.")
    exposed_actions: List[str] = Field(default_factory=list, description="Shared actions exposed to pages.")


class CoderPageTask(BaseModel):
    page_id: str = Field(..., description="Architect page id bound to this task.")
    page_name: str = Field(..., description="Page name assigned to the worker.")
    route: str = Field(..., description="Harmony page route such as pages/Index.")
    design_file: str = Field(..., description="Workspace-relative architect page design file path.")
    page_file: str = Field(..., description="Workspace-relative primary page file path.")
    allowed_write_paths: List[str] = Field(
        default_factory=list,
        description="Workspace-relative file paths the page worker may edit.",
    )
    shared_dependencies: List[str] = Field(
        default_factory=list,
        description="Shared components, stores, or interfaces the page uses.",
    )
    # ✅ 修复 SC-2：responsibilities 改为 Optional 并提供默认值，避免 seed 生成时缺字段崩溃
    responsibilities: str = Field(
        default="",
        description="Page responsibility summary. Defaults to empty string when not yet specified.",
    )
    primary_actions: List[str] = Field(
        default_factory=list,
        description="Primary handlers or user actions for the page.",
    )
    state_notes: Optional[str] = Field(None, description="Relevant page state notes.")
    role: Optional[str] = Field(None, description="Page role copied from architect design when useful.")
    summary: Optional[str] = Field(None, description="Short page summary copied from architect design.")



class CoderSkeletonOutput(BaseModel):
    project_name: str = Field(
        ...,
        pattern=r"^[a-z][a-z0-9_]{0,199}$",
        description="Project directory name.",
    )
    app_display_name: str = Field(..., description="User-visible app name.")
    page_tasks: List[CoderPageTask] = Field(..., min_length=1, description="Page implementation tasks.")
    # ✅ 新增：物化阶段写入的运行时字段，Agent 不需要填，代码层补充
    generated_route_table: Optional[List[dict]] = Field(
        None, description="Route table generated during materialization. Populated by skeleton tool, not by agent."
    )
    generated_files: Optional[dict] = Field(
        None, description="File paths written during materialization. Populated by skeleton tool, not by agent."
    )

class CoderPageTaskBundle(BaseModel):
    project_name: str = Field(..., description="Project name that owns the page tasks.")
    tasks: List[CoderPageTask] = Field(default_factory=list, description="Page task list.")


class CoderPageWorkerResult(BaseModel):
    status: Literal["done", "blocked", "need_human_guidance"] = Field(..., description="Worker completion state.")
    page_name: str = Field(..., description="Page name handled by the worker.")
    modified_files: List[str] = Field(default_factory=list, description="Files modified for this page task.")
    exports_added: List[str] = Field(default_factory=list, description="New exports or symbols added by the worker.")
    shared_contract_requests: List[str] = Field(
        default_factory=list,
        description="Requests for integration to adjust shared contracts.",
    )
    blockers: List[str] = Field(default_factory=list, description="Blocking issues encountered by the worker.")
    summary: str = Field(..., description="Short implementation summary.")


class CoderPageWorkerResultBundle(BaseModel):
    project_name: str = Field(..., description="Project name that owns the worker results.")
    results: List[CoderPageWorkerResult] = Field(default_factory=list, description="Collected page worker results.")


class CoderIntegrationReport(BaseModel):
    compile_status: Literal["SUCCESS", "FAILED"] = Field(..., description="Compilation verdict after integration.")
    project_name: str = Field(..., description="Project name.")
    project_path: str = Field(..., description="Workspace-relative project path.")
    ready_for_tester: bool = Field(..., description="Whether the project is ready for tester validation.")
    fixes_applied: List[str] = Field(default_factory=list, description="Integration fixes applied.")
    remaining_errors: List[str] = Field(default_factory=list, description="Remaining errors after integration.")
    blocker: str = Field(..., description="Blocking summary, use 'none' when clear.")
    next_recommended_agent: Literal["tester", "coder", "human", "orchestrator"] = Field(
        ...,
        description=(
            "Next recommended owner after integration. "
            "Use 'tester' when compile succeeded. "
            "Use 'coder' when errors are fixable but were not resolved in this run. "
            "Use 'orchestrator' when a pipeline-level decision is needed (e.g. re-run skeleton). "
            "Use 'human' when errors require manual intervention."
        ),
    )


class CoderCompileFixAttempt(BaseModel):
    attempt_index: int = Field(..., description="1-based compile attempt index within the integration stage.")
    timestamp: str = Field(..., description="UTC ISO timestamp for this attempt record.")
    task_type: Literal["implementation", "fix_from_test"] = Field(..., description="Coder task type.")
    project_name: str = Field(..., description="Project name.")
    compile_status: Literal["SUCCESS", "FAILED"] = Field(..., description="Compile verdict for this attempt.")
    error_signature: str = Field(..., description="Normalized signature for the primary compile error.")
    key_errors: List[str] = Field(default_factory=list, description="Extracted key compile errors.")
    worker_summary: str = Field(..., description="Integration worker summary for this attempt.")
    worker_summaries_so_far: List[str] = Field(
        default_factory=list,
        description="Cumulative integration worker summaries so far.",
    )
    modified_files: List[str] = Field(default_factory=list, description="Files modified by page workers before integration.")
    fixes_applied: List[str] = Field(default_factory=list, description="Fix summaries known at this point.")
    skills_referenced: List[str] = Field(default_factory=list, description="Skills or references intentionally used for this attempt.")
    resolved_in_next_attempt: Optional[bool] = Field(
        None,
        description="Whether the next attempt resolved this attempt's primary issue.",
    )
    final_success: Optional[bool] = Field(None, description="Whether the overall integration run eventually succeeded.")


class CoderCompileFixTrace(BaseModel):
    project_name: str = Field(..., description="Project name.")
    task_type: Literal["implementation", "fix_from_test"] = Field(..., description="Coder task type.")
    attempts: List[CoderCompileFixAttempt] = Field(default_factory=list, description="Ordered compile/fix attempts.")
    final_compile_status: Literal["SUCCESS", "FAILED"] = Field(..., description="Final compile verdict.")
    final_success: bool = Field(..., description="Whether the overall integration run succeeded.")


class TesterChecklistItem(BaseModel):
    name: str = Field(..., description="Checklist item or page/module name.")
    status: Literal["PASS", "FAIL", "UNKNOWN"] = Field(..., description="Validation status.")
    source: Optional[str] = Field(None, description="Source of the checklist item.")
    evidence: Optional[str] = Field(None, description="Evidence path or summary.")
    gap: Optional[str] = Field(None, description="Missing info or functional gap.")
    pair: Optional[str] = Field(None, description="Reference/runtime image pair summary.")
    advices: Optional[List[str]] = Field(None, description="UI comparison advice list.")
    impact: Optional[Literal["high", "medium", "low"]] = Field(None, description="Impact level for UI gap.")


class TesterMissingItems(BaseModel):
    functional: List[str] = Field(default_factory=list, description="Missing functional items.")
    ui: List[str] = Field(default_factory=list, description="Missing UI items.")


class TesterEvidencePaths(BaseModel):
    description: str = Field(..., description="Description path.")
    reference_images: List[str] = Field(default_factory=list, description="Reference image paths.")
    runtime_screenshots: List[str] = Field(default_factory=list, description="Runtime screenshot paths.")
    layout_json: List[str] = Field(default_factory=list, description="Captured layout json paths.")
    ui_compare_logs: List[str] = Field(default_factory=list, description="UI comparison log paths.")
    report_path: str = Field(..., description="Saved report path.")


class TesterFixSuggestions(BaseModel):
    p0: List[str] = Field(default_factory=list, description="Critical fixes.")
    p1: List[str] = Field(default_factory=list, description="High-priority fixes.")
    p2: List[str] = Field(default_factory=list, description="Low-priority fixes.")


class TesterCompletionSummary(BaseModel):
    task_type: Literal["validation"] = Field(..., description="Tester task type.")
    report_saved: bool = Field(..., description="Whether the json report was saved.")
    next_recommended_agent: Literal["coder", "orchestrator", "human"] = Field(
        ...,
        description="Recommended next owner.",
    )
    blocker: str = Field(..., description="Blocker summary, use 'none' when clear.")


class TesterReportOutput(BaseModel):
    overall: Literal["PASS", "FAIL"] = Field(..., description="Overall validation verdict.")
    functional_completeness: Literal["PASS", "FAIL"] = Field(..., description="Functional verdict.")
    static_ui_completeness: Literal["PASS", "FAIL"] = Field(..., description="Static UI verdict.")
    functional_checklist: List[TesterChecklistItem] = Field(default_factory=list, description="Functional checklist.")
    static_ui_checklist: List[TesterChecklistItem] = Field(default_factory=list, description="Static UI checklist.")
    missing_items: TesterMissingItems = Field(..., description="Missing functional and UI items.")
    evidence_paths: TesterEvidencePaths = Field(..., description="Evidence path collection.")
    fix_suggestions: TesterFixSuggestions = Field(..., description="Fix suggestion groups.")
    completion_summary: TesterCompletionSummary = Field(..., description="Completion metadata.")




# ── 阶段 A 产物：单图独立页面草稿 ──────────────────────────────

# ── 阶段一产物：单图完整草稿 ──────────────────────────────────
 
class ArchitectPageDraft(BaseModel):
    """单张图片直接分析产出的页面草稿，不含跨图归并结论。"""
 
    draft_index: int = Field(..., description="图片在输入列表中的下标，从 0 开始")
    image_path: str = Field(..., description="对应的图片 workspace 路径")
    image_name: str = Field(default="", description="图片文件名（不含扩展名）")
    draft_status: Literal["success", "failed"] = Field(
        default="success", description="success | failed"
    )
    error: Optional[str] = Field(default=None, description="提取失败时的错误信息")
    candidate_page_id: str = Field(
        default="", description="基于本图推断的候选页面 ID（小写下划线）"
    )
    candidate_page_name: str = Field(
        default="", description="基于本图推断的候选页面名称"
    )
    layout_summary: str = Field(default="", description="本图整体布局一句话描述，不超过 50 字")
    key_sections: List[str] = Field(
        default_factory=list,
        description="本图主要区块语义名称列表，如 ['nav_bar', 'content_list', 'tab_bar']",
    )
    has_overlay: bool = Field(
        default=False, description="本图中是否存在浮层结构"
    )
    overlay_hint: Optional[str] = Field(
        default=None, description="浮层类型简述，has_overlay 为 false 时为 null"
    )
    root: Dict[str, Any] = Field(
        default_factory=dict, description="本图组件树根节点"
    )
    overlays: List[Dict[str, Any]] = Field(
        default_factory=list, description="本图可见弹层"
    )
    state_variants: List[Dict[str, Any]] = Field(
        default_factory=list, description="本图可见状态变体"
    )
    visible_interactions: List[Dict[str, Any]] = Field(
        default_factory=list,
        description="本图可见交互线索（不含跨图 navigate 推断）",
    )
    uncertainties: List[str] = Field(
        default_factory=list, description="本图分析中的不确定项"
    )
 
 
# ── 阶段一产物：单图轻量摘要（不含完整 UI 树）────────────────────
 
class ArchitectPageDraftSummary(BaseModel):
    """
    单图轻量摘要，不含 root / overlays / state_variants 等完整 UI 树字段。
    供阶段二归并决策消费，不会撑爆 context。
    """
 
    draft_index: int = Field(..., description="图片在输入列表中的下标，从 0 开始")
    image_path: str = Field(..., description="对应的图片 workspace 路径")
    image_name: str = Field(default="", description="图片文件名（不含扩展名）")
    draft_status: Literal["success", "failed"] = Field(default="success")
    candidate_page_id: str = Field(default="")
    candidate_page_name: str = Field(default="")
    layout_summary: str = Field(default="")
    key_sections: List[str] = Field(default_factory=list)
    has_overlay: bool = Field(default=False)
    overlay_hint: Optional[str] = Field(default=None)
    draft_file: str = Field(
        ..., description="完整草稿文件路径，如 /designs/page_drafts/page_draft_0.json"
    )
 
 
# ── 阶段一产物：所有图的草稿索引（轻量）────────────────────────
 
class ArchitectPageDraftsIndex(BaseModel):
    """
    所有单图轻量摘要的汇总索引，保存为 page_drafts_index.json。
    阶段二归并决策只消费这个，不一次性读取所有完整草稿。
    """
 
    drafts: List[ArchitectPageDraftSummary] = Field(default_factory=list)
    total_image_count: int = Field(default=0)
    success_count: int = Field(default=0)
    failed_count: int = Field(default=0)
 
 
# ── 保持不变，供工具层内部使用 ────────────────────────────────
 
class ArchitectPageDraftsBundle(BaseModel):
    """所有单图完整草稿的汇总，工具层内部使用，不直接喂给 Agent。"""
 
    drafts: List[ArchitectPageDraft] = Field(default_factory=list)
    total_image_count: int = Field(default=0)
    success_count: int = Field(default=0)
    failed_count: int = Field(default=0)