
from typing import List, Optional, Literal
from pydantic import BaseModel, Field

class Page(BaseModel):
	name: str = Field(..., description="页面名称，如 Index")
	responsibilities: str = Field(..., description="页面职责描述")
	images: Optional[List[int]] = Field(None, description="该页面关联的图片下标列表（与 images/image_descriptions 一一对应）")

class DataModelField(BaseModel):
	field: str = Field(..., description="数据字段名")
	type: str = Field(..., description="字段类型")
	description: str = Field(..., description="字段说明")

class Interaction(BaseModel):
	event: str = Field(..., description="用户事件名称")
	description: str = Field(..., description="事件说明")


class ArchitectOutput(BaseModel):
	project_name: str = Field(..., description="项目文件夹名称，短ASCII字符串")
	app_display_name: str = Field(..., description="用户可见的应用名称（可为中文）")
	pages: List[Page] = Field(..., description="页面列表及职责")
	data_model: Optional[List[DataModelField]] = Field(None, description="数据模型字段及说明")
	interactions: Optional[List[Interaction]] = Field(None, description="用户交互事件及说明")
