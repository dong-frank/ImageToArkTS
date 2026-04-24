from __future__ import annotations

from typing import Dict, List, Literal, Optional

from pydantic import BaseModel, ConfigDict, Field


# ============================================================
# Common base / shared style models
# ============================================================

class ArchitectBaseModel(BaseModel):
    model_config = ConfigDict(extra="forbid")


class VisualStyle(ArchitectBaseModel):
    design_tone: str = Field(..., description="Overall visual tone.")
    primary_color: Optional[str] = Field(None, description="Primary brand color.")
    background_color: Optional[str] = Field(None, description="Main background color.")
    accent_colors: Optional[List[str]] = Field(None, description="Accent color list.")
    typography_notes: Optional[str] = Field(None, description="Typography notes.")
    spacing_notes: Optional[str] = Field(None, description="Spacing / radius / shadow notes.")
    style_tokens: Optional[Dict[str, str]] = Field(
        None,
        description="Global reusable style tokens.",
    )


class UIStyle(BaseModel):
    model_config = ConfigDict(extra="allow")
    background_color: Optional[str] = Field(None, description="Background color.")
    font_color: Optional[str] = Field(None, description="Font color.")
    border_color: Optional[str] = Field(None, description="Border color.")
    border_radius: Optional[str] = Field(None, description="Border radius.")
    font_size: Optional[str] = Field(None, description="Font size.")
    font_weight: Optional[str] = Field(None, description="Font weight.")
    text_align: Optional[Literal["start", "center", "end", "justify"]] = Field(
        None, description="Text alignment."
    )
    padding: Optional[str] = Field(None, description="Padding.")
    margin: Optional[str] = Field(None, description="Margin.")
    gap: Optional[str] = Field(None, description="Gap.")
    width: Optional[str] = Field(None, description="Relative width.")
    height: Optional[str] = Field(None, description="Relative height.")
    opacity: Optional[str] = Field(None, description="Opacity.")
    style_tokens: Optional[Dict[str, str]] = Field(
        None,
        description="Extra style tokens.",
    )
    flex_grow: Optional[str] = Field(None, description="Flex grow.")
    flex_shrink: Optional[str] = Field(None, description="Flex shrink.")
    flex_basis: Optional[str] = Field(None, description="Flex basis.")
    align_self: Optional[str] = Field(None, description="Self alignment.")
    align_items: Optional[str] = Field(None, description="Cross-axis alignment.")
    justify_content: Optional[str] = Field(None, description="Main-axis alignment.")
    border_width: Optional[str] = Field(None, description="Border width.")
    shadow: Optional[str] = Field(None, description="Shadow.")
    overflow: Optional[str] = Field(None, description="Overflow handling.")


# ============================================================
# Common literal types
# ============================================================

PageObservationStatus = Literal["success", "failed"]

BlockRole = Literal[
    "page_root",
    "top_bar",
    "navigation_bar",
    "title_area",
    "header",
    "hero",
    "banner",
    "tab_bar",
    "segment_control",
    "search_area",
    "filter_area",
    "summary_area",
    "content_area",
    "list_area",
    "card_collection",
    "detail_area",
    "form_area",
    "info_section",
    "action_area",
    "bottom_action_area",
    "bottom_navigation",
    "floating_action_area",
    "overlay",
    "modal",
    "drawer",
    "bottom_sheet",
    "popup",
    "empty_state",
    "loading_state",
    "success_state",
    "error_state",
    "footer",
    "section",
    "settings_group",
    "promo_section",
    "carousel",
    "grid_area",
    "stats_area",
    "profile_area",
    "unknown",
]

InteractionSourceKind = Literal[
    "button",
    "icon_button",
    "text_button",
    "link",
    "list_item",
    "card",
    "banner",
    "tab",
    "segment",
    "chip",
    "menu_item",
    "nav_item",
    "cta",
    "image",
    "row_item",
    "input_affordance",
    "overlay_control",
    "switch",
    "checkbox",
    "radio",
    "stepper",
    "dropdown",
    "slider",
    "text_input",
    "search_input",
    "avatar",
    "tag",
    "pill",
    "tile",
    "grid_item",
    "settings_item",
    "carousel_item",
    "unknown",
]

InteractionType = Literal[
    "navigate",
    "open_detail",
    "open_subpage",
    "open_overlay",
    "close_overlay",
    "back",
    "dismiss",
    "switch_tab",
    "switch_segment",
    "toggle_state",
    "filter",
    "search",
    "expand",
    "collapse",
    "submit",
    "confirm",
    "cancel",
    "save",
    "edit",
    "delete",
    "login",
    "register",
    "purchase",
    "pay",
    "advance_flow",
    "retreat_flow",
    "select",
    "deselect",
    "enable",
    "disable",
    "copy",
    "share",
    "call",
    "download",
    "upload",
    "refresh",
    "interactive_affordance",
    "unknown",
]

ImportanceLevel = Literal["critical", "high", "medium", "low"]
ConfidenceLevel = Literal["high", "medium", "low"]

PageRoleHint = Literal[
    "home",
    "dashboard",
    "list",
    "detail",
    "form",
    "settings",
    "profile",
    "login",
    "register",
    "search",
    "result",
    "checkout",
    "payment",
    "success",
    "error",
    "modal_like",
    "overlay_like",
    "popup_like",
    "sheet_like",
    "unknown",
]

VariantKind = Literal[
    "independent_page",
    "page_state_variant",
    "overlay_state",
    "tab_variant",
    "filter_variant",
    "step_variant",
    "empty_state_variant",
    "loading_variant",
    "success_variant",
    "error_variant",
    "editing_variant",
    "authentication_variant",
    "unknown",
]

OverlayType = Literal[
    "modal",
    "drawer",
    "bottom_sheet",
    "popup",
    "tooltip",
    "toast_like",
    "unknown",
]

SubpageTargetKind = Literal[
    "detail_page",
    "settings_page",
    "list_page",
    "result_page",
    "form_page",
    "profile_page",
    "checkout_page",
    "payment_page",
    "success_page",
    "webview_page",
    "unknown",
]

LayoutPattern = Literal[
    "hero_banner",
    "horizontal_scroll",
    "vertical_list",
    "grid",
    "grid_2x5",
    "tab_strip",
    "bottom_tab_bar",
    "single_panel",
    "two_column",
    "form_stack",
    "settings_list",
    "icon_grid",
    "card_stack",
    "mixed",
    "unknown",
]

ContainerStyleHint = Literal[
    "plain",
    "card",
    "rounded_card",
    "outlined_card",
    "filled_banner",
    "floating_panel",
    "pill_tab",
    "sheet_panel",
    "toolbar",
    "list_row",
    "unknown",
]

VisualEmphasisHint = Literal[
    "primary_focus",
    "secondary_focus",
    "supporting_focus",
    "neutral",
    "unknown",
]

SpacingDensityHint = Literal["compact", "medium", "spacious", "unknown"]


# ============================================================
# Shared lightweight visual / implementation hint models
# ============================================================

class BlockStyleHints(BaseModel):
    background_hint: Optional[str] = Field(
        default=None,
        description="Coarse background/style hint such as light surface, orange banner, purple section."
    )
    container_hint: ContainerStyleHint = Field(
        default="unknown",
        description="Coarse container style hint."
    )
    emphasis_hint: VisualEmphasisHint = Field(
        default="unknown",
        description="Whether this block is a primary or secondary visual focus."
    )
    text_style_hint: Optional[str] = Field(
        default=None,
        description="High-level text style hint such as bold title, price emphasis, muted secondary text."
    )


class VisualStyleHints(BaseModel):
    overall_tone: Optional[str] = Field(
        default=None,
        description="Overall visual tone such as minimal, card-based, promotional, settings-like, content-feed."
    )
    primary_color_hint: Optional[str] = Field(
        default=None,
        description="Main accent color tendency if visible."
    )
    background_color_hint: Optional[str] = Field(
        default=None,
        description="Dominant page background tendency if visible."
    )
    surface_style_hints: List[str] = Field(
        default_factory=list,
        description="Coarse surface-level style clues such as rounded cards, filled banners, icon grid, fixed light bottom bar."
    )
    typography_hints: List[str] = Field(
        default_factory=list,
        description="High-level typography clues useful for implementation."
    )
    spacing_density_hint: SpacingDensityHint = Field(
        default="unknown",
        description="Overall spacing density."
    )
    visual_focus_summary: Optional[str] = Field(
        default=None,
        description="What areas are visually dominant versus secondary."
    )


class ImplementationHints(BaseModel):
    implementation_priority: ImportanceLevel = Field(
        default="medium",
        description="How important it is to preserve this page/block faithfully in implementation."
    )
    implementation_notes: List[str] = Field(
        default_factory=list,
        description="Implementation-oriented simplification or preservation notes."
    )


# ============================================================
# Stage 1: Observation draft schema
# ============================================================

class StructuralBlock(BaseModel):
    block_id: str = Field(..., description="Stable local identifier for this structural block.")
    name: str = Field(..., description="Human-readable name of the block.")
    role: BlockRole = Field(..., description="Coarse-grained role of this block in the page frame.")
    summary: Optional[str] = Field(default=None, description="Short description of what appears in this block.")
    key_texts: List[str] = Field(default_factory=list, description="Important visible texts associated with this block.")
    layout_pattern: LayoutPattern = Field(
        default="unknown",
        description="Coarse layout pattern of this block."
    )
    item_template_hint: Optional[str] = Field(
        default=None,
        description="High-level repeated item template hint, if this block contains repeated entries."
    )
    media_hint: Optional[str] = Field(
        default=None,
        description="High-level media/content hint such as product images, icons, promo artwork, avatars."
    )
    style_hints: Optional[BlockStyleHints] = Field(
        default=None,
        description="Lightweight visual style hints for this block."
    )
    implementation_hints: Optional[ImplementationHints] = Field(
        default=None,
        description="Implementation-oriented priority and simplification hints."
    )
    children: List["StructuralBlock"] = Field(default_factory=list, description="Nested coarse-grained blocks.")


class UIInteractionClue(BaseModel):
    clue_id: str = Field(..., description="Stable local identifier for the interaction clue.")
    source_label: Optional[str] = Field(default=None, description="Visible text label of the source element, if any.")
    source_kind: InteractionSourceKind = Field(..., description="What kind of UI source element this appears to be.")
    source_location: Optional[str] = Field(default=None, description="Approximate location within the screenshot or page frame.")
    source_block_id: Optional[str] = Field(default=None, description="Related structural block id if known.")
    interaction_type: InteractionType = Field(..., description="Best-effort classification of the interaction effect.")
    target_page_hint: Optional[str] = Field(default=None, description="Semantic hint of the destination page or target context.")
    target_element_hint: Optional[str] = Field(default=None, description="Target UI element or state hint if not a full page navigation.")
    effect_summary: Optional[str] = Field(default=None, description="What this interaction likely does.")
    importance: ImportanceLevel = Field(default="medium", description="Importance for flow reconstruction.")
    confidence: ConfidenceLevel = Field(default="medium", description="Confidence in interpretation.")
    is_potential_navigation: bool = Field(default=False, description="Whether this may lead to another page/subpage/detail.")
    is_weak_affordance: bool = Field(default=False, description="True if it only looks clickable but exact action is uncertain.")
    reasoning: Optional[str] = Field(default=None, description="Why this clue was inferred.")


class PageIdentityHints(BaseModel):
    candidate_page_name: str = Field(..., description="Best-effort human-readable page name.")
    candidate_page_id: str = Field(..., description="Best-effort normalized page identifier.")
    page_role_hint: PageRoleHint = Field(default="unknown", description="Best-effort coarse page role classification.")
    title_texts: List[str] = Field(default_factory=list, description="Title/header texts that help identify the page.")
    distinguishing_texts: List[str] = Field(default_factory=list, description="Texts that distinguish this page from others.")
    page_goal_summary: Optional[str] = Field(default=None, description="What the page is mainly for.")
    primary_content_summary: Optional[str] = Field(default=None, description="What the main content appears to be.")


class PageMergeHints(BaseModel):
    variant_kind: VariantKind = Field(default="unknown", description="Whether this seems like an independent page or a variant.")
    likely_same_page_as: List[str] = Field(default_factory=list, description="Candidate page ids/names this may belong with.")
    shared_frame_signals: List[str] = Field(default_factory=list, description="Evidence of same underlying page frame.")
    distinguishing_state_signals: List[str] = Field(default_factory=list, description="Evidence of state variant instead of new page.")
    independent_page_signals: List[str] = Field(default_factory=list, description="Evidence that this should be a separate page.")
    merge_summary: Optional[str] = Field(default=None, description="Summary of merge/separation judgment.")


class SubpageHint(BaseModel):
    hint_id: str = Field(..., description="Stable local identifier for the subpage hint.")
    source_label: Optional[str] = Field(default=None, description="Visible text of the source entry.")
    source_kind: InteractionSourceKind = Field(..., description="Type of source entry.")
    source_location: Optional[str] = Field(default=None, description="Approximate location of the entry.")
    source_block_id: Optional[str] = Field(default=None, description="Related structural block id if available.")
    likely_target_kind: SubpageTargetKind = Field(default="unknown", description="Best-effort classification of likely target.")
    target_page_hint: Optional[str] = Field(default=None, description="Semantic hint of the destination page.")
    confidence: ConfidenceLevel = Field(default="medium", description="Confidence that this is a subpage/detail entry.")
    reasoning: Optional[str] = Field(default=None, description="Why this was inferred.")


class OverlayHints(BaseModel):
    has_overlay: bool = Field(default=False, description="Whether the screenshot appears to include an overlay.")
    overlay_type: Optional[OverlayType] = Field(default=None, description="Best-effort overlay type.")
    overlay_summary: Optional[str] = Field(default=None, description="What the overlay appears to contain or do.")
    open_trigger_hints: List[str] = Field(default_factory=list, description="Hints about what may open this overlay.")
    close_trigger_hints: List[str] = Field(default_factory=list, description="Hints about what may close this overlay.")


class StateHints(BaseModel):
    tab_labels: List[str] = Field(default_factory=list, description="Visible tab labels.")
    active_tab_hint: Optional[str] = Field(default=None, description="Which tab appears active.")
    active_tab_style_hint: Optional[str] = Field(
        default=None,
        description="High-level visual cue of the active tab, such as highlighted text, icon change, underline, red dot."
    )
    segment_labels: List[str] = Field(default_factory=list, description="Visible segment labels.")
    active_segment_hint: Optional[str] = Field(default=None, description="Which segment appears active.")
    active_segment_style_hint: Optional[str] = Field(
        default=None,
        description="High-level visual cue of the active segment, such as darker text, filled pill, underline."
    )
    filter_hints: List[str] = Field(default_factory=list, description="Visible filters or sorting conditions.")
    page_state_tags: List[str] = Field(
        default_factory=list,
        description="Observed page state tags such as empty, loading, success, member, verified, editing, expanded."
    )
    state_summary: Optional[str] = Field(default=None, description="Summary of visible state clues.")


class NavigationHints(BaseModel):
    has_back: bool = Field(default=False, description="Whether a back affordance is visible.")
    has_close: bool = Field(default=False, description="Whether a close/dismiss control is visible.")
    primary_ctas: List[str] = Field(default_factory=list, description="Primary visible CTA labels.")
    likely_entry_points: List[str] = Field(default_factory=list, description="Visible elements likely to lead deeper.")
    likely_exit_points: List[str] = Field(default_factory=list, description="Visible controls likely to leave current page/state.")
    navigation_summary: Optional[str] = Field(default=None, description="Summary of major navigation clues.")


class ArchitectPageObservationDraft(BaseModel):
    draft_index: int = Field(..., description="Index of this observation draft.")
    image_path: str = Field(..., description="Source screenshot path.")
    draft_status: PageObservationStatus = Field(..., description="Whether observation succeeded.")
    identity: PageIdentityHints = Field(..., description="Page identity and semantic hints.")
    layout_summary: str = Field(..., description="Overall summary of the page frame and major regions.")
    visual_style_hints: Optional[VisualStyleHints] = Field(
        default=None,
        description="High-level visual style hints extracted from the screenshot."
    )
    implementation_hints: Optional[ImplementationHints] = Field(
        default=None,
        description="Implementation-oriented page-level priority and notes."
    )
    structural_blocks: List[StructuralBlock] = Field(default_factory=list, description="Coarse-grained structural blocks.")
    visible_texts: List[str] = Field(default_factory=list, description="Important visible texts useful for identification and merge.")
    key_controls: List[str] = Field(default_factory=list, description="Important visible controls or CTA labels.")
    visible_interactions: List[UIInteractionClue] = Field(default_factory=list, description="Important interaction and navigation clues.")
    subpage_hints: List[SubpageHint] = Field(default_factory=list, description="Hints for subpages or deeper flows.")
    merge_hints: PageMergeHints = Field(..., description="Hints for page merging and variant detection.")
    overlay_hints: OverlayHints = Field(default_factory=OverlayHints, description="Overlay-related hints.")
    state_hints: StateHints = Field(default_factory=StateHints, description="State/tab/segment/filter hints.")
    navigation_hints: NavigationHints = Field(default_factory=NavigationHints, description="High-level navigation clues.")
    uncertainties: List[str] = Field(default_factory=list, description="Known ambiguities.")
    raw_observation: Optional[str] = Field(default=None, description="Free-text summary for debugging or audit.")
    error: Optional[str] = Field(default=None, description="Failure reason when draft_status='failed'.")


class ArchitectObservationBatch(BaseModel):
    observations: List[ArchitectPageObservationDraft] = Field(
        default_factory=list,
        description="Collection of stage 1 page observation drafts."
    )


class ArchitectDraftIndexSummary(BaseModel):
    draft_index: int = Field(..., description="Index of this draft.")
    image_path: str = Field(..., description="Source image path.")
    draft_status: PageObservationStatus = Field(..., description="Observation status.")
    candidate_page_id: str = Field(..., description="Candidate page id from identity hints.")
    candidate_page_name: str = Field(..., description="Candidate page name from identity hints.")
    layout_summary: str = Field(..., description="Compact layout summary.")
    draft_file: str = Field(..., description="Persisted full draft file path.")
    page_role_hint: PageRoleHint = Field(default="unknown", description="Candidate page role.")
    variant_kind: VariantKind = Field(default="unknown", description="Candidate merge variant kind.")
    has_overlay: bool = Field(default=False, description="Whether overlay seems present.")
    visible_interactions: List[UIInteractionClue] = Field(default_factory=list, description="Key visible interaction clues.")


class ArchitectPageDraftsIndexFile(BaseModel):
    drafts: List[ArchitectDraftIndexSummary] = Field(default_factory=list, description="Lightweight summaries of all drafts.")
    total_image_count: int = Field(default=0, description="Total number of input images.")
    success_count: int = Field(default=0, description="Successful observation count.")
    failed_count: int = Field(default=0, description="Failed observation count.")


# ============================================================
# Stage 2 / Stage 3 final architect schema
# ============================================================

FinalPageRole = Literal[
    "home",
    "list",
    "detail",
    "form",
    "settings",
    "profile",
    "search",
    "result",
    "checkout",
    "payment",
    "success",
    "error",
    "modal",
    "overlay",
    "dashboard",
    "unknown",
]

NavigationActionType = Literal[
    "navigate",
    "back",
    "open_overlay",
    "close_overlay",
    "switch_tab",
    "switch_segment",
    "submit",
    "confirm",
    "cancel",
    "save",
    "advance_flow",
    "retreat_flow",
    "select",
    "toggle_state",
    "unknown",
]

PageRelationType = Literal[
    "navigates_to",
    "opens_overlay",
    "closes_overlay",
    "returns_to",
    "switches_tab",
    "switches_segment",
    "same_page_variant",
    "contains_subpage_entry",
    "changes_state",
    "unknown",
]


class FinalActionTarget(BaseModel):
    target_page_id: Optional[str] = Field(default=None, description="Resolved destination page id if known.")
    target_overlay_id: Optional[str] = Field(default=None, description="Resolved overlay id if known.")
    target_state_hint: Optional[str] = Field(default=None, description="Target state hint if action changes page state.")


class FinalInteraction(BaseModel):
    interaction_id: str = Field(..., description="Stable identifier for the final interaction.")
    label: Optional[str] = Field(default=None, description="Visible label.")
    source_kind: InteractionSourceKind = Field(..., description="Source UI element kind.")
    action_type: NavigationActionType = Field(..., description="Resolved action type.")
    source_location: Optional[str] = Field(default=None, description="Approximate source location.")
    target: FinalActionTarget = Field(default_factory=FinalActionTarget, description="Resolved or partially resolved target.")
    importance: ImportanceLevel = Field(default="medium", description="Interaction importance.")
    confidence: ConfidenceLevel = Field(default="medium", description="Resolution confidence.")
    notes: Optional[str] = Field(default=None, description="Optional extra notes.")


class FinalPageBlock(BaseModel):
    block_id: str = Field(..., description="Stable identifier for the final page block.")
    name: str = Field(..., description="Human-readable block name.")
    role: BlockRole = Field(..., description="Coarse-grained block role.")
    summary: Optional[str] = Field(default=None, description="Short summary of this block.")
    layout_pattern: LayoutPattern = Field(
        default="unknown",
        description="Coarse layout pattern of this block."
    )
    item_template_hint: Optional[str] = Field(
        default=None,
        description="High-level repeated item template hint, if applicable."
    )
    media_hint: Optional[str] = Field(
        default=None,
        description="High-level media/content hint."
    )
    style_hints: Optional[BlockStyleHints] = Field(
        default=None,
        description="Lightweight visual style hints retained for implementation."
    )
    implementation_hints: Optional[ImplementationHints] = Field(
        default=None,
        description="Implementation-oriented priority and simplification hints."
    )
    children: List["FinalPageBlock"] = Field(default_factory=list, description="Nested coarse page blocks.")


class ArchitectPageFile(BaseModel):
    page_id: str = Field(..., description="Canonical page identifier.")
    page_name: str = Field(..., description="Human-readable page name.")
    page_role: FinalPageRole = Field(default="unknown", description="Resolved page role.")
    page_summary: Optional[str] = Field(default=None, description="Overall summary of page purpose and contents.")
    visual_style_hints: Optional[VisualStyleHints] = Field(
        default=None,
        description="High-level visual style hints retained for implementation."
    )
    implementation_hints: Optional[ImplementationHints] = Field(
        default=None,
        description="Implementation-oriented page-level priority and notes."
    )
    derived_from_images: List[str] = Field(default_factory=list, description="Source screenshot paths.")
    frame_blocks: List[FinalPageBlock] = Field(default_factory=list, description="Coarse page frame blocks.")
    key_texts: List[str] = Field(default_factory=list, description="Important texts retained for implementation context.")
    interactions: List[FinalInteraction] = Field(default_factory=list, description="Resolved interactions on this page.")
    state_variants: List[str] = Field(default_factory=list, description="Named variants or states associated with this page.")
    overlay_ids: List[str] = Field(default_factory=list, description="Related overlays that can open from this page.")
    child_page_ids: List[str] = Field(default_factory=list, description="Likely child/sub-pages reachable from this page.")
    notes: Optional[str] = Field(default=None, description="Extra implementation-oriented notes.")


class ArchitectPageRelation(BaseModel):
    relation_id: str = Field(..., description="Stable identifier for the page relation.")
    source_page_id: str = Field(..., description="Source page id.")
    relation_type: PageRelationType = Field(..., description="Type of relation.")
    trigger_label: Optional[str] = Field(default=None, description="UI label or interaction label causing the relation.")
    trigger_interaction_id: Optional[str] = Field(default=None, description="Associated final interaction id if available.")
    target_page_id: Optional[str] = Field(default=None, description="Target page id if relation points to another page.")
    target_overlay_id: Optional[str] = Field(default=None, description="Target overlay id if relation points to an overlay.")
    target_state_hint: Optional[str] = Field(default=None, description="State hint if relation represents a state change.")
    confidence: ConfidenceLevel = Field(default="medium", description="Confidence in relation resolution.")
    reasoning: Optional[str] = Field(default=None, description="Why this relation was created.")


class ArchitectIndexFile(BaseModel):
    app_name: str = Field(..., description="Application or project name.")
    summary: Optional[str] = Field(default=None, description="High-level summary of the app structure.")
    visual_style: Optional[VisualStyle] = Field(
        default=None,
        description="Global visual style hints for the app."
    )
    entry_page_id: Optional[str] = Field(default=None, description="Likely entry page id.")
    page_ids: List[str] = Field(default_factory=list, description="All resolved page ids.")
    overlay_ids: List[str] = Field(default_factory=list, description="All resolved overlay ids.")
    relations: List[ArchitectPageRelation] = Field(default_factory=list, description="Resolved navigation and relation graph.")
    global_notes: List[str] = Field(default_factory=list, description="High-level notes for downstream coder.")


# ============================================================
# Coder schemas (restored from old version)
# ============================================================

class CoderRouteSpec(BaseModel):
    page_name: str = Field(..., description="Page name.")
    route: str = Field(..., description="Harmony page route such as pages/Index.")
    page_file: str = Field(..., description="Workspace-relative page file path.")


class CoderSharedArtifact(BaseModel):
    name: str = Field(..., description="Shared artifact name.")
    file_path: str = Field(..., description="Workspace-relative file path.")
    description: str = Field(..., description="Artifact responsibility summary.")


class CoderStateConvention(BaseModel):
    store_name: str = Field(..., description="Primary shared store name.")
    file_path: str = Field(..., description="Workspace-relative store file path.")
    responsibilities: str = Field(..., description="What the store manages.")
    exposed_state: List[str] = Field(default_factory=list, description="Shared state keys exposed to pages.")
    exposed_actions: List[str] = Field(default_factory=list, description="Shared actions exposed to pages.")


class CoderPageTask(BaseModel):
    page_id: str = Field(..., description="Architect page id bound to this task.")
    page_name: str = Field(..., description="Page name assigned to the worker.")
    route: str = Field(..., description="Harmony page route such as pages/Index.")
    design_file: str = Field(..., description="Workspace-relative architect page design file path.")
    page_file: str = Field(..., description="Workspace-relative primary page file path.")
    allowed_write_paths: List[str] = Field(
        default_factory=list,
        description="Workspace-relative file paths the page worker may edit.",
    )
    shared_dependencies: List[str] = Field(
        default_factory=list,
        description="Shared components, stores, or interfaces the page uses.",
    )
    responsibilities: str = Field(
        default="",
        description="Page responsibility summary. Defaults to empty string when not yet specified.",
    )
    primary_actions: List[str] = Field(
        default_factory=list,
        description="Primary handlers or user actions for the page.",
    )
    state_notes: Optional[str] = Field(None, description="Relevant page state notes.")
    role: Optional[str] = Field(None, description="Page role copied from architect design when useful.")
    summary: Optional[str] = Field(None, description="Short page summary copied from architect design when useful.")


class CoderSkeletonOutput(BaseModel):
    project_name: str = Field(
        ...,
        pattern=r"^[a-z][a-z0-9_]{0,199}$",
        description="Project directory name.",
    )
    app_display_name: str = Field(..., description="User-visible app name.")
    page_tasks: List[CoderPageTask] = Field(..., min_length=1, description="Page implementation tasks.")
    generated_route_table: Optional[List[dict]] = Field(
        None,
        description="Route table generated during materialization. Populated by skeleton tool, not by agent."
    )
    generated_files: Optional[dict] = Field(
        None,
        description="File paths written during materialization. Populated by skeleton tool, not by agent."
    )


class CoderPageTaskBundle(BaseModel):
    project_name: str = Field(..., description="Project name that owns the page tasks.")
    tasks: List[CoderPageTask] = Field(default_factory=list, description="Page task list.")


class CoderPageWorkerResult(BaseModel):
    status: Literal["done", "blocked", "need_human_guidance"] = Field(..., description="Worker completion state.")
    page_name: str = Field(..., description="Page name handled by the worker.")
    modified_files: List[str] = Field(default_factory=list, description="Files modified for this page task.")
    exports_added: List[str] = Field(default_factory=list, description="New exports or symbols added by the worker.")
    shared_contract_requests: List[str] = Field(
        default_factory=list,
        description="Requests for integration to adjust shared contracts.",
    )
    blockers: List[str] = Field(default_factory=list, description="Blocking issues encountered by the worker.")
    summary: str = Field(..., description="Short implementation summary.")


class CoderPageWorkerResultBundle(BaseModel):
    project_name: str = Field(..., description="Project name that owns the worker results.")
    results: List[CoderPageWorkerResult] = Field(default_factory=list, description="Collected page worker results.")


class CoderIntegrationReport(BaseModel):
    compile_status: Literal["SUCCESS", "FAILED"] = Field(..., description="Compilation verdict after integration.")
    project_name: str = Field(..., description="Project name.")
    project_path: str = Field(..., description="Workspace-relative project path.")
    ready_for_tester: bool = Field(..., description="Whether the project is ready for tester validation.")
    fixes_applied: List[str] = Field(default_factory=list, description="Integration fixes applied.")
    remaining_errors: List[str] = Field(default_factory=list, description="Remaining errors after integration.")
    blocker: str = Field(..., description="Blocking summary, use 'none' when clear.")
    next_recommended_agent: Literal["tester", "coder", "human", "orchestrator"] = Field(
        ...,
        description=(
            "Next recommended owner after integration. "
            "Use 'tester' when compile succeeded. "
            "Use 'coder' when errors are fixable but were not resolved in this run. "
            "Use 'orchestrator' when a pipeline-level decision is needed. "
            "Use 'human' when errors require manual intervention."
        ),
    )


class CoderCompileFixAttempt(BaseModel):
    attempt_index: int = Field(..., description="1-based compile attempt index within the integration stage.")
    timestamp: str = Field(..., description="UTC ISO timestamp for this attempt record.")
    task_type: Literal["implementation", "fix_from_test"] = Field(..., description="Coder task type.")
    project_name: str = Field(..., description="Project name.")
    compile_status: Literal["SUCCESS", "FAILED"] = Field(..., description="Compile verdict for this attempt.")
    error_signature: str = Field(..., description="Normalized signature for the primary compile error.")
    key_errors: List[str] = Field(default_factory=list, description="Extracted key compile errors.")
    worker_summary: str = Field(..., description="Integration worker summary for this attempt.")
    worker_summaries_so_far: List[str] = Field(default_factory=list, description="Cumulative integration worker summaries so far.")
    modified_files: List[str] = Field(default_factory=list, description="Files modified by page workers before integration.")
    fixes_applied: List[str] = Field(default_factory=list, description="Fix summaries known at this point.")
    skills_referenced: List[str] = Field(default_factory=list, description="Skills or references intentionally used.")
    resolved_in_next_attempt: Optional[bool] = Field(None, description="Whether the next attempt resolved this attempt's primary issue.")
    final_success: Optional[bool] = Field(None, description="Whether the overall integration run eventually succeeded.")


class CoderCompileFixTrace(BaseModel):
    project_name: str = Field(..., description="Project name.")
    task_type: Literal["implementation", "fix_from_test"] = Field(..., description="Coder task type.")
    attempts: List[CoderCompileFixAttempt] = Field(default_factory=list, description="Ordered compile/fix attempts.")
    final_compile_status: Literal["SUCCESS", "FAILED"] = Field(..., description="Final compile verdict.")
    final_success: bool = Field(..., description="Whether the overall integration run succeeded.")


# ============================================================
# Tester schemas (restored from old version)
# ============================================================

class TesterChecklistItem(BaseModel):
    name: str = Field(..., description="Checklist item or page/module name.")
    status: Literal["PASS", "FAIL", "UNKNOWN"] = Field(..., description="Validation status.")
    source: Optional[str] = Field(None, description="Source of the checklist item.")
    evidence: Optional[str] = Field(None, description="Evidence path or summary.")
    gap: Optional[str] = Field(None, description="Missing info or functional gap.")
    pair: Optional[str] = Field(None, description="Reference/runtime image pair summary.")
    advices: Optional[List[str]] = Field(None, description="UI comparison advice list.")
    impact: Optional[Literal["high", "medium", "low"]] = Field(None, description="Impact level for UI gap.")


class TesterMissingItems(BaseModel):
    functional: List[str] = Field(default_factory=list, description="Missing functional items.")
    ui: List[str] = Field(default_factory=list, description="Missing UI items.")


class TesterEvidencePaths(BaseModel):
    description: str = Field(..., description="Description path.")
    reference_images: List[str] = Field(default_factory=list, description="Reference image paths.")
    runtime_screenshots: List[str] = Field(default_factory=list, description="Runtime screenshot paths.")
    layout_json: List[str] = Field(default_factory=list, description="Captured layout json paths.")
    ui_compare_logs: List[str] = Field(default_factory=list, description="UI comparison log paths.")
    report_path: str = Field(..., description="Saved report path.")


class TesterFixSuggestions(BaseModel):
    p0: List[str] = Field(default_factory=list, description="Critical fixes.")
    p1: List[str] = Field(default_factory=list, description="High-priority fixes.")
    p2: List[str] = Field(default_factory=list, description="Low-priority fixes.")


class TesterCompletionSummary(BaseModel):
    task_type: Literal["validation"] = Field(..., description="Tester task type.")
    report_saved: bool = Field(..., description="Whether the json report was saved.")
    next_recommended_agent: Literal["coder", "orchestrator", "human"] = Field(
        ...,
        description="Recommended next owner.",
    )
    blocker: str = Field(..., description="Blocker summary, use 'none' when clear.")


class TesterReportOutput(BaseModel):
    overall: Literal["PASS", "FAIL"] = Field(..., description="Overall validation verdict.")
    functional_completeness: Literal["PASS", "FAIL"] = Field(..., description="Functional verdict.")
    static_ui_completeness: Literal["PASS", "FAIL"] = Field(..., description="Static UI verdict.")
    functional_checklist: List[TesterChecklistItem] = Field(default_factory=list, description="Functional checklist.")
    static_ui_checklist: List[TesterChecklistItem] = Field(default_factory=list, description="Static UI checklist.")
    missing_items: TesterMissingItems = Field(..., description="Missing functional and UI items.")
    evidence_paths: TesterEvidencePaths = Field(..., description="Evidence path collection.")
    fix_suggestions: TesterFixSuggestions = Field(..., description="Fix suggestion groups.")
    completion_summary: TesterCompletionSummary = Field(..., description="Completion metadata.")


# ============================================================
# Transitional aliases / compatibility helpers
# ============================================================

ArchitectPageDraft = ArchitectPageObservationDraft
ArchitectDraftBatch = ArchitectObservationBatch
ArchitectPageDraftsIndex = ArchitectPageDraftsIndexFile