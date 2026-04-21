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
    description=(
        "Stage 1: extract per-image UI tree drafts concurrently and save them. "
        "Stage 2: merge drafts, infer navigation, and save final architecture files."
    ),
    owned_task_types=["architecture"],
    required_inputs=[
        "/user_input/user_input_metadata.json",
        "/designs/page_drafts_index.json",          # 阶段二归并决策用
    ],
    primary_outputs=[
        "/designs/page_drafts/page_draft_{n}.json", # 阶段一产出
        "/designs/page_drafts_index.json",          # 阶段一产出
        "/designs/architect_index.json",            # 阶段二产出
        "/designs/pages/{page_id}.json",            # 阶段二产出
    ],
    structured_output_schema=None,
)


CODER_DEFINITION = SubagentDefinition(
    name="coder",
    description="Run the staged coding pipeline from structured design artifacts to an integration report.",
    owned_task_types=["implementation", "fix_from_test"],
    required_inputs=[
        "/designs/architect_index.json",
        "/designs/pages/{page_id}.json",
    ],
    primary_outputs=[
        "/designs/coder_page_tasks.json",
        "/logs/coder/page_worker_results.json",
        "/logs/coder/integration_report.json",
    ],
    structured_output_schema="CoderIntegrationReport",
)


TESTER_DEFINITION = SubagentDefinition(
    name="tester",
    description="Validate compiled HarmonyOS projects and produce tester reports.",
    owned_task_types=["validation"],
    required_inputs=[
        "/designs/architect_index.json",
        "/designs/pages/{page_id}.json",
        "/user_input/user_input_metadata.json",
    ],
    primary_outputs=["/logs/tester/latest_tester_report.json"],
    structured_output_schema="TesterReportOutput",
)


ARCHITECT_DISPATCH_CONTRACT = DispatchContract(
    task_type="architecture",
    trigger="new_user_input_ready",
    inputs=[
        "/user_input/user_input_metadata.json",
    ],
    required_outputs=[
        "/designs/page_drafts/page_draft_{n}.json",
        "/designs/page_drafts_index.json",
        "/designs/architect_index.json",
        "/designs/pages/{page_id}.json",
    ],
    done_criteria=[
        # 阶段一已由代码完成，无需 Agent 执行
        # 阶段二
        "stage 2: read /designs/page_drafts_index.json first to make merge decisions "
        "without loading all full drafts at once",
        "stage 2: call read_page_draft only for drafts that need to be merged, "
        "do not load all drafts at once",
        "stage 2: identify overlays, state variants, and independent pages from "
        "lightweight summaries before reading full drafts",
        "stage 2: infer navigate actions only when cross-image evidence exists",
        # 最终产物
        "save final project index to /designs/architect_index.json",
        "save at least one page design file to /designs/pages/{page_id}.json",
        "ensure index page list matches the actual per-page files",
        "write global validation results into /designs/architect_index.json",
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
            inputs=[
                "/designs/architect_index.json",
                "/designs/pages/{page_id}.json",
                "/logs/tester/latest_tester_report.json",
                "/designs/coder_page_tasks.json",
            ],
            required_outputs=[
                "/logs/coder/page_worker_results.json",
                "/logs/coder/integration_report.json",
            ],
            done_criteria=[
                "reuse existing skeleton stage artifacts when still valid before dispatching page implementation work",
                "read architecture from /designs/architect_index.json and /designs/pages/{page_id}.json",
                "run page implementation stage on impacted pages or fall back to all page tasks when impact is unclear",
                "run integration stage and save /logs/coder/integration_report.json",
                "address tester failures and fix suggestions",
                "integration stage owns the compile-fix loop and records remaining blockers when compilation fails",
            ],
            fallback=[
                FallbackRule(condition="repeated compile errors do not change", action="need_human_guidance"),
                FallbackRule(condition="task mismatch", action="wrong_agent"),
            ],
        )

    return DispatchContract(
        task_type="implementation",
        trigger="architect_design_ready",
        inputs=[
            "/designs/architect_index.json",
            "/designs/pages/{page_id}.json",
        ],
        required_outputs=[
            "/designs/coder_page_tasks.json",
            "/logs/coder/page_worker_results.json",
            "/logs/coder/integration_report.json",
        ],
        done_criteria=[
            "read architecture from /designs/architect_index.json and /designs/pages/{page_id}.json",
            "skeleton stage owns project bootstrap, page registration, and page-task planning",
            "page implementation stage dispatches page workers from /designs/coder_page_tasks.json",
            "integration stage resolves imports, dependencies, interface mismatches, and owns the compile-fix loop",
            "save /designs/coder_page_tasks.json before page implementation begins",
            "save /logs/coder/page_worker_results.json and /logs/coder/integration_report.json before returning",
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
        "/designs/architect_index.json",
        "/designs/pages/{page_id}.json",
        "/projects",
    ],
    required_outputs=[
        "/user_input/description.md",
        "/logs/tester/latest_tester_report.json",
    ],
    done_criteria=[
        "request or create /user_input/description.md before building the functional checklist",
        "read architecture from /designs/architect_index.json and /designs/pages/{page_id}.json when needed for validation context",
        "save tester report to /logs/tester/latest_tester_report.json",
        "include PASS or FAIL verdict and fix suggestions",
        "use metadata file to discover uploaded reference asset file paths before reading asset files",
    ],
    fallback=[
        FallbackRule(condition="environment or inputs are missing", action="need_human_guidance"),
        FallbackRule(condition="task mismatch", action="wrong_agent"),
    ],
)