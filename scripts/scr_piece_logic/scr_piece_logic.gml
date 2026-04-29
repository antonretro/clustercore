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
    
    var _spawnX = floor(global.COLS / 2);

    var _inst = instance_create_layer(_spawnX * 16, 0, "Instances", obj_block);
    _inst.type = _p.type;
    _inst.color = _p.color;
    _inst.dir = _p.dir;
    _inst.color_id = _p.id;
    _inst.grid_x = _spawnX;
    _inst.grid_y = 0;
    
    with(_inst) update_sprite();
    
    global.activePiece = _inst;
    global.canHold = true;

    // --- IMMEDIATE GAME OVER CHECK ---
    // If the spawn location is already blocked, it's a Top-Out!
    if (global.grid[0][_spawnX] != undefined) {
        global.gameState = "GAMEOVER";
        sfx_game_over(); // Use the sound the user added
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
        
        instance_destroy(global.activePiece);
        
        var _inst = instance_create_layer(_spawnX * 16, 0, "Instances", obj_block);
        _inst.type = _p.type;
        _inst.color = _p.color;
        _inst.dir = _p.dir;
        _inst.color_id = _p.id;
        _inst.grid_x = _spawnX;
        _inst.grid_y = global.HIDDEN_ROWS;
        with(_inst) update_sprite();
        
        global.activePiece = _inst;
        global.holdPiece = _temp;
    }
    
    global.canHold = false;
}
