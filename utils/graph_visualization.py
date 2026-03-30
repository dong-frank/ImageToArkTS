import re
import sys
from pathlib import Path
from typing import Callable, Dict, List, Optional, Sequence, Tuple, Union


def _extract_subagent_types(compiled_graph) -> List[str]:
    tools_node = getattr(compiled_graph, "nodes", {}).get("tools")
    if tools_node is None:
        return []

    tools_by_name = getattr(getattr(tools_node, "bound", None), "tools_by_name", {}) or {}
    task_tool = tools_by_name.get("task")
    description = getattr(task_tool, "description", "") if task_tool else ""
    if not description:
        return []

    matches = re.findall(r"^- ([a-zA-Z0-9_-]+):", description, flags=re.MULTILINE)
    deduped = []
    for item in matches:
        if item not in deduped:
            deduped.append(item)
    return deduped


def _extract_subagent_metadata(compiled_graph) -> Dict[str, Dict[str, List[str]]]:
    subagent_defs = getattr(compiled_graph, "subagents", None)
    if not subagent_defs:
        agent_module = sys.modules.get("agent")
        if agent_module is not None:
            subagent_defs = getattr(agent_module, "subagents", None)

    metadata: Dict[str, Dict[str, List[str]]] = {}
    for subagent in subagent_defs or []:
        name = str(subagent.get("name", "")).strip()
        if not name:
            continue

        tools: List[str] = []
        for tool in subagent.get("tools", []) or []:
            tool_name = getattr(tool, "name", None) or getattr(tool, "__name__", None)
            if tool_name:
                tools.append(str(tool_name))

        skills: List[str] = []
        for skill in subagent.get("skills", []) or []:
            skills.extend(_expand_skill_reference(str(skill)))

        model_name = _resolve_model_name(subagent.get("model"))
        metadata[name] = {"tools": tools, "skills": skills, "model": [model_name] if model_name else []}
    return metadata


def _escape_mermaid_text(text: str) -> str:
    return text.replace('"', "'")


def _join_items(items: Sequence[str]) -> str:
    if not items:
        return "none"
    return ", ".join(items)


def _format_label_lines(items: Sequence[str], per_line: int = 4) -> str:
    if not items:
        return "none"
    lines: List[str] = []
    current: List[str] = []
    for item in items:
        current.append(item)
        if len(current) >= per_line:
            lines.append(", ".join(current))
            current = []
    if current:
        lines.append(", ".join(current))
    return "<br/>".join(lines)


def _resolve_model_name(model_obj) -> str:
    if model_obj is None:
        return ""
    for attr in ("model_name", "model"):
        value = getattr(model_obj, attr, None)
        if isinstance(value, str) and value.strip():
            return value.strip()
    return str(model_obj)


def _extract_main_model(compiled_graph) -> str:
    agent_module = sys.modules.get("agent")
    if agent_module is not None:
        for attr in ("base_model", "model"):
            model_obj = getattr(agent_module, attr, None)
            if model_obj is not None:
                model_name = _resolve_model_name(model_obj)
                if model_name:
                    return model_name
    model_obj = getattr(compiled_graph, "main_model", None)
    if model_obj is not None:
        model_name = _resolve_model_name(model_obj)
        if model_name:
            return model_name
    return ""


def _candidate_skill_paths(skill_ref: str) -> List[Path]:
    candidates: List[Path] = []
    path = Path(skill_ref)
    cwd = Path.cwd()
    if path.is_absolute():
        candidates.append(path)
        stripped = skill_ref.lstrip("/")
        if stripped:
            candidates.append(cwd / stripped)
            candidates.append(cwd / "agent_workspace" / stripped)
        if skill_ref == "/skills":
            candidates.append(cwd / "agent_workspace" / "skills")
    else:
        candidates.append(cwd / skill_ref)
    return candidates


def _expand_skill_reference(skill_ref: str) -> List[str]:
    expanded: List[str] = []
    for candidate in _candidate_skill_paths(skill_ref):
        if candidate.is_file() and candidate.name == "SKILL.md":
            expanded.append(candidate.parent.name)
            break
        if candidate.is_dir():
            found = sorted(candidate.glob("*/SKILL.md"))
            if found:
                expanded.extend([path.parent.name for path in found])
                break

    if expanded:
        deduped: List[str] = []
        for item in expanded:
            if item not in deduped:
                deduped.append(item)
        return deduped
    return [skill_ref]


def _extract_main_tools(compiled_graph) -> List[str]:
    tools_node = getattr(compiled_graph, "nodes", {}).get("tools")
    if tools_node is None:
        return []
    tools_by_name = getattr(getattr(tools_node, "bound", None), "tools_by_name", {}) or {}
    return list(tools_by_name.keys())


def _build_enhanced_mermaid(
    base_mermaid: str,
    subagent_types: List[str],
    subagent_metadata: Dict[str, Dict[str, List[str]]],
    main_tools: List[str],
    main_model: str,
) -> str:
    if "graph TD;" not in base_mermaid or not subagent_types:
        return base_mermaid

    graph_header = "graph TD;\n"
    if "graph TD;\n" in base_mermaid:
        graph_header = "graph TD;\n"
    elif "graph LR;\n" in base_mermaid:
        graph_header = "graph LR;\n"

    additions: List[str] = [
        "\ttask_dispatch{{task dispatch}}",
        "\ttools -.-> task_dispatch;",
    ]
    main_tools_label = _escape_mermaid_text(_format_label_lines(main_tools))
    additions.append(f'\tmain_tools_meta["main tools: {main_tools_label}"]')
    additions.append("\ttools -.-> main_tools_meta;")
    if main_model:
        additions.append(f'\tmain_model_meta["main model: {_escape_mermaid_text(main_model)}"]')
        additions.append("\tmodel -.-> main_model_meta;")

    for subagent in subagent_types:
        node_id = f"subagent_{subagent.replace('-', '_')}"
        safe_name = subagent.replace('"', "'")
        additions.append(f'\tsubgraph cluster_{node_id}["{safe_name}"]')
        additions.append(f'\t\t{node_id}["{safe_name}"]')

        details = subagent_metadata.get(subagent, {})
        tools_items = details.get("tools", [])
        model_items = details.get("model", [])
        if subagent == "general-purpose":
            if not tools_items:
                tools_items = main_tools
            if not model_items and main_model:
                model_items = [main_model]

        tools_label = _format_label_lines(tools_items)
        skills_label = _format_label_lines(details.get("skills", []))
        model_label = _join_items(model_items)
        tools_node_id = f"{node_id}_tools"
        additions.append(f'\t\t{tools_node_id}["tools: {_escape_mermaid_text(tools_label)}"]')
        additions.append(f"\t\t{node_id} -.-> {tools_node_id};")
        if model_label != "none":
            model_node_id = f"{node_id}_model"
            additions.append(f'\t\t{model_node_id}["model: {_escape_mermaid_text(model_label)}"]')
            additions.append(f"\t\t{node_id} -.-> {model_node_id};")
        if skills_label != "none":
            skills_node_id = f"{node_id}_skills"
            additions.append(f'\t\t{skills_node_id}["skills: {_escape_mermaid_text(skills_label)}"]')
            additions.append(f"\t\t{node_id} -.-> {skills_node_id};")
        additions.append("\tend")
        additions.append(f"\ttask_dispatch -.-> {node_id};")
        additions.append(f"\t{node_id} -.-> model;")

    additions.extend(
        [
            "\tclassDef subagent fill:#e8f4ff,stroke:#4a78b8,stroke-width:1px;",
            "\tclassDef meta fill:#f7f8fa,stroke:#9aa5b1,stroke-dasharray: 3 2;",
            "\tclassDef dispatch fill:#fff3e0,stroke:#c77700,stroke-width:1.5px;",
            "\tclass task_dispatch dispatch;",
            "\tclass main_tools_meta,main_model_meta meta;",
        ]
    )
    for subagent in subagent_types:
        node_id = f"subagent_{subagent.replace('-', '_')}"
        additions.append(f"\tclass {node_id} subagent;")
        additions.append(f"\tclass {node_id}_tools meta;")

    if graph_header in base_mermaid:
        return base_mermaid.replace(graph_header, graph_header + "\n".join(additions) + "\n", 1)
    return base_mermaid


def export_graph_visualization(
    compiled_graph,
    output_dir: Union[str, Path] = "artifacts",
    base_name: str = "langgraph",
    png_renderer: Optional[Callable[[str], bytes]] = None,
) -> Tuple[Path, Path]:
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    drawable_graph = compiled_graph.get_graph()

    base_mermaid = drawable_graph.draw_mermaid()
    subagent_types = _extract_subagent_types(compiled_graph)
    subagent_metadata = _extract_subagent_metadata(compiled_graph)
    main_tools = _extract_main_tools(compiled_graph)
    main_model = _extract_main_model(compiled_graph)
    mermaid_text = _build_enhanced_mermaid(base_mermaid, subagent_types, subagent_metadata, main_tools, main_model)
    mermaid_file = output_path / f"{base_name}.mmd"
    mermaid_file.write_text(mermaid_text, encoding="utf-8")

    renderer = png_renderer
    if renderer is None:
        try:
            from langchain_core.runnables.graph_mermaid import draw_mermaid_png

            renderer = draw_mermaid_png
        except Exception:
            renderer = None
    try:
        if renderer is None:
            raise RuntimeError("Mermaid PNG renderer unavailable")
        png_bytes = renderer(mermaid_text)
    except Exception:
        png_bytes = drawable_graph.draw_mermaid_png()
    png_file = output_path / f"{base_name}.png"
    png_file.write_bytes(png_bytes)

    return mermaid_file, png_file
