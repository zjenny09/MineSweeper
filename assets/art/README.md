# Runtime Art Library

`assets/art/` is the authoritative runtime image tree. Runtime fonts under `assets/fonts/` and visual shaders under `shaders/` are maintained in the same stable art catalog.

`docs/art/ui_history/` stores original concepts, discarded variants, and source references. Files there are historical material, not cataloged runtime assets; they must be cleaned, cropped, renamed, and copied into an authoritative runtime tree before use.

## Permanent asset IDs

Every authoritative visual asset has a permanent internal ID:

```text
ART_0001
ART_0002
...
```

The ID does not change when a file is renamed, moved, visually replaced, or no longer used. Retired IDs are kept and never reused.

Maintenance files:

- `docs/art/GAME_ART_CATALOG.xlsx`: human review and provenance workbook; its `素材名称（中文）` column identifies the exact object and state at a glance;
- `docs/art/GAME_ART_CATALOG.json`: version-control-friendly machine manifest;
- `scripts/art_ids.gd`: generated Godot ID-to-path lookup;
- `tools/art_catalog.py`: discover, import, export, and validation tool;
- `docs/art/AI_ART_PROMPT_SYSTEM.md`: prompt definitions linked by `PRM_*` IDs.

Existing semantic constants in `scripts/art_catalog.gd` remain supported. New stable lookup is also available:

```gdscript
ArtCatalog.path_for(&"ART_0001")
ArtCatalog.short_name_for(&"ART_0001")
ArtCatalog.id_for_path("res://assets/art/...")
```

IDs and normalized short names are internal maintenance data and are not displayed to players.

## Directory convention

- `common/`: shared fonts and buttons;
- `gameplay/`: board markers shared by chapters;
- `tutorial/`: tutorial-only artwork;
- `level_01/` and `land_levels/`: Land artwork;
- `ocean_levels/`: Ocean artwork;
- `sky_levels/`: Sky artwork;
- `badge_hall/`: badge-hall chapter displays and milestone artwork;
- `level_select/`: chapter maps and nodes;
- `welcome/`: welcome-screen backgrounds, effects, and actors.

## Naming convention

Physical files use lowercase snake case ordered from broad context to specific content:

```text
<location>_<role>_<content>_<state>.<ext>
```

Examples:

- `top_guardian_white_standing.png`
- `left_panel_sprout_wilted.png`
- `cell_keyboard_focus.png`
- `menu_secondary_pressed.svg`

Catalog short names use:

```text
<scope>_<subject>_<state>
```

Examples:

- `wel_landscape_base`
- `land_pause_normal`
- `ocean_l10_whale_fall_healthy`
- `sky_hexagon_hidden_surface`
- `space_universe_nebula`

Short names must be unique, lowercase snake case, and no longer than 36 characters. They describe use but do not replace permanent IDs.

Do not retain source-generation numbers such as `(16)`, `素材设计18`, or arbitrary upload names in runtime filenames.

## Maintenance commands

Run from the project root:

```bash
python tools/art_catalog.py discover
python tools/art_catalog.py export
python tools/art_catalog.py import
python tools/art_catalog.py validate
```

- `discover`: preserve all known IDs and append IDs for new files. A uniquely matching SHA-256 can preserve the ID of a moved file.
- `export`: refresh computed metadata and rebuild Excel/Godot lookup files. Import unsaved Excel edits first.
- `import`: apply editable Excel fields by permanent ID, then rebuild JSON, Excel, and Godot lookup files.
- `validate`: check structure and synchronization only; it does not approve visual quality or usage rights.

## Adding or replacing artwork

1. Keep source/reference material and generation evidence outside the runtime tree.
2. Export the game-ready asset into an authoritative runtime directory.
3. Use a semantic physical filename.
4. Run `python tools/art_catalog.py discover` to append a new ID.
5. Complete source tool, commercial evidence, rights, prompt, replacement, and review fields in Excel.
6. Run `python tools/art_catalog.py import` and then `validate`.
7. Add or update an `ArtCatalog` semantic constant if runtime code needs one.
8. Show the rendered result to the user for visual approval.

When replacing a file in place, keep its existing ID. When moving or renaming it, update the `当前路径` field for that same ID instead of creating a replacement ID.
