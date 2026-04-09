import unittest


class AgentContractsTests(unittest.TestCase):
    def test_architect_contract_renders_stable_sections(self) -> None:
        from contracts.agent_contracts import ARCHITECT_DISPATCH_CONTRACT

        rendered = ARCHITECT_DISPATCH_CONTRACT.render()

        self.assertIn("task_type: architecture", rendered)
        self.assertIn("inputs:", rendered)
        self.assertIn("- /user_input/user_input_metadata.json", rendered)
        self.assertIn("- /designs/architect_image_facts.json", rendered)
        self.assertIn("fallback:", rendered)
        self.assertIn("- if missing critical inputs => need_human_guidance", rendered)

    def test_coder_fix_contract_contains_tester_report(self) -> None:
        from contracts.agent_contracts import build_coder_dispatch_contract

        rendered = build_coder_dispatch_contract("fix_from_test").render()

        self.assertIn("task_type: fix_from_test", rendered)
        self.assertIn("- /logs/tester/latest_tester_report.json", rendered)

    def test_subagent_definitions_capture_owned_task_types(self) -> None:
        from contracts.agent_contracts import ARCHITECT_DEFINITION, CODER_DEFINITION, TESTER_DEFINITION

        self.assertEqual(ARCHITECT_DEFINITION.owned_task_types, ["architecture"])
        self.assertEqual(CODER_DEFINITION.owned_task_types, ["implementation", "fix_from_test"])
        self.assertEqual(TESTER_DEFINITION.owned_task_types, ["validation"])

    def test_architect_definition_has_structured_output_schema_name(self) -> None:
        from contracts.agent_contracts import ARCHITECT_DEFINITION

        self.assertEqual(ARCHITECT_DEFINITION.structured_output_schema, "ArchitectOutput")

    def test_architect_definition_declares_image_facts_artifact(self) -> None:
        from contracts.agent_contracts import ARCHITECT_DEFINITION

        self.assertEqual(ARCHITECT_DEFINITION.primary_outputs, ["ArchitectOutput"])

    def test_architect_subagent_uses_non_vision_final_model(self) -> None:
        from models import base_model
        from subagents import ARCHITECT_SUBAGENT_SPEC

        self.assertIs(ARCHITECT_SUBAGENT_SPEC["model"], base_model)

    def test_architect_subagent_tools_do_not_expose_final_save_tool(self) -> None:
        from subagents import ARCHITECT_SUBAGENT_TOOLS

        tool_names = [tool.name for tool in ARCHITECT_SUBAGENT_TOOLS]
        self.assertEqual(tool_names, ["request_human_guidance"])
        self.assertNotIn("save_architect_design", tool_names)

    def test_tester_definition_has_structured_output_schema_name(self) -> None:
        from contracts.agent_contracts import TESTER_DEFINITION

        self.assertEqual(TESTER_DEFINITION.structured_output_schema, "TesterReportOutput")

    def test_coder_definition_declares_pipeline_artifacts(self) -> None:
        from contracts.agent_contracts import CODER_DEFINITION

        self.assertEqual(
            CODER_DEFINITION.primary_outputs,
            [
                "/designs/coder_skeleton_plan.json",
                "/designs/coder_page_tasks.json",
                "/logs/coder/page_worker_results.json",
                "/logs/coder/integration_report.json",
            ],
        )
        self.assertEqual(CODER_DEFINITION.structured_output_schema, "CoderIntegrationReport")

    def test_coder_worker_specs_are_split_by_stage(self) -> None:
        from subagents import (
            CODER_ORCHESTRATOR_SPEC,
            CODER_INTEGRATION_WORKER_SPEC,
            CODER_PAGE_WORKER_SPEC,
            CODER_SKELETON_WORKER_SPEC,
        )

        self.assertEqual(CODER_ORCHESTRATOR_SPEC["name"], "coder_orchestrator")
        self.assertEqual(CODER_SKELETON_WORKER_SPEC["name"], "coder_skeleton_worker")
        self.assertEqual(CODER_PAGE_WORKER_SPEC["name"], "coder_page_worker")
        self.assertEqual(CODER_INTEGRATION_WORKER_SPEC["name"], "coder_integration_worker")

    def test_coder_skeleton_worker_uses_skills(self) -> None:
        from subagents import CODER_SKELETON_WORKER_SPEC

        self.assertEqual(CODER_SKELETON_WORKER_SPEC.get("skills"), ["/skills"])


if __name__ == "__main__":
    unittest.main()
