# Cluster Core v2

A turn-based puzzle game about a tiny planet. Fire coloured blocks inward from any side,
everything falls towards the core, and 3+ of the core's colour touching it breaks a layer.
Walk off the end of a side and the whole planet swings round so you're always shooting up.

## Play
- Arrows aim, Space fire, C hold, Z undo, R restart, Q/E turn, H hint, Esc pause (gamepad works too)
- Campaign: 6 worlds x 6 levels (Mercury tutorial, Venus stones, Earth cages, Mars arrows,
  Jupiter bombs/drills/paint, Neptune one-solution finale). Stars for matching par.
- Endless Orbit: break cores, survive meteors, chase a high score.

## Code (all in `scripts/`, one object `obj_game`, one room `room_main`)
| script | what |
|---|---|
| `scr_cc_rules` | the rules as pure data: board, fire, gravity, matches, hold. No drawing. |
| `scr_cc_levels` | loads `datafiles/levels.txt`, worlds, save data |
| `scr_cc_play` | play screen: aim, animate phases, undo, hints, win/fail, Endless |
| `scr_cc_menu` | title, menu, world map, options |
| `scr_cc_draw` / `scr_cc_fx` | board/block drawing, particles, shake, text |
| `scr_cc_audio` | every sound synthesised at boot (no audio files) |
| `scr_cc_input` | keyboard + gamepad |
| `scr_cc_test` | `--autotest`: replays every level's solution, screenshot tour |

## Tools
- `python tools/ccsim.py [--write]` solves every level (fewest shots = par) and writes par/sol into levels.txt.
  It mirrors `scr_cc_rules` exactly; the in-game self-test checks they agree.
- `python tools/ccgen.py <recipe> [count] [seed]` generates puzzle candidates (stones, cages, arrows, tools, chain, big).
- `powershell -File tools\build.ps1 [-Run] [-Test]` builds with Igor (no IDE) and optionally runs the self-test.

The v1 code is in git history (`master`) and in `../_ClusterCore_backups/before_v2_2026-11-24.zip`.
