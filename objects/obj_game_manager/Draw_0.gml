// --- Surface Management ---
if (!surface_exists(global.game_surface)) {
    global.game_surface = surface_create(global.GAME_W, global.GAME_H);
}

// Update Shake
if (global.shakeAmount > 0) {
    global.shakeAmount *= 0.9;
    if (global.shakeAmount < 0.1) global.shakeAmount = 0;
}

gpu_set_texfilter(false);
surface_set_target(global.game_surface);
draw_clear_alpha(c_black, 0);

// --- Draw Low-Res Game World ---
var _shakeX = random_range(-global.shakeAmount, global.shakeAmount);
var _shakeY = random_range(-global.shakeAmount, global.shakeAmount);

// Shifting Gradient Background
draw_rectangle_color(0, 0, global.GAME_W, global.GAME_H, global.bg_colors[0], global.bg_colors[1], global.bg_colors[2], global.bg_colors[1], false);

// Background Stars (Fever Warp)
var _isFever = (global.feverTimer > 0);
for (var i = 0; i < array_length(global.bg_stars); i++) {
    var _s = global.bg_stars[i];
    draw_set_alpha(_isFever ? 0.8 : (_s.spd * 2));
    draw_set_color(c_white);
    if (_isFever) {
        draw_line_width(_s.x, _s.y, _s.x, _s.y - 40, _s.size);
    } else {
        draw_rectangle(_s.x, _s.y, _s.x + _s.size, _s.y + _s.size, false);
    }
}
draw_set_alpha(1.0);

// Board Dimensions (Scaled by PIXEL_SCALE)
var _scale = global.PIXEL_SCALE;
var _bw = global.COLS * 16 * _scale; 
var _bh = global.ROWS * 16 * _scale;
var _bx = (global.GAME_W - _bw) / 2 + _shakeX;
var _by = (global.GAME_H - _bh) / 2 + _shakeY;

// --- Planet Mode Staging Ring ---
// Draw an outer ring of cells one step outside the board, where the active piece waits.
if (global.gameMode == "PLANET" || global.gameMode == "STORY") {
    var _cw = 16 * _scale; // cell width in pixels
    // Piece position in the staging ring
    var _ap_gx = -999;
    var _ap_gy = -999;
    if (global.activePiece != undefined) {
        _ap_gx = global.activePiece.grid_x;
        _ap_gy = global.activePiece.grid_y;
    }
    var _ringPulse = 0.18 + abs(sin(current_time * 0.007)) * 0.22;
    var _apColor   = (global.activePiece != undefined) ? global.activePiece.color : c_white;

    // Helper — draw one staging cell
    // Top row  (gy = HIDDEN_ROWS - 1): gx = 0..COLS-1
    for (var _gx = 0; _gx < global.COLS; _gx++) {
        var _gy_ring = global.HIDDEN_ROWS - 1;
        var _tx = _bx + (_gx * _cw);
        var _ty = _by - _cw;                // 1 cell above the board
        var _isActive = (_gx == _ap_gx && _gy_ring == _ap_gy);
        // Cell fill
        draw_set_alpha(_isActive ? 0.55 : 0.25);
        draw_set_color(_isActive ? _apColor : make_color_rgb(50, 30, 80));
        draw_rectangle(_tx, _ty, _tx + _cw, _ty + _cw, false);
        // Cell border
        draw_set_alpha(_isActive ? 0.9 : 0.35);
        draw_set_color(_isActive ? _apColor : make_color_rgb(110, 60, 160));
        draw_rectangle(_tx, _ty, _tx + _cw, _ty + _cw, true);
        // Glow on active cell
        if (_isActive) {
            gpu_set_blendmode(bm_add);
            draw_set_alpha(_ringPulse * 0.7);
            draw_set_color(_apColor);
            draw_rectangle(_tx - 2, _ty - 2, _tx + _cw + 2, _ty + _cw + 2, false);
            gpu_set_blendmode(bm_normal);
        }
    }
    // Right column (gx = COLS): gy = HIDDEN_ROWS..TOTAL_ROWS-1
    for (var _gy = global.HIDDEN_ROWS; _gy < global.TOTAL_ROWS; _gy++) {
        var _gx_ring = global.COLS;
        var _tx = _bx + _bw;               // 1 cell right of the board
        var _ty = _by + ((_gy - global.HIDDEN_ROWS) * _cw);
        var _isActive = (_gx_ring == _ap_gx && _gy == _ap_gy);
        draw_set_alpha(_isActive ? 0.55 : 0.25);
        draw_set_color(_isActive ? _apColor : make_color_rgb(50, 30, 80));
        draw_rectangle(_tx, _ty, _tx + _cw, _ty + _cw, false);
        draw_set_alpha(_isActive ? 0.9 : 0.35);
        draw_set_color(_isActive ? _apColor : make_color_rgb(110, 60, 160));
        draw_rectangle(_tx, _ty, _tx + _cw, _ty + _cw, true);
        if (_isActive) {
            gpu_set_blendmode(bm_add);
            draw_set_alpha(_ringPulse * 0.7);
            draw_set_color(_apColor);
            draw_rectangle(_tx - 2, _ty - 2, _tx + _cw + 2, _ty + _cw + 2, false);
            gpu_set_blendmode(bm_normal);
        }
    }
    // Bottom row (gy = TOTAL_ROWS): gx = 0..COLS-1
    for (var _gx = 0; _gx < global.COLS; _gx++) {
        var _gy_ring = global.TOTAL_ROWS;
        var _tx = _bx + (_gx * _cw);
        var _ty = _by + _bh;               // 1 cell below the board
        var _isActive = (_gx == _ap_gx && _gy_ring == _ap_gy);
        draw_set_alpha(_isActive ? 0.55 : 0.25);
        draw_set_color(_isActive ? _apColor : make_color_rgb(50, 30, 80));
        draw_rectangle(_tx, _ty, _tx + _cw, _ty + _cw, false);
        draw_set_alpha(_isActive ? 0.9 : 0.35);
        draw_set_color(_isActive ? _apColor : make_color_rgb(110, 60, 160));
        draw_rectangle(_tx, _ty, _tx + _cw, _ty + _cw, true);
        if (_isActive) {
            gpu_set_blendmode(bm_add);
            draw_set_alpha(_ringPulse * 0.7);
            draw_set_color(_apColor);
            draw_rectangle(_tx - 2, _ty - 2, _tx + _cw + 2, _ty + _cw + 2, false);
            gpu_set_blendmode(bm_normal);
        }
    }
    // Left column (gx = -1): gy = HIDDEN_ROWS..TOTAL_ROWS-1
    for (var _gy = global.HIDDEN_ROWS; _gy < global.TOTAL_ROWS; _gy++) {
        var _gx_ring = -1;
        var _tx = _bx - _cw;               // 1 cell left of the board
        var _ty = _by + ((_gy - global.HIDDEN_ROWS) * _cw);
        var _isActive = (_gx_ring == _ap_gx && _gy == _ap_gy);
        draw_set_alpha(_isActive ? 0.55 : 0.25);
        draw_set_color(_isActive ? _apColor : make_color_rgb(50, 30, 80));
        draw_rectangle(_tx, _ty, _tx + _cw, _ty + _cw, false);
        draw_set_alpha(_isActive ? 0.9 : 0.35);
        draw_set_color(_isActive ? _apColor : make_color_rgb(110, 60, 160));
        draw_rectangle(_tx, _ty, _tx + _cw, _ty + _cw, true);
        if (_isActive) {
            gpu_set_blendmode(bm_add);
            draw_set_alpha(_ringPulse * 0.7);
            draw_set_color(_apColor);
            draw_rectangle(_tx - 2, _ty - 2, _tx + _cw + 2, _ty + _cw + 2, false);
            gpu_set_blendmode(bm_normal);
        }
    }
    draw_set_alpha(1.0);
}

// Board Backdrop (Glassmorphism)
draw_set_alpha(0.85);
draw_set_color(make_color_rgb(15, 15, 25));
draw_roundrect_ext(_bx - 12, _by - 12, _bx + _bw + 12, _by + _bh + 12, 20, 20, false);
draw_set_alpha(1.0);

draw_set_color((global.feverTimer > 0) ? c_yellow : global.COLOR_ACCENT);
draw_roundrect_ext(_bx - 12, _by - 12, _bx + _bw + 12, _by + _bh + 12, 20, 20, true);

// Death Line
var _dlY = _by;
gpu_set_blendmode(bm_add);
draw_set_alpha(0.6);
draw_set_color(global.COLOR_DANGER);
draw_line_width(_bx, _dlY, _bx + _bw, _dlY, 3);
gpu_set_blendmode(bm_normal);
draw_set_alpha(1.0);

// --- Ghost Piece (Projected Landing Spot) ---
if (global.gameState == "PLAYING" && global.activePiece != undefined && global.settings.ghostEnabled) {
    var _ap = global.activePiece;
    var _gx = _ap.grid_x;
    var _gy = _ap.grid_y;
    var _cx = floor(global.COLS / 2);
    var _cy = global.HIDDEN_ROWS + floor(global.ROWS / 2);
    
    // Find Landing Spot (Guided by manual previewDepth, restricted by collisions)
    if (global.gameMode == "PLANET" || global.gameMode == "STORY") {
        var _maxD = global.previewDepth;
        var _isHeavy = (global.launchCharge >= global.MAX_CHARGE);
        
        for (var i = 0; i < _maxD; i++) {
            var _dx = sign(_cx - _gx);
            var _dy = sign(_cy - _gy);
            if (_dx == 0 && _dy == 0) break;
            if (abs(_cx - _gx) >= abs(_cy - _gy)) _dy = 0; else _dx = 0;
            
            var _tx = _gx + _dx;
            var _ty = _gy + _dy;
            
            if (_tx < 0 || _tx >= global.COLS || _ty < 0 || _ty >= global.TOTAL_ROWS) break;
            
            var _hit = (global.grid[_ty][_tx] != undefined);
            if (_hit) {
                // --- SIMULATE HEAVY IMPACT ---
                if (_isHeavy) {
                    var _hx = _tx + _dx;
                    var _hy = _ty + _dy;
                    if (_hx >= 0 && _hx < global.COLS && _hy >= 0 && _hy < global.TOTAL_ROWS) {
                        if (global.grid[_hy][_hx] == undefined) {
                            // Can displace! Continue through this cell
                            _isHeavy = false; // Only once
                            _gx = _tx;
                            _gy = _ty;
                            continue;
                        }
                    }
                }
                break; // Real collision
            }
            
            _gx = _tx;
            _gy = _ty;
        }
    } else {
        while (_gy < global.TOTAL_ROWS - 1) {
            if (global.grid[_gy + 1][_gx] != undefined) break;
            _gy++;
        }
    }
    
    var _gpcx = _bx + (_gx * 16 * _scale) + (8 * _scale);
    var _gpcy = _by + ((_gy - global.HIDDEN_ROWS) * 16 * _scale) + (8 * _scale);
    var _apcx = _bx + (_ap.grid_x * 16 * _scale) + (8 * _scale);
    var _apcy = _by + ((_ap.grid_y - global.HIDDEN_ROWS) * 16 * _scale) + (8 * _scale);
    var _sameCell = (_gx == _ap.grid_x && _gy == _ap.grid_y);
    
    // Rotation Sync: Base Counter-Rotate + Manual Piece Spin
    var _gRot = -global.boardRotation + _ap.visualRotation;
    
    if (_gy >= global.HIDDEN_ROWS && !_sameCell) {
        var _activeSpr = _ap.sprite_index;
        // Holographic Pulse
        var _pulse = 0.22 + (abs(sin(current_time * 0.008)) * 0.22);
        
        // Guided Sniper Laser: active mineral to landing target.
        gpu_set_blendmode(bm_add);
        draw_set_alpha(0.30 + _pulse);
        draw_set_color(_ap.color);
        draw_line_width(_apcx, _apcy, _gpcx, _gpcy, max(2, 2 * _scale));
        draw_set_alpha(0.75);
        draw_set_color(c_white);
        draw_line_width(_apcx, _apcy, _gpcx, _gpcy, max(1, _scale));
        gpu_set_blendmode(bm_normal);
        
        draw_set_alpha(_pulse);
        
        // 1. Draw Block Pattern (Monitor-Locked / Billboarded)
        draw_sprite_ext(_activeSpr, 0, _gpcx, _gpcy, _scale, _scale, _gRot, c_white, _pulse);
        
        // 2. Draw Arrows (Planet-Locked / Rotate with planet)
        if (_ap.type == "metal") {
            var _arrowSpr = (_ap.dir == 0) ? spr_lr_arrows : spr_ud_arrows;
            // Use 0 rotation so the Matrix spins it with the planet
            draw_sprite_ext(_arrowSpr, 0, _gpcx, _gpcy, _scale, _scale, 0, c_white, _pulse);
        }
        
        // 3. Targeting Cross
        draw_set_color(_ap.color);
        draw_set_alpha(0.85);
        draw_rectangle(_gpcx - (10 * _scale), _gpcy - (10 * _scale), _gpcx + (10 * _scale), _gpcy + (10 * _scale), true);
        draw_set_color(c_white);
        draw_set_alpha(_pulse * 0.8);
        draw_line_width(_gpcx - (13 * _scale), _gpcy, _gpcx - (5 * _scale), _gpcy, max(1, _scale));
        draw_line_width(_gpcx + (5 * _scale), _gpcy, _gpcx + (13 * _scale), _gpcy, max(1, _scale));
        draw_line_width(_gpcx, _gpcy - (13 * _scale), _gpcx, _gpcy - (5 * _scale), max(1, _scale));
        draw_line_width(_gpcx, _gpcy + (5 * _scale), _gpcx, _gpcy + (13 * _scale), max(1, _scale));
        draw_set_alpha(1.0);
    }
}

// --- Core Placement Hologram ---
if (global.gameMode == "PLANET" || global.gameMode == "STORY") {
    var _cx_core = floor(global.COLS / 2);
    var _cy_core = global.HIDDEN_ROWS + floor(global.ROWS / 2);
    
    // Only show hologram if NO core exists anywhere on the board
    var _hasCore = false;
    with(obj_block) if (type == "core") _hasCore = true;
    
    if (!_hasCore) {
        var _cpx = _bx + (_cx_core * 16 * _scale) + (8 * _scale);
        var _cpy = _by + ((_cy_core - global.HIDDEN_ROWS) * 16 * _scale) + (8 * _scale);
        var _hPulse = 0.15 + (abs(sin(current_time * 0.003)) * 0.1);
        var _hCol = (global.activePiece != undefined) ? global.activePiece.color : c_white;
        draw_sprite_ext(spr_pinkSprite, 0, _cpx, _cpy, _scale, _scale, 0, _hCol, _hPulse);
    }
}


// --- Draw Orbital Lanes (Planet Mode) ---
if (global.gameMode == "PLANET" || global.gameMode == "STORY") {
    var _cx = floor(global.COLS / 2);
    var _cy = global.HIDDEN_ROWS + floor(global.ROWS / 2);
    
    for (var _gy = global.HIDDEN_ROWS; _gy < global.TOTAL_ROWS; _gy++) {
        for (var _gx = 0; _gx < global.COLS; _gx++) {
            var _dx = abs(_gx - _cx);
            var _dy = abs(_gy - _cy);
            var _dist = max(_dx, _dy);
            
            if (_dist > 0) {
                var _tx = _bx + (_gx * 16 * _scale);
                var _ty = _by + ((_gy - global.HIDDEN_ROWS) * 16 * _scale);
                var _tw = 16 * _scale;
                
                // --- RING FULLNESS CHECK (Atmosphere Glow) ---
                var _rocks = 0;
                var _total = 0;
                for (var _ry = global.HIDDEN_ROWS; _ry < global.TOTAL_ROWS; _ry++) {
                    for (var _rx = 0; _rx < global.COLS; _rx++) {
                        if (max(abs(_rx-_cx), abs(_ry-_cy)) == _dist) {
                            _total++;
                            if (global.grid[_ry][_rx] != undefined && global.grid[_ry][_rx].type == "dead") _rocks++;
                        }
                    }
                }
            if (_dist > 0) {
                var _tx = _bx + (_gx * 16 * _scale);
                var _ty = _by + ((_gy - global.HIDDEN_ROWS) * 16 * _scale);
                var _tw = 16 * _scale;
                
                // Simplified Cosmic Tints for Rings
                var _color = make_color_rgb(10, 5, 20); 
                if (_dist == 1) _color = make_color_rgb(30, 10, 50);
                if (_dist == 2) _color = make_color_rgb(20, 5, 30);
                if (_dist == 3) _color = make_color_rgb(10, 2, 15);
                
                draw_set_alpha(0.5);
                draw_set_color(_color);
                draw_rectangle(_tx, _ty, _tx + _tw, _ty + _tw, false);
                
                // Lane Borders (Ultra-Faint)
                draw_set_alpha(0.05);
                draw_set_color(c_white);
                draw_rectangle(_tx, _ty, _tx + _tw, _ty + _tw, true);
                draw_set_alpha(1.0);
            }
            }
        }
    }
}


with(obj_block) {
    var _drawX = _bx + (x * _scale);
    var _drawY = _by + (y * _scale);
    
    // --- PARTIAL RING PRESSURE (Tightening blocks) ---
    var _myDist = max(abs(grid_x - floor(global.COLS / 2)), abs(grid_y - (global.HIDDEN_ROWS + floor(global.ROWS / 2))));
    var _myTighten = 1.0;
    if ((global.gameMode == "PLANET" || global.gameMode == "STORY") && _myDist > 0) {
        // We could calculate fullness here, but for now just check if the piece is in a pulsed ring
        // (Simplified: check current_time pulse if dist matches)
        // ...actually let's just use the global scale for blocks
    }

    var _cx = _drawX + (8 * _scale);
    var _cy = _drawY + (8 * _scale);
    // Clip hidden-row blocks, but let the active piece show in the staging ring above the board
    if (_cy < _by && id != global.activePiece) continue;
    
    // Dynamic Rotation: Stay upright on monitor + manual player spin
    var _renderRot = -global.boardRotation + visualRotation;
    
    if (sprite_index != -1) {
        draw_sprite_ext(sprite_index, image_index, _cx, _cy, _scale * scale_x, _scale * scale_y, _renderRot, c_white, image_alpha);
    }
    
    if (id == global.activePiece) {
        var _activePulse = 0.45 + abs(sin(current_time * 0.01)) * 0.35;
        gpu_set_blendmode(bm_add);
        draw_set_alpha(_activePulse);
        draw_set_color(c_white);
        draw_rectangle(_cx - (10 * _scale), _cy - (10 * _scale), _cx + (10 * _scale), _cy + (10 * _scale), true);
        draw_set_color(color);
        draw_rectangle(_cx - (12 * _scale), _cy - (12 * _scale), _cx + (12 * _scale), _cy + (12 * _scale), true);
        gpu_set_blendmode(bm_normal);
        draw_set_alpha(1);
    }
    
    if (type == "core") {
        gpu_set_blendmode(bm_add);
        var _corePulse = 0.3 + abs(sin(current_time * 0.005)) * 0.4;
        // Outer Glow
        draw_sprite_ext(sprite_index, image_index, _cx, _cy, _scale * scale_x * 1.4, _scale * scale_y * 1.4, _renderRot, c_white, _corePulse * 0.5);
        gpu_set_blendmode(bm_normal);
        
        // Pulsing Target Border
        draw_set_color(c_white);
        draw_set_alpha(_corePulse + 0.2);
        draw_rectangle(_cx - (9 * _scale), _cy - (9 * _scale), _cx + (9 * _scale), _cy + (9 * _scale), true);
        draw_rectangle(_cx - (10 * _scale), _cy - (10 * _scale), _cx + (10 * _scale), _cy + (10 * _scale), true);
        draw_set_alpha(1.0);
    }
    
    if (type == "metal") {
        var _arrowSpr = (dir == 0) ? spr_lr_arrows : spr_ud_arrows;
        // Arrows are planet-locked. The surface matrix rotates them with the board,
        // so the preview and real block communicate the same gameplay direction.
        draw_sprite_ext(_arrowSpr, 0, _cx, _cy, _scale * scale_x, _scale * scale_y, 0, c_white, image_alpha);
    }
    
        // --- PIECE TIMER & CHARGE BARS (Billboarded to stay horizontal) ---
    if ((global.gameMode == "PLANET" || global.gameMode == "STORY") && id == global.activePiece) {
        var _bw = 14 * _scale;
        var _bh = 2 * _scale;
        
        // Push Matrix to counter-rotate bars
        var _barM = matrix_build(_cx, _cy, 0, 0, 0, -global.boardRotation, 1, 1, 1);
        matrix_stack_push(_barM);
        matrix_set(matrix_world, matrix_stack_top());
        
        var _tx = -(_bw/2);
        var _ty = -(14 * _scale); 
        
        // Timer Bar (Top)
        var _pct = global.pieceTimer / global.MAX_PIECE_TIME;
        var _tColor = merge_color(c_red, c_lime, _pct);
        draw_set_color(c_black);
        draw_rectangle(_tx - 1, _ty - 1, _tx + _bw + 1, _ty + _bh + 1, false);
        draw_set_color(_tColor);
        draw_rectangle(_tx, _ty, _tx + (_bw * _pct), _ty + _bh, false);
        
        // Charge Bar (Bottom)
        var _cTy = _ty + 3 * _scale;
        var _cPct = global.launchCharge / global.MAX_CHARGE;
        draw_set_color(c_black);
        draw_rectangle(_tx - 1, _cTy - 1, _tx + _bw + 1, _cTy + _bh + 1, false);
        draw_set_color(merge_color(c_navy, c_aqua, _cPct));
        draw_rectangle(_tx, _cTy, _tx + (_bw * _cPct), _cTy + _bh, false);
        
        if (global.launchCharge >= global.MAX_CHARGE) {
             draw_set_alpha(abs(sin(current_time * 0.02)));
             draw_set_color(c_white);
             draw_rectangle(_tx, _cTy, _tx + _bw, _cTy + _bh, false);
             draw_set_alpha(1.0);
        }
        
        // Reset Matrix
        matrix_stack_pop();
        matrix_set(matrix_world, matrix_stack_top());
    }
}

// --- Draw Beams & Impacts ---
for (var i = 0; i < array_length(global.beams); i++) {
    var _b = global.beams[i];
    var _alpha = _b.life / _b.maxLife;
    draw_set_alpha(_alpha);
    draw_set_color(_b.color);
    if (_b.type == "impact") {
        var _growth = (1 - _alpha) * 32; 
        draw_rectangle(_bx + _b.x - _growth, _by + _b.y - 1, _bx + _b.x + _b.w + _growth, _by + _b.y + 1, false);
    } else {
        // Correct beam positioning for (8,8) origin logic
        draw_rectangle(_bx + (_b.x * _scale), _by + (_b.y * _scale), _bx + (_b.x + 16) * _scale, _by + (_b.y + _b.h) * _scale, false);
    }
}

// --- Draw Particles ---
for (var i = 0; i < array_length(global.particles); i++) {
    var _p = global.particles[i];
    draw_set_alpha(_p.life / 30);
    draw_set_color(_p.color);
    draw_rectangle(_bx + (_p.x * _scale) - 2, _by + (_p.y * _scale) - 2, _bx + (_p.x * _scale) + 2, _by + (_p.y * _scale) + 2, false);
}

draw_set_alpha(1.0);

// --- Jackpot Flash ---
if (global.jackpotFlash > 0) {
    draw_set_alpha((global.jackpotFlash / 45) * 0.75);
    draw_set_color(c_yellow);
    draw_rectangle(0, 0, global.GAME_W, global.GAME_H, false);
    draw_set_alpha(1.0);
}

surface_reset_target();

// --- Draw the Upscaled Surface (with Galaxy Rotation Matrix) ---
gpu_set_texfilter(false);

var _m = matrix_build(global.GAME_W/2, global.GAME_H/2, 0, 0, 0, global.boardRotation, 1, 1, 1);
var _old_m = matrix_get(matrix_world);
matrix_set(matrix_world, _m);

// Draw surface relative to its center pivot
draw_surface(global.game_surface, -global.GAME_W/2, -global.GAME_H/2);

// Restore matrix
matrix_set(matrix_world, _old_m);
gpu_set_texfilter(true);
