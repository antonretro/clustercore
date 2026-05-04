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

function special_clear_reward(_count, _basePts, _label, _color, _hitstopBase = 4) {
    if (_count <= 0) return;
    
    global.hitstop = min(_hitstopBase + _count, 12);
    var _pts = _count * _basePts * ((global.feverTimer > 0) ? 2 : 1);
    global.score += _pts;
    global.levelScore += _pts;
    
    if (global.score >= 100000) steam_ach_unlock("ACH_SCORE_100K");
    if (global.gameMode == "STORY") global.storyCleared += _count;
    
    global.ui_scales.score = 1.4;
    award_shards(_pts, _count);
    
    var _jackpotVal = _count + 2;
    if (_label == "SUPER NOVA!") _jackpotVal += 5;
    charge_jackpot(_jackpotVal);
    
    update_level_progress();
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
        if (_dist >= 5 && _p.type != "drill") {
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
        shield_hp: variable_instance_exists(_p, "shield_hp") ? _p.shield_hp : 0,
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

    // ── SPECIALS: resolve immediately upon locking ──────────────────────────
    if (_p.type == "drill") {
        var _vx = 0; var _vy = 1; 
        if (global.gameMode == "PLANET" || global.gameMode == "STORY") {
            var _rot90 = round(global.targetRotation / 90) mod 4;
            if (_rot90 < 0) _rot90 += 4;
            switch (_rot90) {
                case 1: _vx = -1; _vy = 0; break;
                case 2: _vx = 0;  _vy = -1; break;
                case 3: _vx = 1;  _vy = 0; break;
            }
        }
        var _count = resolve_drill(_px, _py, _vx, _vy);
        if (_count > 0) {
             special_clear_reward(_count, 150, "DRILLED", make_color_rgb(200, 220, 255), 4);
             apply_grid_gravity();
        }
        instance_destroy(_p);
        global.activePiece = undefined;
        return;
    }

    if (_p.type == "bomb") {
        var _count = resolve_bomb(_px, _py, 1);
        if (_count > 0) {
            special_clear_reward(_count, 100, "ULTRA BLAST!", c_orange, 6);
            apply_grid_gravity();
        }
        global.grid[_py][_px] = undefined;
        instance_destroy(_p);
        global.activePiece = undefined;
        return;
    }

    if (_p.type == "super_bomb") {
        var _count = resolve_super_bomb(_px, _py);
        if (_count > 0) {
            special_clear_reward(_count, 250, "SUPER NOVA!", make_color_rgb(255, 100, 255), 10);
            apply_grid_gravity();
        }
        global.grid[_py][_px] = undefined;
        instance_destroy(_p);
        global.activePiece = undefined;
        return;
    }

    if (_p.type == "magnet") {
        pull_cells_toward(_px, _py);
        sfx_drill();
    }

    // ── End of lock: gravity + match check ───────────────────────────────────
    global.activePiece = undefined;
    if (global.settings.shakeEnabled) global.shakeAmount = 2;
    settle_matches();
}

// GRAVITY
// =============================================================================


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

    var _cx = floor(global.TOTAL_COLS / 2);
    var _cy = floor(global.TOTAL_ROWS / 2);
    
    // NEW RULE: If there is a block in the absolute center, it MUST be the core.
    // This satisfies the user requirement that the core stays centered.
    var _centerCell = global.grid[_cy][_cx];
    if (_centerCell != undefined && _centerCell.type != "core" 
    && _centerCell.type != "bomb" && _centerCell.type != "drill" && _centerCell.type != "dead"
    && (_centerCell.inst == undefined || !variable_instance_exists(_centerCell.inst, "clearing") || !_centerCell.inst.clearing)) {
        // Promote center to core
        _centerCell.type = "core";
        if (_centerCell.inst != undefined && instance_exists(_centerCell.inst)) {
            _centerCell.inst.type = "core";
            with (_centerCell.inst) update_sprite();
        }
    }

    var _cores = [];
    for (var _y = 0; _y < global.TOTAL_ROWS; _y++) {
        for (var _x = 0; _x < global.TOTAL_COLS; _x++) {
            var _c = global.grid[_y][_x];
            if (_c != undefined && _c.type == "core") array_push(_cores, {x: _x, y: _y});
        }
    }

    if (array_length(_cores) <= 1) return array_length(_cores);

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
        if (_cell.inst != undefined && instance_exists(_cell.inst)) {
            _cell.inst.type = _toMetal ? "metal" : "normal";
            _cell.inst.core_arrow = false;
            with (_cell.inst) update_sprite();
        }
    }

    return 1;
}

// =============================================================================
// =============================================================================
// CHAIN REACTION SYSTEM
// =============================================================================
function chain_ensure_globals() {
    if (!variable_global_exists("chainActive")) global.chainActive = false;
    if (!variable_global_exists("chainTimer")) global.chainTimer = 0;
    if (!variable_global_exists("chainWave")) global.chainWave = 0;
    if (!variable_global_exists("chainStoredMatches")) global.chainStoredMatches = [];
}

function chain_get_rating_text(_wave) {
    switch (_wave) {
        case 1:  return "GOOD";
        case 2:  return "GREAT";
        case 3:  return "AMAZING";
        case 4:  return "FANTASTIC";
        case 5:  return "AWESOME";
        default: return "CLUSTER!!";
    }
}

function chain_get_rating_color(_wave) {
    switch (_wave) {
        case 1:  return make_color_rgb(180, 255, 180);
        case 2:  return make_color_rgb(100, 255, 100);
        case 3:  return make_color_rgb(255, 220, 80);
        case 4:  return make_color_rgb(255, 160, 40);
        case 5:  return make_color_rgb(255, 100, 180);
        case 6:  return make_color_rgb(180, 100, 255);
        default: return make_color_rgb(255, 80, 80);
    }
}

// =============================================================================
// MATCH ENGINE INTEGRATION
// =============================================================================

function settle_matches() {
    chain_ensure_globals();
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
            
            // METAL PROTECTION: Do not stabilize/steal IDs for metal/arrow blocks
            if (_cellFix.type == "metal") continue;

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

    if (array_length(_matches) >= 4) {
        // --- ENDGAME PROTECTION ---
        // Count total non-core blocks to detect the final "Satisfying" finish
        var _totalDebris = 0;
        for (var _ty = 0; _ty < global.TOTAL_ROWS; _ty++) {
            for (var _tx = 0; _tx < global.TOTAL_COLS; _tx++) {
                var _tc = global.grid[_ty][_tx];
                if (_tc != undefined && _tc.type != "core") _totalDebris++;
            }
        }
        var _isEndgame = (_totalDebris <= 16); // Increased threshold to catch more 'lone block' cases
        
        // --- ROOT CAUSE FIX: COLOR-STRICT EXPANSION ---
        // We run a separate expansion for each matched component to prevent 
        // wildcards from 'bridging' two different colored matches together.
        var _finalClearMask = array_create(global.TOTAL_ROWS);
        for (var _myM = 0; _myM < global.TOTAL_ROWS; _myM++) _finalClearMask[_myM] = array_create(global.TOTAL_COLS, false);
        
        var _seedMask = array_create(global.TOTAL_ROWS);
        for (var _syE = 0; _syE < global.TOTAL_ROWS; _syE++) _seedMask[_syE] = array_create(global.TOTAL_COLS, false);
        for (var _ss = 0; _ss < array_length(_matches); _ss++) {
            _seedMask[_matches[_ss].y][_matches[_ss].x] = true;
            _finalClearMask[_matches[_ss].y][_matches[_ss].x] = true;
        }

        var _processed = array_create(global.TOTAL_ROWS);
        for (var _py = 0; _py < global.TOTAL_ROWS; _py++) _processed[_py] = array_create(global.TOTAL_COLS, false);

        for (var _si = 0; _si < array_length(_matches); _si++) {
            var _sm = _matches[_si];
            if (_processed[_sm.y][_sm.x]) continue;
            
            var _sc = global.grid[_sm.y][_sm.x];
            if (_sc == undefined) continue;
            var _matchId = _sc.id;
            
            // Start BFS from this seed
            var _q = [{x: _sm.x, y: _sm.y}];
            _processed[_sm.y][_sm.x] = true;
            var _head = 0;
            var _dirs = [[1,0],[-1,0],[0,1],[0,-1]];
            
            while (_head < array_length(_q)) {
                var _n = _q[_head++];
                for (var _di = 0; _di < 4; _di++) {
                    var _nx = _n.x + _dirs[_di][0];
                    var _ny = _n.y + _dirs[_di][1];
                    if (!grid_in_bounds(_nx, _ny) || _processed[_ny][_nx]) continue;
                    
                    var _nc = global.grid[_ny][_nx];
                    if (_nc == undefined || match_cell_is_excluded(_nc)) continue;
                    
                    // COLOR RULE: Neighbor must match the SEED color or be a wildcard.
                    // But wildcards cannot bridge to a NEW color in this pass.
                    if (_nc.id != _matchId && _nc.id != WILDCARD_ID && _matchId != WILDCARD_ID) continue;
                    
                    // ARROW PROTECTION: Protect both Metal and Core-Arrows from expansion.
                    // (User requested: "not inlcuding other arwos i meant reg blocks")
                    var _ncIsAr = (_nc.type == "metal") || (variable_struct_exists(_nc, "core_arrow") && _nc.core_arrow);
                    if (_ncIsAr && !_seedMask[_ny][_nx]) continue;
                    
                    // REQUISITION: "IF THER ARE ANY EXTRA BLOCKS MAKE SURE THEY CLEAR"
                    // We removed 'Endgame Protection' which was preventing lone blocks from being sucked in during the final stretch.
                    
                    _processed[_ny][_nx] = true;
                    _finalClearMask[_ny][_nx] = true;
                    array_push(_q, {x: _nx, y: _ny});
                }
            }
        }
        
        _matches = [];
        for (var _ry = 0; _ry < global.TOTAL_ROWS; _ry++) {
            for (var _rx = 0; _rx < global.TOTAL_COLS; _rx++) {
                if (_finalClearMask[_ry][_rx]) array_push(_matches, {x: _rx, y: _ry});
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

        // ── CHAIN REACTION DETECTION ────────────────────────────────────────
        // After gravity settles, check if any new matches cascaded into place.
        // If so, pause and let the player see each wave with a rating callout.
        var _chainMatches = find_matches_in_grid(global.grid, { cols: global.TOTAL_COLS }, global.TOTAL_ROWS);
        if (array_length(_chainMatches) >= 4) {
            if (!global.chainActive) { global.chainActive = true; global.chainWave = 1; }
            else { global.chainWave++; }
            global.chainTimer = 45; // Increased delay for satisfying chain feel

            var _rating = chain_get_rating_text(global.chainWave);
            var _rCol = chain_get_rating_color(global.chainWave);
            var _rScale = 1.0 + global.chainWave * 0.12;
            create_floating_text_ext(global.GAME_W * 0.5, global.GAME_H * 0.38, _rating, _rCol, _rScale);

            global.locking = false;
            return;
        }
        // No chain: business as usual
        global.chainActive = false;
        global.chainWave = 0;

        if (story_objective_is_met()) {
            story_trigger_level_complete();
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

        global.chainActive = false;
        global.chainWave = 0;
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
        var _bestCluster = debug_largest_blob_size();
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
    
    // In Story Mode Clear Board missions, we don't want to infinitely replace cores.
    // If the board is being cleared, let the core stay gone so the level can end.
    if (global.gameMode == "STORY" && global.storyObjectiveType == "clear_board") {
        // If we already have no core, and we're in clear_board mode, don't force a new one.
        // This allows the board to actually become empty.
    } else {
        // Normal logic for other modes: always ensure a core exists
    }

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

    // If we're here, no core was found. 
    // In Clear Board mode, if the core is gone, we WANT it to stay gone.
    if (global.gameMode == "STORY" && global.storyObjectiveType == "clear_board") {
        return false; 
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

// recalculate_planet_surface, calculate_planet_preview_path, handle_planet_input
// → moved to scr_planet_input.gml
