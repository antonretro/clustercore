# Cluster Core — Non-Gameplay Improvements

Everything here improves the game without changing how the core mechanics work.

---

## Sound Design

- Per-color clear SFX — different pitch or timbre for each color so clears feel distinct
- Unique SFX for each special block (drill: piercing whine, bomb: deep thud, dead block: metallic clank)
- Music tempo escalates as level increases — same track, faster BPM
- Combo chain audio — each consecutive chain step raises the pitch of the clear sound slightly

---

## Tutorial / Onboarding

- First run triggers an interactive tutorial that forces specific placements to teach cluster → clear
- Arrow block rule gets its own dedicated step since it's non-obvious
- "Skip tutorial" option shown after first completion
- Brief tooltip on first encounter with each special block type (drill, bomb, dead, asteroid)

---

## Daily Challenge Mode

- Fixed seed each day — everyone gets the same piece sequence
- 5-minute run, score submitted to leaderboard at the end
- No rule changes, no modifiers — pure same-game skill test
- "DAILY" badge shown on the menu next to the mode selector

---

## Replay System

- Record the input stream during a run, save the seed and inputs to a file
- Replay button on the game over screen plays back the run automatically
- "Ghost run" overlay on a new attempt shows your previous best as a semi-transparent shadow

---

## Online Leaderboard

- POST score + mode + planet + combo to a lightweight backend (Supabase free tier works)
- Top 10 shown on the menu screen per mode
- Daily challenge leaderboard resets at midnight, all-time leaderboard is persistent

---

## Controller Support

- Map orbital movement and fire to a gamepad — DAS input structure is already in place
- Left stick or D-pad: move piece along orbit
- A / South button: fire (tap = normal, hold = charge)
- B / East: hold piece, Y / North: rotate, triggers: side jump

---

## Cosmetic Unlocks

- Completing story planets unlocks color palette swaps (e.g. retro green-screen, neon, pastel)
- Board skin variants: clean grid, starfield, circuit board pattern
- Block shape themes: rounded vs sharp pixel corners
- None of these affect match logic or scoring

---

## Quality of Life

- Colorblind mode: add distinct shape overlays on top of block colors
- "Quiet mode" toggle: disables screen shake and flash effects
- Piece statistics screen on game over (how many of each type appeared, accuracy %, fastest clear)
- High score per mode (Planet, Story, Classic tracked separately)
