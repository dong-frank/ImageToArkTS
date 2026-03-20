from langchain_openai import ChatOpenAI
import dotenv
import os

dotenv.load_dotenv()


vision_model = ChatOpenAI(
        model="qwen3-vl-plus",
        api_key=os.getenv("DASHSCOPE_API_KEY"),
        base_url=os.getenv("DASHSCOPE_BASE_URL"),
)

base_model = ChatOpenAI(
        model="qwen3-max",
        api_key=os.getenv("DASHSCOPE_API_KEY"),
        base_url=os.getenv("DASHSCOPE_BASE_URL"),
)