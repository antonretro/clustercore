// Returns { x, y } staging-ring grid position for a given orbital side + position.
// Single source of truth — used by spawn_piece, hold_piece, and Step_0 input.
function get_orbital_pos(_side, _orbX) {
    var _s = (_side % 4 + 4) % 4;
    var _x = 0, _y = 0;
    if (_s == 0) { _x = _orbX;                         _y = global.HIDDEN_ROWS - 1; }
    if (_s == 1) { _x = global.COLS;                    _y = global.HIDDEN_ROWS + _orbX; }
    if (_s == 2) { _x = (global.COLS - 1) - _orbX;     _y = global.TOTAL_ROWS; }
    if (_s == 3) { _x = -1;                             _y = (global.TOTAL_ROWS - 1) - _orbX; }
    return { x: _x, y: _y };
}

function generate_piece() {
    if (global.level >= 5 && random(1) < 0.10) {
        return { type: "dead", color: c_dkgray, dir: 0, id: 999 };
    }
    if (random(1) < 0.02 + (global.level * 0.005)) {
        return { type: "bomb", color: c_black, dir: 0, id: 888 };
    }
    if (global.level >= 1 && random(1) < 0.015 + (global.level * 0.0025)) {
        return { type: "drill", color: c_silver, dir: 0, id: 777 };
    }
    if (random(1) < 0.15) {
        var _colorId = global.activeColors[irandom(array_length(global.activeColors) - 1)];
        var _dir = (random(1) > 0.5 ? 1 : 0);
        return { type: "metal", color: get_color_from_id(_colorId), dir: _dir, id: _colorId };
    }
    
    if (global.level >= 3 && random(1) < 0.05) {
        var _colorId = global.activeColors[irandom(array_length(global.activeColors) - 1)];
        return { type: "asteroid", color: get_color_from_id(_colorId), dir: 0, id: _colorId, shield_hp: 2 };
    }
    
    var _colorId = global.activeColors[irandom(array_length(global.activeColors) - 1)];
    return { type: "normal", color: get_color_from_id(_colorId), dir: 0, id: _colorId };
}

function get_color_from_id(_id) {
    switch(_id) {
        case 1: return make_color_rgb(255, 107, 107); // Pink
        case 2: return make_color_rgb(255, 146, 43);  // Orange
        case 3: return make_color_rgb(252, 196, 25);  // Yellow
        case 4: return make_color_rgb(220, 50,  50);  // Red
        case 5: return make_color_rgb(102, 217, 232); // Cyan
        case 6: return make_color_rgb(80,  200, 80);  // Green
        default: return c_white;
    }
}

function spawn_piece() {
    var _p = array_shift(global.nextQueue);
    array_push(global.nextQueue, generate_piece());

    var _nx = floor(global.COLS / 2);
    var _ny = 0;

    if (global.gameMode == "PLANET" || global.gameMode == "STORY") {
        var _pos = get_orbital_pos(global.orbitalSide, global.orbitalX);
        _nx = _pos.x;
        _ny = _pos.y;
    }

    var _inst = instance_create_layer(_nx * 16, (_ny - global.HIDDEN_ROWS) * 16, "Instances", obj_block);
    _inst.type     = _p.type;
    _inst.color    = _p.color;
    _inst.dir      = _p.dir;
    _inst.color_id = _p.id;
    _inst.grid_x   = _nx;
    _inst.grid_y   = _ny;
    with(_inst) update_sprite();

    global.activePiece  = _inst;
    global.canHold      = true;
    global.pieceTimer   = global.MAX_PIECE_TIME;
    global.launchCharge = 0;
    global.previewDepth = max(1, calculate_landing_depth(_nx, _ny));

    // --- GAME OVER CHECK ---
    var _isOver = false;
    if (global.gameMode == "PLANET" || global.gameMode == "STORY") {
        // Game over only when the piece can't enter the board at all (stuck in staging ring)
        var _cx = floor(global.COLS / 2);
        var _cy = global.HIDDEN_ROWS + floor(global.ROWS / 2);
        if (_nx == _cx && _ny == _cy) {
            _isOver = true; // spawned exactly at center — completely full
        } else {
            _isOver = (calculate_landing_depth(_nx, _ny) == 0);
        }
    } else {
        if (_nx >= 0 && _nx < global.COLS && _ny >= 0 && _ny < global.TOTAL_ROWS) {
            var _occupant = global.grid[_ny][_nx];
            _isOver = (_occupant != undefined && !_occupant.inst.clearing);
        }
    }

    if (_isOver) {
        global.gameState = "GAMEOVER";
        sfx_game_over();
        if (global.score > global.highScore) {
            global.highScore = global.score;
            save_high_score();
        }
    }
}

function hold_piece() {
    if (!global.canHold || global.locking) return;
    
    if (global.holdPiece == undefined) {
        global.holdPiece = {
            type: global.activePiece.type,
            color: global.activePiece.color,
            dir: global.activePiece.dir,
            id: global.activePiece.color_id
        };
        instance_destroy(global.activePiece);
        spawn_piece();
    } else {
        var _temp = {
            type: global.activePiece.type,
            color: global.activePiece.color,
            dir: global.activePiece.dir,
            id: global.activePiece.color_id
        };
        
        var _p = global.holdPiece;
        var _spawnX = floor(global.COLS / 2);
        var _spawnY = 0;
        if (global.gameMode == "PLANET" || global.gameMode == "STORY") {
            var _pos = get_orbital_pos(global.orbitalSide, global.orbitalX);
            _spawnX = _pos.x;
            _spawnY = _pos.y;
        }

        instance_destroy(global.activePiece);

        var _inst = instance_create_layer(_spawnX * 16, (_spawnY - global.HIDDEN_ROWS) * 16, "Instances", obj_block);
        _inst.type     = _p.type;
        _inst.color    = _p.color;
        _inst.dir      = _p.dir;
        _inst.color_id = _p.id;
        _inst.grid_x   = _spawnX;
        _inst.grid_y   = _spawnY;
        with(_inst) update_sprite();

        global.activePiece  = _inst;
        global.holdPiece    = _temp;
        global.previewDepth = max(1, calculate_landing_depth(_spawnX, _spawnY));
    }
    
    global.canHold = false;
}
