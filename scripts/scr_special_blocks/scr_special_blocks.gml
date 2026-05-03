// =============================================================================
// scr_special_blocks - Logic for bombs, drills, magnets, and environmental blocks
// =============================================================================

function crack_locked_cell(_gx, _gy) {
    if (!grid_in_bounds(_gx, _gy)) return false;
    var _c = global.grid[_gy][_gx];
    if (_c == undefined || _c.type != "locked") return false;

    if (!variable_struct_exists(_c, "locked_hp")) _c.locked_hp = 1;
    _c.locked_hp--;
    if (_c.inst != undefined && instance_exists(_c.inst)) {
        _c.inst.locked_hp = _c.locked_hp;
        with(_c.inst) update_sprite();
    }

    if (_c.locked_hp <= 0) {
        // Unlock: transform to normal block
        _c.type = "normal";
        if (_c.inst != undefined && instance_exists(_c.inst)) {
            _c.inst.type = "normal";
            with(_c.inst) update_sprite();
        }
        create_particles((_gx - global.HIDDEN_SIDES) * 16, (_gy - global.HIDDEN_ROWS) * 16, c_white, 10);
        return true;
    }
    return false;
}


function crack_asteroid_cell(_gx, _gy) {
    if (!grid_in_bounds(_gx, _gy)) return false;
    var _c = global.grid[_gy][_gx];
    if (_c == undefined || _c.type != "asteroid") return false;

    if (!variable_struct_exists(_c, "shield_hp")) _c.shield_hp = 1;
    _c.shield_hp--;
    if (_c.inst != undefined && instance_exists(_c.inst)) {
        _c.inst.shield_hp = _c.shield_hp;
        with(_c.inst) update_sprite();
    }

    if (_c.shield_hp <= 0) {
        global.grid[_gy][_gx] = undefined;
        if (_c.inst != undefined && instance_exists(_c.inst)) {
            _c.inst.clearing = true;
            instance_destroy(_c.inst);
        }
        create_particles((_gx - global.HIDDEN_SIDES) * 16, (_gy - global.HIDDEN_ROWS) * 16, c_gray, 15);
        return true;
    }
    return false;
}


function rotate_prism_blocks() {
    for (var _y = 0; _y < global.TOTAL_ROWS; _y++) {
        for (var _x = 0; _x < global.TOTAL_COLS; _x++) {
            var _c = global.grid[_y][_x];
            if (_c != undefined && _c.type == "prism") {
                _c.dir = (_c.dir + 1) mod 4;
                if (_c.inst != undefined && instance_exists(_c.inst)) {
                    _c.inst.dir = _c.dir;
                    with(_c.inst) update_sprite();
                }
            }
        }
    }
}


function resolve_bomb(_gx, _gy, _radius = 1) {
    var _count = 0;
    for (var _dy = -_radius; _dy <= _radius; _dy++) {
        for (var _dx = -_radius; _dx <= _radius; _dx++) {
            var _nx = _gx + _dx;
            var _ny = _gy + _dy;
            if (!grid_in_bounds(_nx, _ny)) continue;

            var _c = global.grid[_ny][_nx];
            if (_c != undefined) {
                if (_c.type == "core") continue; // Core is immune to standard bombs
                
                if (_c.inst != undefined && instance_exists(_c.inst)) {
                    _c.inst.clearing = true;
                    instance_destroy(_c.inst);
                }
                global.grid[_ny][_nx] = undefined;
                _count++;
            }
        }
    }
    create_particles((_gx - global.HIDDEN_SIDES) * 16, (_gy - global.HIDDEN_ROWS) * 16, c_orange, 30);
    sfx_bomb();
    return _count;
}


function resolve_drill(_gx, _gy, _dx, _dy) {
    var _count = 0;
    var _cx = _gx + _dx;
    var _cy = _gy + _dy;

    while (grid_in_bounds(_cx, _cy)) {
        var _c = global.grid[_cy][_cx];
        if (_c != undefined) {
            if (_c.type == "core") break; // Drill stops at core
            
            if (_c.inst != undefined && instance_exists(_c.inst)) {
                _c.inst.clearing = true;
                instance_destroy(_c.inst);
            }
            global.grid[_cy][_cx] = undefined;
            _count++;
        }
        _cx += _dx;
        _cy += _dy;
    }
    sfx_drill();
    return _count;
}

function resolve_super_bomb(_gx, _gy) {
    var _sp = _grid_screen_pos(_gx, _gy);
    create_impact(0, (_gy - global.HIDDEN_ROWS + 1) * 16, global.COLS * 16, make_color_rgb(255, 0, 255));
    create_floating_text_ext(_sp.x, _sp.y, "SUPER NOVA!", make_color_rgb(255, 100, 255), 1.8);
    if (global.settings.shakeEnabled) global.shakeAmount = 25;
    global.hitstop = 12;
    sfx_bomb();

    var _blasted = 0;
    var _bdirs = [[-1,0],[1,0],[0,-1],[0,1],[-1,-1],[1,-1],[-1,1],[1,1],[0,-2],[0,2],[-2,0],[2,0]];
    for (var _bi = 0; _bi < array_length(_bdirs); _bi++) {
        var _bx2 = _gx + _bdirs[_bi][0]; 
        var _by2 = _gy + _bdirs[_bi][1];
        if (!grid_in_bounds(_bx2, _by2)) continue;
        
        var _cell = global.grid[_by2][_bx2];
        if (_cell != undefined) {
            if (_cell.type == "core") migrate_core(_bx2, _by2);
            create_particles((_bx2 - global.HIDDEN_SIDES) * 16, (_by2 - global.HIDDEN_ROWS) * 16, _cell.color);
            if (_cell.inst != undefined) _cell.inst.clearing = true;
            global.grid[_by2][_bx2] = undefined;
            _blasted++;
        }
    }
    return _blasted;
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
        if (_cell.inst != undefined && instance_exists(_cell.inst)) {
            _cell.inst.grid_x = _tx;
            _cell.inst.grid_y = _ty;
            _cell.inst.x = (_tx - global.HIDDEN_SIDES) * 16;
            _cell.inst.y = (_ty - global.HIDDEN_ROWS) * 16;
        }
    }
}
