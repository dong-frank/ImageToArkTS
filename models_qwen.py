import os

import dotenv
from langchain_openai import ChatOpenAI

dotenv.load_dotenv()


architect_vision_model = ChatOpenAI(
        model="qwen3-vl-plus",
        api_key=os.getenv("DASHSCOPE_API_KEY"),
        base_url=os.getenv("DASHSCOPE_BASE_URL"),
)

architect_model = ChatOpenAI(
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
"""
base_model = ChatOpenAI(
        model="qwen3.5-plus",
        api_key=os.getenv("DASHSCOPE_API_KEY"),
        base_url=os.getenv("DASHSCOPE_BASE_URL"),
        extra_body={"enable_thinking": False},
)
"""
base_model = ChatOpenAI(
        model="deepseek-v4-pro",
        api_key=os.getenv("DEEPSEEK_API_KEY"),
        base_url=os.getenv("DEEPSEEK_BASE_URL"),
        extra_body={"enable_thinking": False},
)


# claude-sonnet-4.6
# architect_vision_model = ChatOpenAI(
#         model="anthropic/claude-sonnet-4.6",
#         api_key=os.getenv("OPENROUTER_API_KEY"),
#         base_url=os.getenv("OPENROUTER_BASE_URL"),
# )

# vision_model = ChatOpenAI(
#         model="anthropic/claude-sonnet-4.6",
#         api_key=os.getenv("OPENROUTER_API_KEY"),
#         base_url=os.getenv("OPENROUTER_BASE_URL"),
# )

# small_model = ChatOpenAI(
#         model="qwen-turbo",
#         api_key=os.getenv("DASHSCOPE_API_KEY"),
#         base_url=os.getenv("DASHSCOPE_BASE_URL"),
#         extra_body={"enable_thinking": False},
# )

# base_model = ChatOpenAI(
#         model="anthropic/claude-sonnet-4.6",
#         api_key=os.getenv("OPENROUTER_API_KEY"),
#         base_url=os.getenv("OPENROUTER_BASE_URL"),
#         extra_body={"enable_thinking": False},
# )

## glm

# architect_vision_model = ChatOpenAI(
#         model="z-ai/glm-5v-turbo",
#         api_key=os.getenv("OPENROUTER_API_KEY"),
#         base_url=os.getenv("OPENROUTER_BASE_URL"),
# )

# vision_model = ChatOpenAI(
#         model="z-ai/glm-5v-turbo",
#         api_key=os.getenv("OPENROUTER_API_KEY"),
#         base_url=os.getenv("OPENROUTER_BASE_URL"),
# )

# small_model = ChatOpenAI(
#         model="qwen-turbo",
#         api_key=os.getenv("DASHSCOPE_API_KEY"),
#         base_url=os.getenv("DASHSCOPE_BASE_URL"),
#         extra_body={"enable_thinking": False},
# )

# base_model = ChatOpenAI(
#         model="z-ai/glm-5v-turbo",
#         api_key=os.getenv("OPENROUTER_API_KEY"),
#         base_url=os.getenv("OPENROUTER_BASE_URL"),
#         extra_body={"enable_thinking": False},
# )