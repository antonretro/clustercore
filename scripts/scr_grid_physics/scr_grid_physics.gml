function check_collision(_dx, _dy) {
    var _nx = global.activePiece.grid_x + _dx;
    var _ny = global.activePiece.grid_y + _dy;
    
    if (_nx < 0 || _nx >= global.COLS || _ny >= global.TOTAL_ROWS) return true;
    if (global.grid[_ny][_nx] != undefined) return true;
    
    return false;
}

function hard_drop() {
    var _startY = global.activePiece.grid_y;
    while (!check_collision(0, 1)) {
        global.activePiece.grid_y += 1;
    }
    var _endY = global.activePiece.grid_y;

    if (_endY > _startY) {
        create_beam(global.activePiece.grid_x * 16, (_startY - global.HIDDEN_ROWS) * 16, 16, (_endY - _startY) * 16, global.activePiece.color);
        var _trailColor = global.activePiece.color;
        var _trailX    = global.activePiece.grid_x * 16 + 8;
        for (var _ty = _startY; _ty < _endY; _ty++) {
            if (_ty >= global.HIDDEN_ROWS) {
                create_trail_particles(_trailX, (_ty - global.HIDDEN_ROWS) * 16 + 8, _trailColor);
            }
        }
    }

    sfx_hard_drop();
    lock_piece();
}

function rotate_piece() {
    if (global.activePiece.type == "metal") {
        global.activePiece.dir = (global.activePiece.dir == 0 ? 1 : 0);
    }
}

function lock_piece() {
    global.locking = true;
    var _p = global.activePiece;
    var _px = _p.grid_x;
    var _py = _p.grid_y;
    
    // --- Special Ability: Drill ---
    if (_p.type == "drill") {
        var _bx_calc = (global.GAME_W - (global.COLS * 16 * global.PIXEL_SCALE)) / 2;
        var _by_calc = (global.GAME_H - (global.ROWS * 16 * global.PIXEL_SCALE)) / 2;
        var _tx = _bx_calc + (_px * 16 * global.PIXEL_SCALE) + (8 * global.PIXEL_SCALE);
        var _ty = _by_calc + ((_py - global.HIDDEN_ROWS) * 16 * global.PIXEL_SCALE);
        
        create_floating_text_ext(_tx, _ty, "DRILL PAYOUT", c_white, 1.6);
        if (global.settings.shakeEnabled) global.shakeAmount = 5;
        global.hitstop = 4;
        sfx_drill();
        var _drilled = 0;
        for (var i = 0; i < global.TOTAL_ROWS; i++) {
            var _cell = global.grid[i][_px];
            if (_cell != undefined) {
                create_particles(_px * 16 + 8, i * 16 + 8, c_white);
                _cell.inst.clearing = true;
                global.grid[i][_px] = undefined;
                _drilled++;
            }
        }
        create_beam(_px * 16, 0, 16, global.TOTAL_ROWS * 16, c_white);
        
        if (_drilled > 0) {
            var _drillPoints = _drilled * 150 * ((global.feverTimer > 0) ? 2 : 1);
            global.score += _drillPoints;
            global.levelScore += _drillPoints;
            global.ui_scales.score = 1.3;
            award_shards(_drillPoints, _drilled);
            charge_jackpot(_drilled + 2);
            update_level_progress();
        }
        instance_destroy(_p);
        global.activePiece = undefined;
        apply_grid_gravity();
        alarm[0] = 10;
        return;
    }
    
    // --- Special Ability: Bomb ---
    if (_p.type == "bomb") {
        var _bx_calc = (global.GAME_W - (global.COLS * 16 * global.PIXEL_SCALE)) / 2;
        var _by_calc = (global.GAME_H - (global.ROWS * 16 * global.PIXEL_SCALE)) / 2;
        var _tx = _bx_calc + (_px * 16 * global.PIXEL_SCALE) + (8 * global.PIXEL_SCALE);
        var _ty = _by_calc + ((_py - global.HIDDEN_ROWS) * 16 * global.PIXEL_SCALE);
        
        create_floating_text(_tx, _ty, "BOOM!");
        if (global.settings.shakeEnabled) global.shakeAmount = 8;
        global.hitstop = 6;
        sfx_bomb();
        for (var _dy = -1; _dy <= 1; _dy++) {
            for (var _dx = -1; _dx <= 1; _dx++) {
                var _nx = _px + _dx;
                var _ny = _py + _dy;
                if (_nx >= 0 && _nx < global.COLS && _ny >= 0 && _ny < global.TOTAL_ROWS) {
                    var _cell = global.grid[_ny][_nx];
                    if (_cell != undefined) {
                        create_particles(_nx * 16 + 8, _ny * 16 + 8, c_orange);
                        _cell.inst.clearing = true;
                        global.grid[_ny][_nx] = undefined;
                    }
                }
            }
        }
        instance_destroy(_p);
        global.activePiece = undefined;
        apply_grid_gravity();
        alarm[0] = 10;
        return;
    }

    _p.scale_x = 1.4;
    _p.scale_y = 0.7;
    create_impact(0, (_py - global.HIDDEN_ROWS + 1) * 16, global.COLS * 16, _p.color);
    global.hitstop = 2;
    sfx_piece_lock();
    
    global.grid[_py][_px] = {
        type: _p.type,
        color: _p.color,
        dir: _p.dir,
        id: _p.color_id,
        inst: _p
    };
    
    global.activePiece = undefined;
    if (global.settings.shakeEnabled) global.shakeAmount = 2;
    settle_matches();
}

function settle_matches() {
    var _matches = find_matches_in_grid(global.grid, {cols: global.COLS}, global.TOTAL_ROWS);
    
    if (array_length(_matches) > 0) {
        global.comboChain++;
        global.bestCombo = max(global.bestCombo, global.comboChain);
        global.hitstop = 2 + min(global.comboChain, 4);
        sfx_clear(array_length(_matches), global.comboChain);
        var _feverMult = (global.feverTimer > 0) ? 2 : 1;
        var _points = array_length(_matches) * 100 * global.comboChain * _feverMult;
        global.score += _points;
        global.levelScore += _points;
        global.ui_scales.score = 1.25;
        global.ui_scales.combo = 1.4;
        update_level_progress();
        
        var _bx_calc = (global.GAME_W - (global.COLS * 16 * global.PIXEL_SCALE)) / 2;
        var _by_calc = (global.GAME_H - (global.ROWS * 16 * global.PIXEL_SCALE)) / 2;

        if (array_length(_matches) >= 6) {
            create_floating_text_ext(global.GAME_W * 0.5, global.GAME_H * 0.4, "MEGA CLEAR!!", c_white, 2.0);
            if (global.settings.shakeEnabled) global.shakeAmount = 15;
            global.ui_scales.score = 1.5;
        } else if (global.comboChain > 1) {
            create_floating_text_ext(global.GAME_W * 0.5, global.GAME_H * 0.45, "COMBO x" + string(global.comboChain), global.COLOR_GLOW, 1.5);
        }
        
        // Award Shards & Jackpot
        award_shards(_points, array_length(_matches));
        charge_jackpot(array_length(_matches));
        
        for (var i = 0; i < array_length(_matches); i++) {
            var _m = _matches[i];
            var _cell = global.grid[_m.y][_m.x];
            if (_cell != undefined) {
                // Show point value for EVERY block (User Request)
                var _ptX = _bx_calc + (_m.x * 16 * global.PIXEL_SCALE) + (8 * global.PIXEL_SCALE);
                var _ptY = _by_calc + ((_m.y - global.HIDDEN_ROWS) * 16 * global.PIXEL_SCALE);
                create_floating_text_ext(_ptX, _ptY, "+100", _cell.color, 0.8);
                
                create_particles(_m.x * 16 + 8, _m.y * 16 + 8, _cell.color);
                _cell.inst.clearing = true;
                global.grid[_m.y][_m.x] = undefined;
            }
        }
        
        apply_grid_gravity();
        alarm[0] = 15; 
    } else {
        global.locking = false;
        global.comboChain = 0;
        if (check_game_over()) {
            global.gameState = "GAMEOVER";
            if (global.score > global.highScore) {
                global.highScore = global.score;
                save_high_score();
            }
            sfx_game_over();
        } else {
            spawn_piece();
        }
    }
}

function apply_grid_gravity() {
    for (var _x = 0; _x < global.COLS; _x++) {
        for (var _y = global.TOTAL_ROWS - 1; _y >= 0; _y--) {
            if (global.grid[_y][_x] == undefined) {
                for (var _yy = _y - 1; _yy >= 0; _yy--) {
                    if (global.grid[_yy][_x] != undefined) {
                        global.grid[_y][_x] = global.grid[_yy][_x];
                        global.grid[_yy][_x] = undefined;
                        
                        var _inst = global.grid[_y][_x].inst;
                        _inst.grid_y = _y;
                        break;
                    }
                }
            }
        }
    }
}

function check_game_over() {
    for (var _y = 0; _y < global.HIDDEN_ROWS; _y++) {
        for (var _x = 0; _x < global.COLS; _x++) {
            if (global.grid[_y][_x] != undefined) return true;
        }
    }
    return false;
}

function move_piece(_dx, _dy) {
    if (global.activePiece == undefined || global.locking) return;
    
    if (!check_collision(_dx, _dy)) {
        global.activePiece.grid_x += _dx;
        global.activePiece.grid_y += _dy;
        
        if (_dx != 0) {
            global.activePiece.scale_x = 0.8;
            global.activePiece.scale_y = 1.2;
        }
    }
}
