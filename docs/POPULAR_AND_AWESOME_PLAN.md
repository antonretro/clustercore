# Cluster Core: Popular And Awesome Plan

## The Pitch

Cluster Core should feel like a tiny arcade puzzle game that secretly has teeth.

The simple pitch:

> Drop single blocks into a narrow reactor grid, clear same-color clusters, trigger drills and bombs, survive the rising pressure, and spend Core Shards to permanently evolve the machine.

The Steam pitch:

> A fast, juicy incremental puzzle arcade game where every clear feeds a strange machine. Build wild chain reactions, upgrade your Core, unlock rule-bending modes, and push deeper into a story campaign about a reactor that wants to become alive.

## The Design Spine

The game needs one strong identity, not a pile of random features.

The spine:

1. **Arcade puzzle clarity**
   - Single-piece falling blocks.
   - Match 4+ connected colors.
   - Directional metal pieces change matching rules.
   - Special pieces create big readable moments.

2. **Incremental dopamine**
   - Every run earns Core Shards.
   - Core Shards buy permanent upgrades.
   - Upgrades change how runs feel, not just numbers.
   - The player always has a near-term goal after losing.

3. **Machine fantasy**
   - The player is not just clearing blocks; they are tuning a reactor.
   - UI should feel like a clean arcade control panel.
   - Drills, bombs, beams, overclocks, cores, pressure, shards.

4. **Depth through rule mutation**
   - New modes should remix the grid, pieces, goals, or hazards.
   - Avoid dozens of shallow modes.
   - Prefer a few modes with unique rules and progression.

## The Standout Idea

Most falling-block puzzle games are about survival.
Cluster Core should be about **building a machine through survival**.

The unique hook:

> Every run charges the Core. The Core permanently mutates your future runs, unlocking stronger tools but also stranger hazards.

Examples:

- Upgrade drills so they pierce deeper, split columns, or crack dead metal.
- Upgrade bombs so they chain, pulse, or convert colors.
- Unlock “Core Laws” that modify runs:
  - First clear each run is doubled.
  - Every 6th piece is a drill.
  - Combos charge an emergency purge.
  - Dead metal sometimes becomes a wild block.

This makes it incremental without turning it into an idle game.

## Core Game Modes

### 1. Endless

The main arcade mode.

Goal:

- Survive as long as possible.
- Earn Core Shards.
- Chase score, level, and combo records.

Depth:

- Increasing speed.
- More hazards after level milestones.
- Color rotation.
- Special-piece probabilities affected by upgrades.

### 2. Story Mode

This should be the “real game” for Steam.

Structure:

- Chapters made of short puzzle/arcade stages.
- Each chapter introduces one mechanic or twist.
- Dialogue can be delivered through a compact Paintra-style text box.
- Boss boards are special rules, not action bosses.

Story concept:

- You are booting up a buried machine called the Cluster Core.
- The Core starts as a tool, then starts asking for more.
- Each region of the machine has a different rule mutation.

Example chapters:

- **Ignition:** basic matching and drill tutorial.
- **Pressure:** death line, speed, and emergency clears.
- **Rust Layer:** dead metal and directional metal.
- **Signal Bloom:** color swapping and combo routing.
- **Core Voice:** the machine starts changing rules mid-run.

### 3. Challenges

Short handcrafted missions.

Good for:

- Teaching mechanics.
- Giving completion goals.
- Steam achievements.

Examples:

- Clear 50 blocks.
- Make a 3x combo.
- Use 3 drills in one run.
- Survive with only 3 active colors.
- Clear a diagonal twice.

### 4. Daily Core

This is a popularity feature.

Rules:

- Same seed for everyone each day.
- One attempt or limited attempts.
- Leaderboard-ready score.
- Daily modifier, like “Drills are common, bombs are rare.”

Why it matters:

- Gives players a reason to return.
- Makes stream clips and screenshots easier.
- Adds community without needing huge multiplayer tech.

### 5. Reactor Draft

An advanced mode for replayability.

Before a run, draft 3 Core Laws from a random set.

Example laws:

- “Every combo grants +2 seconds.”
- “Bombs clear diagonals.”
- “Drills split into adjacent columns.”
- “Score is doubled, but dead metal appears earlier.”

This can become the deep roguelite mode later.

## Progression Systems

### Core Shards

Earned from:

- Clears.
- Combos.
- Drills.
- Missions.
- End-of-run score.

Spent on:

- Drill upgrades.
- Bomb upgrades.
- Special-piece frequency.
- Score multipliers.
- New Core Laws.
- Story chapter unlocks.

### Upgrade Rules

Good upgrades:

- Change decisions.
- Create visible effects.
- Make the player want “one more run.”

Weak upgrades:

- Tiny invisible percentages.
- Too many flat multipliers.
- Anything that makes the game play itself.

## Juice Checklist

Every important action should have feedback:

- Move: light tick.
- Lock: thump.
- Clear: burst, score pop, sound chord.
- Combo: bigger text, stronger shake, pitch rising.
- Drill: beam trail, column rumble, white flash.
- Bomb: radial shock, low boom, debris.
- Level up: UI pulse and color swap warning.
- Game over: readable slow-down and score summary.

Keep the game simple, but make every success feel expensive.

## Steam Readiness

Minimum Steam-worthy feature set:

- Endless mode.
- Story Mode chapter 1.
- 30-50 challenges.
- Permanent Core Lab upgrades.
- Daily Core or seeded runs.
- Save data.
- Options menu.
- Keyboard and controller support.
- Steam achievements.
- Leaderboards if possible.
- Clean trailer-friendly visuals.

Steam page hook:

- 10-second trailer should show:
  - Simple drop.
  - Match clear.
  - Drill column.
  - Combo chain.
  - Core Lab upgrade.
  - Weird story-mode board.

## Roadmap

### Phase 1: Foundation

- Separate `room_menu` and `room_game`.
- Make drills truly satisfying.
- Add Core Shards and basic upgrades.
- Centralize text/UI copy.
- Make restart/menu flow clean.

### Phase 2: Depth

- Add 8-12 meaningful upgrades.
- Add run modifiers.
- Add challenge progression.
- Add proper settings and save system.
- Add better tutorialization.

### Phase 3: Story Mode Prototype

- Add `room_story`.
- Add dialogue/text box system.
- Build 5 short stages.
- Add one “boss board” with a unique rule.

### Phase 4: Steam Demo

- Polish visuals and audio.
- Add title screen and trailer capture mode.
- Add achievements locally first.
- Build 20-30 minutes of strong content.
- Release demo for feedback.

## The Rule

When adding anything, ask:

> Does this make the player understand the game better, make a better decision, or want one more run?

If yes, build it.
If no, save it for later.
