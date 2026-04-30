draw_clear(make_color_rgb(6, 7, 16));

var _cx = room_width * 0.5;
var _h  = room_height;

draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_font(main_font);

// Radial rays
for (var _ray = 0; _ray < 24; _ray++) {
    var _ang = (_ray / 24) * 360;
    draw_set_alpha(0.04); draw_set_color(make_color_rgb(100, 160, 255));
    draw_line_width(_cx, 220, _cx + lengthdir_x(1200, _ang), 220 + lengthdir_y(1200, _ang), 2);
}
draw_set_alpha(1);

// Logo
var _lW = sprite_get_width(spr_logo); var _lH = sprite_get_height(spr_logo);
draw_sprite_ext(spr_logo, 0, _cx, 200, min(700/_lW, 200/_lH), min(700/_lW, 200/_lH), 0, c_white, 1);

// Subtitle
draw_set_color(make_color_rgb(120, 140, 180));
draw_text_transformed(_cx, 330, "JACKPOT PUZZLE MACHINE", 1.1, 1.1, 0);

// Divider
draw_set_alpha(0.2); draw_set_color(make_color_rgb(100, 150, 255));
draw_line_width(_cx - 280, 368, _cx + 280, 368, 1); draw_set_alpha(1);

if (in_story_select) {
    draw_set_color(c_white);
    draw_text_transformed(_cx, 390, "STORY: SOLAR SYSTEM", 1.7, 1.7, 0);

    var _sunX = _cx;
    var _sunY = 620;
    gpu_set_blendmode(bm_add);
    draw_set_alpha(0.65 + abs(sin(current_time * 0.003)) * 0.25);
    draw_set_color(make_color_rgb(255, 215, 100));
    draw_circle_color(_sunX, _sunY, 42, c_yellow, make_color_rgb(255, 120, 40), false);
    gpu_set_blendmode(bm_normal);

    for (var i = 0; i < array_length(story_worlds); i++) {
        var _w = story_worlds[i];
        var _r = 130 + i * 80;
        draw_set_alpha(0.15); draw_set_color(make_color_rgb(130, 170, 255));
        draw_circle(_sunX, _sunY, _r, true);

        var _ang = _w.ang + current_time * 0.004 * (0.5 + i * 0.08);
        var _px = _sunX + lengthdir_x(_r, _ang);
        var _py = _sunY + lengthdir_y(_r, _ang);
        var _sel = (i == story_select_index);

        var _z = _sel ? (in_story_level_select ? 1.65 : 1.35) : 1.0;
        draw_set_alpha(_sel ? 1.0 : 0.72);
        draw_set_color(_sel ? make_color_rgb(120, 220, 255) : make_color_rgb(120, 180, 220));
        draw_circle(_px, _py, (_sel ? 22 : 16) * _z, false);
        if (_sel) {
            draw_set_alpha(0.65);
            draw_set_color(make_color_rgb(255, 230, 120));
            draw_circle(_px, _py, 30 * _z, true);
        }

        draw_set_alpha(_sel ? 1.0 : 0.65);
        draw_set_color(_sel ? c_white : make_color_rgb(180, 195, 220));
        draw_text_transformed(_px, _py - 32, _w.name, _sel ? 0.9 : 0.75, _sel ? 0.9 : 0.75, 0);
    }

    var _lvlCountLbl = story_world_level_counts[story_select_index];
    draw_set_alpha(0.9); draw_set_color(make_color_rgb(255, 220, 90));
    draw_text_transformed(_cx, 840, story_worlds[story_select_index].name + "   " + string(_lvlCountLbl) + " LEVELS", 1.0, 1.0, 0);

    if (in_story_level_select) {
        var _pw = 360;
        var _ph = 430;
        var _pxPanel = _cx + 420;
        var _pyPanel = 450;
        draw_set_alpha(0.30); draw_set_color(c_black);
        draw_roundrect_ext(_pxPanel + 8, _pyPanel + 8, _pxPanel + _pw + 8, _pyPanel + _ph + 8, 16, 16, false);
        draw_set_alpha(0.82); draw_set_color(make_color_rgb(20, 28, 52));
        draw_roundrect_ext(_pxPanel, _pyPanel, _pxPanel + _pw, _pyPanel + _ph, 16, 16, false);
        draw_set_alpha(0.65); draw_set_color(make_color_rgb(120, 170, 255));
        draw_roundrect_ext(_pxPanel, _pyPanel, _pxPanel + _pw, _pyPanel + _ph, 16, 16, true);
        draw_set_alpha(1.0); draw_set_color(c_white);
        draw_text_transformed(_pxPanel + _pw * 0.5, _pyPanel + 34, "SELECT LEVEL", 1.1, 1.1, 0);

        var _lvlCount = story_world_level_counts[story_select_index];
        for (var _li = 0; _li < _lvlCount; _li++) {
            var _yy = _pyPanel + 80 + _li * 54;
            var _selL = (_li == story_level_index);
            draw_set_alpha(_selL ? 0.32 : 0.12);
            draw_set_color(_selL ? make_color_rgb(110, 220, 255) : c_white);
            draw_roundrect_ext(_pxPanel + 24, _yy - 18, _pxPanel + _pw - 24, _yy + 18, 8, 8, false);
            draw_set_alpha(1.0); draw_set_color(_selL ? make_color_rgb(255, 225, 120) : make_color_rgb(190, 205, 235));
            draw_text_transformed(_pxPanel + _pw * 0.5, _yy, "LEVEL " + string(_li + 1), _selL ? 1.0 : 0.9, _selL ? 1.0 : 0.9, 0);
        }
    }

    draw_set_alpha(0.45); draw_set_color(make_color_rgb(255,214,102));
    if (in_story_level_select) {
        draw_text_transformed(_cx, _h - 60, "Up/Down Select Level   A Start Level   B Back", 0.85, 0.85, 0);
    } else {
        draw_text_transformed(_cx, _h - 60, "Left/Right Select Planet   A Open Levels   B Back", 0.85, 0.85, 0);
    }

    dialogue_draw();
    draw_set_alpha(1); draw_set_halign(fa_left); draw_set_valign(fa_top);
    exit;
}

// SETTINGS SCREEN
if (in_settings) {
    draw_set_color(c_white);
    draw_text_transformed(_cx, 380, "SETTINGS", 1.8, 1.8, 0);

    var _vals = [global.settings.ghostEnabled, global.settings.shakeEnabled];
    var _sy   = 460; var _gap = 70;
    for (var i = 0; i < array_length(settings_items); i++) {
        var _sel  = (i == settings_index);
        var _col  = _sel ? make_color_rgb(255, 220, 80) : make_color_rgb(180, 195, 220);
        var _valC = _vals[i] ? make_color_rgb(100, 230, 100) : make_color_rgb(220, 80, 80);
        draw_set_alpha(1); draw_set_color(_col);
        draw_text_transformed(_cx - 80, _sy + i*_gap, settings_items[i], 1.1, 1.1, 0);
        draw_set_color(_valC);
        draw_text_transformed(_cx + 100, _sy + i*_gap, _vals[i] ? "ON" : "OFF", 1.1, 1.1, 0);
    }
    draw_set_alpha(0.5); draw_set_color(make_color_rgb(255, 214, 102));
    draw_text_transformed(_cx, _h - 60, "Enter / Space / A  Toggle     Esc / B  Back", 0.9, 0.9, 0);
    draw_set_alpha(1); draw_set_halign(fa_left); draw_set_valign(fa_top);
    exit;
}

// MAIN MENU
var _bw2 = 500; var _bh2 = 68; var _bx1 = _cx - _bw2*0.5; var _bx2 = _cx + _bw2*0.5;
var _sy2 = 400; var _gap2 = 14;
for (var i = 0; i < array_length(menu_items); i++) {
    var _y1  = _sy2 + i * (_bh2 + _gap2);
    var _sel = (i == menu_index);
    draw_set_alpha(_sel ? 0.22 : 0.08);
    draw_set_color(_sel ? make_color_rgb(80,140,255) : make_color_rgb(255,255,255));
    draw_roundrect_ext(_bx1, _y1, _bx2, _y1+_bh2, 12, 12, false);
    draw_set_alpha(_sel ? 0.9 : 0.3);
    draw_set_color(_sel ? make_color_rgb(100,170,255) : make_color_rgb(50,60,90));
    draw_roundrect_ext(_bx1, _y1, _bx2, _y1+_bh2, 12, 12, true);
    if (_sel) {
        draw_set_alpha(1); draw_set_color(make_color_rgb(255,220,80));
        draw_roundrect_ext(_bx1, _y1, _bx1+4, _y1+_bh2, 2, 2, false);
    }
    draw_set_alpha(1);
    draw_set_color(_sel ? make_color_rgb(255,220,80) : make_color_rgb(180,195,220));
    draw_text_transformed(_cx, _y1 + _bh2*0.5, menu_items[i], _sel ? 1.15 : 1.0, _sel ? 1.15 : 1.0, 0);
}

// Hint
var _hy = _sy2 + array_length(menu_items) * (_bh2 + _gap2) + 24;
draw_set_alpha(0.6); draw_set_color(make_color_rgb(120,140,170));
draw_text_transformed(_cx, _hy, menu_hint[menu_index], 0.9, 0.9, 0);

// Footer
draw_set_alpha(0.4); draw_set_color(make_color_rgb(255,214,102));
draw_text_transformed(_cx, _h - 60, "Up/Down or Left Stick     Enter / Space / A  Select", 0.9, 0.9, 0);

draw_set_alpha(1); draw_set_halign(fa_left); draw_set_valign(fa_top);
