// =============================================================================
// scr_piece_logic — Piece spawning, holding, and orbital positioning
//
// PLANET/STORY coordinate contract:
//   Staging ring occupies the outer ring of the 11x11 grid:
//     Top row:    y=0,  x=1..9   (side 0)
//     Right col:  x=10, y=1..9   (side 1)
//     Bottom row: y=10, x=9..1   (side 2, reversed so left=ccw)
//     Left col:   x=0,  y=9..1   (side 3, reversed)
//   orbitalX ranges 0..(COLS-1) i.e. 0..8
//
// Block world pixel position (stored on the instance):
//   inst.x = (grid_x - global.HIDDEN_SIDES) * 16
//   inst.y = (grid_y - global.HIDDEN_ROWS)  * 16
//
// The Draw event scales by PIXEL_SCALE and offsets by _bx/_by.
// =============================================================================

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

// ─────────────────────────────────────────────────────────────────────────────
// generate_piece  — creates a piece data struct from the weighted pool
// ─────────────────────────────────────────────────────────────────────────────
function generate_piece() {
    if (global.level >= 5 && random(1) < 0.10)
        return { type: "dead",     color: c_dkgray, dir: 0, id: 999 };
    if (random(1) < 0.02 + (global.level * 0.005))
        return { type: "bomb",     color: c_black,  dir: 0, id: 888 };
    if (global.level >= 1 && random(1) < 0.015 + (global.level * 0.0025))
        return { type: "drill",    color: c_silver, dir: 0, id: 777 };
    if (random(1) < 0.15) {
        var _cid = global.activeColors[irandom(array_length(global.activeColors) - 1)];
        return { type: "metal", color: get_color_from_id(_cid), dir: (random(1) > 0.5 ? 1 : 0), id: _cid };
    }
    if (global.level >= 3 && random(1) < 0.05) {
        var _cid = global.activeColors[irandom(array_length(global.activeColors) - 1)];
        return { type: "asteroid", color: get_color_from_id(_cid), dir: 0, id: _cid, shield_hp: 2 };
    }
    var _cid = global.activeColors[irandom(array_length(global.activeColors) - 1)];
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
        var _pos = get_orbital_pos(global.orbitalSide, global.orbitalX);
        _gx = _pos.x;
        _gy = _pos.y;

        var _inst = _place_block_instance(_gx, _gy, _p);

        // Drills auto-orient to point inward from their staging side
        if (_p.type == "drill") {
            var _s = ((global.orbitalSide % 4) + 4) % 4;
            if (_s == 0) { _inst.dir = 1; _inst.visualRotation =   0; } // top    → drill downward
            if (_s == 1) { _inst.dir = 0; _inst.visualRotation = 270; } // right  → drill leftward
            if (_s == 2) { _inst.dir = 1; _inst.visualRotation = 180; } // bottom → drill upward
            if (_s == 3) { _inst.dir = 0; _inst.visualRotation =  90; } // left   → drill rightward
            _inst.rotation = 0;
        }

        global.activePiece  = _inst;
        global.canHold      = true;
        global.pieceTimer   = global.MAX_PIECE_TIME;
        global.launchCharge = 0;
        global.previewDepth = max(1, calculate_landing_depth(_gx, _gy));

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
        id:    global.activePiece.color_id
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
        global.previewDepth = max(1, calculate_landing_depth(_gx, _gy));
    }

    global.canHold = false;
}
