# Land v2 runtime artwork

These files are runtime derivatives of the stable source candidates in `docs/art/ver2bygpt/VER2_LAND_ART_CATALOG.xlsx`.

- Source namespace: `V2L_####`
- Preparation tool: `tools/process_land_v2_art.py`
- Permanent runtime/source map: `SOURCE_MAP.json`
- Status: integrated for in-game user review; visual approval remains pending.
- Processing: resize, alpha-bound canvas trim for standalone RGBA components, and semantic runtime renaming only. No masks, generated cutouts, synthetic shadows, or new visual content are added.

## Source groups

- Background/stage/HUD/buttons/cells/markers: `V2L_0001–V2L_0016`, plus `V2L_0076–V2L_0077`.
- Pollution slime: `V2L_0025`.
- Robot front pose: `V2L_0033`.
- Level ecology pairs: `V2L_0062–V2L_0075`.

The layout reference copied as `SOURCE_LAYOUT_SPEC.md` is documentation only and is not imported by Godot.
