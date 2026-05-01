// =============================================================================
// scr_piece_logic — spawning, holding, orbital positioning, story layout
// =============================================================================
//
// PLANET/STORY coordinate contract:
// - TOTAL grid is 11x11.
// - Playable area is x=1..9, y=1..9.
// - Staging ring is the outside edge:
//     side 0: top    y=0,  x=1..9
//     side 1: right  x=10, y=1..9
//     side 2: bottom y=10, x=9..1
//     side 3: left   x=0,  y=9..1
//
// Block instance world pixels:
//   inst.x = (grid_x - global.HIDDEN_SIDES) * 16
//   inst.y = (grid_y - global.HIDDEN_ROWS)  * 16
//
// Draw event handles PIXEL_SCALE and board offset.
// =============================================================================


// =============================================================================
// BASIC GRID HELPERS
// =============================================================================

function piece_is_planet_mode() {
    return (global.gameMode == "PLANET" || global.gameMode == "STORY");
}


function normalize_side(_side) {
    var _s = _side mod 4;
    if (_s < 0) _s += 4;
    return _s;
}


function playable_min_x() {
    return global.HIDDEN_SIDES;
}


function playable_max_x() {
    return global.TOTAL_COLS - global.HIDDEN_SIDES - 1;
}


function playable_min_y() {
    return global.HIDDEN_ROWS;
}


function playable_max_y() {
    return global.TOTAL_ROWS - global.HIDDEN_ROWS - 1;
}


function grid_in_bounds(_gx, _gy) {
    return (_gx >= 0 && _gx < global.TOTAL_COLS && _gy >= 0 && _gy < global.TOTAL_ROWS);
}


function grid_is_playable(_gx, _gy) {
    if (_gx < playable_min_x()) return false;
    if (_gx > playable_max_x()) return false;
    if (_gy < playable_min_y()) return false;
    if (_gy > playable_max_y()) return false;
    return true;
}


function grid_cell_empty(_gx, _gy) {
    if (!grid_in_bounds(_gx, _gy)) return false;
    return global.grid[_gy][_gx] == undefined;
}


// =============================================================================
// ORBITAL POSITIONING
// =============================================================================

function get_orbital_pos(_side, _orbX) {
    var _s = normalize_side(_side);
    var _i = clamp(_orbX, 0, global.COLS - 1);

    var _left   = playable_min_x();
    var _right  = playable_max_x();
    var _top    = playable_min_y();
    var _bottom = playable_max_y();

    // Staging ring is one cell outside playable area.
    if (_s == 0) {
        return {
            x: _left + _i,
            y: _top - 1
        };
    }

    if (_s == 1) {
        return {
            x: _right + 1,
            y: _top + _i
        };
    }

    if (_s == 2) {
        return {
            x: _right - _i,
            y: _bottom + 1
        };
    }

    return {
        x: _left - 1,
        y: _bottom - _i
    };
}


// Returns the playable edge cell for this side/lane.
// This is not the staging cell. It is the first playable cell seen from that side.
function get_orbital_lane_edge_pos(_side, _orbX) {
    var _s = normalize_side(_side);
    var _i = clamp(_orbX, 0, global.COLS - 1);

    var _left   = playable_min_x();
    var _right  = playable_max_x();
    var _top    = playable_min_y();
    var _bottom = playable_max_y();

    if (_s == 0) {
        return {
            x: _left + _i,
            y: _top
        };
    }

    if (_s == 1) {
        return {
            x: _right,
            y: _top + _i
        };
    }

    if (_s == 2) {
        return {
            x: _right - _i,
            y: _bottom
        };
    }

    return {
        x: _left,
        y: _bottom - _i
    };
}


// Returns direction from staging ring into the board.
function get_orbital_inward_dir(_side) {
    var _s = normalize_side(_side);

    if (_s == 0) return { x: 0,  y: 1  };
    if (_s == 1) return { x: -1, y: 0  };
    if (_s == 2) return { x: 0,  y: -1 };

    return { x: 1, y: 0 };
}


// Adaptive lane window based on occupied silhouette from current orbital side.
function get_orbital_lane_bounds(_anchorX = -1) {
    var _cols = max(1, global.COLS);
    var _minIdx = _cols - 1;
    var _maxIdx = 0;
    var _found = false;

    var _side = normalize_side(global.orbitalSide);
    var _dir = get_orbital_inward_dir(_side);

    for (var _i = 0; _i < _cols; _i++) {
        var _edge = get_orbital_lane_edge_pos(_side, _i);
        var _gx = _edge.x;
        var _gy = _edge.y;
        var _hit = false;

        while (grid_is_playable(_gx, _gy)) {
            if (global.grid[_gy][_gx] != undefined) {
                _hit = true;
                break;
            }

            _gx += _dir.x;
            _gy += _dir.y;
        }

        if (_hit) {
            if (_i < _minIdx) _minIdx = _i;
            if (_i > _maxIdx) _maxIdx = _i;
            _found = true;
        }
    }

    // Empty planet: spawn from center lane.
    if (!_found) {
        var _centerLane = floor((_cols - 1) * 0.5);
        return {
            min: _centerLane,
            max: _centerLane,
            size: 1
        };
    }

    return {
        min: _minIdx,
        max: _maxIdx,
        size: _maxIdx - _minIdx + 1
    };
}


// =============================================================================
// PIECE RNG (Deterministic seeding for Story Mode)
// =============================================================================

function piece_rng_seed(_seed) {
    global.piece_rng_state = max(1, floor(_seed));
}

function piece_rng_next_unit() {
    if (!variable_global_exists("piece_rng_state") || global.piece_rng_state <= 0) {
        global.piece_rng_state = 1234567;
    }
    // Park-Miller LCG
    global.piece_rng_state = (global.piece_rng_state * 48271) mod 2147483647;
    return global.piece_rng_state / 2147483647;
}

function piece_rng_random(_max) {
    return piece_rng_next_unit() * _max;
}

function piece_rng_irandom(_max) {
    if (_max <= 0) return 0;
    return floor(piece_rng_random(_max + 1));
}


// =============================================================================
// PIECE DATA
// =============================================================================

function get_color_from_id(_id) {
    switch (_id) {
        case 1: return make_color_rgb(255, 107, 107); // Pink
        case 2: return make_color_rgb(255, 146,  43); // Orange
        case 3: return make_color_rgb(252, 196,  25); // Yellow
        case 4: return make_color_rgb(220,  50,  50); // Red
        case 5: return make_color_rgb(102, 217, 232); // Cyan
        case 6: return make_color_rgb( 80, 200,  80); // Green
    }

    return c_white;
}


function get_random_active_color_id() {
    if (array_length(global.activeColors) <= 0) return 1;
    return global.activeColors[irandom(array_length(global.activeColors) - 1)];
}


function make_piece_data(_type, _id, _dir = 0) {
    var _color = get_color_from_id(_id);
    var _data = {
        type: _type,
        color: _color,
        dir: _dir,
        id: _id,
        shard_value: 0,
        locked_hp: 0,
        special_value: 0
    };

    if (_type == "asteroid") {
        _data.shield_hp = 2;
    }
    if (_type == "locked") {
        _data.locked_hp = 2;
    }
    if (_type == "multiplier") {
        _data.special_value = 2;
    }
    if (_type == "debt") {
        _data.special_value = 750;
    }
    if (_type == "core_key") {
        _data.shard_value = 2;
    }
    if (_type == "wild") {
        _data.id = 999;
        _data.color = c_white;
    }

    return _data;
}

function story_specialty_type_for_piece() {
    if (global.gameMode != "STORY") return "normal";

    var _world = clamp(global.storyPlanet, 0, 4);
    var _level = clamp(global.storyLevel, 0, 5);
    var _chance = 0.10 + (_level * 0.012);
    if (_world == 0) _chance = 0.08 + (_level * 0.01);
    if (piece_rng_random(1) >= _chance) return "normal";

    switch (_world) {
        case 0:
            return (piece_rng_random(1) < 0.55) ? "wild" : "normal";
        case 1:
            return (piece_rng_random(1) < 0.52) ? "locked" : "spore";
        case 2:
            return (piece_rng_random(1) < 0.58) ? "multiplier" : "debt";
        case 3:
            return (piece_rng_random(1) < 0.55) ? "gravity" : "void";
        case 4:
            return (piece_rng_random(1) < 0.50) ? "prism" : "core_key";
    }

    return "normal";
}


function generate_piece() {
    // --- Smart Biasing: Help player clear the core and leftovers ---
    var _coreId = -1;
    var _cx = -1, _cy = -1;
    var _buried = 0;
    var _counts = array_create(10, 0); // Count of each color id
    
    if (global.gameMode == "PLANET" || global.gameMode == "STORY") {
        for (var _y = 0; _y < global.TOTAL_ROWS; _y++) {
            for (var _x = 0; _x < global.TOTAL_COLS; _x++) {
                var _c = global.grid[_y][_x];
                if (_c == undefined) continue;
                if (_c.id > 0 && _c.id < 10) _counts[_c.id]++;
                if (_c.type == "core") { _coreId = _c.id; _cx = _x; _cy = _y; }
            }
        }
        if (_coreId != -1) {
            var _dirs = [[-1,0],[1,0],[0,-1],[0,1]];
            for (var i = 0; i < 4; i++) {
                var _nx = _cx + _dirs[i][0]; var _ny = _cy + _dirs[i][1];
                if (_nx >= 0 && _nx < global.TOTAL_COLS && _ny >= 0 && _ny < global.TOTAL_ROWS) {
                    if (global.grid[_ny][_nx] != undefined) _buried++;
                }
            }
        }
    }

    // Normal Piece Count for scaling
    var _totalBlocks = 0;
    for (var i = 1; i < 10; i++) _totalBlocks += _counts[i];

    // Dead blocks
    if (global.level >= 5 && piece_rng_random(1) < 0.10) {
        return { type: "dead", color: c_dkgray, dir: 0, id: 999 };
    }

    // Bombs: increased chance if core is buried
    var _bombChance = 0.01 + (global.level * 0.0015);
    if (_buried >= 3) _bombChance += 0.04; 
    if (piece_rng_random(1) < _bombChance) {
        return { type: "bomb", color: c_black, dir: 0, id: 888 };
    }

    // Drills: restricted to level 3+ AND only AFTER the first 5 turns
    var _drillChance = 0.008 + (global.level * 0.001);
    if (_buried >= 2) _drillChance += 0.03;
    if (global.level >= 3 && global.turnCount > 5 && piece_rng_random(1) < _drillChance) {
        return { type: "drill", color: c_silver, dir: 0, id: 777 };
    }

    // Metal (Arrows)
    var _metalRate = 0.15;
    if (_totalBlocks < 10) _metalRate *= 0.2; // 80% more rare if board is clearing
    
    if (global.level >= 2 && piece_rng_random(1) < _metalRate) {
        var _lonelyColors = [];
        for (var i = 1; i < 10; i++) if (_counts[i] > 0 && _counts[i] < 4) array_push(_lonelyColors, i);
        
        var _metalId = -1;
        if (array_length(_lonelyColors) > 0 && piece_rng_random(1) < 0.6) {
            // Bias arrow color to help clear leftovers
            _metalId = _lonelyColors[irandom(array_length(_lonelyColors) - 1)];
        } else {
            var _midx = piece_rng_irandom(array_length(global.activeColors) - 1);
            _metalId = global.activeColors[_midx];
        }

        return {
            type: "metal",
            color: get_color_from_id(_metalId),
            dir: (piece_rng_random(1) > 0.5 ? 1 : 0),
            id: _metalId
        };
    }

    // Asteroid
    if (global.level >= 3 && piece_rng_random(1) < 0.05) {
        var _aidx = piece_rng_irandom(array_length(global.activeColors) - 1);
        var _astId = global.activeColors[_aidx];

        return {
            type: "asteroid",
            color: get_color_from_id(_astId),
            dir: 0,
            id: _astId,
            shield_hp: 2
        };
    }

    // Normal
    var _totalBlocks = 0;
    for (var i = 1; i < 10; i++) _totalBlocks += _counts[i];
    
    // Dynamic Help: The fewer blocks left, the more we help (up to 90% helpage)
    var _helpFactor = clamp(1.0 - (_totalBlocks / 45), 0, 1);
    var _lonelyChance = 0.35 + (_helpFactor * 0.55);
    var _coreChance   = 0.25 + (_helpFactor * 0.40);

    var _id = -1;
    var _lonelyColors = [];
    for (var i = 1; i < 10; i++) {
        if (_counts[i] > 0 && _counts[i] < 4) array_push(_lonelyColors, i);
    }

    if (array_length(_lonelyColors) > 0 && random(1) < _lonelyChance) {
        // High chance to clear leftovers as board empties (LIVE random)
        _id = _lonelyColors[irandom(array_length(_lonelyColors) - 1)];
    } else if (_coreId != -1 && random(1) < _coreChance) {
        // Scaled core help (LIVE random)
        _id = _coreId;
    } else {
        // Fallback to SEEDED random for normal pieces
        var _nidx = piece_rng_irandom(array_length(global.activeColors) - 1);
        _id = global.activeColors[_nidx];
    }

    var _shardRate = 0.10;
    if (global.gameMode == "STORY") _shardRate = 0.14 + (global.storyPlanet * 0.015);
    if (global.gameMode == "BONUS") {
        var _bidx = clamp(global.bonusPlanet, 0, array_length(global.bonusPlanets) - 1);
        _shardRate = global.bonusPlanets[_bidx].shard_rate;
    }

    var _type = story_specialty_type_for_piece();
    var _piece = make_piece_data(_type, _id, 0);
    _piece.shard_value = (piece_rng_random(1) < _shardRate) ? 1 : 0;

    if (_type == "wild") {
        _piece.color = c_white;
    } else if (_type == "void") {
        _piece.color = make_color_rgb(25, 15, 45);
        _piece.id = 0;
        _piece.shard_value = 0;
    } else if (_type == "core_key") {
        _piece.shard_value = max(_piece.shard_value, 2);
    }

    return _piece;
}


function piece_data_from_instance(_inst) {
    var _data = {
        type: _inst.type,
        color: _inst.color,
        dir: _inst.dir,
        id: _inst.color_id,
        shard_value: variable_instance_exists(_inst, "shard_value") ? _inst.shard_value : 0,
        locked_hp: variable_instance_exists(_inst, "locked_hp") ? _inst.locked_hp : 0,
        special_value: variable_instance_exists(_inst, "special_value") ? _inst.special_value : 0
    };

    if (_inst.type == "asteroid") {
        if (variable_instance_exists(_inst, "shield_hp")) {
            _data.shield_hp = _inst.shield_hp;
        } else {
            _data.shield_hp = 2;
        }
    }

    return _data;
}


// =============================================================================
// INSTANCE PLACEMENT
// =============================================================================

function _place_block_instance(_gx, _gy, _pieceData) {
    var _wx = (_gx - global.HIDDEN_SIDES) * 16;
    var _wy = (_gy - global.HIDDEN_ROWS)  * 16;

    var _inst = instance_create_layer(_wx, _wy, "Instances", obj_block);

    _inst.type     = _pieceData.type;
    _inst.color    = _pieceData.color;
    _inst.dir      = _pieceData.dir;
    _inst.color_id = _pieceData.id;
    _inst.grid_x   = _gx;
    _inst.grid_y   = _gy;
    _inst.shard_value = variable_struct_exists(_pieceData, "shard_value") ? _pieceData.shard_value : 0;
    _inst.locked_hp = variable_struct_exists(_pieceData, "locked_hp") ? _pieceData.locked_hp : 0;
    _inst.special_value = variable_struct_exists(_pieceData, "special_value") ? _pieceData.special_value : 0;

    if (_pieceData.type == "asteroid") {
        if (variable_struct_exists(_pieceData, "shield_hp")) {
            _inst.shield_hp = _pieceData.shield_hp;
        } else {
            _inst.shield_hp = 2;
        }
    }

    _inst.visualRotation = 0;
    _inst.rotation = 0;

    with (_inst) update_sprite();

    return _inst;
}


function place_grid_cell(_gx, _gy, _pieceData) {
    if (!grid_in_bounds(_gx, _gy)) return undefined;
    if (global.grid[_gy][_gx] != undefined) return undefined;

    var _inst = _place_block_instance(_gx, _gy, _pieceData);

    global.grid[_gy][_gx] = {
        type: _pieceData.type,
        color: _pieceData.color,
        dir: _pieceData.dir,
        id: _pieceData.id,
        inst: _inst,
        shard_value: variable_struct_exists(_pieceData, "shard_value") ? _pieceData.shard_value : 0,
        locked_hp: variable_struct_exists(_pieceData, "locked_hp") ? _pieceData.locked_hp : 0,
        special_value: variable_struct_exists(_pieceData, "special_value") ? _pieceData.special_value : 0
    };

    if (_pieceData.type == "asteroid") {
        var _hp = 2;

        if (variable_struct_exists(_pieceData, "shield_hp")) {
            _hp = _pieceData.shield_hp;
        }

        _inst.shield_hp = _hp;
    }

    return _inst;
}


// =============================================================================
// SPAWNING / HOLDING
// =============================================================================

function get_spawn_grid_pos() {
    if (piece_is_planet_mode()) {
        var _lane = get_orbital_lane_bounds(global.orbitalX);

        global.orbitalX = clamp(global.orbitalX, _lane.min, _lane.max);

        return get_orbital_pos(global.orbitalSide, global.orbitalX);
    }

    return {
        x: floor(global.COLS / 2),
        y: 0
    };
}


function setup_active_piece_after_spawn(_inst, _gx, _gy) {
    global.activePiece = _inst;
    global.canHold = true;
    global.launchCharge = 0;

    if (piece_is_planet_mode()) {
        global.pieceTimer = global.MAX_PIECE_TIME;
        global.previewData = calculate_planet_preview_path(global.activePiece);

        if (global.previewData != undefined) {
            global.previewDepth = max(1, global.previewData.depth);
        } else {
            global.previewDepth = max(1, calculate_landing_depth(_gx, _gy));
        }
    } else {
        global.previewData = undefined;
        global.previewDepth = max(1, calculate_landing_depth(_gx, _gy));
    }
}


function spawn_piece() {
    global.turnCount++;

    if (array_length(global.nextQueue) <= 0) {
        array_push(global.nextQueue, generate_piece());
    }

    var _pieceData = array_shift(global.nextQueue);
    array_push(global.nextQueue, generate_piece());

    var _pos = get_spawn_grid_pos();
    var _gx = _pos.x;
    var _gy = _pos.y;

    var _inst = _place_block_instance(_gx, _gy, _pieceData);

    setup_active_piece_after_spawn(_inst, _gx, _gy);

    // Classic game over: spawn cell already occupied.
    // Planet/Story game over is handled by lock_piece when the piece cannot enter the board.
    if (!piece_is_planet_mode()) {
        var _cell = global.grid[_gy][_gx];

        if (_cell != undefined) {
            var _blocked = true;

            if (_cell.inst != undefined && instance_exists(_cell.inst)) {
                if (variable_instance_exists(_cell.inst, "clearing") && _cell.inst.clearing) {
                    _blocked = false;
                }
            }

            if (_blocked) {
                global.gameState = "GAMEOVER";
                sfx_game_over();

                if (global.score > global.highScore) {
                    global.highScore = global.score;
                    save_high_score();
                }
            }
        }
    }
}


function hold_piece() {
    if (global.activePiece == undefined) return;
    if (!global.canHold || global.locking) return;

    var _outgoing = piece_data_from_instance(global.activePiece);

    instance_destroy(global.activePiece);
    global.activePiece = undefined;

    if (global.holdPiece == undefined) {
        global.holdPiece = _outgoing;
        spawn_piece();
        global.canHold = false;
        return;
    }

    var _incoming = global.holdPiece;
    var _pos = get_spawn_grid_pos();

    var _inst = _place_block_instance(_pos.x, _pos.y, _incoming);

    global.holdPiece = _outgoing;

    setup_active_piece_after_spawn(_inst, _pos.x, _pos.y);

    global.canHold = false;
}


// =============================================================================
// STORY LEVEL DATA
// =============================================================================

function story_level_catalog() {
    return [
        { world_id: 0, level_id: 0, seed: 1001, palette_count: 3, turn_limit: 35, objective: { type: "clear_board", value: 1 } },
        { world_id: 0, level_id: 1, seed: 1002, palette_count: 3, turn_limit: 40, objective: { type: "clear_board", value: 1 } },
        { world_id: 0, level_id: 2, seed: 1003, palette_count: 3, turn_limit: 45, objective: { type: "clear_board", value: 1 } },
        { world_id: 0, level_id: 3, seed: 1004, palette_count: 3, turn_limit: 50, objective: { type: "clear_board", value: 1 } },
        { world_id: 0, level_id: 4, seed: 1005, palette_count: 3, turn_limit: 60, objective: { type: "clear_board", value: 1 } },
        { world_id: 0, level_id: 5, seed: 1006, palette_count: 4, objective: { type: "clear_cores", value: 6 } },

        { world_id: 1, level_id: 0, seed: 2001, palette_count: 3, turn_limit: 45, objective: { type: "clear_board", value: 1 } },
        { world_id: 1, level_id: 1, seed: 2002, palette_count: 3, turn_limit: 50, objective: { type: "clear_board", value: 1 } },
        { world_id: 1, level_id: 2, seed: 2003, palette_count: 4, turn_limit: 55, objective: { type: "clear_board", value: 1 } },
        { world_id: 1, level_id: 3, seed: 2004, palette_count: 4, objective: { type: "clear_board", value: 1 } },
        { world_id: 1, level_id: 4, seed: 2005, palette_count: 4, turn_limit: 60, objective: { type: "clear_board", value: 1 } },
        { world_id: 1, level_id: 5, seed: 2006, palette_count: 4, objective: { type: "clear_board", value: 1 } },

        { world_id: 2, level_id: 0, seed: 3001, palette_count: 4, objective: { type: "clear_board", value: 1 } },
        { world_id: 2, level_id: 1, seed: 3002, palette_count: 4, objective: { type: "clear_board", value: 1 } },
        { world_id: 2, level_id: 2, seed: 3003, palette_count: 4, objective: { type: "clear_board", value: 1 } },
        { world_id: 2, level_id: 3, seed: 3004, palette_count: 4, objective: { type: "clear_board", value: 1 } },
        { world_id: 2, level_id: 4, seed: 3005, palette_count: 5, objective: { type: "clear_board", value: 1 } },
        { world_id: 2, level_id: 5, seed: 3006, palette_count: 5, objective: { type: "clear_cores", value: 12 } },

        { world_id: 3, level_id: 0, seed: 4001, palette_count: 4, objective: { type: "clear_board", value: 1 } },
        { world_id: 3, level_id: 1, seed: 4002, palette_count: 5, full_palette: true, objective: { type: "clear_board", value: 1 } },
        { world_id: 3, level_id: 2, seed: 4003, palette_count: 5, objective: { type: "clear_board", value: 1 } },
        { world_id: 3, level_id: 3, seed: 4004, palette_count: 5, full_palette: true, objective: { type: "clear_board", value: 1 } },
        { world_id: 3, level_id: 4, seed: 4005, palette_count: 5, full_palette: true, objective: { type: "clear_board", value: 1 } },
        { world_id: 3, level_id: 5, seed: 4006, palette_count: 5, full_palette: true, objective: { type: "clear_cores", value: 14 } },

        { world_id: 4, level_id: 0, seed: 5001, palette_count: 5, full_palette: true, objective: { type: "clear_board", value: 1 } },
        { world_id: 4, level_id: 1, seed: 5002, palette_count: 5, full_palette: true, objective: { type: "clear_board", value: 1 } },
        { world_id: 4, level_id: 2, seed: 5003, palette_count: 6, full_palette: true, objective: { type: "clear_board", value: 1 } },
        { world_id: 4, level_id: 3, seed: 5004, palette_count: 6, full_palette: true, objective: { type: "clear_board", value: 1 } },
        { world_id: 4, level_id: 4, seed: 5005, palette_count: 6, full_palette: true, objective: { type: "clear_board", value: 1 } },
        { world_id: 4, level_id: 5, seed: 5006, palette_count: 6, full_palette: true, objective: { type: "clear_cores", value: 20 } }
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

        var _cid = get_random_active_color_id();
        var _type = story_pick_cell_type(_settings);
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
            }
        }
    }

    return true;
}
