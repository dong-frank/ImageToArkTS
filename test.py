from langchain_openai import ChatOpenAI
llm = ChatOpenAI(
    api_key="sk-a4c42c7950e44abb841df063650ed0c8",
    base_url="https://dashscope.aliyuncs.com/compatible-mode/v1",  # 北京地域
    model="qwen3-vl-plus"  # 确保模型名称正确
)
response = llm(messages=[{"role": "user", "content": "示例输入"}])
print(response.usage)  # 检查Token消耗及抵扣情况