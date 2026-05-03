// =============================================================================
// scr_grid_gravity - Deterministic gravity solvers for all game modes
// =============================================================================

function apply_grid_gravity() {
    if (global.gameMode == "PLANET" || global.gameMode == "STORY") {
        return apply_planet_gravity();
    } else {
        return apply_classic_gravity();
    }
}


function apply_planet_gravity() {
    var _anyMoved = false;
    var _cx = floor(global.TOTAL_COLS / 2);
    var _cy = floor(global.TOTAL_ROWS / 2);

    var _safety = 0;
    var _changed = true;
    while (_changed && _safety < 50) {
        _changed = false;
        _safety++;

        // Iterate through all cells and try to move each one step closer to center
        for (var _y = 0; _y < global.TOTAL_ROWS; _y++) {
            for (var _x = 0; _x < global.TOTAL_COLS; _x++) {
                if (match_planet_gravity_step(_x, _y, _cx, _cy)) {
                    _changed = true;
                    _anyMoved = true;
                }
            }
        }
    }
    return _anyMoved;
}


function match_planet_gravity_step(_gx, _gy, _cx, _cy) {
    var _c = global.grid[_gy][_gx];
    if (_c == undefined || _c.type == "core") return false;

    // Determine inward direction
    var _dx = sign(_cx - _gx);
    var _dy = sign(_cy - _gy);
    
    // 1. Try moving directly inward (orthogonal)
    // Favor X if it's further away, otherwise favor Y
    if (abs(_cx - _gx) >= abs(_cy - _gy)) {
        if (_dx != 0 && global.grid[_gy][_gx + _dx] == undefined) {
            return move_grid_cell(_gx, _gy, _gx + _dx, _gy);
        }
        if (_dy != 0 && global.grid[_gy + _dy][_gx] == undefined) {
            return move_grid_cell(_gx, _gy, _gx, _gy + _dy);
        }
    } else {
        if (_dy != 0 && global.grid[_gy + _dy][_gx] == undefined) {
            return move_grid_cell(_gx, _gy, _gx, _gy + _dy);
        }
        if (_dx != 0 && global.grid[_gy][_gx + _dx] == undefined) {
            return move_grid_cell(_gx, _gy, _gx + _dx, _gy);
        }
    }

    // 2. Try diagonal movement if orthogonal is blocked
    if (_dx != 0 && _dy != 0) {
        if (global.grid[_gy + _dy][_gx + _dx] == undefined) {
            return move_grid_cell(_gx, _gy, _gx + _dx, _gy + _dy);
        }
    }
    
    return false;
}


function apply_classic_gravity() {
    var _anyMoved = false;
    var _changed = true;
    var _safety = 0;
    
    while (_changed && _safety < 50) {
        _changed = false;
        _safety++;
        
        // Bottom-up sweep for classic vertical gravity
        for (var _y = global.TOTAL_ROWS - 2; _y >= 0; _y--) {
            for (var _x = 0; _x < global.TOTAL_COLS; _x++) {
                if (global.grid[_y][_x] != undefined && global.grid[_y+1][_x] == undefined) {
                    if (move_grid_cell(_x, _y, _x, _y + 1)) {
                        _changed = true;
                        _anyMoved = true;
                    }
                }
            }
        }
    }
    return _anyMoved;
}


function move_grid_cell(_fx, _fy, _tx, _ty) {
    if (!grid_in_bounds(_tx, _ty)) return false;
    if (global.grid[_ty][_tx] != undefined) return false;

    var _cell = global.grid[_fy][_fx];
    global.grid[_ty][_tx] = _cell;
    global.grid[_fy][_fx] = undefined;

    if (_cell.inst != undefined && instance_exists(_cell.inst)) {
        _cell.inst.grid_x = _tx;
        _cell.inst.grid_y = _ty;
        // Visual interpolation is handled in obj_block step
    }
    return true;
}
