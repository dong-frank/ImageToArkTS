import os

import dotenv
from langchain_openai import ChatOpenAI

dotenv.load_dotenv()


architect_vision_model = ChatOpenAI(
        model="qwen3-vl-plus",
        api_key=os.getenv("DASHSCOPE_API_KEY"),
        base_url=os.getenv("DASHSCOPE_BASE_URL"),
)

vision_model = ChatOpenAI(
        model="qwen3-vl-plus",
        api_key=os.getenv("DASHSCOPE_API_KEY"),
        base_url=os.getenv("DASHSCOPE_BASE_URL"),
)

small_model = ChatOpenAI(
        model=os.getenv("SMALL_MODEL_NAME", "qwen-turbo"),
        api_key=os.getenv("DASHSCOPE_API_KEY"),
        base_url=os.getenv("DASHSCOPE_BASE_URL"),
        extra_body={"enable_thinking": False},
)

base_model = ChatOpenAI(
        model="qwen3.5-plus",
        api_key=os.getenv("DASHSCOPE_API_KEY"),
        base_url=os.getenv("DASHSCOPE_BASE_URL"),
        extra_body={"enable_thinking": False},
)
