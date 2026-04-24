import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import Mock


class RoutingToolsContractTests(unittest.TestCase):
    def test_architect_dispatch_contract_is_fixed(self) -> None:
        from tools.routing_tools import build_architect_dispatch_description

        description = build_architect_dispatch_description()

        self.assertIn("task_type: architecture", description)
        self.assertIn("- /user_input/user_input_metadata.json", description)
        self.assertIn("- /designs/architect_image_facts.json", description)
        self.assertIn("- /designs/architect.json", description)
        self.assertNotIn("- /user_input/description.md", description)
        self.assertNotIn("- /user_input_metadata.json", description)
        self.assertNotIn("\n- /user_input\n", f"\n{description}\n")
        self.assertIn("build /designs/architect_image_facts.json", description)
        self.assertIn("save final design to /designs/architect.json", description)
        self.assertNotIn("orchestration persists /designs/architect.json", description)
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
        self.assertIn("- /designs/coder_page_tasks.json", description)
        self.assertIn("- /logs/coder/integration_report.json", description)

    def test_coder_implementation_dispatch_contract_mentions_three_stages(self) -> None:
        from tools.routing_tools import build_coder_dispatch_description

        description = build_coder_dispatch_description(task_type="implementation")

        self.assertIn("- /designs/coder_page_tasks.json", description)
        self.assertIn("- /logs/coder/page_worker_results.json", description)
        self.assertIn("- /logs/coder/integration_report.json", description)
        self.assertIn("skeleton stage", description)
        self.assertIn("page implementation stage", description)
        self.assertIn("integration stage", description)
        self.assertIn("project bootstrap", description)
        self.assertIn("compile-fix loop", description)

    def test_coder_integration_dispatch_description_excludes_architect_input(self) -> None:
        from tools.routing_tools import build_coder_integration_dispatch_description

        description = build_coder_integration_dispatch_description(task_type="implementation")

        self.assertIn("task_type: implementation", description)
        self.assertIn("- /designs/coder_page_tasks.json", description)
        self.assertIn("- /logs/coder/page_worker_results.json", description)
        self.assertIn("compile-fix loop", description)
        self.assertNotIn("/designs/architect.json", description)

    def test_main_tools_use_routing_tools(self) -> None:
        from tools.tool_sets import ORCHESTRATOR_AGENT_TOOLS

        tool_names = [tool.name for tool in ORCHESTRATOR_AGENT_TOOLS]

        self.assertIn("dispatch_architect", tool_names)
        self.assertIn("dispatch_coder", tool_names)
        self.assertIn("dispatch_review_executor", tool_names)
        self.assertIn("dispatch_flow_summary", tool_names)
        self.assertIn("dispatch_visual_review", tool_names)
        self.assertNotIn("dispatch_tester", tool_names)

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
            unittest.mock.patch("tools.routing_tools.get_architect_agent", return_value=Mock()),
            unittest.mock.patch("tools.routing_tools._invoke_subagent") as invoke_subagent,
            unittest.mock.patch("tools.routing_tools.build_architect_image_facts_bundle_payload") as build_facts,
        ):
            invoke_subagent.return_value = {"messages": [Mock(text=json.dumps(structured, ensure_ascii=False))]}
            build_facts.return_value = "status: SUCCESS"

            command = dispatch_architect.func(runtime=runtime)

        build_facts.assert_called_once()
        tool_message = command.update["messages"][0]
        self.assertIn('"project_name": "calculator_app"', tool_message.content)

    def test_dispatch_architect_reads_materialized_inputs_in_runtime_thread_session(self) -> None:
        from tools.routing_tools import dispatch_architect
        from utils.session_context import get_current_session_id, reset_current_session_id, set_current_session_id

        runtime = Mock()
        runtime.tool_call_id = "tool-architect-session"
        runtime.state = {}
        runtime.config = {"configurable": {"thread_id": "session-architect-123"}}

        observed_sessions: list[str] = []
        structured = {"project_name": "demo_app", "app_display_name": "演示", "pages": []}
        outer_token = set_current_session_id("another-session")
        try:
            def _build_facts():
                observed_sessions.append(get_current_session_id())
                return "status: SUCCESS"

            with (
                unittest.mock.patch("tools.routing_tools.build_architect_image_facts_bundle_payload", side_effect=_build_facts),
                unittest.mock.patch("tools.routing_tools.get_architect_agent", return_value=Mock()),
                unittest.mock.patch("tools.routing_tools._invoke_subagent", return_value={"messages": [Mock(text=json.dumps(structured, ensure_ascii=False))]}),
            ):
                dispatch_architect.func(runtime=runtime)
        finally:
            reset_current_session_id(outer_token)

        self.assertEqual(observed_sessions, ["session-architect-123"])

    def test_dispatch_architect_does_not_save_subagent_output(self) -> None:
        from tools.routing_tools import dispatch_architect

        runtime = Mock()
        runtime.tool_call_id = "tool-3"
        runtime.state = {}
        runtime.config = {"configurable": {"thread_id": "session-123"}}

        with (
            unittest.mock.patch("tools.routing_tools.get_architect_agent", return_value=Mock()),
            unittest.mock.patch("tools.routing_tools._invoke_subagent") as invoke_subagent,
            unittest.mock.patch("tools.routing_tools.build_architect_image_facts_bundle_payload") as build_facts,
        ):
            invoke_subagent.return_value = {"messages": [Mock(text="not-json")]}
            build_facts.return_value = "status: SUCCESS"

            command = dispatch_architect.func(runtime=runtime)

        self.assertIn("not-json", command.update["messages"][0].content)

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
        self.assertIn("Read the required input files yourself", prompt)
        self.assertNotIn("Calculator", prompt)
        self.assertNotIn("display and keypad", prompt)

    def test_page_task_prompt_includes_required_skill_brief(self) -> None:
        from tools.routing_tools import _build_page_task_prompt

        prompt = _build_page_task_prompt(
            task_payload={"page_name": "Index", "allowed_write_paths": ["/projects/demo/entry/src/main/ets/pages/Index.ets"]},
            architect_page_payload={"name": "Index"},
            skeleton_payload={"project_name": "demo"},
            task_type="implementation",
        )

        self.assertIn("Read required skills yourself before coding:", prompt)
        self.assertIn("/skills/harmony-coding-guardrails/SKILL.md", prompt)
        self.assertIn("/skills/harmony-next/SKILL.md", prompt)
        self.assertIn("Skill usage is mandatory before code generation", prompt)
        self.assertIn("Execution priority:", prompt)
        self.assertIn("Reconstruct the UI as faithfully as possible", prompt)
        self.assertIn("target_page_name: Index", prompt)
        self.assertIn("/designs/coder_page_tasks.json", prompt)
        self.assertIn("/designs/architect.json", prompt)
        self.assertNotIn("/designs/coder_skeleton_plan.json", prompt)
        self.assertNotIn('/projects/demo/entry/src/main/ets/pages/Index.ets', prompt)

    def test_run_single_page_worker_formats_worker_summary_into_structured_result(self) -> None:
        from tools.routing_tools import _run_single_page_worker

        runtime = Mock()
        runtime.state = {}
        runtime.config = {"configurable": {"thread_id": "session-123"}}

        task_payload = {
            "page_name": "Index",
            "route": "pages/Index",
            "page_file": "/projects/demo/entry/src/main/ets/pages/Index.ets",
            "allowed_write_paths": ["/projects/demo/entry/src/main/ets/pages/Index.ets"],
            "responsibilities": "首页",
        }
        worker_result = {
            "status": "done",
            "page_name": "Index",
            "modified_files": [],
            "exports_added": [],
            "shared_contract_requests": [],
            "blockers": [],
            "summary": "完成首页 UI，实现页面主结构。",
        }

        with (
            unittest.mock.patch("tools.routing_tools.build_coder_page_worker") as build_coder_page_worker,
            unittest.mock.patch("tools.routing_tools._invoke_subagent") as invoke_subagent,
            unittest.mock.patch("tools.routing_tools.invoke_coder_page_result_formatter") as formatter,
            unittest.mock.patch("tools.routing_tools._detect_modified_files") as detect_modified_files,
        ):
            build_coder_page_worker.return_value = Mock()
            invoke_subagent.return_value = {"messages": [Mock(text="页面已完成，修改了 Index.ets")]}
            formatter.return_value = worker_result
            detect_modified_files.return_value = ["/projects/demo/entry/src/main/ets/pages/Index.ets"]

            result = _run_single_page_worker(
                task_payload=task_payload,
                skeleton_payload={"project_name": "demo"},
                architect_payload={"pages": [{"name": "Index"}]},
                runtime=runtime,
                task_type="implementation",
            )

        self.assertEqual(result["status"], "done")
        self.assertEqual(result["modified_files"], [])
        formatter.assert_called_once()
        _, formatter_kwargs = formatter.call_args
        self.assertEqual(formatter_kwargs["modified_files"], ["/projects/demo/entry/src/main/ets/pages/Index.ets"])

    def test_select_page_tasks_accepts_legacy_page_tasks_field(self) -> None:
        from tools.routing_tools import _select_page_tasks

        selected = _select_page_tasks(
            {
                "project_name": "demo",
                "page_tasks": [
                    {
                        "page_name": "Index",
                        "route": "pages/Index",
                    }
                ],
            }
        )

        self.assertEqual(len(selected), 1)
        self.assertEqual(selected[0]["page_name"], "Index")

    def test_integration_prompt_includes_required_skill_brief(self) -> None:
        from tools.routing_tools import _build_integration_prompt

        prompt = _build_integration_prompt(
            task_type="implementation",
            skeleton_payload={"project_name": "demo"},
            page_results_payload={"results": []},
        )

        self.assertIn("Read required skills yourself before fixing:", prompt)
        self.assertIn("/skills/harmony-coding-guardrails/SKILL.md", prompt)
        self.assertIn("/skills/harmony-next/SKILL.md", prompt)
        self.assertIn("Skill usage is mandatory before fixing ArkTS / ArkUI", prompt)
        self.assertIn("Execution priority:", prompt)
        self.assertIn("Preserve and stabilize UI fidelity first", prompt)
        self.assertIn("/designs/coder_page_tasks.json", prompt)
        self.assertIn("/logs/coder/page_worker_results.json", prompt)
        self.assertNotIn("/designs/architect.json", prompt)

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

    def test_dispatch_page_coder_tasks_reads_payloads_in_runtime_thread_session(self) -> None:
        from tools.routing_tools import dispatch_page_coder_tasks
        from utils.session_context import get_current_session_id, reset_current_session_id, set_current_session_id

        runtime = Mock()
        runtime.tool_call_id = "tool-page"
        runtime.state = {}
        runtime.config = {"configurable": {"thread_id": "session-123"}}

        outer_token = set_current_session_id("another-session")
        observed_sessions: list[str] = []
        try:
            def _load_tasks():
                observed_sessions.append(get_current_session_id())
                return {"project_name": "demo", "tasks": [{"page_name": "Index"}]}

            with (
                unittest.mock.patch("tools.routing_tools.load_coder_page_task_bundle_payload", side_effect=_load_tasks),
                unittest.mock.patch("tools.routing_tools.load_architect_design_payload", return_value={"pages": []}),
                unittest.mock.patch("tools.routing_tools.dispatch_page_coders", return_value={"project_name": "demo", "results": []}),
            ):
                dispatch_page_coder_tasks.func(task_type="implementation", runtime=runtime)
        finally:
            reset_current_session_id(outer_token)

        self.assertEqual(observed_sessions, ["session-123"])

    def test_dispatch_page_coder_tasks_uses_tasks_array_from_task_bundle(self) -> None:
        from tools.routing_tools import dispatch_page_coder_tasks

        runtime = Mock()
        runtime.tool_call_id = "tool-page"
        runtime.state = {}
        runtime.config = {"configurable": {"thread_id": "session-123"}}

        task_bundle = {
            "project_name": "demo",
            "tasks": [
                {
                    "page_name": "TaskOnlyPage",
                    "route": "pages/TaskOnlyPage",
                    "page_file": "/projects/demo/entry/src/main/ets/pages/TaskOnlyPage.ets",
                    "allowed_write_paths": ["/projects/demo/entry/src/main/ets/pages/TaskOnlyPage.ets"],
                }
            ],
            "page_tasks": [
                {
                    "page_name": "LegacyPage",
                    "route": "pages/LegacyPage",
                    "page_file": "/projects/demo/entry/src/main/ets/pages/LegacyPage.ets",
                    "allowed_write_paths": ["/projects/demo/entry/src/main/ets/pages/LegacyPage.ets"],
                }
            ],
        }

        with (
            unittest.mock.patch("tools.routing_tools.load_coder_page_task_bundle_payload", return_value=task_bundle),
            unittest.mock.patch("tools.routing_tools.load_architect_design_payload", return_value={"pages": []}),
            unittest.mock.patch("tools.routing_tools.dispatch_page_coders", return_value={"project_name": "demo", "results": []}) as dispatch_page_coders,
        ):
            dispatch_page_coder_tasks.func(task_type="implementation", runtime=runtime)

        _, kwargs = dispatch_page_coders.call_args
        self.assertEqual(kwargs["task_bundle"]["tasks"][0]["page_name"], "TaskOnlyPage")

    def test_dispatch_coder_skeleton_relies_on_worker_owned_bootstrap(self) -> None:
        from tools.routing_tools import dispatch_coder_skeleton

        runtime = Mock()
        runtime.tool_call_id = "tool-skeleton"
        runtime.state = {}
        runtime.config = {"configurable": {"thread_id": "session-123"}}

        skeleton_payload = {
            "project_name": "damai_app",
            "app_display_name": "大麦",
            "page_tasks": [
                {
                    "page_name": "Index",
                    "route": "pages/Index",
                    "page_file": "/projects/damai_app/entry/src/main/ets/pages/Index.ets",
                    "allowed_write_paths": ["/projects/damai_app/entry/src/main/ets/pages/Index.ets"],
                    "responsibilities": "首页",
                }
            ],
        }

        with (
            unittest.mock.patch("tools.routing_tools.load_architect_design_payload") as load_architect_design_payload,
            unittest.mock.patch("tools.routing_tools.run_coder_skeleton_stage") as run_coder_skeleton_stage,
        ):
            load_architect_design_payload.return_value = {"project_name": "damai_app", "app_display_name": "大麦", "pages": []}
            run_coder_skeleton_stage.return_value = (skeleton_payload, "worker created project and registered pages")

            command = dispatch_coder_skeleton.func(task_type="implementation", runtime=runtime)

        self.assertIn('"project_name": "damai_app"', command.update["messages"][0].content)
        self.assertIn('"worker_execution_summary": "worker created project and registered pages"', command.update["messages"][0].content)
        self.assertIn('"skeleton_plan_saved": false', command.update["messages"][0].content)

    def test_run_coder_skeleton_stage_invokes_subagent_then_formats(self) -> None:
        from tools.routing_tools import run_coder_skeleton_stage

        runtime = Mock()
        runtime.state = {}
        runtime.config = {"configurable": {"thread_id": "session-123"}}

        skeleton_payload = {
            "project_name": "damai_app",
            "app_display_name": "大麦",
            "page_tasks": [
                {
                    "page_name": "Index",
                    "route": "pages/Index",
                    "page_file": "/projects/damai_app/entry/src/main/ets/pages/Index.ets",
                    "allowed_write_paths": ["/projects/damai_app/entry/src/main/ets/pages/Index.ets"],
                    "responsibilities": "首页",
                }
            ],
        }

        with (
            unittest.mock.patch("tools.routing_tools.get_coder_skeleton_worker") as get_coder_skeleton_worker,
            unittest.mock.patch("tools.routing_tools._invoke_subagent") as invoke_subagent,
            unittest.mock.patch("tools.routing_tools.invoke_coder_skeleton_result_formatter") as formatter,
        ):
            get_coder_skeleton_worker.return_value = Mock()
            invoke_subagent.return_value = {"messages": [Mock(text="skeleton summary")]}
            formatter.return_value = skeleton_payload

            payload, summary = run_coder_skeleton_stage(
                architect_payload={"project_name": "damai_app", "pages": []},
                task_type="implementation",
                runtime=runtime,
            )

        self.assertEqual(payload["project_name"], "damai_app")
        self.assertEqual(summary, "skeleton summary")
        called_agent = invoke_subagent.call_args.args[0]
        self.assertIs(called_agent, get_coder_skeleton_worker.return_value)
        formatter.assert_called_once()

    def test_run_coder_integration_persists_compile_fix_logs(self) -> None:
        from tools.routing_tools import run_coder_integration

        runtime = Mock()
        runtime.state = {}
        runtime.config = {"configurable": {"thread_id": "session-123"}}

        skeleton_payload = {
            "project_name": "damai_app",
        }
        page_results_payload = {
            "results": [
                {
                    "page_name": "Index",
                    "modified_files": ["/projects/damai_app/entry/src/main/ets/pages/Index.ets"],
                }
            ]
        }
        compile_output = "\n".join(
            [
                "compile_status: SUCCESS",
                "project_name: damai_app",
                "project_path: /projects/damai_app",
                "key_errors:",
                "- none",
                "recent_log_tail:",
                "done",
            ]
        )
        integration_report = {
            "compile_status": "SUCCESS",
            "project_name": "damai_app",
            "project_path": "/projects/damai_app",
            "ready_for_tester": True,
            "fixes_applied": ["fixed imports"],
            "remaining_errors": [],
            "blocker": "none",
            "next_recommended_agent": "tester",
        }
        worker_summary = "\n".join(
            [
                "fixed imports",
                "<<FINAL_COMPILE_OUTPUT>>",
                compile_output,
                "<<END_FINAL_COMPILE_OUTPUT>>",
            ]
        )

        with (
            unittest.mock.patch("tools.routing_tools.get_coder_integration_worker") as get_coder_integration_worker,
            unittest.mock.patch("tools.routing_tools._invoke_subagent") as invoke_subagent,
            unittest.mock.patch("tools.routing_tools.invoke_coder_integration_report_formatter") as formatter,
            unittest.mock.patch("tools.routing_tools.append_coder_compile_fix_attempt") as append_attempt,
            unittest.mock.patch("tools.routing_tools.save_coder_compile_fix_trace_payload") as save_trace,
            unittest.mock.patch("tools.routing_tools.save_coder_integration_report_payload") as save_report,
        ):
            get_coder_integration_worker.return_value = Mock()
            invoke_subagent.return_value = {"messages": [Mock(text=worker_summary)]}
            formatter.return_value = integration_report

            result = run_coder_integration(
                task_type="implementation",
                skeleton_payload=skeleton_payload,
                page_results_payload=page_results_payload,
                runtime=runtime,
            )

        self.assertEqual(result["compile_status"], "SUCCESS")
        invoke_subagent.assert_called_once()
        append_attempt.assert_called_once()
        save_trace.assert_called_once()
        save_report.assert_called_once_with(integration_report)

    def test_run_coder_integration_uses_worker_final_compile_output_after_fix(self) -> None:
        from tools.routing_tools import run_coder_integration

        runtime = Mock()
        runtime.state = {}
        runtime.config = {"configurable": {"thread_id": "session-123"}}

        success_compile = "\n".join(
            [
                "compile_status: SUCCESS",
                "project_name: damai_app",
                "project_path: /projects/damai_app",
                "key_errors:",
                "- none",
                "recent_log_tail:",
                "done",
            ]
        )
        worker_summary = "\n".join(
            [
                "ran compile, fixed missing import, recompiled successfully",
                "<<FINAL_COMPILE_OUTPUT>>",
                success_compile,
                "<<END_FINAL_COMPILE_OUTPUT>>",
            ]
        )

        with (
            unittest.mock.patch("tools.routing_tools.get_coder_integration_worker") as get_coder_integration_worker,
            unittest.mock.patch("tools.routing_tools._invoke_subagent") as invoke_subagent,
            unittest.mock.patch("tools.routing_tools.invoke_coder_integration_report_formatter") as formatter,
            unittest.mock.patch("tools.routing_tools.append_coder_compile_fix_attempt") as append_attempt,
            unittest.mock.patch("tools.routing_tools.save_coder_compile_fix_trace_payload"),
            unittest.mock.patch("tools.routing_tools.save_coder_integration_report_payload"),
        ):
            get_coder_integration_worker.return_value = Mock()
            invoke_subagent.return_value = {"messages": [Mock(text=worker_summary)]}
            formatter.return_value = {
                "compile_status": "SUCCESS",
                "project_name": "damai_app",
                "project_path": "/projects/damai_app",
                "ready_for_tester": True,
                "fixes_applied": ["fixed imports after compile failure"],
                "remaining_errors": [],
                "blocker": "none",
                "next_recommended_agent": "tester",
            }

            run_coder_integration(
                task_type="implementation",
                skeleton_payload={"project_name": "damai_app"},
                page_results_payload={"results": []},
                runtime=runtime,
            )

        invoke_subagent.assert_called_once()
        append_attempt.assert_called_once()

    def test_invoke_coder_skeleton_planner_extracts_tool_args(self) -> None:
        from tools.routing_tools import invoke_coder_skeleton_planner

        llm_response = Mock()
        expected = {
            "project_name": "damai_app",
            "app_display_name": "大麦",
            "page_tasks": [
                {
                    "page_name": "Index",
                    "route": "pages/Index",
                    "page_file": "/projects/damai_app/entry/src/main/ets/pages/Index.ets",
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

    def test_skeleton_planning_prompt_includes_guardrail_skill(self) -> None:
        from tools.routing_tools import build_coder_skeleton_planning_prompt

        prompt = build_coder_skeleton_planning_prompt(
            architect_payload={
                "project_name": "damai_app",
                "app_display_name": "大麦",
                "pages": [{"name": "Index", "responsibilities": "首页"}],
            },
            task_type="implementation",
        )

        self.assertIn("/skills/harmony-coding-guardrails/SKILL.md", prompt)
        self.assertIn("/skills/harmony-next/SKILL.md", prompt)
        self.assertIn("- /designs/coder_page_tasks.json", prompt)
        self.assertIn("- /designs/architect.json", prompt)
        self.assertIn("write /designs/coder_page_tasks.json yourself", prompt)
        self.assertNotIn("materialize_coder_skeleton_artifacts", prompt)
        self.assertNotIn("/logs/coder/page_worker_results.json", prompt)
        self.assertNotIn("/logs/coder/integration_report.json", prompt)
        self.assertNotIn("integration stage", prompt)
        self.assertNotIn('"project_name": "damai_app"', prompt)

    def test_invoke_coder_skeleton_planner_allows_incomplete_page_tasks_without_revalidation(self) -> None:
        from tools.routing_tools import invoke_coder_skeleton_planner

        llm_response = Mock()
        incomplete = {
            "project_name": "damai_app",
            "app_display_name": "大麦",
            "page_tasks": [],
        }

        with (
            unittest.mock.patch("tools.routing_tools.invoke_with_tool") as invoke_with_tool,
            unittest.mock.patch("tools.routing_tools.extract_tool_call_args") as extract_tool_call_args,
        ):
            invoke_with_tool.return_value = llm_response
            extract_tool_call_args.return_value = incomplete

            result = invoke_coder_skeleton_planner(
                architect_payload={
                    "project_name": "damai_app",
                    "app_display_name": "大麦",
                    "pages": [{"name": "Index", "responsibilities": "首页"}],
                },
                task_type="implementation",
            )

        self.assertEqual(result["page_tasks"], [])

    def test_invoke_coder_skeleton_planner_accepts_minimal_page_task_only_payload(self) -> None:
        from tools.routing_tools import invoke_coder_skeleton_planner

        llm_response = Mock()
        payload = {
            "project_name": "damai_app",
            "app_display_name": "大麦",
            "page_tasks": [
                {
                    "page_name": "Index",
                    "route": "pages/Index",
                    "page_file": "/projects/damai_app/entry/src/main/ets/pages/Index.ets",
                    "allowed_write_paths": ["/projects/damai_app/entry/src/main/ets/pages/Index.ets"],
                    "responsibilities": "首页",
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

        self.assertEqual(len(result["page_tasks"]), 1)
        self.assertEqual(result["page_tasks"][0]["page_name"], "Index")

    def test_invoke_coder_skeleton_planner_normalizes_relative_project_paths(self) -> None:
        from tools.routing_tools import invoke_coder_skeleton_planner

        llm_response = Mock()
        payload = {
            "project_name": "damai_app",
            "app_display_name": "大麦",
            "page_tasks": [
                {
                    "page_name": "Index",
                    "route": "pages/Index",
                    "page_file": "entry/src/main/ets/pages/Index.ets",
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
            result["page_tasks"][0]["allowed_write_paths"][0],
            "/projects/damai_app/entry/src/main/ets/pages/Index.ets",
        )

    def test_invoke_coder_skeleton_planner_adds_navigation_dependencies_for_multi_page_app(self) -> None:
        from tools.routing_tools import invoke_coder_skeleton_planner

        llm_response = Mock()
        payload = {
            "project_name": "damai_app",
            "app_display_name": "大麦",
            "page_tasks": [
                {
                    "page_name": "Index",
                    "route": "pages/Index",
                    "page_file": "/projects/damai_app/entry/src/main/ets/pages/Index.ets",
                    "allowed_write_paths": ["/projects/damai_app/entry/src/main/ets/pages/Index.ets"],
                    "shared_dependencies": [],
                    "responsibilities": "首页",
                    "primary_actions": ["open_detail"],
                },
                {
                    "page_name": "Profile",
                    "route": "pages/Profile",
                    "page_file": "/projects/damai_app/entry/src/main/ets/pages/Profile.ets",
                    "allowed_write_paths": ["/projects/damai_app/entry/src/main/ets/pages/Profile.ets"],
                    "shared_dependencies": [],
                    "responsibilities": "我的页面",
                    "primary_actions": ["open_settings"],
                },
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
                    "pages": [{"name": "Index"}, {"name": "Profile"}],
                },
                task_type="implementation",
            )

        for task in result["page_tasks"]:
            self.assertIn("BottomNavBar", task["shared_dependencies"])
            self.assertIn("NavigationService", task["shared_dependencies"])

    def test_invoke_coder_page_result_formatter_accepts_plain_json_text_without_tool_call(self) -> None:
        from tools.routing_tools import invoke_coder_page_result_formatter

        llm_response = Mock()
        llm_response.content = json.dumps(
            {
                "status": "done",
                "page_name": "Index",
                "summary": "implemented page",
            },
            ensure_ascii=False,
        )

        with (
            unittest.mock.patch("tools.routing_tools.invoke_with_tool", return_value=llm_response),
            unittest.mock.patch("tools.routing_tools.extract_tool_call_args", return_value=None),
        ):
            result = invoke_coder_page_result_formatter(
                task_payload={"page_name": "Index"},
                modified_files=["/projects/demo/entry/src/main/ets/pages/Index.ets"],
                agent_summary="implemented page",
            )

        self.assertEqual(result["status"], "done")
        self.assertEqual(result["page_name"], "Index")
        self.assertEqual(
            result["modified_files"],
            ["/projects/demo/entry/src/main/ets/pages/Index.ets"],
        )

    def test_invoke_coder_skeleton_result_formatter_falls_back_without_tool_call(self) -> None:
        from tools.routing_tools import invoke_coder_skeleton_result_formatter

        llm_response = Mock()
        llm_response.content = "plain text summary only"
        fallback_payload = {
            "project_name": "demo_app",
            "app_display_name": "Demo",
            "page_tasks": [
                {
                    "page_name": "Index",
                    "route": "pages/Index",
                    "page_file": "/projects/demo_app/entry/src/main/ets/pages/Index.ets",
                    "allowed_write_paths": ["/projects/demo_app/entry/src/main/ets/pages/Index.ets"],
                    "shared_dependencies": [],
                    "responsibilities": "首页",
                    "primary_actions": [],
                }
            ],
        }

        with (
            unittest.mock.patch("tools.routing_tools.invoke_with_tool", return_value=llm_response),
            unittest.mock.patch("tools.routing_tools.extract_tool_call_args", return_value=None),
            unittest.mock.patch("tools.routing_tools.build_coder_skeleton_seed_from_architect", return_value=fallback_payload),
        ):
            result = invoke_coder_skeleton_result_formatter(
                architect_payload={"pages": []},
                task_type="implementation",
                agent_summary="plain text summary only",
            )

        self.assertEqual(result["project_name"], "demo_app")
        self.assertEqual(len(result["page_tasks"]), 1)

    def test_load_json_dict_file_recovers_embedded_json_object(self) -> None:
        from tools.routing_tools import _load_json_dict_file

        with tempfile.TemporaryDirectory() as tmpdir:
            path = Path(tmpdir) / "payload.json"
            path.write_text(
                'Result summary\n```json\n{"project_name":"demo_app","status":"done"}\n```',
                encoding="utf-8",
            )

            payload = _load_json_dict_file(path)

        self.assertEqual(payload["project_name"], "demo_app")
        self.assertEqual(payload["status"], "done")

    def test_run_coder_pipeline_ignores_invalid_saved_task_bundle_and_rebuilds(self) -> None:
        from tools.routing_tools import run_coder_pipeline

        tasks_path = Mock()
        tasks_path.exists.return_value = True

        skeleton_payload = {
            "project_name": "demo_app",
            "page_tasks": [{"page_name": "Index", "allowed_write_paths": []}],
        }
        page_results = {"project_name": "demo_app", "results": []}
        integration_report = {"project_name": "demo_app", "compile_status": "SUCCESS"}

        with (
            unittest.mock.patch("tools.routing_tools.resolve_workspace_path", return_value=tasks_path),
            unittest.mock.patch("tools.routing_tools.load_architect_design_payload", return_value={"pages": []}),
            unittest.mock.patch(
                "tools.routing_tools.load_coder_page_task_bundle_payload",
                side_effect=ValueError("bad json"),
            ),
            unittest.mock.patch(
                "tools.routing_tools.run_coder_skeleton_stage",
                return_value=(skeleton_payload, "worker summary"),
            ) as run_skeleton,
            unittest.mock.patch(
                "tools.routing_tools.dispatch_page_coders",
                return_value=page_results,
            ) as dispatch_pages,
            unittest.mock.patch(
                "tools.routing_tools.run_coder_integration",
                return_value=integration_report,
            ) as run_integration,
        ):
            result = run_coder_pipeline(task_type="implementation", runtime=Mock())

        self.assertEqual(result, integration_report)
        run_skeleton.assert_called_once()
        dispatch_pages.assert_called_once()
        run_integration.assert_called_once()


if __name__ == "__main__":
    unittest.main()
