# Cluster Core — Session Changes

## Bug Fixes

### Arrow Block BFS Expansion (scr_grid_physics)
Arrow cells were being used as BFS seeds during `settle_matches`, accidentally clearing adjacent same-color normal blocks that shouldn't have been cleared. Fixed by skipping BFS expansion on arrow/metal cells.

### Bomb "ULTRA BLAST!" Never Showed (scr_grid_physics, scr_special_blocks)
`special_clear_reward`'s label param was only used for jackpot logic. Fixed by adding `create_floating_text_ext` directly in the bomb handler in `lock_piece`. Also added per-cell particles inside `resolve_bomb` loop and bumped center burst from 30 → 40 particles.

### `hintPulseEnabled` Missing from Settings Init (obj_menu_controller/Create_0)
`global.settings` was initialised without `hintPulseEnabled`, so entering from the menu could silently disable hints. Added the field to the struct literal.

---

## New Features

### Arrow Axis Glow (obj_game_manager/Draw_0)
Active arrow piece now glows along its valid match axis (row for H, column for V, both for cross) using additive-blend coloured rectangles that pulse subtly.

### Match Hints Settings Toggle
"Match Hints" added as the 3rd item in the Settings screen. Toggles `global.settings.hintPulseEnabled`. Updated settings array, loop sizes, and mouse hit areas from 2 → 3 items.

### Next Piece Preview — Single Piece Only (obj_game_manager/Draw_64)
Changed from showing up to 2 queued pieces to exactly 1, centred in the panel.

---

## Menu System Redesign

### State Stack Replaces 13 Boolean Flags
**Before:** `in_title`, `in_settings`, `in_story_select`, `in_bonus_select`, `in_refabricator`, `in_inventory`, `in_shop`, `in_how_to_play`, `in_achievements`, `in_save_slots`, `in_name_entry`, `is_loading`, `in_level_transition`, `in_story_level_select`, `exit_pending` (15 variables)

**After:** `global.menu_stack` (array) + `menu_popping` (bool) + 3 functions:
- `menu_current()` — returns top of stack
- `menu_push(MenuState.X)` — navigate deeper
- `menu_pop_immediate()` — instantly pop (used inside the fade-out animation)

**Enum** (`scr_menu_render_shared`):
```
TITLE, SAVE_SLOTS, NAME_ENTRY, LOADING,
MAIN,
STORY_SELECT, STORY_LEVEL, BONUS_SELECT,
REFABRICATOR, INVENTORY, SHOP, HOW_TO_PLAY, ACHIEVEMENTS, SETTINGS,
LEVEL_TRANS
```

**Back navigation** is now a single path everywhere: set `menu_popping = true` → Step_0 fades screen to black → calls `menu_pop_immediate()` → fades back in. No more `exit_pending` string + 10-case switch.

### Files changed by refactor
| File | Change |
|------|--------|
| `scr_menu_render_shared.gml` | Added enum + 3 helper functions |
| `obj_menu_controller/Create_0.gml` | Removed 13 flags → `global.menu_stack` |
| `obj_menu_controller/Step_0.gml` | Full rewrite using `menu_current()` / `menu_push()` |
| `obj_menu_controller/Draw_64.gml` | Dispatcher uses `menu_current()` instead of flag chain |
| `scr_menu_render_main.gml` | `menu_draw_title` checks `menu_current()` instead of flags |
| `scr_menu_render_story.gml` | `menu_draw_story_select` checks `menu_current()` instead of `in_story_level_select` |

### Visual Improvements
- **Per-mode card colours**: Story=blue, Planet=purple, Classic=amber — gradient from visible tint at top to deep dark at bottom, plus 5px solid accent stripe at the top of each card
- **Mode-coloured borders and labels**: unselected cards now show their mode colour at 50% opacity; labels match mode colour
- **Sub-screen consistency**: `menu_draw_settings` and `menu_draw_refabricator` now use `_menu_draw_sub_screen_base` (removed ~25 lines of duplicated setup code each)
- **Subtitle position fixed**: was drawn at `_cy - 40` (middle of screen), now at `y=165` (just below title)
- **Toolbar labels always visible**: toolbar item names shown at 38% opacity normally, 100% when selected
