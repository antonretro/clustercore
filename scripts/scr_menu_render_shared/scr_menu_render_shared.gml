/// @module scr_menu_render_shared
/// Shared UI helpers and background rendering.

function draw_ui_panel(_x1, _y1, _x2, _y2, _alpha = 1.0) {
    var _w = _x2 - _x1; var _h2 = _y2 - _y1;
    if (sprite_exists(spr_ui_panel)) {
        draw_set_alpha(_alpha * 0.45);
        draw_sprite_stretched_ext(spr_ui_panel, 0, _x1 + 6, _y1 + 6, _w, _h2, c_black, _alpha * 0.45);
        draw_set_alpha(_alpha);
        draw_sprite_stretched_ext(spr_ui_panel, 0, _x1, _y1, _w, _h2, c_white, _alpha);
    } else {
        draw_set_alpha(_alpha * 0.82); draw_set_color(make_color_rgb(18, 26, 48));
        draw_roundrect_ext(_x1, _y1, _x2, _y2, 14, 14, false);
        draw_set_alpha(_alpha * 0.58); draw_set_color(make_color_rgb(120, 180, 255));
        draw_roundrect_ext(_x1, _y1, _x2, _y2, 14, 14, true);
    }
    draw_set_alpha(1);
}

function draw_ui_button(_x1, _y1, _x2, _y2, _selected = false) {
    var _w = _x2 - _x1; var _h2 = _y2 - _y1;
    if (sprite_exists(spr_ui_button)) {
        var _tint = _selected ? make_color_rgb(180, 210, 255) : c_white;
        draw_set_alpha(_selected ? 0.30 : 0.10);
        draw_sprite_stretched_ext(spr_ui_button, 0, _x1, _y1, _w, _h2, _tint, _selected ? 0.30 : 0.10);
        draw_set_alpha(1.0);
        draw_sprite_stretched_ext(spr_ui_button, 0, _x1, _y1, _w, _h2, _tint, 1.0);
        if (_selected) {
            draw_set_alpha(1); draw_set_color(make_color_rgb(255, 220, 80));
            draw_sprite_stretched_ext(spr_ui_button, 0, _x1, _y1, 4, _h2, make_color_rgb(255, 220, 80), 1.0);
        }
    } else {
        draw_set_alpha(_selected ? 0.22 : 0.08);
        draw_set_color(_selected ? make_color_rgb(80, 140, 255) : make_color_rgb(255, 255, 255));
        draw_roundrect_ext(_x1, _y1, _x2, _y2, 12, 12, false);
        draw_set_alpha(_selected ? 0.9 : 0.3);
        draw_set_color(_selected ? make_color_rgb(100, 170, 255) : make_color_rgb(50, 60, 90));
        draw_roundrect_ext(_x1, _y1, _x2, _y2, 12, 12, true);
        if (_selected) {
            draw_set_alpha(1); draw_set_color(make_color_rgb(255, 220, 80));
            draw_roundrect_ext(_x1, _y1, _x1 + 4, _y2, 2, 2, false);
        }
    }
    draw_set_alpha(1);
}

function draw_planet(_px, _py, _rad, _world, _unlocked, _sel, _drawname) {
    if (variable_struct_exists(_world, "sprite") && sprite_exists(_world.sprite)) {
        var _s = (_rad * 2.4) / sprite_get_width(_world.sprite);
        var _tint = _unlocked ? c_white : merge_color(c_white, c_black, 0.5);
        draw_set_alpha(_sel ? 1.0 : 0.7);
        draw_sprite_ext(_world.sprite, 0, _px, _py, _s, _s, 0, _tint, 1.0);
    } else {
        var _pColA = _unlocked ? _world.color_a : merge_color(_world.color_a, c_black, 0.7);
        var _pColB = _unlocked ? _world.color_b : merge_color(_world.color_b, c_black, 0.7);
        draw_circle_color(_px, _py, _rad, _pColA, _pColB, false);
        if (!_unlocked) {
            draw_set_color(c_white); draw_set_alpha(0.6);
            draw_text_transformed(_px, _py, "LOCKED", 0.5, 0.5, 0);
        }
        draw_set_alpha(0.38); draw_set_color(c_black);
        draw_circle(_px - _rad * 0.28, _py + _rad * 0.08, _rad * 0.82, false);
        draw_set_alpha(_sel ? 0.92 : 0.52);
        draw_set_color(_unlocked ? make_color_rgb(235, 250, 255) : c_gray);
        draw_circle(_px + _rad * 0.30, _py - _rad * 0.34, max(2, _rad * 0.18), false);
    }
    if (_drawname) {
        draw_set_alpha(_sel ? 1.0 : 0.62);
        draw_set_color(_sel ? c_white : make_color_rgb(180, 195, 220));
        draw_text_transformed(_px, _py - _rad - 22, _world.name, _sel ? 0.88 : 0.68, _sel ? 0.88 : 0.68, 0);
    }
    if (_sel) {
        gpu_set_blendmode(bm_add);
        draw_set_alpha(0.42); draw_set_color(make_color_rgb(255, 230, 120));
        draw_circle(_px, _py, _rad + 18, true);
        gpu_set_blendmode(bm_normal);
    }
}

function draw_card_icon(_cardIndex, _iconCX, _iconCY, _iconR, _sel, _cardAlpha) {
    if (_cardIndex == 0) {
        var _gRot = current_time * 0.0004;
        draw_set_color(_sel ? make_color_rgb(80, 180, 255) : make_color_rgb(60, 130, 210));
        draw_circle(_iconCX, _iconCY, _iconR, false);
        draw_set_color(_sel ? make_color_rgb(30, 80, 160) : make_color_rgb(20, 50, 120));
        draw_ellipse(_iconCX - _iconR, _iconCY - 16, _iconCX + _iconR, _iconCY + 16, true);
        draw_ellipse(_iconCX - _iconR * 0.6, _iconCY - 28, _iconCX + _iconR * 0.6, _iconCY + 28, true);
        draw_set_color(make_color_rgb(150, 220, 255));
        draw_set_alpha(_cardAlpha * 0.6);
        draw_ellipse(_iconCX + cos(_gRot) * _iconR * 0.5 - _iconR * 0.3, _iconCY - _iconR,
                     _iconCX + cos(_gRot) * _iconR * 0.5 + _iconR * 0.3, _iconCY + _iconR, true);
        draw_set_alpha(_cardAlpha * 0.75);
        draw_set_color(make_color_rgb(80, 200, 120));
        draw_circle(_iconCX - 18 + cos(_gRot * 0.7) * 10, _iconCY - 10, 14, false);
        draw_circle(_iconCX + 22 + sin(_gRot * 0.5) * 8,  _iconCY + 12, 9,  false);
    } else if (_cardIndex == 1) {
        draw_set_color(_sel ? make_color_rgb(180, 120, 255) : make_color_rgb(120, 70, 200));
        draw_circle(_iconCX, _iconCY, _iconR * 0.72, false);
        draw_set_color(_sel ? make_color_rgb(220, 180, 255) : make_color_rgb(160, 120, 220));
        draw_set_alpha(_cardAlpha * 0.65);
        draw_ellipse(_iconCX - _iconR, _iconCY - 14, _iconCX + _iconR, _iconCY + 14, true);
        draw_set_alpha(_cardAlpha * 0.35);
        draw_ellipse(_iconCX - _iconR * 0.76, _iconCY - 11, _iconCX + _iconR * 0.76, _iconCY + 11, true);
        draw_set_alpha(_cardAlpha * 0.5);
        draw_set_color(make_color_rgb(255, 200, 120));
        draw_circle(_iconCX + 16, _iconCY - 14, 10, false);
    } else if (_cardIndex == 2) {
        var _sqSz = 20; var _sqGap = 6;
        var _sqCols = [make_color_rgb(255,100,100), make_color_rgb(100,180,255), make_color_rgb(100,230,100),
                       make_color_rgb(255,220,80), make_color_rgb(200,100,255), make_color_rgb(255,150,60),
                       make_color_rgb(100,220,200), make_color_rgb(255,120,180), make_color_rgb(150,200,255)];
        var _sqTimer = floor(current_time / 220) mod 9;
        for (var _sq = 0; _sq < 9; _sq++) {
            var _sqX = _iconCX - (_sqSz + _sqGap) + (_sq mod 3) * (_sqSz + _sqGap);
            var _sqY = _iconCY - (_sqSz + _sqGap) + (_sq div 3) * (_sqSz + _sqGap);
            var _sqPulse = (_sq == _sqTimer) ? 1.3 : 1.0;
            var _sqA = (_sq == _sqTimer) ? 1.0 : 0.7;
            draw_set_alpha(_cardAlpha * _sqA);
            draw_set_color(_sqCols[_sq]);
            draw_rectangle(_sqX - _sqSz*0.5*_sqPulse, _sqY - _sqSz*0.5*_sqPulse,
                           _sqX + _sqSz*0.5*_sqPulse, _sqY + _sqSz*0.5*_sqPulse, false);
        }
    } else {
        var _gearRot = current_time * 0.0008;
        var _teeth = 8;
        draw_set_color(_sel ? make_color_rgb(255, 210, 80) : make_color_rgb(180, 160, 60));
        for (var _t = 0; _t < _teeth; _t++) {
            var _ta = (_t / _teeth) * 360 + _gearRot * 57.3;
            var _tx = _iconCX + lengthdir_x(_iconR * 0.82, _ta);
            var _ty = _iconCY + lengthdir_y(_iconR * 0.82, _ta);
            draw_set_alpha(_cardAlpha * 0.9);
            draw_rectangle(_tx - 7, _ty - 7, _tx + 7, _ty + 7, false);
        }
        draw_set_alpha(_cardAlpha);
        draw_set_color(_sel ? make_color_rgb(255, 210, 80) : make_color_rgb(180, 160, 60));
        draw_circle(_iconCX, _iconCY, _iconR * 0.58, false);
        draw_set_color(make_color_rgb(14, 20, 44));
        draw_circle(_iconCX, _iconCY, _iconR * 0.28, false);
    }
}

function menu_draw_background(_cx, _cy, _sw, _sh) {
    draw_set_alpha(1.0); draw_set_color(make_color_rgb(2, 4, 10));
    draw_rectangle(0, 0, _sw, _sh, false);
    var _starT = current_time * 0.00008;
    for (var i = 0; i < 80; i++) {
        var _px = (i * 197.5 + _starT * 120) % _sw;
        var _py = (i * 143.4 + _starT * 60) % _sh;
        draw_set_alpha(0.2 + (i % 4) * 0.15); draw_set_color(c_white);
        draw_circle(_px, _py, 1 + (i % 2), false);
    }
    // Radial rays
    for (var _ray = 0; _ray < 24; _ray++) {
        var _ang = (_ray / 24) * 360;
        draw_set_alpha(0.04); draw_set_color(make_color_rgb(100, 160, 255));
        draw_line_width(_cx, _cy, _cx + lengthdir_x(1200, _ang), _cy + lengthdir_y(1200, _ang), 2);
    }
    draw_set_alpha(1);
}
