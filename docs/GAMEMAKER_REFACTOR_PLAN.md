# GameMaker Refactor Plan

## Goal

Make Cluster Core easier to grow into a real Steam game by splitting the current giant `obj_game_manager` into focused systems.

Do this gradually. Do not rewrite the whole game at once.

## Current Problem

`obj_game_manager` currently owns too much:

- Game rules
- Piece spawning
- Grid state
- Match resolving
- Special pieces
- Score
- Jackpot/fever/shards
- Particles
- HUD drawing
- Menu leftovers

That makes every new feature risky.

## Target Object Split

### `obj_game_manager`

Owns run state only:

- Start run
- End run
- Pause
- Current mode
- Score/shards/level

### `obj_grid_controller`

Owns board logic:

- Grid array
- Collision
- Gravity
- Locking pieces
- Spawn positions

### `obj_match_controller`

Owns clear logic:

- Match finding
- Combo chain
- Cascades
- Special clear triggers

### `obj_piece_controller`

Owns active piece:

- Movement
- Hard drop
- Rotation
- Hold/next piece later

### `obj_payout_controller`

Owns casino/incremental systems:

- Jackpot meter
- Fever timer
- Core Shards
- Payout text
- Upgrade modifiers

### `obj_hud`

Owns GUI drawing:

- Score
- Level
- Next preview
- Jackpot meter
- Fever timer
- Combo
- Shards

### `obj_menu_controller`

Owns menu rooms only:

- Main menu
- Story Mode select
- Core Lab
- Challenges
- Settings

## Script Split

Create these scripts:

- `scr_piece_utils`
  - `piece_generate`
  - `piece_get_sprite`
  - `piece_get_color`

- `scr_ui_theme`
  - `ui_draw_panel`
  - `ui_draw_meter`
  - `ui_draw_label`
  - `ui_text`

- `scr_payouts`
  - `payout_award_score`
  - `payout_award_shards`
  - `payout_charge_jackpot`
  - `payout_start_fever`

- `scr_save`
  - `save_load`
  - `save_write`
  - `save_reset`

## First Refactor Step

Move only these first:

1. Piece sprite selection into `scr_piece_utils`.
2. HUD panel/meter drawing into `scr_ui_theme`.
3. Jackpot/fever/shard math into `scr_payouts`.

Leave grid/matching in `obj_game_manager` until the game feels good.

## Font Direction

For the Steam version, add a real font resource instead of relying on GameMaker default text.

Recommended style:

- Title: chunky casino/arcade display font.
- HUD numbers: bold digital or payout-machine style.
- Body/help text: clean readable sans font.

The important rule:

> Score, combo, jackpot, and fever text should look like payout text, not debug labels.

## Depth Rule

Every system should answer one question:

> Does this create anticipation, a better decision, or a better payout moment?

If not, cut it or delay it.
