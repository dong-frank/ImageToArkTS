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
        "Run a three-stage architecture pipeline. "
        "Stage 1 extracts per-image observation drafts and should preserve page identity, visible page frame, visible UI structure, "
        "interaction clues, navigation clues, merge clues, subpage clues, overlay clues, state clues, and lightweight visual semantics, "
        "while staying faithful to screenshot facts and avoiding fabricated unseen structure. "
        "Stage 2 merges related observation drafts into the final page set, including standalone pages, same-page state variants, and overlays. "
        "Stage 2 may incrementally persist finalized per-page artifacts before writing the final merge index. "
        "Final page files are canonical stage2 outputs and must be saved before the final merge index is written; "
        "the final merge index save is for merge-summary persistence and consistency validation, not for rewriting canonical page files. "
        "Stage 2 should preserve implementation-useful page structure and interaction clues without finalizing global navigation. "
        "Stage 3 infers page hierarchy and navigation relations from merged page evidence, validates global consistency, determines the entry page, "
        "and saves the canonical navigation design file. "
        "The architecture pipeline is artifact-aware: when valid canonical artifacts for a later resume point already exist, "
        "earlier stages should not be rerun unnecessarily. "
        "Canonical persisted architecture artifacts must be written through dedicated save/materialization tools rather than arbitrary freeform file writes."
    ),
    owned_task_types=["architecture"],
    required_inputs=[
        "/user_input/user_input_metadata.json",
    ],
    primary_outputs=[
        "/designs/page_drafts/page_draft_{n}.json",
        "/designs/page_drafts_index.json",
        "/designs/pages/{page_id}.json",
        "/designs/page_merge_index.json",
        "/designs/navigation_design.json",
    ],
    structured_output_schema=None,
)


CODER_DEFINITION = SubagentDefinition(
    name="coder",
    description=(
        "Run the staged coding pipeline from structured design artifacts to a final integration report. "
        "The coding pipeline consists of: "
        "(1) a skeleton/planning stage that bootstraps the project and materializes a canonical /designs/coder_page_tasks.json bundle, "
        "(2) a page implementation stage that dispatches page workers from normalized tasks, and "
        "(3) an integration stage that resolves global imports, routing, dependencies, and compile issues. "
        "Architect page files are the source of truth for per-page UI structure and implementation semantics. "
        "The canonical global navigation source of truth is /designs/navigation_design.json. "
        "Page files may contain local navigation clues or interaction hints, but cross-page navigation wiring must follow the navigation design file when the two differ. "
        "Canonical coder artifacts should be reused only when validation of the persisted artifacts passes. "
        "The canonical task schema uses normalized tasks rather than legacy page_tasks. "
        "Shared navigation must not be inferred solely from page count; shared navigation dependencies must remain explicit in canonical task artifacts. "
        "Canonical persisted coder artifacts must be written through dedicated tools rather than arbitrary freeform file writes."
    ),
    owned_task_types=["implementation", "fix_from_test"],
    required_inputs=[
        "/designs/pages/{page_id}.json",
        "/designs/navigation_design.json",
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
    description=(
        "Validate compiled HarmonyOS projects and produce tester reports. "
        "Architect outputs provide structured page semantics, canonical navigation intent, and coarse implementation context. "
        "Page files should not be assumed to be legacy deep UI trees, and global navigation should be interpreted from /designs/navigation_design.json. "
        "If architecture artifacts are incomplete, inconsistent, or missing required canonical navigation context, validation may require human guidance."
    ),
    owned_task_types=["validation"],
    required_inputs=[
        "/designs/pages/{page_id}.json",
        "/designs/navigation_design.json",
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
        "/designs/pages/{page_id}.json",
        "/designs/page_merge_index.json",
        "/designs/navigation_design.json",
    ],
    done_criteria=[
        "before running any architect stage, inspect canonical architect artifacts and resume from the latest valid completed stage when possible",
        "do not rerun stage 1 when valid stage 1 artifacts already exist and later stages can resume from them",
        "do not rerun stage 2 when valid final page artifacts already exist and only stage 3 remains incomplete",
        "stage 1: extract per-image observation drafts and save /designs/page_drafts/page_draft_{n}.json and /designs/page_drafts_index.json through dedicated save tools",
        "stage 1: preserve page identity, visible page frame, visible UI structure, interaction clues, navigation clues, merge clues, subpage clues, overlay clues, and state clues",
        "stage 1: preserve lightweight visual semantics useful for downstream implementation, such as page-level tone, emphasis, coarse block style, layout pattern, active-state appearance, and visual focus",
        "stage 1: stay faithful to screenshot facts and avoid fabricating unseen or unsupported deep structure",
        "stage 2: read /designs/page_drafts_index.json first to make merge decisions without loading all full drafts at once",
        "stage 2: call read_page_draft only for drafts that need deeper inspection, do not load all drafts at once",
        "stage 2: determine the final page set by distinguishing same-page drafts, state variants, overlays, and standalone pages",
        "stage 2: when a final page boundary becomes stable, it may be incrementally persisted to /designs/pages/{page_id}.json through a dedicated save tool instead of waiting for all pages to finish",
        "stage 2: incrementally saved page artifacts must remain consistent with the final canonical page set",
        "stage 2: canonical stage2 page files must be saved before the final merge index is written",
        "stage 2: the final merge index save must not be treated as the canonical writer for page files and must not be relied on to rewrite or upgrade page artifacts",
        "stage 2: if a page changes after an earlier save, the updated page must be re-saved through the dedicated page save tool before the final merge index is written",
        "stage 2: after final page determination, save the canonical merge index to /designs/page_merge_index.json through a dedicated save tool before navigation finalization",
        "stage 2: the final merge index save is for merge-summary persistence and consistency validation against persisted page artifacts",
        "stage 2: preserve implementation-useful page-level and block-level visual hints when they remain supported by screenshot evidence",
        "stage 2: preserve navigation clues inside pages when useful, but do not finalize global page navigation relations in this stage",
        "stage 3: read /designs/page_merge_index.json first and only read page files on demand",
        "stage 3: validate actual persisted stage 2 page files, not only the presence of the merge index",
        "stage 3: infer page hierarchy and navigation relations from merged page evidence",
        "stage 3: determine the entry page from merged page evidence and global structure",
        "stage 3: infer explicit navigate actions only when merged page evidence strongly supports the relation",
        "stage 3: save canonical global navigation output to /designs/navigation_design.json through a dedicated save tool",
        "stage 3: ensure navigation output is consistent with the actual persisted per-page files and page merge index",
        "stage 3: write global validation and navigation inference results into canonical architecture outputs",
    ],
    fallback=[
        FallbackRule(condition="task mismatch", action="wrong_agent"),
        FallbackRule(
            condition="critical pipeline execution failure prevents writing minimal valid outputs",
            action="blocked",
        ),
    ],
)


def build_coder_dispatch_contract(
    task_type: Literal["implementation", "fix_from_test"]
) -> DispatchContract:
    if task_type == "fix_from_test":
        return DispatchContract(
            task_type="fix_from_test",
            trigger="tester_report_fail",
            inputs=[
                "/designs/pages/{page_id}.json",
                "/designs/navigation_design.json",
                "/logs/tester/latest_tester_report.json",
                "/designs/coder_page_tasks.json",
            ],
            required_outputs=[
                "/logs/coder/page_worker_results.json",
                "/logs/coder/integration_report.json",
            ],
            done_criteria=[
                "read per-page architecture from /designs/pages/{page_id}.json",
                "read canonical global navigation from /designs/navigation_design.json",
                "treat architect page files as structured page semantics that may contain coarse frame blocks, interactions, child pages, overlays, visual_style_hints, implementation_hints, and block-level layout/style hints rather than legacy deep UI trees",
                "use /designs/navigation_design.json as the source of truth for cross-page navigation wiring and route relations",
                "reuse existing skeleton stage artifacts only when canonical /designs/coder_page_tasks.json validation passes",
                "if canonical skeleton artifacts are missing or invalid, regenerate normalized skeleton artifacts before dispatching page implementation work",
                "canonical /designs/coder_page_tasks.json must include project_name and normalized tasks",
                "normalized tasks are the canonical task schema; do not rely on legacy page_tasks as the execution contract",
                "shared navigation scaffold must not be created solely because there are multiple pages",
                "page-level shared_dependencies must remain explicit in canonical task artifacts",
                "reuse existing page worker results only when canonical artifact validation passes; otherwise rerun the necessary page implementation work",
                "run page implementation stage on impacted pages or fall back to all page tasks when impact is unclear",
                "page implementation stage must dispatch workers from normalized tasks rather than relying on legacy page_tasks",
                "run integration stage and save /logs/coder/integration_report.json",
                "address tester failures and fix suggestions",
                "integration stage owns the compile-fix loop and records remaining blockers when compilation fails",
                "save /logs/coder/page_worker_results.json before returning",
            ],
            fallback=[
                FallbackRule(
                    condition="repeated compile blockers do not materially change",
                    action="need_human_guidance",
                ),
                FallbackRule(condition="task mismatch", action="wrong_agent"),
            ],
        )

    return DispatchContract(
        task_type="implementation",
        trigger="architect_design_ready",
        inputs=[
            "/designs/pages/{page_id}.json",
            "/designs/navigation_design.json",
        ],
        required_outputs=[
            "/designs/coder_page_tasks.json",
            "/logs/coder/page_worker_results.json",
            "/logs/coder/integration_report.json",
        ],
        done_criteria=[
            "read per-page architecture from /designs/pages/{page_id}.json",
            "read canonical global navigation from /designs/navigation_design.json",
            "treat architect page files as structured page semantics that may contain coarse frame blocks, interactions, child pages, overlays, visual_style_hints, implementation_hints, and block-level layout/style hints rather than legacy deep UI trees",
            "use /designs/navigation_design.json as the source of truth for cross-page navigation wiring and route relations",
            "treat navigation hints inside page files as supplemental context only when they do not conflict with /designs/navigation_design.json",
            "reuse canonical coder artifacts only when artifact validation passes",
            "skeleton stage owns project bootstrap, page registration, and page-task planning",
            "skeleton stage must materialize canonical /designs/coder_page_tasks.json through dedicated tools before page implementation begins",
            "/designs/coder_page_tasks.json must include project_name and normalized tasks",
            "normalized tasks are the canonical task schema; do not rely on legacy page_tasks as the execution contract",
            "shared navigation scaffold must not be created solely because there are multiple pages",
            "page-level shared_dependencies must remain explicit in canonical task artifacts",
            "page implementation stage dispatches page workers from /designs/coder_page_tasks.json using normalized tasks rather than relying on legacy page_tasks",
            "integration stage resolves imports, dependencies, interface mismatches, and owns the compile-fix loop",
            "save /logs/coder/page_worker_results.json and /logs/coder/integration_report.json before returning",
        ],
        fallback=[
            FallbackRule(
                condition="repeated compile blockers do not materially change",
                action="need_human_guidance",
            ),
            FallbackRule(condition="task mismatch", action="wrong_agent"),
        ],
    )


TESTER_DISPATCH_CONTRACT = DispatchContract(
    task_type="validation",
    trigger="compiled_project_ready",
    inputs=[
        "/user_input/user_input_metadata.json",
        "/designs/pages/{page_id}.json",
        "/designs/navigation_design.json",
        "/projects",
    ],
    required_outputs=[
        "/user_input/description.md",
        "/logs/tester/latest_tester_report.json",
    ],
    done_criteria=[
        "request or create /user_input/description.md before building the functional checklist",
        "read page structure from /designs/pages/{page_id}.json when needed for validation context",
        "read canonical global navigation from /designs/navigation_design.json when validating cross-page behavior",
        "treat architect page files as structured page semantics and coarse implementation context, not as a guaranteed legacy deep UI tree",
        "save tester report to /logs/tester/latest_tester_report.json",
        "include PASS or FAIL verdict and fix suggestions",
        "use metadata file to discover uploaded reference asset file paths before reading asset files",
    ],
    fallback=[
        FallbackRule(
            condition="environment or inputs are missing",
            action="need_human_guidance",
        ),
        FallbackRule(
            condition="architecture artifacts are incomplete or inconsistent for validation",
            action="need_human_guidance",
        ),
        FallbackRule(condition="task mismatch", action="wrong_agent"),
    ],
)