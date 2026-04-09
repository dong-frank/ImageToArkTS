import json
import unittest
from unittest.mock import Mock


class RoutingToolsContractTests(unittest.TestCase):
    def test_architect_dispatch_contract_is_fixed(self) -> None:
        from tools.routing_tools import build_architect_dispatch_description

        description = build_architect_dispatch_description()

        self.assertIn("task_type: architecture", description)
        self.assertIn("- /user_input/user_input_metadata.json", description)
        self.assertIn("- /designs/architect_image_facts.json", description)
        self.assertIn("- ArchitectOutput", description)
        self.assertNotIn("- /user_input/description.md", description)
        self.assertNotIn("- /user_input_metadata.json", description)
        self.assertNotIn("\n- /user_input\n", f"\n{description}\n")
        self.assertIn("build /designs/architect_image_facts.json", description)
        self.assertIn("orchestration persists /designs/architect.json", description)
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
        self.assertIn("- /designs/coder_skeleton_plan.json", description)
        self.assertIn("- /logs/coder/integration_report.json", description)

    def test_coder_implementation_dispatch_contract_mentions_three_stages(self) -> None:
        from tools.routing_tools import build_coder_dispatch_description

        description = build_coder_dispatch_description(task_type="implementation")

        self.assertIn("- /designs/coder_skeleton_plan.json", description)
        self.assertIn("- /designs/coder_page_tasks.json", description)
        self.assertIn("- /logs/coder/page_worker_results.json", description)
        self.assertIn("- /logs/coder/integration_report.json", description)
        self.assertIn("skeleton stage", description)
        self.assertIn("page implementation stage", description)
        self.assertIn("integration stage", description)

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

    def test_dispatch_architect_uses_tool_output(self) -> None:
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

        with (
            unittest.mock.patch("tools.routing_tools.invoke_architect_aggregator") as invoke_architect_aggregator,
            unittest.mock.patch("tools.routing_tools.save_architect_design_payload") as save_payload,
            unittest.mock.patch("tools.routing_tools.build_architect_image_facts_bundle_payload") as build_facts,
            unittest.mock.patch("tools.routing_tools.load_architect_materialized_inputs") as load_inputs,
        ):
            invoke_architect_aggregator.return_value = structured
            save_payload.return_value = "architect 设计已保存到 /designs/architect.json"
            build_facts.return_value = "status: SUCCESS"
            load_inputs.return_value = (
                {"files": {"a.png": {"path": "/user_input/a.png"}}},
                {"facts": [], "shared_patterns": [], "conflicts": [], "coverage_summary": {"total_image_count": 0, "processed_image_count": 0, "omitted_image_count": 0, "failed_image_count": 0, "strategy": "all_images_processed"}, "omitted_images": []},
            )

            command = dispatch_architect.func(runtime=runtime)

        build_facts.assert_called_once()
        save_payload.assert_called_once_with(structured)
        tool_message = command.update["messages"][0]
        self.assertIn('"project_name": "calculator_app"', tool_message.content)

    def test_dispatch_architect_requires_tool_output(self) -> None:
        from tools.routing_tools import dispatch_architect

        runtime = Mock()
        runtime.tool_call_id = "tool-3"
        runtime.state = {}
        runtime.config = {"configurable": {"thread_id": "session-123"}}

        with (
            unittest.mock.patch("tools.routing_tools.invoke_architect_aggregator") as invoke_architect_aggregator,
            unittest.mock.patch("tools.routing_tools.build_architect_image_facts_bundle_payload") as build_facts,
            unittest.mock.patch("tools.routing_tools.load_architect_materialized_inputs") as load_inputs,
        ):
            invoke_architect_aggregator.side_effect = ValueError("Architect dispatch requires tool-call output from ArchitectOutput")
            build_facts.return_value = "status: SUCCESS"
            load_inputs.return_value = (
                {"files": {}},
                {"facts": [], "shared_patterns": [], "conflicts": [], "coverage_summary": {"total_image_count": 0, "processed_image_count": 0, "omitted_image_count": 0, "failed_image_count": 0, "strategy": "all_images_processed"}, "omitted_images": []},
            )

            with self.assertRaisesRegex(ValueError, "tool-call output"):
                dispatch_architect.func(runtime=runtime)

    def test_invoke_architect_aggregator_extracts_tool_args(self) -> None:
        from tools.routing_tools import invoke_architect_aggregator

        llm_response = Mock()

        with (
            unittest.mock.patch("tools.routing_tools.invoke_with_tool") as invoke_with_tool,
            unittest.mock.patch("tools.routing_tools.extract_tool_call_args") as extract_tool_call_args,
        ):
            invoke_with_tool.return_value = llm_response
            extract_tool_call_args.return_value = {
                "project_name": "calculator_app",
                "app_display_name": "计算器",
                "pages": [{"name": "Index", "responsibilities": "展示主页面"}],
            }

            result = invoke_architect_aggregator({"files": {}}, {"facts": []})

        self.assertEqual(result["project_name"], "calculator_app")

    def test_architect_aggregation_prompt_materializes_metadata_and_facts(self) -> None:
        from tools.routing_tools import build_architect_aggregation_prompt

        prompt = build_architect_aggregation_prompt(
            metadata_payload={"files": {"a.png": {"path": "/user_input/a.png", "content_type": "image/png"}}},
            facts_bundle={
                "facts": [
                    {
                        "image_path": "/user_input/a.png",
                        "image_role": "entry",
                        "visible_texts": ["Calculator"],
                        "layout_summary": "display and keypad",
                        "key_sections": ["display", "keypad"],
                        "interactive_hints": ["tap digits"],
                        "uncertainties": [],
                    }
                ],
                "shared_patterns": [],
                "conflicts": [],
                "coverage_summary": {
                    "total_image_count": 1,
                    "processed_image_count": 1,
                    "omitted_image_count": 0,
                    "failed_image_count": 0,
                    "strategy": "all_images_processed",
                },
                "omitted_images": [],
            },
        )

        self.assertIn("/user_input/user_input_metadata.json", prompt)
        self.assertIn("/designs/architect_image_facts.json", prompt)
        self.assertIn("Calculator", prompt)
        self.assertIn("display and keypad", prompt)

    def test_dispatch_tester_reads_saved_json_report(self) -> None:
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

        result = {"messages": [Mock(text="not-json")]}

        with (
            unittest.mock.patch("tools.routing_tools.get_tester_agent") as get_tester_agent,
            unittest.mock.patch("tools.routing_tools.load_tester_report_payload") as load_tester_report_payload,
        ):
            get_tester_agent.return_value.invoke.return_value = result
            load_tester_report_payload.return_value = structured
            command = dispatch_tester.func(runtime=runtime)

        tool_message = command.update["messages"][0]
        self.assertIn('"overall": "PASS"', tool_message.content)

    def test_dispatch_coder_routes_through_coder_orchestrator(self) -> None:
        from tools.routing_tools import dispatch_coder

        runtime = Mock()
        runtime.tool_call_id = "tool-coder"
        runtime.state = {}
        runtime.config = {"configurable": {"thread_id": "session-123"}}

        orchestrator_result = {"messages": [Mock(text='{"compile_status":"SUCCESS"}')]}

        with (
            unittest.mock.patch("tools.routing_tools.get_coder_orchestrator") as get_coder_orchestrator,
            unittest.mock.patch("tools.routing_tools._invoke_subagent") as invoke_subagent,
        ):
            get_coder_orchestrator.return_value = Mock()
            invoke_subagent.return_value = orchestrator_result

            dispatch_coder.func(task_type="implementation", runtime=runtime)

        invoke_subagent.assert_called_once()
        called_agent = invoke_subagent.call_args.args[0]
        self.assertIs(called_agent, get_coder_orchestrator.return_value)

    def test_dispatch_coder_skeleton_calls_create_project_and_materialize(self) -> None:
        from tools.routing_tools import dispatch_coder_skeleton

        runtime = Mock()
        runtime.tool_call_id = "tool-skeleton"
        runtime.state = {}
        runtime.config = {"configurable": {"thread_id": "session-123"}}

        skeleton_payload = {
            "project_name": "damai_app",
            "app_display_name": "大麦",
            "route_table": [],
            "shared_data_models": [],
            "shared_components": [],
            "public_interfaces": [],
            "state_management": {
                "store_name": "AppStore",
                "file_path": "/projects/damai_app/entry/src/main/ets/common/store/AppStore.ets",
                "responsibilities": "管理全局共享状态",
                "exposed_state": [],
                "exposed_actions": [],
            },
            "page_tasks": [],
        }

        with (
            unittest.mock.patch("tools.routing_tools.load_architect_design_payload") as load_architect_design_payload,
            unittest.mock.patch("tools.routing_tools.invoke_coder_skeleton_planner") as invoke_coder_skeleton_planner,
            unittest.mock.patch("tools.routing_tools.save_coder_skeleton_plan_payload") as save_coder_skeleton_plan_payload,
            unittest.mock.patch("tools.routing_tools.create_project") as create_project,
            unittest.mock.patch("tools.routing_tools.materialize_coder_skeleton") as materialize_coder_skeleton,
        ):
            load_architect_design_payload.return_value = {"project_name": "damai_app", "app_display_name": "大麦", "pages": []}
            invoke_coder_skeleton_planner.return_value = skeleton_payload
            create_project.func.return_value = "项目创建完成"
            materialize_coder_skeleton.return_value = "status: SUCCESS"

            command = dispatch_coder_skeleton.func(task_type="implementation", runtime=runtime)

        create_project.func.assert_called_once_with("damai_app")
        materialize_coder_skeleton.assert_called_once_with(skeleton_payload)
        self.assertIn('"project_name": "damai_app"', command.update["messages"][0].content)

    def test_invoke_coder_skeleton_planner_extracts_tool_args(self) -> None:
        from tools.routing_tools import invoke_coder_skeleton_planner

        llm_response = Mock()
        expected = {
            "project_name": "damai_app",
            "app_display_name": "大麦",
            "route_table": [
                {
                    "page_name": "Index",
                    "route": "pages/Index",
                    "page_file": "/projects/damai_app/entry/src/main/ets/pages/Index.ets",
                }
            ],
            "shared_components": [],
            "public_interfaces": [],
            "state_management": {
                "store_name": "AppStore",
                "file_path": "/projects/damai_app/entry/src/main/ets/common/store/AppStore.ets",
                "responsibilities": "管理全局共享状态",
                "exposed_state": ["selectedCity"],
                "exposed_actions": ["setSelectedCity"],
            },
            "page_tasks": [
                {
                    "page_name": "Index",
                    "route": "pages/Index",
                    "page_file": "/projects/damai_app/entry/src/main/ets/pages/Index.ets",
                    "component_files": [],
                    "allowed_write_paths": ["/projects/damai_app/entry/src/main/ets/pages/Index.ets"],
                    "shared_dependencies": [],
                    "responsibilities": "首页",
                    "primary_actions": ["open_detail"],
                }
            ],
        }

        with (
            unittest.mock.patch("tools.routing_tools.invoke_with_tool") as invoke_with_tool,
            unittest.mock.patch("tools.routing_tools.extract_tool_call_args") as extract_tool_call_args,
        ):
            invoke_with_tool.return_value = llm_response
            extract_tool_call_args.return_value = expected

            result = invoke_coder_skeleton_planner(
                architect_payload={
                    "project_name": "damai_app",
                    "app_display_name": "大麦",
                    "pages": [{"name": "Index", "responsibilities": "首页"}],
                },
                task_type="implementation",
            )

        self.assertEqual(result["project_name"], "damai_app")

    def test_invoke_coder_skeleton_planner_validates_required_fields_immediately(self) -> None:
        from tools.routing_tools import invoke_coder_skeleton_planner

        llm_response = Mock()
        incomplete = {
            "project_name": "damai_app",
            "app_display_name": "大麦",
            "route_table": [],
            "shared_components": [],
            "public_interfaces": [],
            "page_tasks": [],
        }

        with (
            unittest.mock.patch("tools.routing_tools.invoke_with_tool") as invoke_with_tool,
            unittest.mock.patch("tools.routing_tools.extract_tool_call_args") as extract_tool_call_args,
        ):
            invoke_with_tool.return_value = llm_response
            extract_tool_call_args.return_value = incomplete

            with self.assertRaisesRegex(ValueError, "missing state_management"):
                invoke_coder_skeleton_planner(
                    architect_payload={
                        "project_name": "damai_app",
                        "app_display_name": "大麦",
                        "pages": [{"name": "Index", "responsibilities": "首页"}],
                    },
                    task_type="implementation",
                )

    def test_invoke_coder_skeleton_planner_loads_nested_state_management_json(self) -> None:
        from tools.routing_tools import invoke_coder_skeleton_planner

        llm_response = Mock()
        payload = {
            "project_name": "damai_app",
            "app_display_name": "大麦",
            "route_table": [],
            "shared_data_models": [],
            "shared_components": [],
            "public_interfaces": [],
            "state_management": json.dumps(
                {
                    "store_name": "AppStore",
                    "file_path": "/projects/damai_app/entry/src/main/ets/common/store/AppStore.ets",
                    "responsibilities": "管理全局共享状态",
                    "exposed_state": ["city"],
                    "exposed_actions": ["setCity"],
                },
                ensure_ascii=False,
            ),
            "page_tasks": [],
        }

        with (
            unittest.mock.patch("tools.routing_tools.invoke_with_tool") as invoke_with_tool,
            unittest.mock.patch("tools.routing_tools.extract_tool_call_args") as extract_tool_call_args,
        ):
            invoke_with_tool.return_value = llm_response
            extract_tool_call_args.return_value = payload

            result = invoke_coder_skeleton_planner(
                architect_payload={
                    "project_name": "damai_app",
                    "app_display_name": "大麦",
                    "pages": [{"name": "Index", "responsibilities": "首页"}],
                },
                task_type="implementation",
            )

        self.assertIsInstance(result["state_management"], dict)
        self.assertEqual(result["state_management"]["store_name"], "AppStore")

    def test_invoke_coder_skeleton_planner_normalizes_relative_project_paths(self) -> None:
        from tools.routing_tools import invoke_coder_skeleton_planner

        llm_response = Mock()
        payload = {
            "project_name": "damai_app",
            "app_display_name": "大麦",
            "route_table": [
                {
                    "page_name": "Index",
                    "route": "pages/Index",
                    "page_file": "entry/src/main/ets/pages/Index.ets",
                }
            ],
            "shared_data_models": [],
            "shared_components": [
                {
                    "name": "BottomNavBar",
                    "file_path": "entry/src/main/ets/common/components/BottomNavBar.ets",
                    "description": "底部导航栏",
                }
            ],
            "public_interfaces": [
                {
                    "name": "NavigationService",
                    "file_path": "entry/src/main/ets/common/interfaces/NavigationService.ets",
                    "description": "导航接口",
                }
            ],
            "state_management": json.dumps(
                {
                    "store_name": "AppStore",
                    "file_path": "entry/src/main/ets/common/store/AppStore.ets",
                    "responsibilities": "管理全局共享状态",
                    "exposed_state": ["city"],
                    "exposed_actions": ["setCity"],
                },
                ensure_ascii=False,
            ),
            "page_tasks": [
                {
                    "page_name": "Index",
                    "route": "pages/Index",
                    "page_file": "entry/src/main/ets/pages/Index.ets",
                    "component_files": ["entry/src/main/ets/pages/components/IndexHeader.ets"],
                    "allowed_write_paths": [
                        "entry/src/main/ets/pages/Index.ets",
                        "entry/src/main/ets/pages/components/IndexHeader.ets",
                    ],
                    "shared_dependencies": ["BottomNavBar", "AppStore"],
                    "responsibilities": "首页",
                    "primary_actions": ["open_detail"],
                }
            ],
        }

        with (
            unittest.mock.patch("tools.routing_tools.invoke_with_tool") as invoke_with_tool,
            unittest.mock.patch("tools.routing_tools.extract_tool_call_args") as extract_tool_call_args,
        ):
            invoke_with_tool.return_value = llm_response
            extract_tool_call_args.return_value = payload

            result = invoke_coder_skeleton_planner(
                architect_payload={
                    "project_name": "damai_app",
                    "app_display_name": "大麦",
                    "pages": [{"name": "Index", "responsibilities": "首页"}],
                },
                task_type="implementation",
            )

        self.assertEqual(
            result["route_table"][0]["page_file"],
            "/projects/damai_app/entry/src/main/ets/pages/Index.ets",
        )
        self.assertEqual(
            result["shared_components"][0]["file_path"],
            "/projects/damai_app/entry/src/main/ets/common/components/BottomNavBar.ets",
        )
        self.assertEqual(
            result["state_management"]["file_path"],
            "/projects/damai_app/entry/src/main/ets/common/store/AppStore.ets",
        )
        self.assertEqual(
            result["page_tasks"][0]["allowed_write_paths"][0],
            "/projects/damai_app/entry/src/main/ets/pages/Index.ets",
        )


if __name__ == "__main__":
    unittest.main()
