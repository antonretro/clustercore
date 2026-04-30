# Cluster Core Full Audit and Next Steps

## Snapshot
- Date: 2026-04-29
- Project state: Playable core loop with major systems integrated, but not full release-ready.
- Priority: Stability first, then content completion, then platform/cert readiness.

## What Is Working
- Three modes exist and launch: `STORY`, `PLANET`, `CLASSIC`.
- Story world select with solar-system presentation is implemented.
- Story level select per world is implemented.
- Dialogue system is integrated in menu and gameplay.
- Hint pulse system is integrated and color-aware.
- Match contracts are centralized (`scr_match_contracts`).
- Core persistence/re-establish behavior exists in Planet/Story.
- Controller support exists in menu and gameplay.
- Steam achievement framework is integrated with `global.useSteam` gating.

## Critical Risks (Must Fix First)
1. `scr_grid_physics.gml` is too large and high-risk for regressions.
2. Steam calls can still be fragile if Steam extension/runtime is unavailable but `global.useSteam` is enabled.
3. No deterministic replay/simulation harness yet.
4. Story is system-complete but content is not yet fully curated/finished for launch scale.

## High-Value Fixes In Progress
- Stability hardening of Steam guards and runtime-safe achievement calls.
- Validation pass for gravity/match/arrow interaction edge cases.

## Release Gaps by Area

### Gameplay Systems
- Needed:
  - Final regression pass for drill path correctness.
  - Final regression pass for arrow line + spill behavior.
  - Confirm gravity only resolves after breaks/special clears.

### Story Content
- Needed:
  - Curated level data per world (minimum 4+ each; target 5-8 each).
  - Objective variants per level set:
    - clear premade core set,
    - score threshold,
    - clear X cores,
    - survive waves,
    - hazard/mutator constraints.

### Platform Readiness
- Needed:
  - Platform service abstraction (`achievement`, `profile`, `cloud save`, `stats`).
  - Steam complete validation.
  - Switch/Xbox prep branch with service adapters and cert-safe flows.

### UX and Accessibility
- Needed:
  - Input remap UI.
  - Colorblind palettes.
  - Expanded settings and controller-only full flow verification.

### QA and Tooling
- Needed:
  - Deterministic seed+input replay harness.
  - Scripted regression checklist for every build.
  - Debug overlays toggle set for pathing/match/core state.

## Recommended Build Plan

## Phase 1 - Systems Stability (Now)
- Harden Steam wrapper calls and fail-safe behavior.
- Split/refactor high-risk sections of `scr_grid_physics`.
- Run manual regression for core gameplay rules.

## Phase 2 - Content Foundation
- Build data-driven world/level tables.
- Ship two fully curated worlds as vertical slice.
- Implement objective scripting framework.

## Phase 3 - Full Campaign
- Complete all launch worlds and level objectives.
- Tune economy, pacing, and difficulty curve.
- Add capstone/challenge beats per world.

## Phase 4 - Launch Prep
- Audio/VFX/UI polish pass.
- Accessibility pass.
- Performance and crash sweep.
- Store/trailer/release checklist completion.

## Definition of "Full Game" for This Project
All must be true:
- No critical progression blockers.
- Story campaign complete and winnable with curated levels.
- Planet and Classic endless modes stable.
- Controller-only navigation works from menu to end-of-run.
- Save/high score/profile data stable.
- Platform APIs abstracted and validated per target.
- Launch QA matrix passed.

## Immediate Next 5 Tasks
1. Harden Steam achievement calls to be runtime-safe even if Steam is unavailable.
2. Lock down gravity/match/arrow regression tests and fix any found edge cases.
3. Split `scr_grid_physics.gml` into smaller scripts by responsibility.
4. Create data files for World 1 and World 2 curated levels.
5. Add objective scripting hooks and wire Story levels to objective completion.

## Suggested Tracking Files
- `docs/RELEASE_TASKBOARD.md` (checkbox roadmap)
- `docs/QA_REGRESSION_CHECKLIST.md` (build-by-build verification)
- `docs/PLATFORM_ABSTRACTION_PLAN.md` (Steam/Switch/Xbox adapters)
