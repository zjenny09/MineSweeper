#!/usr/bin/env python3
"""Apply badge hall prototype assets to the runtime art manifest.

JSON and generated GDScript are updated without rewriting the Excel workbook.
"""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOOL_PATH = ROOT / "tools" / "art_catalog.py"
SOURCE_MAP = ROOT / "assets" / "art" / "badge_hall" / "SOURCE_MAP.json"


def load_art_catalog_tool():
    specification = importlib.util.spec_from_file_location("art_catalog_tool", TOOL_PATH)
    if specification is None or specification.loader is None:
        raise RuntimeError("Could not load tools/art_catalog.py")
    module = importlib.util.module_from_spec(specification)
    specification.loader.exec_module(module)
    return module


def prompt_for_category(category: str) -> str:
    return {
        "背景": "PRM_BG_BADGE_HALL",
        "勋章殿堂展示台": "PRM_STAGE_BADGE_HALL",
        "勋章殿堂生态元素": "PRM_ECOLOGY",
        "勋章殿堂按钮": "PRM_BUTTON",
    }.get(category, "PRM_STYLE")


def main() -> None:
    tool = load_art_catalog_tool()
    payload = tool.load_payload()
    source_payload = json.loads(SOURCE_MAP.read_text(encoding="utf-8"))
    by_id = {entry["id"]: entry for entry in payload["entries"]}
    occupied_names = {entry["short_name"] for entry in payload["entries"]}
    next_id = max(
        int(payload.get("max_id", 0)),
        max(int(entry["id"].split("_")[1]) for entry in payload["entries"]),
    )

    for mapped in source_payload["assets"]:
        art_id = mapped["art_id"]
        if art_id not in by_id:
            requested_number = int(art_id.split("_")[1])
            if requested_number != next_id + 1:
                raise RuntimeError(
                    f"Cannot assign {art_id}; next permanent ID is ART_{next_id + 1:04d}"
                )
            source_path = tool.local_path(mapped["path"])
            if not source_path.exists():
                raise RuntimeError(f"Runtime artwork is missing: {mapped['path']}")
            entry = tool.new_entry(source_path, art_id, occupied_names)
            payload["entries"].append(entry)
            by_id[art_id] = entry
            next_id = requested_number
        entry = by_id[art_id]
        if entry["path"] != mapped["path"]:
            raise RuntimeError(
                f"Path mismatch for {art_id}: {entry['path']} != {mapped['path']}"
            )
        entry.update({
            "short_name": mapped["short_name"],
            "asset_name": mapped["asset_name"],
            "description": f"勋章殿堂 · {mapped['category']} · {mapped['asset_name']}",
            "scope": "勋章系统",
            "category": mapped["category"],
            "variant": mapped["variant"],
            "prompt_id": prompt_for_category(mapped["category"]),
            "replacement_status": "独立视觉测试待确认",
            "source_tool": "ChatGPT（用户生成来源）",
            "note": (
                f"{mapped['v2l_id']}；由 tools/process_badge_hall_art.py "
                "生成运行规格文件，暂不关联真实游戏进度。"
            ),
            "review": "待用户确认",
        })

    payload["max_id"] = max(int(payload.get("max_id", 0)), next_id)
    payload["entries"].sort(key=lambda item: int(item["id"].split("_")[1]))
    tool.refresh_entries(payload["entries"])
    tool.save_payload(payload)
    tool.write_generated_gdscript(payload["entries"])
    print(
        f"Updated {len(source_payload['assets'])} badge hall entries; "
        "Excel export is deferred while the workbook is open."
    )


if __name__ == "__main__":
    main()
