from langchain.tools import tool

@tool
def retrieve_rag_context(self, keywords: List[str]) -> str:
    """从 RAG 获取相关代码片段"""
    if not self.rag_manager:
        return ""
    
    context_str = ""
    unique_snippets = set()
    
    for keyword in keywords:
        # 查询
        try:
            results = self.rag_manager.query(keyword, n_results=2)
            if results and results.get('documents'):
                for idx, doc_list in enumerate(results['documents']):
                    for doc in doc_list:
                        if doc not in unique_snippets:
                            unique_snippets.add(doc)
                            context_str += f"// Reference for {keyword}:\n{doc}\n\n"
        except Exception as e:
            print(f"Error querying RAG for {keyword}: {e}")
            
    return context_str

@tool
def mock_compile_check(self, code: str) -> List[str]:
    """
    模拟编译器检查，返回错误列表。
    基于规则的简单检查。
    """
    errors = []
    
    # Rule 1: 禁止三元表达式
    if re.search(r'\?.*:', code):
        errors.append("Error: Ternary operator (? :) is not allowed in ArkTS for UI logic. Use if-else instead.")
        
    # Rule 2: 禁止内联对象类型定义 (简单检查)
    if re.search(r'Array\s*<\{', code):
        errors.append("Error: Inline object type definition in Array<...> is not allowed. Define an interface first.")
        
    # Rule 3: 检查 @Entry 数量
    entry_count = len(re.findall(r'@Entry', code))
    if entry_count > 1:
        errors.append(f"Error: Found {entry_count} @Entry decorators. Only one is allowed per file.")
    elif entry_count == 0:
        errors.append("Error: No @Entry decorator found. One component must be the entry point.")

    # Rule 4: 禁止使用 'any' (严格模式)
    if re.search(r'\bany\b', code):
            errors.append("Error: Usage of 'any' type is discouraged. Please use specific types.")
            
    # Rule 5: 检查是否使用了 Router.back()
    if 'getRouter().back()' in code:
        errors.append("Error: Do not use getRouter().back().")

    return errors

@tool
def generate_code_llm(self, page_data: PageExtractionResult, error_feedback: str = "") -> str:
    """
    调用 LLM 生成代码。
    如果是 Retry，会包含 error_feedback。
    """
    
    system_prompt = f"""你是鸿蒙系统ArkTS语言专家，专注于生成规范的代码示例。
请严格遵守以下规则：
1. 如果创建了可复用组件，需要加上@Builder注释。
2. 在ArkTS中，**绝对不要使用三目表达式**，必须使用 if-else。
3. 只能有一个@Entry注释的组件。
4. **不要在代码中使用引用类资源**。
5. 回答由且仅由完整代码组成，不要Markdown格式，不要 ```typescript ... ``` 包裹。
6. 使用颜文字或文字代替简单图标，或使用以下系统资源：{', '.join(SYS_MEDIA_LIST)}。
7. 禁止内联对象类型，例如 `items: Array<{{text: string}}>` 是错误的，必须先定义 `interface PageName_Item {{ text: string }}`。
8. 所有 interface 定义必须在 @Entry 之外。
9. 页面跳转使用 `this.getUIContext().getRouter().pushUrl()` 并处理 `.then().catch()`。
10. 组件属性设置要在组件调用之后链式调用。

参考代码片段 (RAG Context):
{{rag_context}}
"""

    user_prompt = f"""
请根据以下 UI 结构生成 ArkTS 代码：
页面名称: {{page_data.page_name}}
UI 结构 (JSON):
{{json.dumps(page_data.ui_tree, indent=2, ensure_ascii=False)}}

"""
    if error_feedback:
        user_prompt += f"\n\n!!! 上一次编译失败，请根据以下错误修改代码 !!!\n{{error_feedback}}\n"
        
    try:
        response = client.chat.completions.create(
            model="deepseek-chat", # 或者 deepseek-v3, 取决于可用模型
            messages=[
                {{"role": "system", "content": system_prompt}},
                {{"role": "user", "content": user_prompt}},
            ],
            temperature=0.2, # 低温度以保证准确性
            stream=False
        )
        return response.choices[0].message.content.strip()
    except Exception as e:
        return f"// Error generating code: {{str(e)}}"

@tool
def extract_keywords(self, ui_tree: Dict[str, Any]) -> List[str]:
    """
    从 UI Tree 中递归提取所有组件类型作为关键词。
    """
    keywords = set()
    def traverse(node):
        if isinstance(node, dict):
            if "type" in node:
                keywords.add(f"ArkTS {{node['type']}}") # 添加 ArkTS 前缀有助于检索
            for key, value in node.items():
                traverse(value)
        elif isinstance(node, list):
            for item in node:
                traverse(item)
                
    traverse(ui_tree)
    return list(keywords)
