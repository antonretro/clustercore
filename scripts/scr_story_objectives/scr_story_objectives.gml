// =============================================================================
// scr_story_objectives - Story mode progression and win conditions
// =============================================================================

function story_objective_is_met() {
    if (global.gameMode != "STORY") return false;

    var _value = max(1, global.storyObjectiveValue);

    if (global.storyObjectiveType == "score") {
        return global.score >= _value;
    }

    if (global.storyObjectiveType == "survive_waves") {
        return global.storyWavesSurvived >= _value;
    }

    if (global.storyObjectiveType == "collect_shards") {
        return global.storyShardsCollected >= _value;
    }

    if (global.storyObjectiveType == "clear_board") {
        // 1. Grid Check: Ensure the logical grid is empty of debris
        var _count = 0;
        for (var _y = 0; _y < global.TOTAL_ROWS; _y++) {
            for (var _x = 0; _x < global.TOTAL_COLS; _x++) {
                var _c = global.grid[_y][_x];
                if (_c != undefined && _c.type != "core") {
                    _count++;
                }
            }
        }
        
        // 2. Physical Sweep: Ensure no actual block objects are lingering
        var _physCount = 0;
        with (obj_block) {
            if (type != "core" && !clearing) _physCount++;
        }
        
        // Only return true if BOTH the data and the objects are truly, completely gone
        if (_count == 0 && _physCount == 0) {
            // Final check: in clear_board mode, we even want the core gone
            var _coreExists = false;
            with(obj_block) { if (!clearing) _coreExists = true; }
            if (!_coreExists) return true;
        }
        return false;
    }

    if (global.storyObjectiveType == "clear_cores") {
        return global.storyCleared >= max(1, global.storyTarget);
    }

    // Default for score/time/waves
    return global.storyCleared >= max(1, global.storyTarget);
}


function story_trigger_level_complete() {
    if (global.gameState == "LEVEL_COMPLETE" || global.gameState == "FINISHING_LEVEL") return;
    
    global.gameState = "FINISHING_LEVEL";
    global.finishTimer = 180; // ~3 seconds of cinematic animation
    
    // Calculate Rank and Bonus
    global.storyBonus = 0;
    global.storyRank = "D";
    
    if (global.turnLimit > 0) {
        var _rem = max(0, global.turnLimit - global.turnCount);
        global.storyBonus = _rem * 500;
        global.score += global.storyBonus;
        
        var _pct = _rem / global.turnLimit;
        if (_pct >= 0.70) global.storyRank = "S";
        else if (_pct >= 0.50) global.storyRank = "A";
        else if (_pct >= 0.30) global.storyRank = "B";
        else if (_pct >= 0.10) global.storyRank = "C";
    } else {
        global.storyRank = "A";
    }

    // TRIGGER DRAMATIC CLEANUP
    global.flashAlpha = 1.0;
    global.restoredTilesAlpha = 0;
    generate_restored_planet_map();
    sfx_fever(); // Big victory sound
    
    // Trigger graceful cleanup of all blocks
    with(obj_block) {
        if (type == "core") {
            // Give the core a final dramatic burst
            create_particles(x, y, color, 40);
            clearing = true;
            death_timer = 40; // Specific long death for the core
        } else {
            // Standard vaporize for debris
            if (!clearing) {
                clearing = true;
                create_particles(x, y, color, 8);
            }
        }
    }
    
    // Clear grid data
    for (var _gy = 0; _gy < global.TOTAL_ROWS; _gy++) {
        for (var _gx = 0; _gx < global.TOTAL_COLS; _gx++) {
            global.grid[_gy][_gx] = undefined;
        }
    }
    
    create_floating_text_ext(global.GAME_W * 0.5, global.GAME_H * 0.34, "PLANET PURIFIED", global.COLOR_GLOW, 2.5);
}


function story_advance_planet() {
    var _prevPlanet = global.storyPlanet;
    global.storyLevel++;

    if (global.storyLevel >= 10) {
        global.storyPlanet++;
        global.storyLevel = 0;
    }

    // Set gameState so we don't re-enter the FINISHING_LEVEL cinematic loop.
    global.gameState = "LEVEL_COMPLETE";
    global.level_transition_cooldown = 40;

    if (_prevPlanet == 0 && global.storyPlanet >= 1) {
        steam_ach_unlock("ACH_STORY_WORLD_1");
    }

    if (global.storyPlanet >= array_length(global.storyPlanets)) {
        global.storyComplete = true;
        global.gameState = "GAMEOVER";
        create_floating_text_ext(global.GAME_W * 0.5, global.GAME_H * 0.34, "STORY CLEAR!", c_yellow, 2.4);
        return;
    }
}


function generate_restored_planet_map() {
    random_set_seed(global.storyLevelSeed + 777);
    
    for (var _y = 0; _y < global.TOTAL_ROWS; _y++) {
        for (var _x = 0; _x < global.TOTAL_COLS; _x++) {
            if (!grid_cell_is_playable(_x, _y)) {
                global.restoredMap[_y][_x] = { type: 0, variant: 0 }; 
                continue;
            }
            
            var _r = random(100);
            var _type = 1; // Default Ocean
            if (_r > 30)  _type = 2; // Forest
            if (_r > 65)  _type = 3; // Mountain
            if (_r > 85)  _type = 4; // Desert
            if (_r > 95)  _type = 5; // Tundra
            
            global.restoredMap[_y][_x] = {
                type: _type,
                variant: irandom(3),
                alpha: 0
            };
        }
    }
}
