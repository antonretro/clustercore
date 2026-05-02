/// @function menu_draw_main_deck(_cx, _cy, _sw, _sh, _menu_index)
function menu_draw_main_deck(_cx, _cy, _sw, _sh, _menu_index) {
    var _mainY = _cy - 60;
    var _cardW = 380;
    var _cardH = 480;
    var _gap   = 40;
    var _totalW = (_cardW * 3) + (_gap * 2);
    var _startX = _cx - _totalW * 0.5;

    var _cards = [
        { label: "STORY MODE",      sub: "Restore the corrupted galaxy.",             icon: asset_get_index("spr_story_icon"), locked: false },
        { label: "PLANET ENDLESS",  sub: global.endlessPlanetUnlocked  ? "Mining gravity & rotations." : "Complete TIN MOON to unlock.", icon: asset_get_index("spr_planet_endless"), locked: !global.endlessPlanetUnlocked },
        { label: "CLASSIC ENDLESS", sub: global.endlessClassicUnlocked ? "Pure arcade matching."         : "Complete RUST GARDEN to unlock.", icon: asset_get_index("spr_classic_endless"), locked: !global.endlessClassicUnlocked }
    ];

    for (var i = 0; i < 3; i++) {
        var _sel = (_menu_index == i);
        var _tx = _startX + i * (_cardW + _gap);
        var _ty = _mainY - _cardH * 0.5;
        
        var _scale = _sel ? (1.0 + abs(sin(current_time * 0.004)) * 0.04) : 1.0;
        var _cw = _cardW * _scale; var _ch = _cardH * _scale;
        var _x1 = _tx + _cardW*0.5 - _cw*0.5; var _y1 = _ty + _cardH*0.5 - _ch*0.5;
        var _x2 = _x1 + _cw; var _y2 = _y1 + _ch;
        
        // Card Shadow
        draw_set_alpha(0.4); draw_set_color(c_black);
        draw_roundrect_ext(_x1+10, _y1+10, _x2+10, _y2+10, 16, 16, false);

        // Card Glass
        draw_set_alpha(_sel ? 0.95 : 0.7);
        var _gradCol = _sel ? make_color_rgb(50, 90, 200) : make_color_rgb(25, 30, 50);
        draw_rectangle_colour(_x1, _y1, _x2, _y2, _gradCol, _gradCol, c_black, c_black, false);
        
        // Technical Grid Overlay
        draw_set_alpha(0.05); draw_set_color(c_white);
        for (var gx = _x1; gx < _x2; gx += 40) draw_line(gx, _y1, gx, _y2);
        for (var gy = _y1; gy < _y2; gy += 40) draw_line(_x1, gy, _x2, gy);
        
        // Outline & Selection Glow
        draw_set_alpha(_sel ? 1.0 : 0.3); draw_set_color(_sel ? c_white : make_color_rgb(140, 180, 255));
        draw_roundrect_ext(_x1, _y1, _x2, _y2, 12, 12, true);
        if (_sel) {
            draw_set_alpha(0.15); draw_set_color(make_color_rgb(100, 200, 255));
            draw_roundrect_ext(_x1-4, _y1-4, _x2+4, _y2+4, 16, 16, true);
        }
        
        // Icon Logic
        var _iconY = _y1 + 160;
        if (sprite_exists(_cards[i].icon)) {
            draw_sprite_ext(_cards[i].icon, 0, (_x1+_x2)*0.5, _iconY, 3.6, 3.6, 0, c_white, 1);
        } else {
            // High-end fallback visuals
            draw_set_alpha(0.8); draw_set_color(c_white);
            if (i == 0) { // Story fallback
                draw_circle((_x1+_x2)*0.5, _iconY, 100, true);
                draw_set_alpha(0.4); draw_circle((_x1+_x2)*0.5, _iconY, 60, false);
            } else if (i == 1) { // Planet fallback
                draw_circle((_x1+_x2)*0.5, _iconY, 120, true);
                draw_circle((_x1+_x2)*0.5, _iconY, 80, false);
            } else if (i == 2) { // Classic fallback
                for (var r=0; r<3; r++) for (var c=0; c<3; c++) 
                    draw_rectangle((_x1+_x2)*0.5-60+c*44, _iconY-60+r*44, (_x1+_x2)*0.5-24+c*44, _iconY-24+r*44, false);
            }
        }
        
        // Labels
        draw_set_halign(fa_center); draw_set_color(c_white);
        draw_text_transformed((_x1+_x2)*0.5, _y1 + 320, _cards[i].label, 1.8, 1.8, 0);
        draw_set_alpha(0.6);
        draw_text_transformed((_x1+_x2)*0.5, _y1 + 380, _cards[i].sub, 0.9, 0.9, 0);
    }
}

/// @function menu_draw_extras_bar(_cx, _cy, _sw, _sh, _menu_index)
function menu_draw_extras_bar(_cx, _cy, _sw, _sh, _menu_index) {
    var _barY = _sh - 120;
    var _iconSize = 140;
    var _barGap = 110;
    var _barW = (_iconSize * 3) + (_barGap * 2);
    var _barX = _cx - _barW * 0.5;

    // Bottom Bar Glass Base
    draw_set_alpha(0.4); draw_set_color(c_black);
    draw_roundrect_ext(_cx - _barW*0.55, _barY - 80, _cx + _barW*0.55, _barY + 80, 50, 50, false);
    draw_set_alpha(0.1); draw_set_color(c_white);
    draw_roundrect_ext(_cx - _barW*0.55, _barY - 80, _cx + _barW*0.55, _barY + 80, 50, 50, true);

    var _extras = [
        { label: "ENCYCLOPEDIA", icon: asset_get_index("spr_encyclopedia"), color: make_color_rgb(100, 255, 180) },
        { label: "ACHIEVEMENTS", icon: asset_get_index("spr_achievements"), color: make_color_rgb(255, 214, 102) },
        { label: "SETTINGS",     icon: asset_get_index("spr_settings_icon"), color: make_color_rgb(180, 200, 255) }
    ];

    for (var i = 0; i < 3; i++) {
        var _idx = 3 + i;
        var _sel = (_menu_index == _idx);
        var _exX = _barX + i * (_iconSize + _barGap) + _iconSize*0.5;
        var _exY = _barY;
        
        var _exScale = _sel ? 1.5 : 1.0;
        
        if (_sel) {
            draw_set_alpha(0.3); draw_set_color(_extras[i].color);
            draw_circle(_exX, _exY, 80, false);
        }
        
        draw_set_alpha(_sel ? 1.0 : 0.5);
        draw_set_color(_sel ? _extras[i].color : c_white);
        draw_circle(_exX, _exY, (_iconSize*0.5) * _exScale, true);
        
        if (sprite_exists(_extras[i].icon)) {
            draw_sprite_ext(_extras[i].icon, 0, _exX, _exY, 1.2 * _exScale, 1.2 * _exScale, 0, c_white, _sel ? 1.0 : 0.6);
        } else {
            draw_set_halign(fa_center); draw_set_valign(fa_middle);
            draw_text_transformed(_exX, _exY, "?", 3.0 * _exScale, 3.0 * _exScale, 0);
            draw_set_valign(fa_top);
        }
        
        if (_sel) {
            draw_set_color(c_white); draw_set_alpha(1.0);
            draw_text_transformed(_exX, _exY - 110, _extras[i].label, 1.1, 1.1, 0);
        }
    }
}

/// @function menu_draw_settings(_cx, _cy, _sw, _sh, _settings_index, _settings_items)
function menu_draw_settings(_cx, _cy, _sw, _sh, _settings_index, _settings_items) {
    draw_set_alpha(0.95); draw_set_color(make_color_rgb(5, 10, 20)); draw_rectangle(0, 0, _sw, _sh, false);
    
    // Header
    draw_set_halign(fa_center); draw_set_color(c_white);
    draw_text_transformed(_cx, 120, "SYSTEM CONFIGURATION", 4.5, 4.5, 0);
    draw_set_alpha(0.3); draw_set_color(make_color_rgb(100, 200, 255));
    draw_rectangle(_cx - 400, 180, _cx + 400, 184, false);
    
    var _vals = [global.settings.ghostEnabled, global.settings.shakeEnabled];
    var _startY = 350;
    var _panelW = 800; var _panelH = 120;
    
    for (var i = 0; i < 2; i++) {
        var _py = _startY + i * 160;
        var _isSel = (i == _settings_index);
        
        // Option Panel
        draw_set_alpha(_isSel ? 0.2 : 0.1); draw_set_color(c_white);
        draw_roundrect_ext(_cx - _panelW*0.5, _py - _panelH*0.5, _cx + _panelW*0.5, _py + _panelH*0.5, 20, 20, false);
        draw_set_alpha(_isSel ? 0.6 : 0.2);
        draw_roundrect_ext(_cx - _panelW*0.5, _py - _panelH*0.5, _cx + _panelW*0.5, _py + _panelH*0.5, 20, 20, true);
        
        // Label
        draw_set_halign(fa_left); draw_set_alpha(1.0);
        draw_set_color(_isSel ? make_color_rgb(255, 220, 100) : c_white);
        draw_text_transformed(_cx - _panelW*0.5 + 40, _py, _settings_items[i], 2.0, 2.0, 0);
        
        // Toggle Switch
        var _swX = _cx + _panelW*0.5 - 120;
        draw_set_color(c_black); draw_set_alpha(0.5);
        draw_roundrect_ext(_swX - 60, _py - 25, _swX + 60, _py + 25, 25, 25, false);
        
        if (_vals[i]) {
            draw_set_color(make_color_rgb(100, 255, 150)); draw_set_alpha(0.8);
            draw_circle(_swX + 30, _py, 20, false);
            draw_set_halign(fa_center);
            draw_text_transformed(_swX - 25, _py, "ON", 1.2, 1.2, 0);
        } else {
            draw_set_color(make_color_rgb(255, 100, 100)); draw_set_alpha(0.8);
            draw_circle(_swX - 30, _py, 20, false);
            draw_set_halign(fa_center);
            draw_text_transformed(_swX + 25, _py, "OFF", 1.2, 1.2, 0);
        }
    }
    
    // Settings Hint
    draw_set_halign(fa_center); draw_set_color(c_white); draw_set_alpha(0.5);
    draw_text_transformed(_cx, _sh - 120, "[SPACE] TOGGLE    [B] RETURN", 1.2, 1.2, 0);
}

/// @function menu_draw_story_map(_cx, _cy, _sw, _sh, _story_select_index, _story_worlds)
function menu_draw_story_map(_cx, _cy, _sw, _sh, _story_select_index, _story_worlds) {
    draw_set_alpha(0.95); draw_set_color(c_black); draw_rectangle(0, 0, _sw, _sh, false);
    
    // 1. Central Sun
    draw_set_alpha(0.3); draw_set_color(c_yellow);
    draw_circle(_cx, _cy, 120 + sin(current_time*0.002)*10, false);
    draw_set_alpha(1.0); draw_set_color(c_white);
    draw_circle(_cx, _cy, 60, false);
    
    // 2. Orbital Rings & Planets
    for (var i = 0; i < array_length(_story_worlds); i++) {
        var _w = _story_worlds[i];
        var _dist = _sh * _w.orbit;
        var _sel = (_story_select_index == i);
        
        // Draw Ring
        draw_set_alpha(_sel ? 0.3 : 0.1); draw_set_color(c_white);
        draw_circle(_cx, _cy, _dist, true);
        
        // Draw Planet position
        var _px = _cx + lengthdir_x(_dist, _w.ang + current_time*0.01);
        var _py = _cy + lengthdir_y(_dist, _w.ang + current_time*0.01);
        
        if (_sel) {
            draw_set_alpha(0.4); draw_set_color(c_white);
            draw_circle(_px, _py, _w.size * 2.5, false);
            draw_set_alpha(1.0);
            draw_text_transformed(_px, _py - _w.size - 50, _w.name, 1.5, 1.5, 0);
        }
        
        if (sprite_exists(_w.sprite)) {
            var _s = (_w.size * 2) / sprite_get_width(_w.sprite);
            draw_sprite_ext(_w.sprite, 0, _px, _py, _s, _s, current_time * 0.02, c_white, 1.0);
        } else {
            draw_set_color(_w.color_a);
            draw_circle(_px, _py, _w.size, false);
        }
        draw_set_color(c_white); draw_set_alpha(0.3);
        draw_circle(_px, _py, _w.size, true);
    }
    
    // 3. Mission Panel
    var _mw = 500; var _mh = 600;
    var _mx1 = _sw - _mw - 60; var _my1 = _cy - _mh*0.5;
    var _mx2 = _mx1 + _mw; var _my2 = _my1 + _mh;
    
    draw_set_alpha(0.85); draw_set_color(make_color_rgb(10, 20, 40));
    draw_rectangle(_mx1, _my1, _mx2, _my2, false);
    draw_set_alpha(0.4); draw_set_color(c_white);
    draw_rectangle(_mx1, _my1, _mx2, _my2, true);
    
    var _selWorld = _story_worlds[_story_select_index];
    draw_set_halign(fa_center); draw_set_alpha(1.0);
    draw_set_color(make_color_rgb(255, 214, 102));
    draw_text_transformed(_mx1 + _mw*0.5, _my1 + 40, "MISSION DATA", 2.5, 2.5, 0);
    draw_set_color(c_white);
    draw_text_transformed(_mx1 + _mw*0.5, _my1 + 100, _selWorld.name, 2.0, 2.0, 0);
    
    draw_set_halign(fa_left);
    draw_text_transformed(_mx1 + 40, _my1 + 180, "THREAT: LOW-ORBIT CORRUPTION", 1.0, 1.0, 0);
    draw_text_transformed(_mx1 + 40, _my1 + 220, "SECTOR: " + string(_story_select_index + 1) + "-A", 1.0, 1.0, 0);
    
    draw_set_alpha(0.6);
    var _flavor = "Atmospheric cleanup required. Corrupted core\ndetected in the subterranean layers. Fire the\nrefabricator to begin extraction.";
    draw_text_transformed(_mx1 + 40, _my1 + 300, _flavor, 1.0, 1.0, 0);
    
    draw_set_halign(fa_center); draw_set_alpha(1.0);
    draw_set_color(make_color_rgb(100, 255, 150));
    draw_text_transformed(_mx1 + _mw*0.5, _my2 - 60, "[A] INITIATE DROP", 1.5, 1.5, 0);
}
