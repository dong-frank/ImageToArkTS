import json
import tempfile
import unittest
from pathlib import Path


class CoderPipelineTests(unittest.TestCase):
    def test_materialize_coder_skeleton_creates_artifacts(self) -> None:
        from tools.coder_tools import materialize_coder_skeleton, save_coder_skeleton_plan_payload
        from utils.session_context import reset_current_session_id, set_current_session_id
        from utils.session_workspace import session_workspace_dir

        with tempfile.TemporaryDirectory() as tmpdir:
            project_root = Path(tmpdir)
            session_id = "session-coder-skeleton"
            token = set_current_session_id(session_id)
            try:
                skeleton_payload = {
                    "project_name": "calculator_app",
                    "app_display_name": "计算器",
                    "page_tasks": [
                        {
                            "page_name": "Index",
                            "route": "pages/Index",
                            "page_file": "/projects/calculator_app/entry/src/main/ets/pages/Index.ets",
                            "allowed_write_paths": ["/projects/calculator_app/entry/src/main/ets/pages/Index.ets"],
                            "shared_dependencies": ["AppHeader", "CalculatorStore"],
                            "responsibilities": "主计算页面",
                            "primary_actions": ["append_digit", "evaluate"],
                        },
                        {
                            "page_name": "History",
                            "route": "pages/History",
                            "page_file": "/projects/calculator_app/entry/src/main/ets/pages/History.ets",
                            "allowed_write_paths": ["/projects/calculator_app/entry/src/main/ets/pages/History.ets"],
                            "shared_dependencies": ["AppHeader", "CalculatorStore"],
                            "responsibilities": "历史记录页面",
                            "primary_actions": ["open_record"],
                        },
                    ],
                }

                save_coder_skeleton_plan_payload(skeleton_payload, project_root=project_root)
                result = materialize_coder_skeleton(skeleton_payload, project_root=project_root)

                self.assertIn("status: SUCCESS", result)
                workspace = session_workspace_dir(project_root, session_id)
                self.assertTrue((workspace / "designs" / "coder_page_tasks.json").exists())

                page_tasks = json.loads((workspace / "designs" / "coder_page_tasks.json").read_text(encoding="utf-8"))
                self.assertEqual(len(page_tasks["tasks"]), 2)

                project_dir = workspace / "projects" / "calculator_app"
                self.assertTrue((project_dir / "entry/src/main/ets/pages/History.ets").exists())
                main_pages_path = project_dir / "entry/src/main/resources/base/profile/main_pages.json"
                self.assertTrue(main_pages_path.exists())
                main_pages = json.loads(main_pages_path.read_text(encoding="utf-8"))
                self.assertEqual(main_pages["src"], ["pages/Index", "pages/History"])

                index_page_text = (project_dir / "entry/src/main/ets/pages/Index.ets").read_text(encoding="utf-8")
                history_page_text = (project_dir / "entry/src/main/ets/pages/History.ets").read_text(encoding="utf-8")
                self.assertIn("BottomNavBar", index_page_text)
                self.assertIn("BottomNavBar", history_page_text)

                navigation_service_path = project_dir / "entry/src/main/ets/common/services/NavigationService.ets"
                bottom_nav_path = project_dir / "entry/src/main/ets/common/components/BottomNavBar.ets"
                self.assertTrue(navigation_service_path.exists())
                self.assertTrue(bottom_nav_path.exists())
                self.assertIn("routeFor", navigation_service_path.read_text(encoding="utf-8"))
            finally:
                reset_current_session_id(token)

    def test_compile_fix_logs_are_persisted(self) -> None:
        from tools.coder_tools import (
            append_coder_compile_fix_attempt,
            build_coder_compile_fix_attempt_payload,
            load_coder_compile_fix_history_payload,
            load_coder_compile_fix_trace_payload,
            save_coder_compile_fix_trace_payload,
        )
        from utils.session_context import reset_current_session_id, set_current_session_id

        with tempfile.TemporaryDirectory() as tmpdir:
            project_root = Path(tmpdir)
            token = set_current_session_id("session-compile-fix-log")
            try:
                attempt = build_coder_compile_fix_attempt_payload(
                    attempt_index=1,
                    task_type="implementation",
                    project_name="calculator_app",
                    compile_status="FAILED",
                    error_signature="missing-import",
                    key_errors=["Cannot find module './Foo'"],
                    worker_summary="added placeholder import",
                    worker_summaries_so_far=["added placeholder import"],
                    modified_files=["/projects/calculator_app/entry/src/main/ets/pages/Index.ets"],
                    fixes_applied=["added placeholder import"],
                    skills_referenced=["/skills/harmony-next/SKILL.md"],
                    final_success=False,
                )
                append_coder_compile_fix_attempt(attempt, project_root=project_root)
                save_coder_compile_fix_trace_payload(
                    {
                        "project_name": "calculator_app",
                        "task_type": "implementation",
                        "attempts": [attempt],
                        "final_compile_status": "FAILED",
                        "final_success": False,
                    },
                    project_root=project_root,
                )

                history = load_coder_compile_fix_history_payload(project_root=project_root)
                trace = load_coder_compile_fix_trace_payload(project_root=project_root)

                self.assertEqual(len(history), 1)
                self.assertEqual(history[0]["error_signature"], "missing-import")
                self.assertEqual(trace["project_name"], "calculator_app")
                self.assertEqual(trace["attempts"][0]["compile_status"], "FAILED")
            finally:
                reset_current_session_id(token)


if __name__ == "__main__":
    unittest.main()
