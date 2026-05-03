from __future__ import annotations

from functools import lru_cache
from typing import Any

from deepagents import create_deep_agent

from contracts.agent_contracts import TESTER_DEFINITION
from models import architect_model, base_model, code_model
from tools.architect_tools import (
    read_page_draft,
    read_page_drafts_index,
    read_page_file,
    read_page_merge_index,
    save_merged_page,
    save_navigation_design,
    save_page_draft,
    save_page_drafts_index,
    save_page_merge_result,
)
from tools.coder_tools import materialize_coder_skeleton_artifacts
from tools.human_guidance import request_human_guidance
from tools.json_tools import validate_json_syntax
from tools.project_tools import (
    compile_project,
    create_project,
)
from tools.tester_tools import TESTER_TOOLS
from utils.checkpointing import get_checkpointer
from utils.session_backend import backend_factory
from utils.utils import load_prompt

# ---------------------------------------------------------------------------
# Architect tool groups
# ---------------------------------------------------------------------------

ARCHITECT_OBSERVATION_EXTRACTOR_TOOLS = [
    save_page_draft,
    save_page_drafts_index,
    validate_json_syntax,
]

ARCHITECT_PAGE_MERGER_TOOLS = [
    read_page_drafts_index,
    read_page_draft,
    save_merged_page,
    save_page_merge_result,
    validate_json_syntax,
]

ARCHITECT_NAVIGATION_PLANNER_TOOLS = [
    read_page_merge_index,
    read_page_file,
    save_navigation_design,
    validate_json_syntax,
]

# ---------------------------------------------------------------------------
# Coder / Tester tool groups
# ---------------------------------------------------------------------------

# Note:
# deepagent injects default filesystem tools for coder workers at runtime
# (for example read/write/edit/list/glob capabilities). The tool lists below
# only include explicitly-registered extra tools needed by each worker.

CODER_SKELETON_WORKER_TOOLS = [
    create_project,
    materialize_coder_skeleton_artifacts,
    validate_json_syntax,
    request_human_guidance,
]

CODER_PAGE_WORKER_TOOLS = [
    validate_json_syntax,
    request_human_guidance,
]

CODER_INTEGRATION_WORKER_TOOLS = [
    compile_project,
    validate_json_syntax,
    request_human_guidance,
]

TESTER_SUBAGENT_TOOLS = [
    *TESTER_TOOLS,
    validate_json_syntax,
    request_human_guidance,
]

# ---------------------------------------------------------------------------
# Architect specs
# ---------------------------------------------------------------------------

ARCHITECT_OBSERVATION_EXTRACTOR_SPEC: dict[str, Any] = {
    "name": "architect_observation_extractor",
    "description": (
        "Extract single-image observation facts and persist stage1 observation drafts "
        "without doing cross-image merge or global navigation inference. "
        "Stage1 should preserve page identity, visible page frame, visible UI structure, "
        "interaction clues, navigation clues, merge clues, subpage clues, overlay clues, "
        "state clues, and lightweight visual semantics useful for downstream implementation, "
        "while staying faithful to screenshot facts and avoiding fabricated unseen structure."
    ),
    "model": base_model,
    "system_prompt": load_prompt("architect_draft_extractor_system_prompt.md"),
    "tools": ARCHITECT_OBSERVATION_EXTRACTOR_TOOLS,
}

ARCHITECT_PAGE_MERGER_SPEC: dict[str, Any] = {
    "name": "architect_page_merger",
    "description": (
        "Read stage1 observation drafts and merge related screenshots into the final page set. "
        "Stage2 should distinguish same-page drafts, state variants, overlays, and standalone pages, "
        "incrementally persist stable, implementation-useful final page artifacts for downstream coding, "
        "and write the final merge index after page files have been finalized. "
        "Preserve merged page structure, ui_tree, interaction clues, state variants, overlays, "
        "and high-level implementation/visual hints, but do not finalize global navigation relations in this stage."
    ),
    "model": code_model,
    "system_prompt": load_prompt("architect_page_merger_system_prompt.md"),
    "tools": ARCHITECT_PAGE_MERGER_TOOLS,
}

ARCHITECT_NAVIGATION_PLANNER_SPEC: dict[str, Any] = {
    "name": "architect_navigation_planner",
    "description": (
        "Read stage2 final page artifacts, infer page hierarchy and navigation relations, "
        "determine entry page, validate global consistency, and persist a navigation-only design artifact. "
        "Do not rewrite or downgrade stage2 page files. "
        "Stage3 should only output navigation and hierarchy results based on existing page artifacts."
    ),
    "model": code_model,
    "system_prompt": load_prompt("architect_navigation_planner_system_prompt.md"),
    "tools": ARCHITECT_NAVIGATION_PLANNER_TOOLS,
}

ARCHITECT_DRAFT_EXTRACTOR_TOOLS = ARCHITECT_OBSERVATION_EXTRACTOR_TOOLS
ARCHITECT_DRAFT_EXTRACTOR_SPEC = ARCHITECT_OBSERVATION_EXTRACTOR_SPEC

# Backward-compatible alias only.
# Note: this points to the stage3 planner, not to a full multi-stage architect orchestrator.
ARCHITECT_SUBAGENT_SPEC = ARCHITECT_NAVIGATION_PLANNER_SPEC

# ---------------------------------------------------------------------------
# Coder specs
# ---------------------------------------------------------------------------

CODER_ORCHESTRATOR_SPEC: dict[str, Any] = {
    "name": "coder_orchestrator",
    "description": (
        "Coordinate skeleton, page worker, and integration stages for coding tasks "
        "using architect outputs as the source of truth. "
        "Architect page files may provide merged ui_tree, frame blocks, interactions, navigation intent, "
        "page-level visual_style_hints, implementation_hints, and block-level layout/style hints."
    ),
    "model": code_model,
    "system_prompt": load_prompt("coder_orchestrator_system_prompt.md"),
    # Actual tool set is injected lazily in _build_coder_orchestrator().
    "tools": [],
}

CODER_SKELETON_WORKER_SPEC: dict[str, Any] = {
    "name": "coder_skeleton_worker",
    "description": (
        "Plan shared project skeleton and page tasks from final architect outputs. "
        "Architect pages may contain merged ui_tree, frame blocks, interactions, child-page relations, "
        "visual_style_hints, implementation_hints, and block-level style/layout hints."
    ),
    "model": code_model,
    "system_prompt": load_prompt("coder_skeleton_system_prompt.md"),
    "skills": ["/skills"],
    "tools": CODER_SKELETON_WORKER_TOOLS,
}

CODER_PAGE_WORKER_SPEC: dict[str, Any] = {
    "name": "coder_page_worker",
    "description": (
        "Implement one page and its page-local components inside assigned file boundaries. "
        "Use architect page ui_tree, semantics, interactions, and visual/style hints instead of assuming a fabricated legacy deep UI tree."
    ),
    "model": code_model,
    "system_prompt": load_prompt("coder_page_system_prompt.md"),
    "skills": ["/skills"],
    "tools": CODER_PAGE_WORKER_TOOLS,
}

CODER_INTEGRATION_WORKER_SPEC: dict[str, Any] = {
    "name": "coder_integration_worker",
    "description": (
        "Integrate page results, resolve shared issues, and support compile closure "
        "while preserving page identity, navigation intent, visible structure, ui_tree, and coarse visual semantics."
    ),
    "model": code_model,
    "system_prompt": load_prompt("coder_integration_system_prompt.md"),
    "skills": ["/skills"],
    "tools": CODER_INTEGRATION_WORKER_TOOLS,
}

# ---------------------------------------------------------------------------
# Tester spec
# ---------------------------------------------------------------------------

TESTER_SUBAGENT_SPEC: dict[str, Any] = {
    "name": TESTER_DEFINITION.name,
    "description": TESTER_DEFINITION.description,
    "model": architect_model,
    "system_prompt": load_prompt("tester_system_prompt.md"),
    "tools": TESTER_SUBAGENT_TOOLS,
}

# ---------------------------------------------------------------------------
# Registry
# ---------------------------------------------------------------------------

SUBAGENT_SPECS = [
    ARCHITECT_OBSERVATION_EXTRACTOR_SPEC,
    ARCHITECT_PAGE_MERGER_SPEC,
    ARCHITECT_NAVIGATION_PLANNER_SPEC,
    CODER_ORCHESTRATOR_SPEC,
    CODER_SKELETON_WORKER_SPEC,
    CODER_PAGE_WORKER_SPEC,
    CODER_INTEGRATION_WORKER_SPEC,
    TESTER_SUBAGENT_SPEC,
]

# ---------------------------------------------------------------------------
# Builders
# ---------------------------------------------------------------------------


def _build_subagent(spec: dict[str, Any]):
    """Build one deep subagent from a spec dictionary."""
    return create_deep_agent(
        model=spec["model"],
        system_prompt=spec["system_prompt"],
        tools=spec["tools"],
        skills=spec.get("skills"),
        backend=backend_factory,
        #checkpointer=get_checkpointer(),
        checkpointer=None,
        name=spec["name"],
    )


def _build_architect_observation_extractor():
    """Build the stage1 architect observation extractor subagent."""
    return _build_subagent(ARCHITECT_OBSERVATION_EXTRACTOR_SPEC)


def _build_architect_page_merger():
    """Build the stage2 architect page merger subagent."""
    return _build_subagent(ARCHITECT_PAGE_MERGER_SPEC)


def _build_architect_navigation_planner():
    """Build the stage3 architect navigation planner subagent."""
    return _build_subagent(ARCHITECT_NAVIGATION_PLANNER_SPEC)


# ---------------------------------------------------------------------------
# Cached getters
# ---------------------------------------------------------------------------


@lru_cache(maxsize=1)
def get_architect_observation_extractor():
    """Return the cached stage1 architect observation extractor."""
    return _build_architect_observation_extractor()


@lru_cache(maxsize=1)
def get_architect_page_merger():
    """Return the cached stage2 architect page merger."""
    return _build_architect_page_merger()


@lru_cache(maxsize=1)
def get_architect_navigation_planner():
    """Return the cached stage3 architect navigation planner."""
    return _build_architect_navigation_planner()


@lru_cache(maxsize=1)
def get_architect_draft_extractor():
    """Backward-compatible alias for the stage1 architect observation extractor."""
    return _build_architect_observation_extractor()


@lru_cache(maxsize=1)
def get_architect_agent():
    """Backward-compatible alias for the stage3 architect navigation planner only."""
    return _build_architect_navigation_planner()


@lru_cache(maxsize=1)
def get_coder_skeleton_worker():
    """Return the cached coder skeleton worker."""
    return _build_subagent(CODER_SKELETON_WORKER_SPEC)


def _build_coder_orchestrator():
    """Build the coder orchestrator with routing tools injected lazily."""
    from tools.routing_tools import CODER_ORCHESTRATOR_TOOLS as ROUTING_CODER_ORCHESTRATOR_TOOLS

    return create_deep_agent(
        model=CODER_ORCHESTRATOR_SPEC["model"],
        system_prompt=CODER_ORCHESTRATOR_SPEC["system_prompt"],
        tools=[
            *ROUTING_CODER_ORCHESTRATOR_TOOLS,
            validate_json_syntax,
            request_human_guidance,
        ],
        backend=backend_factory,
        checkpointer=get_checkpointer(),
        name=CODER_ORCHESTRATOR_SPEC["name"],
    )


@lru_cache(maxsize=1)
def get_coder_orchestrator():
    """Return the cached coder orchestrator."""
    return _build_coder_orchestrator()


def build_coder_page_worker():
    """Build a non-cached coder page worker instance."""
    return _build_subagent(CODER_PAGE_WORKER_SPEC)


@lru_cache(maxsize=1)
def get_coder_integration_worker():
    """Return the cached coder integration worker."""
    return _build_subagent(CODER_INTEGRATION_WORKER_SPEC)


@lru_cache(maxsize=1)
def get_tester_agent():
    """Return the cached tester subagent."""
    return _build_subagent(TESTER_SUBAGENT_SPEC)


# ---------------------------------------------------------------------------
# Cache reset
# ---------------------------------------------------------------------------


def clear_subagent_caches():
    """
    Clear cached singleton subagents.

    Useful after changing:
    - tool registrations
    - prompts
    - models
    """
    get_architect_observation_extractor.cache_clear()
    get_architect_page_merger.cache_clear()
    get_architect_navigation_planner.cache_clear()
    get_architect_draft_extractor.cache_clear()
    get_architect_agent.cache_clear()
    get_coder_skeleton_worker.cache_clear()
    get_coder_orchestrator.cache_clear()
    get_coder_integration_worker.cache_clear()
    get_tester_agent.cache_clear()