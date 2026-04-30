# Steam Achievements Integration Guide

## 1) What Was Added
Helper functions were added in:
- `scripts/scr_juice_systems/scr_juice_systems.gml`

New functions:
- `steam_ach_catalog()`
- `steam_ach_init()`
- `steam_ach_unlock(_id)`
- `steam_ach_update()`
- `steam_ach_is_ready()`

These functions queue unlocks safely and only call Steam when stats are ready.

## 2) Minimal Wiring (GameMaker)
Add to game startup (manager create / start):
```gml
steam_ach_init();
```

Call each step:
```gml
steam_ach_update();
```

Unlock from gameplay moments:
```gml
steam_ach_unlock("ACH_FIRST_DROP");
steam_ach_unlock("ACH_CHAIN_3");
steam_ach_unlock("ACH_FEVER");
```

## 3) Suggested Trigger Points
- First lock: `ACH_FIRST_DROP`
- First core clear/migration event: `ACH_CORE_BREAKER`
- Combo chain >= 3: `ACH_CHAIN_3`
- Enter fever: `ACH_FEVER`
- Story world clear: `ACH_STORY_WORLD_1`
- Run score >= 100000: `ACH_SCORE_100K`

## 4) Steamworks Setup
In Steamworks App Admin:
1. Go to Achievements.
2. Create achievements with API names exactly matching code IDs.
3. Upload unlocked/locked icons.
4. Publish changes for the branch you test.

## 5) Achievement Icon Workflow
Use a clean, repeatable pipeline:

1. Canvas:
- Create at `512x512` while designing.
- Export final to `64x64` (Steam classic-safe target) and optionally keep `128x128` master files.

2. Style:
- Strong silhouette, readable at tiny size.
- One focal symbol per achievement.
- High contrast against dark and bright backgrounds.
- Avoid tiny text inside icon.

3. Unlocked vs Locked:
- Unlocked: full color.
- Locked: grayscale/dimmed variant of the same icon.

4. Naming:
- `ACH_FIRST_DROP_on.png`
- `ACH_FIRST_DROP_off.png`

5. Batch Process:
- Keep source PSD/Aseprite/Krita files in `art/achievements/source/`.
- Export finals to `art/achievements/steam/`.

## 6) Fast Icon Set Starter
For current IDs:
- `ACH_FIRST_DROP`: falling block + spark
- `ACH_CORE_BREAKER`: cracked core glyph
- `ACH_CHAIN_3`: three linked rings
- `ACH_FEVER`: overheat meter/flame
- `ACH_STORY_WORLD_1`: moon/flag badge
- `ACH_SCORE_100K`: six-digit ticker badge

## 7) Testing Checklist
- Steam overlay appears in test build.
- `steam_ach_update()` runs each step.
- Achievement IDs match Steamworks exactly.
- Achievements unlock once and persist after restart.
- Locked/unlocked icons display correctly on Steam profile.
