# Cluster Core Improvement List

## Main Goal

Make the game simple to understand, but deep to master.

Core sentence:

> Drop minerals onto a spinning planet, aim with a clear ghost/laser preview, build clusters around the core, and use special blocks to create chain-reaction payouts.

## Fix First

1. **Preview clarity**
   - The ghost must never sit directly inside the active placing piece.
   - The landing path needs a clear laser line.
   - The ghost should be an outline/hologram, not another full block.
   - The Next panel and the landing ghost must look like different systems.

2. **Control clarity**
   - Left/Right moves the orbital crane.
   - Up/Down changes preview depth.
   - Space launches.
   - C holds.
   - Z toggles arrow direction on arrow blocks.

3. **Arrow clarity**
   - Color/art stays upright for comfort.
   - Arrows stay planet-locked for truth.
   - The ghost must show arrows the same way real landed blocks do.

4. **Payout clarity**
   - Every clear should show why it paid.
   - Combo text should appear near the board center.
   - Jackpot/Fever should be visually obvious.

5. **Depth without mess**
   - Add complexity through block behavior, not extra controls.
   - Drills, bombs, arrows, shields, and core pressure should all affect the same simple loop.

## Good Steam Direction

- Endless: score and shard grind.
- Story Mode: mechanic-by-mechanic campaign.
- Challenge Mode: handcrafted goals.
- Daily Core: one seeded run per day.
- Reactor Draft: choose modifiers before a run.

## Current Priority

Make the base run readable and fun before adding more modes.

## Implemented Direction

1. **Story Mode**
   - Clear a sequence of planets.
   - Each planet has a block-clear target.
   - Planet difficulty increases by target count, level, and color count.

2. **Placement Contract**
   - The preview starts one cell away from the launcher so it does not sit inside the active piece.
   - Up/Down moves the landing target deeper/shallower.
   - Space places at the visible target.

3. **Bomb Rule**
   - Bombs are first placed into the grid.
   - Then the placed bomb detonates.
   - The core cannot be destroyed by the bomb blast.

4. **Arrow Rule**
   - Horizontal arrow blocks only connect matches left/right.
   - Vertical arrow blocks only connect matches up/down.
   - Z toggles the held arrow direction before placement.
