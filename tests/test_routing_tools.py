import unittest
from unittest.mock import Mock


class RoutingToolsContractTests(unittest.TestCase):
    def test_architect_dispatch_contract_is_fixed(self) -> None:
        from tools.routing_tools import build_architect_dispatch_description

        description = build_architect_dispatch_description()

        self.assertIn("task_type: architecture", description)
        self.assertIn("- /user_input/user_input_metadata.json", description)
        self.assertIn("- /designs/architect.json", description)
        self.assertNotIn("- /user_input/description.md", description)
        self.assertNotIn("- /user_input_metadata.json", description)
        self.assertNotIn("\n- /user_input\n", f"\n{description}\n")
        self.assertIn("use metadata file to discover uploaded asset file paths", description)
        self.assertNotIn("帮我实现", description)

    def test_tester_dispatch_contract_requires_test_description(self) -> None:
        from tools.routing_tools import build_tester_dispatch_description

        description = build_tester_dispatch_description()

        self.assertIn("task_type: validation", description)
        self.assertIn("- /user_input/user_input_metadata.json", description)
        self.assertIn("- /user_input/description.md", description)
        self.assertIn("- /logs/tester/latest_tester_report.json", description)
        self.assertIn("request or create /user_input/description.md", description)

    def test_coder_fix_dispatch_contract_uses_tester_report(self) -> None:
        from tools.routing_tools import build_coder_dispatch_description

        description = build_coder_dispatch_description(task_type="fix_from_test")

        self.assertIn("task_type: fix_from_test", description)
        self.assertIn("- /logs/tester/latest_tester_report.json", description)
        self.assertIn("need_human_guidance", description)

    def test_main_tools_use_routing_tools(self) -> None:
        from tools.tool_sets import ORCHESTRATOR_AGENT_TOOLS

        tool_names = [tool.name for tool in ORCHESTRATOR_AGENT_TOOLS]

        self.assertIn("dispatch_architect", tool_names)
        self.assertIn("dispatch_coder", tool_names)
        self.assertIn("dispatch_tester", tool_names)
        self.assertNotIn("save_architect_design", tool_names)

    def test_invoke_subagent_forwards_runtime_config(self) -> None:
        from tools.routing_tools import _invoke_subagent

        agent = Mock()
        agent.invoke.return_value = {"messages": []}
        runtime = Mock()
        runtime.state = {"messages": ["ignored"], "custom": "value"}
        runtime.config = {"configurable": {"thread_id": "session-123"}}

        _invoke_subagent(agent, "task_type: architecture", runtime)

        agent.invoke.assert_called_once()
        _, kwargs = agent.invoke.call_args
        self.assertEqual(kwargs["config"], {"configurable": {"thread_id": "session-123"}})

    def test_dispatch_architect_prefers_structured_response(self) -> None:
        from tools.routing_tools import dispatch_architect

        runtime = Mock()
        runtime.tool_call_id = "tool-1"
        runtime.state = {}
        runtime.config = {"configurable": {"thread_id": "session-123"}}

        structured = {
            "project_name": "calculator_app",
            "app_display_name": "计算器",
            "pages": [
                {
                    "name": "Index",
                    "responsibilities": "展示计算器主界面与结果区域",
                }
            ],
        }

        result = {
            "messages": [Mock(text="not-json")],
            "structured_response": structured,
        }

        with (
            unittest.mock.patch("tools.routing_tools.get_architect_agent") as get_architect_agent,
            unittest.mock.patch("tools.routing_tools.save_architect_design_payload") as save_payload,
        ):
            get_architect_agent.return_value.invoke.return_value = result
            save_payload.return_value = "architect 设计已保存到 /designs/architect.json"

            command = dispatch_architect.func(runtime=runtime)

        save_payload.assert_called_once_with(structured)
        tool_message = command.update["messages"][0]
        self.assertIn('"project_name": "calculator_app"', tool_message.content)

    def test_dispatch_tester_prefers_structured_response(self) -> None:
        from tools.routing_tools import dispatch_tester

        runtime = Mock()
        runtime.tool_call_id = "tool-2"
        runtime.state = {}
        runtime.config = {"configurable": {"thread_id": "session-123"}}

        structured = {
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

        result = {
            "messages": [Mock(text="not-json")],
            "structured_response": structured,
        }

        with unittest.mock.patch("tools.routing_tools.get_tester_agent") as get_tester_agent:
            get_tester_agent.return_value.invoke.return_value = result
            command = dispatch_tester.func(runtime=runtime)

        tool_message = command.update["messages"][0]
        self.assertIn('"overall": "PASS"', tool_message.content)


if __name__ == "__main__":
    unittest.main()
