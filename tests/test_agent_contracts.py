import unittest


class AgentContractsTests(unittest.TestCase):
    def test_architect_contract_renders_stable_sections(self) -> None:
        from contracts.agent_contracts import ARCHITECT_DISPATCH_CONTRACT

        rendered = ARCHITECT_DISPATCH_CONTRACT.render()

        self.assertIn("task_type: architecture", rendered)
        self.assertIn("inputs:", rendered)
        self.assertIn("- /user_input/user_input_metadata.json", rendered)
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

    def test_tester_definition_has_structured_output_schema_name(self) -> None:
        from contracts.agent_contracts import TESTER_DEFINITION

        self.assertEqual(TESTER_DEFINITION.structured_output_schema, "TesterReportOutput")


if __name__ == "__main__":
    unittest.main()
