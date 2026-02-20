from __future__ import annotations

import argparse
import base64
import json
from pathlib import Path
from typing import Any, TypedDict

from state import ProjectState


IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp", ".bmp"}
DESCRIPTION_EXTENSIONS = {".md", ".txt"}
DESCRIPTION_KEYWORDS = ("说明", "description")


class ValidationReport(TypedDict):
    passed: bool
    blockers: list[str]
    warnings: list[str]
    stats: dict[str, int]


class InputBundle(TypedDict):
    state: ProjectState
    validation_report: ValidationReport


DEFAULT_INPUT_ROOT = (Path(__file__).resolve().parent / "Memo").resolve()
DEFAULT_OUTPUT_BUNDLE = (Path(__file__).resolve().parent / "artifacts" / "input_bundle.json").resolve()


def _to_posix_relative(path: Path, root: Path) -> str:
    return path.relative_to(root).as_posix()


def _is_image(path: Path) -> bool:
    return path.suffix.lower() in IMAGE_EXTENSIONS


def _looks_like_description(path: Path) -> bool:
    name = path.stem.lower()
    return path.suffix.lower() in DESCRIPTION_EXTENSIONS and any(keyword in name for keyword in DESCRIPTION_KEYWORDS)


def build_folder_tree(root: Path) -> dict[str, Any]:
    def build_node(current: Path) -> dict[str, Any]:
        directories = sorted([item for item in current.iterdir() if item.is_dir()], key=lambda item: item.name.lower())
        files = sorted([item for item in current.iterdir() if item.is_file()], key=lambda item: item.name.lower())
        return {
            "name": current.name,
            "path": _to_posix_relative(current, root) if current != root else ".",
            "dirs": [build_node(directory) for directory in directories],
            "files": [file.name for file in files],
        }

    return build_node(root)


def find_description_file(root: Path) -> tuple[Path | None, list[Path]]:
    root_text_files = [
        file for file in root.iterdir() if file.is_file() and file.suffix.lower() in DESCRIPTION_EXTENSIONS
    ]
    matched = [file for file in root_text_files if _looks_like_description(file)]
    if matched:
        matched = sorted(matched, key=lambda item: item.name.lower())
        return matched[0], matched
    if root_text_files:
        root_text_files = sorted(root_text_files, key=lambda item: item.name.lower())
        return root_text_files[0], root_text_files
    return None, []


def read_global_description(root: Path) -> tuple[str, Path | None, list[Path]]:
    desc_file, candidates = find_description_file(root)
    if not desc_file:
        return "", None, []
    return desc_file.read_text(encoding="utf-8"), desc_file, candidates


def collect_image_assets(root: Path, include_base64: bool = False) -> list[dict[str, str]]:
    image_assets: list[dict[str, str]] = []
    for file in sorted(root.rglob("*"), key=lambda item: item.as_posix().lower()):
        if not file.is_file() or not _is_image(file):
            continue
        image_path = _to_posix_relative(file, root)
        image_data = ""
        if include_base64:
            raw = file.read_bytes()
            image_data = base64.b64encode(raw).decode("utf-8")
        image_assets.append({"image_path": image_path, "image_data": image_data})
    return image_assets


def _find_page_dirs_with_images(root: Path) -> set[str]:
    page_dirs: set[str] = set()
    for file in root.rglob("*"):
        if file.is_file() and _is_image(file):
            page_dirs.add(_to_posix_relative(file.parent, root))
    return page_dirs


def validate_inputs(root: Path, description_candidates: list[Path], image_assets: list[dict[str, str]]) -> ValidationReport:
    blockers: list[str] = []
    warnings: list[str] = []

    if len(description_candidates) == 0:
        blockers.append("根目录未找到功能描述文件（建议: 说明文档.md 或 description.md）。")
    elif len(description_candidates) > 1:
        warnings.append("根目录存在多个文本候选文件，已按名称排序选择第一个作为功能描述。")

    page_dirs = _find_page_dirs_with_images(root)
    if not page_dirs:
        blockers.append("未找到任何页面图片，请按页面目录放置至少一张图片。")

    stats = {
        "description_candidates": len(description_candidates),
        "image_count": len(image_assets),
        "page_dir_count": len(page_dirs),
    }

    return {
        "passed": len(blockers) == 0,
        "blockers": blockers,
        "warnings": warnings,
        "stats": stats,
    }


def build_initial_project_state(input_root: str | Path, include_base64: bool = False) -> tuple[ProjectState, ValidationReport]:
    root = Path(input_root).resolve()
    global_description, _, description_candidates = read_global_description(root)
    folder_tree = build_folder_tree(root)
    image_assets = collect_image_assets(root, include_base64=include_base64)
    report = validate_inputs(root, description_candidates, image_assets)

    state: ProjectState = {
        "global_description": global_description,
        "folder_tree": folder_tree,
        "image_assets": image_assets,
        "route_map": {},
        "global_data_models": "",
        "page_tasks": [],
        "generated_files": [],
        "review_errors": [],
        "revision_count": 0,
    }
    return state, report


def main() -> None:
    parser = argparse.ArgumentParser(description="Process input assets and generate one bundle JSON file")
    parser.add_argument("--input-root", default=str(DEFAULT_INPUT_ROOT), help="Input root folder path")
    parser.add_argument("--output-bundle", default=str(DEFAULT_OUTPUT_BUNDLE), help="Output JSON bundle path")
    parser.add_argument("--include-base64", action="store_true", help="Embed image data in base64")
    args = parser.parse_args()

    state, report = build_initial_project_state(args.input_root, include_base64=args.include_base64)
    bundle: InputBundle = {
        "state": state,
        "validation_report": report,
    }

    output_bundle = Path(args.output_bundle).resolve()
    output_bundle.parent.mkdir(parents=True, exist_ok=True)
    output_bundle.write_text(json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
