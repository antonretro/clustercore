# Steam Deck Verified Checklist (Cluster Core)

## 1) Steamworks + Build Basics
- Enable Steamworks extension in GameMaker and confirm Steam overlay appears in desktop and Deck test builds.
- Ensure achievements are created in Steamworks with exact API names:
  - `ACH_FIRST_DROP`
  - `ACH_CORE_BREAKER`
  - `ACH_CHAIN_3`
  - `ACH_FEVER`
  - `ACH_STORY_WORLD_1`
  - `ACH_SCORE_100K`
- Upload Linux-compatible build (or Proton-tested Windows build) to a Steam beta branch for Deck QA.

## 2) Deck Input Requirements
- Full gamepad support from boot:
  - Menu navigation
  - Gameplay actions
  - Pause/restart/exit flows
- No keyboard-required prompts during normal play.
- Verify mapping on Deck defaults:
  - `A`: fire / confirm
  - `B`: hold/swap
  - `D-Pad / Left Stick`: orbital movement
  - `Shoulders`: rotate side
  - `Start`: pause

## 3) Readability (1280x800)
- Test at native Deck resolution (`1280x800`, 16:10).
- Confirm all critical HUD text is readable without squinting:
  - Score
  - Objective/target
  - Timer/fever/combo
  - Game-over options
- Confirm colorblind-safe palette option is available before launch.

## 4) Performance + Stability
- Hold steady frame pacing during:
  - Dense chain clears
  - Drill/bomb effects
  - Fever moments
- Check memory and stutter after 30+ minutes of continuous play.
- Resume-from-suspend should return to active gameplay without input loss.

## 5) Proton/Compatibility Pass
- Clean boot from Steam library on Deck.
- No external launcher or extra dialogs.
- No crash on:
  - Room transitions
  - Pause/resume
  - End-run restart loop

## 6) Store + Review Readiness
- Add controller support flags correctly on Steam Store.
- Upload Deck gameplay captures/screenshots.
- Run through Valve review checklist before requesting Verified status.

## 7) Quick Manual Test Script
1. Start game on Deck with no keyboard attached.
2. Complete one short run, unlock one achievement, and quit.
3. Reopen game and confirm achievement persistence.
4. Suspend Deck mid-run, resume, then finish run.
5. Navigate all menus and settings via controller only.
