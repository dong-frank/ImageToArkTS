from pathlib import Path
import subprocess

from agent import run_agent


def main():
    project_root = Path(__file__).resolve().parent
    reset_script = project_root / "scripts" / "reset_agent_workspace.sh"

    subprocess.run(["bash", str(reset_script)], check=True, cwd=project_root)
    run_agent()


if __name__ == "__main__":
    main()
