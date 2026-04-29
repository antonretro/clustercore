// =============================================================================
// obj_game_manager — Draw GUI Event
//
// Coordinate system:
//   _bx, _by  = top-left corner of the PLAYABLE board on screen
//   Block screen x = _bx + (grid_x - HIDDEN_SIDES) * 16 * scale
//   Block screen y = _by + (grid_y - HIDDEN_ROWS)  * 16 * scale
//   Staging ring cells appear at negative or > COLS offsets (outside board)
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

// Background gradient
draw_rectangle_color(0, 0, global.GAME_W, global.GAME_H,
    global.bg_colors[0], global.bg_colors[1], global.bg_colors[2], global.bg_colors[1], false);

// Stars
var _isFever = (global.feverTimer > 0);
for (var i = 0; i < array_length(global.bg_stars); i++) {
    var _s = global.bg_stars[i];
    draw_set_alpha(_isFever ? 0.8 : (_s.spd * 2));
    draw_set_color(c_white);
    if (_isFever) draw_line_width(_s.x, _s.y, _s.x, _s.y - 40, _s.size);
    else draw_rectangle(_s.x, _s.y, _s.x + _s.size, _s.y + _s.size, false);
}
draw_set_alpha(1.0);

// --- Board geometry (playable 9x9 or 10x20, centred on screen) ---
var _scale = global.PIXEL_SCALE;
var _bw    = global.COLS * 16 * _scale;
var _bh    = global.ROWS * 16 * _scale;
var _bx    = (global.GAME_W - _bw) / 2 + _shakeX;
var _by    = (global.GAME_H - _bh) / 2 + _shakeY;
var _cw    = 16 * _scale; // one cell width in pixels

// --- Apply board rotation matrix (rotates staging ring, backdrop, grid, lane tints, blocks, and effects together) ---
// We rotate AROUND the center of the screen, but keep the origin at (0,0) so the existing _bx/_by math works.
var _cx = global.GAME_W / 2;
var _cy = global.GAME_H / 2;
var _matT1 = matrix_build(-_cx, -_cy, 0, 0, 0, 0, 1, 1, 1);
var _matR  = matrix_build(0, 0, 0, 0, 0, global.boardRotation, 1, 1, 1);
var _matT2 = matrix_build(_cx, _cy, 0, 0, 0, 0, 1, 1, 1);
var _matFinal = matrix_multiply(_matT2, matrix_multiply(_matR, _matT1));

matrix_stack_push(_matFinal);
matrix_set(matrix_world, matrix_stack_top());

// --- Planet staging ring (outer ring of 11x11, drawn outside board bounds) ---
if (global.gameMode == "PLANET" || global.gameMode == "STORY") {
    var _ap_gx    = (global.activePiece != undefined) ? global.activePiece.grid_x : -999;
    var _ap_gy    = (global.activePiece != undefined) ? global.activePiece.grid_y : -999;
    var _ringPulse = 0.18 + abs(sin(current_time * 0.007)) * 0.22;
    var _apColor  = (global.activePiece != undefined) ? global.activePiece.color : c_white;

    // Build flat list of all 4 staging sides, draw inline (no lambda — GML closures can't capture locals)
    var _ring = [];
    for (var _i = 1; _i <= global.COLS; _i++)  array_push(_ring, {sx: _i,                   sy: 0});
    for (var _i = 1; _i <= global.ROWS; _i++)  array_push(_ring, {sx: global.TOTAL_COLS-1,  sy: _i});
    for (var _i = global.COLS; _i >= 1; _i--)  array_push(_ring, {sx: _i,                   sy: global.TOTAL_ROWS-1});
    for (var _i = global.ROWS; _i >= 1; _i--)  array_push(_ring, {sx: 0,                    sy: _i});

    for (var _ri = 0; _ri < array_length(_ring); _ri++) {
        var _sx    = _ring[_ri].sx;
        var _sy    = _ring[_ri].sy;
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
    draw_set_alpha(1.0);
}


// --- Board backdrop ---
draw_set_alpha(0.85);
draw_set_color(make_color_rgb(15, 15, 25));
draw_roundrect_ext(_bx - 12, _by - 12, _bx + _bw + 12, _by + _bh + 12, 20, 20, false);
draw_set_alpha(1.0);

// --- Board grid lines ---
draw_set_alpha(0.07);
draw_set_color(c_white);
for (var i = 0; i <= global.COLS; i++) draw_line(_bx + i * _cw, _by, _bx + i * _cw, _by + _bh);
for (var i = 0; i <= global.ROWS; i++) draw_line(_bx, _by + i * _cw, _bx + _bw, _by + i * _cw);
draw_set_alpha(1.0);

// --- Board border ---
draw_set_color((global.feverTimer > 0) ? c_yellow : global.COLOR_ACCENT);
draw_roundrect_ext(_bx - 12, _by - 12, _bx + _bw + 12, _by + _bh + 12, 20, 20, true);

// --- Orbital lane tints (Planet) ---
if (global.gameMode == "PLANET" || global.gameMode == "STORY") {
    for (var _gy3 = global.HIDDEN_ROWS; _gy3 < global.TOTAL_ROWS - global.HIDDEN_SIDES; _gy3++) {
        for (var _gx3 = global.HIDDEN_SIDES; _gx3 < global.TOTAL_COLS - global.HIDDEN_SIDES; _gx3++) {
            var _dist = max(abs(_gx3 - floor(global.TOTAL_COLS / 2)), abs(_gy3 - floor(global.TOTAL_ROWS / 2)));
            if (_dist == 0) continue;
            var _tx = _bx + (_gx3 - global.HIDDEN_SIDES) * _cw;
            var _ty = _by + (_gy3 - global.HIDDEN_ROWS)  * _cw;
            var _col = make_color_rgb(10, 5, 20);
            if (_dist == 1) _col = make_color_rgb(30, 10, 50);
            if (_dist == 2) _col = make_color_rgb(20, 5, 30);
            if (_dist == 3) _col = make_color_rgb(10, 2, 15);
            draw_set_alpha(0.5); draw_set_color(_col);
            draw_rectangle(_tx, _ty, _tx + _cw, _ty + _cw, false);
            draw_set_alpha(0.05); draw_set_color(c_white);
            draw_rectangle(_tx, _ty, _tx + _cw, _ty + _cw, true);
        }
    }
    draw_set_alpha(1.0);
}

// --- Ghost Piece & Laser ---
if (global.gameState == "PLAYING" && global.activePiece != undefined && global.settings.ghostEnabled) {
    var _ap  = global.activePiece;
    var _gx4 = _ap.grid_x;
    var _gy4 = _ap.grid_y;

    // ── PLANET ghost: trace radial path ──────────────────────────────────────
    if (global.gameMode == "PLANET" || global.gameMode == "STORY") {
        var _tx4 = _gx4; var _ty4 = _gy4;
        var _isHeavy = (global.launchCharge >= global.MAX_CHARGE);
        for (var i = 0; i < global.previewDepth; i++) {
            var _ddx = sign(floor(global.TOTAL_COLS / 2) - _tx4);
            var _ddy = sign(floor(global.TOTAL_ROWS / 2) - _ty4);
            if (_ddx == 0 && _ddy == 0) break;
            if (abs(floor(global.TOTAL_COLS / 2) - _tx4) >= abs(floor(global.TOTAL_ROWS / 2) - _ty4)) _ddy = 0; else _ddx = 0;
            var _nx4 = _tx4 + _ddx; var _ny4 = _ty4 + _ddy;
            if (_nx4 < 0 || _nx4 >= global.TOTAL_COLS || _ny4 < 0 || _ny4 >= global.TOTAL_ROWS) break;
            if (global.grid[_ny4][_nx4] != undefined) {
                if (_isHeavy) {
                    var _hx4 = _nx4 + _ddx; var _hy4 = _ny4 + _ddy;
                    if (_hx4 >= 0 && _hx4 < global.TOTAL_COLS && _hy4 >= 0 && _hy4 < global.TOTAL_ROWS
                    && global.grid[_hy4][_hx4] == undefined) {
                        _isHeavy = false; _tx4 = _nx4; _ty4 = _ny4; continue;
                    }
                }
                break;
            }
            _tx4 = _nx4; _ty4 = _ny4;
        }
        _gx4 = _tx4; _gy4 = _ty4;

    // ── CLASSIC ghost: fall straight down ────────────────────────────────────
    } else {
        while (_gy4 < global.TOTAL_ROWS - 1) {
            if (global.grid[_gy4 + 1][_gx4] != undefined) break;
            _gy4++;
        }
    }

    // Screen positions (both use the same offset formula)
    var _gpcx  = _bx + (_gx4 - global.HIDDEN_SIDES) * _cw + 8 * _scale;
    var _gpcy  = _by + (_gy4 - global.HIDDEN_ROWS)  * _cw + 8 * _scale;
    var _apcx  = _bx + (_ap.grid_x - global.HIDDEN_SIDES) * _cw + 8 * _scale;
    var _apcy  = _by + (_ap.grid_y - global.HIDDEN_ROWS)  * _cw + 8 * _scale;
    var _same  = (_gx4 == _ap.grid_x && _gy4 == _ap.grid_y);
    var _gRot  = -global.boardRotation + _ap.visualRotation;
    var _pulse = 0.22 + abs(sin(current_time * 0.008)) * 0.22;

    if (!_same) {
        // Laser
        gpu_set_blendmode(bm_add);
        draw_set_alpha(0.30 + _pulse); draw_set_color(_ap.color);
        draw_line_width(_apcx, _apcy, _gpcx, _gpcy, max(2, 2 * _scale));
        draw_set_alpha(0.75); draw_set_color(c_white);
        draw_line_width(_apcx, _apcy, _gpcx, _gpcy, max(1, _scale));
        gpu_set_blendmode(bm_normal);
        // Ghost sprite
        draw_set_alpha(_pulse);
        draw_sprite_ext(_ap.sprite_index, 0, _gpcx, _gpcy, _scale, _scale, _gRot, c_white, _pulse);
        if (_ap.type == "metal") {
            var _arrowSpr = (_ap.dir == 0) ? spr_lr_arrows : spr_ud_arrows;
            draw_sprite_ext(_arrowSpr, 0, _gpcx, _gpcy, _scale, _scale, 0, c_white, _pulse);
        }
        // Targeting cross
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

// --- Core placement hologram (Planet, before first core established) ---
if (global.gameMode == "PLANET" || global.gameMode == "STORY") {
    var _hasCore = false;
    with (obj_block) if (type == "core") { _hasCore = true; break; }
    if (!_hasCore) {
        var _cpx = _bx + (floor(global.TOTAL_COLS / 2) - global.HIDDEN_SIDES) * _cw + 8 * _scale;
        var _cpy = _by + (floor(global.TOTAL_ROWS / 2) - global.HIDDEN_ROWS)  * _cw + 8 * _scale;
        var _hp  = 0.15 + abs(sin(current_time * 0.003)) * 0.1;
        var _hc  = (global.activePiece != undefined) ? global.activePiece.color : c_white;
        draw_sprite_ext(spr_pinkSprite, 0, _cpx, _cpy, _scale, _scale, 0, _hc, _hp);
    }
}

// --- Draw blocks (via obj_block instances) ---

with (obj_block) {
    // Block screen position: board origin + world pixel offset * scale
    var _drawX = _bx + (x * _scale);
    var _drawY = _by + (y * _scale);
    var _cx5   = _drawX + 8 * _scale;
    var _cy5   = _drawY + 8 * _scale;

    // Hide blocks behind the board top edge (classic hidden row), except active piece
    if (_cy5 < _by && id != global.activePiece) continue;

    var _renderRot = -global.boardRotation + visualRotation;

    if (sprite_index != -1) {
        draw_sprite_ext(sprite_index, image_index, _cx5, _cy5,
            _scale * scale_x, _scale * scale_y, _renderRot, c_white, image_alpha);
    }

    // Active piece highlight
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

    // Core glow
    if (type == "core") {
        gpu_set_blendmode(bm_add);
        var _cp2 = 0.3 + abs(sin(current_time * 0.005)) * 0.4;
        draw_sprite_ext(sprite_index, image_index, _cx5, _cy5, _scale*scale_x*1.4, _scale*scale_y*1.4, _renderRot, c_white, _cp2 * 0.5);
        gpu_set_blendmode(bm_normal);
        draw_set_color(c_white); draw_set_alpha(_cp2 + 0.2);
        draw_rectangle(_cx5 - 9*_scale, _cy5 - 9*_scale, _cx5 + 9*_scale, _cy5 + 9*_scale, true);
        draw_rectangle(_cx5 - 10*_scale, _cy5-10*_scale, _cx5+10*_scale, _cy5+10*_scale, true);
        draw_set_alpha(1.0);
    }

    // Metal arrow overlay
    if (type == "metal") {
        var _arSpr = (dir == 0) ? spr_lr_arrows : spr_ud_arrows;
        draw_sprite_ext(_arSpr, 0, _cx5, _cy5, _scale*scale_x, _scale*scale_y, 0, c_white, image_alpha);
    }

    // Piece timer + charge bars (Planet active piece, billboarded upright)
    if ((global.gameMode == "PLANET" || global.gameMode == "STORY") && id == global.activePiece) {
        var _barW = 14 * _scale; var _barH = 2 * _scale;
        var _barM = matrix_build(_cx5, _cy5, 0, 0, 0, -global.boardRotation, 1, 1, 1);
        matrix_stack_push(_barM);
        matrix_set(matrix_world, matrix_stack_top());
        var _bxb = -(_barW/2); var _byb = -(14 * _scale);
        // Timer bar
        var _pct = global.pieceTimer / global.MAX_PIECE_TIME;
        draw_set_color(c_black);   draw_rectangle(_bxb-1, _byb-1, _bxb+_barW+1, _byb+_barH+1, false);
        draw_set_color(merge_color(c_red, c_lime, _pct));
        draw_rectangle(_bxb, _byb, _bxb + _barW * _pct, _byb + _barH, false);
        // Charge bar
        var _cBy = _byb + 3*_scale; var _cPct = global.launchCharge / global.MAX_CHARGE;
        draw_set_color(c_black);   draw_rectangle(_bxb-1, _cBy-1, _bxb+_barW+1, _cBy+_barH+1, false);
        draw_set_color(merge_color(c_navy, c_aqua, _cPct));
        draw_rectangle(_bxb, _cBy, _bxb + _barW * _cPct, _cBy + _barH, false);
        if (global.launchCharge >= global.MAX_CHARGE) {
            draw_set_alpha(abs(sin(current_time * 0.02))); draw_set_color(c_white);
            draw_rectangle(_bxb, _cBy, _bxb + _barW, _cBy + _barH, false);
            draw_set_alpha(1.0);
        }
        matrix_stack_pop();
        matrix_set(matrix_world, matrix_stack_top());
    }
}

// --- Beams & particles ---
for (var i = 0; i < array_length(global.beams); i++) {
    var _b = global.beams[i]; var _ba = _b.life / _b.maxLife;
    draw_set_alpha(_ba); draw_set_color(_b.color);
    if (_b.type == "impact") {
        var _gr = (1 - _ba) * 32;
        draw_rectangle(_bx + _b.x - _gr, _by + _b.y - 1, _bx + _b.x + _b.w + _gr, _by + _b.y + 1, false);
    } else {
        draw_rectangle(_bx + _b.x*_scale, _by + _b.y*_scale, _bx + (_b.x+16)*_scale, _by + (_b.y+_b.h)*_scale, false);
    }
}
for (var i = 0; i < array_length(global.particles); i++) {
    var _p2 = global.particles[i]; draw_set_alpha(_p2.life / 30); draw_set_color(_p2.color);
    draw_rectangle(_bx + _p2.x*_scale - 2, _by + _p2.y*_scale - 2, _bx + _p2.x*_scale + 2, _by + _p2.y*_scale + 2, false);
}

// Reset world matrix (Back to screen-space for floating text and HUD)
matrix_stack_pop();
matrix_set(matrix_world, matrix_build(0,0,0,0,0,0,1,1,1));

for (var i = 0; i < array_length(global.floatingTexts); i++) {
    var _ft = global.floatingTexts[i];
    draw_set_alpha(_ft.life / 90); draw_set_color(_ft.color);
    draw_set_font(main_font); draw_set_halign(fa_center);
    draw_text_transformed(_ft.x, _ft.y, _ft.text, _ft.scale, _ft.scale, 0);
}
draw_set_alpha(1.0);

// --- Jackpot flash ---
if (global.jackpotFlash > 0) {
    draw_set_alpha((global.jackpotFlash / 45) * 0.75); draw_set_color(c_yellow);
    draw_rectangle(0, 0, global.GAME_W, global.GAME_H, false); draw_set_alpha(1.0);
}

// --- Game Over overlay ---
if (global.gameState == "GAMEOVER") {
    draw_set_alpha(0.6); draw_set_color(c_black);
    draw_rectangle(0, 0, global.GAME_W, global.GAME_H, false);
    draw_set_alpha(1); draw_set_font(main_font); draw_set_halign(fa_center);
    draw_set_color(global.storyComplete ? c_yellow : c_white);
    draw_text_transformed(global.GAME_W/2, global.GAME_H*0.38,
        global.storyComplete ? "STORY COMPLETE!" : "GAME OVER", 2.5, 2.5, 0);
    draw_set_color(make_color_rgb(180,180,200));
    draw_text_transformed(global.GAME_W/2, global.GAME_H*0.52, "Score: " + string(global.score), 1.3, 1.3, 0);
    draw_text_transformed(global.GAME_W/2, global.GAME_H*0.60, "Best: "  + string(global.highScore), 1.1, 1.1, 0);
    draw_set_color(make_color_rgb(255,214,102));
    draw_text_transformed(global.GAME_W/2, global.GAME_H*0.72, "R  Retry     Esc  Menu", 1.0, 1.0, 0);
}

// --- Paused overlay ---
if (global.gameState == "PAUSED") {
    draw_set_alpha(0.5); draw_set_color(c_black);
    draw_rectangle(0, 0, global.GAME_W, global.GAME_H, false);
    draw_set_alpha(1); draw_set_font(main_font); draw_set_halign(fa_center); draw_set_color(c_white);
    draw_text_transformed(global.GAME_W/2, global.GAME_H*0.4, "PAUSED", 3.0, 3.0, 0);
    draw_set_color(make_color_rgb(180,180,200));
    draw_text_transformed(global.GAME_W/2, global.GAME_H*0.55, "Esc — Resume    G — Ghost    S — Shake", 1.0, 1.0, 0);
}

surface_reset_target();

// --- Composite surface to screen ---
draw_surface_ext(global.game_surface, 0, 0, 1, 1, 0, c_white, 1);

draw_set_halign(fa_left); draw_set_valign(fa_top); draw_set_alpha(1.0);
