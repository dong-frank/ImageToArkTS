import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch


class ArchitectImageFactsTests(unittest.TestCase):
    def test_normalize_architect_payload_loads_nested_json_strings(self) -> None:
        from tools.architect_tools import _normalize_architect_payload

        normalized = _normalize_architect_payload(
            {
                "project_name": "damai_app",
                "app_display_name": "大麦",
                "pages": [
                    {
                        "name": "Index",
                        "responsibilities": "展示首页",
                    }
                ],
                "visual_style": json.dumps(
                    {
                        "design_tone": "简洁卡片化",
                        "style_tokens": {"card_padding": "16"},
                    },
                    ensure_ascii=False,
                ),
                "navigation": json.dumps(
                    [
                        {
                            "from_page": "Index",
                            "trigger": "点击卡片",
                            "to_page": "Detail",
                            "transition": "push",
                        }
                    ],
                    ensure_ascii=False,
                ),
                "data_model": json.dumps(
                    [
                        {
                            "field": "city",
                            "type": "string",
                            "description": "城市",
                        }
                    ],
                    ensure_ascii=False,
                ),
                "interactions": json.dumps(
                    [
                        {
                            "event": "search",
                            "description": "执行搜索",
                        }
                    ],
                    ensure_ascii=False,
                ),
            }
        )

        self.assertIsInstance(normalized["visual_style"], dict)
        self.assertIsInstance(normalized["navigation"], list)
        self.assertIsInstance(normalized["data_model"], list)
        self.assertIsInstance(normalized["interactions"], list)

    def test_build_architect_image_facts_bundle_saves_bundle(self) -> None:
        from tools.architect_tools import build_architect_image_facts_bundle_payload
        from utils.session_context import reset_current_session_id, set_current_session_id
        from utils.session_workspace import session_workspace_dir, session_user_input_dir

        with tempfile.TemporaryDirectory() as tmpdir:
            project_root = Path(tmpdir)
            session_id = "session-facts"
            token = set_current_session_id(session_id)
            try:
                user_input_dir = session_user_input_dir(project_root, session_id)
                user_input_dir.mkdir(parents=True, exist_ok=True)
                (user_input_dir / "a.png").write_bytes(b"fake-image-a")
                (user_input_dir / "b.png").write_bytes(b"fake-image-b")
                (user_input_dir / "user_input_metadata.json").write_text(
                    json.dumps(
                        {
                            "files": {
                                "a.png": {"path": "/user_input/a.png", "content_type": "image/png"},
                                "b.png": {"path": "/user_input/b.png", "content_type": "image/png"},
                            }
                        },
                        ensure_ascii=False,
                    ),
                    encoding="utf-8",
                )

                fake_outputs = [
                    {
                        "image_path": "/user_input/a.png",
                        "image_role": "entry",
                        "visible_texts": ["Calculator"],
                        "layout_summary": "top result and keypad",
                        "key_sections": ["display", "keypad"],
                        "interactive_hints": ["tap digits"],
                        "uncertainties": [],
                    },
                    {
                        "image_path": "/user_input/b.png",
                        "image_role": "entry",
                        "visible_texts": ["History"],
                        "layout_summary": "history list",
                        "key_sections": ["header", "history list"],
                        "interactive_hints": ["tap history item"],
                        "uncertainties": ["secondary state unclear"],
                    },
                ]

                with patch("tools.architect_tools._extract_architect_image_facts_for_image", side_effect=fake_outputs):
                    result = build_architect_image_facts_bundle_payload(project_root=project_root)

                self.assertIn("status: SUCCESS", result)
                bundle_path = session_workspace_dir(project_root, session_id) / "designs" / "architect_image_facts.json"
                self.assertTrue(bundle_path.exists())
                saved = json.loads(bundle_path.read_text(encoding="utf-8"))
                self.assertEqual(len(saved["facts"]), 2)
                self.assertTrue(saved["conflicts"])
                self.assertEqual(saved["coverage_summary"]["processed_image_count"], 2)
            finally:
                reset_current_session_id(token)

    def test_build_architect_image_facts_bundle_respects_budget(self) -> None:
        from tools.architect_tools import build_architect_image_facts_bundle_payload
        from utils.session_context import reset_current_session_id, set_current_session_id
        from utils.session_workspace import session_user_input_dir

        with tempfile.TemporaryDirectory() as tmpdir:
            project_root = Path(tmpdir)
            session_id = "session-budget"
            token = set_current_session_id(session_id)
            try:
                user_input_dir = session_user_input_dir(project_root, session_id)
                user_input_dir.mkdir(parents=True, exist_ok=True)
                files = {}
                for index in range(10):
                    name = f"{index}.png"
                    (user_input_dir / name).write_bytes(f"img-{index}".encode("utf-8"))
                    files[name] = {"path": f"/user_input/{name}", "content_type": "image/png"}
                (user_input_dir / "user_input_metadata.json").write_text(
                    json.dumps({"files": files}, ensure_ascii=False),
                    encoding="utf-8",
                )

                with patch(
                    "tools.architect_tools._extract_architect_image_facts_for_image",
                    side_effect=lambda image_path, **_: {
                        "image_path": image_path,
                        "image_role": "unknown",
                        "visible_texts": [],
                        "layout_summary": "",
                        "key_sections": [],
                        "interactive_hints": [],
                        "uncertainties": [],
                    },
                ) as extractor:
                    result = build_architect_image_facts_bundle_payload(project_root=project_root, max_images=8)

                self.assertIn("status: SUCCESS", result)
                self.assertEqual(extractor.call_count, 8)
                self.assertIn("omitted_image_count: 2", result)
            finally:
                reset_current_session_id(token)


if __name__ == "__main__":
    unittest.main()
