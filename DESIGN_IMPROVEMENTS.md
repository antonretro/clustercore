# Cluster Core — Design Improvement Document

---

## 1. The Orbital Rotation Problem

This is the most important issue in the game.

Right now, rotating the board is probably almost always correct. If you can always spin to find a better angle, rotation isn't a decision — it's just "extra free moves before placing." That makes the orbital mechanic feel like a helper rather than the game's identity.

**What needs to happen:** Rotation should sometimes hurt you. Ideas:
- Gravity blocks that shift the entire board contents when you rotate (pieces slide, stacks collapse)
- A cooldown bar that fills when you rotate — rotate too much and pieces start dropping faster
- Specific level objectives that punish rotation ("survive X turns without rotating")
- Locked-gravity levels where rotation is disabled entirely, forcing you to appreciate what it does by taking it away

The goal: every rotation should feel like a tradeoff, not a free look around.

---

## 2. Block Roster — Sequence of Introduction

You have 12+ block types. Introducing them in the wrong order, or too fast, kills the learning curve. Suggested world-by-world rollout:

| World | New Mechanic Introduced | Should NOT appear yet |
|-------|------------------------|-----------------------|
| Tin Moon (W1) | Color blocks, Metal Arrows, Wildcards | Everything else |
| Rust Garden (W2) | Locked Cages, Asteroids | Void, Prisms, Debt |
| Casino Comet (W3) | Multipliers, Core Gems | Void, Debt |
| Dead Orbit (W4) | Void Spores, Gravity blocks, Dead Metal | Prisms, Debt |
| Cluster Core (W5) | Prisms, Debt blocks, Core Keys | (everything active) |

If players are seeing void spores in World 1, that's a problem. If Cluster Core doesn't feel meaningfully harder than Dead Orbit, that's also a problem.

**Within each world:** Level 1 should be the tutorial for that world's new mechanic. Level 10 (the "Purge" level) should be a stress test of everything introduced so far.

---

## 3. Arrow Blocks Don't Feel Different Enough

Right now: a metal arrow clears in a line of 4+ along its axis. In practice, players probably just treat it like a slightly pickier color block and place it where a line seems available.

The mechanic should create a different *thought process*, not just a different *clear condition*. Ideas:
- Arrow blocks that, when cleared, shoot a beam destroying everything in their line (like a drill, but triggered by matching). This would make placing arrows a setup play — "I'm positioning this for a big clear later."
- Cross arrows that can anchor a line match AND a cluster match simultaneously, creating genuine dual-purpose pieces
- Arrow blocks that don't match color at all — they only clear via their line mechanic, ignoring color. This makes them wild cards for line clears but useless for clusters.

---

## 4. Dialogue Is Too Sparse For a Story Mode

50 levels with a named story and five worlds needs more connective tissue. Currently: one backstory intro, and planet-select snippets. That's a framing, not a story.

**Minimum viable story beats needed:**
- Each world: 1 intro scene (arriving at the planet), 1 mid-point scene (around level 5, something goes wrong), 1 exit scene (world cleared or failed)
- That's 15 scenes for 5 worlds. Short — even 4-6 lines of dialogue each is enough.
- The Purge levels (10th level of each world) should feel climactic. Right now "Tin Purge", "Rust Purge" etc. are just names — there's nothing in the system that makes level 10 feel different from level 7.

**What the dialogue should do:**
- Establish why THIS planet matters (Tin Moon: first corruption signal. Casino Comet: someone's running a racket here.)
- Give the player a reason to feel something when they clear it
- Seed lore about Cluster Core (the final world) early so arriving there feels earned

The sci-fi GRU framing is good — lean into it. Mission briefings, system alerts, crew banter. Don't need voiced audio. Text is enough.

---

## 5. Level Design Principles (Currently Unknown)

The levels have great names but from the code, objectives are structs: `clear_board`, `clear_cores`, `score`, `survive_waves`, `collect_shards`. The risk is that all 50 levels are "clear_board" with slightly different board setups.

**Each level should have an identity:**
- A specific board layout that creates a puzzle (pre-placed blocks forcing a specific strategy)
- An objective that isn't just "clear everything"
- At least one "aha moment" — a board state where the intended solution clicks

**Suggested objective distribution per 10-level world:**
- Levels 1-3: `clear_cores` or `score` (gentle, forgiving)
- Levels 4-6: `collect_shards` with a twist mechanic
- Levels 7-9: `survive_waves` or turn-limited variants
- Level 10 (Purge): `clear_board` with the hardest board layout in the world

---

## 6. Endless Modes Are Hidden Too Deep

Planet Endless unlocks after completing Tin Moon. Classic Endless after Rust Garden. That means 10-20 levels of story before players see the endless modes at all.

Endless modes in puzzle games are often where the replayability lives. Consider:
- Show both endless modes on the main menu as locked but visible from day one (you already do this with the [LOCKED] label — good)
- Unlock Planet Endless after completing just 3 levels of Tin Moon, not the whole world
- Add a daily score challenge to endless mode so players have a reason to return

---

## 7. Combo System Needs Visibility

The combo system exists (x2, x3 multipliers for chained clears) but it's not clear if players understand it or even notice it. Combos should feel exciting, not like a background calculation.

**Improvements:**
- A visible combo counter that grows on screen during a chain (currently unclear if this exists in the HUD)
- The "ULTRA BLAST!" floating text pattern is correct — do the same for every combo tier: "DOUBLE!", "TRIPLE!", "CHAIN x4!" with escalating colors and scale
- A combo meter (progress bar) that depletes between turns — keeps it in focus

---

## 8. The Refabricator Loop Needs a Reason

Currently: collect 25 shards → get 1 gem → spend gems in shop. This loop only works if the shop has things worth buying that tangibly change how the game feels.

If the shop sells passive buffs ("+1 turn limit per level") it's forgettable. If it sells active pieces that show up in your queue (a guaranteed drill every 10 pieces, or a wildcard that appears every 5 pieces), players will care about the economy.

**The economy needs to answer:** "Why am I collecting shards right now, on this level, today?" If the answer isn't immediate and obvious, players ignore it.

---

## 9. Quick Wins (Low Effort, High Impact)

These are small changes that would meaningfully improve the feel:

- **Purge levels should have a different board tint or visual treatment** — make level 10 of each world look different from levels 1-9. Even a red tint on the background would signal "this is the boss level."
- **The loading bar between save slots and main menu** feels out of place for a puzzle game. Either cut it or replace it with something thematic (a "SYNCING GALACTIC DATA..." with a planet spinning).
- **Achievement notifications** — getting an achievement should interrupt the screen with a proper popup, not silently unlock in a list. Even a 2-second banner at the bottom of the screen.
- **The hint pulse system** fires every 3 seconds but only lasts 30 frames (0.5s). Extend the pulse to 60 frames so players actually notice it.
- **Dead metal blocks** — "Cannot be matched, remove with drills or bombs." If there's no drill or bomb in the queue, this block is permanently impassable. Either give players a way to earn drills, or make dead metal rare enough that it never blocks the only path.

---

## Priority Order

| Priority | Item | Effort |
|----------|------|--------|
| 1 | Make rotation a meaningful tradeoff | High |
| 2 | Ensure block introduction is paced per world | Medium |
| 3 | Write 15 story dialogue scenes (3 per world) | Medium |
| 4 | Audit all 50 levels — does each have a unique identity? | High |
| 5 | Combo visibility (counter, floating text, meter) | Low |
| 6 | Unlock endless modes earlier | Low |
| 7 | Make shop items tangible and impactful | Medium |
| 8 | Purge level visual treatment | Low |
| 9 | Extend hint pulse to 60 frames | Low |
