import unittest
from unittest import mock


class SkillQaAgentTests(unittest.TestCase):
    def test_skill_qa_agent_uses_harmony_next_skill(self) -> None:
        from scripts.skill_qa_agent import build_skill_qa_agent_spec

        spec = build_skill_qa_agent_spec()

        self.assertEqual(spec["name"], "skill_qa_agent")
        self.assertEqual(spec["skills"], ["/skills"])

    def test_script_bootstrap_adds_repo_root_to_sys_path(self) -> None:
        import importlib.util
        import sys
        from pathlib import Path

        script_path = Path(__file__).resolve().parent.parent / "scripts" / "skill_qa_agent.py"
        spec = importlib.util.spec_from_file_location("skill_qa_agent_bootstrap_test", script_path)
        module = importlib.util.module_from_spec(spec)
        assert spec and spec.loader
        spec.loader.exec_module(module)

        repo_root = str(script_path.resolve().parent.parent)
        self.assertIn(repo_root, sys.path)

    def test_ask_supplies_default_thread_id(self) -> None:
        from scripts.skill_qa_agent import ask

        fake_agent = mock.Mock()
        fake_agent.invoke.return_value = {"messages": []}

        with mock.patch("scripts.skill_qa_agent.build_skill_qa_agent", return_value=fake_agent):
            ask("test question")

        _, kwargs = fake_agent.invoke.call_args
        thread_id = kwargs["config"]["configurable"]["thread_id"]
        self.assertTrue(thread_id.startswith("skill-qa-agent-"))

    def test_skill_qa_agent_builds_with_filesystem_backend(self) -> None:
        from scripts.skill_qa_agent import build_skill_qa_agent

        agent = build_skill_qa_agent()

        self.assertEqual(type(agent).__name__, "CompiledStateGraph")


if __name__ == "__main__":
    unittest.main()
