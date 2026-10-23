#!/usr/bin/env python3
"""Apply the Sky v2 source map to the runtime art manifest.

The authoritative Excel workbook is intentionally left untouched while it may
be open; JSON and generated GDScript stay synchronized.
"""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOOL_PATH = ROOT / "tools" / "art_catalog.py"
SOURCE_MAP = ROOT / "assets" / "art" / "sky_v2" / "SOURCE_MAP.json"


def load_art_catalog_tool():
    specification = importlib.util.spec_from_file_location("art_catalog_tool", TOOL_PATH)
    if specification is None or specification.loader is None:
        raise RuntimeError("Could not load tools/art_catalog.py")
    module = importlib.util.module_from_spec(specification)
    specification.loader.exec_module(module)
    return module


def prompt_for_category(category: str) -> str:
    return {
        "背景": "PRM_BG_SKY",
        "棋盘舞台": "PRM_STAGE_SKY",
        "HUD组件": "PRM_PANEL",
        "HUD图标": "PRM_MARKER",
        "按钮": "PRM_BUTTON",
        "标记": "PRM_MARKER",
        "数字": "PRM_CELL_SKY",
        "污染怪兽": "PRM_MONSTER",
        "主角载具": "PRM_ROBOT",
        "生态元素": "PRM_ECOLOGY",
        "徽章": "PRM_STYLE",
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
            "description": f"天空篇 · {mapped['category']} · {mapped['asset_name']}",
            "scope": "天空篇",
            "category": mapped["category"],
            "variant": mapped["variant"],
            "prompt_id": prompt_for_category(mapped["category"]),
            "replacement_status": "运行预览待确认",
            "source_tool": "ChatGPT（用户生成来源）",
            "note": (
                f"{mapped['v2l_id']}；由 tools/process_sky_v2_art.py "
                "生成运行规格文件。"
            ),
            "review": "待用户确认",
        })

    payload["max_id"] = max(int(payload.get("max_id", 0)), next_id)
    payload["entries"].sort(key=lambda item: int(item["id"].split("_")[1]))
    tool.refresh_entries(payload["entries"])
    tool.save_payload(payload)
    tool.write_generated_gdscript(payload["entries"])
    print(
        f"Updated {len(source_payload['assets'])} Sky v2 entries; "
        "Excel export is deferred while the workbook is open."
    )


if __name__ == "__main__":
    main()
