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

// --- Ghost Piece ---
if (global.gameState == "PLAYING" && global.activePiece != undefined && global.settings.ghostEnabled) {
    var _gx = global.activePiece.grid_x;
    var _gy = global.activePiece.grid_y;
    while (_gy < global.TOTAL_ROWS - 1) {
        if (global.grid[_gy + 1][_gx] != undefined) break;
        _gy++;
    }
    // Correct center positioning for (8,8) origin
    var _gpcx = _bx + (_gx * 16 * _scale) + (8 * _scale);
    var _gpcy = _by + ((_gy - global.HIDDEN_ROWS) * 16 * _scale) + (8 * _scale);
    
    if (_gy >= global.HIDDEN_ROWS) {
        var _activeSpr = global.activePiece.sprite_index;
        draw_set_alpha(0.3);
        draw_sprite_ext(_activeSpr, 0, _gpcx, _gpcy, _scale, _scale, 0, c_white, 0.3);
        if (global.activePiece.type == "metal") {
            var _arrowSpr = (global.activePiece.dir == 0) ? spr_lr_arrows : spr_ud_arrows;
            draw_sprite_ext(_arrowSpr, 0, _gpcx, _gpcy, _scale, _scale, 0, c_white, 0.3);
        }
        draw_set_alpha(1.0);
    }
}

// --- Draw Blocks ---
with(obj_block) {
    var _drawX = _bx + (x * _scale);
    var _drawY = _by + (y * _scale);
    var _cx = _drawX + (8 * _scale);
    var _cy = _drawY + (8 * _scale);
    if (_cy < _by) continue; // clip hidden rows
    if (sprite_index != -1) {
        draw_sprite_ext(sprite_index, image_index, _cx, _cy, _scale * scale_x, _scale * scale_y, rotation, c_white, image_alpha);
    }
    if (type == "metal") {
        var _arrowSpr = (dir == 0) ? spr_lr_arrows : spr_ud_arrows;
        draw_sprite_ext(_arrowSpr, 0, _cx, _cy, _scale * scale_x, _scale * scale_y, rotation, c_white, image_alpha);
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

// --- Draw the Upscaled Surface ---
gpu_set_texfilter(false);
draw_surface(global.game_surface, 0, 0);
gpu_set_texfilter(true);
