// =============================================================================
// obj_game_manager — Draw GUI Event
// =============================================================================

// --- Surface setup ---
if (!surface_exists(global.game_surface)) {
    global.game_surface = surface_create(global.GAME_W, global.GAME_H);
}
if (global.shakeAmount > 0) {
    global.shakeAmount *= 0.9;
    if (global.shakeAmount < 0.1) global.shakeAmount = 0;
}
gpu_set_texfilter(false);
surface_set_target(global.game_surface);
draw_clear_alpha(c_black, 0);

var _shakeX = random_range(-global.shakeAmount, global.shakeAmount);
var _shakeY = random_range(-global.shakeAmount, global.shakeAmount);

// Cache common values
var _centerGX = floor(global.TOTAL_COLS / 2);
var _centerGY = floor(global.TOTAL_ROWS / 2);
var _scale    = global.PIXEL_SCALE;
var _bw       = global.COLS * 16 * _scale;
var _bh       = global.ROWS * 16 * _scale;
var _cw       = 16 * _scale; 

// --- Background ---
draw_rectangle_color(0, 0, global.GAME_W, global.GAME_H,
    global.bg_colors[0], global.bg_colors[1], global.bg_colors[2], global.bg_colors[1], false);

var _isFever = (global.feverTimer > 0);
for (var i = 0; i < array_length(global.bg_stars); i++) {
    var _s = global.bg_stars[i];
    draw_set_alpha(_isFever ? 0.8 : (_s.spd * 2));
    draw_set_color(c_white);
    if (_isFever) draw_line_width(_s.x, _s.y, _s.x, _s.y - 40, _s.size);
    else draw_rectangle(_s.x, _s.y, _s.x + _s.size, _s.y + _s.size, false);
}
draw_set_alpha(1.0);

// --- Board Matrix Setup ---
var _matRot = matrix_build(global.GAME_W/2, global.GAME_H/2, 0, 0, 0, global.boardRotation, 1, 1, 1);
matrix_stack_push(_matRot);
matrix_set(matrix_world, matrix_stack_top());

var _bx = -_bw / 2 + _shakeX;
var _by = -_bh / 2 + _shakeY;

// --- Staging Ring (Planet/Story) ---
if (global.gameMode == "PLANET" || global.gameMode == "STORY") {
    var _ap_gx    = (global.activePiece != undefined) ? global.activePiece.grid_x : -999;
    var _ap_gy    = (global.activePiece != undefined) ? global.activePiece.grid_y : -999;
    var _ringPulse = 0.18 + abs(sin(current_time * 0.007)) * 0.22;
    var _apColor  = (global.activePiece != undefined) ? global.activePiece.color : c_white;

    for (var _ri = 0; _ri < array_length(global.stagingRingCells); _ri++) {
        var _sx    = global.stagingRingCells[_ri].sx;
        var _sy    = global.stagingRingCells[_ri].sy;
        var _stx   = _bx + (_sx - global.HIDDEN_SIDES) * _cw;
        var _sty   = _by + (_sy - global.HIDDEN_ROWS)  * _cw;
        var _isAct = (_sx == _ap_gx && _sy == _ap_gy);
        draw_set_alpha(_isAct ? 0.55 : 0.25);
        draw_set_color(_isAct ? _apColor : make_color_rgb(50, 30, 80));
        draw_rectangle(_stx, _sty, _stx + _cw, _sty + _cw, false);
        draw_set_alpha(_isAct ? 0.9 : 0.35);
        draw_set_color(_isAct ? _apColor : make_color_rgb(110, 60, 160));
        draw_rectangle(_stx, _sty, _stx + _cw, _sty + _cw, true);
        if (_isAct) {
            gpu_set_blendmode(bm_add);
            draw_set_alpha(_ringPulse * 0.7);
            draw_set_color(_apColor);
            draw_rectangle(_stx - 2, _sty - 2, _stx + _cw + 2, _sty + _cw + 2, false);
            gpu_set_blendmode(bm_normal);
        }
    }
}

// --- Board Backdrop & Grid ---
draw_set_alpha(0.85); draw_set_color(make_color_rgb(15, 15, 25));
draw_roundrect_ext(_bx - 12, _by - 12, _bx + _bw + 12, _by + _bh + 12, 20, 20, false);
draw_set_alpha(0.07); draw_set_color(c_white);
for (var i = 0; i <= global.COLS; i++) draw_line(_bx + i * _cw, _by, _bx + i * _cw, _by + _bh);
for (var i = 0; i <= global.ROWS; i++) draw_line(_bx, _by + i * _cw, _bx + _bw, _by + i * _cw);
draw_set_alpha(1.0); draw_set_color((global.feverTimer > 0) ? c_yellow : global.COLOR_ACCENT);
draw_roundrect_ext(_bx - 12, _by - 12, _bx + _bw + 12, _by + _bh + 12, 20, 20, true);

// --- Lane Tints & Danger Ring ---
if (global.gameMode == "PLANET" || global.gameMode == "STORY") {
    for (var _gy3 = global.HIDDEN_ROWS; _gy3 < global.TOTAL_ROWS - global.HIDDEN_ROWS; _gy3++) {
        for (var _gx3 = global.HIDDEN_SIDES; _gx3 < global.TOTAL_COLS - global.HIDDEN_SIDES; _gx3++) {
            var _dist = max(abs(_gx3 - _centerGX), abs(_gy3 - _centerGY));
            if (_dist == 0) continue;
            var _tx = _bx + (_gx3 - global.HIDDEN_SIDES) * _cw;
            var _ty = _by + (_gy3 - global.HIDDEN_ROWS)  * _cw;
            var _col = make_color_rgb(10, 5, 20);
            if (_dist == 1) _col = make_color_rgb(30, 10, 50);
            if (_dist == 2) _col = make_color_rgb(20, 5, 30);
            if (_dist == 3) _col = make_color_rgb(10, 2, 15);
            if (_dist == 4) _col = make_color_rgb(45, 8, 8);
            draw_set_alpha(0.5); draw_set_color(_col);
            draw_rectangle(_tx, _ty, _tx + _cw, _ty + _cw, false);
            draw_set_alpha(0.05); draw_set_color(c_white);
            draw_rectangle(_tx, _ty, _tx + _cw, _ty + _cw, true);
        }
    }
    var _dangerPulse = 0.08 + abs(sin(current_time * 0.004)) * 0.12;
    gpu_set_blendmode(bm_add);
    for (var _gy4b = global.HIDDEN_ROWS; _gy4b < global.TOTAL_ROWS - global.HIDDEN_ROWS; _gy4b++) {
        for (var _gx4b = global.HIDDEN_SIDES; _gx4b < global.TOTAL_COLS - global.HIDDEN_SIDES; _gx4b++) {
            if (max(abs(_gx4b - _centerGX), abs(_gy4b - _centerGY)) != 4) continue;
            var _tx2 = _bx + (_gx4b - global.HIDDEN_SIDES) * _cw;
            var _ty2 = _by + (_gy4b - global.HIDDEN_ROWS)  * _cw;
            draw_set_alpha(_dangerPulse); draw_set_color(global.COLOR_DANGER);
            draw_rectangle(_tx2, _ty2, _tx2 + _cw, _ty2 + _cw, true);
        }
    }
    gpu_set_blendmode(bm_normal);
}

// --- Ghost Piece & Trajectory ---
if (global.gameState == "PLAYING" && global.activePiece != undefined && global.settings.ghostEnabled) {
    var _ap  = global.activePiece;
    var _gx4 = _ap.grid_x; var _gy4 = _ap.grid_y;
    
    // Ghost target cell — read from the cached path, clamped to previewDepth
    if (global.previewData != undefined) {
        var _path = global.previewData.path;
        var _pathLen = array_length(_path);
        var _clampedDepth = clamp(global.previewDepth, 0, _pathLen) - 1;
        if (_clampedDepth >= 0 && _pathLen > 0) {
            _gx4 = _path[_clampedDepth].gx;
            _gy4 = _path[_clampedDepth].gy;
        }
    }

    var _gpcx  = _bx + (_gx4 - global.HIDDEN_SIDES) * _cw + 8 * _scale;
    var _gpcy  = _by + (_gy4 - global.HIDDEN_ROWS)  * _cw + 8 * _scale;
    var _apcx  = _bx + (_ap.grid_x - global.HIDDEN_SIDES) * _cw + 8 * _scale;
    var _apcy  = _by + (_ap.grid_y - global.HIDDEN_ROWS)  * _cw + 8 * _scale;
    var _pulse = 0.22 + abs(sin(current_time * 0.008)) * 0.22;

    if (_gx4 != _ap.grid_x || _gy4 != _ap.grid_y) {
        // ── Full-lane sight highlight ──────────────────────────────────────────
        // Draw a faint glow along the ENTIRE drop lane (spoke) from the active
        // piece's ring cell all the way to the landing cell, like a targeting sight.
        if ((global.gameMode == "PLANET" || global.gameMode == "STORY") && global.previewData != undefined) {
            var _s4 = ((global.orbitalSide % 4) + 4) % 4;
            gpu_set_blendmode(bm_add);
            // Full lane: from piece down to landing, every playable cell in the lane
            var _lx = _ap.grid_x; var _ly = _ap.grid_y;
            var _lddx = 0; var _lddy = 0;
            if (_s4 == 0) _lddy =  1;
            if (_s4 == 1) _lddx = -1;
            if (_s4 == 2) _lddy = -1;
            if (_s4 == 3) _lddx =  1;
            var _laneStep = 0;
            var _laneMax  = global.previewData.depth;
            while (_laneStep < _laneMax) {
                _lx += _lddx; _ly += _lddy;
                if (_lx < global.HIDDEN_SIDES || _lx >= global.TOTAL_COLS - global.HIDDEN_SIDES
                || _ly < global.HIDDEN_ROWS  || _ly >= global.TOTAL_ROWS  - global.HIDDEN_ROWS) break;
                var _fade = (_laneStep + 1) / max(1, _laneMax);
                draw_set_alpha((0.04 + 0.18 * _fade) * _pulse * 3);
                draw_set_color(_ap.color);
                var _lsx = _bx + (_lx - global.HIDDEN_SIDES) * _cw;
                var _lsy = _by + (_ly - global.HIDDEN_ROWS)  * _cw;
                draw_rectangle(_lsx, _lsy, _lsx + _cw, _lsy + _cw, false);
                _laneStep++;
            }
            gpu_set_blendmode(bm_normal);
        }
        // Laser & Ghost
        gpu_set_blendmode(bm_add);
        draw_set_alpha(0.30 + _pulse); draw_set_color(_ap.color);
        draw_line_width(_apcx, _apcy, _gpcx, _gpcy, max(2, 2 * _scale));
        draw_set_alpha(0.75); draw_set_color(c_white);
        draw_line_width(_apcx, _apcy, _gpcx, _gpcy, max(1, _scale));
        gpu_set_blendmode(bm_normal);
        
        draw_set_alpha(_pulse);
        draw_block_instance(_ap, _bx, _by, _scale, _pulse, _gpcx, _gpcy);
        
        // Target cross
        draw_set_alpha(0.85); draw_set_color(_ap.color);
        draw_rectangle(_gpcx - 10*_scale, _gpcy - 10*_scale, _gpcx + 10*_scale, _gpcy + 10*_scale, true);
        draw_set_alpha(_pulse * 0.8); draw_set_color(c_white);
        draw_line_width(_gpcx - 13*_scale, _gpcy, _gpcx - 5*_scale, _gpcy, max(1,_scale));
        draw_line_width(_gpcx + 5*_scale,  _gpcy, _gpcx + 13*_scale, _gpcy, max(1,_scale));
        draw_line_width(_gpcx, _gpcy - 13*_scale, _gpcx, _gpcy - 5*_scale, max(1,_scale));
        draw_line_width(_gpcx, _gpcy + 5*_scale,  _gpcx, _gpcy + 13*_scale, max(1,_scale));
        draw_set_alpha(1.0);
    }
}

// --- Core Hologram ---
if ((global.gameMode == "PLANET" || global.gameMode == "STORY") && !instance_exists(obj_block) && global.activePiece != undefined) {
    var _cpx = _bx + (_centerGX - global.HIDDEN_SIDES) * _cw + 8 * _scale;
    var _cpy = _by + (_centerGY - global.HIDDEN_ROWS)  * _cw + 8 * _scale;
    draw_sprite_ext(spr_pinkSprite, 0, _cpx, _cpy, _scale, _scale, 0, global.activePiece.color, 0.15 + abs(sin(current_time * 0.003)) * 0.1);
}

// --- Blocks Rendering ---
with (obj_block) {
    var _cx5 = _bx + (x * _scale) + 8 * _scale;
    var _cy5 = _by + (y * _scale) + 8 * _scale;
    // Allow drawing blocks in the staging rows/columns too
    if (_cy5 < _by - 16 * _scale && id != global.activePiece) continue;

    other.draw_block_instance(id, _bx, _by, _scale);

    // Active Highlight
    if (id == global.activePiece) {
        var _ap2 = 0.45 + abs(sin(current_time * 0.01)) * 0.35;
        gpu_set_blendmode(bm_add);
        draw_set_alpha(_ap2); draw_set_color(c_white);
        draw_rectangle(_cx5 - 10*_scale, _cy5 - 10*_scale, _cx5 + 10*_scale, _cy5 + 10*_scale, true);
        draw_set_color(color);
        draw_rectangle(_cx5 - 12*_scale, _cy5 - 12*_scale, _cx5 + 12*_scale, _cy5 + 12*_scale, true);
        gpu_set_blendmode(bm_normal);
        draw_set_alpha(1);
    }

    // Active Piece HUD (Upright Billboard)
    if ((global.gameMode == "PLANET" || global.gameMode == "STORY") && id == global.activePiece) {
        var _barW = 14 * _scale; var _barH = 2 * _scale;
        var _barM = matrix_build(_cx5, _cy5, 0, 0, 0, -global.boardRotation, 1, 1, 1);
        matrix_stack_push(_barM);
        matrix_set(matrix_world, matrix_stack_top());
        var _bxb = -(_barW/2); var _byb = -(14 * _scale);
        var _pct = global.pieceTimer / global.MAX_PIECE_TIME;
        draw_set_color(c_black); draw_rectangle(_bxb-1, _byb-1, _bxb+_barW+1, _byb+_barH+1, false);
        draw_set_color(merge_color(c_red, c_lime, _pct)); draw_rectangle(_bxb, _byb, _bxb + _barW * _pct, _byb + _barH, false);
        var _cBy = _byb + 3*_scale; var _cPct = global.launchCharge / global.MAX_CHARGE;
        draw_set_color(c_black); draw_rectangle(_bxb-1, _cBy-1, _bxb+_barW+1, _cBy+_barH+1, false);
        draw_set_color(merge_color(c_navy, c_aqua, _cPct)); draw_rectangle(_bxb, _cBy, _bxb + _barW * _cPct, _cBy + _barH, false);
        if (global.launchCharge >= global.MAX_CHARGE) {
            draw_set_alpha(abs(sin(current_time * 0.02))); draw_set_color(c_white);
            draw_rectangle(_bxb, _cBy, _bxb + _barW, _cBy + _barH, false); draw_set_alpha(1.0);
        }
        matrix_stack_pop();
        matrix_set(matrix_world, matrix_stack_top());
    }
}

// --- Effects & Particles ---
for (var i = 0; i < array_length(global.beams); i++) {
    var _b = global.beams[i]; var _ba = _b.life / _b.maxLife;
    draw_set_alpha(_ba); draw_set_color(_b.color);
    if (_b.type == "impact") draw_rectangle(_bx + _b.x - (1-_ba)*32, _by + _b.y - 1, _bx + _b.x + _b.w + (1-_ba)*32, _by + _b.y + 1, false);
    else draw_rectangle(_bx + _b.x*_scale, _by + _b.y*_scale, _bx + (_b.x+16)*_scale, _by + (_b.y+_b.h)*_scale, false);
}
for (var i = 0; i < array_length(global.particles); i++) {
    var _p2 = global.particles[i]; draw_set_alpha(_p2.life / 30); draw_set_color(_p2.color);
    draw_rectangle(_bx + _p2.x*_scale - 2, _by + _p2.y*_scale - 2, _bx + _p2.x*_scale + 2, _by + _p2.y*_scale + 2, false);
}

// --- Composite to Screen ---
matrix_stack_pop();
matrix_set(matrix_world, matrix_build(0,0,0,0,0,0,1,1,1));

for (var i = 0; i < array_length(global.floatingTexts); i++) {
    var _ft = global.floatingTexts[i]; draw_set_alpha(_ft.life / 90); draw_set_color(_ft.color);
    draw_set_font(main_font); draw_set_halign(fa_center); draw_text_transformed(_ft.x, _ft.y, _ft.text, _ft.scale, _ft.scale, 0);
}

if (global.gameState == "GAMEOVER") {
    draw_set_alpha(0.6); draw_set_color(c_black); draw_rectangle(0, 0, global.GAME_W, global.GAME_H, false);
    draw_set_alpha(1); draw_set_font(main_font); draw_set_halign(fa_center);
    draw_set_color(global.storyComplete ? c_yellow : c_white);
    draw_text_transformed(global.GAME_W/2, global.GAME_H*0.38, global.storyComplete ? "STORY COMPLETE!" : "GAME OVER", 2.5, 2.5, 0);
    draw_set_color(make_color_rgb(180,180,200));
    draw_text_transformed(global.GAME_W/2, global.GAME_H*0.52, "Score: " + string(global.score), 1.3, 1.3, 0);
    draw_text_transformed(global.GAME_W/2, global.GAME_H*0.60, "Best: "  + string(global.highScore), 1.1, 1.1, 0);
    draw_set_color(make_color_rgb(255,214,102));
    draw_text_transformed(global.GAME_W/2, global.GAME_H*0.72, "R  Retry     Esc  Menu", 1.0, 1.0, 0);
}

surface_reset_target();
draw_surface_ext(global.game_surface, 0, 0, 1, 1, 0, c_white, 1);
draw_set_halign(fa_left); draw_set_valign(fa_top); draw_set_alpha(1.0);
