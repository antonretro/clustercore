function check_collision(_dx, _dy) {
    var _nx = global.activePiece.grid_x + _dx;
    var _ny = global.activePiece.grid_y + _dy;
    
    if (_nx < 0 || _nx >= global.COLS || _ny < 0 || _ny >= global.TOTAL_ROWS) return true;
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
    if (global.activePiece == undefined) return;
    
    // Scale Pulse (Juice)
    global.activePiece.scale_x = 1.25;
    global.activePiece.scale_y = 1.25;
    
    // Gameplay Logic: only arrow blocks have meaningful rotation.
    if (global.activePiece.type == "metal") {
        global.activePiece.dir = (global.activePiece.dir == 0 ? 1 : 0);
    }
}

function story_advance_planet() {
    global.locking = false;
    global.storyPlanet++;
    
    if (global.storyPlanet >= array_length(global.storyPlanets)) {
        global.storyComplete = true;
        global.gameState = "GAMEOVER";
        create_floating_text_ext(global.GAME_W * 0.5, global.GAME_H * 0.34, "STORY CLEAR!", c_yellow, 2.4);
        return;
    }
    
    create_floating_text_ext(global.GAME_W * 0.5, global.GAME_H * 0.34, "PLANET CLEARED", global.COLOR_GLOW, 2.0);
    with (obj_game_manager) {
        start_game();
    }
}

function lock_piece() {
    global.locking = true;
    var _p = global.activePiece;
    var _px = _p.grid_x;
    var _py = _p.grid_y;
    
    // --- Establish Planet Core (First piece to hit center) ---
    var _cx_core = floor(global.COLS / 2);
    var _cy_core = global.HIDDEN_ROWS + floor(global.ROWS / 2);
    if (_px == _cx_core && _py == _cy_core && (global.gameMode == "PLANET" || global.gameMode == "STORY")) {
        _p.type = "core";
        with(_p) update_sprite();
        var _bx_core = (global.GAME_W - (global.COLS * 16 * global.PIXEL_SCALE)) / 2;
        var _by_core = (global.GAME_H - (global.ROWS * 16 * global.PIXEL_SCALE)) / 2;
        var _ftx = _bx_core + (_px * 16 * global.PIXEL_SCALE) + (8 * global.PIXEL_SCALE);
        var _fty = _by_core + ((_py - global.HIDDEN_ROWS) * 16 * global.PIXEL_SCALE);
        create_floating_text_ext(_ftx, _fty, "CORE ESTABLISHED!", c_white, 1.4);
    }
    
    // --- Special Ability: Drill ---
    if (_p.type == "drill") {
        // --- Calculate Screen Position for Floating Text (Rotate with Board) ---
        var _bx_calc = (global.GAME_W - (global.COLS * 16 * global.PIXEL_SCALE)) / 2;
        var _by_calc = (global.GAME_H - (global.ROWS * 16 * global.PIXEL_SCALE)) / 2;
        var _tx_raw = _bx_calc + (_px * 16 * global.PIXEL_SCALE) + (8 * global.PIXEL_SCALE);
        var _ty_raw = _by_calc + ((_py - global.HIDDEN_ROWS) * 16 * global.PIXEL_SCALE);
        
        // Rotate point around screen center to match board rotation
        var _cx_screen = global.GAME_W / 2;
        var _cy_screen = global.GAME_H / 2;
        var _angle = degtorad(global.boardRotation);
        var _tx = _cx_screen + (_tx_raw - _cx_screen) * cos(_angle) - (_ty_raw - _cy_screen) * sin(_angle);
        var _ty = _cy_screen + (_tx_raw - _cx_screen) * sin(_angle) + (_ty_raw - _cy_screen) * cos(_angle);
        
        create_floating_text_ext(_tx, _ty, "DRILL PAYOUT", c_white, 1.6);
        if (global.settings.shakeEnabled) global.shakeAmount = 12;
        global.hitstop = 4;
        sfx_drill();
        
        var _drilled = 0;
        
        if (global.gameMode == "PLANET" || global.gameMode == "STORY") {
            // --- PIERCING RADIAL DRILL: Path through the entire planet ---
            var _gx = _px;
            var _gy = _py;
            var _cx_grid = floor(global.COLS / 2);
            var _cy_grid = global.HIDDEN_ROWS + floor(global.ROWS / 2);

            // Direction = dominant axis from landing position toward center
            var _vx = 0;
            var _vy = 0;
            var _adx = abs(_px - _cx_grid);
            var _ady = abs(_py - _cy_grid);
            if (_adx >= _ady) {
                _vx = (_px <= _cx_grid) ? 1 : -1; // farther on X → drill horizontally
            } else {
                _vy = (_py <= _cy_grid) ? 1 : -1; // farther on Y → drill vertically
            }
            if (_vx == 0 && _vy == 0) _vy = 1;

            while (true) {
                var _cell = global.grid[_gy][_gx];
                if (_cell != undefined) {
                    if (_cell.type == "core") migrate_core(_gx, _gy);
                    create_particles(_gx * 16 + 8, (_gy - global.HIDDEN_ROWS) * 16 + 8, c_white);
                    _cell.inst.clearing = true;
                    global.grid[_gy][_gx] = undefined;
                    _drilled++;
                }
                
                // Visual Beam Segment
                create_beam(_gx * 16, (_gy - global.HIDDEN_ROWS) * 16, 16, 16, c_white);
                
                // STOP AT THE CENTER
                if (_gx == _cx_grid && _gy == _cy_grid) break;
                
                _gx += _vx;
                _gy += _vy;
                
                if (_gx < 0 || _gx >= global.COLS || _gy < 0 || _gy >= global.TOTAL_ROWS) break;
            }
        } else {
            // --- CLASSIC DRILL: Full Column ---
            for (var i = 0; i < global.TOTAL_ROWS; i++) {
                var _cell = global.grid[i][_px];
                if (_cell != undefined && _cell.type != "core") {
                    create_particles(_px * 16 + 8, (i - global.HIDDEN_ROWS) * 16 + 8, c_white);
                    _cell.inst.clearing = true;
                    global.grid[i][_px] = undefined;
                    _drilled++;
                }
            }
            create_beam(_px * 16, 0, 16, (global.TOTAL_ROWS - global.HIDDEN_ROWS) * 16, c_white);
        }
        
        if (_drilled > 0) {
            var _drillPoints = _drilled * 150 * ((global.feverTimer > 0) ? 2 : 1);
            global.score += _drillPoints;
            global.levelScore += _drillPoints;
            if (global.gameMode == "STORY") {
                global.storyCleared += _drilled;
            }
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
        
        // Place bomb temporarily to include it in the blast loop
        global.grid[_py][_px] = { type: "bomb", color: _p.color, id: _p.color_id, inst: _p };
        
        create_impact(0, (_py - global.HIDDEN_ROWS + 1) * 16, global.COLS * 16, c_orange);
        create_floating_text_ext(_tx, _ty, "ULTRA BLAST!", c_orange, 1.5);
        if (global.settings.shakeEnabled) global.shakeAmount = 15;
        global.hitstop = 8;
        sfx_bomb();

        var _blasted = 0;
        // 5x5 Diamond Radius for "Ultra Blast"
        for (var _dy = -2; _dy <= 2; _dy++) {
            for (var _dx = -2; _dx <= 2; _dx++) {
                if (abs(_dx) + abs(_dy) > 3) continue; // Diamond shape
                
                var _nx = _px + _dx;
                var _ny = _py + _dy;
                if (_nx >= 0 && _nx < global.COLS && _ny >= 0 && _ny < global.TOTAL_ROWS) {
                    var _cell = global.grid[_ny][_nx];
                    if (_cell != undefined && _cell.type != "core") {
                        create_particles(_nx * 16 + 8, (_ny - global.HIDDEN_ROWS) * 16 + 8, c_orange);
                        _cell.inst.clearing = true;
                        global.grid[_ny][_nx] = undefined;
                        _blasted++;
                    }
                    
                    // Extra explosion particles even on empty air
                    if (random(1) < 0.3) create_particles(_nx * 16 + 8, (_ny - global.HIDDEN_ROWS) * 16 + 8, c_white);
                }
            }
        }

        if (global.gameMode == "STORY") global.storyCleared += _blasted;
        
        instance_destroy(_p); // Explicitly destroy the bomb piece
        global.activePiece = undefined;
        apply_grid_gravity();
        alarm[0] = 12;
        return;
    }

    _p.scale_x = 1.6; // Squash
    _p.scale_y = 0.6; // Stretch
    create_impact(0, (_py - global.HIDDEN_ROWS + 1) * 16, global.COLS * 16, _p.color);
    global.hitstop = 3;
    if (global.settings.shakeEnabled) global.shakeAmount = 4; // Beefier shake
    sfx_piece_lock();
    
    global.grid[_py][_px] = {
        type: _p.type,
        color: _p.color,
        dir: _p.dir,
        id: _p.color_id,
        inst: _p
    };
    
    // --- MAGNETIC PULSE: Max Charge shots pull their own color ---
    if (global.launchCharge >= global.MAX_CHARGE) {
        var _targetX = _px;
        var _targetY = _py;
        var _color = _p.color;
        
        // Emit Pulse
        for (var _y = global.HIDDEN_ROWS; _y < global.TOTAL_ROWS; _y++) {
            for (var _x = 0; _x < global.COLS; _x++) {
                var _cell = global.grid[_y][_x];
                if (_cell != undefined && _cell.color == _color && (_x != _targetX || _y != _targetY)) {
                    var _pdx = sign(_targetX - _x);
                    var _pdy = sign(_targetY - _y);
                    
                    // Prioritize axis toward the magnet
                    if (abs(_targetX - _x) >= abs(_targetY - _y)) _pdy = 0; else _pdx = 0;
                    
                    var _px_new = _x + _pdx;
                    var _py_new = _y + _pdy;
                    
                    if (_px_new >= 0 && _px_new < global.COLS && _py_new >= 0 && _py_new < global.TOTAL_ROWS) {
                        if (global.grid[_py_new][_px_new] == undefined) {
                            global.grid[_py_new][_px_new] = _cell;
                            global.grid[_y][_x] = undefined;
                            _cell.inst.grid_x = _px_new;
                            _cell.inst.grid_y = _py_new;
                            _cell.inst.x = _px_new * 16;
                            _cell.inst.y = (_py_new - global.HIDDEN_ROWS) * 16;
                        }
                    }
                }
            }
        }
        sfx_drill(); // Use drill sfx for now as a placeholder for pulse
    }

    global.activePiece = undefined;
    if (global.settings.shakeEnabled) global.shakeAmount = 2;
    
    apply_grid_gravity();
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
        if (global.gameMode == "STORY") {
            global.storyCleared += array_length(_matches);
        }
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
                var _inst = _cell.inst;
                
                // --- PLANET CORE LOGIC (Migrate on match) ---
                if (_cell.type == "core") {
                    migrate_core(_m.x, _m.y);
                    // Core is cleared, so we don't 'continue' anymore. 
                    // It will be cleared below with the rest of the match.
                }
                
                // --- ASTEROID BLOCK LOGIC ---
                if (_cell.type == "asteroid" && _inst.shield_hp > 1) {
                    _inst.shield_hp--;
                    _inst.scale_x = 1.3; _inst.scale_y = 1.3; // Impact pulse
                    with(_inst) update_sprite();
                    create_particles(_m.x * 16 + 8, _m.y * 16 + 8, make_color_rgb(100, 100, 100)); // Stone dust
                    continue; // Do not clear yet!
                }
                
                // Show point value for EVERY block (User Request)
                var _ptX = _bx_calc + (_m.x * 16 * global.PIXEL_SCALE) + (8 * global.PIXEL_SCALE);
                var _ptY = _by_calc + ((_m.y - global.HIDDEN_ROWS) * 16 * global.PIXEL_SCALE);
                create_floating_text_ext(_ptX, _ptY, "+100", _cell.color, 0.8);
                
                create_particles(_m.x * 16 + 8, _m.y * 16 + 8, _cell.color);
                
                // Blocks are destroyed in both modes now
                _inst.clearing = true;
                global.grid[_m.y][_m.x] = undefined;
            }
        }
        
        apply_grid_gravity();
        alarm[0] = 15; 
    } else {
        global.locking = false;
        global.comboChain = 0;
        // Hint: tell the player how many more blocks they need
        var _bestCluster = debug_largest_cluster_size();
        if (_bestCluster > 0 && _bestCluster < 4) {
            var _need = 4 - _bestCluster;
            create_floating_text_ext(global.GAME_W * 0.5, global.GAME_H * 0.55,
                "NEED " + string(_need) + " MORE", make_color_rgb(200, 200, 200), 0.9);
        }
        if (global.gameMode == "STORY" && global.coresCleared >= global.storyTarget) {
            story_advance_planet();
            return;
        }
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

function check_game_over() {
    for (var _y = 0; _y < global.HIDDEN_ROWS; _y++) {
        for (var _x = 0; _x < global.COLS; _x++) {
            if (global.grid[_y][_x] != undefined) return true;
        }
    }
    return false;
}

function move_piece(_dx, _dy) {
    if (global.activePiece == undefined || global.locking) return false;
    
    if (!check_collision(_dx, _dy)) {
        global.activePiece.grid_x += _dx;
        global.activePiece.grid_y += _dy;
        
        if (_dx != 0) {
            global.activePiece.scale_x = 0.8;
            global.activePiece.scale_y = 1.2;
        }
        return true;
    }
    
    return false;
}

function rotate_grid_90() {
    var _newGrid = array_create(global.TOTAL_ROWS);
    for (var i = 0; i < global.TOTAL_ROWS; i++) {
        _newGrid[i] = array_create(global.COLS, undefined);
    }

    // New X = (Size-1) - Y, New Y = X
    var _coreCell = undefined;
    for (var _y = 0; _y < global.TOTAL_ROWS; _y++) {
        for (var _x = 0; _x < global.COLS; _x++) {
            var _cell = global.grid[_y][_x];
            if (_cell != undefined) {
                if (_cell.type == "core") {
                    _coreCell = _cell;
                    continue;
                }
                
                var _nx = (global.TOTAL_ROWS - 1) - _y;
                var _ny = _x;
                
                if (_nx >= 0 && _nx < global.COLS && _ny >= 0 && _ny < global.TOTAL_ROWS) {
                    _newGrid[_ny][_nx] = _cell;
                    _cell.inst.grid_x = _nx;
                    _cell.inst.grid_y = _ny;
                }
            }
        }
    }
    
    // Re-place the fixed core in the center
    if (_coreCell != undefined) {
        var _cx = floor(global.COLS / 2);
        var _cy = global.HIDDEN_ROWS + floor(global.ROWS / 2);
        _newGrid[_cy][_cx] = _coreCell;
        _coreCell.inst.grid_x = _cx;
        _coreCell.inst.grid_y = _cy;
    }
    
    global.grid = _newGrid;
    settle_matches();
}

function move_piece_radial() {
    if (global.activePiece == undefined || global.locking) return false;
    
    var _cx = floor(global.COLS / 2);
    var _cy = global.HIDDEN_ROWS + floor(global.ROWS / 2);
    
    var _gx = global.activePiece.grid_x;
    var _gy = global.activePiece.grid_y;
    var _dx = sign(_cx - _gx);
    var _dy = sign(_cy - _gy);
    
    // Standard Radial Pathfinding
    if (abs(_cx - _gx) >= abs(_cy - _gy)) _dy = 0; else _dx = 0;
    
    if (move_piece(_dx, _dy)) {
        return true;
    } else {
        lock_piece();
        return false;
    }
}

function hard_drop_radial() {
    if (global.activePiece == undefined || global.locking) return;
    
    var _cx = floor(global.COLS / 2);
    var _cy = global.HIDDEN_ROWS + floor(global.ROWS / 2);
    var _isHeavy = (global.launchCharge >= global.MAX_CHARGE);
    
    // GUIDED LAUNCH: Travel to the target depth
    var _targetDepth = global.previewDepth;
    for (var i = 0; i < _targetDepth; i++) {
        var _gx = global.activePiece.grid_x;
        var _gy = global.activePiece.grid_y;
        var _dx = sign(_cx - _gx);
        var _dy = sign(_cy - _gy);
        
        // Standard Radial Pathfinding
        if (abs(_cx - _gx) >= abs(_cy - _gy)) _dy = 0; else _dx = 0;
        
        if (_dx == 0 && _dy == 0) break;
        
        if (!move_piece(_dx, _dy)) {
            // --- HEAVY IMPACT: Try to displace the block we hit ---
            if (_isHeavy) {
                var _tx = _gx + _dx;
                var _ty = _gy + _dy;
                var _hitBlock = global.grid[_ty][_tx];
                
                if (_hitBlock != undefined && _hitBlock.type != "core") {
                    // Check if there is space BEHIND the hit block
                    var _hx = _tx + _dx;
                    var _hy = _ty + _dy;
                    if (_hx >= 0 && _hx < global.COLS && _hy >= 0 && _hy < global.TOTAL_ROWS) {
                        if (global.grid[_hy][_hx] == undefined) {
                            // DISPLACE!
                            global.grid[_hy][_hx] = _hitBlock;
                            global.grid[_ty][_tx] = undefined;
                            _hitBlock.inst.grid_x = _hx;
                            _hitBlock.inst.grid_y = _hy;
                            _hitBlock.inst.x = _hx * 16;
                            _hitBlock.inst.y = (_hy - global.HIDDEN_ROWS) * 16;
                            
                            sfx_drill();
                            if (global.settings.shakeEnabled) global.shakeAmount = 10;
                            
                            _isHeavy = false; // Only displace ONCE per shot
                            if (move_piece(_dx, _dy)) continue; 
                        }
                    }
                }
            }
            break;
        }
    }
    lock_piece();
    global.previewDepth = 1; // Reset for next piece
}

function apply_grid_gravity() {
    var _cx = floor(global.COLS / 2);
    var _cy = global.HIDDEN_ROWS + floor(global.ROWS / 2);
    
    if (global.gameMode == "PLANET" || global.gameMode == "STORY") {
        var _changed = true;
        while (_changed) {
            _changed = false;
            for (var _y = 0; _y < global.TOTAL_ROWS; _y++) {
                for (var _x = 0; _x < global.COLS; _x++) {
                    var _cell = global.grid[_y][_x];
                    if (_cell == undefined || _cell.type == "core") continue;
                    
                    var _dx = sign(_cx - _x);
                    var _dy = sign(_cy - _y);
                    if (_dx == 0 && _dy == 0) continue;
                    
                    // True Radial Pathfinding (Axis Priority)
                    if (abs(_cx - _x) >= abs(_cy - _y)) _dy = 0; else _dx = 0;
                    
                    var _nx = _x + _dx;
                    var _ny = _y + _dy;
                    
                    if (_nx >= 0 && _nx < global.COLS && _ny >= 0 && _ny < global.TOTAL_ROWS) {
                        if (global.grid[_ny][_nx] == undefined) {
                            // MOVE TOWARD CORE
                            global.grid[_ny][_nx] = _cell;
                            global.grid[_y][_x] = undefined;
                            _cell.inst.grid_x = _nx;
                            _cell.inst.grid_y = _ny;
                            
                            // Let the Step lerp handle the slide animation
                            
                            _changed = true;
                        }
                    }
                }
            }
        }
    } else {
        // CLASSIC GRAVITY: Fall Down
        for (var _x = 0; _x < global.COLS; _x++) {
            for (var _y = global.TOTAL_ROWS - 1; _y >= 0; _y--) {
                if (global.grid[_y][_x] == undefined) {
                    for (var _yy = _y - 1; _yy >= 0; _yy--) {
                        var _cellToMove = global.grid[_yy][_x];
                        if (_cellToMove != undefined && _cellToMove.type != "core") {
                            global.grid[_y][_x] = _cellToMove;
                            global.grid[_yy][_x] = undefined;
                            _cellToMove.inst.grid_y = _y;
                            _cellToMove.inst.y = (_y - global.HIDDEN_ROWS) * 16;
                            break;
                        }
                    }
                }
            }
        }
    }
}
function calculate_landing_depth(_gx, _gy) {
    var _cx = floor(global.COLS / 2);
    var _cy = global.HIDDEN_ROWS + floor(global.ROWS / 2);
    var _depth = 0;
    
    var _tx = _gx;
    var _ty = _gy;
    
    // Simple simulation of hard_drop_radial logic
    while (_depth < global.TOTAL_ROWS) {
        var _dx = sign(_cx - _tx);
        var _dy = sign(_cy - _ty);
        if (_dx == 0 && _dy == 0) break;
        if (abs(_cx - _tx) >= abs(_cy - _ty)) _dy = 0; else _dx = 0;
        
        var _nx = _tx + _dx;
        var _ny = _ty + _dy;
        
        if (_nx < 0 || _nx >= global.COLS || _ny < 0 || _ny >= global.TOTAL_ROWS) break;
        if (global.grid[_ny][_nx] != undefined) break; // Collision!
        
        _tx = _nx;
        _ty = _ny;
        _depth++;
    }
    
    return max(1, _depth);
}
function migrate_core(_oldX, _oldY) {
    global.coresCleared++;
    var _candidates = [];
    var _dirs = [[-1,0], [1,0], [0,-1], [0,1]];
    for (var i = 0; i < 4; i++) {
        var _nx = _oldX + _dirs[i][0];
        var _ny = _oldY + _dirs[i][1];
        if (_nx >= 0 && _nx < global.COLS && _ny >= 0 && _ny < global.TOTAL_ROWS) {
            var _cell = global.grid[_ny][_nx];
            // Candidate must be a real block and NOT already being cleared or another special type
            if (_cell != undefined && _cell.type != "core" && _cell.type != "bomb" && _cell.type != "drill") {
                if (!_cell.inst.clearing) {
                    array_push(_candidates, {x: _nx, y: _ny});
                }
            }
        }
    }
    
    var _bx_m = (global.GAME_W - (global.COLS * 16 * global.PIXEL_SCALE)) / 2;
    var _by_m = (global.GAME_H - (global.ROWS * 16 * global.PIXEL_SCALE)) / 2;
    if (array_length(_candidates) > 0) {
        var _pick = _candidates[irandom(array_length(_candidates) - 1)];
        global.grid[_pick.y][_pick.x].type = "core";
        with(global.grid[_pick.y][_pick.x].inst) update_sprite();
        var _ftx = _bx_m + (_pick.x * 16 * global.PIXEL_SCALE) + (8 * global.PIXEL_SCALE);
        var _fty = _by_m + ((_pick.y - global.HIDDEN_ROWS) * 16 * global.PIXEL_SCALE);
        create_floating_text_ext(_ftx, _fty, "CORE MIGRATED!", c_white, 1.2);
    } else {
        var _ftx = _bx_m + (_oldX * 16 * global.PIXEL_SCALE) + (8 * global.PIXEL_SCALE);
        var _fty = _by_m + ((_oldY - global.HIDDEN_ROWS) * 16 * global.PIXEL_SCALE);
        create_floating_text_ext(_ftx, _fty, "CORE CLEARED!", c_yellow, 1.5);
    }
}
