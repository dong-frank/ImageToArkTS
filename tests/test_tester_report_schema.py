import json
import tempfile
import unittest
from pathlib import Path


class TesterReportSchemaTests(unittest.TestCase):
    def test_save_tester_report_payload_accepts_schema_dict(self) -> None:
        from tools.tester_tools import save_tester_report_payload
        from utils.session_context import reset_current_session_id, set_current_session_id
        from utils.session_workspace import session_workspace_dir

        with tempfile.TemporaryDirectory() as tmpdir:
            project_root = Path(tmpdir)
            session_id = "session-report"
            token = set_current_session_id(session_id)
            try:
                payload = {
                    "overall": "PASS",
                    "functional_completeness": "PASS",
                    "static_ui_completeness": "PASS",
                    "functional_checklist": [],
                    "static_ui_checklist": [],
                    "missing_items": {"functional": [], "ui": []},
                    "evidence_paths": {
                        "description": "/user_input/description.md",
                        "reference_images": [],
                        "runtime_screenshots": [],
                        "layout_json": [],
                        "ui_compare_logs": [],
                        "report_path": "/logs/tester/latest_tester_report.json",
                    },
                    "fix_suggestions": {"p0": [], "p1": [], "p2": []},
                    "completion_summary": {
                        "task_type": "validation",
                        "report_saved": True,
                        "next_recommended_agent": "coder",
                        "blocker": "none",
                    },
                }

                result = save_tester_report_payload(payload, project_root=project_root)
                latest_path = session_workspace_dir(project_root, session_id) / "logs" / "tester" / "latest_tester_report.json"

                self.assertIn("status: SUCCESS", result)
                self.assertTrue(latest_path.exists())
                saved = json.loads(latest_path.read_text(encoding="utf-8"))
                self.assertEqual(saved["overall"], "PASS")
            finally:
                reset_current_session_id(token)


if __name__ == "__main__":
    unittest.main()
