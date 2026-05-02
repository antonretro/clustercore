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
    global.activePiece.x = (global.activePiece.grid_x - global.HIDDEN_SIDES) * 16;
    global.activePiece.y = (global.activePiece.grid_y - global.HIDDEN_ROWS)  * 16;
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
// hard_drop  — Classic Mode: drop straight down to landing
// ─────────────────────────────────────────────────────────────────────────────
function hard_drop() {
    if (global.activePiece == undefined || global.locking) return;
    var _depth = calculate_landing_depth(global.activePiece.grid_x, global.activePiece.grid_y);
    global.activePiece.grid_y += _depth;
    global.activePiece.y = (global.activePiece.grid_y - global.HIDDEN_ROWS) * 16;
    lock_piece();
}

// ─────────────────────────────────────────────────────────────────────────────
// hard_drop_radial  — Planet Mode: drop inward along the straight orbital axis
// ─────────────────────────────────────────────────────────────────────────────
function hard_drop_radial() {
    if (global.activePiece == undefined || global.locking) return;
    var _pData = calculate_planet_preview_path(global.activePiece);
    if (_pData == undefined) return;
    
    global.shipRecoil = 12; // Visual juice for the Refabricator ship
    
    global.activePiece.grid_x = _pData.target.gx;
    global.activePiece.grid_y = _pData.target.gy;
    global.activePiece.x = (global.activePiece.grid_x - global.HIDDEN_SIDES) * 16;
    global.activePiece.y = (global.activePiece.grid_y - global.HIDDEN_ROWS) * 16;
    lock_piece();
}

// ─────────────────────────────────────────────────────────────────────────────
// story_advance_planet  — Story Mode: move to next planet or end game
// ─────────────────────────────────────────────────────────────────────────────
function story_advance_planet() {
    // Snap the board back to perfect zero so the background isn't upside down during MISSION COMPLETE
    global.boardRotation = 0;
    global.targetRotation = 0;
    
    var _prevPlanet = global.storyPlanet;
    var _prevLevel = global.storyLevel;
    global.locking = false;
    story_progress_mark_complete(_prevPlanet, _prevLevel);
    wallet_save();

    global.storyLevel++;

    if (global.storyLevel < 6) {
        global.gameState = "LEVEL_COMPLETE";
        return;
    }

    global.storyLevel = 0;
    global.storyPlanet++;

    story_start_between_level_dialogue(_prevPlanet);

    if (_prevPlanet == 0 && global.storyPlanet >= 1) {
        steam_ach_unlock("ACH_STORY_WORLD_1");
    }

    if (global.storyPlanet >= array_length(global.storyPlanets)) {
        global.storyComplete = true;
        global.gameState = "GAMEOVER";
        create_floating_text_ext(global.GAME_W * 0.5, global.GAME_H * 0.34, "STORY CLEAR!", c_yellow, 2.4);
        return;
    }
}

function story_trigger_level_complete() {
    if (global.gameState == "LEVEL_COMPLETE" || global.gameState == "FINISHING_LEVEL") return;
    
    global.gameState = "FINISHING_LEVEL";
    global.finishTimer = 100; // Delay for animations
    
    // Calculate Rank and Bonus
    global.storyBonus = 0;
    global.storyRank = "D";
    
    if (global.turnLimit > 0) {
        var _rem = max(0, global.turnLimit - global.turnCount);
        global.storyBonus = _rem * 500;
        global.score += global.storyBonus;
        
        var _pct = _rem / global.turnLimit;
        if (_pct >= 0.70) global.storyRank = "S";
        else if (_pct >= 0.50) global.storyRank = "A";
        else if (_pct >= 0.30) global.storyRank = "B";
        else if (_pct >= 0.10) global.storyRank = "C";
    } else {
        global.storyRank = "A";
    }

    // TRIGGER DRAMATIC CLEANUP
    global.flashAlpha = 1.0;
    global.restoredTilesAlpha = 0;
    generate_restored_planet_map();
    sfx_fever(); // Big victory sound
    // Destroy all remaining blocks with juice
    with(obj_block) {
        if (type == "core") {
            // Big core explosion
            create_particles(x, y, c_yellow);
            create_particles(x, y, c_white);
            global.shakeAmount = 25;
        } else {
            create_particles(x, y, color);
        }
        instance_destroy();
    }
    
    create_floating_text_ext(global.GAME_W * 0.5, global.GAME_H * 0.34, "PLANET PURIFIED", global.COLOR_GLOW, 2.5);
}

function story_objective_is_met() {
    if (global.gameMode != "STORY") return false;

    var _value = max(1, global.storyObjectiveValue);

    if (global.storyObjectiveType == "score") {
        return global.score >= _value;
    }

    if (global.storyObjectiveType == "survive_waves") {
        return global.storyWavesSurvived >= _value;
    }

    if (global.storyObjectiveType == "collect_shards") {
        return global.storyShardsCollected >= _value;
    }

    if (global.storyObjectiveType == "clear_board") {
        // Precise grid check: ensure no non-core blocks remain in the 11x11 play area
        var _count = 0;
        for (var _y = 0; _y < global.TOTAL_ROWS; _y++) {
            for (var _x = 0; _x < global.TOTAL_COLS; _x++) {
                var _c = global.grid[_y][_x];
                if (_c != undefined && _c.type != "core") {
                    _count++;
                }
            }
        }
        return (_count == 0);
    }

    // Default to comparing storyCleared (blocks or cores depending on resolve_clears) to storyTarget
    return global.storyCleared >= max(1, global.storyTarget);
}


function generate_restored_planet_map() {
    random_set_seed(global.storyLevelSeed + 777);
    
    for (var _y = 0; _y < global.TOTAL_ROWS; _y++) {
        for (var _x = 0; _x < global.TOTAL_COLS; _x++) {
            if (!grid_cell_is_playable(_x, _y)) {
                global.restoredMap[_y][_x] = { type: 0, variant: 0 }; // Space
                continue;
            }
            
            // Random biome distribution
            var _r = random(100);
            var _type = 1; // Default Ocean
            if (_r > 30)  _type = 2; // Forest
            if (_r > 65)  _type = 3; // Mountain
            if (_r > 85)  _type = 4; // Desert
            if (_r > 95)  _type = 5; // Tundra
            
            global.restoredMap[_y][_x] = {
                type: _type,
                variant: irandom(3),
                alpha: 0,
                scale: 0.5 + random(0.5)
            };
        }
    }
    randomize(); // Return to live randomness
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
function sync_special_cell_visual(_gx, _gy) {
    if (!grid_in_bounds(_gx, _gy)) return;
    var _cell = global.grid[_gy][_gx];
    if (_cell == undefined || _cell.inst == undefined) return;

    _cell.inst.type = _cell.type;
    _cell.inst.color = _cell.color;
    _cell.inst.color_id = _cell.id;
    _cell.inst.dir = _cell.dir;
    _cell.inst.shard_value = variable_struct_exists(_cell, "shard_value") ? _cell.shard_value : 0;
    _cell.inst.locked_hp = variable_struct_exists(_cell, "locked_hp") ? _cell.locked_hp : 0;
    _cell.inst.special_value = variable_struct_exists(_cell, "special_value") ? _cell.special_value : 0;
    with (_cell.inst) update_sprite();
}

function crack_locked_cell(_gx, _gy) {
    if (!grid_in_bounds(_gx, _gy)) return false;
    var _cell = global.grid[_gy][_gx];
    if (_cell == undefined || _cell.type != "locked") return false;

    var _hp = variable_struct_exists(_cell, "locked_hp") ? _cell.locked_hp : 2;
    if (_hp <= 1) return false;

    _cell.locked_hp = _hp - 1;
    if (_cell.inst != undefined) {
        _cell.inst.locked_hp = _cell.locked_hp;
        _cell.inst.scale_x = 1.25;
        _cell.inst.scale_y = 1.25;
    }
    var _sp = _grid_screen_pos(_gx, _gy);
    create_floating_text_ext(_sp.x, _sp.y, "CRACK", make_color_rgb(220, 220, 160), 0.75);
    create_particles((_gx - global.HIDDEN_SIDES) * 16, (_gy - global.HIDDEN_ROWS) * 16, make_color_rgb(210, 190, 120));
    sync_special_cell_visual(_gx, _gy);
    return true;
}

function crack_asteroid_cell(_gx, _gy) {
    if (!grid_in_bounds(_gx, _gy)) return false;
    var _cell = global.grid[_gy][_gx];
    if (_cell == undefined || _cell.type != "asteroid") return false;

    var _hp = (variable_struct_exists(_cell, "shield_hp")) ? _cell.shield_hp : 2;
    if (_hp <= 1) {
        // Break completely
        _cell.inst.clearing = true;
        global.grid[_gy][_gx] = undefined;
        var _sp = _grid_screen_pos(_gx, _gy);
        create_floating_text_ext(_sp.x, _sp.y, "SHATTER", make_color_rgb(180, 180, 180), 0.9);
        create_particles((_gx - global.HIDDEN_SIDES) * 16, (_gy - global.HIDDEN_ROWS) * 16, make_color_rgb(100, 100, 100));
        return true;
    }

    _cell.shield_hp = _hp - 1;
    if (_cell.inst != undefined) {
        _cell.inst.shield_hp = _cell.shield_hp;
        _cell.inst.scale_x = 1.3; _cell.inst.scale_y = 1.3;
        with (_cell.inst) update_sprite();
    }
    var _sp = _grid_screen_pos(_gx, _gy);
    create_floating_text_ext(_sp.x, _sp.y, "SHIELD", make_color_rgb(220, 220, 120), 0.7);
    create_particles((_gx - global.HIDDEN_SIDES) * 16, (_gy - global.HIDDEN_ROWS) * 16, make_color_rgb(100, 100, 100));
    return true;
}

function rotate_prism_blocks() {
    if (array_length(global.activeColors) <= 0) return;

    for (var _y = 0; _y < global.TOTAL_ROWS; _y++) {
        for (var _x = 0; _x < global.TOTAL_COLS; _x++) {
            var _cell = global.grid[_y][_x];
            if (_cell == undefined || _cell.type != "prism") continue;

            var _idx = 0;
            for (var _i = 0; _i < array_length(global.activeColors); _i++) {
                if (global.activeColors[_i] == _cell.id) {
                    _idx = _i;
                    break;
                }
            }
            _idx = (_idx + 1) mod array_length(global.activeColors);
            _cell.id = global.activeColors[_idx];
            _cell.color = get_color_from_id(_cell.id);
            sync_special_cell_visual(_x, _y);
        }
    }
}

function pull_cells_toward(_gx, _gy) {
    var _dirs = [[-1,0],[1,0],[0,-1],[0,1],[-1,-1],[1,-1],[-1,1],[1,1]];

    for (var _i = 0; _i < array_length(_dirs); _i++) {
        var _sx = _gx + _dirs[_i][0] * 2;
        var _sy = _gy + _dirs[_i][1] * 2;
        var _tx = _sx - sign(_sx - _gx);
        var _ty = _sy - sign(_sy - _gy);
        if (!grid_in_bounds(_sx, _sy) || !grid_in_bounds(_tx, _ty)) continue;
        if (global.grid[_sy][_sx] == undefined || global.grid[_ty][_tx] != undefined) continue;

        var _cell = global.grid[_sy][_sx];
        if (_cell.type == "core") continue;
        global.grid[_ty][_tx] = _cell;
        global.grid[_sy][_sx] = undefined;
        if (_cell.inst != undefined) {
            _cell.inst.grid_x = _tx;
            _cell.inst.grid_y = _ty;
            _cell.inst.x = (_tx - global.HIDDEN_SIDES) * 16;
            _cell.inst.y = (_ty - global.HIDDEN_ROWS) * 16;
        }
    }
}

function planet_has_outer_danger_block() {
    if (!(global.gameMode == "PLANET" || global.gameMode == "STORY")) return false;

    var _cx = floor(global.TOTAL_COLS / 2);
    var _cy = floor(global.TOTAL_ROWS / 2);
    for (var _y = 0; _y < global.TOTAL_ROWS; _y++) {
        for (var _x = 0; _x < global.TOTAL_COLS; _x++) {
            var _cell = global.grid[_y][_x];
            if (_cell == undefined) continue;
            if (max(abs(_x - _cx), abs(_y - _cy)) >= 5) return true;
        }
    }
    return false;
}

function lock_piece() {
    global.turnCount++;
    global.locking = true;
    steam_ach_unlock("ACH_FIRST_DROP");
    var _p  = global.activePiece;
    var _px = _p.grid_x;
    var _py = _p.grid_y;

    // ── PLANET / STORY: game over if piece locks in the staging ring (dist≥5) ─
    // Ring 4 is the outermost PLAYABLE ring — pieces can fill it safely.
    // Game over only fires when the piece can't enter the board at all (staging ring, dist=5).
    if (global.gameMode == "PLANET" || global.gameMode == "STORY") {
        var _dist = max(abs(_px - floor(global.TOTAL_COLS / 2)), abs(_py - floor(global.TOTAL_ROWS / 2)));
        if (false && _dist >= 5 && _p.type != "drill") {
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
        inst:  _p,
        shard_value: variable_instance_exists(_p, "shard_value") ? _p.shard_value : 0,
        locked_hp: variable_instance_exists(_p, "locked_hp") ? _p.locked_hp : 0,
        special_value: variable_instance_exists(_p, "special_value") ? _p.special_value : 0
    };
    _p.just_landed = true;

    // ── PLANET: first piece to land on center becomes the core ───────────────
    if ((global.gameMode == "PLANET" || global.gameMode == "STORY")
    && _px == floor(global.TOTAL_COLS / 2)
    && _py == floor(global.TOTAL_ROWS / 2)) {

        var _hasCore = false;

        with (obj_block) {
            if (type == "core") {
                _hasCore = true;
                break;
            }
        }

        // Bombs and drills cannot become the core.
        if (!_hasCore && _p.type != "bomb" && _p.type != "drill") {
            var _wasMetalCore = (_p.type == "metal");
            var _coreId = _p.color_id;

            if (_coreId <= 0 || _coreId == undefined) {
                if (array_length(global.activeColors) > 0) _coreId = global.activeColors[0];
                else _coreId = 1;
            }

            var _coreColor = get_color_from_id(_coreId);

            _p.type = "core";
            _p.core_arrow = _wasMetalCore;
            _p.color_id = _coreId;
            _p.color = _coreColor;

            global.grid[_py][_px].type = "core";
            global.grid[_py][_px].core_arrow = _wasMetalCore;
            global.grid[_py][_px].id = _coreId;
            global.grid[_py][_px].color = _coreColor;

            with (_p) update_sprite();

            var _sp = _grid_screen_pos(_px, _py);
            create_floating_text_ext(_sp.x, _sp.y, "CORE ESTABLISHED!", c_white, 1.4);
        }
    }

    // ── DRILL: blast through the planet (Planet) or column (Classic) ─────────
    if (_p.type == "drill") {
        // Compute screen position for floating text (board-rotation-aware)
        var _sp  = _grid_screen_pos(_px, _py);
        var _ang = degtorad(global.boardRotation);
        var _ccx = global.GAME_W / 2; var _ccy = global.GAME_H / 2;
        var _ftx = _ccx + (_sp.x - _ccx) * cos(_ang) - (_sp.y - _ccy) * sin(_ang);
        var _fty = _ccy + (_sp.x - _ccx) * sin(_ang) + (_sp.y - _ccy) * cos(_ang);

        if (global.settings.shakeEnabled) global.shakeAmount = 12;
        global.hitstop = 4;
        sfx_drill();
        global.grid[_py][_px] = undefined; // consume the drill itself

        var _drilled = 0;
        var _drillCol = make_color_rgb(200, 220, 255); // icy-silver drill colour

        if (global.gameMode == "PLANET" || global.gameMode == "STORY") {
            // Drill should always travel DOWN on screen.
            // Convert screen-down into board-space cardinal direction
            // using the snapped visual rotation.
            var _rot90 = round(global.targetRotation / 90) mod 4;
            if (_rot90 < 0) _rot90 += 4;
            var _vx = 0;
            var _vy = 1;
            switch (_rot90) {
                case 0: _vx = 0;  _vy = 1;  break; // board normal -> grid down
                case 1: _vx = -1; _vy = 0;  break; // board turned right -> grid left
                case 2: _vx = 0;  _vy = -1; break; // upside down -> grid up
                case 3: _vx = 1;  _vy = 0;  break; // board turned left -> grid right
            }
            var _gx = _px; var _gy = _py;
            while (true) {
                var _cell = global.grid[_gy][_gx];
                if (_cell != undefined) {
                    if (_cell.type == "core") migrate_core(_gx, _gy);
                    // Correct particle coords: block-space pixels (Draw_0 applies PIXEL_SCALE)
                    create_particles((_gx - global.HIDDEN_SIDES) * 16,
                                     (_gy - global.HIDDEN_ROWS)  * 16, _drillCol);
                    _cell.inst.clearing = true;
                    global.grid[_gy][_gx] = undefined;
                    _drilled++;
                }
                create_beam((_gx - global.HIDDEN_SIDES) * 16, (_gy - global.HIDDEN_ROWS) * 16, 16, 16, _drillCol);
                _gx += _vx; _gy += _vy;
                if (_gx < 0 || _gx >= global.TOTAL_COLS || _gy < 0 || _gy >= global.TOTAL_ROWS) break;
            }
        } else {
            // Classic: drill downward from impact point.
            for (var i = _py; i < global.TOTAL_ROWS; i++) {
                var _cell = global.grid[i][_px];
                if (_cell != undefined && _cell.type != "core") {
                    create_particles((_px - global.HIDDEN_SIDES) * 16, (i - global.HIDDEN_ROWS) * 16, _drillCol);
                    _cell.inst.clearing = true;
                    global.grid[i][_px] = undefined;
                    _drilled++;
                }
            }
            create_beam((_px - global.HIDDEN_SIDES) * 16, (_py - global.HIDDEN_ROWS) * 16, 16,
                        (global.TOTAL_ROWS - _py) * 16, _drillCol);
        }

        if (_drilled > 0) {
            global.hitstop = min(4 + _drilled, 12); // scale freeze with destruction
            create_floating_text_ext(_ftx, _fty, "DRILLED " + string(_drilled) + "!", _drillCol, 1.6);
            var _pts = _drilled * 150 * ((global.feverTimer > 0) ? 2 : 1);
            global.score += _pts; global.levelScore += _pts;
            if (global.score >= 100000) steam_ach_unlock("ACH_SCORE_100K");
            if (global.gameMode == "STORY") global.storyCleared += _drilled;
            global.ui_scales.score = 1.3;
            award_shards(_pts, _drilled);
            charge_jackpot(_drilled + 2);
            update_level_progress();
        } else {
            create_floating_text_ext(_ftx, _fty, "DRILL MISS", make_color_rgb(150, 150, 170), 1.2);
        }
        instance_destroy(_p);
        global.activePiece = undefined;
        if (_drilled > 0) apply_grid_gravity();
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
        for (var _dx = -1; _dx <= 1; _dx++) {
            for (var _dy = -1; _dy <= 1; _dy++) {
                var _bx2 = _px + _dx; var _by2 = _py + _dy;
                if (_bx2 < 0 || _bx2 >= global.TOTAL_COLS || _by2 < 0 || _by2 >= global.TOTAL_ROWS) continue;
                var _cell = global.grid[_by2][_bx2];
                if (_cell != undefined) {
                    if (_cell.type == "core") migrate_core(_bx2, _by2);
                    create_particles((_bx2 - global.HIDDEN_SIDES) * 16,
                                     (_by2 - global.HIDDEN_ROWS)  * 16, _cell.color);
                    if (_cell.inst != undefined) _cell.inst.clearing = true;
                    global.grid[_by2][_bx2] = undefined;
                    _blasted++;
                }
            }
        }
        global.grid[_py][_px] = undefined;
        if (_blasted > 0) {
            var _pts = _blasted * 100 * ((global.feverTimer > 0) ? 2 : 1);
            global.score += _pts; global.levelScore += _pts;
            if (global.score >= 100000) steam_ach_unlock("ACH_SCORE_100K");
            if (global.gameMode == "STORY") global.storyCleared += _blasted;
            global.ui_scales.score = 1.3;
            award_shards(_pts, _blasted);
            charge_jackpot(_blasted + 3);
            update_level_progress();
        }
        instance_destroy(_p);
        global.activePiece = undefined;
        if (_blasted > 0) apply_grid_gravity();
        alarm[0] = 10;
        return;
    }

    // ── SUPER BOMB: 5x5 diamond blast ────────────────────────────────────────
    if (_p.type == "super_bomb") {
        var _sp = _grid_screen_pos(_px, _py);
        create_impact(0, (_py - global.HIDDEN_ROWS + 1) * 16, global.COLS * 16, make_color_rgb(255, 0, 255));
        create_floating_text_ext(_sp.x, _sp.y, "SUPER NOVA!", make_color_rgb(255, 100, 255), 1.8);
        if (global.settings.shakeEnabled) global.shakeAmount = 25;
        global.hitstop = 12;
        sfx_bomb();

        var _blasted = 0;
        var _bdirs = [[-1,0],[1,0],[0,-1],[0,1],[-1,-1],[1,-1],[-1,1],[1,1],[0,-2],[0,2],[-2,0],[2,0]];
        for (var _bi = 0; _bi < array_length(_bdirs); _bi++) {
            var _bx2 = _px + _bdirs[_bi][0]; var _by2 = _py + _bdirs[_bi][1];
            if (_bx2 < 0 || _bx2 >= global.TOTAL_COLS || _by2 < 0 || _by2 >= global.TOTAL_ROWS) continue;
            var _cell = global.grid[_by2][_bx2];
            if (_cell != undefined) {
                if (_cell.type == "core") migrate_core(_bx2, _by2);
                create_particles((_bx2 - global.HIDDEN_SIDES) * 16,
                                 (_by2 - global.HIDDEN_ROWS)  * 16, _cell.color);
                if (_cell.inst != undefined) _cell.inst.clearing = true;
                global.grid[_by2][_bx2] = undefined;
                _blasted++;
            }
        }
        global.grid[_py][_px] = undefined;
        if (_blasted > 0) {
            var _pts = _blasted * 250 * ((global.feverTimer > 0) ? 2 : 1);
            global.score += _pts; global.levelScore += _pts;
            if (global.gameMode == "STORY") global.storyCleared += _blasted;
            global.ui_scales.score = 1.5;
            award_shards(_pts, _blasted);
            charge_jackpot(_blasted + 8);
            update_level_progress();
        }
        instance_destroy(_p);
        global.activePiece = undefined;
        if (_blasted > 0) apply_grid_gravity();
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
    settle_matches();
}

// GRAVITY
// =============================================================================

function apply_grid_gravity() {
    if (global.gameMode == "PLANET" || global.gameMode == "STORY") {
        // Find the core's current position to use as the gravity anchor.
        var _coreX = floor(global.TOTAL_COLS / 2);
        var _coreY = floor(global.TOTAL_ROWS / 2);
        var _foundCore = false;
        
        for (var _cy = 0; _cy < global.TOTAL_ROWS; _cy++) {
            for (var _cx = 0; _cx < global.TOTAL_COLS; _cx++) {
                var _c = global.grid[_cy][_cx];
                if (_c != undefined && _c.type == "core") {
                    _coreX = _cx;
                    _coreY = _cy;
                    _foundCore = true;
                    break;
                }
            }
            if (_foundCore) break;
        }

        // Radial: pull all non-core blocks inward toward the core.
        var _changed = true;
        var _safety = 0;
        while (_changed && _safety < 20) {
            _changed = false;
            _safety++;
            
            var _blockList = [];
            for (var _y = 0; _y < global.TOTAL_ROWS; _y++) {
                for (var _x = 0; _x < global.TOTAL_COLS; _x++) {
                    var _cell = global.grid[_y][_x];
                    if (_cell != undefined && _cell.type != "core") {
                        var _dist = abs(_x - _coreX) + abs(_y - _coreY);
                        array_push(_blockList, { x: _x, y: _y, dist: _dist, cell: _cell });
                    }
                }
            }
            
            // Sort: nearest to core first.
            array_sort(_blockList, function(_a, _b) { return _a.dist - _b.dist; });

            for (var _i = 0; _i < array_length(_blockList); _i++) {
                var _b = _blockList[_i];
                var _x = _b.x; var _y = _b.y; var _cell = _b.cell;
                
                var _dx = sign(_coreX - _x);
                var _dy = sign(_coreY - _y);
                if (_dx == 0 && _dy == 0) continue;
                
                if (abs(_coreX - _x) >= abs(_coreY - _y)) _dy = 0; else _dx = 0;
                
                var _nx = _x + _dx; var _ny = _y + _dy;
                if (_nx >= 0 && _nx < global.TOTAL_COLS && _ny >= 0 && _ny < global.TOTAL_ROWS
                && global.grid[_ny][_nx] == undefined) {
                    global.grid[_ny][_nx] = _cell;
                    global.grid[_y][_x]   = undefined;
                    _cell.inst.grid_x = _nx; 
                    _cell.inst.grid_y = _ny;
                    _changed = true;
                    _b.x = _nx; _b.y = _ny;
                }
            }
        }

        // Clear one-tick landing protection after gravity resolution.
        for (var _cy = 0; _cy < global.TOTAL_ROWS; _cy++) {
            for (var _cx = 0; _cx < global.TOTAL_COLS; _cx++) {
                var _cc = global.grid[_cy][_cx];
                if (_cc != undefined && _cc.inst != undefined && variable_instance_exists(_cc.inst, "just_landed") && _cc.inst.just_landed) {
                    _cc.inst.just_landed = false;
                }
            }
        }
        
        recalculate_planet_surface();
        ensure_planet_core_presence(-1, -1, false);
        enforce_single_core_in_grid();
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
// calculate_landing_depth   how many steps inward before collision?
// -----------------------------------------------------------------------------
function calculate_landing_depth(_gx, _gy) {
    if (global.gameMode == "PLANET" || global.gameMode == "STORY") {
        var _pData = calculate_planet_preview_path(global.activePiece);
        if (_pData != undefined) return _pData.depth;
        return 1;
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
// rotate_grid_90   CLASSIC ONLY, called on level-up rotation
// -----------------------------------------------------------------------------
function rotate_grid_90() {
    // Classic currently uses a non-square playfield; 90-degree transpose on this
    // layout can produce invalid remaps. Keep behavior safe/no-op for now.
    if (global.gameMode == "CLASSIC") return;

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

function enforce_single_core_in_grid() {
    if (!(global.gameMode == "PLANET" || global.gameMode == "STORY")) return 0;

    var _cores = [];
    for (var _y = 0; _y < global.TOTAL_ROWS; _y++) {
        for (var _x = 0; _x < global.TOTAL_COLS; _x++) {
            var _c = global.grid[_y][_x];
            if (_c != undefined && _c.type == "core") array_push(_cores, {x: _x, y: _y});
        }
    }

    if (array_length(_cores) <= 1) return array_length(_cores);

    var _cx = floor(global.TOTAL_COLS / 2);
    var _cy = floor(global.TOTAL_ROWS / 2);
    var _keep = 0;
    var _best = 99999;
    for (var _i = 0; _i < array_length(_cores); _i++) {
        var _p = _cores[_i];
        var _d = abs(_p.x - _cx) + abs(_p.y - _cy);
        if (_d < _best) { _best = _d; _keep = _i; }
    }

    for (var _j = 0; _j < array_length(_cores); _j++) {
        if (_j == _keep) continue;
        var _drop = _cores[_j];
        var _cell = global.grid[_drop.y][_drop.x];
        if (_cell == undefined) continue;
        var _toMetal = (variable_struct_exists(_cell, "core_arrow") && _cell.core_arrow);
        _cell.type = _toMetal ? "metal" : "normal";
        _cell.core_arrow = false;
        if (_cell.inst != undefined) {
            _cell.inst.type = _toMetal ? "metal" : "normal";
            _cell.inst.core_arrow = false;
            with (_cell.inst) update_sprite();
        }
    }

    return 1;
}

// =============================================================================
// MATCH ENGINE INTEGRATION
// =============================================================================

function settle_matches() {
    enforce_single_core_in_grid();

    // Stabilize matching IDs: repair in-flight cells whose id drifted from visuals.
    // If ids are invalid, visually same blocks may fail to clear.
    for (var _sy = 0; _sy < global.TOTAL_ROWS; _sy++) {
        for (var _sx = 0; _sx < global.TOTAL_COLS; _sx++) {
            var _cellFix = global.grid[_sy][_sx];
            if (_cellFix == undefined) continue;
            if (match_cell_is_excluded(_cellFix)) continue;
            if (_cellFix.type == "wild") continue; // Wildcards keep id=999 always
            if (_cellFix.id > 0) continue;

            var _fixedId = 0;
            var _dirsFix = [[-1,0],[1,0],[0,-1],[0,1]];
            var _idCounts = array_create(7, 0); // color ids 1..6
            for (var _di = 0; _di < 4; _di++) {
                var _nxFix = _sx + _dirsFix[_di][0];
                var _nyFix = _sy + _dirsFix[_di][1];
                if (_nxFix < 0 || _nxFix >= global.TOTAL_COLS || _nyFix < 0 || _nyFix >= global.TOTAL_ROWS) continue;
                var _nbFix = global.grid[_nyFix][_nxFix];
                if (_nbFix != undefined && _nbFix.id > 0 && _nbFix.id < array_length(_idCounts)) {
                    _idCounts[_nbFix.id]++;
                }
            }
            var _bestCount = 0;
            for (var _id = 1; _id < array_length(_idCounts); _id++) {
                if (_idCounts[_id] > _bestCount) { _bestCount = _idCounts[_id]; _fixedId = _id; }
            }
            if (_fixedId <= 0 && _cellFix.inst != undefined && variable_instance_exists(_cellFix.inst, "color_id")) {
                _fixedId = _cellFix.inst.color_id;
            }
            if (_fixedId <= 0 && array_length(global.activeColors) > 0) _fixedId = global.activeColors[0];
            if (_fixedId > 0) {
                _cellFix.id = _fixedId;
                _cellFix.color = get_color_from_id(_fixedId);
                if (_cellFix.inst != undefined) {
                    _cellFix.inst.color_id = _fixedId;
                    _cellFix.inst.color = _cellFix.color;
                    with (_cellFix.inst) update_sprite();
                }
            }
        }
    }

    var _matches = find_matches_in_grid(global.grid, { cols: global.TOTAL_COLS }, global.TOTAL_ROWS);
    
    // HARD GUARD: Only proceed if we found a valid 4+ match
    if (array_length(_matches) < 4) {
        _matches = []; // Reject anything smaller than 4
    }

    if (array_length(_matches) > 0) {
        // Final clear guarantee: expand from all matched seeds to the full
        // orthogonally connected same-id component. This prevents L-shape
        // corner leftovers when overlapping patterns resolve in one tick.
        var _clearMask = array_create(global.TOTAL_ROWS);
        var _visit = array_create(global.TOTAL_ROWS);
        for (var _ey = 0; _ey < global.TOTAL_ROWS; _ey++) {
            _clearMask[_ey] = array_create(global.TOTAL_COLS, false);
            _visit[_ey] = array_create(global.TOTAL_COLS, false);
        }
        var _q = [];
        for (var _si = 0; _si < array_length(_matches); _si++) {
            var _sm = _matches[_si];
            if (_sm.x < 0 || _sm.x >= global.TOTAL_COLS || _sm.y < 0 || _sm.y >= global.TOTAL_ROWS) continue;
            var _sc = global.grid[_sm.y][_sm.x];
            if (_sc == undefined) continue;
            _clearMask[_sm.y][_sm.x] = true;
            if (!_visit[_sm.y][_sm.x]) {
                _visit[_sm.y][_sm.x] = true;
                array_push(_q, {x:_sm.x, y:_sm.y, id:_sc.id});
            }
        }
        var _seedMask = array_create(global.TOTAL_ROWS);
        for (var _syE = 0; _syE < global.TOTAL_ROWS; _syE++) _seedMask[_syE] = array_create(global.TOTAL_COLS, false);
        for (var _ss = 0; _ss < array_length(_matches); _ss++) {
            var _sm2 = _matches[_ss];
            if (_sm2.x >= 0 && _sm2.x < global.TOTAL_COLS && _sm2.y >= 0 && _sm2.y < global.TOTAL_ROWS) {
                _seedMask[_sm2.y][_sm2.x] = true;
            }
        }
        var _head = 0;
        var _dirsE = [[1,0],[-1,0],[0,1],[0,-1]];
        while (_head < array_length(_q)) {
            var _n = _q[_head++];
            var _fromCell = global.grid[_n.y][_n.x];
            if (_fromCell == undefined) continue;
            for (var _diE = 0; _diE < 4; _diE++) {
                var _nxE = _n.x + _dirsE[_diE][0];
                var _nyE = _n.y + _dirsE[_diE][1];
                if (_nxE < 0 || _nxE >= global.TOTAL_COLS || _nyE < 0 || _nyE >= global.TOTAL_ROWS) continue;
                if (_visit[_nyE][_nxE]) continue;
                var _ncE = global.grid[_nyE][_nxE];
                if (_ncE == undefined) continue;
                if (_ncE.type == "bomb" || _ncE.type == "dead") continue;
                var _axisE = (_dirsE[_diE][0] != 0) ? "h" : "v";
                if (!match_cells_can_link(_fromCell, _ncE, _axisE, false)) continue;
                
                // Color Lock: Prevent wildcards from bridging different colors during expansion
                if (_n.id != 999 && _ncE.id != 999 && _ncE.id != _n.id) continue;
                var _ncHasArrow = (_ncE.type == "metal") || (variable_struct_exists(_ncE, "core_arrow") && _ncE.core_arrow);
                if (_ncHasArrow && !_seedMask[_nyE][_nxE]) continue;
                _visit[_nyE][_nxE] = true;
                _clearMask[_nyE][_nxE] = true;
                array_push(_q, {x:_nxE, y:_nyE, id:_n.id});
            }
        }
        _matches = [];
        for (var _ryE = 0; _ryE < global.TOTAL_ROWS; _ryE++) {
            for (var _rxE = 0; _rxE < global.TOTAL_COLS; _rxE++) {
                if (_clearMask[_ryE][_rxE]) array_push(_matches, {x:_rxE, y:_ryE});
            }
        }

        var _specialMultiplier = 1;
        var _debtBonus = 0;
        var _voidTax = false;
        var _gravityClears = [];
        var _activeClearMask = array_create(global.TOTAL_ROWS);
        for (var _amy = 0; _amy < global.TOTAL_ROWS; _amy++) _activeClearMask[_amy] = array_create(global.TOTAL_COLS, false);

        var _filteredMatches = [];
        for (var _fm = 0; _fm < array_length(_matches); _fm++) {
            var _pm = _matches[_fm];
            var _pc = global.grid[_pm.y][_pm.x];
            if (_pc == undefined) continue;

            if (_pc.type == "locked" && crack_locked_cell(_pm.x, _pm.y)) {
                continue;
            }

            _activeClearMask[_pm.y][_pm.x] = true;
            array_push(_filteredMatches, _pm);

            if (_pc.type == "multiplier") {
                _specialMultiplier *= max(2, variable_struct_exists(_pc, "special_value") ? _pc.special_value : 2);
            } else if (_pc.type == "debt") {
                _debtBonus += variable_struct_exists(_pc, "special_value") ? _pc.special_value : 750;
            } else if (_pc.type == "gravity") {
                array_push(_gravityClears, {x: _pm.x, y: _pm.y});
            } else if (_pc.type == "core_key") {
                if (!variable_global_exists("sunGateKeys")) global.sunGateKeys = 0;
                global.sunGateKeys++;
                global.walletGems += 1;
                wallet_save();
                var _keySp = _grid_screen_pos(_pm.x, _pm.y);
                create_floating_text_ext(_keySp.x, _keySp.y, "KEY + GEM", c_aqua, 0.85);
            }
        }
        _matches = _filteredMatches;
        var _adjDirs = [[-1,0],[1,0],[0,-1],[0,1]];
        
        // --- SMART CLUSTER COLLECTION PASS ---
        // If ANY block is adjacent to a cleared cell and shares its color, collect it.
        // This allows LINE + ADDITIONS (L-shapes, T-shapes, clusters) to clear together.
        var _extraBlocks = [];
        for (var _am = 0; _am < array_length(_matches); _am++) {
            var _pma = _matches[_am];
            var _pca = global.grid[_pma.y][_pma.x];
            if (_pca == undefined) continue;
            
            for (var _ad = 0; _ad < 4; _ad++) {
                var _ax = _pma.x + _adjDirs[_ad][0];
                var _ay = _pma.y + _adjDirs[_ad][1];
                if (!grid_in_bounds(_ax, _ay)) continue;
                if (_activeClearMask[_ay][_ax]) continue; // already clearing
                
                var _ac = global.grid[_ay][_ax];
                if (_ac != undefined) {
                    // Check if color matches
                    if (match_cells_share_color(_pca, _ac)) {
                        _activeClearMask[_ay][_ax] = true;
                        array_push(_extraBlocks, {x: _ax, y: _ay});
                    }
                }
            }
        }
        for (var _eb = 0; _eb < array_length(_extraBlocks); _eb++) {
            array_push(_matches, _extraBlocks[_eb]);
        }

        if (array_length(_matches) <= 0) {
            global.locking = false;
            recalculate_planet_surface(); // Ensure surface is fresh for next piece preview
            rotate_prism_blocks();
            if (planet_has_outer_danger_block()) {
                global.gameState = "GAMEOVER";
                if (global.score > global.highScore) { global.highScore = global.score; save_high_score(); }
                sfx_game_over();
                return;
            }
            if (story_objective_is_met()) {
                global.gameState = "FINISHING_LEVEL";
                global.finishTimer = 100;
                return;
            }
            spawn_piece();
            return;
        }

        for (var _vm = 0; _vm < array_length(_matches); _vm++) {
            var _mpv = _matches[_vm];
            var _sporeCell = global.grid[_mpv.y][_mpv.x];
            for (var _vd = 0; _vd < 4; _vd++) {
                var _vx = _mpv.x + _adjDirs[_vd][0];
                var _vy = _mpv.y + _adjDirs[_vd][1];
                if (!grid_in_bounds(_vx, _vy)) continue;
                var _vc = global.grid[_vy][_vx];
                if (_vc == undefined) continue;

                if (_vc.type == "void") {
                    _voidTax = true;
                    create_particles((_vx - global.HIDDEN_SIDES) * 16, (_vy - global.HIDDEN_ROWS) * 16, make_color_rgb(65, 35, 100));
                    if (_vc.inst != undefined) _vc.inst.clearing = true;
                    global.grid[_vy][_vx] = undefined;
                } else if (!_activeClearMask[_vy][_vx]) {
                    crack_locked_cell(_vx, _vy);
                    crack_asteroid_cell(_vx, _vy);
                }

                if (_sporeCell != undefined && _sporeCell.type == "spore"
                && _vc != undefined && _vc.type == "normal") {
                    _vc.id = _sporeCell.id;
                    _vc.color = _sporeCell.color;
                    sync_special_cell_visual(_vx, _vy);
                    break;
                }
            }
        }

        global.comboChain++;
        global.pityBudget = max(0, global.pityBudget - (array_length(_matches) * 0.1) - (global.comboChain * 0.2));
        if (global.comboChain >= 3) steam_ach_unlock("ACH_CHAIN_3");
        var _pts = (array_length(_matches) * 100 * global.comboChain * ((global.feverTimer > 0) ? 2 : 1) * _specialMultiplier) + _debtBonus;
        global.score += _pts; global.levelScore += _pts;
        if (global.score >= 100000) steam_ach_unlock("ACH_SCORE_100K");
        
        if (global.gameMode == "STORY") {
            if (global.storyObjectiveType == "clear_cores") {
                // Only count the clear if a core was actually part of the matched set
                var _hasCore = false;
                for(var _ck=0; _ck<array_length(_matches); _ck++) {
                    var _mc2 = global.grid[_matches[_ck].y][_matches[_ck].x];
                    if (_mc2 != undefined && _mc2.type == "core") { _hasCore = true; break; }
                }
                if (_hasCore) global.storyCleared++;
            } else {
                // Clear Board missions count total blocks cleared
                global.storyCleared += array_length(_matches);
            }
        }
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
        if (_specialMultiplier > 1) {
            create_floating_text_ext(global.GAME_W * 0.5, global.GAME_H * 0.36, "x" + string(_specialMultiplier), c_yellow, 1.4);
        }
        if (_debtBonus > 0) {
            create_floating_text_ext(global.GAME_W * 0.5, global.GAME_H * 0.40, "DEBT PAID +" + string(_debtBonus), make_color_rgb(255, 120, 190), 1.1);
        }
        if (!_voidTax) award_shards(_pts, array_length(_matches));
        else create_floating_text_ext(global.GAME_W * 0.5, global.GAME_H * 0.44, "VOID ATE THE SHARDS", make_color_rgb(130, 80, 180), 0.9);
        charge_jackpot(array_length(_matches));
        // Active recovery: good clears restore stability.
        if (variable_global_exists("coreStability")) {
            var _stbGain = 3 + floor(array_length(_matches) * 0.5);
            global.coreStability = min(global.coreStabilityMax, global.coreStability + _stbGain);
        }
        var _newCoreX = -1;
        var _newCoreY = -1;
        var _matchMask = array_create(global.TOTAL_ROWS);
        for (var _my0 = 0; _my0 < global.TOTAL_ROWS; _my0++) _matchMask[_my0] = array_create(global.TOTAL_COLS, false);
        for (var _mk = 0; _mk < array_length(_matches); _mk++) {
            var _mp = _matches[_mk];
            if (_mp.x >= 0 && _mp.x < global.TOTAL_COLS && _mp.y >= 0 && _mp.y < global.TOTAL_ROWS) {
                _matchMask[_mp.y][_mp.x] = true;
            }
        }

        // Resolve core migration once, before clearing matched cells.
        var _oldCoreX = -1;
        var _oldCoreY = -1;
        for (var _mi = 0; _mi < array_length(_matches); _mi++) {
            var _mm = _matches[_mi];
            var _mc = global.grid[_mm.y][_mm.x];
            if (_mc != undefined && _mc.type == "core") {
                _oldCoreX = _mm.x;
                _oldCoreY = _mm.y;
                break;
            }
        }
        if (_oldCoreX >= 0) {
            migrate_core(_oldCoreX, _oldCoreY, _matchMask);
            // Hard guarantee: old core coordinate must be cleared in this resolve.
            var _hasOldCoreInClear = false;
            for (var _chk = 0; _chk < array_length(_matches); _chk++) {
                if (_matches[_chk].x == _oldCoreX && _matches[_chk].y == _oldCoreY) {
                    _hasOldCoreInClear = true;
                    break;
                }
            }
            if (!_hasOldCoreInClear) {
                array_push(_matches, {x: _oldCoreX, y: _oldCoreY});
            }
            // Find the new core to protect it from the current clear cycle.
            for (var _fy = 0; _fy < global.TOTAL_ROWS; _fy++) {
                for (var _fx = 0; _fx < global.TOTAL_COLS; _fx++) {
                    if (_fx == _oldCoreX && _fy == _oldCoreY) continue;
                    var _nc = global.grid[_fy][_fx];
                    if (_nc != undefined && _nc.type == "core") {
                        _newCoreX = _fx;
                        _newCoreY = _fy;
                        break;
                    }
                }
                if (_newCoreX >= 0) break;
            }
        }

        for (var i = array_length(_matches) - 1; i >= 0; i--) {
            var _mpArrow = _matches[i];
            var _cArrow = global.grid[_mpArrow.y][_mpArrow.x];
            if (_cArrow == undefined) continue;
            
            var _isArrow = (_cArrow.type == "metal") || (variable_struct_exists(_cArrow, "core_arrow") && _cArrow.core_arrow);
            if (_isArrow) {
                // Firing a pulse in the arrow's direction
                var _pDir = _cArrow.dir; // 0=H, 1=V, 2=ULDR
                
                // Vertical pulse (V or Cross)
                if (_pDir == 1 || _pDir == 2) {
                    for (var _ay = 0; _ay < global.TOTAL_ROWS; _ay++) {
                        if (_ay == _mpArrow.y) continue;
                        crack_asteroid_cell(_mpArrow.x, _ay);
                        crack_locked_cell(_mpArrow.x, _ay);
                    }
                }
                
                // Horizontal pulse (H or Cross)
                if (_pDir == 0 || _pDir == 2) {
                    for (var _ax = 0; _ax < global.TOTAL_COLS; _ax++) {
                        if (_ax == _mpArrow.x) continue;
                        crack_asteroid_cell(_ax, _mpArrow.y);
                        crack_locked_cell(_ax, _mpArrow.y);
                    }
                }
            }
        }

        for (var i = array_length(_matches) - 1; i >= 0; i--) {
            var _m = _matches[i];
            var _cell = global.grid[_m.y][_m.x];
            if (_cell == undefined) continue;
            if (_m.x == _newCoreX && _m.y == _newCoreY
            && !(_m.x == _oldCoreX && _m.y == _oldCoreY)) continue;
            if (_cell.type == "core") {
                var _toMetal2 = (variable_struct_exists(_cell, "core_arrow") && _cell.core_arrow);
                _cell.type = _toMetal2 ? "metal" : "normal";
                _cell.core_arrow = false;
                if (_cell.inst != undefined) {
                    _cell.inst.type = _toMetal2 ? "metal" : "normal";
                    _cell.inst.core_arrow = false;
                }
            }
            // Asteroids are no longer cleared by color matches (Junk rule)
            // They are only cleared by crack_asteroid_cell via collateral neighbor logic
            var _sp = _grid_screen_pos(_m.x, _m.y);
            var _pts_each = 100 * global.comboChain * ((global.feverTimer > 0) ? 2 : 1);
            create_floating_text_ext(_sp.x, _sp.y, "+" + string(_pts_each), _cell.color, 0.8);
            if (!_voidTax && variable_struct_exists(_cell, "shard_value") && _cell.shard_value > 0) {
                collect_block_shards(_m.x, _m.y, _cell.shard_value);
            }
            create_particles((_m.x - global.HIDDEN_SIDES) * 16,
                             (_m.y - global.HIDDEN_ROWS)  * 16, _cell.color);
            if (_cell.inst != undefined) _cell.inst.clearing = true;
            global.grid[_m.y][_m.x] = undefined;
        }
        cleanup_grid_ghost_cells();
        for (var _gc = 0; _gc < array_length(_gravityClears); _gc++) {
            pull_cells_toward(_gravityClears[_gc].x, _gravityClears[_gc].y);
        }
        apply_grid_gravity();
        cleanup_grid_ghost_cells();
        rotate_prism_blocks();
        // Always guarantee a valid core after a clear cycle.
        if (global.gameMode == "PLANET" || global.gameMode == "STORY") {
            ensure_planet_core_presence(_oldCoreX, _oldCoreY, false);
            enforce_single_core_in_grid();
        }
        if (planet_has_outer_danger_block()) {
            global.gameState = "GAMEOVER";
            if (global.score > global.highScore) { global.highScore = global.score; save_high_score(); }
            sfx_game_over();
            global.locking = false;
            return;
        }
        alarm[0] = 15;
    } else {
        // No clear happened: remove one-tick landing protection now.
        for (var _cy = 0; _cy < global.TOTAL_ROWS; _cy++) {
            for (var _cx = 0; _cx < global.TOTAL_COLS; _cx++) {
                var _cc = global.grid[_cy][_cx];
                if (_cc != undefined && _cc.inst != undefined && variable_instance_exists(_cc.inst, "just_landed") && _cc.inst.just_landed) {
                    _cc.inst.just_landed = false;
                }
            }
        }

        global.bestCombo = max(global.bestCombo, global.comboChain);
        global.locking = false;
        global.comboChain = 0;
        if (global.gameMode == "STORY") {
            global.storyWavesSurvived++;
        }
        rotate_prism_blocks();
        if (planet_has_outer_danger_block()) {
            global.gameState = "GAMEOVER";
            if (global.score > global.highScore) { global.highScore = global.score; save_high_score(); }
            sfx_game_over();
            return;
        }
        var _bestCluster = debug_largest_cluster_size();
        if (_bestCluster == 3) {
            create_floating_text_ext(global.GAME_W * 0.5, global.GAME_H * 0.55,
                "1 MORE!", make_color_rgb(200, 200, 200), 0.9);
        }
        if (story_objective_is_met()) {
            story_trigger_level_complete();
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

function cleanup_grid_ghost_cells() {
    for (var _y = 0; _y < global.TOTAL_ROWS; _y++) {
        for (var _x = 0; _x < global.TOTAL_COLS; _x++) {
            var _c = global.grid[_y][_x];
            if (_c == undefined) continue;
            if (_c.inst == undefined) {
                global.grid[_y][_x] = undefined;
                continue;
            }
            if (!instance_exists(_c.inst)) {
                global.grid[_y][_x] = undefined;
                continue;
            }
        }
    }
}

// =============================================================================
// CORE STABILITY SYSTEM
// =============================================================================
// If the core drifts away from center, stability drains.
// Low stability increases time pressure until the core is recentred.
function update_core_stability() {
    if (!(global.gameMode == "PLANET" || global.gameMode == "STORY")) return;
    if (global.gameState != "PLAYING") return;

    var _coreX = -1;
    var _coreY = -1;
    for (var _y = 0; _y < global.TOTAL_ROWS; _y++) {
        for (var _x = 0; _x < global.TOTAL_COLS; _x++) {
            var _c = global.grid[_y][_x];
            if (_c != undefined && _c.type == "core") {
                _coreX = _x;
                _coreY = _y;
                break;
            }
        }
        if (_coreX >= 0) break;
    }

    if (_coreX < 0) return;

    var _cx = floor(global.TOTAL_COLS / 2);
    var _cy = floor(global.TOTAL_ROWS / 2);
    var _dist = abs(_coreX - _cx) + abs(_coreY - _cy);

    if (_dist <= 0) {
        global.coreStability = min(global.coreStabilityMax, global.coreStability + global.coreStabilityRecoverRate);
    } else {
        global.coreStability = max(0, global.coreStability - (global.coreStabilityDrainBase + _dist));
    }

    if (_dist > 0 && global.coreStability < 60) {
        // Pressure: timer burns faster while core is unstable.
        global.pieceTimer = max(1, global.pieceTimer - 1);
    }
    global.coreUnstable = (_dist > 0);
}

function grid_cell_is_playable(_x, _y) {
    if (_x < global.HIDDEN_SIDES || _x >= global.TOTAL_COLS - global.HIDDEN_SIDES) return false;
    if (_y < global.HIDDEN_ROWS  || _y >= global.TOTAL_ROWS - global.HIDDEN_ROWS) return false;
    return true;
}

function migrate_core(_oldX, _oldY, _avoidMask = undefined) {
    global.coresCleared++;
    steam_ach_unlock("ACH_CORE_BREAKER");
    // Demote old core immediately to avoid dual-core protection ambiguity.
    if (_oldX >= 0 && _oldX < global.TOTAL_COLS && _oldY >= 0 && _oldY < global.TOTAL_ROWS) {
        var _oldCell = global.grid[_oldY][_oldX];
        if (_oldCell != undefined && _oldCell.type == "core") {
            var _toMetal3 = (variable_struct_exists(_oldCell, "core_arrow") && _oldCell.core_arrow);
            _oldCell.type = _toMetal3 ? "metal" : "normal";
            _oldCell.core_arrow = false;
            if (_oldCell.inst != undefined) _oldCell.inst.type = _toMetal3 ? "metal" : "normal";
            if (_oldCell.inst != undefined) _oldCell.inst.core_arrow = false;
        }
    }
    var _candidates = [];
    var _dirs = [[-1,0],[1,0],[0,-1],[0,1]];
    for (var i = 0; i < 4; i++) {
        var _nx = _oldX + _dirs[i][0]; var _ny = _oldY + _dirs[i][1];
        if (_nx < 0 || _nx >= global.TOTAL_COLS || _ny < 0 || _ny >= global.TOTAL_ROWS) continue;
        if (!grid_cell_is_playable(_nx, _ny)) continue;
        var _cell = global.grid[_ny][_nx];
        if (_cell != undefined && _cell.type != "core" && _cell.type != "bomb"
        && _cell.type != "drill" && _cell.type != "dead"
        && (_cell.inst == undefined || !variable_instance_exists(_cell.inst, "clearing") || !_cell.inst.clearing)) {
            var _avoid = false;
            if (_avoidMask != undefined && is_array(_avoidMask) && _ny >= 0 && _ny < array_length(_avoidMask)) {
                var _row = _avoidMask[_ny];
                if (is_array(_row) && _nx >= 0 && _nx < array_length(_row)) _avoid = _row[_nx];
            }
            if (!_avoid) array_push(_candidates, {x: _nx, y: _ny});
        }
    }

    if (array_length(_candidates) > 0) {
        // Smart migration: score each candidate by number of same-color neighbors.
        // Core migrates toward where play is densest, rewarding strategic thinking.
        var _bestScore = -999;
        var _bestPick  = _candidates[0];
        for (var _ci = 0; _ci < array_length(_candidates); _ci++) {
            var _cand     = _candidates[_ci];
            var _candCell = global.grid[_cand.y][_cand.x];
            var _score    = 0;
            // Bonus for same-color neighbors (makes a near-match even nearer)
            for (var _cd = 0; _cd < 4; _cd++) {
                var _cnx = _cand.x + _dirs[_cd][0];
                var _cny = _cand.y + _dirs[_cd][1];
                if (_cnx < 0 || _cnx >= global.TOTAL_COLS || _cny < 0 || _cny >= global.TOTAL_ROWS) continue;
                var _nb = global.grid[_cny][_cnx];
                if (_nb != undefined && _nb.id == _candCell.id) _score += 4;
                if (_nb != undefined && _nb.type != undefined) _score += 1; // any neighbor = more active
            }
            // Prefer staying closer to center (fairer, less likely to get stuck in corner)
            var _dist = max(abs(_cand.x - floor(global.TOTAL_COLS/2)), abs(_cand.y - floor(global.TOTAL_ROWS/2)));
            _score -= _dist;
            // Small random tie-break so same-scored cells still vary
            _score += random(0.5);
            if (_score > _bestScore) { _bestScore = _score; _bestPick = _cand; }
        }
        var _newCore = global.grid[_bestPick.y][_bestPick.x];
        var _promotedFromMetal = (_newCore.type == "metal");
        _newCore.type = "core";
        _newCore.core_arrow = _promotedFromMetal;
        if (_newCore.inst != undefined) {
            _newCore.inst.type = "core";
            _newCore.inst.core_arrow = _promotedFromMetal;
            with (_newCore.inst) update_sprite();
        }
        var _sp = _grid_screen_pos(_bestPick.x, _bestPick.y);
        create_floating_text_ext(_sp.x, _sp.y, "CORE MIGRATED!", c_white, 1.2);
    }
    cleanup_grid_ghost_cells();
}

function ensure_planet_core_presence(_preferX = -1, _preferY = -1, _showText = false) {
    if (!(global.gameMode == "PLANET" || global.gameMode == "STORY")) return false;

    // Remove invalid cores that ended up outside playable board.
    for (var _y = 0; _y < global.TOTAL_ROWS; _y++) {
        for (var _x = 0; _x < global.TOTAL_COLS; _x++) {
            var _cell = global.grid[_y][_x];
            if (_cell != undefined && _cell.type == "core" && !grid_cell_is_playable(_x, _y)) {
                var _toMetal4 = (variable_struct_exists(_cell, "core_arrow") && _cell.core_arrow);
                _cell.type = _toMetal4 ? "metal" : "normal";
                _cell.core_arrow = false;
                if (_cell.inst != undefined && instance_exists(_cell.inst)) {
                    _cell.inst.type = _toMetal4 ? "metal" : "normal";
                    _cell.inst.core_arrow = false;
                    with (_cell.inst) update_sprite();
                }
            }
        }
    }

    // Fast path: already has a valid playable core.
    for (var _y2 = 0; _y2 < global.TOTAL_ROWS; _y2++) {
        for (var _x2 = 0; _x2 < global.TOTAL_COLS; _x2++) {
            var _cell2 = global.grid[_y2][_x2];
            if (_cell2 != undefined && _cell2.type == "core" && grid_cell_is_playable(_x2, _y2)) return true;
        }
    }

    var _chooseX = -1;
    var _chooseY = -1;
    var _cx = floor(global.TOTAL_COLS / 2);
    var _cy = floor(global.TOTAL_ROWS / 2);

    // 1) Preferred coordinate (old core position).
    if (_preferX >= 0 && _preferX < global.TOTAL_COLS && _preferY >= 0 && _preferY < global.TOTAL_ROWS
    && grid_cell_is_playable(_preferX, _preferY)) {
        var _pc = global.grid[_preferY][_preferX];
        if (_pc != undefined && _pc.inst != undefined && _pc.type != "bomb" && _pc.type != "drill" && _pc.type != "dead") {
            _chooseX = _preferX; _chooseY = _preferY;
        }
    }

    // 2) Center cell if occupied by a valid block.
    if (_chooseX < 0) {
        var _cc = global.grid[_cy][_cx];
        if (grid_cell_is_playable(_cx, _cy)
        && _cc != undefined && _cc.inst != undefined && _cc.type != "bomb" && _cc.type != "drill" && _cc.type != "dead") {
            _chooseX = _cx; _chooseY = _cy;
        }
    }

    // 3) Nearest valid occupied cell to center.
    if (_chooseX < 0) {
        var _bestDist = 9999;
        for (var _yy = 0; _yy < global.TOTAL_ROWS; _yy++) {
            for (var _xx = 0; _xx < global.TOTAL_COLS; _xx++) {
                if (!grid_cell_is_playable(_xx, _yy)) continue;
                var _c = global.grid[_yy][_xx];
                if (_c == undefined || _c.inst == undefined) continue;
                if (_c.type == "bomb" || _c.type == "drill" || _c.type == "dead") continue;
                var _d = abs(_xx - _cx) + abs(_yy - _cy);
                if (_d < _bestDist) {
                    _bestDist = _d;
                    _chooseX = _xx;
                    _chooseY = _yy;
                }
            }
        }
    }

    // 4) No valid block exists: Spawn a fresh core at center.
    if (_chooseX < 0) {
        var _cxR = floor(global.TOTAL_COLS / 2);
        var _cyR = floor(global.TOTAL_ROWS / 2);
        var _cIdx = (array_length(global.activeColors) > 0) ? 0 : 0;
        var _coreIdR = (array_length(global.activeColors) > 0) ? global.activeColors[_cIdx] : 1;
        var _coreColR = get_color_from_id(_coreIdR);
        var _coreDataR = { type: "core", color: _coreColR, dir: 0, id: _coreIdR, core_arrow: false };
        var _instR = _place_block_instance(_cxR, _cyR, _coreDataR);
        global.grid[_cyR][_cxR] = { type: "core", color: _coreColR, dir: 0, id: _coreIdR, inst: _instR, core_arrow: false };
        
        recalculate_planet_surface();
        return true;
    }

    // Promote chosen cell into the new core.
    var _newCore = global.grid[_chooseY][_chooseX];
    var _promotedFromMetal2 = (_newCore.type == "metal");
    _newCore.type = "core";
    _newCore.core_arrow = _promotedFromMetal2;
    if (_newCore.inst != undefined) _newCore.inst.type = "core";
    if (_newCore.inst != undefined) _newCore.inst.core_arrow = _promotedFromMetal2;
    if (_newCore.id <= 0) {
        _newCore.id = (array_length(global.activeColors) > 0) ? global.activeColors[0] : 1;
        _newCore.color = get_color_from_id(_newCore.id);
        _newCore.inst.color_id = _newCore.id;
        _newCore.inst.color = _newCore.color;
    }
    if (_newCore.inst != undefined) with (_newCore.inst) update_sprite();
    if (_showText) {
        var _sp = _grid_screen_pos(_chooseX, _chooseY);
        create_floating_text_ext(_sp.x, _sp.y, "CORE RE-ESTABLISHED!", c_white, 1.25);
    }
    return true;
}

// ─────────────────────────────────────────────────────────────────────────────
// recalculate_planet_surface — Caches the shallowest block distance for performance
// ─────────────────────────────────────────────────────────────────────────────
function recalculate_planet_surface() {
    cleanup_grid_ghost_cells();
    var _cx = floor(global.TOTAL_COLS / 2);
    var _cy = floor(global.TOTAL_ROWS / 2);
    var _minDist = _cx;
    var _maxDist = 1;
    for (var _sy = global.HIDDEN_ROWS; _sy < global.TOTAL_ROWS - global.HIDDEN_ROWS; _sy++) {
        for (var _sx = global.HIDDEN_SIDES; _sx < global.TOTAL_COLS - global.HIDDEN_SIDES; _sx++) {
            if (global.grid[_sy][_sx] != undefined) {
                var _d = max(abs(_sx - _cx), abs(_sy - _cy));
                if (_d < _minDist) _minDist = _d;
                if (_d > _maxDist) _maxDist = _d;
            }
        }
    }
    global.planetSurfaceDist = max(_minDist, 1);
    global.planetOuterRadius = max(_maxDist, 1);
}

// ─────────────────────────────────────────────────────────────────────────────
// calculate_planet_preview_path — Traces the path from spawn to landing
// Returns: { path: [{gx, gy}], target: {gx, gy}, depth: int }
// ─────────────────────────────────────────────────────────────────────────────
function calculate_planet_preview_path(_inst) {
    if (_inst == undefined) return undefined;
    cleanup_grid_ghost_cells();

    var _tx  = _inst.grid_x;
    var _ty  = _inst.grid_y;
    var _cx  = floor(global.TOTAL_COLS / 2);
    var _cy  = floor(global.TOTAL_ROWS / 2);
    var _centerCell = global.grid[_cy][_cx];
    var _centerOccupied = (_centerCell != undefined
        && _centerCell.inst != undefined
        && instance_exists(_centerCell.inst)
        && (!variable_instance_exists(_centerCell.inst, "clearing") || !_centerCell.inst.clearing));
    var _s   = ((global.orbitalSide % 4) + 4) % 4;
    var _isHeavy     = (global.launchCharge >= global.MAX_CHARGE);
    var _isDrill     = (_inst.type == "drill");
    var _penetration = (_inst.type == "drill") ? 3 : 0;
    var _path  = [];
    var _depth = 0;

    // Pure radial direction — straight inward from spawn cell (spoke of a wheel)
    var _ddx = 0, _ddy = 0;
    if (_s == 0) _ddy =  1;   // top    → drop down
    if (_s == 1) _ddx = -1;   // right  → drop left
    if (_s == 2) _ddy = -1;   // bottom → drop up
    if (_s == 3) _ddx =  1;   // left   → drop right

    // Use cached surface distance for performance
    var _surfaceDist = global.planetSurfaceDist;

    for (var i = 0; i < global.TOTAL_ROWS + global.TOTAL_COLS; i++) {

        var _nx = _tx + _ddx;
        var _ny = _ty + _ddy;
        if (_nx < 0 || _nx >= global.TOTAL_COLS || _ny < 0 || _ny >= global.TOTAL_ROWS) break;

        // Surface cap: don't tunnel through a truly occupied center.
        // If center is empty, allow path to reach it (no invisible center wall).
        if (!_isDrill && !_isHeavy) {
            var _distToCenter = max(abs(_nx - _cx), abs(_ny - _cy));
            if (_centerOccupied && _distToCenter < _surfaceDist) break;
        }

        if (global.grid[_ny][_nx] != undefined) {
            var _target = global.grid[_ny][_nx];
            if (_isHeavy || (_penetration > 0 && _target.type != "core"
            && _target.type != "dead" && _target.type != "bomb")) {
                if (_isHeavy) _isHeavy = false; else _penetration--;
                var _hx = _nx + _ddx;
                var _hy = _ny + _ddy;
                if (_hx >= 0 && _hx < global.TOTAL_COLS && _hy >= 0 && _hy < global.TOTAL_ROWS
                && global.grid[_hy][_hx] == undefined) {
                    _tx = _nx; _ty = _ny; _depth++;
                    array_push(_path, {gx: _tx, gy: _ty});
                    continue;
                }
            }
            break;
        }
        _tx = _nx; _ty = _ny; _depth++;
        array_push(_path, {gx: _tx, gy: _ty});
    }

    // ── PRE-CALCULATE MATCH HIGHLIGHT (Performance Optimization) ──
    var _hlList = [];
    var _isMatchRdy = false;
    if (_tx >= 0 && _tx < global.TOTAL_COLS && _ty >= 0 && _ty < global.TOTAL_ROWS) {
        var _hlVis = [];
        for (var _vy = 0; _vy < global.TOTAL_ROWS; _vy++) _hlVis[_vy] = array_create(global.TOTAL_COLS, false);
        _hlVis[_ty][_tx] = true;
        var _nbDirs = [[-1,0],[1,0],[0,-1],[0,1]];
        var _hlQueue = [];
        
        // Initial neighbors
        for (var _nd = 0; _nd < 4; _nd++) {
            var _nnx = _tx + _nbDirs[_nd][0], _nny = _ty + _nbDirs[_nd][1];
            if (_nnx >= 0 && _nnx < global.TOTAL_COLS && _nny >= 0 && _nny < global.TOTAL_ROWS) {
                var _nc = global.grid[_nny][_nnx];
                if (_nc != undefined && _nc.id == _inst.color_id && cell_can_match(_nc)) {
                    _hlVis[_nny][_nnx] = true;
                    array_push(_hlList, {x: _nnx, y: _nny});
                    array_push(_hlQueue, {x: _nnx, y: _nny});
                }
            }
        }
        
        // BFS with head pointer for O(N) performance
        var _head = 0;
        while (_head < array_length(_hlQueue)) {
            var _curr = _hlQueue[_head++];
            for (var _nd = 0; _nd < 4; _nd++) {
                var _nnx = _curr.x + _nbDirs[_nd][0], _nny = _curr.y + _nbDirs[_nd][1];
                if (_nnx >= 0 && _nnx < global.TOTAL_COLS && _nny >= 0 && _nny < global.TOTAL_ROWS) {
                    var _nc = global.grid[_nny][_nnx];
                    if (_nc != undefined && _nc.id == _inst.color_id && !_hlVis[_nny][_nnx] && cell_can_match(_nc)) {
                        _hlVis[_nny][_nnx] = true;
                        array_push(_hlList, {x: _nnx, y: _nny});
                        array_push(_hlQueue, {x: _nnx, y: _nny});
                    }
                }
            }
        }
        // Match occurs if 3+ neighbors share color (making 4 including self)
        _isMatchRdy = (array_length(_hlList) >= 3);
    }

    return { path: _path, target: {gx: _tx, gy: _ty}, depth: _depth, hlList: _hlList, isMatchRdy: _isMatchRdy };
}

// ─────────────────────────────────────────────────────────────────────────────
// handle_planet_input — Processes all orbital movement and firing
// ─────────────────────────────────────────────────────────────────────────────
function handle_planet_input(_controls) {
    var _ap = global.activePiece;
    if (_ap == undefined || global.locking) return;

    var _prevSide = global.orbitalSide;
    var _lane    = get_orbital_lane_bounds(global.orbitalX);
    var _laneMin = _lane.min;
    var _laneMax = _lane.max;
    global.orbitalX = clamp(global.orbitalX, _laneMin, _laneMax);
    
    // Side rotation
    if (_controls.rotL) { global.orbitalSide--; global.targetRotation = global.orbitalSide * 90; sfx_piece_move(); }
    if (_controls.rotR) { global.orbitalSide++; global.targetRotation = global.orbitalSide * 90; sfx_piece_move(); }

    // Orbital movement
    if (_controls.moveDir != 0) {
        global.orbitalX += _controls.moveDir;
        if (global.orbitalX < _laneMin) { global.orbitalSide--; global.orbitalX = _laneMax; }
        if (global.orbitalX > _laneMax) { global.orbitalSide++; global.orbitalX = _laneMin; }
        global.targetRotation = global.orbitalSide * 90;
        sfx_piece_move();
    }

    // Re-clamp after side changes (Q/E or wrap) so bounds stay adaptive per side.
    _lane = get_orbital_lane_bounds(global.orbitalX);
    _laneMin = _lane.min;
    _laneMax = _lane.max;
    global.orbitalX = clamp(global.orbitalX, _laneMin, _laneMax);

    // Update position and path
    var _pos = get_orbital_pos(global.orbitalSide, global.orbitalX);
    var _posChanged = (_ap.grid_x != _pos.x || _ap.grid_y != _pos.y);
    _ap.grid_x = _pos.x; _ap.grid_y = _pos.y;
    _ap.x = (_pos.x - global.HIDDEN_SIDES) * 16;
    _ap.y = (_pos.y - global.HIDDEN_ROWS) * 16;

    if (_posChanged || global.previewData == undefined) {
        global.previewData = calculate_planet_preview_path(_ap);
        global.previewDepth = (global.previewData != undefined) ? global.previewData.depth : 1;
    }

    // Preview depth is now fully automatic from path solver.
    // Manual up/down placement nudging removed.

    _ap.rotation = 0;
    if (_prevSide != global.orbitalSide) sfx_piece_move();

    // Charging and firing
    if (_controls.fireHeld) global.launchCharge = min(global.launchCharge + 1, global.MAX_CHARGE);
    if (_controls.fireRel || global.launchCharge >= global.MAX_CHARGE) {
        hard_drop_radial();
    }
}
