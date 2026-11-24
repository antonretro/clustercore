// =============================================================================
// scr_cc_menu - title, main menu, world map, options
// =============================================================================

function cc_goto(_scene, _fade = true) {
    global.scene = _scene;
    global.scene_t = 0;
    global.menu_sel = 0;
}

function cc_goto_map(_li = -1) {
    cc_goto("map");
    if (_li >= 0) {
        global.map_world = global.levels[_li].world;
        var _wl = cc_world_levels(global.map_world);
        for (var _i = 0; _i < array_length(_wl); _i++) if (_wl[_i] == _li) global.map_sel = _i;
    }
}

// ── title ────────────────────────────────────────────────────────────────────
function cc_title_step() {
    if (global.scene_t > 20 && global.inp.any) { cc_sfx("confirm"); cc_goto("menu"); }
}

function cc_title_draw() {
    var _t = global.scene_t;
    cc_draw_bg($240a12, spr_neptune, current_time / 16);
    cc_draw_orbit_ring(640, 300, _t);
    var _bob = sin(_t / 30) * 6;
    var _k = ease_out_back(clamp(_t / 40, 0, 1));
    cc_spr(spr_logo, 0, 640, 290 + _bob, 2.4 * _k, sin(_t / 50) * 2);
    if ((_t div 30) mod 2 == 0 && _t > 40) cc_text(640, 560, "PRESS START", 2.6, c_white, 1, fa_center, fa_middle);
    cc_text(640, 690, "v2.0", 1.2, $a0666f, 1, fa_center, fa_bottom, false);
}

// little ring of blocks orbiting a core (title + menu decoration)
function cc_draw_orbit_ring(_x, _y, _t) {
    for (var _i = 0; _i < 12; _i++) {
        var _a = _t * 0.6 + _i * 30;
        var _r = 210 + 14 * sin(_t / 40 + _i);
        var _px = _x + lengthdir_x(_r, _a), _py = _y + lengthdir_y(_r * 0.45, _a);
        var _front = lengthdir_y(1, _a) > 0;
        cc_spr(cc_color_sprite(_i mod 6), 0, _px, _py, _front ? 3 : 2, _a, c_white, _front ? 1 : 0.5);
    }
}

// ── main menu ────────────────────────────────────────────────────────────────
function cc_menu_items() { return ["CAMPAIGN", "ENDLESS", "OPTIONS", "QUIT"]; }

function cc_menu_step() {
    var _I = global.inp, _items = cc_menu_items(), _n = array_length(_items);
    if (_I.up)   { global.menu_sel = (global.menu_sel + _n - 1) mod _n; cc_sfx("select"); }
    if (_I.down) { global.menu_sel = (global.menu_sel + 1) mod _n; cc_sfx("select"); }
    if (_I.back) { cc_goto("title"); return; }
    if (_I.ok) {
        cc_sfx("confirm");
        switch (_items[global.menu_sel]) {
            case "CAMPAIGN": cc_goto_map(cc_first_unbeaten()); break;
            case "ENDLESS":  cc_play_start_endless(); cc_goto("play"); break;
            case "OPTIONS":  global.options_return = "menu"; cc_goto("options"); break;
            case "QUIT":     game_end(); break;
        }
    }
}

function cc_first_unbeaten() {
    for (var _i = 0; _i < array_length(global.levels); _i++) {
        if (global.save.stars[_i] == 0 && cc_level_open(_i)) return _i;
    }
    return 0;
}

function cc_menu_draw() {
    var _t = global.scene_t;
    cc_draw_bg($240a12, spr_neptune, current_time / 16);
    cc_draw_orbit_ring(340, 330, current_time / 16);
    cc_spr(spr_logo, 0, 340, 320 + sin(current_time / 500) * 5, 1.8, 0);
    var _items = cc_menu_items();
    for (var _i = 0; _i < array_length(_items); _i++) {
        var _k = ease_out_cubic(clamp((_t - _i * 4) / 18, 0, 1));
        cc_button(880 + (1 - _k) * 200, 230 + _i * 80, 320, 60, _items[_i], global.menu_sel == _i);
    }
    var _tot = cc_total_stars(), _max = array_length(global.levels) * 3;
    cc_draw_star(70, 670, 16, true);
    cc_text(96, 670, string(_tot) + " / " + string(_max), 2, $3ad9ff, 1, fa_left, fa_middle);
    if (global.save.endless_best > 0) cc_text(1240, 670, "ENDLESS BEST " + string(global.save.endless_best), 1.6, $d89fa9, 1, fa_right, fa_middle);
}

// ── world map ────────────────────────────────────────────────────────────────
function cc_map_step() {
    var _I = global.inp;
    var _ws = cc_worlds();
    var _wl = cc_world_levels(global.map_world);
    var _cnt = array_length(_wl);
    global.map_sel = clamp(global.map_sel, 0, max(0, _cnt - 1));
    if (_I.left)  { if (global.map_sel > 0) { global.map_sel--; cc_sfx("tick"); } else cc_map_world(-1); }
    if (_I.right) { if (global.map_sel < _cnt - 1) { global.map_sel++; cc_sfx("tick"); } else cc_map_world(1); }
    if (_I.up)    cc_map_world(-1, true);
    if (_I.down)  cc_map_world(1, true);
    if (_I.rotl)  cc_map_world(-1, true);
    if (_I.rotr)  cc_map_world(1, true);
    if (_I.back)  { cc_goto("menu"); cc_sfx("select"); return; }
    if (_I.ok && _cnt > 0) {
        var _li = _wl[global.map_sel];
        if (cc_level_open(_li)) { cc_sfx("confirm"); cc_play_start_level(_li); cc_goto("play"); }
        else { cc_sfx("blocked"); cc_shake(4); }
    }
}

function cc_map_world(_d, _keep = false) {
    var _nw = clamp(global.map_world + _d, 0, array_length(cc_worlds()) - 1);
    if (_nw == global.map_world) { cc_sfx("blocked"); return; }
    if (array_length(cc_world_levels(_nw)) == 0) { cc_sfx("blocked"); return; }
    global.map_world = _nw;
    global.map_slide = _d;
    var _cnt = array_length(cc_world_levels(_nw));
    global.map_sel = _keep ? min(global.map_sel, _cnt - 1) : ((_d > 0) ? 0 : _cnt - 1);
    cc_sfx("turn");
}

function cc_map_draw() {
    var _ws = cc_worlds();
    var _w = global.map_world;
    var _W = _ws[_w];
    var _open = cc_world_open(_w);
    global.map_slide = lerp(global.map_slide, 0, 0.15);
    cc_draw_bg(_W.bg, undefined, current_time / 16);

    // big planet
    var _px = 640 - global.map_slide * 300;
    var _spr = _W.spr;
    var _k = 300 / max(sprite_get_width(_spr), sprite_get_height(_spr) * 1.6);
    gpu_set_blendmode(bm_add);
    draw_set_alpha(0.18); draw_set_color(_W.col); draw_circle(_px, 240, 150 + 6 * sin(current_time / 300), false);
    draw_set_alpha(1); gpu_set_blendmode(bm_normal);
    cc_spr(_spr, 0, _px, 240, _k * 1.6, current_time / 200, _open ? c_white : $504040);
    cc_text(640, 70, "WORLD " + string(_w + 1), 1.8, $d89fa9, 1, fa_center, fa_middle);
    cc_text(640, 400, _W.name, 4, _W.col, 1, fa_center, fa_middle);
    cc_text(640, 440, _W.blurb, 1.8, $f0c0c8, 1, fa_center, fa_middle);

    // world arrows
    if (_w > 0) cc_text(80, 240, "<", 5, $d89fa9, 0.5 + 0.5 * sin(current_time / 200), fa_center, fa_middle);
    if (_w < array_length(_ws) - 1 && array_length(cc_world_levels(_w + 1)) > 0) cc_text(1200, 240, ">", 5, $d89fa9, 0.5 + 0.5 * sin(current_time / 200), fa_center, fa_middle);

    // level nodes
    var _wl = cc_world_levels(_w);
    var _cnt = array_length(_wl);
    var _gap = 150;
    var _x0 = 640 - (_cnt - 1) * _gap / 2;
    for (var _i = 0; _i < _cnt; _i++) {
        var _li = _wl[_i];
        var _x = _x0 + _i * _gap, _y = 540;
        var _lopen = cc_level_open(_li);
        var _sel = (_i == global.map_sel);
        if (_i < _cnt - 1) { draw_set_color($60313a); draw_line_width(_x + 36, _y, _x + _gap - 36, _y, 4); }
        var _s = _sel ? 1.15 + 0.05 * sin(current_time / 120) : 1;
        draw_set_color(_sel ? _W.col : $441c24);
        draw_circle(_x, _y, 36 * _s, false);
        draw_set_color(_lopen ? merge_color(_W.col, c_white, 0.3) : $60313a);
        draw_circle(_x, _y, 36 * _s, true);
        if (_lopen) cc_text(_x, _y, string(_i + 1), 2.6 * _s, c_white, 1, fa_center, fa_middle);
        else cc_spr(spr_locked_cage, 0, _x, _y, 2.5, 0, c_white, 0.8);
        var _st = global.save.stars[_li];
        for (var _s2 = 0; _s2 < 3; _s2++) cc_draw_star(_x - 24 + _s2 * 24, _y + 56, 10, _s2 < _st);
    }
    if (_cnt > 0) {
        var _li = _wl[global.map_sel];
        var _lv = global.levels[_li];
        var _txt = cc_level_open(_li) ? string_upper(_lv.name) + "   -   PAR " + string(_lv.par) : (_open ? "BEAT THE LEVEL BEFORE" : "BEAT 4 LEVELS IN " + _ws[max(0, _w - 1)].name);
        cc_text(640, 640, _txt, 2, c_white, 1, fa_center, fa_middle);
    }
    cc_text(640, 700, "LEFT/RIGHT choose   UP/DOWN world   ENTER play   ESC back", 1.3, $c0868f, 1, fa_center, fa_bottom, false);
    cc_draw_star(1150, 40, 14, true);
    cc_text(1172, 40, string(cc_total_stars()), 2, $3ad9ff, 1, fa_left, fa_middle);
}

// ── options ──────────────────────────────────────────────────────────────────
function cc_options_items() { return ["VOLUME", "SCREEN SHAKE", "FLASHES", "FULLSCREEN", "BACK"]; }

function cc_options_step() {
    var _I = global.inp, _items = cc_options_items(), _n = array_length(_items);
    var _S = global.save;
    if (_I.up)   { global.menu_sel = (global.menu_sel + _n - 1) mod _n; cc_sfx("select"); }
    if (_I.down) { global.menu_sel = (global.menu_sel + 1) mod _n; cc_sfx("select"); }
    var _item = _items[global.menu_sel];
    var _dx = _I.right - _I.left;
    var _press = _I.ok;
    switch (_item) {
        case "VOLUME":
            if (_dx != 0) { _S.sfx = clamp(round((_S.sfx + _dx * 0.1) * 10) / 10, 0, 1); cc_sfx("tick"); cc_save_write(); }
            break;
        case "SCREEN SHAKE": if (_dx != 0 || _press) { _S.shake = !_S.shake; cc_shake(8); cc_sfx("select"); cc_save_write(); } break;
        case "FLASHES":      if (_dx != 0 || _press) { _S.flash = !_S.flash; cc_flash(0.5); cc_sfx("select"); cc_save_write(); } break;
        case "FULLSCREEN":   if (_dx != 0 || _press) { window_set_fullscreen(!window_get_fullscreen()); cc_sfx("select"); } break;
        case "BACK": if (_press) _I.back = true; break;
    }
    if (_I.back) {
        cc_sfx("select");
        if (global.options_return == "play") { global.scene = "play"; global.play.paused = true; }
        else cc_goto("menu");
    }
}

function cc_options_draw() {
    cc_draw_bg($240a12, undefined, current_time / 16);
    cc_text(640, 100, "OPTIONS", 4, c_white, 1, fa_center, fa_middle);
    var _items = cc_options_items();
    var _S = global.save;
    for (var _i = 0; _i < array_length(_items); _i++) {
        var _y = 210 + _i * 80;
        var _sel = global.menu_sel == _i;
        var _val = "";
        switch (_items[_i]) {
            case "VOLUME": _val = string(round(_S.sfx * 10) * 10) + "%"; break;
            case "SCREEN SHAKE": _val = _S.shake ? "ON" : "LOW"; break;
            case "FLASHES": _val = _S.flash ? "ON" : "LOW"; break;
            case "FULLSCREEN": _val = window_get_fullscreen() ? "ON" : "OFF"; break;
        }
        cc_button(640, _y, 560, 60, (_val == "") ? _items[_i] : _items[_i] + "   < " + _val + " >", _sel);
    }
}
