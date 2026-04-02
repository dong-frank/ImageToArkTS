from typing import Any, Dict, List, Optional, Literal
from pydantic import BaseModel, Field


class VisualStyle(BaseModel):
	design_tone: Optional[str] = Field(None, description="整体视觉调性，如简洁、卡片化、科技感、拟物化")
	primary_color: Optional[str] = Field(None, description="主色，如 #007DFF")
	background_color: Optional[str] = Field(None, description="主背景色，如 #F5F5F5")
	font_family: Optional[str] = Field(None, description="字体家族，如 system")
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


class ComponentSpec(BaseModel):
	type: str = Field(..., description="组件类型，如 button、icon_button、text、card")
	label: Optional[str] = Field(None, description="组件标签文案")
	id: Optional[str] = Field(None, description="组件标识")
	content: Optional[str] = Field(None, description="文本内容")
	icon: Optional[str] = Field(None, description="图标语义名或 emoji")
	action: Optional[str] = Field(None, description="动作标识/函数名")
	style: Optional[Dict[str, Any]] = Field(None, description="组件样式键值")


class KeyBlock(BaseModel):
	name: str = Field(..., description="页面区块名称，如 status_bar、display_area")
	components: List[ComponentSpec] = Field(..., description="区块组件列表")


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
	responsibilities: Optional[str] = Field(None, description="页面职责描述")
	role: Optional[str] = Field(None, description="页面角色描述")
	route: Optional[str] = Field(None, description="页面路由标识，如 index、detail、profile")
	layout_summary: Optional[str] = Field(None, description="页面整体布局摘要，如 顶部导航 + 中部卡片列表 + 底部Tab")
	key_blocks: Optional[List[KeyBlock]] = Field(None, description="页面关键区块（推荐输出）")
	key_sections: Optional[List[PageSection]] = Field(None, description="页面关键区块拆解")
	main_actions: Optional[List[str]] = Field(None, description="页面核心动作列表")
	state_indicators: Optional[Dict[str, Any]] = Field(None, description="页面状态字段与默认值")
	primary_actions: Optional[List[str]] = Field(None, description="页面上最重要的操作，如 搜索、提交、切换Tab")
	state_notes: Optional[str] = Field(None, description="页面状态说明，如 空态、加载态、选中态、展开态")
	images: Optional[List[int]] = Field(None, description="该页面关联的图片下标列表（与 images/image_descriptions 一一对应）")


class DataModelField(BaseModel):
	field: str = Field(..., description="数据字段名")
	type: str = Field(..., description="字段类型")
	description: str = Field(..., description="字段说明")


class Interaction(BaseModel):
	event: str = Field(..., description="用户事件名称")
	description: Optional[str] = Field(None, description="事件说明")
	target: Optional[str] = Field(None, description="事件目标组件，如 equals_button、conversion_card")
	handler: Optional[str] = Field(None, description="事件处理函数名，应与组件 action 语义一致")
	state_change: Optional[Dict[str, Any]] = Field(None, description="触发后状态变化")


class NavigationFlow(BaseModel):
	from_page: str = Field(..., description="起始页面名称")
	trigger: str = Field(..., description="触发跳转的动作，如 点击商品卡片、点击底部Tab、点击返回")
	to_page: str = Field(..., description="目标页面名称")
	transition: str = Field(..., description="跳转类型，如 push、back、slide_left、slide_right")
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
	data_model: Optional[Dict[str, Any]] = Field(None, description="数据模型定义（对象映射形式）")
	interactions: Optional[List[Interaction]] = Field(None, description="用户交互事件及说明")
