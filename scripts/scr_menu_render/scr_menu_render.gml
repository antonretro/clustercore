/// @module scr_menu_render
/// Menu rendering — one function per screen. Shared helpers at top.

// ═══════════════════════════════════════════════════════════════════════════
// SHARED UI HELPERS
// ═══════════════════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════════════════
// BACKGROUND — shared starfield + radial rays
// ═══════════════════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════════════════
// TITLE SCREEN
// ═══════════════════════════════════════════════════════════════════════════

function menu_draw_title(_cx, _cy, _sw, _sh) {
    draw_set_halign(fa_center);
    var _logoScale = 1.8 + sin(current_time * 0.001) * 0.08;
    if (sprite_exists(spr_logo)) {
        draw_sprite_ext(spr_logo, 0, _cx, _cy - 120, _logoScale, _logoScale, 0, c_white, 1.0);
    } else {
        draw_set_color(c_white);
        draw_text_transformed(_cx, _cy - 120, "CLUSTER CORE", 8.0 * _logoScale, 8.0 * _logoScale, 0);
    }
    draw_set_color(make_color_rgb(180, 210, 255));
    draw_text_transformed(_cx, _cy + 20, "GALACTIC RESTORATION UNIT", 2.5, 2.5, 0);

    if (in_save_slots && !is_loading) {
        menu_draw_save_slots(_cx, _cy, _sw, _sh);
        return;
    }
    if (is_loading) {
        menu_draw_loading_bar(_cx, _cy);
        return;
    }

    draw_set_alpha(0.5 + abs(sin(current_time * 0.003)) * 0.5);
    draw_set_color(make_color_rgb(255, 220, 100));
    draw_text_transformed(_cx, _cy + 150, "PRESS SPACE TO START", global.TXT_H2, global.TXT_H2, 0);
}

function menu_draw_save_slots(_cx, _cy, _sw, _sh) {
    draw_set_alpha(0.85); draw_set_color(make_color_rgb(2, 6, 15));
    draw_rectangle(0, 0, _sw, _sh, false);
    draw_set_alpha(0.05); draw_set_color(c_white);
    for (var i = 0; i < _sh; i += 4) draw_line(0, i, _sw, i);

    draw_set_halign(fa_center); draw_set_alpha(1.0); draw_set_color(make_color_rgb(180, 210, 255));
    draw_text_transformed(_cx, 120, "AUTHORIZED PILOT SELECTION", 3.5, 3.5, 0);

    var _cardW = 480; var _cardH = 650; var _gap = 50;
    var _startX = _cx - (_cardW * 1.5 + _gap);
    for (var i = 0; i < 3; i++) {
        var _slot = save_slots[i];
        var _sx = _startX + i * (_cardW + _gap);
        var _sy = _cy - 200;
        var _sel = (save_slot_index == i);
        var _hoverY = _sel ? sin(current_time * 0.005) * 15 : 0;
        var _ty = _sy + _hoverY;

        draw_set_alpha(0.5); draw_set_color(c_black);
        draw_roundrect_ext(_sx + 10, _ty + 10, _sx + _cardW + 10, _ty + _cardH + 10, 30, 30, false);

        draw_set_alpha(_sel ? 0.95 : 0.7);
        var _c1 = _sel ? make_color_rgb(20, 35, 60) : make_color_rgb(10, 15, 25);
        draw_rectangle_colour(_sx, _ty, _sx + _cardW, _ty + _cardH, _c1, _c1, c_black, c_black, false);

        var _borderCol = _sel ? make_color_rgb(100, 255, 150) : make_color_rgb(80, 120, 180);
        draw_set_alpha(_sel ? 1.0 : 0.4); draw_set_color(_borderCol);
        draw_roundrect_ext(_sx, _ty, _sx + _cardW, _ty + _cardH, 20, 20, true);

        if (_sel) {
            gpu_set_blendmode(bm_add);
            draw_set_alpha(0.2 + abs(sin(current_time * 0.01)) * 0.1);
            draw_roundrect_ext(_sx - 4, _ty - 4, _sx + _cardW + 4, _ty + _cardH + 4, 24, 24, true);
            gpu_set_blendmode(bm_normal);
        }

        draw_set_alpha(0.2); draw_set_color(c_white);
        draw_rectangle(_sx + 30, _ty + 30, _sx + _cardW - 30, _ty + 220, false);
        draw_set_alpha(0.8); draw_set_halign(fa_center);
        draw_set_color(_sel ? make_color_rgb(255, 214, 102) : c_white);
        draw_text_transformed(_sx + _cardW * 0.5, _ty + 240, _slot.name, 2.2, 2.2, 0);

        var _dy = _ty + 320; draw_set_halign(fa_left);
        var _labels = ["SECTORS CLEARED", "CORE STABILITY", "WALLET BALANCE", "LAST SYNC"];
        var _vals = [string(_slot.progress) + "%", "STABLE", string(_slot.shards) + " SH", _slot.playtime];
        for (var d = 0; d < 4; d++) {
            draw_set_alpha(0.4); draw_set_color(c_white);
            draw_text_transformed(_sx + 50, _dy + d * 55, _labels[d], 0.9, 0.9, 0);
            draw_set_alpha(0.9); draw_set_color(_sel ? c_white : make_color_rgb(180, 210, 255));
            draw_text_transformed(_sx + 240, _dy + d * 55, ":: " + _vals[d], 1.1, 1.1, 0);
        }

        if (_sel) {
            draw_set_halign(fa_center); draw_set_alpha(0.8 + abs(sin(current_time * 0.01)) * 0.2);
            draw_set_color(make_color_rgb(100, 255, 150));
            draw_text_transformed(_sx + _cardW * 0.5, _ty + _cardH - 50, ">> PRESS A TO SYNC <<", 1.4, 1.4, 0);
        }
    }
    draw_set_halign(fa_center); draw_set_alpha(0.4); draw_set_color(c_white);
    draw_text_transformed(_cx, _sh - 80, "[ARROWS] NAVIGATE PROFILES    [B] LOGOUT", 1.2, 1.2, 0);
}

function menu_draw_loading_bar(_cx, _cy) {
    var _p = loading_timer / 90;
    var _bw = 400; var _bh = 10;
    draw_set_alpha(0.2); draw_set_color(c_white);
    draw_rectangle(_cx - _bw, _cy + 140, _cx + _bw, _cy + 140 + _bh, false);
    draw_set_alpha(0.8); draw_set_color(make_color_rgb(100, 255, 150));
    draw_rectangle(_cx - _bw, _cy + 140, _cx - _bw + (_bw * 2 * _p), _cy + 140 + _bh, false);
    draw_set_halign(fa_center); draw_set_color(c_white); draw_set_alpha(0.8);
    var _loadText = "SYNCING SYSTEM DATA...";
    if (_p > 0.7) _loadText = "PILOT AUTHORIZED.";
    draw_text_transformed(_cx, _cy + 180, _loadText, 1.5, 1.5, 0);
}

// ═══════════════════════════════════════════════════════════════════════════
// MAIN MENU DECK — 3 cards (top) + 7-icon toolbar (bottom)
// ═══════════════════════════════════════════════════════════════════════════

function menu_draw_main_deck(_cx, _cy, _sw, _sh) {
    var _cardW = 380; var _cardH = 480; var _gap = 40;
    var _startX = _cx - ((_cardW * 3 + _gap * 2) * 0.5);
    var _mainY = _cy - 80 - _cardH * 0.5;

    // Logo
    if (sprite_exists(spr_logo)) {
        var _lW = sprite_get_width(spr_logo); var _lH = sprite_get_height(spr_logo);
        draw_sprite_ext(spr_logo, 0, _cx, 140, min(600/_lW, 160/_lH), min(600/_lW, 160/_lH), 0, c_white, 1);
    } else {
        draw_set_halign(fa_center); draw_set_color(c_white);
        draw_text_transformed(_cx, 120, "CLUSTER CORE", 6.0, 6.0, 0);
    }
    draw_set_color(make_color_rgb(120, 140, 180));
    draw_text_transformed(_cx, 240, "JACKPOT PUZZLE MACHINE", 1.1, 1.1, 0);
    draw_set_alpha(0.2); draw_set_color(make_color_rgb(100, 150, 255));
    draw_line_width(_cx - 280, 270, _cx + 280, 270, 1); draw_set_alpha(1);

    // Wallet
    draw_set_alpha(0.80); draw_set_color(make_color_rgb(180, 230, 255));
    draw_set_halign(fa_right);
    draw_text_transformed(_cx + 280, _mainY - 20, "SHARDS " + string(global.walletShards) + "   GEMS " + string(global.walletGems), global.TXT_SMALL, global.TXT_SMALL, 0);

    // 3 Mode Cards
    var _cardIcons = [spr_story_icon, spr_planet_endless, spr_classic_endless];
    for (var i = 0; i < 3; i++) {
        var _isSel = (menu_index == i);
        var _xx = _startX + i * (_cardW + _gap);
        var _off = _isSel ? -20 : 0;

        // Card shadow
        draw_set_alpha(_isSel ? 0.5 : 0.25); draw_set_color(c_black);
        draw_roundrect_ext(_xx + 8, _mainY + _off + 8, _xx + _cardW + 8, _mainY + _cardH + _off + 8, 16, 16, false);

        // Card base
        draw_set_alpha(_isSel ? 0.95 : 0.7);
        var _gradCol = _isSel ? make_color_rgb(25, 45, 80) : make_color_rgb(12, 18, 35);
        draw_rectangle_colour(_xx, _mainY + _off, _xx + _cardW, _mainY + _cardH + _off, _gradCol, _gradCol, c_black, c_black, false);

        // Grid overlay
        draw_set_alpha(0.04); draw_set_color(c_white);
        for (var gx = _xx; gx < _xx + _cardW; gx += 40) draw_line(gx, _mainY + _off, gx, _mainY + _cardH + _off);
        for (var gy = _mainY + _off; gy < _mainY + _cardH + _off; gy += 40) draw_line(_xx, gy, _xx + _cardW, gy);

        // Border
        draw_set_alpha(1); draw_set_color(_isSel ? make_color_rgb(100, 255, 150) : c_white);
        draw_roundrect_ext(_xx, _mainY + _off, _xx + _cardW, _mainY + _cardH + _off, 16, 16, true);

        // Selection glow
        if (_isSel) {
            gpu_set_blendmode(bm_add);
            draw_set_alpha(0.15 + abs(sin(current_time * 0.004)) * 0.06);
            draw_set_color(make_color_rgb(100, 200, 255));
            draw_roundrect_ext(_xx - 6, _mainY + _off - 6, _xx + _cardW + 6, _mainY + _cardH + _off + 6, 22, 22, true);
            gpu_set_blendmode(bm_normal);
        }

        // Icon area
        var _iconCX = _xx + _cardW * 0.5;
        var _iconCY = _mainY + _off + 160;
        var _iconR = 54;
        draw_set_alpha(1);
        if (sprite_exists(_cardIcons[i])) {
            draw_sprite_ext(_cardIcons[i], 0, _iconCX, _iconCY, 3.0, 3.0, 0, c_white, 1);
        } else {
            draw_card_icon(i, _iconCX, _iconCY, _iconR, _isSel, 1.0);
        }

        // Label
        draw_set_halign(fa_center); draw_set_color(_isSel ? make_color_rgb(255, 220, 100) : c_white);
        draw_text_transformed(_xx + _cardW * 0.5, _mainY + 340 + _off, menu_items[i], 2.0, 2.0, 0);

        // Subtitle
        draw_set_alpha(0.6);
        draw_text_transformed(_xx + _cardW * 0.5, _mainY + 390 + _off, menu_hint[i], 0.9, 0.9, 0);
    }

    // ── Bottom Toolbar (7 icons) ──
    var _iconSize = 100; var _barGap = 40;
    var _totalBarW = (_iconSize * 7) + (_barGap * 6);
    var _barX = _cx - _totalBarW * 0.5;
    var _barY = _sh - 150;

    var _toolbarSprites = [
        spr_ui_panel,           // SAVE (Placeholder)
        spr_gemshard,           // SHARDS
        spr_ui_panel,           // INVENTORY
        spr_ui_button,          // SHOP
        spr_encyclopedia_icon,  // ENCYCLOPEDIA
        spr_achievements_icon,  // ACHIEVEMENTS
        spr_settings_icon       // SETTINGS
    ];
    var _toolbarColors = [c_lime, c_orange, c_aqua, c_fuchsia, c_white, c_yellow, c_silver];

    // Bar glass base
    draw_set_alpha(0.15); draw_set_color(c_white);
    draw_roundrect_ext(_barX - 30, _barY - 70, _barX + _totalBarW + 30, _barY + _iconSize + 30, 30, 30, false);

    for (var i = 0; i < 7; i++) {
        var _idx = 3 + i;
        var _isSel = (menu_index == _idx);
        var _exX = _barX + i * (_iconSize + _barGap) + _iconSize * 0.5;
        var _exY = _barY + _iconSize * 0.5;

        // Selection glow
        if (_isSel) {
            draw_set_alpha(0.3); draw_set_color(_toolbarColors[i]);
            draw_circle(_exX, _exY, _iconSize * 0.65, false);
        }

        // Icon background
        draw_set_alpha(_isSel ? 0.25 : 0.08); draw_set_color(c_white);
        draw_roundrect_ext(_exX - _iconSize * 0.5, _exY - _iconSize * 0.5,
                          _exX + _iconSize * 0.5, _exY + _iconSize * 0.5, 12, 12, false);
        draw_set_alpha(_isSel ? 1.0 : 0.35); draw_set_color(_isSel ? _toolbarColors[i] : c_white);
        draw_roundrect_ext(_exX - _iconSize * 0.5, _exY - _iconSize * 0.5,
                          _exX + _iconSize * 0.5, _exY + _iconSize * 0.5, 12, 12, true);

        // Sprite or fallback dot
        if (_toolbarSprites[i] != -1 && sprite_exists(_toolbarSprites[i])) {
            draw_sprite_ext(_toolbarSprites[i], 0, _exX, _exY, 1.0, 1.0, 0, c_white, _isSel ? 1.0 : 0.5);
        } else {
            draw_set_color(_toolbarColors[i]);
            draw_circle(_exX, _exY, _iconSize * 0.2, false);
        }

        // Label above selected
        if (_isSel) {
            draw_set_halign(fa_center); draw_set_alpha(1.0); draw_set_color(c_white);
            draw_text_transformed(_exX, _barY - 30, menu_items[_idx], 1.2, 1.2, 0);
        }
    }

    // Hint
    var _curHint = menu_hint[menu_index];
    draw_set_halign(fa_center); draw_set_alpha(0.5); draw_set_color(c_white);
    draw_text_transformed(_cx, _sh - 220, _curHint, 1.1, 1.1, 0);
}

// ═══════════════════════════════════════════════════════════════════════════
// SETTINGS SCREEN
// ═══════════════════════════════════════════════════════════════════════════

function menu_draw_settings(_cx, _cy, _sw, _sh) {
    draw_set_alpha(0.95); draw_set_color(make_color_rgb(3, 6, 16)); draw_rectangle(0, 0, _sw, _sh, false);

    // Starfield
    var _starT = current_time * 0.00008;
    for (var i = 0; i < 40; i++) {
        var _pxs = (i * 173.3 + _starT * 100) % _sw;
        var _pys = (i * 217.7 + _starT * 55) % _sh;
        draw_set_alpha(0.1 + (i % 3) * 0.1); draw_set_color(c_white);
        draw_circle(_pxs, _pys, 1 + (i % 2), false);
    }
    draw_set_alpha(1);

    // Back button
    var _backSprite = asset_get_index("spr_back_icon");
    if (_backSprite != -1 && sprite_exists(_backSprite)) {
        draw_set_alpha(0.6);
        draw_sprite_ext(_backSprite, 0, 50, 50, 0.55, 0.55, 0, c_white, 1);
    }
    draw_set_alpha(0.5); draw_set_color(make_color_rgb(140, 190, 255));
    draw_text_transformed(76, 48, "B - BACK", global.TXT_SMALL, global.TXT_SMALL, 0);

    draw_set_halign(fa_center); draw_set_color(c_white);
    draw_text_transformed(_cx, 120, "SYSTEM CONFIGURATION", global.TXT_H1, global.TXT_H1, 0);
    draw_set_alpha(0.3); draw_set_color(make_color_rgb(100, 200, 255));
    draw_rectangle(_cx - 400, 190, _cx + 400, 194, false);

    var _vals = [global.settings.ghostEnabled, global.settings.shakeEnabled];
    var _startY = 360;
    var _panelW = 800; var _panelH = 120;

    for (var i = 0; i < 2; i++) {
        var _py = _startY + i * 170;
        var _isSel = (i == settings_index);

        // Panel background
        draw_set_alpha(_isSel ? 0.22 : 0.08); draw_set_color(c_white);
        draw_roundrect_ext(_cx - _panelW * 0.5, _py - _panelH * 0.5,
                          _cx + _panelW * 0.5, _py + _panelH * 0.5, 16, 16, false);
        draw_set_alpha(_isSel ? 0.55 : 0.18);
        draw_set_color(_isSel ? make_color_rgb(140, 200, 255) : make_color_rgb(80, 100, 140));
        draw_roundrect_ext(_cx - _panelW * 0.5, _py - _panelH * 0.5,
                          _cx + _panelW * 0.5, _py + _panelH * 0.5, 16, 16, true);

        // Selection glow
        if (_isSel) {
            gpu_set_blendmode(bm_add);
            draw_set_alpha(0.08 + abs(sin(current_time * 0.004)) * 0.04);
            draw_set_color(make_color_rgb(100, 200, 255));
            draw_roundrect_ext(_cx - _panelW * 0.5 - 4, _py - _panelH * 0.5 - 4,
                              _cx + _panelW * 0.5 + 4, _py + _panelH * 0.5 + 4, 20, 20, true);
            gpu_set_blendmode(bm_normal);
        }

        draw_set_halign(fa_left); draw_set_alpha(1.0);
        draw_set_color(_isSel ? make_color_rgb(255, 220, 100) : c_white);
        draw_text_transformed(_cx - _panelW * 0.5 + 40, _py, settings_items[i], global.TXT_H2, global.TXT_H2, 0);

        // Toggle switch
        var _swX = _cx + _panelW * 0.5 - 120;
        draw_set_color(make_color_rgb(10, 15, 30)); draw_set_alpha(0.6);
        draw_roundrect_ext(_swX - 70, _py - 28, _swX + 70, _py + 28, 28, 28, false);

        if (_vals[i]) {
            draw_set_color(make_color_rgb(100, 255, 150)); draw_set_alpha(0.85);
            draw_roundrect_ext(_swX + 10, _py - 20, _swX + 62, _py + 20, 18, 18, false);
            draw_set_halign(fa_center);
            draw_text_transformed(_swX - 22, _py, "ON", global.TXT_H4, global.TXT_H4, 0);
        } else {
            draw_set_color(make_color_rgb(255, 100, 100)); draw_set_alpha(0.85);
            draw_roundrect_ext(_swX - 62, _py - 20, _swX - 10, _py + 20, 18, 18, false);
            draw_set_halign(fa_center);
            draw_text_transformed(_swX + 22, _py, "OFF", global.TXT_H4, global.TXT_H4, 0);
        }
    }

    draw_set_halign(fa_center); draw_set_color(c_white); draw_set_alpha(0.45);
    draw_text_transformed(_cx, _sh - 80, "SPACE  Toggle    B  Return", global.TXT_H4, global.TXT_H4, 0);
}

// ═══════════════════════════════════════════════════════════════════════════
// STORY SELECT — Glassmorphism Side Panel + Solar System
// ═══════════════════════════════════════════════════════════════════════════

function menu_draw_story_select(_cx, _cy, _sw, _sh) {
    // Background
    draw_set_alpha(1.0); draw_set_color(make_color_rgb(2, 4, 10));
    draw_rectangle(0, 0, _sw, _sh, false);

    // Starfield
    var _starT = current_time * 0.00008;
    for (var i = 0; i < 60; i++) {
        var _pxs = (i * 197.5 + _starT * 140) % _sw;
        var _pys = (i * 143.4 + _starT * 70) % _sh;
        draw_set_alpha(0.15 + (i % 5) * 0.12); draw_set_color(c_white);
        draw_circle(_pxs, _pys, 1 + (i % 2), false);
    }

    // Scanning grid overlay
    draw_set_alpha(0.06); draw_set_color(make_color_rgb(100, 200, 255));
    for (var gx = 0; gx < _sw; gx += 120) draw_line(gx, 0, gx, _sh);
    for (var gy = 0; gy < _sh; gy += 120) draw_line(0, gy, _sw, gy);
    draw_set_alpha(1);

    // ═══ LEFT PANEL — Glassmorphism ═══
    var _panelW = 440;
    var _panelX1 = 20;
    var _panelX2 = _panelX1 + _panelW;
    var _panelY1 = 80;
    var _panelY2 = _sh - 40;

    // Panel shadow + base
    draw_set_alpha(0.55); draw_set_color(c_black);
    draw_roundrect_ext(_panelX1 + 8, _panelY1 + 8, _panelX2 + 8, _panelY2 + 8, 22, 22, false);

    // Panel gradient background
    var _pTop = make_color_rgb(14, 24, 55);
    var _pBot = make_color_rgb(6, 10, 28);
    draw_set_alpha(0.88);
    draw_rectangle_colour(_panelX1, _panelY1, _panelX2, _panelY2, _pTop, _pTop, _pBot, _pBot, false);

    // Grid texture inside panel
    draw_set_alpha(0.03); draw_set_color(c_white);
    for (var gpx = _panelX1 + 20; gpx < _panelX2; gpx += 40)
        draw_line(gpx, _panelY1, gpx, _panelY2);
    for (var gpy = _panelY1 + 20; gpy < _panelY2; gpy += 40)
        draw_line(_panelX1, gpy, _panelX2, gpy);

    // Panel border
    draw_set_alpha(0.5); draw_set_color(make_color_rgb(140, 190, 255));
    draw_roundrect_ext(_panelX1, _panelY1, _panelX2, _panelY2, 22, 22, true);

    // Panel inner glow (left edge)
    gpu_set_blendmode(bm_add);
    draw_set_alpha(0.12); draw_set_color(make_color_rgb(100, 200, 255));
    draw_roundrect_ext(_panelX1 + 2, _panelY1 + 2, _panelX2 - 2, _panelY2 - 2, 20, 20, true);
    gpu_set_blendmode(bm_normal);

    // Back button
    var _backX = _panelX1 + 34;
    var _backY = _panelY1 + 36;
    var _backSprite = asset_get_index("spr_back_icon");
    if (_backSprite != -1 && sprite_exists(_backSprite)) {
        draw_sprite_ext(_backSprite, 0, _backX, _backY, 0.55, 0.55, 0, c_white, 0.6);
    } else {
        draw_set_alpha(0.6); draw_set_color(make_color_rgb(140, 190, 255));
        draw_triangle(_backX, _backY, _backX + 16, _backY - 10, _backX + 16, _backY + 10, false);
    }
    draw_set_alpha(0.5); draw_set_color(make_color_rgb(140, 190, 255));
    draw_text_transformed(_backX + 24, _backY, "B - BACK", global.TXT_SMALL, global.TXT_SMALL, 0);

    // ═══ Selected World Info ═══
    var _w = story_worlds[story_select_index];
    var _unlocked = story_progress_is_unlocked(story_select_index, 0);
    var _infoY = _panelY1 + 90;

    // Planet mini preview
    if (variable_struct_exists(_w, "sprite") && sprite_exists(_w.sprite)) {
        var _ms = 36 / sprite_get_width(_w.sprite);
        draw_set_alpha(1.0);
        draw_sprite_ext(_w.sprite, 0, _panelX1 + 60, _infoY + 30, _ms, _ms, 0,
                       _unlocked ? c_white : merge_color(c_white, c_black, 0.55), 1.0);
    } else {
        draw_set_alpha(1.0);
        draw_circle_color(_panelX1 + 60, _infoY + 30, 28, _w.color_a, _w.color_b, false);
    }

    // Locked overlay sprite
    if (!_unlocked) {
        var _lo = asset_get_index("spr_locked_overlay");
        if (_lo != -1 && sprite_exists(_lo)) {
            draw_set_alpha(0.7);
            draw_sprite_ext(_lo, 0, _panelX1 + 60, _infoY + 30, 0.8, 0.8, 0, c_white, 1);
        }
    }

    // World name
    draw_set_halign(fa_left); draw_set_alpha(1.0);
    draw_set_color(_unlocked ? make_color_rgb(255, 220, 100) : make_color_rgb(180, 60, 60));
    draw_text_transformed(_panelX1 + 110, _infoY + 10, _w.name, global.TXT_H2, global.TXT_H2, 0);

    // Threat / status
    var _threatLabels = ["MINIMAL", "MODERATE", "ELEVATED", "HIGH", "CRITICAL"];
    draw_set_color(make_color_rgb(180, 200, 230));
    draw_text_transformed(_panelX1 + 110, _infoY + 42, "THREAT: ", global.TXT_SMALL, global.TXT_SMALL, 0);
    draw_set_color(_unlocked ? make_color_rgb(255, 180, 70) : c_red);
    draw_text_transformed(_panelX1 + 160, _infoY + 42, _threatLabels[story_select_index], global.TXT_SMALL, global.TXT_SMALL, 0);

    // Mission count
    var _lvlCount = story_world_level_counts[story_select_index];
    var _completedCount = 0;
    for (var ci = 0; ci < _lvlCount; ci++) {
        if (!story_progress_is_unlocked(story_select_index, ci)) _completedCount++;
        else break;
    }
    draw_set_color(make_color_rgb(180, 200, 230));
    draw_text_transformed(_panelX1 + 110, _infoY + 62, "MISSIONS: ", global.TXT_SMALL, global.TXT_SMALL, 0);
    draw_set_color(_unlocked ? make_color_rgb(100, 255, 150) : c_gray);
    draw_text_transformed(_panelX1 + 170, _infoY + 62, string(_completedCount) + " / " + string(_lvlCount) + " CLEAR", global.TXT_SMALL, global.TXT_SMALL, 0);

    // Divider
    draw_set_alpha(0.25); draw_set_color(make_color_rgb(100, 180, 255));
    draw_line_width(_panelX1 + 30, _infoY + 90, _panelX2 - 30, _infoY + 90, 1); draw_set_alpha(1);

    // ═══ Level Grid (when zoomed) or World Description (when not) ═══
    var _gridY0 = _infoY + 120;

    if (in_story_level_select) {
        // Level grid header
        draw_set_halign(fa_center); draw_set_alpha(1.0); draw_set_color(c_white);
        draw_text_transformed(_panelX1 + _panelW * 0.5, _gridY0, "SELECT MISSION", global.TXT_H3, global.TXT_H3, 0);

        // Grid of level cards (3x2)
        var _cellW = 114;
        var _cellH = 90;
        var _cellGap = 14;
        var _gridStartX = _panelX1 + (_panelW - (_cellW * 3 + _cellGap * 2)) * 0.5;
        var _gridStartY = _gridY0 + 40;

        for (var _li = 0; _li < _lvlCount; _li++) {
            var _col = _li mod 3;
            var _row = _li div 3;
            var _cxCell = _gridStartX + _col * (_cellW + _cellGap) + _cellW * 0.5;
            var _cyCell = _gridStartY + _row * (_cellH + _cellGap) + _cellH * 0.5;
            var _selL = (_li == story_level_index);
            var _unlockedL = story_progress_is_unlocked(story_select_index, _li);

            // Cell background
            draw_set_alpha(_selL ? 0.35 : 0.12);
            var _cellCol = _selL ? make_color_rgb(70, 160, 255) : c_white;
            if (!_unlockedL) { draw_set_alpha(0.06); _cellCol = make_color_rgb(80, 20, 20); }
            draw_set_color(_cellCol);
            draw_roundrect_ext(_cxCell - _cellW * 0.5, _cyCell - _cellH * 0.5,
                              _cxCell + _cellW * 0.5, _cyCell + _cellH * 0.5, 10, 10, false);

            // Cell border
            draw_set_alpha(_selL ? 1.0 : 0.35);
            draw_set_color(_selL ? make_color_rgb(255, 220, 80) : make_color_rgb(120, 150, 200));
            if (!_unlockedL) draw_set_color(make_color_rgb(140, 60, 60));
            draw_roundrect_ext(_cxCell - _cellW * 0.5, _cyCell - _cellH * 0.5,
                              _cxCell + _cellW * 0.5, _cyCell + _cellH * 0.5, 10, 10, true);

            // Selection glow
            if (_selL) {
                gpu_set_blendmode(bm_add);
                draw_set_alpha(0.2 + abs(sin(current_time * 0.005)) * 0.08);
                draw_set_color(make_color_rgb(255, 220, 80));
                draw_roundrect_ext(_cxCell - _cellW * 0.5 - 4, _cyCell - _cellH * 0.5 - 4,
                                  _cxCell + _cellW * 0.5 + 4, _cyCell + _cellH * 0.5 + 4, 14, 14, true);
                gpu_set_blendmode(bm_normal);
            }

            // Mission number
            draw_set_halign(fa_center); draw_set_alpha(1.0);
            draw_set_color(_selL ? make_color_rgb(255, 220, 100) : make_color_rgb(180, 210, 255));
            if (!_unlockedL) draw_set_color(c_gray);
            draw_text_transformed(_cxCell, _cyCell - 16, string(_li + 1),
                                 _selL ? global.TXT_H3 : global.TXT_H4,
                                 _selL ? global.TXT_H3 : global.TXT_H4, 0);

            // Mission name
            var _lvlName = _unlockedL ? story_level_names[story_select_index][_li] : "LOCKED";
            if (string_length(_lvlName) > 10) _lvlName = string_copy(_lvlName, 1, 9) + ".";
            draw_set_alpha(_unlockedL ? (_selL ? 0.8 : 0.5) : 0.3);
            draw_set_color(_unlockedL ? c_white : c_gray);
            draw_text_transformed(_cxCell, _cyCell + 16, _lvlName, global.TXT_SMALL, global.TXT_SMALL, 0);
        }

        // Level detail below grid
        var _detailY = _gridStartY + 2 * (_cellH + _cellGap) + 36;
        var _missionName = story_level_names[story_select_index][story_level_index];
        var _def = story_get_level_def(story_select_index, story_level_index);
        var _objText = "OBJECTIVE PENDING";
        if (_def != undefined && variable_struct_exists(_def, "objective")) {
            if (_def.objective.type == "clear_cores") _objText = "CLEAR " + string(_def.objective.value) + " CORES";
            if (_def.objective.type == "score") _objText = "SCORE " + string(_def.objective.value);
            if (_def.objective.type == "survive_waves") _objText = "SURVIVE " + string(_def.objective.value) + " WAVES";
            if (_def.objective.type == "collect_shards") _objText = "COLLECT " + string(_def.objective.value) + " SHARDS";
        }

        draw_set_alpha(0.4); draw_set_color(make_color_rgb(100, 200, 255));
        draw_line_width(_panelX1 + 40, _detailY - 16, _panelX2 - 40, _detailY - 16, 1); draw_set_alpha(1);

        draw_set_halign(fa_center);
        draw_set_color(make_color_rgb(255, 220, 90));
        draw_text_transformed(_panelX1 + _panelW * 0.5, _detailY + 6, _missionName, global.TXT_H4, global.TXT_H4, 0);
        draw_set_color(make_color_rgb(180, 210, 255));
        draw_text_transformed(_panelX1 + _panelW * 0.5, _detailY + 32, _objText, global.TXT_SMALL, global.TXT_SMALL, 0);

        // Prompts
        draw_set_alpha(0.5); draw_set_color(make_color_rgb(255, 214, 102));
        draw_text_transformed(_panelX1 + _panelW * 0.5, _sh - 90, "A  DEPLOY    D  DWARF ROUTES", global.TXT_SMALL, global.TXT_SMALL, 0);
        draw_text_transformed(_panelX1 + _panelW * 0.5, _sh - 70, "S  SHOP    B  BACK TO WORLDS", global.TXT_SMALL, global.TXT_SMALL, 0);

    } else {
        // Galaxy view — world flavor text
        var _flavorTexts = [
            "A tiny moon caught in a tin-colored mist. The first signal of the corruption came from here. Short missions, low gravity.",
            "Once a garden world of rust-colored blooms, now choked by industrial decay. Moderate threat. Ground-based defense grids online.",
            "A rogue comet turned casino — high stakes, wild luck. The house always wins until you break the cycle. Gravity fluctuates.",
            "The dead orbit of a shattered planet. Derelict ships and silent debris fields. Zero-G navigation required.",
            "The heart of the corruption. Deep-space horror, color-locked gates, solar teeth. Only the best pilots make it here."
        ];
        draw_set_alpha(0.6); draw_set_color(make_color_rgb(180, 210, 240));

        var _flav = _flavorTexts[story_select_index];
        // Word wrap manually
        var _maxChars = 36;
        var _lineH = 22;
        for (var _line = 0; _line < 5; _line++) {
            var _start = _line * _maxChars + 1;
            var _sub = string_copy(_flav, _start, _maxChars);
            if (_sub == "") break;
            draw_text_transformed(_panelX1 + _panelW * 0.5, _gridY0 + 20 + _line * _lineH, _sub, global.TXT_SMALL, global.TXT_SMALL, 0);
        }

        // Controls
        draw_set_alpha(0.5); draw_set_color(make_color_rgb(255, 214, 102));
        draw_text_transformed(_panelX1 + _panelW * 0.5, _sh - 100, "A  SELECT WORLD    D  DWARF ROUTES", global.TXT_SMALL, global.TXT_SMALL, 0);
        draw_text_transformed(_panelX1 + _panelW * 0.5, _sh - 80, "S  SHOP    B  BACK TO MENU", global.TXT_SMALL, global.TXT_SMALL, 0);

        // Locked warning
        if (!_unlocked) {
            draw_set_alpha(0.35 + abs(sin(current_time * 0.006)) * 0.15);
            draw_set_color(make_color_rgb(255, 80, 80));
            draw_text_transformed(_panelX1 + _panelW * 0.5, _gridY0 + 160, "SYSTEM LOCKED", 2.5, 2.5, 0);
        }
    }

    // ═══ RIGHT SIDE — Solar System ═══
    var _spaceX = _panelX2 + 40;
    var _spaceW = _sw - _spaceX;
    var _spaceCX = _spaceX + _spaceW * 0.5;

    // Sun position (shifts during zoom)
    var _sunShiftX = lerp(0, 340, zoom_lerp);
    var _sunShiftY = lerp(0, -60, zoom_lerp);
    var _sunX = _spaceCX - _sunShiftX;
    var _sunY = _cy + _sunShiftY;
    var _zoomScale = lerp(1.0, 1.9, zoom_lerp);

    // Sun glow layers
    var _sunPulse = 0.65 + abs(sin(current_time * 0.003)) * 0.25;
    gpu_set_blendmode(bm_add);
    draw_set_alpha(_sunPulse * 0.5);
    draw_set_color(make_color_rgb(255, 215, 100));
    draw_circle_color(_sunX, _sunY, 76, c_yellow, make_color_rgb(255, 120, 40), false);
    draw_set_alpha(0.14);
    draw_circle_color(_sunX, _sunY, 180, make_color_rgb(255, 180, 70), c_black, false);
    draw_set_alpha(0.06);
    draw_circle_color(_sunX, _sunY, 300, make_color_rgb(255, 150, 40), c_black, false);
    gpu_set_blendmode(bm_normal);

    // Sun label
    draw_set_halign(fa_center); draw_set_alpha(0.7);
    draw_set_color(make_color_rgb(255, 235, 150));
    draw_text_transformed(_sunX, _sunY, "SUN GATE", global.TXT_SMALL, global.TXT_SMALL, 0);

    // Orbital rings
    for (var _orb = array_length(story_worlds) - 1; _orb >= 0; _orb--) {
        var _rxOrb = 130 + _orb * 84;
        var _ryOrb = _rxOrb * story_worlds[_orb].tilt;
        draw_set_alpha((0.10 + (_orb * 0.015)) * (1.0 - zoom_lerp * 0.6));
        draw_set_color(make_color_rgb(110, 160, 255));
        draw_ellipse(_sunX - _rxOrb * _zoomScale, _sunY - _ryOrb * _zoomScale,
                     _sunX + _rxOrb * _zoomScale, _sunY + _ryOrb * _zoomScale, true);
    }

    // Dwarf Routes cluster (top-right of space)
    draw_set_alpha(0.7 * (1.0 - zoom_lerp * 0.5));
    draw_set_color(make_color_rgb(115, 220, 255));
    for (var _dw = 0; _dw < array_length(bonus_planet_names); _dw++) {
        var _dwAng = (_dw / array_length(bonus_planet_names)) * 360 - story_solar_spin * 1.6;
        var _dwX = _spaceCX + 300 + lengthdir_x(60, _dwAng);
        var _dwY = _cy - 180 + lengthdir_y(22, _dwAng);
        draw_circle_color(_dwX, _dwY, 7 + (_dw mod 2) * 3,
                         make_color_rgb(115, 220, 255), make_color_rgb(35, 65, 120), false);
    }
    draw_set_color(make_color_rgb(160, 220, 255));
    draw_text_transformed(_spaceCX + 300, _cy - 230, "DWARF", global.TXT_SMALL, global.TXT_SMALL, 0);
    draw_text_transformed(_spaceCX + 300, _cy - 212, "ROUTES", global.TXT_SMALL, global.TXT_SMALL, 0);

    // Refabricator marker
    draw_set_alpha(0.7 * (1.0 - zoom_lerp * 0.5));
    draw_set_color(make_color_rgb(95, 190, 255));
    draw_triangle(_spaceCX - 390, _cy - 160, _spaceCX - 350, _cy - 176, _spaceCX - 350, _cy - 144, false);
    draw_set_color(make_color_rgb(160, 220, 255));
    draw_text_transformed(_spaceCX - 370, _cy - 200, "REFAB", global.TXT_SMALL, global.TXT_SMALL, 0);

    // Planets (two-pass depth sort: back then front)
    for (var _pass = 0; _pass < 2; _pass++) {
        for (var i = 0; i < array_length(story_worlds); i++) {
            var _w = story_worlds[i];
            var _rx = 130 + i * 84;
            var _ry = _rx * _w.tilt;
            var _ang = _w.ang + story_solar_spin * (0.55 + i * 0.08);
            var _depth = (lengthdir_y(1, _ang) + 1) * 0.5;
            var _front = (_depth >= 0.5);
            if ((_pass == 0 && _front) || (_pass == 1 && !_front)) continue;

            // Compute orbit position first
            var _orbPX = _sunX + lengthdir_x(_rx * _zoomScale, _ang);
            var _orbPY = _sunY + lengthdir_y(_ry * _zoomScale, _ang);

            // When zoomed, lerp selected planet toward a "focus" position in the space area
            var _sel = (i == story_select_index);
            var _focusX = _spaceCX + 100;
            var _focusY = _cy + 20;
            var _px = lerp(_orbPX, _focusX, zoom_lerp * (1 + i * 0.02));
            var _py = lerp(_orbPY, _focusY, zoom_lerp * (1 + i * 0.02));

            // Scale
            var _scaleP = 0.72 + (_depth * 0.58);
            if (_sel) _scaleP += 0.22 + zoom_lerp * 0.3;
            var _rad = _w.size * _scaleP * _zoomScale * (1.0 + zoom_lerp * 0.3);

            // Fade non-selected planets during zoom
            var _alphaMul = _sel ? 1.0 : (1.0 - zoom_lerp * 0.55);

            // Shadow
            draw_set_alpha((0.20 + _depth * 0.18) * _alphaMul); draw_set_color(c_black);
            draw_ellipse(_px - _rad * 1.15, _py + _rad * 0.78, _px + _rad * 1.15, _py + _rad * 1.18, false);

            var _unlocked = story_progress_is_unlocked(i, 0);

            // Planet rendering (sprite or procedural)
            if (variable_struct_exists(_w, "sprite") && sprite_exists(_w.sprite)) {
                var _s = (_rad * 2.4) / sprite_get_width(_w.sprite);
                var _tint = _unlocked ? c_white : merge_color(c_white, c_black, 0.5);
                draw_set_alpha(_sel ? 1.0 : (0.7 * _alphaMul));
                draw_sprite_ext(_w.sprite, 0, _px, _py, _s, _s, 0, _tint, 1.0);
            } else {
                var _pColA = _unlocked ? _w.color_a : merge_color(_w.color_a, c_black, 0.7);
                var _pColB = _unlocked ? _w.color_b : merge_color(_w.color_b, c_black, 0.7);
                draw_set_alpha((_sel ? 1.0 : 0.74) * _alphaMul);
                draw_circle_color(_px, _py, _rad, _pColA, _pColB, false);
                if (!_unlocked) {
                    draw_set_color(c_white); draw_set_alpha(0.6 * _alphaMul);
                    draw_text_transformed(_px, _py, "LOCKED", 0.5 * _scaleP, 0.5 * _scaleP, 0);
                }
                draw_set_alpha(0.38 * _alphaMul); draw_set_color(c_black);
                draw_circle(_px - _rad * 0.28, _py + _rad * 0.08, _rad * 0.82, false);
                draw_set_alpha((_sel ? 0.92 : 0.52) * _alphaMul);
                draw_set_color(_unlocked ? make_color_rgb(235, 250, 255) : c_gray);
                draw_circle(_px + _rad * 0.30, _py - _rad * 0.34, max(2, _rad * 0.18), false);
            }

            // Selection glow
            if (_sel) {
                gpu_set_blendmode(bm_add);
                draw_set_alpha((0.42 + _depth * 0.2 + zoom_lerp * 0.2));
                draw_set_color(make_color_rgb(255, 230, 120));
                draw_circle(_px, _py, _rad + 18, true);
                gpu_set_blendmode(bm_normal);
            }

            // Special rings
            if (i == 2 || i == 4) {
                draw_set_alpha((_sel ? 0.70 : 0.36) * _alphaMul);
                draw_set_color(i == 2 ? make_color_rgb(255, 230, 120) : make_color_rgb(185, 150, 255));
                draw_ellipse(_px - _rad * 1.65 * _zoomScale, _py - _rad * 0.36 * _zoomScale,
                             _px + _rad * 1.65 * _zoomScale, _py + _rad * 0.36 * _zoomScale, true);
            }

            // Planet name
            draw_set_halign(fa_center);
            draw_set_alpha((_sel ? 1.0 : 0.62) * _alphaMul);
            draw_set_color(_sel ? c_white : make_color_rgb(180, 195, 220));
            var _nameScale = _sel ? (0.88 + zoom_lerp * 0.4) : 0.68;
            draw_text_transformed(_px, _py - _rad - 22, _w.name, _nameScale, _nameScale, 0);

            // Moon sprites orbiting their planets
            var _moonSprite = -1;
            switch(i) {
                case 0: _moonSprite = -1; break; // Mercury — no moon
                case 1: _moonSprite = -1; break; // Mars — no moon (has rings instead)
                case 2: _moonSprite = asset_get_index("spr_earthmoon"); break; // Venus/Earth
                case 3: break; // Saturn — use moons below
                case 4: _moonSprite = asset_get_index("spr_jupitermoon"); break; // Jupiter
            }
            if (_moonSprite != -1 && sprite_exists(_moonSprite)) {
                var _mAng = story_solar_spin * 1.8 + i * 47;
                var _mDist = _rad + 24;
                var _mS = 0.7;
                draw_set_alpha(0.85 * _alphaMul);
                draw_sprite_ext(_moonSprite, 0,
                    _px + lengthdir_x(_mDist, _mAng),
                    _py + lengthdir_y(_mDist * 0.5, _mAng),
                    _mS, _mS, 0, c_white, 1);
            }
            // Saturn double moons
            if (i == 3) {
                var _m1 = asset_get_index("spr_saterlite1");
                var _m2 = asset_get_index("spr_saterlite2");
                if (_m1 != -1 && sprite_exists(_m1)) {
                    var _ma1 = story_solar_spin * 1.6 + 30;
                    draw_set_alpha(0.8 * _alphaMul);
                    draw_sprite_ext(_m1, 0,
                        _px + lengthdir_x(_rad + 28, _ma1),
                        _py + lengthdir_y((_rad + 28) * 0.4, _ma1),
                        0.6, 0.6, 0, c_white, 1);
                }
                if (_m2 != -1 && sprite_exists(_m2)) {
                    var _ma2 = story_solar_spin * 1.3 + 190;
                    draw_set_alpha(0.75 * _alphaMul);
                    draw_sprite_ext(_m2, 0,
                        _px + lengthdir_x(_rad + 22, _ma2),
                        _py + lengthdir_y((_rad + 22) * 0.4, _ma2),
                        0.5, 0.5, 0, c_white, 1);
                }
            }

            // Spore overlay on locked worlds
            if (!_unlocked) {
                var _spo = asset_get_index("spr_spore_overlay");
                if (_spo != -1 && sprite_exists(_spo)) {
                    var _s = (_rad * 2.6) / sprite_get_width(_spo);
                    draw_set_alpha(0.55 * _alphaMul);
                    draw_sprite_ext(_spo, 0, _px, _py, _s, _s, story_solar_spin * 0.3, c_white, 1);
                }
            }
        }
    }

    // Wallet bar (bottom-right corner, always visible)
    draw_set_halign(fa_right);
    draw_set_alpha(0.55); draw_set_color(make_color_rgb(180, 230, 255));
    draw_text_transformed(_sw - 40, _sh - 30, "SHARDS " + string(global.walletShards) + "   GEMS " + string(global.walletGems), global.TXT_SMALL, global.TXT_SMALL, 0);

    draw_set_alpha(1);
}

// ═══════════════════════════════════════════════════════════════════════════
// BONUS SELECT — Dwarf Routes
// ═══════════════════════════════════════════════════════════════════════════

function menu_draw_bonus_select(_cx, _cy, _sw, _sh) {
    draw_set_alpha(0.9); draw_set_color(c_black); draw_rectangle(0, 0, _sw, _sh, false);
    draw_set_color(c_white);
    draw_text_transformed(_cx, 120, "DWARF ROUTES", 4.0, 4.0, 0);

    var _baseY = _cy + 100;
    for (var _bi = 0; _bi < array_length(bonus_planet_names); _bi++) {
        var _angB = (_bi / array_length(bonus_planet_names)) * 360 + story_solar_spin;
        var _pxB = _cx + lengthdir_x(310, _angB);
        var _pyB = _baseY + lengthdir_y(105, _angB);
        var _selB = (_bi == bonus_select_index);
        var _radB = _selB ? 34 : 24;
        draw_set_alpha(_selB ? 1 : 0.65);
        draw_circle_color(_pxB, _pyB, _radB, make_color_rgb(115, 220, 255), make_color_rgb(40, 70, 120), false);
        if (_selB) {
            draw_set_alpha(0.36); draw_set_color(make_color_rgb(255, 220, 90));
            draw_circle(_pxB, _pyB, _radB + 14, true);
        }
        draw_set_alpha(_selB ? 1 : 0.55); draw_set_color(c_white);
        draw_text_transformed(_pxB, _pyB - _radB - 24, bonus_planet_names[_bi], _selB ? 0.78 : 0.58, _selB ? 0.78 : 0.58, 0);
    }

    draw_ui_panel(_cx - 350, _sh - 300, _cx + 350, _sh - 200);
    draw_set_alpha(1);
    draw_set_color(make_color_rgb(255, 220, 90));
    draw_text_transformed(_cx, _sh - 275, bonus_planet_names[bonus_select_index], global.TXT_H2, global.TXT_H2, 0);
    draw_set_color(c_white);
    draw_text_transformed(_cx, _sh - 240, "90-120 SEC SCORE ATTACK     GOAL " + string(bonus_planet_goals[bonus_select_index]) + "     REWARD +" + string(bonus_planet_rewards[bonus_select_index]) + " SHARDS", global.TXT_H4, global.TXT_H4, 0);

    draw_set_alpha(0.45); draw_set_color(make_color_rgb(255, 214, 102));
    draw_text_transformed(_cx, _sh - 60, "Left/Right Select Dwarf Route   A Start Bonus Mission   B Back To Solar System", global.TXT_SMALL, global.TXT_SMALL, 0);
}

// ═══════════════════════════════════════════════════════════════════════════
// REFABRICATOR
// ═══════════════════════════════════════════════════════════════════════════

function menu_draw_refabricator(_cx, _cy, _sw, _sh) {
    draw_set_alpha(0.92); draw_set_color(make_color_rgb(3, 6, 16)); draw_rectangle(0, 0, _sw, _sh, false);

    // Starfield
    var _starT = current_time * 0.00008;
    for (var i = 0; i < 40; i++) {
        var _pxs = (i * 173.3 + _starT * 100) % _sw;
        var _pys = (i * 217.7 + _starT * 55) % _sh;
        draw_set_alpha(0.1 + (i % 3) * 0.1); draw_set_color(c_white);
        draw_circle(_pxs, _pys, 1 + (i % 2), false);
    }
    draw_set_alpha(1);

    // Back button
    var _backSprite = asset_get_index("spr_back_icon");
    if (_backSprite != -1 && sprite_exists(_backSprite)) {
        draw_set_alpha(0.6);
        draw_sprite_ext(_backSprite, 0, 50, 50, 0.55, 0.55, 0, c_white, 1);
    }
    draw_set_alpha(0.5); draw_set_color(make_color_rgb(140, 190, 255));
    draw_text_transformed(76, 48, "B - BACK", global.TXT_SMALL, global.TXT_SMALL, 0);

    draw_set_halign(fa_center); draw_set_color(make_color_rgb(180, 240, 255));
    draw_text_transformed(_cx, 120, "REFABRICATOR", global.TXT_H1, global.TXT_H1, 0);

    // Glassmorphism panel
    var _pw = 800; var _ph = 320;
    var _px1 = _cx - _pw * 0.5;
    var _py1 = _cy - _ph * 0.5 - 20;

    draw_set_alpha(0.5); draw_set_color(c_black);
    draw_roundrect_ext(_px1 + 8, _py1 + 8, _px1 + _pw + 8, _py1 + _ph + 8, 20, 20, false);

    var _pTop = make_color_rgb(18, 30, 60);
    var _pBot = make_color_rgb(8, 14, 32);
    draw_set_alpha(0.88);
    draw_rectangle_colour(_px1, _py1, _px1 + _pw, _py1 + _ph, _pTop, _pTop, _pBot, _pBot, false);

    draw_set_alpha(0.03); draw_set_color(c_white);
    for (var gx = _px1; gx < _px1 + _pw; gx += 40) draw_line(gx, _py1, gx, _py1 + _ph);
    for (var gy = _py1; gy < _py1 + _ph; gy += 40) draw_line(_px1, gy, _px1 + _pw, gy);

    draw_set_alpha(0.45); draw_set_color(make_color_rgb(140, 190, 255));
    draw_roundrect_ext(_px1, _py1, _px1 + _pw, _py1 + _ph, 20, 20, true);

    // Ship sprite in refabricator
    var _shipSprite = asset_get_index("spr_refabricator_ship");
    if (_shipSprite != -1 && sprite_exists(_shipSprite)) {
        var _s = 2.5;
        var _sx = _cx + 140;
        var _sy = _py1 + 80 + sin(current_time * 0.002) * 12;
        draw_set_alpha(0.9);
        draw_sprite_ext(_shipSprite, 0, _sx, _sy, _s, _s, current_time * 0.0003, c_white, 1);
    }

    // Text
    draw_set_halign(fa_center); draw_set_color(c_white);
    draw_text_transformed(_cx, _py1 + 60, "Condense planetary debris into pure Core Gems.", global.TXT_H3, global.TXT_H3, 0);

    draw_set_color(make_color_rgb(255, 214, 102));
    draw_text_transformed(_cx, _py1 + 130, "25 SHARDS = 1 GEM", global.TXT_H1, global.TXT_H1, 0);

    // Shard and gem icons
    var _gs = asset_get_index("spr_gemshard");
    if (_gs != -1 && sprite_exists(_gs)) draw_sprite_ext(_gs, 0, _cx - 160, _py1 + 200, 3.5, 3.5, 0, c_white, 1);
    var _gm = asset_get_index("spr_gem");
    if (_gm != -1 && sprite_exists(_gm)) draw_sprite_ext(_gm, 0, _cx + 160, _py1 + 200, 3.5, 3.5, 0, c_white, 1);

    draw_set_color(make_color_rgb(255, 220, 90));
    draw_text_transformed(_cx, _py1 + 260, "SHARDS " + string(global.walletShards) + "     GEMS " + string(global.walletGems), global.TXT_H2, global.TXT_H2, 0);

    // Action prompt
    draw_set_alpha(0.5); draw_set_color(make_color_rgb(255, 214, 102));
    draw_text_transformed(_cx, _sh - 80, "A  Refabricate     B  Back", global.TXT_H4, global.TXT_H4, 0);
}

// ═══════════════════════════════════════════════════════════════════════════
// PLACEHOLDER SCREENS — Inventory, Shop, Encyclopedia, Achievements
// ═══════════════════════════════════════════════════════════════════════════

function _menu_draw_sub_screen_base(_cx, _cy, _sw, _sh, _title, _subtitle) {
    draw_set_alpha(0.92); draw_set_color(make_color_rgb(3, 6, 16)); draw_rectangle(0, 0, _sw, _sh, false);

    var _starT = current_time * 0.00008;
    for (var i = 0; i < 30; i++) {
        var _pxs = (i * 173.3 + _starT * 100) % _sw;
        var _pys = (i * 217.7 + _starT * 55) % _sh;
        draw_set_alpha(0.1 + (i % 3) * 0.1); draw_set_color(c_white);
        draw_circle(_pxs, _pys, 1 + (i % 2), false);
    }

    // Scanning grid
    draw_set_alpha(0.04); draw_set_color(make_color_rgb(100, 200, 255));
    for (var gx = 0; gx < _sw; gx += 160) draw_line(gx, 0, gx, _sh);
    for (var gy = 0; gy < _sh; gy += 160) draw_line(0, gy, _sw, gy);
    draw_set_alpha(1);

    // Back button
    var _backSprite = asset_get_index("spr_back_icon");
    if (_backSprite != -1 && sprite_exists(_backSprite)) {
        draw_set_alpha(0.6);
        draw_sprite_ext(_backSprite, 0, 50, 50, 0.55, 0.55, 0, c_white, 1);
    }
    draw_set_alpha(0.5); draw_set_color(make_color_rgb(140, 190, 255));
    draw_text_transformed(76, 48, "B - BACK", global.TXT_SMALL, global.TXT_SMALL, 0);

    draw_set_halign(fa_center); draw_set_color(c_white);
    draw_text_transformed(_cx, 120, _title, global.TXT_H1, global.TXT_H1, 0);

    if (_subtitle != "") {
        draw_set_alpha(0.4); draw_set_color(make_color_rgb(140, 200, 255));
        draw_text_transformed(_cx, _cy - 40, _subtitle, global.TXT_H4, global.TXT_H4, 0);
    }
    draw_set_alpha(1);
}

function menu_draw_inventory(_cx, _cy, _sw, _sh) {
    _menu_draw_sub_screen_base(_cx, _cy, _sw, _sh, "INVENTORY", "Pilot equipment — manage collected gear and upgrades");

    var _panelX = _cx - 450; var _panelW = 900;
    draw_ui_panel(_panelX, _cy, _panelX + _panelW, _cy + 160);

    draw_set_halign(fa_center); draw_set_alpha(0.4); draw_set_color(make_color_rgb(180, 210, 255));
    draw_text_transformed(_cx, _cy + 50, "No equipment modules installed.", global.TXT_H3, global.TXT_H3, 0);
    draw_text_transformed(_cx, _cy + 90, "Complete missions to acquire pilot upgrades.", global.TXT_SMALL, global.TXT_SMALL, 0);

    draw_set_alpha(0.5); draw_set_color(c_white);
    draw_text_transformed(_cx, _sh - 80, "B  Back", global.TXT_H4, global.TXT_H4, 0);
}

function menu_draw_shop(_cx, _cy, _sw, _sh) {
    _menu_draw_sub_screen_base(_cx, _cy, _sw, _sh, "TECH SHOP", "Spend gems on specialized core-mining technology");

    var _panelX = _cx - 450; var _panelW = 900;
    draw_ui_panel(_panelX, _cy, _panelX + _panelW, _cy + 160);

    draw_set_halign(fa_center); draw_set_alpha(0.4); draw_set_color(make_color_rgb(180, 210, 255));
    draw_text_transformed(_cx, _cy + 50, "Shop inventory loading...", global.TXT_H3, global.TXT_H3, 0);
    draw_text_transformed(_cx, _cy + 90, "GEMS: " + string(global.walletGems) + " available for upgrades.", global.TXT_SMALL, global.TXT_SMALL, 0);

    draw_set_alpha(0.5); draw_set_color(c_white);
    draw_text_transformed(_cx, _sh - 80, "B  Back", global.TXT_H4, global.TXT_H4, 0);
}

function menu_draw_how_to_play(_cx, _cy, _sw, _sh) {
    _menu_draw_sub_screen_base(_cx, _cy, _sw, _sh, "ENCYCLOPEDIA", "Pilot Data Notebook — Page " + string(how_to_page + 1) + " of " + string(how_to_max_pages));

    var _panelX = _cx - 500; var _panelW = 1000;
    draw_ui_panel(_panelX, _cy - 20, _panelX + _panelW, _cy + 200);

    var _pages = [
        "MOVE: Arrow Keys or Left Stick\nDROP: Space / A Button\nROTATE: Z or Up Arrows\nHOLD: C or Left Bumper\nSWITCH SIDE: Q/E or L/R Bumpers",
    ];
    draw_set_halign(fa_center); draw_set_alpha(0.5); draw_set_color(c_white);
    var _t = _pages[how_to_page mod array_length(_pages)];
    var _lines = 4;
    for (var _li = 0; _li < _lines; _li++) {
        var _ln = "";
        var _nl = string_pos("\n", _t); if (_nl > 0) { _ln = string_copy(_t, 1, _nl - 1); _t = string_delete(_t, 1, _nl); }
        else { _ln = _t; _t = ""; }
        draw_text_transformed(_cx, _cy - 20 + _li * 42, _ln, global.TXT_H3, global.TXT_H3, 0);
    }

    draw_set_alpha(0.45); draw_set_color(make_color_rgb(255, 214, 102));
    draw_text_transformed(_cx, _sh - 80, "B  Back", global.TXT_H4, global.TXT_H4, 0);
}

function menu_draw_achievements(_cx, _cy, _sw, _sh) {
    _menu_draw_sub_screen_base(_cx, _cy, _sw, _sh, "ACHIEVEMENTS", "");

    // Achievement list panel
    var _px = _cx - 520; var _pw = 1040;
    var _py = 210;
    var _ph = 70 * 10 + 20;

    draw_set_alpha(0.55); draw_set_color(c_black);
    draw_roundrect_ext(_px + 6, _py + 6, _px + _pw + 6, _py + _ph + 6, 16, 16, false);

    var _pTop = make_color_rgb(14, 24, 52);
    var _pBot = make_color_rgb(6, 10, 26);
    draw_set_alpha(0.85);
    draw_rectangle_colour(_px, _py, _px + _pw, _py + _ph, _pTop, _pTop, _pBot, _pBot, false);

    draw_set_alpha(0.025); draw_set_color(c_white);
    for (var gx = _px; gx < _px + _pw; gx += 40) draw_line(gx, _py, gx, _py + _ph);
    for (var gy = _py; gy < _py + _ph; gy += 40) draw_line(_px, gy, _px + _pw, gy);

    draw_set_alpha(0.4); draw_set_color(make_color_rgb(140, 190, 255));
    draw_roundrect_ext(_px, _py, _px + _pw, _py + _ph, 16, 16, true);

    // Items
    var _count = min(10, array_length(global.achievements));
    for (var i = 0; i < _count; i++) {
        var _ach = global.achievements[i];
        var _ay = _py + 20 + i * 70;

        // Row background
        draw_set_alpha(_ach.unlocked ? 0.1 : 0.04); draw_set_color(c_white);
        draw_roundrect_ext(_px + 20, _ay - 22, _px + _pw - 20, _ay + 38, 8, 8, false);

        // Status icon
        var _achIcon = asset_get_index("spr_achievements_icon");
        if (_achIcon != -1 && sprite_exists(_achIcon)) {
            draw_set_alpha(_ach.unlocked ? 1.0 : 0.3);
            draw_sprite_ext(_achIcon, 0, _px + 52, _ay + 8, 1.3, 1.3, 0,
                           _ach.unlocked ? c_white : c_gray, 1);
        } else {
            draw_set_alpha(_ach.unlocked ? 0.8 : 0.3);
            draw_set_color(_ach.unlocked ? make_color_rgb(100, 255, 150) : make_color_rgb(80, 80, 80));
            draw_circle(_px + 52, _ay + 8, 16, false);
        }

        // Name
        draw_set_halign(fa_left); draw_set_alpha(1);
        draw_set_color(_ach.unlocked ? c_white : c_gray);
        draw_text_transformed(_px + 90, _ay - 2, _ach.name, global.TXT_H4, global.TXT_H4, 0);

        // Description
        draw_set_alpha(_ach.unlocked ? 0.45 : 0.25);
        draw_set_color(_ach.unlocked ? make_color_rgb(180, 210, 255) : c_gray);
        draw_text_transformed(_px + 90, _ay + 22, _ach.desc, global.TXT_SMALL, global.TXT_SMALL, 0);

        // Status label
        draw_set_halign(fa_right);
        draw_set_alpha(_ach.unlocked ? 0.8 : 0.4);
        draw_set_color(_ach.unlocked ? make_color_rgb(100, 255, 150) : make_color_rgb(255, 100, 100));
        draw_text_transformed(_px + _pw - 50, _ay + 8,
                             _ach.unlocked ? "UNLOCKED" : "LOCKED", global.TXT_SMALL, global.TXT_SMALL, 0);
    }

    draw_set_halign(fa_center); draw_set_alpha(0.45); draw_set_color(c_white);
    draw_text_transformed(_cx, _sh - 60, "B  Back", global.TXT_H4, global.TXT_H4, 0);
}

// ═══════════════════════════════════════════════════════════════════════════
// LEVEL TRANSITION — Cinematic Deployment
// ═══════════════════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════════════════
// FLOATING TEXTS + DIALOGUE
// ═══════════════════════════════════════════════════════════════════════════

function menu_draw_floating_texts() {
    for (var i = 0; i < array_length(global.floatingTexts); i++) {
        var _ft = global.floatingTexts[i];
        draw_set_alpha(_ft.life / 90);
        draw_set_color(_ft.color);
        draw_text_transformed(_ft.x, _ft.y, _ft.text, _ft.scale, _ft.scale, 0);
    }
}
