# Cluster Core: Game Design Bible v2

## 1) Product Vision
Cluster Core is a high-clarity arcade puzzle-action game about dropping mineral blocks onto a rotating planet, shaping color structures around a living core, and detonating chain-reaction payouts.

Player promise:
- Learn in 60 seconds.
- Feel clever by minute 5.
- Still discover new mastery at hour 20.

Commercial promise:
- Strong "one more run" loop.
- Distinct visual + mechanical identity for trailer discoverability.
- Scalable content model for post-launch seasons.

## 2) Design Pillars
1. Readable chaos.
- Explosive moments can be intense, but player intent is always legible.
- Every clear has a visible cause.

2. High agency.
- Player controls aim, lane, timing, depth, hold, and risk.
- Fewer random losses, more owned mistakes.

3. Momentum economy.
- Score, combo, shards, jackpot/fever, and progression reinforce each other.
- Every run contributes to meta growth.

4. Depth through rule mutation.
- New depth comes from changing interactions, not adding complicated controls.

5. Platform confidence.
- Controller-first UX, deterministic core logic, and cert-safe systems.

## 3) Core Fantasy
You are operating a dangerous planetary reactor.
The core is not just an objective; it is the machine's "heartbeat" that redirects strategy.

Game feel keywords:
- Tense
- Satisfying
- Punchy
- Fair
- Replayable

## 4) Core Loop
1. Orbit and aim from staging ring/lane.
2. Commit shot and lock block.
3. Resolve specials (drill, bomb, directional, hazards).
4. Resolve matches and cascades.
5. Apply gravity/settle.
6. Score + shards + progression.
7. Repeat until objective complete or fail state.

Timing targets:
- Micro decision cadence: 1-3s.
- Burst event cadence: 10-20s.
- Clutch event cadence: 45-90s.

## 5) Gameplay Contracts (Non-Negotiables)
1. Preview truthfulness.
- Ghost and path must always match real landing result.

2. Core persistence.
- Planet/Story always maintains a core presence.
- If migration candidate is unavailable, re-establish immediately.

3. Match clarity.
- One source of truth for color equivalence and axis legality.
- Directional blocks are visually and behaviorally consistent.

4. Input fairness.
- No hidden input modes.
- DAS/ARR behavior is predictable and mode-appropriate.

5. Deterministic simulation.
- Seed + input stream reproduces identical board outcomes.

## 6) Mode Structure
### Story Campaign
- Curated progression with world identities and mechanic onboarding.
- Includes intro, mixed, mastery, and capstone beats per mechanic.

### Endless Planet
- Primary score-chase mode.
- Difficulty ramps through piece pool, hazards, and speed pressure.

### Classic
- Simpler geometry and traditional line pressure.
- Shares economy and progression hooks where possible.

### Daily/Challenge
- Fixed seed and fixed mutators.
- Supports community comparison and retention.

## 7) World Model (Launch)
1. Tin Moon: onboarding and confidence.
2. Rust Garden: resource pressure and lane discipline.
3. Casino Comet: variance and payout gambles.
4. Dead Orbit: hazard-heavy execution.
5. Cluster Core Prime: full-system mastery.

Per world:
- 8-12 levels.
- 1 mechanic intro.
- 1 miniboss rule challenge.
- 1 capstone challenge.

## 8) Objective Archetypes
- Clear Target: clear N cores.
- Score Attack: reach threshold within pressure constraints.
- Survival: survive T waves.
- Puzzle Seed: solve handcrafted board state.
- Hazard Run: clear under forced mutators.

## 9) Systems and Economy
### In-run systems
- Score.
- Combo chain.
- Jackpot/Fever pressure.
- Risk multipliers from aggressive play.

### Meta systems
- Shards as persistent currency.
- Unlock trees:
  - Utility (hold+, queue info, reroll).
  - World keys / progression gates.
  - Cosmetic tracks.

### Reward design rules
- Rewards must alter decisions, not just inflate numbers.
- Milestone rewards must be visible in next run.

## 10) Difficulty and Balance Curves
Per-world curve:
- Levels 1-3: onboarding.
- Levels 4-7: mixed pressure.
- Levels 8-10+: mastery checks.

Global curve levers:
- Active color count.
- Hazard frequency.
- Special rates.
- Timer strictness.
- Objective strictness.

Balance telemetry targets:
- First big chain by minute 3 median.
- Story level fail rate target band: 35-55% on first attempt.
- Daily completion target band: 20-40%.

## 11) Expansion Priorities
Priority A (ship-critical):
- Data-driven mutator framework.
- Tutorial/hint clarity.
- Objective scripting framework.
- Replay/seed support.

Priority B (high value):
- New specials (converter, anchor, pulse).
- Multi-step boss conditions.

Priority C (depth/polish):
- Perk draft between levels.
- Mastery stars/medals.
- Accessibility modifiers.

## 12) UX and Readability Standards
- Core state always explicit.
- Landing and match confidence cues always visible.
- Fail state explains why.
- Objective always visible during active play.
- Hinting should be actionable and periodic, not spammy.

Onboarding requirements:
- First 3 minutes teach orbit, fire timing, matching around core, and one special.
- Every mechanic gets intro, mixed, mastery exposure.

## 13) Content Pipeline Schema
Level data fields:
- world_id
- level_id
- seed or handcrafted state
- objective
- mutators
- rewards
- intro text / hint script id

Piece pool fields:
- active colors
- special weights
- hazard phase timings
- banned combos (optional safety list)

## 14) Technical Roadmap
1. Split `scr_grid_physics.gml` by responsibility:
- lock/resolve
- gravity
- planet pathing
- fail states

2. Maintain single source for preview/path logic.
3. Keep formal match contracts centralized.
4. Build deterministic harness for seeded replay.
5. Add debug overlays:
- lane bounds
- match candidates
- core migration/re-establish target

## 15) QA Matrix
Coverage axes:
- Modes: Story / Endless / Classic / Challenge.
- Inputs: keyboard / gamepad.
- States: pause, hold swap, timer expiry, edge placements.
- Specials: isolated and mixed interactions.
- Core interactions: migration, re-establish, clear correctness.

Regression tests:
- Core color id integrity.
- Placement determinism within tick.
- Drill direction under all rotations.
- Preview truthfulness in Classic and Planet.
- Achievement unlock guards for non-Steam targets.

## 16) Platform Readiness
### Steam
- Achievements wired and validated.
- Controller-first UX.
- Save stability and crash resilience.

### Steam Deck
- 1280x800 readability.
- Suspend/resume robustness.
- Full gamepad-only navigation from boot.

### Console path (Switch/Xbox/PlayStation)
- Service abstraction layer (achievements/cloud/profile).
- TRC/TCR-safe pause, disconnect, and account flows.
- Memory/performance budgets tracked continuously.

## 17) Milestones
### Milestone 1: Systems Stability (1-2 weeks)
- Resolve placement/match consistency bugs.
- Finalize preview correctness.
- Add debug toggles.

### Milestone 2: Content Foundation (2-3 weeks)
- Data schema finalized.
- Two worlds fully playable.
- Objective scripting shipped.

### Milestone 3: Full Campaign (3-5 weeks)
- All launch worlds and capstones.
- Economy tuning pass.
- Difficulty and pacing pass.

### Milestone 4: Launch Prep (2-4 weeks)
- Audio/VFX/UI polish.
- Accessibility pass.
- Performance/stability sweep.
- Store assets + checklist completion.

## 18) Launch Gates
Must pass before release:
- No critical progression blockers.
- Save migration stable.
- Input remap and controller support complete.
- Colorblind-safe palette shipped.
- Daily/seed challenge functional.
- Minimum telemetry or robust local run stats.

## 19) North-Star Metrics
- D1 replay rate.
- Average session length.
- Run completion by world.
- Time to first major chain.
- Daily challenge participation.

Interpretation rule:
If these improve while players describe the game as readable, fair, and satisfying, the design is succeeding.

## 20) Kill Criteria
Any feature is delayed or cut if it:
- Reduces readability.
- Adds controls without meaningful agency.
- Increases implementation risk without improving retention.
- Slows launch-critical stability work.
