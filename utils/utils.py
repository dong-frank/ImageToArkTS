import os
from pathlib import Path

PROMPT_ROOT = Path(__file__).resolve().parents[1] / "prompts"
SCHEMA_ROOT = Path(__file__).resolve().parents[1] / "schemas"

def load_prompt(name: str) -> str:
    prompt_path = PROMPT_ROOT / name
    return prompt_path.read_text(encoding="utf-8")

