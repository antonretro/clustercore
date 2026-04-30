# Cluster Core Story Plot and Dialogue Plan

## Premise
You are the last reactor operator in a collapsing orbital belt.
The buried machine called Cluster Core is waking up, and each planet you stabilize brings the system closer to a solar ignition event at the Sun.

## Story Spine
1. Tin Moon: boot sequence and trust building.
2. Rust Garden: instability and scarcity.
3. Casino Comet: volatility and greed temptation.
4. Dead Orbit: survival under hostile conditions.
5. Cluster Core Prime: direct synchronization with the core.
6. Sun Gate (final goal): full ignition choice and ending.

## Tone
- Sci-fi arcade.
- Short, punchy lines.
- Mechanical language with personality.
- Core should feel useful, then unsettling, then transcendent.

## Dialogue System Rules (Paintra-style)
- Compact textbox overlay during Story starts and key transitions.
- Typewriter reveal with:
  - `A`/`Space`/`Enter`: advance.
  - `B`/`Esc`: skip scene.
- Keep lines short (8-20 words) for high gameplay pace.
- Speaker tags:
  - `Operator`
  - `Core`
  - Optional `System`

## Level Objective Blend
Story levels rotate objective archetypes:
- Core clear (premade structure).
- Score target.
- Core count.
- Survival.
- Twist challenge.

Suggested cadence:
- Level 1 intro objective.
- Level 2 mixed objective.
- Level 3 mastery objective.
- Later levels combine two objectives.

## Current Implementation Notes
- Runtime dialogue scenes live in:
  - `scripts/scr_story_dialogue/scr_story_dialogue.gml`
- Intro scenes currently mapped to Story planet index:
  - `intro_0` through `intro_4`
- First entry per scene is tracked and shown once using `global.story_seen_scenes`.
