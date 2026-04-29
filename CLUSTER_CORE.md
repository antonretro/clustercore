# Cluster Core

Tetris-style falling-block puzzle game with colored cluster matching, special pieces, combo chains, and a Fever/Jackpot system. Built in GameMaker Studio 2. Target platform: Steam (Windows).

---

## Rooms

| Room | Size | Contents |
|------|------|----------|
| `room_menu` | 1920×1080 | `obj_menu_controller` |
| `room_game` | 1920×1080 | `obj_game_manager`, spawns `obj_block` at runtime |

Flow: `room_menu` → Enter → `room_game`. Game Over → R restarts `room_game`, ESC returns to `room_menu`.

---

## Core Objects

### `obj_game_manager`
The single controller object in `room_game`. Handles all game logic, rendering, and state.

- **Create**: Initializes all globals, calls `start_game()` immediately
- **Step**: Hitstop tick → juice updates → input → gameplay logic
- **Draw**: Renders to a 1280×720 surface, upscales to screen (crisp pixel rendering via `gpu_set_texfilter(false)`)
- **Draw GUI (64)**: Full HUD, pause overlay, game over overlay
- **Alarm[0]**: Calls `settle_matches()` to continue chain reactions

### `obj_block`
One instance per piece on the grid. Handles its own animation only — no logic.

- **Create**: Sets type, color, color_id, grid_x, grid_y, scale_x/y, clearing flag
- **Step**: Lerps render position toward grid position; spins/shrinks/fades when `clearing = true`
- **Draw**: Empty — drawing is done by `obj_game_manager/Draw_0` for pixel-correct scaling

### `obj_menu_controller`
Lives only in `room_menu`. Handles menu navigation and `room_goto(room_game)`.

---

## Scripts

### `scr_grid_physics`
- `check_collision(_dx, _dy)` — wall/floor/stack collision check
- `move_piece(_dx, _dy)` — moves active piece, applies squash/stretch
- `hard_drop()` — instant fall + beam VFX
- `rotate_piece()` — flips metal block direction only
- `lock_piece()` — locks piece to grid; triggers drill/bomb abilities or `settle_matches()`
- `settle_matches()` — find+clear matches, award points, chain via `alarm[0]`
- `apply_grid_gravity()` — drops floating blocks after a clear
- `check_game_over()` — true if any block is in the hidden rows

### `scr_match_engine`
- `find_matches_in_grid()` — entry point, returns array of `{x,y}` coords to clear
- `add_cluster_matches()` — flood-fill: normal blocks clear at 3+, metal (arrows) clear only in a line of 4+
- `add_diagonal_matches()` — 3-diagonal clears for normal blocks only
- `expand_core_set()` — chain reaction: expands cleared set to adjacent same-color normal blocks
- `collect_cluster()` — BFS to find connected same-color group
- `in_cluster()` — linear search helper (O(n), acceptable at current board size)

### `scr_piece_logic`
- `generate_piece()` — random piece weighted by level (dead/bomb/drill/metal/normal)
- `get_color_from_id(_id)` — maps color ID 1–6 to RGB
- `spawn_piece()` — pops next queue, creates `obj_block` instance, replenishes queue
- `hold_piece()` — swaps active piece into hold slot (once per drop)

### `scr_juice_systems`
- `create_particles()`, `create_floating_text()`, `create_floating_text_ext()` — VFX spawners
- `create_beam()`, `create_impact()` — flash effects on hard drop / piece land
- `award_shards()` — grants run currency based on match count + fever bonus
- `charge_jackpot()` — fills meter; triggers Fever Mode at 50 charge
- `update_level_progress()` — levels up when `levelScore >= scoreToNext` (×1.5 each level)
- **SFX stubs** — `sfx_piece_lock()`, `sfx_clear()`, `sfx_bomb()`, `sfx_drill()`, `sfx_fever()`, `sfx_level_up()`, `sfx_game_over()`, etc. All wired at the right callsites, commented out until audio assets are added.

---

## Piece Types

| Type | ID | Behavior |
|------|----|----------|
| Normal | 1–6 | Clears in clusters of 3+ same color |
| Metal (Arrow) | 1–6 | Requires line of 4+ to clear; shows direction arrows |
| Bomb | 888 | On lock: destroys 3×3 area, 6-frame hitstop |
| Drill | 777 | On lock: destroys entire column, 4-frame hitstop |
| Dead | 999 | Inert blocker; never clears, never chains |

---

## Color System

6 colors, introduced progressively:

| ID | Color | Active from |
|----|-------|-------------|
| 1 | Pink | Level 1 |
| 2 | Orange | Level 1 |
| 3 | Yellow | Level 1 |
| 4 | Purple | Level 3 |
| 5 | Cyan | Level 6 |
| 6 | Blue | Level 9 |

Every 3 levels, one reserve color moves to the active pool.

---

## Scoring

| Event | Points |
|-------|--------|
| Match clear | `count × 100 × comboChain × feverMult` |
| Drill block | `150 × feverMult` per block destroyed |
| Bomb (area) | No direct points, triggers matches |
| Fever multiplier | ×2 while active |

---

## Combo & Fever

- **Combo chain**: increments each time `settle_matches()` finds matches in a single drop sequence; resets to 0 when no matches found
- **Best combo**: tracked per run, displayed in BEST panel
- **Jackpot meter**: fills by match count + drill/bomb hits; triggers **Fever Mode** at 50
- **Fever Mode**: 600 frames (10 seconds), ×2 points, star warp background, yellow UI tint, 8-frame hitstop on activation

---

## Hitstop

Brief frame-freeze on key events (gameplay input blocked, VFX still update):

| Event | Frames |
|-------|--------|
| Normal piece lock | 2 |
| Drill | 4 |
| Bomb | 6 |
| Match clear | 2 + min(combo, 4) |
| Fever activate | 8 |

---

## Global State

```
global.gameState        "PLAYING" | "PAUSED" | "GAMEOVER"
global.score            Current run score
global.level            Current level (1+)
global.levelScore       Score progress toward next level
global.scoreToNext      Threshold (starts 1500, ×1.5 per level)
global.comboChain       Active combo count (resets each piece)
global.bestCombo        Best chain this run
global.runShards        Collectible currency earned this run
global.jackpotMeter     0–50 charge toward Fever
global.feverTimer       Frames remaining in Fever (0 = inactive)
global.hitstop          Frames of gameplay freeze remaining
global.grid[y][x]       11×5 array of {type, color, dir, id, inst} or undefined
global.activePiece      Current falling obj_block instance
global.holdPiece        Held piece data struct (or undefined)
global.canHold          Whether hold is available this drop
global.nextQueue[]      3-piece preview queue
global.locking          True during match/chain resolution
global.settings         {ghostEnabled, shakeEnabled}
global.PIXEL_SCALE      4 (scales 80×144 board to 320×576 on screen)
global.COLS / ROWS      5 / 9 (+ 2 hidden rows at top)
```

---

## Layout (1920×1080)

```
┌──────────────────────────────────────────────────────────────────┐
│  [SCORE  ]  │                                │  [NEXT         ]  │
│  [LEVEL  ]  │       Board 400×720px          │                   │
│  [HOLD   ]  │    centered at (760, 180)      │  [SHARDS       ]  │
│  [BEST   ]  │                                │  [COMBO        ]  │
└──────────────────────────────────────────────────────────────────┘
               ↑ level gauge    jackpot gauge ↑
```

- `PIXEL_SCALE = 5` → board `400×720` in 1920×1080
- Board: `_bx = (1920 - 400) / 2 = 760`, `_by = (1080 - 720) / 2 = 180`
- Left column (`x=50`, `w=240`): panels anchor to `_by2`, fill exact board height (720px)
- Right column (`x=1630`, `w=240`): same anchor, same total height
- Gauges: level gauge left of board at `_bx - 32`, jackpot gauge right at `_bx + bw + 20`

---

## Known Issues / Next Steps

### Bugs remaining
- `expand_core_set()` only chains to normal blocks — metal arrows don't chain after initial clear
- `in_cluster()` is O(n) linear search — fine now, worth replacing with 2D bool grid if perf degrades

### Steam readiness gaps
1. **SFX** — all hooks wired in `scr_juice_systems`, all commented. Drop in audio assets and uncomment.
2. **Controller support** — no gamepad input yet (mandatory for puzzle games on Steam)
3. **Save/load** — no persistence. High scores, unlocks, settings not saved between sessions.
4. **Settings screen** — G/S toggles work in-game but no settings UI in menu
5. **Menu items 2–5** (Story, Lab, Challenges, Settings) — `launch_mode` set but no destination rooms
6. **Colorblind mode** — important for a color-matching game
7. **Resolution/windowed toggle** — not implemented
8. **Steam leaderboards** — not implemented
