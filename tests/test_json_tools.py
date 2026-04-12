import tempfile
import unittest
from pathlib import Path


class JsonToolsTests(unittest.TestCase):
    def test_validate_json_syntax_reports_valid_json(self) -> None:
        from tools.json_tools import _validate_json_syntax
        from utils.session_context import reset_current_session_id, set_current_session_id

        with tempfile.TemporaryDirectory() as tmpdir:
            project_root = Path(tmpdir)
            token = set_current_session_id("session-json-valid")
            try:
                target = project_root / "agent_workspace" / "sessions" / "session-json-valid" / "designs" / "sample.json"
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text('{"name":"demo","items":[1,2,3]}', encoding="utf-8")

                result = _validate_json_syntax("/designs/sample.json", project_root=project_root)

                self.assertIn("status: VALID", result)
                self.assertIn("json_type: object", result)
            finally:
                reset_current_session_id(token)

    def test_validate_json_syntax_reports_invalid_json(self) -> None:
        from tools.json_tools import _validate_json_syntax
        from utils.session_context import reset_current_session_id, set_current_session_id

        with tempfile.TemporaryDirectory() as tmpdir:
            project_root = Path(tmpdir)
            token = set_current_session_id("session-json-invalid")
            try:
                target = project_root / "agent_workspace" / "sessions" / "session-json-invalid" / "designs" / "broken.json"
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text('{"name": "demo",}', encoding="utf-8")

                result = _validate_json_syntax("/designs/broken.json", project_root=project_root)

                self.assertIn("status: INVALID", result)
                self.assertIn("error:", result)
            finally:
                reset_current_session_id(token)
