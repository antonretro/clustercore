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
function cluster_core_draw_block(_inst, _bx, _by, _scale, _alphaOverride = -1, _xOverride = -1, _yOverride = -1) {
    // Determine drawing coordinates (allow absolute screen override for ghost piece)
    var _ix = (_xOverride != -1) ? (_xOverride - 8 * _scale) : (_bx + (_inst.x * _scale));
    var _iy = (_yOverride != -1) ? (_yOverride - 8 * _scale) : (_by + (_inst.y * _scale));
    
    // Centers for sprites that draw from center
    var _cx = _ix + 8 * _scale;
    var _cy = _iy + 8 * _scale;

    var _alpha = (_alphaOverride != -1) ? _alphaOverride : _inst.image_alpha;
    
    // Block square: counter-rotate by boardRotation so it always appears UPRIGHT
    var _blockRot = _inst.visualRotation + _inst.rotation - global.boardRotation;
    // Arrow overlay: no counter-rotation — matrix naturally rotates it with the board
    var _arrowRot = _inst.visualRotation + _inst.rotation;

    // 1. Draw Base Sprite
    if (_inst.sprite_index != -1 && sprite_exists(_inst.sprite_index)) {
        var _baseSpr = _inst.sprite_index;
        if (_inst.type == "super_bomb") {
            var _sbAsset = asset_get_index("spr_super_bomb");
            if (sprite_exists(_sbAsset)) _baseSpr = _sbAsset;
        }
        
        // --- 1px Gap/Padding Logic ---
        // We slightly shrink the sprite so the grid lines show through
        var _gapScl = 0.94; // approx 1px gap at standard scale
        draw_sprite_ext(_baseSpr, _inst.image_index, _cx, _cy,
            _scale * _inst.scale_x * _gapScl, _scale * _inst.scale_y * _gapScl, _blockRot, c_white, _alpha);
    }
    
    // 2. Specialty Overlays (Drawn on top of base color)
    var _sclX = _scale * _inst.scale_x;
    var _sclY = _scale * _inst.scale_y;

    // Metal / Directional Core arrows
    if (_inst.type == "metal" || (_inst.type == "core" && variable_instance_exists(_inst, "core_arrow") && _inst.core_arrow)) {
        var _arSpr = spr_lr_arrows;
        if (_inst.dir == 1) _arSpr = spr_ud_arrows;
        if (_inst.dir == 2) _arSpr = asset_get_index("spr_uldr_arrows");
        
        if (sprite_exists(_arSpr)) {
            draw_sprite_ext(_arSpr, 0, _cx, _cy, _sclX, _sclY, _arrowRot, c_white, _alpha);
        }
    }
    
    // Overlay Sprites with Text Fallbacks
    var _mark = "";
    var _markCol = c_white;
    var _overlaySpr = -1;

    switch (_inst.type) {
        case "locked": 
            var _lhp = variable_instance_exists(_inst, "locked_hp") ? _inst.locked_hp : 2;
            if (_lhp >= 2) _overlaySpr = asset_get_index("spr_locked_cage");
            else _overlaySpr = asset_get_index("spr_locked_overlay");
            _mark = ""; 
            break;
        case "multiplier": 
            _overlaySpr = asset_get_index("spr_multiplier_overlay");
            _mark = "x2"; _markCol = c_yellow; 
            break;
        case "spore": 
            _overlaySpr = asset_get_index("spr_spore_overlay");
            _mark = "..."; _markCol = make_color_rgb(180, 255, 150); 
            break;
        case "void": 
            _overlaySpr = asset_get_index("spr_void_overlay");
            _mark = "O"; _markCol = make_color_rgb(40, 15, 80); 
            break;
        case "debt":
            _mark = "$"; _markCol = make_color_rgb(255, 110, 190);
            break;
        case "gravity":
            _mark = "G"; _markCol = make_color_rgb(170, 220, 255);
            break;
        case "prism":
            _mark = "<>"; _markCol = c_aqua;
            break;
        case "core_key":
            _mark = "K"; _markCol = c_aqua;
            break;
        case "super_bomb":
            _mark = "!!!"; _markCol = make_color_rgb(255, 100, 255);
            break;
    }

    if (_overlaySpr != -1 && sprite_exists(_overlaySpr)) {
        draw_sprite_ext(_overlaySpr, 0, _cx, _cy, _sclX, _sclY, _blockRot, c_white, _alpha);
    } else if (_mark != "") {
        draw_set_halign(fa_center); draw_set_valign(fa_middle);
        draw_set_alpha(_alpha);
        var _font = asset_get_index("main_font");
        if (_font != -1) draw_set_font(_font);
        draw_set_color(_markCol);
        draw_text_transformed(_cx, _cy + 1 * _scale, _mark, 0.45 * _scale, 0.45 * _scale, 0);
        draw_set_alpha(1.0);
        draw_set_halign(fa_left); draw_set_valign(fa_top);
    }
    
    // Shard/Gem overlays
    if (variable_instance_exists(_inst, "shard_value") && _inst.shard_value > 0) {
        var _shSeed = (_inst.grid_x * 13) + (_inst.grid_y * 17);
        var _shPulse = 0.86 + abs(sin(current_time * 0.008 + _shSeed)) * 0.18;
        var _shSpr = asset_get_index("spr_shard_on_block");
        if (_shSpr != -1 && sprite_exists(_shSpr)) {
            draw_sprite_ext(_shSpr, 0, _cx, _cy - 2 * _scale, _sclX * _shPulse, _sclY * _shPulse, _blockRot, c_white, _alpha);
        }
    }

    // 3. Core glow/highlight
    if (_inst.type == "core") {
        gpu_set_blendmode(bm_add);
        var _cp2 = 0.3 + abs(sin(current_time * 0.005)) * 0.4;
        draw_sprite_ext(_inst.sprite_index, _inst.image_index, _cx, _cy, _scale*_inst.scale_x*1.4, _scale*_inst.scale_y*1.4, _blockRot, c_white, _cp2 * 0.5 * _alpha);
        gpu_set_blendmode(bm_normal);
        
        draw_set_color(c_white); draw_set_alpha((_cp2 + 0.2) * _alpha);
        draw_rectangle(_cx - 9*_scale, _cy - 9*_scale, _cx + 9*_scale, _cy + 9*_scale, true);
        draw_rectangle(_cx - 10*_scale, _cy-10*_scale, _cx+10*_scale, _cy+10*_scale, true);
        draw_set_alpha(1.0);
    }
}

// Returns the display sprite for a piece data struct (used by HUD panels).
function get_piece_sprite(_piece) {
    if (_piece == undefined) return spr_pinkSprite;
    if (_piece.type == "bomb")       return spr_bomb;
    if (_piece.type == "super_bomb") return asset_get_index("spr_super_bomb");
    if (_piece.type == "drill")      return spr_drill;
    if (_piece.type == "dead")       return spr_deadmetal;
    if (_piece.type == "metal")      return spr_pinkSprite; // arrow overlay drawn separately
    var _colorSprites = [spr_pinkSprite, spr_pinkSprite, spr_orangeSprite, spr_yellowSprite, spr_redSprite, spr_lightblueSprite, spr_greenSprite];
    var _idx = clamp(_piece.id, 0, array_length(_colorSprites) - 1);
    return _colorSprites[_idx];
}
