# Cluster Core Script Audit

Date: 2026-04-29
Scope: All `.gml` scripts and object events in the repository.

## Executive Summary
- Status: Not fully ironed out yet.
- Core loop: Functional and significantly improved.
- Main risk: Runtime inconsistency from duplicated logic and oversized core scripts.
- Recommendation: Run one stabilization sprint before adding more features.

## High-Severity Findings (Fix First)

1. Duplicate `calculate_planet_preview_path` definitions (behavior drift risk)
- Files:
  - `scripts/scr_grid_physics/scr_grid_physics.gml`
  - `scripts/scr_draw_logic/scr_draw_logic.gml`
- Risk:
  - Two different implementations can cause preview/path mismatches and drill/landing confusion depending on load/compile order.
- Action:
  - Keep one canonical implementation only (prefer `scr_grid_physics`), remove or rename the other.

2. Duplicate SFX function suites (symbol collision risk)
- Files:
  - `scripts/scr_sfx/scr_sfx.gml`
  - `scripts/scr_juice_systems/scr_juice_systems.gml`
- Risk:
  - Same function names (`sfx_piece_move`, `sfx_bomb`, etc.) are defined twice.
  - Can lead to unpredictable function resolution or maintenance bugs.
- Action:
  - Keep SFX only in `scr_sfx`; remove duplicate SFX declarations from `scr_juice_systems`.

3. Legacy/parallel gameplay objects still present
- Files:
  - `objects/obj_controls/Create_0.gml`
  - `objects/obj_controls/Step_0.gml`
  - `objects/obj_game_controller/Create_0.gml`
- Risk:
  - These scripts define alternate board/control models unrelated to current live architecture and can cause accidental room-level conflicts.
- Action:
  - Mark as deprecated and remove from active rooms/resources, or isolate into a `legacy/` path.

## Medium-Severity Findings

1. `scr_grid_physics.gml` is too large and high-risk
- File:
  - `scripts/scr_grid_physics/scr_grid_physics.gml`
- Risk:
  - Multi-system file (input, lock, specials, gravity, matching handoff, story transitions, core logic) makes regressions likely.
- Action:
  - Split into:
    - `scr_lock_resolve`
    - `scr_specials_drill_bomb`
    - `scr_gravity`
    - `scr_core_logic`
    - `scr_planet_pathing`

2. Steam achievement calls still rely on Steam functions directly
- File:
  - `scripts/scr_juice_systems/scr_juice_systems.gml`
- Risk:
  - With `global.useSteam=true` in non-Steam runtime, direct calls may still break.
- Action:
  - Add a `platform_service` wrapper and route all Steam calls through one guarded adapter.

3. Dialogue and menu flow are integrated but rely heavily on global state
- Files:
  - `scripts/scr_story_dialogue/scr_story_dialogue.gml`
  - `objects/obj_menu_controller/*.gml`
- Risk:
  - Easy to regress with future menu changes.
- Action:
  - Add a tiny `global.ui_state` struct and centralize scene transitions.

## Low-Severity Findings

1. Encoding artifacts in comments (mojibake)
- Seen in multiple files (garbled dash/box chars).
- Impact: readability only.
- Action: normalize file encoding/comments in a cleanup pass.

2. Minor room-scale hardcoding
- Example: menu uses many fixed coordinates.
- Impact: future resolution scaling complexity.
- Action: move key UI anchors to constants.

## File-by-File Status

### Core Runtime
- `scripts/scr_grid_physics/scr_grid_physics.gml`: Functional but high-risk; needs modular split.
- `scripts/scr_match_engine/scr_match_engine.gml`: Stronger now with line-seed spill logic; keep regression tests on arrow spill/core migration.
- `scripts/scr_match_contracts/scr_match_contracts.gml`: Good single-source contract; keep as authority.
- `scripts/scr_piece_logic/scr_piece_logic.gml`: Good structure; verify orbital bounds and spawn edge cases with tests.

### UX/Systems
- `scripts/scr_hint_system/scr_hint_system.gml`: Crash-prone locals fixed; generally good now.
- `scripts/scr_story_dialogue/scr_story_dialogue.gml`: Good baseline; add save/load scene persistence if needed.
- `scripts/scr_juice_systems/scr_juice_systems.gml`: Good utilities + achievements, but remove duplicate SFX function set.
- `scripts/scr_sfx/scr_sfx.gml`: Keep as sole SFX module.

### Draw Path
- `scripts/scr_draw_logic/scr_draw_logic.gml`: Contains duplicate path function; keep only draw helpers.

### Objects
- `objects/obj_game_manager/*`: Main live gameplay path; stable but dense.
- `objects/obj_menu_controller/*`: Controller/story select integration is good; keep polishing.
- `objects/obj_block/*`: Stable animation/sprite update behavior.
- `objects/obj_controls/*`: Legacy path; deprecate.
- `objects/obj_game_controller/*`: Legacy path; deprecate.
- `objects/obj_ui/Draw_64.gml`: Minimal/no conflict.

## Immediate Priority Checklist (Next 3 Days)
1. Remove duplicate function definitions (`calculate_planet_preview_path`, SFX set).
2. Deprecate or isolate legacy objects (`obj_controls`, `obj_game_controller`).
3. Add regression matrix and run after each patch:
   - Drill direction under all board rotations.
   - 4-line clear includes placed block.
   - Core migration/re-establish correctness.
   - Classic soft-drop DAS/ARR behavior.
4. Begin `scr_grid_physics` modular extraction (no behavior changes).

## Ship Readiness Score (Current)
- Systems stability: 7/10
- Content completeness: 5/10
- Platform readiness: 4/10
- Overall release readiness: 6/10

## Conclusion
The game is in strong progress, but not "perfect" yet. Biggest blockers are structural duplication and high-risk monolithic runtime code. Once those are cleaned and regression-tested, stability will jump fast.
