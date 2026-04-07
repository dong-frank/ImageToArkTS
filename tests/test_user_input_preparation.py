import tempfile
import unittest
from pathlib import Path

from langchain_core.messages import HumanMessage


class UserInputPreparationTests(unittest.TestCase):
    def test_refresh_user_input_artifacts_does_not_build_description_from_uploads(self) -> None:
        from utils.user_input_preparation import (
            refresh_user_input_artifacts,
            save_user_input_metadata_payload,
        )
        from utils.session_workspace import session_description_md_path, session_user_input_dir

        with tempfile.TemporaryDirectory() as tmpdir:
            project_root = Path(tmpdir)
            session_id = "session-a"
            user_input_dir = session_user_input_dir(project_root, session_id)
            user_input_dir.mkdir(parents=True, exist_ok=True)
            (user_input_dir / "notes.txt").write_text("calculator requirements", encoding="utf-8")

            save_user_input_metadata_payload(
                project_root,
                session_id,
                {
                    "files": {
                        "screen.png": {
                            "name": "screen.png",
                            "description": "calculator main screen",
                            "path": "/user_input/screen.png",
                            "content_type": "image/png",
                        },
                        "notes.txt": {
                            "name": "notes.txt",
                            "description": "text requirement file",
                            "path": "/user_input/notes.txt",
                            "content_type": "text/plain",
                        },
                    }
                },
            )

            refresh_user_input_artifacts(project_root, session_id)

            self.assertFalse(session_description_md_path(project_root, session_id).exists())

    def test_prepend_instruction_references_metadata_only(self) -> None:
        from utils.user_input_preparation import prepend_user_input_instruction, refresh_user_input_artifacts
        from utils.session_workspace import session_description_md_path, session_user_input_dir

        with tempfile.TemporaryDirectory() as tmpdir:
            project_root = Path(tmpdir)
            session_id = "session-b"
            user_input_dir = session_user_input_dir(project_root, session_id)
            user_input_dir.mkdir(parents=True, exist_ok=True)
            (user_input_dir / "requirements.md").write_text("uploaded requirements", encoding="utf-8")

            refresh_user_input_artifacts(project_root, session_id)

            messages = prepend_user_input_instruction(
                project_root,
                [HumanMessage(content="帮我实现一个简单的计算器app")],
                session_id,
            )

            combined = messages[-1].content

            self.assertFalse(session_description_md_path(project_root, session_id).exists())
            self.assertIn("/user_input/user_input_metadata.json", combined)
            self.assertNotIn("/user_input/description.md", combined)
            self.assertIn("帮我实现一个简单的计算器app", combined)

    def test_persist_test_description_writes_description_md(self) -> None:
        from utils.user_input_preparation import persist_test_description
        from utils.session_workspace import session_description_md_path

        with tempfile.TemporaryDirectory() as tmpdir:
            project_root = Path(tmpdir)
            session_id = "session-c"

            persist_test_description(project_root, session_id, "请重点测试加减乘除和清空按钮")

            description_path = session_description_md_path(project_root, session_id)
            self.assertTrue(description_path.exists())
            self.assertEqual(
                description_path.read_text(encoding="utf-8"),
                "请重点测试加减乘除和清空按钮",
            )


if __name__ == "__main__":
    unittest.main()
