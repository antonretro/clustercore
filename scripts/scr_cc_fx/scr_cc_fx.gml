// =============================================================================
// scr_cc_fx - juice: particles, shake, flash, floating text, rings, easing
// All in screen space, updated by obj_game each frame.
// =============================================================================

function cc_fx_init() {
    global.fx = { parts: [], texts: [], rings: [], shake: 0, flash: 0, flash_col: c_white, hitstop: 0, zoom: 0 };
}

function ease_out_cubic(_t) { _t = clamp(_t, 0, 1); return 1 - power(1 - _t, 3); }
function ease_out_back(_t)  { _t = clamp(_t, 0, 1); var _c = 1.70158; return 1 + (_c + 1) * power(_t - 1, 3) + _c * power(_t - 1, 2); }
function ease_in_quad(_t)   { _t = clamp(_t, 0, 1); return _t * _t; }
function ease_out_elastic(_t) {
    _t = clamp(_t, 0, 1);
    if (_t == 0 || _t == 1) return _t;
    return power(2, -10 * _t) * sin((_t * 10 - 0.75) * (2 * pi) / 3) + 1;
}

function cc_shake(_amt) {
    if (!global.save.shake) _amt *= 0.25;
    global.fx.shake = max(global.fx.shake, _amt);
}

function cc_flash(_amt, _col = c_white) {
    if (!global.save.flash) _amt *= 0.3;
    global.fx.flash = max(global.fx.flash, _amt);
    global.fx.flash_col = _col;
}

function cc_hitstop(_frames) { global.fx.hitstop = max(global.fx.hitstop, _frames); }

// kind: 0 square spark, 1 round glow, 2 shard (spins)
function cc_burst(_x, _y, _col, _count, _speed = 6, _kind = 0, _life = 40) {
    repeat (_count) {
        var _a = random(360), _s = random_range(_speed * 0.3, _speed);
        array_push(global.fx.parts, {
            x: _x, y: _y, vx: lengthdir_x(_s, _a), vy: lengthdir_y(_s, _a),
            col: _col, life: _life * random_range(0.6, 1.1), max: _life,
            size: random_range(3, 7), kind: _kind, rot: random(360), spin: random_range(-12, 12)
        });
    }
}

function cc_ring(_x, _y, _col, _r0, _r1, _life = 24, _w = 6) {
    array_push(global.fx.rings, { x: _x, y: _y, col: _col, r0: _r0, r1: _r1, t: 0, life: _life, w: _w });
}

function cc_float_text(_x, _y, _txt, _col, _scale = 2, _life = 60) {
    array_push(global.fx.texts, { x: _x, y: _y, txt: _txt, col: _col, scale: _scale, t: 0, life: _life });
}

function cc_fx_update() {
    var _F = global.fx;
    _F.shake = max(0, _F.shake * 0.86 - 0.05);
    _F.flash = max(0, _F.flash - 0.06);
    _F.zoom *= 0.88;

    for (var _i = array_length(_F.parts) - 1; _i >= 0; _i--) {
        var _p = _F.parts[_i];
        _p.x += _p.vx; _p.y += _p.vy;
        _p.vx *= 0.92; _p.vy *= 0.92;
        _p.vy += (_p.kind == 2) ? 0.25 : 0.04;
        _p.rot += _p.spin;
        _p.life--;
        if (_p.life <= 0) array_delete(_F.parts, _i, 1);
    }
    for (var _i = array_length(_F.rings) - 1; _i >= 0; _i--) {
        var _r = _F.rings[_i];
        _r.t++;
        if (_r.t >= _r.life) array_delete(_F.rings, _i, 1);
    }
    for (var _i = array_length(_F.texts) - 1; _i >= 0; _i--) {
        var _t = _F.texts[_i];
        _t.t++;
        if (_t.t >= _t.life) array_delete(_F.texts, _i, 1);
    }
}

function cc_fx_draw() {
    var _F = global.fx;
    gpu_set_blendmode(bm_add);
    for (var _i = 0; _i < array_length(_F.rings); _i++) {
        var _r = _F.rings[_i];
        var _k = ease_out_cubic(_r.t / _r.life);
        var _rad = lerp(_r.r0, _r.r1, _k);
        draw_set_alpha(1 - _k);
        draw_set_color(_r.col);
        for (var _w = 0; _w < _r.w * (1 - _k) + 1; _w++) draw_circle(_r.x, _r.y, _rad + _w, true);
    }
    for (var _i = 0; _i < array_length(_F.parts); _i++) {
        var _p = _F.parts[_i];
        var _a = clamp(_p.life / _p.max, 0, 1);
        var _s = _p.size * (0.4 + 0.6 * _a);
        draw_set_alpha(_a);
        draw_set_color(_p.col);
        if (_p.kind == 1) {
            draw_circle(_p.x, _p.y, _s, false);
        } else {
            var _dx = lengthdir_x(_s, _p.rot), _dy = lengthdir_y(_s, _p.rot);
            var _ex = lengthdir_x(_s, _p.rot + 90), _ey = lengthdir_y(_s, _p.rot + 90);
            draw_triangle(_p.x + _dx, _p.y + _dy, _p.x + _ex, _p.y + _ey, _p.x - _dx, _p.y - _dy, false);
            draw_triangle(_p.x - _dx, _p.y - _dy, _p.x - _ex, _p.y - _ey, _p.x + _dx, _p.y + _dy, false);
        }
    }
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);

    for (var _i = 0; _i < array_length(_F.texts); _i++) {
        var _t = _F.texts[_i];
        var _k = _t.t / _t.life;
        var _pop = (_t.t < 10) ? ease_out_back(_t.t / 10) : 1;
        var _a = (_k > 0.7) ? (1 - (_k - 0.7) / 0.3) : 1;
        cc_text(_t.x, _t.y - ease_out_cubic(_k) * 40, _t.txt, _t.scale * _pop, _t.col, _a, fa_center, fa_middle, true);
    }
}

// Shared text helper: pixel font, optional dark outline for readability.
function cc_text(_x, _y, _str, _scale, _col, _alpha = 1, _ha = fa_left, _va = fa_top, _outline = true) {
    draw_set_font(main_font);
    draw_set_halign(_ha);
    draw_set_valign(_va);
    draw_set_alpha(_alpha);
    if (_outline) {
        var _o = max(1, round(_scale));
        draw_set_color($14070b);
        draw_text_transformed(_x + _o, _y + _o, _str, _scale, _scale, 0);
        draw_text_transformed(_x - _o, _y + _o, _str, _scale, _scale, 0);
        draw_text_transformed(_x + _o, _y - _o, _str, _scale, _scale, 0);
        draw_text_transformed(_x - _o, _y - _o, _str, _scale, _scale, 0);
        draw_text_transformed(_x, _y + _o * 2, _str, _scale, _scale, 0);
    }
    draw_set_color(_col);
    draw_text_transformed(_x, _y, _str, _scale, _scale, 0);
    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}
