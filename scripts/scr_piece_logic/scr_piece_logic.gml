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
        _data.id = WILDCARD_ID;
        _data.color = c_white;
    }

    return _data;
}

function story_specialty_type_for_piece() {
    // Specialty obstacles (locked, spore, etc.) should only exist in the seed layout,
    // NOT in the player's active piece queue.
    return "normal";
}


// Scans the live grid and returns a board-state report used by generate_piece().
function board_analyze_intent() {
    var _cx = floor(global.TOTAL_COLS / 2);
    var _cy = floor(global.TOTAL_ROWS / 2);

    // Per-color tallies
    var _colorCount = {};      // id → block count
    var _colorNeighbors = {};  // id → max connected-neighbor count (proxy for near-match)
    var _junkCount  = 0;
    var _coreDist   = 999;     // min distance of any block to center
    var _outerDist  = 0;
    var _totalBlocks = 0;
    var _deadCells  = 0;
    var _asteroidCount = 0;

    for (var _gy = global.HIDDEN_ROWS; _gy < global.TOTAL_ROWS - global.HIDDEN_ROWS; _gy++) {
        for (var _gx = global.HIDDEN_SIDES; _gx < global.TOTAL_COLS - global.HIDDEN_SIDES; _gx++) {
            var _cell = global.grid[_gy][_gx];
            if (_cell == undefined) continue;
            _totalBlocks++;
            var _dist = max(abs(_gx - _cx), abs(_gy - _cy));
            if (_dist < _coreDist) _coreDist = _dist;
            if (_dist > _outerDist) _outerDist = _dist;

            if (_cell.type == "dead" || _cell.type == "void") { _deadCells++; continue; }
            if (_cell.type == "asteroid") { _asteroidCount++; _junkCount++; continue; }
            if (_cell.type == "bomb" || _cell.type == "drill") { _junkCount++; continue; }
            if (_cell.type == "core") continue;

            var _id = _cell.id;
            if (_id <= 0 || _id == WILDCARD_ID) continue;

            _colorCount[$ string(_id)] = (variable_struct_exists(_colorCount, string(_id)) ? _colorCount[$ string(_id)] : 0) + 1;

            // Count same-color orthogonal neighbors
            var _nbCount = 0;
            var _dirs = [[-1,0],[1,0],[0,-1],[0,1]];
            for (var _d = 0; _d < 4; _d++) {
                var _nx = _gx + _dirs[_d][0];
                var _ny = _gy + _dirs[_d][1];
                if (_nx < 0 || _nx >= global.TOTAL_COLS || _ny < 0 || _ny >= global.TOTAL_ROWS) continue;
                var _nb = global.grid[_ny][_nx];
                if (_nb != undefined && _nb.id == _id) _nbCount++;
            }
            var _key = string(_id);
            if (!variable_struct_exists(_colorNeighbors, _key) || _colorNeighbors[$ _key] < _nbCount) {
                _colorNeighbors[$ _key] = _nbCount;
            }
        }
    }

    // Categorize colors
    var _hot    = [];  // ≥3 neighbors (one more finishes a match)
    var _warm   = [];  // ≥2 neighbors
    var _dead   = [];  // only 1-2 blocks total (can't ever match alone)
    var _mercy  = [];  // ≤3 blocks remaining on the board
    var _keys = variable_struct_get_names(_colorCount);
    for (var _ki = 0; _ki < array_length(_keys); _ki++) {
        var _k   = _keys[_ki];
        var _cnt = _colorCount[$ _k];
        var _nb  = variable_struct_exists(_colorNeighbors, _k) ? _colorNeighbors[$ _k] : 0;
        var _numId = real(_k);
        if (_nb >= 3) array_push(_hot, _numId);
        else if (_nb >= 2) array_push(_warm, _numId);
        if (_cnt <= 2) array_push(_dead, _numId);
        if (_cnt > 0 && _cnt <= 3) array_push(_mercy, _numId);
    }

    // Pressure scores (0–1 scale)
    var _corePressure = (_coreDist <= 3) ? clamp((4 - _coreDist) / 3, 0, 1) : 0;
    var _junkPressure = clamp(_junkCount / max(1, _totalBlocks), 0, 1);

    return {
        total_blocks:   _totalBlocks,
        core_pressure:  _corePressure,
        junk_pressure:  _junkPressure,
        hot_colors:     _hot,
        warm_colors:    _warm,
        dead_colors:    _dead,
        mercy_colors:   _mercy,
        needs_bomb:     (_junkCount >= 4 || _asteroidCount >= 2),
        needs_drill:    (_coreDist <= 2 && _totalBlocks >= 6)
    };
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


// story_level_catalog, story_get_level_def, story_get_level_seed,
// story_apply_level_palette, story_place_cell, story_get_layout_settings,
// story_pick_cell_type, story_apply_level_layout
// → moved to scr_story_data.gml
