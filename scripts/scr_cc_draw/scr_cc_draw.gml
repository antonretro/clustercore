// =============================================================================
// scr_cc_draw - board, blocks, background, panels
// =============================================================================

function cc_color_hex(_c) {
    static _cols = [ $ae4fff, $2e8aff, $3ad9ff, $7fd13f, $ffbc2b, $4040ff];
    return (_c >= 0 && _c < 6) ? _cols[_c] : c_white;
}

function cc_color_sprite(_c) {
    static _spr = [spr_pinkSprite, spr_orangeSprite, spr_yellowSprite, spr_greenSprite, spr_lightblueSprite, spr_redSprite];
    return (_c >= 0 && _c < 6) ? _spr[_c] : spr_space_rock;
}

// Draw a sprite centred on (x,y) whatever its origin, rotated by _ang (CCW deg).
function cc_spr(_spr, _img, _x, _y, _scale, _ang, _col = c_white, _alpha = 1) {
    var _vx = (sprite_get_width(_spr) * 0.5 - sprite_get_xoffset(_spr)) * _scale;
    var _vy = (sprite_get_height(_spr) * 0.5 - sprite_get_yoffset(_spr)) * _scale;
    var _c = dcos(_ang), _s = dsin(_ang);
    var _rx = _vx * _c + _vy * _s;
    var _ry = -_vx * _s + _vy * _c;
    draw_sprite_ext(_spr, _img, _x - _rx, _y - _ry, _scale, _scale, _ang, _col, _alpha);
}

// ── board geometry ───────────────────────────────────────────────────────────
// global.view = { x, y, cs (cell px), ang (deg), n }
function cc_to_screen(_gx, _gy) {
    var _V = global.view;
    var _c = (_V.n - 1) * 0.5;
    var _dx = (_gx - _c) * _V.cs, _dy = (_gy - _c) * _V.cs;
    var _co = dcos(_V.ang), _si = dsin(_V.ang);
    return [_V.x + _dx * _co + _dy * _si + _V.sx, _V.y - _dx * _si + _dy * _co + _V.sy];
}

// ── one cell ─────────────────────────────────────────────────────────────────
function cc_draw_cell(_v, _x, _y, _scale, _ang, _alpha = 1, _white = 0, _core_col = -1, _core_layers = 0) {
    var _t = cc_t(_v);
    var _sc = _scale;
    switch (_t) {
        case CC_NORMAL:
        case CC_ARROW:
            cc_spr(cc_color_sprite(cc_col(_v)), 0, _x, _y, _sc, _ang, c_white, _alpha);
            if (_t == CC_ARROW) {
                var _spr = (cc_ax(_v) == 0) ? spr_lr_arrows : spr_ud_arrows;
                cc_spr(_spr, 0, _x, _y, _sc * 0.8, _ang, c_white, _alpha);
            }
            if (cc_cage(_v)) cc_spr(spr_locked_cage, 0, _x, _y, _sc, _ang, c_white, _alpha);
            break;
        case CC_STONE: cc_spr(spr_space_rock, 0, _x, _y, _sc, _ang, c_white, _alpha); break;
        case CC_WALL:  cc_spr(spr_deadmetal, 0, _x, _y, _sc, _ang, c_white, _alpha); break;
        case CC_CORE:
            cc_draw_core(_x, _y, _sc, _alpha, _core_col, _core_layers);
            break;
    }
    if (_white > 0) {
        gpu_set_fog(true, c_white, 0, 1);
        cc_spr(spr_pinkSprite, 0, _x, _y, _sc, _ang, c_white, _white * _alpha);
        gpu_set_fog(false, c_white, 0, 1);
    }
}

// The core: a glowing orb in its current colour, with one orbiting ring per
// layer still waiting behind it (coloured like that layer).
function cc_draw_core(_x, _y, _sc, _alpha, _core_col, _layers) {
    var _col = cc_color_hex(_core_col);
    var _t = current_time / 1000;
    var _pulse = 0.5 + 0.5 * sin(_t * 4);
    draw_set_circle_precision(32);
    gpu_set_blendmode(bm_add);
    draw_set_color(_col);
    draw_set_alpha((0.18 + 0.12 * _pulse) * _alpha);
    draw_circle(_x, _y, _sc * (10 + 1.5 * _pulse), false);
    draw_set_alpha(0.25 * _alpha);
    draw_circle(_x, _y, _sc * 7.5, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(_alpha);
    draw_set_color(merge_color(_col, c_black, 0.55));
    draw_circle(_x, _y, _sc * 6.4, false);
    draw_set_color(_col);
    draw_circle(_x, _y, _sc * 5.6, false);
    draw_set_color(merge_color(_col, c_white, 0.45));
    draw_circle(_x - _sc * 1, _y - _sc * 1, _sc * 3.6, false);
    draw_set_color(c_white);
    draw_set_alpha(0.8 * _alpha);
    draw_circle(_x - _sc * 2.1, _y - _sc * 2.1, _sc * 1.3, false);
    // a bright spinning spark band so it never reads as a normal block
    gpu_set_blendmode(bm_add);
    for (var _i = 0; _i < 3; _i++) {
        var _a = _t * 140 + _i * 120;
        draw_set_alpha(0.7 * _alpha);
        draw_circle(_x + lengthdir_x(_sc * 6.2, _a), _y + lengthdir_y(_sc * 6.2, _a), _sc * 0.9, false);
    }
    gpu_set_blendmode(bm_normal);
    // rings for the layers still to come
    var _P = global.play;
    if (_P != undefined) {
        var _seq = _P.st.seq;
        var _hp = _P.disp_hp;
        for (var _i = 1; _i < _layers; _i++) {
            var _lc = (_hp + _i < array_length(_seq)) ? cc_color_hex(_seq[_hp + _i]) : c_white;
            var _r = _sc * (6.8 + _i * 1.3);
            draw_set_color(_lc);
            draw_set_alpha(0.9 * _alpha);
            var _spin = _t * (60 - _i * 25);
            for (var _k = 0; _k < 8; _k++) {
                var _a0 = _spin + _k * 45, _a1 = _a0 + 28;
                draw_line_width(_x + lengthdir_x(_r, _a0), _y + lengthdir_y(_r, _a0), _x + lengthdir_x(_r, _a1), _y + lengthdir_y(_r, _a1), max(2, _sc * 0.7));
            }
        }
    }
    draw_set_alpha(1);
}

function cc_draw_piece(_p, _x, _y, _scale, _ang = 0, _alpha = 1) {
    if (_p < 0) return;
    if (_p == CC_BOMB)       cc_spr(spr_bomb, 0, _x, _y, _scale, _ang, c_white, _alpha);
    else if (_p == CC_DRILL) cc_spr(spr_drill, 0, _x, _y, _scale, _ang + 180, c_white, _alpha);
    else if (_p == CC_PAINT) cc_spr(spr_wildcard, 0, _x, _y, _scale, _ang, make_color_hsv((current_time / 8) mod 255, 120, 255), _alpha);
    else cc_spr(cc_color_sprite(_p), 0, _x, _y, _scale, _ang, c_white, _alpha);
}

function cc_piece_color(_p) {
    if (_p >= 0 && _p < 6) return cc_color_hex(_p);
    if (_p == CC_BOMB) return $3a6aff;
    if (_p == CC_DRILL) return $e0d6d0;
    return make_color_hsv((current_time / 8) mod 255, 160, 255);
}

// ── background ───────────────────────────────────────────────────────────────
function cc_bg_init() {
    global.stars = [];
    random_set_seed(77);
    repeat (140) array_push(global.stars, { x: random(1280), y: random(720), z: random_range(0.2, 1), tw: random(1000) });
    random_set_seed(current_time);
}

function cc_draw_bg(_col, _planet, _t) {
    draw_clear(_col);
    // soft vertical gradient
    draw_rectangle_color(0, 0, 1280, 720, merge_color(_col, c_black, 0.5), merge_color(_col, c_black, 0.5), merge_color(_col, $502030, 0.35), merge_color(_col, $502030, 0.35), false);
    // stars drift slowly
    for (var _i = 0; _i < array_length(global.stars); _i++) {
        var _s = global.stars[_i];
        var _x = (_s.x - _t * 0.15 * _s.z) mod 1280; if (_x < 0) _x += 1280;
        var _a = 0.35 + 0.65 * _s.z * (0.6 + 0.4 * sin(_s.tw + _t * 0.05));
        draw_set_alpha(_a);
        draw_set_color(c_white);
        var _r = (_s.z > 0.85) ? 2 : 1;
        draw_rectangle(_x, _s.y, _x + _r, _s.y + _r, false);
    }
    draw_set_alpha(1);
    if (_planet != undefined && sprite_exists(_planet)) {
        var _w = sprite_get_width(_planet);
        var _k = 520 / max(_w, 1);
        cc_spr(_planet, 0, 1120, 640, _k, _t * 0.01, c_white, 0.22);
    }
}

function cc_draw_scanlines() {
    draw_set_alpha(0.07);
    draw_set_color(c_black);
    for (var _y = 0; _y < 720; _y += 3) draw_line(0, _y, 1280, _y);
    draw_set_alpha(1);
    // soft dark edges top and bottom
    for (var _i = 0; _i < 6; _i++) {
        draw_set_alpha(0.06);
        draw_set_color(c_black);
        draw_rectangle(0, 0, 1280, 10 + _i * 10, false);
        draw_rectangle(0, 710 - _i * 10, 1280, 720, false);
    }
    draw_set_alpha(1);
}

// ── ui panels ─────────────────────────────────────────────────────────────────
function cc_panel(_x, _y, _w, _h, _accent = $fc5d6d, _alpha = 0.85) {
    draw_set_alpha(_alpha);
    draw_set_color($220c12);
    draw_roundrect_ext(_x, _y, _x + _w, _y + _h, 18, 18, false);
    draw_set_alpha(1);
    draw_set_color(_accent);
    draw_roundrect_ext(_x, _y, _x + _w, _y + _h, 18, 18, true);
    draw_roundrect_ext(_x + 1, _y + 1, _x + _w - 1, _y + _h - 1, 18, 18, true);
}

function cc_button(_x, _y, _w, _h, _label, _focus, _accent = $fc5d6d, _enabled = true) {
    var _k = _focus ? (1 + 0.04 * sin(current_time / 120)) : 1;
    var _cw = _w * _k, _ch = _h * _k;
    var _bx = _x - _cw / 2, _by = _y - _ch / 2;
    draw_set_color(_focus ? _accent : $36151d);
    draw_set_alpha(_enabled ? 1 : 0.5);
    draw_roundrect_ext(_bx, _by + 4, _bx + _cw, _by + _ch + 4, 14, 14, false);
    draw_set_color(_focus ? merge_color(_accent, c_white, 0.25) : $50202a);
    draw_roundrect_ext(_bx, _by, _bx + _cw, _by + _ch, 14, 14, false);
    draw_set_alpha(1);
    cc_text(_x, _y, _label, 2.2 * _k, _focus ? c_white : $e0b0b8, _enabled ? 1 : 0.5, fa_center, fa_middle, _focus);
}

function cc_draw_star(_x, _y, _r, _filled, _col = $3ad9ff) {
    var _pts = [];
    for (var _i = 0; _i < 10; _i++) {
        var _rr = (_i mod 2 == 0) ? _r : _r * 0.45;
        var _a = 90 + _i * 36;
        array_push(_pts, [_x + lengthdir_x(_rr, _a), _y + lengthdir_y(_rr, _a)]);
    }
    draw_set_color(_filled ? _col : $60313a);
    for (var _i = 0; _i < 10; _i++) {
        var _p = _pts[_i], _q = _pts[(_i + 1) mod 10];
        draw_triangle(_x, _y, _p[0], _p[1], _q[0], _q[1], false);
    }
}
