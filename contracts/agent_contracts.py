from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field

SubagentName = Literal["architect", "coder", "tester"]
TaskType = Literal["architecture", "implementation", "fix_from_test", "validation"]
CompletionStatus = Literal["done", "wrong_agent", "blocked", "need_human_guidance"]
NextRecommendedAgent = Literal["architect", "coder", "tester", "orchestrator", "human"]


class FallbackRule(BaseModel):
    condition: str = Field(..., description="Condition that triggers fallback handling.")
    action: CompletionStatus = Field(..., description="Expected fallback action token.")

    def render(self) -> str:
        return f"- if {self.condition} => {self.action}"


class DispatchContract(BaseModel):
    task_type: TaskType
    trigger: str
    inputs: list[str] = Field(default_factory=list)
    required_outputs: list[str] = Field(default_factory=list)
    done_criteria: list[str] = Field(default_factory=list)
    fallback: list[FallbackRule] = Field(default_factory=list)

    def render(self) -> str:
        sections: list[str] = [
            f"task_type: {self.task_type}",
            f"trigger: {self.trigger}",
            "inputs:",
            *[f"- {item}" for item in self.inputs],
            "required_outputs:",
            *[f"- {item}" for item in self.required_outputs],
            "done_criteria:",
            *[f"- {item}" for item in self.done_criteria],
            "fallback:",
            *[item.render() for item in self.fallback],
        ]
        return "\n".join(sections)


class CompletionContract(BaseModel):
    status: CompletionStatus
    produced_artifacts: list[str] = Field(default_factory=list)
    next_recommended_agent: NextRecommendedAgent | None = None
    blocker: str | None = None


class SubagentDefinition(BaseModel):
    name: SubagentName
    description: str
    owned_task_types: list[TaskType] = Field(default_factory=list)
    required_inputs: list[str] = Field(default_factory=list)
    primary_outputs: list[str] = Field(default_factory=list)
    structured_output_schema: str | None = None


ARCHITECT_DEFINITION = SubagentDefinition(
    name="architect",
    description="Read uploaded inputs and produce structured architecture JSON.",
    owned_task_types=["architecture"],
    required_inputs=["/user_input/user_input_metadata.json"],
    primary_outputs=["/designs/architect.json"],
    structured_output_schema="ArchitectOutput",
)


CODER_DEFINITION = SubagentDefinition(
    name="coder",
    description="Implement or repair the HarmonyOS project from structured design artifacts.",
    owned_task_types=["implementation", "fix_from_test"],
    required_inputs=["/designs/architect.json"],
    primary_outputs=["/projects/<project_name>"],
)


TESTER_DEFINITION = SubagentDefinition(
    name="tester",
    description="Validate compiled HarmonyOS projects and produce tester reports.",
    owned_task_types=["validation"],
    required_inputs=["/designs/architect.json", "/user_input/user_input_metadata.json"],
    primary_outputs=["/logs/tester/latest_tester_report.json"],
    structured_output_schema="TesterReportOutput",
)


ARCHITECT_DISPATCH_CONTRACT = DispatchContract(
    task_type="architecture",
    trigger="new_user_input_ready",
    inputs=["/user_input/user_input_metadata.json"],
    required_outputs=["/designs/architect.json"],
    done_criteria=[
        "return valid JSON matching ArchitectOutput",
        "final response contains only architecture JSON content",
        "use metadata file to discover uploaded asset file paths before reading asset files",
    ],
    fallback=[
        FallbackRule(condition="missing critical inputs", action="need_human_guidance"),
        FallbackRule(condition="task mismatch", action="wrong_agent"),
    ],
)


def build_coder_dispatch_contract(task_type: Literal["implementation", "fix_from_test"]) -> DispatchContract:
    if task_type == "fix_from_test":
        return DispatchContract(
            task_type="fix_from_test",
            trigger="tester_report_fail",
            inputs=["/designs/architect.json", "/logs/tester/latest_tester_report.json"],
            required_outputs=["/projects/<project_name>", "compiled project"],
            done_criteria=[
                "address tester failures and fix suggestions",
                "run compile_project(project_name) successfully after changes",
            ],
            fallback=[
                FallbackRule(condition="repeated compile errors do not change", action="need_human_guidance"),
                FallbackRule(condition="task mismatch", action="wrong_agent"),
            ],
        )

    return DispatchContract(
        task_type="implementation",
        trigger="architect_design_ready",
        inputs=["/designs/architect.json"],
        required_outputs=["/projects/<project_name>", "compiled project"],
        done_criteria=[
            "create or update HarmonyOS project from architect design",
            "run compile_project(project_name) successfully at least once",
        ],
        fallback=[
            FallbackRule(condition="repeated compile errors do not change", action="need_human_guidance"),
            FallbackRule(condition="task mismatch", action="wrong_agent"),
        ],
    )


TESTER_DISPATCH_CONTRACT = DispatchContract(
    task_type="validation",
    trigger="compiled_project_ready",
    inputs=[
        "/user_input/user_input_metadata.json",
        "/designs/architect.json",
        "/projects",
    ],
    required_outputs=[
        "/user_input/description.md",
        "/logs/tester/latest_tester_report.json",
    ],
    done_criteria=[
        "request or create /user_input/description.md before building the functional checklist",
        "save tester report to /logs/tester/latest_tester_report.json",
        "include PASS or FAIL verdict and fix suggestions",
        "use metadata file to discover uploaded reference asset file paths before reading asset files",
    ],
    fallback=[
        FallbackRule(condition="environment or inputs are missing", action="need_human_guidance"),
        FallbackRule(condition="task mismatch", action="wrong_agent"),
    ],
)
