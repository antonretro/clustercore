// =============================================================================
// scr_piece_logic Ã¢â‚¬â€ spawning, holding, orbital positioning, story layout
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
    // Specialty obstacles (locked, spore, etc.) should only exist in the seed layout,
    // NOT in the player's active piece queue.
    return "normal";
}


function refill_piece_bag() {
    var _temp = [];
    for (var i = 0; i < array_length(global.activeColors); i++) {
        array_push(_temp, global.activeColors[i]);
    }
    // Fisher-Yates shuffle
    for (var i = array_length(_temp) - 1; i > 0; i--) {
        var j = irandom(i);
        var _val = _temp[i];
        _temp[i] = _temp[j];
        _temp[j] = _val;
    }
    for (var i = 0; i < array_length(_temp); i++) {
        array_push(global.pieceBag, _temp[i]);
    }
}

function generate_piece() {
    var _report = board_analyze_intent();
    
    // Update Pity Budget based on board pressure
    global.pityBudget += (_report.core_pressure * 0.2) + (_report.junk_pressure * 0.15);
    if (_report.total_blocks > 40) global.pityBudget += 0.1;
    
    // Create candidates
    var _bestScore = -999;
    var _bestPiece = undefined;
    var _numCandidates = (global.pityBudget > 5) ? 4 : 2; // More choices if we are struggling

    for (var i = 0; i < _numCandidates; i++) {
        var _candidate = _generate_raw_candidate(_report);
        var _score = _score_piece_usefulness(_candidate, _report);
        
        if (_score > _bestScore || _bestPiece == undefined) {
            _bestScore = _score;
            _bestPiece = _candidate;
        }
    }

    // Pity spend
    if (_bestScore > 10) global.pityBudget = max(0, global.pityBudget - 1);
    
    // Memory
    if (variable_struct_exists(_bestPiece, "id")) {
        array_push(global.lastGeneratedColors, _bestPiece.id);
        if (array_length(global.lastGeneratedColors) > 4) array_shift(global.lastGeneratedColors);
    }

    return _bestPiece;
}

/// @function _generate_raw_candidate
/// @description Internal helper to create a random piece before scoring.
function _generate_raw_candidate(_report) {
    if (array_length(global.pieceBag) == 0) refill_piece_bag();
    var _colorId = array_shift(global.pieceBag);

    // Mercy: when only few blocks of a color remain, guarantee those colors.
    // We check if total blocks are low (near-clear) and pick from the mercy list.
    if (_report.total_blocks > 0 && _report.total_blocks <= 10) {
        var _mList = _report.mercy_colors;
        if (array_length(_mList) > 0) {
            // Pick a color from the mercy list that we haven't generated too recently
            // if there are multiple choices.
            var _mercyId = _mList[0];
            if (array_length(_mList) > 1) {
                // Find which of these mercy colors was generated LEAST recently
                var _bestScore = -1;
                for (var _mi = 0; _mi < array_length(_mList); _mi++) {
                    var _mid = _mList[_mi];
                    var _lastIdx = -1;
                    for (var _li = array_length(global.lastGeneratedColors)-1; _li >= 0; _li--) {
                        if (global.lastGeneratedColors[_li] == _mid) { _lastIdx = _li; break; }
                    }
                    // If never generated or generated long ago, pick it
                    var _age = (_lastIdx == -1) ? 99 : (array_length(global.lastGeneratedColors) - _lastIdx);
                    if (_age > _bestScore) {
                        _bestScore = _age;
                        _mercyId = _mid;
                    }
                }
            }
            _colorId = _mercyId;
            // When in mercy mode, do NOT disrupt the "set of 4" with specials.
            return make_piece_data("normal", _colorId, 0);
        }
    }

    // Roll for Specials
    var _roll = piece_rng_random(1.0);
    
    // Pity influence on specials
    var _bonus = global.pityBudget * 0.01;

    // Drills (unchanged)
    if (global.level >= 3 && _roll < (0.01 + _bonus + (_report.needs_drill ? 0.05 : 0))) {
        return { type: "drill", color: c_silver, dir: 0, id: 777 };
    }
    // Bombs: rare by default, more likely when board is clogged or nearly cleared
    var _bombChance = 0.004 + _bonus;
    if (_report.needs_bomb) _bombChance += 0.025;
    if (_report.total_blocks <= 3 && _report.total_blocks > 0) _bombChance += 0.04;
    if (_roll < _bombChance) {
        return { type: "bomb", color: c_black, dir: 0, id: 888 };
    }

    // Arrows
    if (global.level >= 2 && _roll < 0.12) {
        var _midx = piece_rng_irandom(array_length(global.activeColors) - 1);
        var _metalId = global.activeColors[_midx];
        return {
            type: "metal",
            color: get_color_from_id(_metalId),
            dir: (piece_rng_random(1) > 0.5 ? 1 : 0),
            id: _metalId
        };
    }

    // Normal Piece
    var _type = story_specialty_type_for_piece();
    var _piece = make_piece_data(_type, _colorId, 0);
    
    var _shardRate = 0.10 + (global.level * 0.01);
    _piece.shard_value = (piece_rng_random(1) < _shardRate) ? 1 : 0;
    
    return _piece;
}

/// @function _score_piece_usefulness
/// @description Assigns a score to a piece based on the current board intent.
function _score_piece_usefulness(_piece, _report) {
    var _score = 10; // Base score
    
    // Color categorization bonuses
    if (variable_struct_exists(_piece, "id")) {
        var _id = _piece.id;
        
        // Is it hot? (Near-match)
        for (var i = 0; i < array_length(_report.hot_colors); i++) {
            if (_report.hot_colors[i] == _id) { _score += 15; break; }
        }
        // Is it warm?
        for (var i = 0; i < array_length(_report.warm_colors); i++) {
            if (_report.warm_colors[i] == _id) { _score += 7; break; }
        }
        // Is it dead?
        for (var i = 0; i < array_length(_report.dead_colors); i++) {
            if (_report.dead_colors[i] == _id) { _score -= 20; break; }
        }
        
        // Memory penalty (Anti-streak)
        for (var i = 0; i < array_length(global.lastGeneratedColors); i++) {
            if (global.lastGeneratedColors[i] == _id) { _score -= 5; }
        }
    }
    
    // Type bonuses
    if (_piece.type == "bomb" && _report.needs_bomb) _score += 20;
    if (_piece.type == "drill" && _report.needs_drill) _score += 20;
    if (_piece.type == "metal") _score += 2; // Slight bias for arrows as they are rarer

    return _score;
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
    if (global.gameMode == "PLANET" || global.gameMode == "STORY") {
        recalculate_planet_surface();
    }

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


function check_if_cell_creates_match(_gx, _gy, _cid) {
    // Simple BFS check for 4+ same-color adjacency
    var _q = [{x: _gx, y: _gy}];
    var _visited = ds_map_create();
    _visited[? string(_gx) + "," + string(_gy)] = true;
    var _count = 1;
    var _head = 0;
    
    var _dirs = [[1,0],[-1,0],[0,1],[0,-1]];
    
    while (_head < array_length(_q)) {
        var _curr = _q[_head++];
        for (var i = 0; i < 4; i++) {
            var _nx = _curr.x + _dirs[i][0];
            var _ny = _curr.y + _dirs[i][1];
            var _key = string(_nx) + "," + string(_ny);
            
            if (grid_in_bounds(_nx, _ny) && !ds_map_exists(_visited, _key)) {
                var _cell = global.grid[_ny][_nx];
                if (_cell != undefined && _cell.id == _cid && _cell.type == "normal") {
                    _visited[? _key] = true;
                    array_push(_q, {x: _nx, y: _ny});
                    _count++;
                }
            }
        }
    }
    
    ds_map_destroy(_visited);
    return (_count >= 4);
}

// =============================================================================
// Board Intent Analyzer helper functions
// =============================================================================

function board_cell_can_color_match(_c) {
    if (_c == undefined) return false;
    if (_c.id <= 0 || _c.id >= 10) return false;
    if (_c.type == "metal" || _c.type == "core_arrow") return false;
    if (_c.type == "bomb" || _c.type == "drill" || _c.type == "dead") return false;
    if (_c.type == "void" || _c.type == "asteroid" || _c.type == "locked" || _c.type == "spore") return false;
    return true;
}

function board_count_open_extensions(_x, _y, _dx, _dy) {
    var _open = 0;
    var _bx = _x - _dx;
    var _by = _y - _dy;
    if (grid_in_bounds(_bx, _by) && global.grid[_by][_bx] == undefined) _open++;
    var _ax = _x + _dx;
    var _ay = _y + _dy;
    if (grid_in_bounds(_ax, _ay) && global.grid[_ay][_ax] == undefined) _open++;
    return _open;
}

function board_analyze_intent() {
    var _report = {
        color_potential: array_create(10, 0),
        hot_colors: [],
        warm_colors: [],
        cold_colors: [],
        dead_colors: [],
        core_pressure: 0,
        core_access_distance: 0,
        junk_pressure: 0,
        needs_bomb: false,
        needs_drill: false,
        mercy_color: -1,
        arrow_opportunities: [],
        total_blocks: 0,
        nearest_match_distance: 99
    };
    var _counts = array_create(10, 0);
    var _coreId = -1;
    var _cx = -1, _cy = -1;
    var _junkBlocks = 0;
    var _buriedCore = 0;
    for (var _y = 0; _y < global.TOTAL_ROWS; _y++) {
        for (var _x = 0; _x < global.TOTAL_COLS; _x++) {
            var _c = global.grid[_y][_x];
            if (_c == undefined) continue;
            _report.total_blocks++;
            if (_c.id > 0 && _c.id < 10) _counts[_c.id]++;
            if (_c.type == "core") { _coreId = _c.id; _cx = _x; _cy = _y; }
            if (_c.type == "asteroid" || _c.type == "locked" || _c.type == "spore") _junkBlocks++;
        }
    }
    for (var _y = 0; _y < global.TOTAL_ROWS; _y++) {
        for (var _x = 0; _x < global.TOTAL_COLS; _x++) {
            var _c = global.grid[_y][_x];
            if (_c == undefined) continue;
            if (board_cell_can_color_match(_c)) {
                var _dirs = [[1,0], [0,1], [1,1], [1,-1]];
                for (var i = 0; i < 4; i++) {
                    var _dx = _dirs[i][0];
                    var _dy = _dirs[i][1];
                    var _nx = _x + _dx;
                    var _ny = _y + _dy;
                    if (!grid_in_bounds(_nx, _ny)) continue;
                    var _nc = global.grid[_ny][_nx];
                    if (_nc != undefined && _nc.id == _c.id) {
                        var _open = board_count_open_extensions(_x, _y, -_dx, -_dy) + board_count_open_extensions(_nx, _ny, _dx, _dy);
                        if (_open > 0) {
                            _report.color_potential[_c.id] += 8;
                            _report.nearest_match_distance = min(_report.nearest_match_distance, 2);
                            var _nnx = _nx + _dx;
                            var _nny = _ny + _dy;
                            if (grid_in_bounds(_nnx, _nny)) {
                                var _nnc = global.grid[_nny][_nnx];
                                if (_nnc != undefined && _nnc.id == _c.id) {
                                    _report.color_potential[_c.id] += 15;
                                    _report.nearest_match_distance = min(_report.nearest_match_distance, 1);
                                }
                            }
                        }
                    }
                }
            }
            if (_c.type == "metal") {
                var _axis = (_c.dir == 0) ? "h" : "v";
                var _aDir = (_c.dir == 0) ? {x:1, y:0} : {x:0, y:1};
                var _matchCount = 1;
                var _openSlots = 0;
                var _scanDirs = [1, -1];
                for (var _sd = 0; _sd < 2; _sd++) {
                    var _dMult = _scanDirs[_sd];
                    for (var _step = 1; _step < 4; _step++) {
                        var _ax = _x + (_aDir.x * _step * _dMult);
                        var _ay = _y + (_aDir.y * _step * _dMult);
                        if (!grid_in_bounds(_ax, _ay)) break;
                        var _ac = global.grid[_ay][_ax];
                        if (_ac == undefined) _openSlots++;
                        else if (_ac.id == _c.id) _matchCount++;
                        else break;
                    }
                }
                if (_matchCount >= 2 && _openSlots > 0) {
                    _report.color_potential[_c.id] += 12;
                    array_push(_report.arrow_opportunities, { color: _c.id, axis: _axis, size: _matchCount, open: _openSlots });
                }
            }
            if (_coreId != -1) {
                var _dist = abs(_x - _cx) + abs(_y - _cy);
                if (_dist <= 2) _report.color_potential[_c.id] += 4;
            }
        }
    }
    if (_coreId != -1) {
        var _adj = [[-1,0],[1,0],[0,-1],[0,1]];
        for (var i = 0; i < 4; i++) {
            var _nx = _cx + _adj[i][0];
            var _ny = _cy + _adj[i][1];
            if (grid_in_bounds(_nx, _ny) && global.grid[_ny][_nx] != undefined) _buriedCore++;
        }
        _report.core_access_distance = _buriedCore;
        _report.core_pressure = _buriedCore / 4.0;
    }
    _report.junk_pressure = clamp(_junkBlocks / 15.0, 0, 1.0);
    _report.needs_bomb = (_report.junk_pressure > 0.4 || _report.core_access_distance >= 3);
    _report.needs_drill = (_report.core_pressure > 0.5 && _report.total_blocks > 25);
    if (_coreId != -1 && _report.core_pressure > 0.7) _report.color_potential[_coreId] += 12;
    for (var i = 0; i < array_length(global.activeColors); i++) {
        var _id = global.activeColors[i];
        var _pot = _report.color_potential[_id];
        if (_counts[_id] == 0) array_push(_report.dead_colors, _id);
        else if (_pot >= 22) array_push(_report.hot_colors, _id);
        else if (_pot >= 8) array_push(_report.warm_colors, _id);
        else array_push(_report.cold_colors, _id);
    }

    // Mercy colors: when only 1-3 blocks of a single color remain, flag them
    _report.mercy_colors = [];
    for (var i = 0; i < array_length(global.activeColors); i++) {
        var _id = global.activeColors[i];
        var _c = _counts[_id];
        if (_c >= 1 && _c <= 4) { // Slightly higher threshold to ensure player has enough to work with
            array_push(_report.mercy_colors, _id);
        }
    }

    return _report;
}
