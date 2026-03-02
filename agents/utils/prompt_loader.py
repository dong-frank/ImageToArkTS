from functools import lru_cache
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
PROMPTS_DIR = PROJECT_ROOT / "prompts"


@lru_cache(maxsize=64)
def load_prompt(prompt_name: str) -> str:
    prompt_path = PROMPTS_DIR / prompt_name
    return prompt_path.read_text(encoding="utf-8")
