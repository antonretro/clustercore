// =============================================================================
// scr_piece_logic — Piece spawning, holding, and orbital positioning
//
// PLANET/STORY coordinate contract:
//   Staging ring occupies the outer ring of the 11x11 grid:
//     Top row:    y=0,  x=1..9   (side 0)
//     Right col:  x=10, y=1..9   (side 1)
//     Bottom row: y=10, x=9..1   (side 2, reversed so left=ccw)
//     Left col:   x=0,  y=9..1   (side 3, reversed)
//   orbitalX ranges 0..(COLS-1), with adaptive lane bounds per surface state.
//
// Block world pixel position (stored on the instance):
//   inst.x = (grid_x - global.HIDDEN_SIDES) * 16
//   inst.y = (grid_y - global.HIDDEN_ROWS)  * 16
//
// The Draw event scales by PIXEL_SCALE and offsets by _bx/_by.
// =============================================================================

// -----------------------------------------------------------------------------
// Piece RNG stream (deterministic queue support)
// -----------------------------------------------------------------------------
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

// ─────────────────────────────────────────────────────────────────────────────
// get_orbital_pos  — Planet/Story only
// Returns the staging-ring grid cell {x, y} for the current orbit position.
// ─────────────────────────────────────────────────────────────────────────────
function get_orbital_pos(_side, _orbX) {
    var _s = ((_side % 4) + 4) % 4;  // normalise to 0-3
    var _x = 0, _y = 0;

    // Side 0 = TOP row (y=0), left-to-right as orbX increases
    if (_s == 0) { _x = 1 + _orbX;              _y = 0;  }
    // Side 1 = RIGHT col (x=10), top-to-bottom
    if (_s == 1) { _x = global.TOTAL_COLS - 1;  _y = 1 + _orbX; }
    // Side 2 = BOTTOM row (y=10), right-to-left (mirrors side 0)
    if (_s == 2) { _x = global.COLS - _orbX;    _y = global.TOTAL_ROWS - 1; }
    // Side 3 = LEFT col (x=0), bottom-to-top (mirrors side 1)
    if (_s == 3) { _x = 0;                      _y = global.ROWS - _orbX; }

    return { x: _x, y: _y };
}

// -----------------------------------------------------------------------------
// get_orbital_lane_bounds  — adaptive lane window for Planet/Story movement
// Returns { min, max, size } in orbitalX space (0..COLS-1).
// Bounds are derived from the current occupied planet silhouette PER SIDE:
// we sample the first occupied cell seen from that side for each lane index.
// This makes width shrink/grow correctly and supports asymmetry naturally.
// -----------------------------------------------------------------------------
function get_orbital_lane_bounds(_anchorX = -1) {
    var _cols = max(1, global.COLS);
    var _maxX = _cols - 1;
    var _s = ((global.orbitalSide % 4) + 4) % 4;
    var _minIdx = _maxX;
    var _maxIdx = 0;
    var _found = false;

    for (var _i = 0; _i < _cols; _i++) {
        var _hit = false;

        if (_s == 0) {
            var _gx = global.HIDDEN_SIDES + _i;
            for (var _gy = global.HIDDEN_ROWS; _gy < global.TOTAL_ROWS - global.HIDDEN_ROWS; _gy++) {
                if (global.grid[_gy][_gx] != undefined) { _hit = true; break; }
            }
        } else if (_s == 2) {
            var _gx2 = global.COLS - _i;
            for (var _gy2 = global.TOTAL_ROWS - global.HIDDEN_ROWS - 1; _gy2 >= global.HIDDEN_ROWS; _gy2--) {
                if (global.grid[_gy2][_gx2] != undefined) { _hit = true; break; }
            }
        } else if (_s == 1) {
            var _gy3 = global.HIDDEN_ROWS + _i;
            for (var _gx3 = global.TOTAL_COLS - global.HIDDEN_SIDES - 1; _gx3 >= global.HIDDEN_SIDES; _gx3--) {
                if (global.grid[_gy3][_gx3] != undefined) { _hit = true; break; }
            }
        } else {
            var _gy4 = global.ROWS - _i;
            for (var _gx4 = global.HIDDEN_SIDES; _gx4 < global.TOTAL_COLS - global.HIDDEN_SIDES; _gx4++) {
                if (global.grid[_gy4][_gx4] != undefined) { _hit = true; break; }
            }
        }

        if (_hit) {
            if (_i < _minIdx) _minIdx = _i;
            if (_i > _maxIdx) _maxIdx = _i;
            _found = true;
        }
    }

    if (!_found) {
        var _c = floor((_cols - 1) * 0.5);
        return { min: _c, max: _c, size: 1 };
    }

    return { min: _minIdx, max: _maxIdx, size: (_maxIdx - _minIdx + 1) };
}

// ─────────────────────────────────────────────────────────────────────────────
// generate_piece  — creates a piece data struct from the weighted pool
// ─────────────────────────────────────────────────────────────────────────────
function generate_piece() {
    if (global.level >= 5 && piece_rng_random(1) < 0.10)
        return { type: "dead",     color: c_dkgray, dir: 0, id: 999 };
    if (piece_rng_random(1) < 0.01 + (global.level * 0.0015))
        return { type: "bomb",     color: c_black,  dir: 0, id: 888 };
    if (global.level >= 1 && piece_rng_random(1) < 0.008 + (global.level * 0.001))
        return { type: "drill",    color: c_silver, dir: 0, id: 777 };
    if (piece_rng_random(1) < 0.15) {
        var _cid = global.activeColors[piece_rng_irandom(array_length(global.activeColors) - 1)];
        return { type: "metal", color: get_color_from_id(_cid), dir: (piece_rng_random(1) > 0.5 ? 1 : 0), id: _cid };
    }
    if (global.level >= 3 && piece_rng_random(1) < 0.05) {
        var _cid = global.activeColors[piece_rng_irandom(array_length(global.activeColors) - 1)];
        return { type: "asteroid", color: get_color_from_id(_cid), dir: 0, id: _cid, shield_hp: 2 };
    }
    var _cid = global.activeColors[piece_rng_irandom(array_length(global.activeColors) - 1)];
    return { type: "normal", color: get_color_from_id(_cid), dir: 0, id: _cid };
}

// ─────────────────────────────────────────────────────────────────────────────
// get_color_from_id  — maps color ID integer to an RGB colour
// ─────────────────────────────────────────────────────────────────────────────
function get_color_from_id(_id) {
    switch (_id) {
        case 1: return make_color_rgb(255, 107, 107); // Pink
        case 2: return make_color_rgb(255, 146,  43); // Orange
        case 3: return make_color_rgb(252, 196,  25); // Yellow
        case 4: return make_color_rgb(220,  50,  50); // Red
        case 5: return make_color_rgb(102, 217, 232); // Cyan
        case 6: return make_color_rgb( 80, 200,  80); // Green
        default: return c_white;
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// _place_block_instance  — internal helper
// Creates and configures an obj_block instance at the given grid cell.
// World pixel position: x=(gx-HIDDEN_SIDES)*16, y=(gy-HIDDEN_ROWS)*16
// ─────────────────────────────────────────────────────────────────────────────
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
    _inst.core_arrow = false;
    if (variable_struct_exists(_pieceData, "core_arrow")) {
        _inst.core_arrow = _pieceData.core_arrow;
    }
    with (_inst) update_sprite();
    return _inst;
}

// ─────────────────────────────────────────────────────────────────────────────
// spawn_piece  — pull from queue, create instance, check immediate game over
// ─────────────────────────────────────────────────────────────────────────────
function spawn_piece() {
    var _p = array_shift(global.nextQueue);
    array_push(global.nextQueue, generate_piece());

    var _gx, _gy;

    // ── PLANET / STORY ───────────────────────────────────────────────────────
    if (global.gameMode == "PLANET" || global.gameMode == "STORY") {
        var _lane = get_orbital_lane_bounds(global.orbitalX);
        global.orbitalX = clamp(global.orbitalX, _lane.min, _lane.max);
        var _pos = get_orbital_pos(global.orbitalSide, global.orbitalX);
        _gx = _pos.x;
        _gy = _pos.y;

        var _inst = _place_block_instance(_gx, _gy, _p);
        _inst.visualRotation = 0; // Exactly like blocks
        _inst.rotation = 0;

        global.activePiece  = _inst;
        global.canHold      = true;
        global.pieceTimer   = global.MAX_PIECE_TIME;
        global.launchCharge = 0;
        global.previewData  = calculate_planet_preview_path(global.activePiece);
        if (global.previewData != undefined) global.previewDepth = max(1, global.previewData.depth);
        else global.previewDepth = max(1, calculate_landing_depth(_gx, _gy));

        // Game over is handled by lock_piece (dist >= 5) when the piece can't enter the board.

    // ── CLASSIC ──────────────────────────────────────────────────────────────
    } else {
        _gx = floor(global.COLS / 2);
        _gy = 0; // hidden top row

        var _inst = _place_block_instance(_gx, _gy, _p);
        global.activePiece  = _inst;
        global.canHold      = true;
        global.launchCharge = 0;

        // Game over: spawn cell already occupied
        if (global.grid[_gy][_gx] != undefined && !global.grid[_gy][_gx].inst.clearing) {
            global.gameState = "GAMEOVER";
            sfx_game_over();
            if (global.score > global.highScore) {
                global.highScore = global.score;
                save_high_score();
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// hold_piece  — swap active piece into the hold slot
// ─────────────────────────────────────────────────────────────────────────────
function hold_piece() {
    if (!global.canHold || global.locking) return;

    var _outgoing = {
        type:  global.activePiece.type,
        color: global.activePiece.color,
        dir:   global.activePiece.dir,
        id:    global.activePiece.color_id,
        core_arrow: global.activePiece.core_arrow
    };
    instance_destroy(global.activePiece);
    global.activePiece = undefined;

    if (global.holdPiece == undefined) {
        // First hold — just stash and spawn normally
        global.holdPiece = _outgoing;
        spawn_piece();
    } else {
        // Swap: restore held piece at current orbital position
        var _p  = global.holdPiece;
        var _gx, _gy;

        // ── PLANET / STORY ───────────────────────────────────────────────────
        if (global.gameMode == "PLANET" || global.gameMode == "STORY") {
            var _lane = get_orbital_lane_bounds(global.orbitalX);
            global.orbitalX = clamp(global.orbitalX, _lane.min, _lane.max);
            var _pos = get_orbital_pos(global.orbitalSide, global.orbitalX);
            _gx = _pos.x;
            _gy = _pos.y;
        // ── CLASSIC ──────────────────────────────────────────────────────────
        } else {
            _gx = floor(global.COLS / 2);
            _gy = 0;
        }

        var _inst = _place_block_instance(_gx, _gy, _p);
        global.activePiece  = _inst;
        global.holdPiece    = _outgoing;
        if (global.gameMode == "PLANET" || global.gameMode == "STORY") {
            global.previewData = calculate_planet_preview_path(global.activePiece);
            if (global.previewData != undefined) global.previewDepth = max(1, global.previewData.depth);
            else global.previewDepth = max(1, calculate_landing_depth(_gx, _gy));
        } else {
            global.previewData = undefined;
            global.previewDepth = max(1, calculate_landing_depth(_gx, _gy));
        }
    }

    global.canHold = false;
}

// =============================================================================
// Story level seed/layout helpers
// =============================================================================

function story_level_catalog() {
    return [
        { world_id: 0, level_id: 0, seed: 1001, palette_count: 3, objective: { type: "clear_cores", value: 16 } },
        { world_id: 0, level_id: 1, seed: 1002, palette_count: 3, objective: { type: "clear_cores", value: 18 } },
        { world_id: 0, level_id: 2, seed: 1003, palette_count: 3, objective: { type: "clear_cores", value: 20 } },
        { world_id: 0, level_id: 3, seed: 1004, palette_count: 3, objective: { type: "score", value: 12000 } },

        { world_id: 1, level_id: 0, seed: 2001, palette_count: 3, objective: { type: "clear_cores", value: 22 } },
        { world_id: 1, level_id: 1, seed: 2002, palette_count: 3, objective: { type: "clear_cores", value: 24 } },
        { world_id: 1, level_id: 2, seed: 2003, palette_count: 4, objective: { type: "score", value: 18000 } },
        { world_id: 1, level_id: 3, seed: 2004, palette_count: 4, objective: { type: "clear_cores", value: 28 } },

        { world_id: 2, level_id: 0, seed: 3001, palette_count: 4, objective: { type: "clear_cores", value: 30 } },
        { world_id: 2, level_id: 1, seed: 3002, palette_count: 4, objective: { type: "score", value: 22000 } },
        { world_id: 2, level_id: 2, seed: 3003, palette_count: 4, objective: { type: "clear_cores", value: 34 } },
        { world_id: 2, level_id: 3, seed: 3004, palette_count: 4, objective: { type: "survive_waves", value: 6 } },

        { world_id: 3, level_id: 0, seed: 4001, palette_count: 4, objective: { type: "clear_cores", value: 38 } },
        { world_id: 3, level_id: 1, seed: 4002, palette_count: 5, full_palette: true, objective: { type: "survive_waves", value: 8 } },
        { world_id: 3, level_id: 2, seed: 4003, palette_count: 5, objective: { type: "score", value: 28000 } },
        { world_id: 3, level_id: 3, seed: 4004, palette_count: 5, full_palette: true, objective: { type: "clear_cores", value: 42 } },

        { world_id: 4, level_id: 0, seed: 5001, palette_count: 5, full_palette: true, objective: { type: "clear_cores", value: 48 } },
        { world_id: 4, level_id: 1, seed: 5002, palette_count: 5, full_palette: true, objective: { type: "score", value: 36000 } },
        { world_id: 4, level_id: 2, seed: 5003, palette_count: 6, objective: { type: "survive_waves", value: 10 } },
        { world_id: 4, level_id: 3, seed: 5004, palette_count: 6, full_palette: true, objective: { type: "clear_cores", value: 55 } }
    ];
}

function story_get_level_def(_worldId, _levelId) {
    var _cat = story_level_catalog();
    for (var i = 0; i < array_length(_cat); i++) {
        var _d = _cat[i];
        if (_d.world_id == _worldId && _d.level_id == _levelId) return _d;
    }
    return undefined;
}

function story_get_level_seed(_worldId, _levelId) {
    var _d = story_get_level_def(_worldId, _levelId);
    if (_d != undefined && variable_struct_exists(_d, "seed")) return _d.seed;
    // Deterministic fallback so every level always has a stable seed.
    return 100000 + (_worldId * 1000) + (_levelId * 37);
}

function story_place_cell(_gx, _gy, _type, _cid, _dir) {
    if (_gx < 0 || _gx >= global.TOTAL_COLS || _gy < 0 || _gy >= global.TOTAL_ROWS) return;
    if (global.grid[_gy][_gx] != undefined) return;
    var _data = { type: _type, color: get_color_from_id(_cid), dir: _dir, id: _cid, core_arrow: false };
    var _inst = _place_block_instance(_gx, _gy, _data);
    global.grid[_gy][_gx] = { type: _type, color: _data.color, dir: _dir, id: _cid, inst: _inst, core_arrow: false };
}

function story_apply_level_palette(_def, _seed) {
    var _oldSeed = random_get_seed();
    random_set_seed(_seed + 7919); // decorrelate from layout RNG stream

    var _pool = [1, 2, 3, 4, 5, 6];
    for (var _i = array_length(_pool) - 1; _i > 0; _i--) {
        var _j = irandom(_i);
        var _t = _pool[_i];
        _pool[_i] = _pool[_j];
        _pool[_j] = _t;
    }

    var _count = 3;
    if (_def != undefined && variable_struct_exists(_def, "palette_count")) _count = _def.palette_count;
    if (_def != undefined && variable_struct_exists(_def, "full_palette") && _def.full_palette) _count = array_length(_pool);
    _count = clamp(_count, 3, array_length(_pool));

    global.activeColors = [];
    global.reserveColors = [];
    for (var _a = 0; _a < array_length(_pool); _a++) {
        if (_a < _count) array_push(global.activeColors, _pool[_a]);
        else array_push(global.reserveColors, _pool[_a]);
    }

    random_set_seed(_oldSeed);
}

function story_apply_level_layout(_def) {
    if (_def == undefined) return false;

    var _oldSeed = random_get_seed();
    var _seed = story_get_level_seed(_def.world_id, _def.level_id);
    random_set_seed(_seed);
    story_apply_level_palette(_def, _seed);

    var _cx = floor(global.TOTAL_COLS / 2);
    var _cy = floor(global.TOTAL_ROWS / 2);

    // Always place one deterministic core first.
    var _coreCid = global.activeColors[irandom(array_length(global.activeColors) - 1)];
    story_place_cell(_cx, _cy, "core", _coreCid, 0);

    // Deterministic CONNECTED cluster generation (never scattered),
    // with difficulty scaling by world + level.
    var _rank = (_def.world_id * 10) + _def.level_id; // monotonic run index
    var _targetCount = clamp(6 + _rank, 6, 26); // denser over progression
    var _radius = clamp(2 + floor(_rank / 6), 2, 4); // opens up space gradually
    var _metalRate = clamp(0.03 + (_rank * 0.003), 0.03, 0.12);
    var _asteroidRate = clamp(0.02 + (_rank * 0.004), 0.02, 0.16);
    var _placed = [];
    array_push(_placed, {x: _cx, y: _cy});

    var _dirs = [[1,0],[-1,0],[0,1],[0,-1]];
    var _guard = 0;
    while (array_length(_placed) - 1 < _targetCount && _guard < 900) {
        _guard++;
        var _base = _placed[irandom(array_length(_placed) - 1)];
        var _d = _dirs[irandom(3)];
        var _rx = _base.x + _d[0];
        var _ry = _base.y + _d[1];

        if (_rx < global.HIDDEN_SIDES || _rx >= global.TOTAL_COLS - global.HIDDEN_SIDES) continue;
        if (_ry < global.HIDDEN_ROWS  || _ry >= global.TOTAL_ROWS - global.HIDDEN_ROWS) continue;
        if (global.grid[_ry][_rx] != undefined) continue;
        if (max(abs(_rx - _cx), abs(_ry - _cy)) > _radius) continue;

        var _cid = global.activeColors[irandom(array_length(global.activeColors) - 1)];
        var _roll = random(1);
        if (_roll < _metalRate) story_place_cell(_rx, _ry, "metal", _cid, (random(1) > 0.5 ? 1 : 0));
        else if (_roll < (_metalRate + _asteroidRate)) story_place_cell(_rx, _ry, "asteroid", _cid, 0);
        else story_place_cell(_rx, _ry, "normal", _cid, 0);

        array_push(_placed, {x: _rx, y: _ry});
    }

    random_set_seed(_oldSeed);

    global.storyLevelSeed = _seed;
    global.storyLevelDef = _def;
    global.storyObjectiveType = _def.objective.type;
    global.storyObjectiveValue = _def.objective.value;
    if (_def.objective.type == "clear_cores") global.storyTarget = _def.objective.value;

    return true;
}
