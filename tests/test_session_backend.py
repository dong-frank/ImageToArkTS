import tempfile
import unittest
from pathlib import Path


class SessionBackendTests(unittest.TestCase):
    def test_backend_routes_skills_without_copying_into_session_root(self) -> None:
        from utils.session_backend import SessionBackendManager

        with tempfile.TemporaryDirectory() as tmpdir:
            project_root = Path(tmpdir)
            shared_skill_dir = project_root / "agent_workspace" / "skills" / "harmony-next"
            shared_skill_dir.mkdir(parents=True, exist_ok=True)
            (shared_skill_dir / "SKILL.md").write_text(
                "---\nname: harmony-next\ndescription: test skill\n---\n",
                encoding="utf-8",
            )

            manager = SessionBackendManager(project_root=project_root)
            backend = manager.get_backend("session-a")

            session_root = project_root / "agent_workspace" / "sessions" / "session-a"
            self.assertTrue(session_root.exists())
            self.assertFalse((session_root / "skills").exists())

            skills_listing = backend.ls_info("/skills")
            self.assertEqual(len(skills_listing), 1)
            self.assertEqual(skills_listing[0]["path"], "/skills/harmony-next/")

            read_result = backend.read("/skills/harmony-next/SKILL.md")
            self.assertIn("harmony-next", read_result)


if __name__ == "__main__":
    unittest.main()
