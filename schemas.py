from __future__ import annotations

from typing import Dict, List, Optional, Literal
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


class UINavigationTarget(ArchitectBaseModel):
	transition: Literal["push", "replace", "switch_tab", "modal", "popup", "back"] = Field(
		..., description="视觉跳转类型"
	)
	target_page: Optional[str] = Field(None, description="目标页面名称；back 场景可为空")
	trigger_label: Optional[str] = Field(None, description="触发文案或控件标签")
	notes: Optional[str] = Field(None, description="仅描述视觉反馈或跳转语义，不涉及业务逻辑")


class UIOverlay(ArchitectBaseModel):
	id: str = Field(..., description="弹层唯一标识，如 sort_menu")
	name: Optional[str] = Field(None, description="弹层名称，如 排序菜单、筛选底部弹窗")
	presentation: Literal["popup", "modal", "bottom_sheet", "dropdown", "drawer", "tooltip", "context_menu"] = Field(
		..., description="弹层呈现形式"
	)
	summary: Optional[str] = Field(None, description="弹层视觉摘要")
	content: "UINode" = Field(..., description="弹层内部的递归 UI 树")


class UINode(ArchitectBaseModel):
	id: str = Field(..., description="节点唯一标识，如 header_title、product_card")
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
	children: List["UINode"] = Field(default_factory=list, description="子节点列表")
	overlay: Optional[UIOverlay] = Field(None, description="由当前节点触发并承载的弹层")
	navigation: Optional[UINavigationTarget] = Field(None, description="由当前节点触发的页面跳转")


class Page(ArchitectBaseModel):
	name: str = Field(..., description="页面名称，如 home_page、detail_page")
	summary: str = Field(..., description="页面视觉摘要")
	role: Optional[Literal["entry", "primary", "secondary", "detail", "modal", "popup"]] = Field(
		None, description="页面在产品中的角色"
	)
	route: Optional[str] = Field(None, description="页面路由标识，如 home_page、detail_page")
	layout_summary: Optional[str] = Field(None, description="页面整体布局摘要，如 顶部栏 + 列表区 + 底部Tab")
	root: UINode = Field(..., description="页面主视图的递归 UI 树")
	source_images: Optional[List[int]] = Field(None, description="该页面关联的图片下标列表")


class DataModelField(BaseModel):
	field: str = Field(..., description="数据字段名")
	type: str = Field(..., description="字段类型")
	description: str = Field(..., description="字段说明")


class NavigationFlow(ArchitectBaseModel):
	from_page: str = Field(..., description="起始页面名称")
	trigger: str = Field(..., description="触发跳转的视觉动作，如 点击商品卡片、点击底部Tab、点击返回")
	trigger_node_id: Optional[str] = Field(None, description="触发节点 id，如 product_card_1")
	to_page: str = Field(..., description="目标页面名称")
	transition: Literal["push", "replace", "switch_tab", "modal", "popup", "back"] = Field(
		..., description="跳转类型"
	)
	ui_feedback: Optional[str] = Field(None, description="跳转前后的界面反馈，如 高亮切换、弹层出现、返回上一页")


class ArchitectOutput(ArchitectBaseModel):
	project_name: str = Field(
		...,
		pattern=r"^[a-z][a-z0-9_]{0,199}$",
		description="项目文件夹名称，必须以小写字母开头，只能包含小写字母、数字和下划线，如 calculator_app",
	)
	app_display_name: str = Field(..., description="用户可见的应用名称（可为中文）")
	visual_style: Optional[VisualStyle] = Field(None, description="全局视觉风格说明")
	pages: List[Page] = Field(..., description="页面列表及其递归 UI 树")
	navigation: Optional[List[NavigationFlow]] = Field(None, description="页面间跳转与切换关系")


UIOverlay.model_rebuild()
UINode.model_rebuild()
Page.model_rebuild()
ArchitectOutput.model_rebuild()


class ArchitectImageFactsOutput(BaseModel):
	image_path: str = Field(..., description="Workspace-relative image path.")
	image_role: Literal["entry", "primary", "secondary", "detail", "modal", "popup", "unknown"] = Field(
		..., description="Most likely UI role of the image."
	)
	visible_texts: List[str] = Field(default_factory=list, description="Visible text snippets found in the image.")
	layout_summary: str = Field(..., description="High-level layout description grounded in the image.")
	key_sections: List[str] = Field(default_factory=list, description="Key visible sections in the image.")
	interactive_hints: List[str] = Field(default_factory=list, description="Observable interaction hints from the image.")
	uncertainties: List[str] = Field(default_factory=list, description="Uncertain or ambiguous observations.")


class ArchitectCoverageSummary(BaseModel):
	total_image_count: int = Field(..., description="Total discovered image inputs.")
	processed_image_count: int = Field(..., description="Processed image count within budget.")
	omitted_image_count: int = Field(..., description="Image count skipped due to budget limits.")
	failed_image_count: int = Field(..., description="Image count that failed fact extraction.")
	strategy: Literal["all_images_processed", "limited_to_budget"] = Field(
		..., description="Image processing strategy used for this bundle."
	)
	notes: Optional[str] = Field(None, description="Extra context about the coverage decision.")


class ArchitectImageFactsBundle(BaseModel):
	facts: List[ArchitectImageFactsOutput] = Field(default_factory=list, description="Per-image grounded facts.")
	shared_patterns: List[str] = Field(default_factory=list, description="Patterns shared across multiple images.")
	conflicts: List[str] = Field(default_factory=list, description="Conflicts detected across image facts.")
	coverage_summary: ArchitectCoverageSummary = Field(..., description="Coverage and budgeting summary.")
	omitted_images: List[str] = Field(default_factory=list, description="Image paths skipped due to budget limits.")


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
    page_name: str = Field(..., description="Page name assigned to the worker.")
    route: str = Field(..., description="Harmony page route such as pages/Index.")
    page_file: str = Field(..., description="Workspace-relative primary page file path.")
    allowed_write_paths: List[str] = Field(default_factory=list, description="Workspace-relative file paths the page worker may edit.")
    shared_dependencies: List[str] = Field(default_factory=list, description="Shared components, stores, or interfaces the page uses.")
    responsibilities: str = Field(..., description="Page responsibility summary.")
    primary_actions: List[str] = Field(default_factory=list, description="Primary handlers or user actions for the page.")
    state_notes: Optional[str] = Field(None, description="Relevant page state notes.")
    role: Optional[str] = Field(None, description="Page role copied from architect design when useful.")


class CoderSkeletonOutput(BaseModel):
    project_name: str = Field(
        ...,
        pattern=r"^[a-z][a-z0-9_]{0,199}$",
        description="Project directory name.",
    )
    app_display_name: str = Field(..., description="User-visible app name.")
    page_tasks: List[CoderPageTask] = Field(..., min_length=1, description="Page implementation tasks.")


class CoderPageTaskBundle(BaseModel):
    project_name: str = Field(..., description="Project name that owns the page tasks.")
    tasks: List[CoderPageTask] = Field(default_factory=list, description="Page task list.")


class CoderPageWorkerResult(BaseModel):
    status: Literal["done", "blocked", "need_human_guidance"] = Field(..., description="Worker completion state.")
    page_name: str = Field(..., description="Page name handled by the worker.")
    modified_files: List[str] = Field(default_factory=list, description="Files modified for this page task.")
    exports_added: List[str] = Field(default_factory=list, description="New exports or symbols added by the worker.")
    shared_contract_requests: List[str] = Field(default_factory=list, description="Requests for integration to adjust shared contracts.")
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
        description="Next recommended owner after integration.",
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
    worker_summaries_so_far: List[str] = Field(default_factory=list, description="Cumulative integration worker summaries so far.")
    modified_files: List[str] = Field(default_factory=list, description="Files modified by page workers before integration.")
    fixes_applied: List[str] = Field(default_factory=list, description="Fix summaries known at this point.")
    skills_referenced: List[str] = Field(default_factory=list, description="Skills or references intentionally used for this attempt.")
    resolved_in_next_attempt: Optional[bool] = Field(None, description="Whether the next attempt resolved this attempt's primary issue.")
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
		..., description="Recommended next owner."
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
