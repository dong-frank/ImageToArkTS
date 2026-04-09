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
                    "route_table": [
                        {
                            "page_name": "Index",
                            "route": "pages/Index",
                            "page_file": "/projects/calculator_app/entry/src/main/ets/pages/Index.ets",
                        },
                        {
                            "page_name": "History",
                            "route": "pages/History",
                            "page_file": "/projects/calculator_app/entry/src/main/ets/pages/History.ets",
                        },
                    ],
                    "shared_data_models": [
                        {
                            "field": "expression",
                            "type": "string",
                            "description": "当前表达式",
                        }
                    ],
                    "shared_components": [
                        {
                            "name": "AppHeader",
                            "file_path": "/projects/calculator_app/entry/src/main/ets/common/components/AppHeader.ets",
                            "description": "通用头部",
                        }
                    ],
                    "public_interfaces": [
                        {
                            "name": "CalculatorService",
                            "file_path": "/projects/calculator_app/entry/src/main/ets/common/services/CalculatorService.ets",
                            "description": "计算服务接口",
                        }
                    ],
                    "state_management": {
                        "store_name": "CalculatorStore",
                        "file_path": "/projects/calculator_app/entry/src/main/ets/common/store/CalculatorStore.ets",
                        "responsibilities": "管理表达式与结果状态",
                        "exposed_state": ["expression", "result"],
                        "exposed_actions": ["setExpression", "setResult", "clearAll"],
                    },
                    "page_tasks": [
                        {
                            "page_name": "Index",
                            "route": "pages/Index",
                            "page_file": "/projects/calculator_app/entry/src/main/ets/pages/Index.ets",
                            "component_files": [],
                            "allowed_write_paths": ["/projects/calculator_app/entry/src/main/ets/pages/Index.ets"],
                            "shared_dependencies": ["AppHeader", "CalculatorStore"],
                            "responsibilities": "主计算页面",
                            "primary_actions": ["append_digit", "evaluate"],
                        },
                        {
                            "page_name": "History",
                            "route": "pages/History",
                            "page_file": "/projects/calculator_app/entry/src/main/ets/pages/History.ets",
                            "component_files": [],
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
                self.assertTrue((project_dir / "entry/src/main/ets/common/store/CalculatorStore.ets").exists())
                main_pages_path = project_dir / "entry/src/main/resources/base/profile/main_pages.json"
                self.assertTrue(main_pages_path.exists())
                main_pages = json.loads(main_pages_path.read_text(encoding="utf-8"))
                self.assertEqual(main_pages["src"], ["pages/Index", "pages/History"])
            finally:
                reset_current_session_id(token)


if __name__ == "__main__":
    unittest.main()
