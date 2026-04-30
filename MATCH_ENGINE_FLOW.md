# Match Engine Flow

This document mirrors the current runtime matching pipeline in `scripts/scr_grid_physics/scr_grid_physics.gml` and `scripts/scr_match_engine/scr_match_engine.gml`.

```text
[Piece Locks]
      |
      v
[settle_matches()]
      |
      v
[Pre-pass Repairs]
- enforce_single_core_in_grid()
- repair invalid cell ids (prevents false non-matches)
      |
      v
[Find Base Matches]
find_matches_in_grid():
- cluster matches (4+)
- line matches (H/V 4+)
- diagonal matches
- safety line pass
      |
      v
{Any matches?}
  | No ----------------------------> [clear_landing_flags]
  |                                  [combo reset / spawn next / gameover check]
  |
  | Yes
  v
[Expand Clear Set]
- build clear mask from matched seeds
- flood same-color orthogonal neighbors
- DO NOT auto-pull metal unless it was in seed set
      |
      v
[Score + Combo + Rewards]
- combo++
- points/shards/jackpot
- story progress
- stability restore on clear
      |
      v
[Core Break Phase]
- build match mask
- detect core in matches
- migrate_core(oldCore, avoidMask)
  - old core demoted first
  - pick valid neighbor NOT in avoid mask
      |
      v
[Clear Phase]
for each cell in final clear set:
- skip only protected NEW core cell
- asteroid shield check (may absorb hit)
- particles/text
- mark instance clearing
- global.grid[y][x] = undefined
      |
      v
[Post Clear Cleanup]
- cleanup_grid_ghost_cells()
- apply_grid_gravity()
- cleanup_grid_ghost_cells()
- ensure_planet_core_presence()
- enforce_single_core_in_grid()
      |
      v
[alarm[0] -> next resolve/spawn cycle]
```

## Function Map

- Entry: `settle_matches()` in `scripts/scr_grid_physics/scr_grid_physics.gml`
- Match discovery: `find_matches_in_grid()` in `scripts/scr_match_engine/scr_match_engine.gml`
- Core migration: `migrate_core()` in `scripts/scr_grid_physics/scr_grid_physics.gml`
- Core presence: `ensure_planet_core_presence()` in `scripts/scr_grid_physics/scr_grid_physics.gml`
- Cleanup: `cleanup_grid_ghost_cells()` and `apply_grid_gravity()` in `scripts/scr_grid_physics/scr_grid_physics.gml`

## Sync Note

If we change any ordering in `settle_matches()`, update this file in the same commit.
