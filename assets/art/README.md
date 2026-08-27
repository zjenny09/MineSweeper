# Runtime Art Library

`assets/art/` is the only art tree that runtime code should reference.

`docs/ui_history/` stores original concepts, discarded variants, and source references. Files there must be copied, cleaned, cropped, and renamed before use in the game.

## Directory convention

- `common/`: shared fonts and buttons
- `gameplay/`: gameplay markers shared by boards
- `tutorial/`: tutorial-only artwork
- `level_01/`: first-level background, board, interface, decorations, and guardians
- `welcome/`: welcome-screen backgrounds, effects, and actors

## Naming convention

Use lowercase snake case ordered from broad context to specific content:

`<location>_<role>_<content>_<state>.<ext>`

Examples:

- `top_guardian_white_standing.png`
- `left_panel_sprout_wilted.png`
- `cell_keyboard_focus.png`
- `menu_secondary_pressed.svg`

Do not retain source-generation numbers such as `(16)`, `素材设计18`, or `guardian_11` in runtime filenames.

## Runtime catalog

All runtime paths are declared in `res://scripts/art_catalog.gd`. Game scripts reference `ArtCatalog` constants instead of embedding paths.

When adding artwork:

1. Keep the original in `docs/ui_history/`.
2. Export a game-ready copy with transparent edges and cropped bounds into `assets/art/`.
3. Name it by location, role, content, and state.
4. Add one constant to `scripts/art_catalog.gd`.
5. Reference only that constant from runtime code.
