from __future__ import annotations

import os
import shutil
import subprocess
from pathlib import Path
from typing import List

from utils.session_context import get_current_session_id
from utils.session_workspace import session_workspace_dir

PROJECT_ROOT = Path(__file__).resolve().parent.parent


def workspace_root() -> Path:
    return session_workspace_dir(PROJECT_ROOT, get_current_session_id())


def projects_root() -> Path:
    return workspace_root() / "projects"


def resolve_workspace_path(raw_path: str) -> Path:
    raw = str(raw_path or "").strip()
    root = workspace_root()
    if not raw:
        return root

    normalized = raw.replace("\\", "/")
    if normalized.startswith("/"):
        return root / normalized.lstrip("/")

    candidate = Path(raw)
    if candidate.is_absolute():
        return candidate

    return PROJECT_ROOT / normalized


def ensure_directory(path: Path) -> Path:
    path.mkdir(parents=True, exist_ok=True)
    return path


def run_cmd(cmd: List[str], check: bool = False, timeout: int = 120) -> subprocess.CompletedProcess[str]:
    try:
        return subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="ignore",
            check=check,
            timeout=timeout,
        )
    except FileNotFoundError:
        command = cmd[0] if cmd else "<empty>"
        message = (
            f"command not found: {command}. "
            "If you are on WSL and Harmony emulator is on Windows, "
            "set HDC_WINDOWS_EXE to the full hdc.exe path."
        )
        return subprocess.CompletedProcess(args=cmd, returncode=127, stdout="", stderr=message)


def is_wsl() -> bool:
    if os.name != "posix":
        return False
    try:
        with open("/proc/version", "r", encoding="utf-8", errors="ignore") as fp:
            version_info = fp.read().lower()
        return "microsoft" in version_info or "wsl" in version_info
    except OSError:
        return False


def to_windows_path_if_needed(path_value: str) -> str:
    if not is_wsl():
        return path_value
    result = run_cmd(["wslpath", "-w", str(path_value)], check=False, timeout=10)
    if result.returncode == 0 and (result.stdout or "").strip():
        return result.stdout.strip()
    return path_value


def resolve_hdc_executable() -> str:
    explicit = str(os.getenv("HDC_EXECUTABLE", "")).strip()
    if explicit:
        return explicit

    if is_wsl():
        win_hdc = str(os.getenv("HDC_WINDOWS_EXE", "")).strip()
        if win_hdc:
            return win_hdc

        for candidate in ["hdc.exe", "hdc"]:
            resolved = shutil.which(candidate)
            if resolved:
                return resolved

        common_paths = [
            "/mnt/c/Program Files/Huawei/DevEco Studio/tools/hdc.exe",
            "/mnt/c/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/toolchains/hdc.exe",
            "/mnt/c/Program Files/Huawei/DevEco Studio/sdk/default/ohos-sdk/toolchains/hdc.exe",
            "/mnt/c/Program Files/DevEco Studio/tools/hdc.exe",
        ]
        for path in common_paths:
            if os.path.exists(path):
                return path

    for candidate in ["hdc", "hdc.exe"]:
        resolved = shutil.which(candidate)
        if resolved:
            return resolved

    return "hdc"


def _hdc_uses_windows_binary(hdc_executable: str) -> bool:
    lowered = hdc_executable.lower()
    if lowered.endswith(".exe"):
        return True
    return bool(is_wsl() and os.getenv("HDC_WINDOWS_EXE"))


def _adapt_hdc_args_for_target(hdc_args: List[str], hdc_executable: str) -> List[str]:
    adapted = list(hdc_args)
    if not _hdc_uses_windows_binary(hdc_executable):
        return adapted

    if len(adapted) >= 4 and adapted[0] == "file" and adapted[1] == "recv":
        adapted[3] = to_windows_path_if_needed(adapted[3])
    elif len(adapted) >= 4 and adapted[0] == "file" and adapted[1] == "send":
        adapted[2] = to_windows_path_if_needed(adapted[2])
    elif len(adapted) >= 2 and adapted[0] == "install":
        for idx in range(1, len(adapted)):
            value = adapted[idx]
            if value.startswith("-"):
                continue
            if os.path.exists(value):
                adapted[idx] = to_windows_path_if_needed(value)
    return adapted


def run_hdc_cmd(hdc_args: List[str], check: bool = False, timeout: int = 120) -> subprocess.CompletedProcess[str]:
    hdc_executable = resolve_hdc_executable()
    adapted_args = _adapt_hdc_args_for_target(hdc_args, hdc_executable)
    return run_cmd([hdc_executable, *adapted_args], check=check, timeout=timeout)


def format_cmd_result(result: subprocess.CompletedProcess[str]) -> str:
    stdout = (result.stdout or "").strip()
    stderr = (result.stderr or "").strip()
    return "\n".join(
        [
            f"exit_code: {result.returncode}",
            "stdout:",
            stdout if stdout else "(empty)",
            "stderr:",
            stderr if stderr else "(empty)",
        ]
    )
