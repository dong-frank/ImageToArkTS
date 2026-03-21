from pathlib import Path
import subprocess
import time

from agent import run_agent


def main():
    start_time = time.perf_counter()
    project_root = Path(__file__).resolve().parent
    reset_script = project_root / "scripts" / "reset_agent_workspace.sh"

    subprocess.run(["bash", str(reset_script)], check=True, cwd=project_root)
    run_agent()
    elapsed = time.perf_counter() - start_time
    print(f"Total elapsed time: {elapsed:.2f}s")


if __name__ == "__main__":
    main()
