/// @module scr_menu_render_vfx
/// Cinematic transitions and floating text rendering.

function menu_draw_level_transition(_cx, _cy, _sw, _sh) {
    // Dark background
    draw_set_alpha(1.0); draw_set_color(make_color_rgb(2, 4, 10));
    draw_rectangle(0, 0, _sw, _sh, false);

    // Starfield
    var _starT = current_time * 0.00008;
    for (var i = 0; i < 50; i++) {
        var _pxs = (i * 197.5 + _starT * 160) % _sw;
        var _pys = (i * 143.4 + _starT * 80) % _sh;
        draw_set_alpha(0.1 + (i % 4) * 0.08); draw_set_color(c_white);
        draw_circle(_pxs, _pys, 1 + (i % 2), false);
    }
    draw_set_alpha(1);

    var _p = level_transition_timer / 60;
    var _world = story_worlds[transition_target_world];
    var _levelName = story_level_names[transition_target_world][transition_target_level];

    // Glassmorphism deployment panel
    var _pw = 700; var _ph = 340;
    var _px1 = _cx - _pw * 0.5;
    var _py1 = _cy - _ph * 0.5 - 40;

    // Panel shadow
    draw_set_alpha(0.5); draw_set_color(c_black);
    draw_roundrect_ext(_px1 + 8, _py1 + 8, _px1 + _pw + 8, _py1 + _ph + 8, 20, 20, false);

    // Panel background
    var _pTop = make_color_rgb(16, 28, 60);
    var _pBot = make_color_rgb(6, 10, 28);
    draw_set_alpha(0.9);
    draw_rectangle_colour(_px1, _py1, _px1 + _pw, _py1 + _ph, _pTop, _pTop, _pBot, _pBot, false);

    // Grid texture
    draw_set_alpha(0.03); draw_set_color(c_white);
    for (var gx = _px1; gx < _px1 + _pw; gx += 40) draw_line(gx, _py1, gx, _py1 + _ph);
    for (var gy = _py1; gy < _py1 + _ph; gy += 40) draw_line(_px1, gy, _px1 + _pw, gy);

    // Panel border
    draw_set_alpha(0.5); draw_set_color(make_color_rgb(140, 190, 255));
    draw_roundrect_ext(_px1, _py1, _px1 + _pw, _py1 + _ph, 20, 20, true);

    // Ship deployment animation
    var _shipSprite = asset_get_index("spr_refabricator_ship");
    if (_shipSprite != -1 && sprite_exists(_shipSprite)) {
        var _shipX = _cx + 80 + sin(_p * 2.0) * 20;
        var _shipY = _py1 - 40;
        var _shipS = 2.0 + _p * 0.5;
        var _shipAlpha = clamp(_p * 2.0, 0.2, 1.0);
        draw_set_alpha(_shipAlpha);
        draw_sprite_ext(_shipSprite, 0, _shipX, _shipY, _shipS, _shipS,
                       current_time * 0.001, c_white, 1.0);
    }

    // World name
    draw_set_halign(fa_center);
    draw_set_alpha(0.5); draw_set_color(make_color_rgb(140, 200, 255));
    draw_text_transformed(_cx, _py1 + 50, _world.name, global.TXT_H2, global.TXT_H2, 0);

    // Level name
    draw_set_alpha(1.0); draw_set_color(c_white);
    draw_text_transformed(_cx, _py1 + 110, _levelName, global.TXT_H1, global.TXT_H1, 0);

    // Deployment flavor text
    var _flavor = "";
    if (_p < 0.33) _flavor = "CALIBRATING NAVIGATION SYSTEMS...";
    else if (_p < 0.66) _flavor = "SYNCING ORBITAL COORDINATES...";
    else _flavor = "INITIATING LANDING SEQUENCE...";
    draw_set_alpha(0.6); draw_set_color(make_color_rgb(100, 220, 255));
    draw_text_transformed(_cx, _py1 + 170, _flavor, global.TXT_H4, global.TXT_H4, 0);

    // Loading bar
    var _bw = 500; var _bh = 8;
    var _by = _py1 + 230;

    // Bar background
    draw_set_alpha(0.15); draw_set_color(c_white);
    draw_roundrect_ext(_cx - _bw * 0.5, _by, _cx + _bw * 0.5, _by + _bh, 4, 4, false);

    // Bar fill
    gpu_set_blendmode(bm_add);
    draw_set_alpha(0.25); draw_set_color(make_color_rgb(100, 220, 255));
    draw_roundrect_ext(_cx - _bw * 0.5 - 4, _by - 4, _cx + _bw * 0.5 + 4, _by + _bh + 4, 8, 8, false);
    gpu_set_blendmode(bm_normal);

    draw_set_alpha(0.9); draw_set_color(make_color_rgb(100, 220, 255));
    draw_roundrect_ext(_cx - _bw * 0.5, _by, _cx - _bw * 0.5 + (_bw * _p), _by + _bh, 4, 4, false);

    // Bar glow
    gpu_set_blendmode(bm_add);
    draw_set_alpha(0.2 + abs(sin(current_time * 0.01)) * 0.08);
    draw_set_color(make_color_rgb(100, 220, 255));
    draw_roundrect_ext(_cx - _bw * 0.5, _by, _cx - _bw * 0.5 + (_bw * _p), _by + _bh, 4, 4, false);
    gpu_set_blendmode(bm_normal);

    // Progress percentage
    draw_set_alpha(0.4); draw_set_color(c_white);
    draw_text_transformed(_cx, _by + 30, string(floor(_p * 100)) + "%", global.TXT_SMALL, global.TXT_SMALL, 0);

    // Bottom scan line
    draw_set_alpha(0.12); draw_set_color(make_color_rgb(100, 200, 255));
    var _scanY = _sh - 120 + sin(current_time * 0.002) * 15;
    draw_line_width(100, _scanY, _sw - 100, _scanY, 2);

    draw_set_alpha(1);
}

function menu_draw_floating_texts() {
    for (var i = 0; i < array_length(global.floatingTexts); i++) {
        var _ft = global.floatingTexts[i];
        draw_set_alpha(_ft.life / 90);
        draw_set_color(_ft.color);
        draw_text_transformed(_ft.x, _ft.y, _ft.text, _ft.scale, _ft.scale, 0);
    }
}
