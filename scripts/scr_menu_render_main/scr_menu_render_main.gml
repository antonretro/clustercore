/// @module scr_menu_render_main
/// Main Menu screens: Title, Save Slots, Loading, and the Main Deck.

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

    if (in_name_entry) {
        menu_draw_name_entry(_cx, _cy, _sw, _sh);
        return;
    }
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

function menu_draw_name_entry(_cx, _cy, _sw, _sh) {
    // Dark overlay
    draw_set_alpha(0.9); draw_set_color(make_color_rgb(2, 4, 10));
    draw_rectangle(0, 0, _sw, _sh, false);

    var _slot = save_slots[name_entry_index];

    // Glass panel
    var _pw = 700; var _ph = 340;
    var _px1 = _cx - _pw * 0.5; var _py1 = _cy - _ph * 0.5;

    draw_set_alpha(0.5); draw_set_color(c_black);
    draw_roundrect_ext(_px1 + 8, _py1 + 8, _px1 + _pw + 8, _py1 + _ph + 8, 20, 20, false);

    var _pTop = make_color_rgb(16, 28, 60);
    var _pBot = make_color_rgb(6, 10, 28);
    draw_set_alpha(0.92);
    draw_rectangle_colour(_px1, _py1, _px1 + _pw, _py1 + _ph, _pTop, _pTop, _pBot, _pBot, false);

    draw_set_alpha(0.03); draw_set_color(c_white);
    for (var gx = _px1; gx < _px1 + _pw; gx += 40) draw_line(gx, _py1, gx, _py1 + _ph);
    for (var gy = _py1; gy < _py1 + _ph; gy += 40) draw_line(_px1, gy, _px1 + _pw, gy);

    draw_set_alpha(0.5); draw_set_color(make_color_rgb(140, 190, 255));
    draw_roundrect_ext(_px1, _py1, _px1 + _pw, _py1 + _ph, 20, 20, true);

    // Title
    draw_set_halign(fa_center); draw_set_alpha(1); draw_set_color(c_white);
    draw_text_transformed(_cx, _py1 + 50, "PILOT REGISTRATION", global.TXT_H1, global.TXT_H1, 0);
    draw_set_alpha(0.5); draw_set_color(make_color_rgb(140, 200, 255));
    draw_text_transformed(_cx, _py1 + 90, "Enter your callsign, Pilot.", global.TXT_H4, global.TXT_H4, 0);

    // Input field
    var _fieldW = 440; var _fieldH = 56;
    var _fx = _cx - _fieldW * 0.5; var _fy = _py1 + 140;

    draw_set_alpha(0.12); draw_set_color(c_white);
    draw_roundrect_ext(_fx, _fy, _fx + _fieldW, _fy + _fieldH, 10, 10, false);
    draw_set_alpha(0.6); draw_set_color(make_color_rgb(100, 200, 255));
    draw_roundrect_ext(_fx, _fy, _fx + _fieldW, _fy + _fieldH, 10, 10, true);

    // Text in field
    var _displayText = name_entry_text;
    var _cursor = (floor(current_time / 500) mod 2 == 0);
    if (_cursor) _displayText += "_";

    draw_set_halign(fa_center); draw_set_alpha(1); draw_set_color(make_color_rgb(255, 220, 100));
    draw_text_transformed(_cx, _fy + _fieldH * 0.5, _displayText, global.TXT_H2, global.TXT_H2, 0);

    // Slot info
    draw_set_alpha(0.4); draw_set_color(make_color_rgb(180, 200, 230));
    draw_text_transformed(_cx, _py1 + 220, "DATA SLOT " + string(name_entry_index + 1) + "   |   PROGRESS " + string(_slot.progress) + "%", global.TXT_H4, global.TXT_H4, 0);

    // Hint
    draw_set_alpha(0.5); draw_set_color(make_color_rgb(255, 214, 102));
    draw_text_transformed(_cx, _py1 + 275, "TYPE NAME    [ENTER] CONFIRM    [ESC] CANCEL", global.TXT_H4, global.TXT_H4, 0);
}

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

    // Check if endless modes are unlocked (need story progress)
    var _slotIdx = global.current_save_slot - 1;
    var _hasStoryProgress = (_slotIdx >= 0 && _slotIdx < 3 && save_slots[_slotIdx].progress > 0);
    var _endlessLocked = !_hasStoryProgress;

    // 3 Mode Cards
    var _cardIcons = [spr_story_icon, spr_planet_endless, spr_classic_endless];
    for (var i = 0; i < 3; i++) {
        var _isSel = (menu_index == i);
        var _isLocked = (i > 0 && _endlessLocked);
        var _xx = _startX + i * (_cardW + _gap);
        var _off = _isSel ? -20 : 0;

        // Card shadow
        draw_set_alpha(_isSel ? 0.5 : 0.25); draw_set_color(c_black);
        draw_roundrect_ext(_xx + 8, _mainY + _off + 8, _xx + _cardW + 8, _mainY + _cardH + _off + 8, 16, 16, false);

        // Card base
        draw_set_alpha(_isLocked ? 0.45 : (_isSel ? 0.95 : 0.7));
        var _gradCol = _isLocked ? make_color_rgb(8, 8, 18) : (_isSel ? make_color_rgb(25, 45, 80) : make_color_rgb(12, 18, 35));
        draw_rectangle_colour(_xx, _mainY + _off, _xx + _cardW, _mainY + _cardH + _off, _gradCol, _gradCol, c_black, c_black, false);

        // Grid overlay
        draw_set_alpha(_isLocked ? 0.01 : 0.04); draw_set_color(c_white);
        for (var gx = _xx; gx < _xx + _cardW; gx += 40) draw_line(gx, _mainY + _off, gx, _mainY + _cardH + _off);
        for (var gy = _mainY + _off; gy < _mainY + _cardH + _off; gy += 40) draw_line(_xx, gy, _xx + _cardW, gy);

        // Border
        draw_set_alpha(1);
        if (_isLocked) draw_set_color(make_color_rgb(60, 60, 80));
        else draw_set_color(_isSel ? make_color_rgb(100, 255, 150) : c_white);
        draw_roundrect_ext(_xx, _mainY + _off, _xx + _cardW, _mainY + _cardH + _off, 16, 16, true);

        // Selection glow
        if (_isSel && !_isLocked) {
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
        draw_set_alpha(_isLocked ? 0.3 : 1);
        if (sprite_exists(_cardIcons[i])) {
            draw_sprite_ext(_cardIcons[i], 0, _iconCX, _iconCY, 3.0, 3.0, 0,
                           _isLocked ? c_gray : c_white, 1);
        } else {
            draw_card_icon(i, _iconCX, _iconCY, _iconR, _isSel && !_isLocked, _isLocked ? 0.3 : 1.0);
        }

        // Label
        draw_set_halign(fa_center);
        draw_set_color(_isLocked ? make_color_rgb(100, 100, 120) : (_isSel ? make_color_rgb(255, 220, 100) : c_white));
        draw_text_transformed(_xx + _cardW * 0.5, _mainY + 340 + _off, menu_items[i], 2.0, 2.0, 0);

        // Subtitle / Locked text
        if (_isLocked) {
            draw_set_alpha(0.5); draw_set_color(make_color_rgb(255, 120, 100));
            draw_text_transformed(_xx + _cardW * 0.5, _mainY + 390 + _off, "COMPLETE STORY LEVEL 1 TO UNLOCK", 0.75, 0.75, 0);
        } else {
            draw_set_alpha(0.6);
            draw_text_transformed(_xx + _cardW * 0.5, _mainY + 390 + _off, menu_hint[i], 0.9, 0.9, 0);
        }

        // Lock icon overlay
        if (_isLocked) {
            draw_set_alpha(0.7); draw_set_color(make_color_rgb(255, 80, 80));
            draw_set_halign(fa_center);
            draw_text_transformed(_iconCX, _iconCY, "[ LOCKED ]", 1.8, 1.8, 0);
        }
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
        if (sprite_exists(_toolbarSprites[i])) {
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
