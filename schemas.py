from typing import Dict, List, Optional, Literal
from pydantic import BaseModel, Field


class VisualStyle(BaseModel):
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


class InteractiveComponent(BaseModel):
	name: str = Field(..., description="可交互组件名称，如 数字按钮、返回图标、菜单项")
	component_type: str = Field(..., description="组件类型，如 Button、IconButton、Card、MenuItem")
	action: str = Field(..., description="动作标识/函数名，如 append_digit、clear_all、open_conversion_menu")
	style: Optional[Dict[str, str]] = Field(
		None,
		description="组件原子化样式键值，如 {'width': '72', 'height': '72', 'bg_color': '#E0E0E0'}",
	)


class PageSection(BaseModel):
	name: str = Field(..., description="页面区块名称，如 顶部栏、Banner、列表区、底部操作区")
	purpose: str = Field(..., description="该区块承担的展示或交互职责")
	layout: str = Field(..., description="区块布局方式，如 纵向列表、双列网格、顶部横滑卡片")
	components: List[str] = Field(..., description="该区块的核心组件列表，如 Text、Image、Button、Tabs、List")
	style_notes: Optional[str] = Field(None, description="该区块的样式补充，如颜色、字号、边框、圆角、对齐方式")
	interactive_components: Optional[List[InteractiveComponent]] = Field(
		None,
		description="区块内可交互组件及其 action 绑定",
	)
	style_tokens: Optional[Dict[str, str]] = Field(
		None,
		description="区块级原子化样式键值，如 {'padding': '16', 'margin_top': '12'}",
	)


class Page(BaseModel):
	name: str = Field(..., description="页面名称，如 Index")
	responsibilities: str = Field(..., description="页面职责描述")
	role: Optional[Literal["entry", "primary", "secondary", "detail", "modal", "popup"]] = Field(
		None, description="页面在产品中的角色"
	)
	route: Optional[str] = Field(None, description="页面路由标识，如 index、detail、profile")
	layout_summary: Optional[str] = Field(None, description="页面整体布局摘要，如 顶部导航 + 中部卡片列表 + 底部Tab")
	key_sections: Optional[List[PageSection]] = Field(None, description="页面关键区块拆解")
	primary_actions: Optional[List[str]] = Field(None, description="页面上最重要的操作，如 搜索、提交、切换Tab")
	state_notes: Optional[str] = Field(None, description="页面状态说明，如 空态、加载态、选中态、展开态")
	images: Optional[List[int]] = Field(None, description="该页面关联的图片下标列表（与 images/image_descriptions 一一对应）")


class DataModelField(BaseModel):
	field: str = Field(..., description="数据字段名")
	type: str = Field(..., description="字段类型")
	description: str = Field(..., description="字段说明")


class Interaction(BaseModel):
	event: str = Field(..., description="用户事件名称")
	description: str = Field(..., description="事件说明")
	target: Optional[str] = Field(None, description="事件目标组件，如 equals_button、conversion_card")
	handler: Optional[str] = Field(None, description="事件处理函数名，应与组件 action 语义一致")
	state_change: Optional[str] = Field(None, description="触发后状态变化，如 切换到 result 状态")


class NavigationFlow(BaseModel):
	from_page: str = Field(..., description="起始页面名称")
	trigger: str = Field(..., description="触发跳转的动作，如 点击商品卡片、点击底部Tab、点击返回")
	to_page: str = Field(..., description="目标页面名称")
	transition: Literal["push", "replace", "switch_tab", "modal", "popup", "back"] = Field(
		..., description="跳转类型"
	)
	params: Optional[List[str]] = Field(None, description="跳转需要携带的参数名列表")
	ui_feedback: Optional[str] = Field(None, description="跳转前后的界面反馈，如 高亮切换、弹层出现、返回上一页")


class ArchitectOutput(BaseModel):
	project_name: str = Field(
		...,
		pattern=r"^[a-z][a-z0-9_]{0,199}$",
		description="项目文件夹名称，必须以小写字母开头，只能包含小写字母、数字和下划线，如 calculator_app",
	)
	app_display_name: str = Field(..., description="用户可见的应用名称（可为中文）")
	visual_style: Optional[VisualStyle] = Field(None, description="全局视觉风格说明")
	pages: List[Page] = Field(..., description="页面列表及职责")
	navigation: Optional[List[NavigationFlow]] = Field(None, description="页面间跳转与切换关系")
	data_model: Optional[List[DataModelField]] = Field(None, description="数据模型字段及说明")
	interactions: Optional[List[Interaction]] = Field(None, description="用户交互事件及说明")


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
    component_files: List[str] = Field(default_factory=list, description="Page-local component file paths.")
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
    route_table: List[CoderRouteSpec] = Field(default_factory=list, description="Initial route table.")
    shared_data_models: List[DataModelField] = Field(default_factory=list, description="Shared data model definitions.")
    shared_components: List[CoderSharedArtifact] = Field(default_factory=list, description="Shared component artifacts.")
    public_interfaces: List[CoderSharedArtifact] = Field(default_factory=list, description="Shared interface/service artifacts.")
    state_management: CoderStateConvention = Field(..., description="Shared state management convention.")
    page_tasks: List[CoderPageTask] = Field(default_factory=list, description="Page implementation tasks.")


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
