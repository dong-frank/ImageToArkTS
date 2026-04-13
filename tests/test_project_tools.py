import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch


class ProjectToolsTests(unittest.TestCase):
    def test_create_project_uses_unified_create_script(self) -> None:
        from tools import project_tools
        from utils.session_context import reset_current_session_id, set_current_session_id

        with tempfile.TemporaryDirectory() as tmpdir:
            project_root = Path(tmpdir)
            token = set_current_session_id("session-create-project")
            try:
                expected_workspace = project_root / "agent_workspace" / "sessions" / "session-create-project" / "projects"
                script_path = project_root / "scripts" / "create_project.sh"
                script_path.parent.mkdir(parents=True, exist_ok=True)
                script_path.write_text("#!/usr/bin/env bash\n", encoding="utf-8")

                with patch.object(project_tools, "PROJECT_ROOT", project_root), patch.object(
                    project_tools, "CREATE_PROJECT_SCRIPT", script_path, create=True
                ), patch.object(project_tools, "projects_root", return_value=expected_workspace), patch.object(
                    project_tools.subprocess, "run"
                ) as run_mock:
                    run_mock.return_value = subprocess.CompletedProcess(
                        args=["bash", str(script_path), "demo_app"],
                        returncode=0,
                        stdout="Project created: demo_app\n",
                        stderr="",
                    )

                    result = project_tools.create_project.func("demo_app")

                run_mock.assert_called_with(
                    ["bash", str(script_path), "demo_app"],
                    cwd=expected_workspace,
                    capture_output=True,
                    text=True,
                    encoding="utf-8",
                    errors="ignore",
                )
                self.assertIn("项目创建完成", result)
                self.assertIn("create_mode: script", result)
                self.assertIn("project_path: /projects/demo_app", result)
            finally:
                reset_current_session_id(token)

    def test_create_project_script_uses_repo_templates_and_current_workdir(self) -> None:
        script_path = Path("/Users/dong/2026/ImageToArkTS-DeepAgents/scripts/create_project.sh")
        content = script_path.read_text(encoding="utf-8")

        self.assertIn('ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"', content)
        self.assertIn('TARGET_BASE_DIR="${TARGET_BASE_DIR:-$PWD}"', content)
        self.assertIn('PROJECT_DIR="$TARGET_BASE_DIR/$PROJECT_NAME"', content)
        self.assertIn("sync-harmony-shell-assets.mjs", content)
        self.assertIn("updateEntryAbilityAppId", content)
        self.assertIn("resfileAppsDir", content)
        self.assertIn('pkg.scripts[\'sync:app-harmony-shell\'] = \'node scripts/sync-harmony-shell-assets.mjs\'', content)
        self.assertIn('manifestRaw = manifestRaw.replace(/"appid"\\s*:\\s*"[^"]*"/, `"appid" : "${safeAppId}"`);', content)

    def test_compile_script_supports_preview_and_device_workflows(self) -> None:
        script_path = Path("/Users/dong/2026/ImageToArkTS-DeepAgents/scripts/compile.sh")
        content = script_path.read_text(encoding="utf-8")

        self.assertIn('MODE="${2:-device}"', content)
        self.assertIn('if [[ -x "./node_modules/.bin/uni" ]]; then', content)
        self.assertIn('run_step "npm-install" npm install', content)
        self.assertIn('run_step "npm-dev-h5" npm run dev:h5', content)
        self.assertIn('run_step "npm-build-harmony-cli" npm run build:harmony:cli', content)
        self.assertIn('run_step "hdc-install-hap" "$HDC_BIN" install -r "$HAP_RELATIVE_PATH"', content)
        self.assertIn('Supported modes: preview, device', content)

    def test_add_project_dependency_runs_npm_install_for_dev_dependency(self) -> None:
        from tools import project_tools
        from utils.session_context import reset_current_session_id, set_current_session_id

        with tempfile.TemporaryDirectory() as tmpdir:
            project_root = Path(tmpdir)
            token = set_current_session_id("session-add-project-dependency")
            try:
                project_dir = project_root / "agent_workspace" / "sessions" / "session-add-project-dependency" / "projects" / "demo_app"
                project_dir.mkdir(parents=True, exist_ok=True)
                (project_dir / "package.json").write_text('{"name":"demo_app"}\n', encoding="utf-8")

                with patch.object(project_tools, "projects_root", return_value=project_dir.parent), patch.object(
                    project_tools.subprocess, "run"
                ) as run_mock:
                    run_mock.return_value = subprocess.CompletedProcess(
                        args=["npm", "install", "-D", "sass"],
                        returncode=0,
                        stdout="added sass\n",
                        stderr="",
                    )

                    result = project_tools.add_project_dependency.func("demo_app", "sass", True)

                run_mock.assert_called_with(
                    ["npm", "install", "-D", "sass"],
                    cwd=project_dir,
                    capture_output=True,
                    text=True,
                    encoding="utf-8",
                    errors="ignore",
                )
                self.assertIn("dependency_add_status: SUCCESS", result)
                self.assertIn("project_path: /projects/demo_app", result)
                self.assertIn("package_name: sass", result)
                self.assertIn("dependency_scope: devDependency", result)
            finally:
                reset_current_session_id(token)

    def test_add_project_dependency_requires_package_json(self) -> None:
        from tools import project_tools
        from utils.session_context import reset_current_session_id, set_current_session_id

        with tempfile.TemporaryDirectory() as tmpdir:
            project_root = Path(tmpdir)
            token = set_current_session_id("session-add-project-dependency-missing")
            try:
                project_dir = project_root / "agent_workspace" / "sessions" / "session-add-project-dependency-missing" / "projects" / "demo_app"
                project_dir.mkdir(parents=True, exist_ok=True)

                with patch.object(project_tools, "projects_root", return_value=project_dir.parent):
                    result = project_tools.add_project_dependency.func("demo_app", "sass", True)

                self.assertIn("未找到 package.json", result)
            finally:
                reset_current_session_id(token)

    def test_add_project_dependency_requires_package_name(self) -> None:
        from tools import project_tools
        from utils.session_context import reset_current_session_id, set_current_session_id

        with tempfile.TemporaryDirectory() as tmpdir:
            project_root = Path(tmpdir)
            token = set_current_session_id("session-add-project-dependency-empty")
            try:
                project_dir = project_root / "agent_workspace" / "sessions" / "session-add-project-dependency-empty" / "projects" / "demo_app"
                project_dir.mkdir(parents=True, exist_ok=True)
                (project_dir / "package.json").write_text('{"name":"demo_app"}\n', encoding="utf-8")

                with patch.object(project_tools, "projects_root", return_value=project_dir.parent):
                    result = project_tools.add_project_dependency.func("demo_app", "", True)

                self.assertIn("package_name 不能为空", result)
            finally:
                reset_current_session_id(token)


if __name__ == "__main__":
    unittest.main()
