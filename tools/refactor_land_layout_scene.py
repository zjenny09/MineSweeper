#!/usr/bin/env python3
"""Flatten the Land layout into editor-addressable top-level controls."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCENE_PATH = ROOT / "scenes" / "main.tscn"

NODE_RE = re.compile(r'^\[node name="([^"]+)"(?: type="[^"]+")?(?: parent="([^"]+)")?.*\]$')

OLD_ENV = "PageMargin/Columns/LeftColumn/EnvironmentPanel"
OLD_BOARD = "PageMargin/Columns/BoardPanel"
OLD_GUIDE = f"{OLD_BOARD}/FirstMoveGuide"
OLD_RIGHT = f"{OLD_GUIDE}/RightColumn"
OLD_HUD = f"{OLD_RIGHT}/HudPanel"
OLD_QUICK = f"{OLD_RIGHT}/QuickButtons"

PREFIX_MAP = [
    (OLD_HUD, "LandLayout/RightInfo"),
    (OLD_QUICK, "LandLayout/QuickActions"),
    (OLD_GUIDE, "LandLayout/FirstMoveGuide"),
    (OLD_BOARD, "LandLayout/BoardArea"),
    (OLD_ENV, "LandLayout/LeftInfo"),
    ("LandTopHud", "LandLayout/TopHud"),
    ("LevelOneBackground", "LandLayout/Stage"),
]

REMOVE_EXACT = {
    "PageMargin",
    "PageMargin/Columns",
    "PageMargin/Columns/LeftColumn",
    OLD_RIGHT,
    "LevelOneAnimationPlayer",
}

REMOVE_PREFIXES = (
    "LevelOneBackground/LevelOneDecorations",
    "PageMargin/Columns/LeftColumn/LeftDecorativeSprout",
    "PageMargin/Columns/LeftColumn/LeftSproutVictoryDots",
    "PageMargin/Columns/LeftColumn/LeftSproutGuardianLeftShadow",
    "PageMargin/Columns/LeftColumn/LeftSproutGuardianRightShadow",
    f"{OLD_RIGHT}/BudSproutDecorationA",
    f"{OLD_BOARD}/BoardCenter/Board/BoardShadow",
    f"{OLD_BOARD}/BoardCenter/Board/BoardTray",
    f"{OLD_ENV}/InfoBackShadow",
    f"{OLD_ENV}/InfoBackArtwork",
    f"{OLD_ENV}/InfoTopShadow",
    f"{OLD_ENV}/InfoNoteArtwork",
    f"{OLD_HUD}/StatusNoteShadow",
    f"{OLD_HUD}/StatusNoteArtwork",
)

ROOT_PROPERTIES: dict[str, list[str]] = {
    "LandLayout/Stage": [
        "unique_name_in_owner = true",
        "layout_mode = 0",
        "offset_left = 100.0",
        "offset_top = 15.0",
        "offset_right = 1200.0",
        "offset_bottom = 565.0",
        "mouse_filter = 2",
    ],
    "LandLayout/LeftInfo": [
        "unique_name_in_owner = true",
        "layout_mode = 0",
        "offset_left = 115.0",
        "offset_top = 153.0",
        "offset_right = 245.0",
        "offset_bottom = 411.0",
        "pivot_offset = Vector2(65, 129)",
    ],
    "LandLayout/BoardArea": [
        "unique_name_in_owner = true",
        "layout_mode = 0",
        "offset_left = 368.0",
        "offset_top = 91.0",
        "offset_right = 988.0",
        "offset_bottom = 678.0",
    ],
    "LandLayout/FirstMoveGuide": [
        "unique_name_in_owner = true",
        "visible = false",
        "z_index = 80",
        "layout_mode = 1",
        "anchors_preset = 15",
        "anchor_right = 1.0",
        "anchor_bottom = 1.0",
        "grow_horizontal = 2",
        "grow_vertical = 2",
        "mouse_filter = 2",
    ],
    "LandLayout/RightInfo": [
        "unique_name_in_owner = true",
        "layout_mode = 0",
        "offset_left = 932.0",
        "offset_top = 134.0",
        "offset_right = 1142.0",
        "offset_bottom = 428.0",
        "pivot_offset = Vector2(105, 147)",
    ],
    "LandLayout/QuickActions": [
        "unique_name_in_owner = true",
        "layout_mode = 0",
        "offset_left = 954.0",
        "offset_top = 377.0",
        "offset_right = 1126.0",
        "offset_bottom = 467.0",
        "theme_override_constants/separation = 14",
    ],
    "LandLayout/TopHud": [
        "unique_name_in_owner = true",
        "z_index = 12",
        "layout_mode = 0",
        "offset_left = 197.00002",
        "offset_top = 15.999999",
        "offset_right = 1636.9999",
        "offset_bottom = 128.85713",
        "scale = Vector2(0.7, 0.7)",
        "mouse_filter = 2",
    ],
}

LAYOUT_KEYS = {
    "layout_mode",
    "anchors_preset",
    "anchor_left",
    "anchor_top",
    "anchor_right",
    "anchor_bottom",
    "offset_left",
    "offset_top",
    "offset_right",
    "offset_bottom",
    "grow_horizontal",
    "grow_vertical",
    "position",
    "size",
    "scale",
    "pivot_offset",
    "custom_minimum_size",
    "size_flags_horizontal",
    "size_flags_vertical",
    "alignment",
    "visible",
    "z_index",
    "mouse_filter",
    "theme_override_constants/separation",
    "unique_name_in_owner",
}


def node_path(header: str) -> str:
    match = NODE_RE.match(header)
    if match is None:
        raise RuntimeError(f"Could not parse node header: {header}")
    name, parent = match.groups()
    if parent is None or parent == ".":
        return name
    return f"{parent}/{name}"


def map_path(path: str) -> str:
    for old_prefix, new_prefix in PREFIX_MAP:
        if path == old_prefix:
            return new_prefix
        if path.startswith(old_prefix + "/"):
            return new_prefix + path[len(old_prefix):]
    return path


def should_remove(path: str) -> bool:
    if path in REMOVE_EXACT:
        return True
    return any(path == prefix or path.startswith(prefix + "/") for prefix in REMOVE_PREFIXES)


def rewrite_header(header: str, mapped_path: str) -> str:
    name = mapped_path.rsplit("/", 1)[-1]
    parent = mapped_path.rsplit("/", 1)[0] if "/" in mapped_path else "."
    rewritten = re.sub(r'name="[^"]+"', f'name="{name}"', header, count=1)
    if ' parent="' in rewritten:
        rewritten = re.sub(r' parent="[^"]+"', f' parent="{parent}"', rewritten, count=1)
    elif parent != ".":
        rewritten = rewritten[:-1] + f' parent="{parent}"]'
    return rewritten


def replace_layout_properties(block: list[str], properties: list[str]) -> list[str]:
    kept = [block[0]]
    for line in block[1:]:
        if "=" not in line:
            kept.append(line)
            continue
        key = line.split("=", 1)[0].strip()
        if key not in LAYOUT_KEYS:
            kept.append(line)
    return [kept[0], *properties, *kept[1:]]


def direct_fill_properties(block: list[str]) -> list[str]:
    properties = [
        "z_index = 1",
        "layout_mode = 1",
        "anchors_preset = 15",
        "anchor_right = 1.0",
        "anchor_bottom = 1.0",
        "grow_horizontal = 2",
        "grow_vertical = 2",
        "pivot_offset = Vector2(310, 293.5)",
    ]
    return replace_layout_properties(block, properties)


def guide_bubble_properties(block: list[str]) -> list[str]:
    properties = [
        "unique_name_in_owner = true",
        "anchors_preset = 0",
        "offset_left = 566.0",
        "offset_top = 252.07349",
        "offset_right = 1050.0",
        "offset_bottom = 427.9265",
        "mouse_filter = 1",
    ]
    return replace_layout_properties(block, properties)


def split_scene(text: str) -> tuple[str, list[list[str]]]:
    lines = text.splitlines()
    first_node = next(index for index, line in enumerate(lines) if line.startswith("[node "))
    preamble = "\n".join(lines[:first_node]).rstrip() + "\n\n"
    blocks: list[list[str]] = []
    current: list[str] = []
    for line in lines[first_node:]:
        if line.startswith("[node "):
            if current:
                blocks.append(current)
            current = [line]
        else:
            current.append(line)
    if current:
        blocks.append(current)
    return preamble, blocks


def land_layout_block() -> list[str]:
    return [
        '[node name="LandLayout" type="Control" parent="."]',
        "unique_name_in_owner = true",
        "layout_mode = 0",
        "offset_right = 1280.0",
        "offset_bottom = 720.0",
        "mouse_filter = 2",
        "",
    ]


def actor_layout_blocks() -> list[list[str]]:
    return [
        [
            '[node name="LandRobot" type="TextureRect" parent="LandLayout"]',
            "unique_name_in_owner = true",
            "z_index = 6",
            "layout_mode = 0",
            "offset_left = 10.0",
            "offset_top = 570.0",
            "offset_right = 130.0",
            "offset_bottom = 670.0",
            "mouse_filter = 2",
            'texture = ExtResource("49_land_robot_layout")',
            "expand_mode = 1",
            "stretch_mode = 5",
            "",
        ],
        [
            '[node name="LandEcology" type="TextureRect" parent="LandLayout"]',
            "unique_name_in_owner = true",
            "z_index = 6",
            "layout_mode = 0",
            "offset_left = 400.0",
            "offset_top = 510.0",
            "offset_right = 800.0",
            "offset_bottom = 690.0",
            "mouse_filter = 2",
            'texture = ExtResource("19_txyw0")',
            "expand_mode = 1",
            "stretch_mode = 5",
            "",
        ],
        [
            '[node name="LandMonster" type="TextureRect" parent="LandLayout"]',
            "unique_name_in_owner = true",
            "z_index = 6",
            "layout_mode = 0",
            "offset_left = 1150.0",
            "offset_top = 570.0",
            "offset_right = 1270.0",
            "offset_bottom = 670.0",
            "mouse_filter = 2",
            'texture = ExtResource("50_land_monster_layout")',
            "expand_mode = 1",
            "stretch_mode = 5",
            "",
        ],
        [
            '[node name="LandAnimationController" parent="." instance=ExtResource("46_tabletop_actors")]',
            "unique_name_in_owner = true",
            "visible = false",
            "layout_mode = 1",
            "anchors_preset = 15",
            "anchor_right = 1.0",
            "anchor_bottom = 1.0",
            "grow_horizontal = 2",
            "grow_vertical = 2",
            "",
        ],
    ]


def add_preview_resources(preamble: str) -> str:
    resources = (
        '[ext_resource type="Texture2D" '
        'path="res://assets/art/land_v2/characters/sprout_robot_right_front.png" '
        'id="49_land_robot_layout"]\n'
        '[ext_resource type="Texture2D" '
        'path="res://assets/art/land_v2/characters/pollution_slime_defiant_a.png" '
        'id="50_land_monster_layout"]\n'
    )
    marker = "\n[sub_resource "
    if marker not in preamble:
        raise RuntimeError("Could not locate sub-resource section")
    return preamble.replace(marker, "\n" + resources + marker, 1)


def main() -> None:
    original = SCENE_PATH.read_text(encoding="utf-8")
    preamble, blocks = split_scene(original)
    preamble = add_preview_resources(preamble)
    output: list[list[str]] = []
    layout_inserted = False
    actor_blocks_inserted = False

    for block in blocks:
        old_path = node_path(block[0])
        if should_remove(old_path):
            continue
        mapped_path = map_path(old_path)
        if mapped_path == "LandLayout/Stage" and not layout_inserted:
            output.append(land_layout_block())
            layout_inserted = True
        block[0] = rewrite_header(block[0], mapped_path)
        if mapped_path in ROOT_PROPERTIES:
            block = replace_layout_properties(block, ROOT_PROPERTIES[mapped_path])
        elif mapped_path == "LandLayout/BoardArea/BoardCenter":
            block = direct_fill_properties(block)
        elif mapped_path == "LandLayout/FirstMoveGuide/GuideBubbleRoot":
            block = guide_bubble_properties(block)
        if mapped_path == "PauseOverlay" and not actor_blocks_inserted:
            output.extend(actor_layout_blocks())
            actor_blocks_inserted = True
        output.append(block)

    if not layout_inserted or not actor_blocks_inserted:
        raise RuntimeError("Failed to insert the new Land layout nodes")

    rendered = preamble + "\n".join("\n".join(block).rstrip() for block in output) + "\n"
    SCENE_PATH.write_text(rendered, encoding="utf-8")
    print("Refactored main.tscn into a flat, editor-addressable Land layout.")


if __name__ == "__main__":
    main()
