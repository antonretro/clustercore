// Drawing helpers and path calculations are now centralized here.

// ─────────────────────────────────────────────────────────────────────────────
// calculate_planet_preview_path — Traces the path from spawn to landing
// Returns: { path: [{gx, gy}], target: {gx, gy}, depth: int }
// ─────────────────────────────────────────────────────────────────────────────
function drawlogic_calculate_planet_preview_path_legacy(_inst) {
    if (_inst == undefined) return undefined;
    
    var _tx = _inst.grid_x;
    var _ty = _inst.grid_y;
    var _isHeavy = (global.launchCharge >= global.MAX_CHARGE);
    var _path = [];
    var _depth = 0;
    var _centerGX = floor(global.TOTAL_COLS / 2);
    var _centerGY = floor(global.TOTAL_ROWS / 2);
    
    // We trace up to TOTAL_ROWS steps to ensure we find a landing
    for (var i = 0; i < global.TOTAL_ROWS; i++) {
        var _ddx = sign(_centerGX - _tx);
        var _ddy = sign(_centerGY - _ty);
        if (_ddx == 0 && _ddy == 0) break;
        
        // Preferred axis logic matching hard_drop_radial
        if (abs(_centerGX - _tx) >= abs(_centerGY - _ty)) _ddy = 0; else _ddx = 0;
        
        var _nx = _tx + _ddx;
        var _ny = _ty + _ddy;
        
        if (_nx < 0 || _nx >= global.TOTAL_COLS || _ny < 0 || _ny >= global.TOTAL_ROWS) break;
        
        if (global.grid[_ny][_nx] != undefined) {
            // Heavy logic: try to displace
            if (_isHeavy) {
                var _hx = _nx + _ddx;
                var _hy = _ny + _ddy;
                if (_hx >= 0 && _hx < global.TOTAL_COLS && _hy >= 0 && _hy < global.TOTAL_ROWS
                && global.grid[_hy][_hx] == undefined) {
                    _isHeavy = false; // consume charge
                    _tx = _nx; _ty = _ny; _depth++;
                    array_push(_path, {gx: _tx, gy: _ty});
                    continue;
                }
            }
            break; // hit something
        }
        
        _tx = _nx; _ty = _ny; _depth++;
        array_push(_path, {gx: _tx, gy: _ty});
    }
    
    return {
        path: _path,
        target: {gx: _tx, gy: _ty},
        depth: _depth
    };
}

// ─────────────────────────────────────────────────────────────────────────────
// draw_block_instance — Centralised block rendering
// ─────────────────────────────────────────────────────────────────────────────
function draw_block_instance(_inst, _bx, _by, _scale) {
    var _drawX = _bx + (_inst.x * _scale);
    var _drawY = _by + (_inst.y * _scale);
    var _cx = _drawX + 8 * _scale;
    var _cy = _drawY + 8 * _scale;

    // Use visual rotation logic: stay upright relative to screen
    var _renderRot = -global.boardRotation + _inst.visualRotation + _inst.rotation;

    if (_inst.sprite_index != -1) {
        draw_sprite_ext(_inst.sprite_index, _inst.image_index, _cx, _cy,
            _scale * _inst.scale_x, _scale * _inst.scale_y, _renderRot, c_white, _inst.image_alpha);
    }
    
    // Metal arrow overlay (rotates WITH board)
    if (_inst.type == "metal") {
        var _arSpr = (_inst.dir == 0) ? spr_lr_arrows : spr_ud_arrows;
        draw_sprite_ext(_arSpr, 0, _cx, _cy, _scale * _inst.scale_x, _scale * _inst.scale_y, 0, c_white, _inst.image_alpha);
    }
    
    // Core glow/highlight
    if (_inst.type == "core") {
        gpu_set_blendmode(bm_add);
        var _cp2 = 0.3 + abs(sin(current_time * 0.005)) * 0.4;
        draw_sprite_ext(_inst.sprite_index, _inst.image_index, _cx, _cy, _scale*_inst.scale_x*1.4, _scale*_inst.scale_y*1.4, _renderRot, c_white, _cp2 * 0.5);
        gpu_set_blendmode(bm_normal);
        draw_set_color(c_white); draw_set_alpha(_cp2 + 0.2);
        draw_rectangle(_cx - 9*_scale, _cy - 9*_scale, _cx + 9*_scale, _cy + 9*_scale, true);
        draw_rectangle(_cx - 10*_scale, _cy-10*_scale, _cx+10*_scale, _cy+10*_scale, true);
        draw_set_alpha(1.0);
    }
}
