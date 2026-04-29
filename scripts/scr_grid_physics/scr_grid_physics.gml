// =============================================================================
// scr_grid_physics  —  collision, locking, dropping, rotation
//
// Coordinate contract:
//   PLANET: 11x11 grid. Playable = cols 1-9, rows 1-9. Staging = outer ring.
//           Center = (GRID_CX=5, GRID_CY=5). Game over if locked in staging ring.
//   CLASSIC: 10x21 grid. Playable = rows 1-20, hidden top = row 0.
//            Game over if locked in row 0.
//
// Block world pixel:  inst.x = (grid_x - HIDDEN_SIDES)*16
//                     inst.y = (grid_y - HIDDEN_ROWS)*16
// =============================================================================

// ─────────────────────────────────────────────────────────────────────────────
// check_collision  — would moving by (dx,dy) hit a wall or another block?
// ─────────────────────────────────────────────────────────────────────────────
function check_collision(_dx, _dy) {
    var _nx = global.activePiece.grid_x + _dx;
    var _ny = global.activePiece.grid_y + _dy;
    if (_nx < 0 || _nx >= global.TOTAL_COLS) return true;
    if (_ny < 0 || _ny >= global.TOTAL_ROWS) return true;
    if (global.grid[_ny][_nx] != undefined) return true;
    return false;
}

// ─────────────────────────────────────────────────────────────────────────────
// move_piece  — move active piece by (dx,dy) if no collision. Returns success.
// ─────────────────────────────────────────────────────────────────────────────
function move_piece(_dx, _dy) {
    if (global.activePiece == undefined || global.locking) return false;
    if (check_collision(_dx, _dy)) return false;
    global.activePiece.grid_x += _dx;
    global.activePiece.grid_y += _dy;
    if (_dx != 0) { global.activePiece.scale_x = 0.8; global.activePiece.scale_y = 1.2; }
    return true;
}

// ─────────────────────────────────────────────────────────────────────────────
// rotate_piece  — flip arrow/metal direction; juice pulse
// ─────────────────────────────────────────────────────────────────────────────
function rotate_piece() {
    if (global.activePiece == undefined) return;
    global.activePiece.scale_x = 1.25;
    global.activePiece.scale_y = 1.25;
    if (global.activePiece.type == "metal") {
        global.activePiece.dir = (global.activePiece.dir == 0 ? 1 : 0);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// story_advance_planet  — Story Mode: move to next planet or end game
// ─────────────────────────────────────────────────────────────────────────────
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
    with (obj_game_manager) start_game();
}

// ─────────────────────────────────────────────────────────────────────────────
// _grid_screen_pos  — helper: grid cell → screen pixel (centre of cell)
// Uses the playable-board origin (_bx/_by) then offsets by staging.
// ─────────────────────────────────────────────────────────────────────────────
function _grid_screen_pos(_gx, _gy) {
    var _bx = (global.GAME_W - global.COLS * 16 * global.PIXEL_SCALE) / 2;
    var _by = (global.GAME_H - global.ROWS * 16 * global.PIXEL_SCALE) / 2;
    var _sx = _bx + (_gx - global.HIDDEN_SIDES) * 16 * global.PIXEL_SCALE + 8 * global.PIXEL_SCALE;
    var _sy = _by + (_gy - global.HIDDEN_ROWS)  * 16 * global.PIXEL_SCALE + 8 * global.PIXEL_SCALE;
    return { x: _sx, y: _sy };
}

// ─────────────────────────────────────────────────────────────────────────────
// lock_piece  — commit the active piece to the grid, run specials, chain
// ─────────────────────────────────────────────────────────────────────────────
function lock_piece() {
    global.locking = true;
    var _p  = global.activePiece;
    var _px = _p.grid_x;
    var _py = _p.grid_y;

    // ── PLANET / STORY: game over if still in staging ring ───────────────────
    if (global.gameMode == "PLANET" || global.gameMode == "STORY") {
        var _dist = max(abs(_px - floor(global.TOTAL_COLS / 2)), abs(_py - floor(global.TOTAL_ROWS / 2)));
        if (_dist >= 5) {
            global.gameState = "GAMEOVER";
            sfx_game_over();
            if (global.score > global.highScore) { global.highScore = global.score; save_high_score(); }
            instance_destroy(_p);
            global.activePiece = undefined;
            global.locking = false;
            return;
        }

    // ── CLASSIC: game over if locked in hidden row ───────────────────────────
    } else {
        if (_py < global.HIDDEN_ROWS) {
            global.gameState = "GAMEOVER";
            sfx_game_over();
            if (global.score > global.highScore) { global.highScore = global.score; save_high_score(); }
            instance_destroy(_p);
            global.activePiece = undefined;
            global.locking = false;
            return;
        }
    }

    // ── Commit to grid ───────────────────────────────────────────────────────
    global.grid[_py][_px] = {
        type:  _p.type,
        color: _p.color,
        dir:   _p.dir,
        id:    _p.color_id,
        inst:  _p
    };

    // ── PLANET: first piece to land on center becomes the core ───────────────
    if ((global.gameMode == "PLANET" || global.gameMode == "STORY")
    && _px == floor(global.TOTAL_COLS / 2) && _py == floor(global.TOTAL_ROWS / 2)) {
        var _hasCore = false;
        with (obj_block) if (type == "core") { _hasCore = true; break; }
        if (!_hasCore) {
            _p.type = "core";
            global.grid[_py][_px].type = "core";
            with (_p) update_sprite();
            var _sp = _grid_screen_pos(_px, _py);
            create_floating_text_ext(_sp.x, _sp.y, "CORE ESTABLISHED!", c_white, 1.4);
        }
    }

    // ── DRILL: blast through the planet (Planet) or column (Classic) ─────────
    if (_p.type == "drill") {
        var _sp = _grid_screen_pos(_px, _py);
        // Rotate floating text position with board
        var _ang = degtorad(global.boardRotation);
        var _ccx = global.GAME_W / 2; var _ccy = global.GAME_H / 2;
        var _ftx = _ccx + (_sp.x - _ccx) * cos(_ang) - (_sp.y - _ccy) * sin(_ang);
        var _fty = _ccy + (_sp.x - _ccx) * sin(_ang) + (_sp.y - _ccy) * cos(_ang);
        create_floating_text_ext(_ftx, _fty, "DRILL PAYOUT", c_white, 1.6);
        if (global.settings.shakeEnabled) global.shakeAmount = 12;
        global.hitstop = 4;
        sfx_drill();
        // Remove from grid (drill destroys itself by boring)
        global.grid[_py][_px] = undefined;

        var _drilled = 0;

        if (global.gameMode == "PLANET" || global.gameMode == "STORY") {
            // Straight line toward center
            var _gx = _px; var _gy = _py;
            var _vx = (_px <= floor(global.TOTAL_COLS / 2)) ? 1 : -1;
            var _vy = (_py <= floor(global.TOTAL_ROWS / 2)) ? 1 : -1;
            if (abs(_px - floor(global.TOTAL_COLS / 2)) >= abs(_py - floor(global.TOTAL_ROWS / 2))) _vy = 0; else _vx = 0;
            if (_vx == 0 && _vy == 0) _vy = 1;

            while (true) {
                var _cell = global.grid[_gy][_gx];
                if (_cell != undefined) {
                    if (_cell.type == "core") migrate_core(_gx, _gy);
                    create_particles((_gx - global.HIDDEN_SIDES) * 16 * global.PIXEL_SCALE,
                                     (_gy - global.HIDDEN_ROWS)  * 16 * global.PIXEL_SCALE, c_white);
                    _cell.inst.clearing = true;
                    global.grid[_gy][_gx] = undefined;
                    _drilled++;
                }
                create_beam((_gx - global.HIDDEN_SIDES) * 16, (_gy - global.HIDDEN_ROWS) * 16, 16, 16, c_white);
                if (_gx == floor(global.TOTAL_COLS / 2) && _gy == floor(global.TOTAL_ROWS / 2)) break;
                _gx += _vx; _gy += _vy;
                if (_gx < 0 || _gx >= global.TOTAL_COLS || _gy < 0 || _gy >= global.TOTAL_ROWS) break;
            }
        } else {
            // Classic: clear full column
            for (var i = 0; i < global.TOTAL_ROWS; i++) {
                var _cell = global.grid[i][_px];
                if (_cell != undefined && _cell.type != "core") {
                    create_particles(_px * 16, (i - global.HIDDEN_ROWS) * 16, c_white);
                    _cell.inst.clearing = true;
                    global.grid[i][_px] = undefined;
                    _drilled++;
                }
            }
            create_beam(_px * 16, 0, 16, (global.TOTAL_ROWS - global.HIDDEN_ROWS) * 16, c_white);
        }

        if (_drilled > 0) {
            var _pts = _drilled * 150 * ((global.feverTimer > 0) ? 2 : 1);
            global.score += _pts; global.levelScore += _pts;
            if (global.gameMode == "STORY") global.storyCleared += _drilled;
            global.ui_scales.score = 1.3;
            award_shards(_pts, _drilled);
            charge_jackpot(_drilled + 2);
            update_level_progress();
        }
        instance_destroy(_p);
        global.activePiece = undefined;
        apply_grid_gravity();
        alarm[0] = 10;
        return;
    }

    // ── BOMB: 5x5 diamond blast ──────────────────────────────────────────────
    if (_p.type == "bomb") {
        var _sp = _grid_screen_pos(_px, _py);
        create_impact(0, (_py - global.HIDDEN_ROWS + 1) * 16, global.COLS * 16, c_orange);
        create_floating_text_ext(_sp.x, _sp.y, "ULTRA BLAST!", c_orange, 1.5);
        if (global.settings.shakeEnabled) global.shakeAmount = 15;
        global.hitstop = 8;
        sfx_bomb();

        var _blasted = 0;
        for (var _dy = -2; _dy <= 2; _dy++) {
            for (var _dx2 = -2; _dx2 <= 2; _dx2++) {
                if (abs(_dx2) + abs(_dy) > 3) continue;
                var _bx2 = _px + _dx2; var _by2 = _py + _dy;
                if (_bx2 < 0 || _bx2 >= global.TOTAL_COLS || _by2 < 0 || _by2 >= global.TOTAL_ROWS) continue;
                var _cell = global.grid[_by2][_bx2];
                if (_cell != undefined && _cell.type != "core") {
                    create_particles((_bx2 - global.HIDDEN_SIDES)*16*global.PIXEL_SCALE,
                                     (_by2 - global.HIDDEN_ROWS)*16*global.PIXEL_SCALE, _cell.color);
                    _cell.inst.clearing = true;
                    global.grid[_by2][_bx2] = undefined;
                    _blasted++;
                }
            }
        }
        global.grid[_py][_px] = undefined;
        if (_blasted > 0) {
            var _pts = _blasted * 100 * ((global.feverTimer > 0) ? 2 : 1);
            global.score += _pts; global.levelScore += _pts;
            if (global.gameMode == "STORY") global.storyCleared += _blasted;
            global.ui_scales.score = 1.3;
            award_shards(_pts, _blasted);
            charge_jackpot(_blasted + 3);
            update_level_progress();
        }
        instance_destroy(_p);
        global.activePiece = undefined;
        apply_grid_gravity();
        alarm[0] = 10;
        return;
    }

    // ── MAGNET: pull matching neighbours toward center ───────────────────────
    if (_p.type == "magnet") {
        var _dirs = [[-1,0],[1,0],[0,-1],[0,1]];
        for (var i = 0; i < 4; i++) {
            var _mx = _px + _dirs[i][0]; var _my = _py + _dirs[i][1];
            if (_mx < 0 || _mx >= global.TOTAL_COLS || _my < 0 || _my >= global.TOTAL_ROWS) continue;
            var _cell = global.grid[_my][_mx];
            if (_cell == undefined || _cell.type == "core") continue;
            if (_cell.id == global.grid[_py][_px].id) {
                var _tdx = _dirs[i][0]; var _tdy = _dirs[i][1];
                var _tx = _mx + _tdx; var _ty = _my + _tdy;
                if (_tx >= 0 && _tx < global.TOTAL_COLS && _ty >= 0 && _ty < global.TOTAL_ROWS
                && global.grid[_ty][_tx] == undefined) {
                    global.grid[_ty][_tx] = _cell;
                    global.grid[_my][_mx] = undefined;
                    _cell.inst.grid_x = _tx; _cell.inst.grid_y = _ty;
                    _cell.inst.x = (_tx - global.HIDDEN_SIDES) * 16;
                    _cell.inst.y = (_ty - global.HIDDEN_ROWS) * 16;
                }
            }
        }
        sfx_drill();
    }

    // ── End of lock: gravity + match check ───────────────────────────────────
    global.activePiece = undefined;
    if (global.settings.shakeEnabled) global.shakeAmount = 2;
    apply_grid_gravity();
    settle_matches();
}

// ─────────────────────────────────────────────────────────────────────────────
// hard_drop  — CLASSIC only: fall straight down then lock
// ─────────────────────────────────────────────────────────────────────────────
function hard_drop() {
    var _startY = global.activePiece.grid_y;
    while (!check_collision(0, 1)) global.activePiece.grid_y++;
    var _endY = global.activePiece.grid_y;
    if (_endY > _startY) {
        create_beam(global.activePiece.grid_x * 16, (_startY - global.HIDDEN_ROWS) * 16,
                    16, (_endY - _startY) * 16, global.activePiece.color);
        for (var _ty = _startY; _ty < _endY; _ty++) {
            if (_ty >= global.HIDDEN_ROWS)
                create_trail_particles(global.activePiece.grid_x * 16 + 8, (_ty - global.HIDDEN_ROWS) * 16 + 8, global.activePiece.color);
        }
    }
    sfx_hard_drop();
    lock_piece();
}

// ─────────────────────────────────────────────────────────────────────────────
// hard_drop_radial  — PLANET/STORY only: fire piece inward and lock
// ─────────────────────────────────────────────────────────────────────────────
function hard_drop_radial() {
    if (global.activePiece == undefined) return;
    var _depth  = calculate_landing_depth(global.activePiece.grid_x, global.activePiece.grid_y);
    var _isHeavy = (global.launchCharge >= global.MAX_CHARGE);

    for (var i = 0; i < _depth; i++) {
        var _gx = global.activePiece.grid_x;
        var _gy = global.activePiece.grid_y;
        var _dx = sign(floor(global.TOTAL_COLS / 2) - _gx);
        var _dy = sign(floor(global.TOTAL_ROWS / 2) - _gy);
        if (abs(floor(global.TOTAL_COLS / 2) - _gx) >= abs(floor(global.TOTAL_ROWS / 2) - _gy)) _dy = 0; else _dx = 0;
        if (_dx == 0 && _dy == 0) break;

        if (!move_piece(_dx, _dy)) {
            // Heavy: try to displace one block
            if (_isHeavy) {
                var _tx = _gx + _dx; var _ty = _gy + _dy;
                if (_tx >= 0 && _tx < global.TOTAL_COLS && _ty >= 0 && _ty < global.TOTAL_ROWS) {
                    var _hit = global.grid[_ty][_tx];
                    var _hx = _tx + _dx; var _hy = _ty + _dy;
                    if (_hit != undefined && _hit.type != "core"
                    && _hx >= 0 && _hx < global.TOTAL_COLS && _hy >= 0 && _hy < global.TOTAL_ROWS
                    && global.grid[_hy][_hx] == undefined) {
                        global.grid[_hy][_hx] = _hit; global.grid[_ty][_tx] = undefined;
                        _hit.inst.grid_x = _hx; _hit.inst.grid_y = _hy;
                        _hit.inst.x = (_hx - global.HIDDEN_SIDES) * 16;
                        _hit.inst.y = (_hy - global.HIDDEN_ROWS) * 16;
                        sfx_drill();
                        if (global.settings.shakeEnabled) global.shakeAmount = 10;
                        _isHeavy = false;
                        if (move_piece(_dx, _dy)) continue;
                    }
                }
            }
            break;
        }
    }
    lock_piece();
    global.previewDepth = 1;
    global.launchCharge = 0;
}

// =============================================================================
// GRAVITY
// =============================================================================

function apply_grid_gravity() {
    if (global.gameMode == "PLANET" || global.gameMode == "STORY") {
        // Radial: pull all non-core blocks one step toward (GRID_CX, GRID_CY)
        var _changed = true;
        while (_changed) {
            _changed = false;
            for (var _y = 0; _y < global.TOTAL_ROWS; _y++) {
                for (var _x = 0; _x < global.TOTAL_COLS; _x++) {
                    var _cell = global.grid[_y][_x];
                    if (_cell == undefined || _cell.type == "core") continue;
                    var _dx = sign(floor(global.TOTAL_COLS / 2) - _x);
                    var _dy = sign(floor(global.TOTAL_ROWS / 2) - _y);
                    if (_dx == 0 && _dy == 0) continue;
                    // Dominant axis first
                    if (abs(floor(global.TOTAL_COLS / 2) - _x) >= abs(floor(global.TOTAL_ROWS / 2) - _y)) _dy = 0; else _dx = 0;
                    var _nx = _x + _dx; var _ny = _y + _dy;
                    if (_nx >= 0 && _nx < global.TOTAL_COLS && _ny >= 0 && _ny < global.TOTAL_ROWS
                    && global.grid[_ny][_nx] == undefined) {
                        global.grid[_ny][_nx] = _cell;
                        global.grid[_y][_x]   = undefined;
                        _cell.inst.grid_x = _nx; _cell.inst.grid_y = _ny;
                        _changed = true;
                    }
                }
            }
        }
    } else {
        // Classic: fall straight down
        for (var _x = 0; _x < global.COLS; _x++) {
            for (var _y = global.TOTAL_ROWS - 1; _y >= 0; _y--) {
                if (global.grid[_y][_x] != undefined) continue;
                for (var _yy = _y - 1; _yy >= 0; _yy--) {
                    var _c = global.grid[_yy][_x];
                    if (_c != undefined && _c.type != "core") {
                        global.grid[_y][_x]  = _c;
                        global.grid[_yy][_x] = undefined;
                        _c.inst.grid_y = _y;
                        _c.inst.y = (_y - global.HIDDEN_ROWS) * 16;
                        break;
                    }
                }
            }
        }
    }
}

// -----------------------------------------------------------------------------
// calculate_landing_depth  � how many steps inward before collision?
// -----------------------------------------------------------------------------
function calculate_landing_depth(_gx, _gy) {
    if (global.gameMode == "PLANET" || global.gameMode == "STORY") {
        var _tx = _gx; var _ty = _gy; var _depth = 0;
        while (_depth < global.TOTAL_ROWS) {
            var _dx = sign(floor(global.TOTAL_COLS / 2) - _tx);
            var _dy = sign(floor(global.TOTAL_ROWS / 2) - _ty);
            if (_dx == 0 && _dy == 0) break;
            if (abs(floor(global.TOTAL_COLS / 2) - _tx) >= abs(floor(global.TOTAL_ROWS / 2) - _ty)) _dy = 0; else _dx = 0;
            var _nx = _tx + _dx; var _ny = _ty + _dy;
            if (_nx < 0 || _nx >= global.TOTAL_COLS || _ny < 0 || _ny >= global.TOTAL_ROWS) break;
            if (global.grid[_ny][_nx] != undefined) break;
            _tx = _nx; _ty = _ny; _depth++;
        }
        return _depth;
    } else {
        // Classic: count empty cells below
        var _depth = 0;
        var _ty = _gy;
        while (_ty < global.TOTAL_ROWS - 1) {
            if (global.grid[_ty + 1][_gx] != undefined) break;
            _ty++; _depth++;
        }
        return _depth;
    }
}

// -----------------------------------------------------------------------------
// rotate_grid_90  � CLASSIC ONLY, called on level-up rotation
// -----------------------------------------------------------------------------
function rotate_grid_90() {
    var _newGrid = array_create(global.TOTAL_ROWS);
    for (var i = 0; i < global.TOTAL_ROWS; i++) _newGrid[i] = array_create(global.COLS, undefined);
    var _coreCell = undefined;
    for (var _y = 0; _y < global.TOTAL_ROWS; _y++) {
        for (var _x = 0; _x < global.COLS; _x++) {
            var _cell = global.grid[_y][_x];
            if (_cell == undefined) continue;
            if (_cell.type == "core") { _coreCell = _cell; continue; }
            var _nx = (global.TOTAL_ROWS - 1) - _y;
            var _ny = _x;
            if (_nx < global.COLS && _ny < global.TOTAL_ROWS) {
                _newGrid[_ny][_nx] = _cell;
                _cell.inst.grid_x = _nx; _cell.inst.grid_y = _ny;
                _cell.inst.x = _nx * 16;
                _cell.inst.y = (_ny - global.HIDDEN_ROWS) * 16;
            }
        }
    }
    if (_coreCell != undefined) {
        var _midX = floor(global.COLS / 2);
        var _midY = global.HIDDEN_ROWS + floor(global.ROWS / 2);
        _newGrid[_midY][_midX] = _coreCell;
        _coreCell.inst.grid_x = _midX; _coreCell.inst.grid_y = _midY;
    }
    global.grid = _newGrid;
}

// =============================================================================
// MATCH ENGINE INTEGRATION
// =============================================================================

function settle_matches() {
    var _matches = find_matches_in_grid(global.grid, { cols: global.TOTAL_COLS }, global.TOTAL_ROWS);
    if (array_length(_matches) > 0) {
        global.comboChain++;
        var _pts = array_length(_matches) * 100 * global.comboChain * ((global.feverTimer > 0) ? 2 : 1);
        global.score += _pts; global.levelScore += _pts;
        if (global.gameMode == "STORY") global.storyCleared += array_length(_matches);
        global.ui_scales.score = 1.25; global.ui_scales.combo = 1.4;
        update_level_progress();
        var _bx_c = (global.GAME_W - global.COLS * 16 * global.PIXEL_SCALE) / 2;
        var _by_c = (global.GAME_H - global.ROWS * 16 * global.PIXEL_SCALE) / 2;
        if (array_length(_matches) >= 6) {
            create_floating_text_ext(global.GAME_W * 0.5, global.GAME_H * 0.4, "MEGA CLEAR!!", c_white, 2.0);
            if (global.settings.shakeEnabled) global.shakeAmount = 15;
            global.ui_scales.score = 1.5;
        } else if (global.comboChain > 1) {
            create_floating_text_ext(global.GAME_W * 0.5, global.GAME_H * 0.45, "COMBO x" + string(global.comboChain), global.COLOR_GLOW, 1.5);
        }
        award_shards(_pts, array_length(_matches));
        charge_jackpot(array_length(_matches));
        var _coreMigrated = false;
        for (var i = 0; i < array_length(_matches); i++) {
            var _m = _matches[i];
            var _cell = global.grid[_m.y][_m.x];
            if (_cell == undefined) continue;
            if (_cell.type == "core" && !_coreMigrated) {
                migrate_core(_m.x, _m.y);
                _coreMigrated = true;
            }
            if (_cell.type == "asteroid" && _cell.inst.shield_hp > 1) {
                _cell.inst.shield_hp--;
                _cell.inst.scale_x = 1.3; _cell.inst.scale_y = 1.3;
                with (_cell.inst) update_sprite();
                create_particles((_m.x - global.HIDDEN_SIDES) * 16 * global.PIXEL_SCALE,
                                 (_m.y - global.HIDDEN_ROWS)  * 16 * global.PIXEL_SCALE, make_color_rgb(100,100,100));
                continue;
            }
            var _sp = _grid_screen_pos(_m.x, _m.y);
            create_floating_text_ext(_sp.x, _sp.y, "+100", _cell.color, 0.8);
            create_particles((_m.x - global.HIDDEN_SIDES) * 16 * global.PIXEL_SCALE,
                             (_m.y - global.HIDDEN_ROWS)  * 16 * global.PIXEL_SCALE, _cell.color);
            _cell.inst.clearing = true;
            global.grid[_m.y][_m.x] = undefined;
        }
        apply_grid_gravity();
        alarm[0] = 15;
    } else {
        global.locking = false;
        global.comboChain = 0;
        var _bestCluster = debug_largest_cluster_size();
        if (_bestCluster > 0 && _bestCluster < 4) {
            create_floating_text_ext(global.GAME_W * 0.5, global.GAME_H * 0.55,
                "NEED " + string(4 - _bestCluster) + " MORE", make_color_rgb(200,200,200), 0.9);
        }
        if (global.gameMode == "STORY" && global.coresCleared >= global.storyTarget) {
            story_advance_planet();
            return;
        }
        if (check_game_over()) {
            global.gameState = "GAMEOVER";
            if (global.score > global.highScore) { global.highScore = global.score; save_high_score(); }
            sfx_game_over();
        } else {
            spawn_piece();
        }
    }
}

function check_game_over() {
    // Classic only: block in hidden top row = game over
    if (global.gameMode == "CLASSIC") {
        for (var _x = 0; _x < global.COLS; _x++) {
            if (global.grid[0][_x] != undefined) return true;
        }
    }
    return false;
}

function migrate_core(_oldX, _oldY) {
    global.coresCleared++;
    var _candidates = [];
    var _dirs = [[-1,0],[1,0],[0,-1],[0,1]];
    for (var i = 0; i < 4; i++) {
        var _nx = _oldX + _dirs[i][0]; var _ny = _oldY + _dirs[i][1];
        if (_nx < 0 || _nx >= global.TOTAL_COLS || _ny < 0 || _ny >= global.TOTAL_ROWS) continue;
        var _cell = global.grid[_ny][_nx];
        if (_cell != undefined && _cell.type != "core" && _cell.type != "bomb"
        && _cell.type != "drill" && !_cell.inst.clearing) {
            array_push(_candidates, {x: _nx, y: _ny});
        }
    }
    if (array_length(_candidates) > 0) {
        var _pick = _candidates[irandom(array_length(_candidates) - 1)];
        var _newCore = global.grid[_pick.y][_pick.x];
        _newCore.type = "core";
        _newCore.inst.type = "core";
        with (_newCore.inst) update_sprite();
        var _sp = _grid_screen_pos(_pick.x, _pick.y);
        create_floating_text_ext(_sp.x, _sp.y, "CORE MIGRATED!", c_white, 1.2);
    } else {
        var _sp = _grid_screen_pos(_oldX, _oldY);
        create_floating_text_ext(_sp.x, _sp.y, "CORE CLEARED!", c_yellow, 1.5);
    }
}
