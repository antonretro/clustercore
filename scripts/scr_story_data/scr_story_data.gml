// =============================================================================
// scr_story_data — Story level catalog, palette, and layout placement
// =============================================================================

function story_level_catalog() {
    return [
        // ── TIN MOON (World 0) ── Tutorial progression ─────────────────────
        { world_id: 0, level_id: 0, seed: 1001, palette_count: 3, turn_limit: 35, objective: { type: "clear_board", value: 1 } },
        { world_id: 0, level_id: 1, seed: 1002, palette_count: 3, turn_limit: 40, objective: { type: "clear_board", value: 1 } },
        { world_id: 0, level_id: 2, seed: 1003, palette_count: 3, turn_limit: 45, objective: { type: "clear_board", value: 1 } },
        { world_id: 0, level_id: 3, seed: 1004, palette_count: 3, turn_limit: 50, objective: { type: "clear_board", value: 1 } },
        { world_id: 0, level_id: 4, seed: 1005, palette_count: 3, turn_limit: 60, objective: { type: "clear_board", value: 1 } },
        { world_id: 0, level_id: 5, seed: 1006, palette_count: 4, turn_limit: 55, objective: { type: "clear_board", value: 1 } },
        { world_id: 0, level_id: 6, seed: 1007, palette_count: 4, turn_limit: 45, objective: { type: "clear_board", value: 1 } },
        { world_id: 0, level_id: 7, seed: 1008, palette_count: 4, turn_limit: 50, objective: { type: "clear_board", value: 1 } },
        { world_id: 0, level_id: 8, seed: 1009, palette_count: 4, turn_limit: 55, objective: { type: "clear_board", value: 1 } },
        { world_id: 0, level_id: 9, seed: 1010, palette_count: 5, turn_limit: 65, objective: { type: "clear_board", value: 1 } },

        // ── RUST GARDEN (World 1) ── Locked cages + spores ──────────────────
        { world_id: 1, level_id: 0, seed: 2001, palette_count: 3, turn_limit: 45, objective: { type: "clear_board", value: 1 } },
        { world_id: 1, level_id: 1, seed: 2002, palette_count: 3, turn_limit: 50, objective: { type: "clear_board", value: 1 } },
        { world_id: 1, level_id: 2, seed: 2003, palette_count: 4, turn_limit: 55, objective: { type: "clear_board", value: 1 } },
        { world_id: 1, level_id: 3, seed: 2004, palette_count: 4, objective: { type: "clear_board", value: 1 } },
        { world_id: 1, level_id: 4, seed: 2005, palette_count: 4, turn_limit: 60, objective: { type: "clear_board", value: 1 } },
        { world_id: 1, level_id: 5, seed: 2006, palette_count: 4, objective: { type: "clear_board", value: 1 } },
        { world_id: 1, level_id: 6, seed: 2007, palette_count: 4, turn_limit: 55, objective: { type: "clear_board", value: 1 } },
        { world_id: 1, level_id: 7, seed: 2008, palette_count: 4, turn_limit: 60, objective: { type: "clear_board", value: 1 } },
        { world_id: 1, level_id: 8, seed: 2009, palette_count: 5, turn_limit: 65, objective: { type: "clear_board", value: 1 } },
        { world_id: 1, level_id: 9, seed: 2010, palette_count: 5, turn_limit: 75, objective: { type: "clear_board", value: 1 } },

        // ── CASINO COMET (World 2) ── Multipliers + debt blocks ─────────────
        { world_id: 2, level_id: 0, seed: 3001, palette_count: 4, objective: { type: "clear_board", value: 1 } },
        { world_id: 2, level_id: 1, seed: 3002, palette_count: 4, objective: { type: "clear_board", value: 1 } },
        { world_id: 2, level_id: 2, seed: 3003, palette_count: 4, objective: { type: "clear_board", value: 1 } },
        { world_id: 2, level_id: 3, seed: 3004, palette_count: 4, objective: { type: "clear_board", value: 1 } },
        { world_id: 2, level_id: 4, seed: 3005, palette_count: 5, objective: { type: "clear_board", value: 1 } },
        { world_id: 2, level_id: 5, seed: 3006, palette_count: 5, turn_limit: 60, objective: { type: "clear_board", value: 1 } },
        { world_id: 2, level_id: 6, seed: 3007, palette_count: 5, turn_limit: 50, objective: { type: "clear_board", value: 1 } },
        { world_id: 2, level_id: 7, seed: 3008, palette_count: 5, turn_limit: 55, objective: { type: "clear_board", value: 1 } },
        { world_id: 2, level_id: 8, seed: 3009, palette_count: 5, full_palette: true, objective: { type: "clear_board", value: 1 } },
        { world_id: 2, level_id: 9, seed: 3010, palette_count: 5, full_palette: true, turn_limit: 80, objective: { type: "clear_board", value: 1 } },

        // ── DEAD ORBIT (World 3) ── Gravity + void blocks ───────────────────
        { world_id: 3, level_id: 0, seed: 4001, palette_count: 4, objective: { type: "clear_board", value: 1 } },
        { world_id: 3, level_id: 1, seed: 4002, palette_count: 5, full_palette: true, objective: { type: "clear_board", value: 1 } },
        { world_id: 3, level_id: 2, seed: 4003, palette_count: 5, objective: { type: "clear_board", value: 1 } },
        { world_id: 3, level_id: 3, seed: 4004, palette_count: 5, full_palette: true, objective: { type: "clear_board", value: 1 } },
        { world_id: 3, level_id: 4, seed: 4005, palette_count: 5, full_palette: true, objective: { type: "clear_board", value: 1 } },
        { world_id: 3, level_id: 5, seed: 4006, palette_count: 5, full_palette: true, turn_limit: 65, objective: { type: "clear_board", value: 1 } },
        { world_id: 3, level_id: 6, seed: 4007, palette_count: 5, full_palette: true, objective: { type: "clear_board", value: 1 } },
        { world_id: 3, level_id: 7, seed: 4008, palette_count: 5, full_palette: true, turn_limit: 60, objective: { type: "clear_board", value: 1 } },
        { world_id: 3, level_id: 8, seed: 4009, palette_count: 6, full_palette: true, objective: { type: "clear_board", value: 1 } },
        { world_id: 3, level_id: 9, seed: 4010, palette_count: 6, full_palette: true, turn_limit: 85, objective: { type: "clear_board", value: 1 } },

        // ── CLUSTER CORE (World 4) ── Prism + core keys ─────────────────────
        { world_id: 4, level_id: 0, seed: 5001, palette_count: 5, full_palette: true, objective: { type: "clear_board", value: 1 } },
        { world_id: 4, level_id: 1, seed: 5002, palette_count: 5, full_palette: true, objective: { type: "clear_board", value: 1 } },
        { world_id: 4, level_id: 2, seed: 5003, palette_count: 6, full_palette: true, objective: { type: "clear_board", value: 1 } },
        { world_id: 4, level_id: 3, seed: 5004, palette_count: 6, full_palette: true, objective: { type: "clear_board", value: 1 } },
        { world_id: 4, level_id: 4, seed: 5005, palette_count: 6, full_palette: true, objective: { type: "clear_board", value: 1 } },
        { world_id: 4, level_id: 5, seed: 5006, palette_count: 6, full_palette: true, turn_limit: 70, objective: { type: "clear_board", value: 1 } },
        { world_id: 4, level_id: 6, seed: 5007, palette_count: 6, full_palette: true, objective: { type: "clear_board", value: 1 } },
        { world_id: 4, level_id: 7, seed: 5008, palette_count: 6, full_palette: true, turn_limit: 55, objective: { type: "clear_board", value: 1 } },
        { world_id: 4, level_id: 8, seed: 5009, palette_count: 6, full_palette: true, objective: { type: "clear_board", value: 1 } },
        { world_id: 4, level_id: 9, seed: 5010, palette_count: 6, full_palette: true, turn_limit: 100, objective: { type: "clear_board", value: 1 } }
    ];
}


function story_get_level_def(_worldId, _levelId) {
    var _cat = story_level_catalog();

    for (var i = 0; i < array_length(_cat); i++) {
        var _def = _cat[i];

        if (_def.world_id == _worldId && _def.level_id == _levelId) {
            return _def;
        }
    }

    return undefined;
}


function story_get_level_seed(_worldId, _levelId) {
    var _def = story_get_level_def(_worldId, _levelId);

    if (_def != undefined && variable_struct_exists(_def, "seed")) {
        return _def.seed;
    }

    return 100000 + (_worldId * 1000) + (_levelId * 37);
}


// =============================================================================
// STORY PALETTE / LAYOUT
// =============================================================================

function story_apply_level_palette(_def, _seed) {
    var _oldSeed = random_get_seed();
    random_set_seed(_seed + 7919);

    var _pool = [1, 2, 3, 4, 5, 6];

    for (var i = array_length(_pool) - 1; i > 0; i--) {
        var j = irandom(i);
        var t = _pool[i];
        _pool[i] = _pool[j];
        _pool[j] = t;
    }

    var _count = 3;

    if (_def != undefined && variable_struct_exists(_def, "palette_count")) {
        _count = _def.palette_count;
    }

    if (_def != undefined
    && variable_struct_exists(_def, "full_palette")
    && _def.full_palette) {
        _count = array_length(_pool);
    }

    _count = clamp(_count, 3, array_length(_pool));

    global.activeColors = [];
    global.reserveColors = [];

    for (var c = 0; c < array_length(_pool); c++) {
        if (c < _count) {
            array_push(global.activeColors, _pool[c]);
        } else {
            array_push(global.reserveColors, _pool[c]);
        }
    }

    random_set_seed(_oldSeed);
}


function story_place_cell(_gx, _gy, _type, _cid, _dir = 0) {
    if (!grid_in_bounds(_gx, _gy)) return undefined;
    if (!grid_is_playable(_gx, _gy)) return undefined;
    if (global.grid[_gy][_gx] != undefined) return undefined;

    var _data = make_piece_data(_type, _cid, _dir);

    return place_grid_cell(_gx, _gy, _data);
}


function story_get_layout_settings(_def) {
    var _rank = (_def.world_id * 6) + _def.level_id;

    return {
        rank: _rank,
        target_count: clamp(7 + _rank, 7, 30),
        radius: clamp(2 + floor(_rank / 8), 2, 4),
        metal_rate: clamp(0.03 + (_rank * 0.0035), 0.03, 0.16),
        asteroid_rate: clamp(0.02 + (_rank * 0.0045), 0.02, 0.18)
    };
}


function story_pick_cell_type(_settings) {
    var _roll = random(1);

    if (_roll < _settings.metal_rate) {
        return "metal";
    }

    if (_roll < _settings.metal_rate + _settings.asteroid_rate) {
        return "asteroid";
    }

    return "normal";
}


function story_apply_level_layout(_def) {
    if (_def == undefined) return false;

    var _oldSeed = random_get_seed();
    var _seed = story_get_level_seed(_def.world_id, _def.level_id);

    random_set_seed(_seed);
    story_apply_level_palette(_def, _seed);

    var _cx = floor(global.TOTAL_COLS / 2);
    var _cy = floor(global.TOTAL_ROWS / 2);

    // Place deterministic core first.
    var _coreCid = get_random_active_color_id();
    story_place_cell(_cx, _cy, "core", _coreCid, 0);

    var _settings = story_get_layout_settings(_def);
    var _placed = [];
    var _dirs = [[1,0],[-1,0],[0,1],[0,-1]];

    array_push(_placed, { x: _cx, y: _cy });

    var _guard = 0;

    while (array_length(_placed) - 1 < _settings.target_count && _guard < 900) {
        _guard++;

        var _base = _placed[irandom(array_length(_placed) - 1)];
        var _dir = _dirs[irandom(3)];

        var _rx = _base.x + _dir[0];
        var _ry = _base.y + _dir[1];

        if (!grid_is_playable(_rx, _ry)) continue;
        if (global.grid[_ry][_rx] != undefined) continue;

        if (max(abs(_rx - _cx), abs(_ry - _cy)) > _settings.radius) {
            continue;
        }

        var _type = story_pick_cell_type(_settings);
        var _cid = get_random_active_color_id();

        // Match Prevention: Normal blocks shouldn't start in a 4+ cluster.
        // Arrows are fine as they don't match in clusters anyway.
        if (_type == "normal") {
            var _colorGuard = 0;
            while (check_if_cell_creates_match(_rx, _ry, _cid) && _colorGuard < 10) {
                _cid = get_random_active_color_id();
                _colorGuard++;
            }
        }
        var _blockDir = 0;

        if (_type == "metal") {
            _blockDir = (random(1) > 0.5 ? 1 : 0);
        }

        story_place_cell(_rx, _ry, _type, _cid, _blockDir);

        array_push(_placed, { x: _rx, y: _ry });
    }

    random_set_seed(_oldSeed);

    global.storyLevelSeed = _seed;
    global.storyLevelDef = _def;

    if (_def != undefined) {
        if (variable_struct_exists(_def, "turn_limit")) {
            global.turnLimit = _def.turn_limit;
        } else {
            global.turnLimit = 0;
        }

        if (variable_struct_exists(_def, "objective")) {
            global.storyObjectiveType = _def.objective.type;
            global.storyObjectiveValue = _def.objective.value;

            if (_def.objective.type == "clear_cores") {
                global.storyTarget = _def.objective.value;
            } else if (_def.objective.type == "clear_board") {
                global.storyTarget = 1; // Used as a sentinel, specific logic in story_objective_is_met
            }
        }
    }

    return true;
}
