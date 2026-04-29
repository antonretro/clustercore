var _guiW = display_get_gui_width();
var _guiH = display_get_gui_height();
draw_set_font(main_font);
gpu_set_texfilter(false);

// Persistent Background for Menus
if (global.gameState != "PLAYING" && global.gameState != "PAUSED") {
    draw_rectangle_color(0, 0, _guiW, _guiH, global.bg_colors[0], global.bg_colors[1], global.bg_colors[2], global.bg_colors[1], false);
}

// --- Screen Specific Content ---
switch(global.gameState) {
    case "MENU":
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_color(global.COLOR_ACCENT);
        draw_text_transformed(_guiW / 2, _guiH / 3, "CLUSTER CORE", 6, 6, 0); 
        draw_set_color(c_white);
        draw_text_transformed(_guiW / 2, _guiH / 2, "PRESS ENTER TO START", 2, 2, 0);
        break;
}

// --- In-Game HUD (Premium Layout) ---
if (global.gameState == "PLAYING" || global.gameState == "PAUSED" || global.gameState == "GAMEOVER") {
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    
    // Wavy Text Helper
    function draw_text_wavy(_x, _y, _text, _scale, _col) {
        var _len = string_length(_text);
        var _timer = current_time * 0.005;
        draw_set_color(_col);
        draw_set_halign(fa_center);
        for (var i = 1; i <= _len; i++) {
            var _char = string_char_at(_text, i);
            var _offY = sin(_timer + (i * 0.5)) * 10;
            var _charW = string_width(_char) * _scale;
            draw_text_transformed(_x - (_len * 10 * _scale) + (i * 20 * _scale), _y + _offY, _char, _scale, _scale, 0);
        }
    }

    function draw_stat_panel(_x, _y, _w, _h, _label, _val, _scale = 2) {
        draw_set_alpha(0.2); draw_set_color(c_black);
        draw_roundrect_ext(_x+4, _y+4, _x+_w+4, _y+_h+4, 15, 15, false);
        draw_set_alpha(0.1); draw_set_color(c_white);
        draw_roundrect_ext(_x, _y, _x + _w, _y + _h, 15, 15, false);
        draw_set_alpha(0.6); draw_set_color((global.feverTimer > 0) ? c_yellow : global.COLOR_ACCENT);
        draw_roundrect_ext(_x, _y, _x + _w, _y + _h, 15, 15, true);
        draw_set_alpha(1.0); draw_set_color(global.COLOR_ACCENT);
        draw_text_transformed(_x + 10, _y + 10, _label, 1.2, 1.2, 0);
        draw_set_color(c_white);
        draw_text_transformed(_x + 10, _y + 35, _val, _scale, _scale, 0);
    }

    // --- LEFT COLUMN ---
    var _lx = 50;
    draw_stat_panel(_lx, 50, 240, 100, "SCORE", string(global.score), 2.5 * global.ui_scales.score);
    draw_stat_panel(_lx, 170, 240, 80, "LEVEL", string(global.level), 2 * global.ui_scales.level);
    draw_stat_panel(_lx, 270, 240, 150, "HOLD [C]", "");
    
    if (global.holdPiece != undefined) {
        var _hScale = global.PIXEL_SCALE * 1.5;
        var _hcx = _lx + 120;
        var _hcy = 270 + 85; 
        var _hSpr = spr_pinkSprite;
        switch(global.holdPiece.id) {
            case 1: _hSpr = spr_pinkSprite; break;
            case 2: _hSpr = spr_orangeSprite; break;
            case 3: _hSpr = spr_yellowSprite; break;
            case 4: _hSpr = spr_redSprite; break;
            case 5: _hSpr = spr_lightblueSprite; break;
            case 6: _hSpr = spr_greenSprite; break;
        }
        if (global.holdPiece.type == "bomb") _hSpr = spr_bomb;
        if (global.holdPiece.type == "drill") _hSpr = spr_drill;
        if (global.holdPiece.type == "dead") _hSpr = spr_deadmetal;
        draw_sprite_ext(_hSpr, 0, _hcx, _hcy, _hScale, _hScale, 0, c_white, global.canHold ? 1.0 : 0.4);
    }

    // --- RIGHT COLUMN ---
    var _rx = _guiW - 290;
    draw_stat_panel(_rx, 50, 240, 420, "NEXT", "");
    draw_stat_panel(_rx, 490, 240, 80, "SHARDS", "+" + string(global.runShards), 2 * global.ui_scales.shards);
    draw_stat_panel(_rx, 590, 240, 80, "COMBO", "x" + string(global.bestCombo), 2 * global.ui_scales.combo);

    for (var i = 0; i < array_length(global.nextQueue); i++) {
        var _qPiece = global.nextQueue[i];
        var _qScale = (i == 0) ? (global.PIXEL_SCALE * 1.6) : (global.PIXEL_SCALE * 1.1);
        var _qcx = _rx + 120;
        var _qcy = 50 + 100 + (i * 120); 
        var _qSpr = spr_pinkSprite;
        switch(_qPiece.id) {
            case 1: _qSpr = spr_pinkSprite; break;
            case 2: _qSpr = spr_orangeSprite; break;
            case 3: _qSpr = spr_yellowSprite; break;
            case 4: _qSpr = spr_redSprite; break;
            case 5: _qSpr = spr_lightblueSprite; break;
            case 6: _qSpr = spr_greenSprite; break;
        }
        if (_qPiece.type == "bomb") _qSpr = spr_bomb;
        if (_qPiece.type == "drill") _qSpr = spr_drill;
        if (_qPiece.type == "dead") _qSpr = spr_deadmetal;
        draw_sprite_ext(_qSpr, 0, _qcx, _qcy, _qScale, _qScale, 0, c_white, (i == 0 ? 1.0 : 0.5));
    }

    // --- VERTICAL GAUGES ---
    var _scale = global.PIXEL_SCALE;
    var _bw = global.COLS * 16 * _scale;
    var _bh = global.ROWS * 16 * _scale;
    var _bx = (_guiW - _bw) / 2;
    var _by = (_guiH - _bh) / 2 - 40;

    var _gx = _bx - 40;
    var _prog = (global.levelScore / global.scoreToNext);
    draw_set_color(c_black); draw_set_alpha(0.5);
    draw_roundrect_ext(_gx, _by, _gx + 12, _by + _bh, 5, 5, false);
    draw_set_color(global.COLOR_ACCENT); draw_set_alpha(1.0);
    draw_roundrect_ext(_gx, _by + _bh * (1 - _prog), _gx + 12, _by + _bh, 5, 5, false);

    var _jx = _bx + _bw + 28;
    var _jackPct = global.jackpotMeter / global.jackpotMax;
    draw_set_color(c_black); draw_set_alpha(0.5);
    draw_roundrect_ext(_jx, _by, _jx + 12, _by + _bh, 5, 5, false);
    draw_set_color((global.feverTimer > 0) ? c_yellow : global.COLOR_GLOW); draw_set_alpha(1.0);
    draw_roundrect_ext(_jx, _by + _bh * (1 - _jackPct), _jx + 12, _by + _bh, 5, 5, false);

    // --- COMBO CELEBRATIONS ---
    if (global.bestCombo >= 3) {
        var _celebration = "GOOD!";
        if (global.bestCombo >= 5) _celebration = "EXCELLENT!!";
        if (global.bestCombo >= 8) _celebration = "AMAZING!!!";
        if (global.bestCombo >= 12) _celebration = "UNBELIEVABLE!!!!";
        draw_text_wavy(_guiW / 2, 80, _celebration, 3, (global.feverTimer > 0) ? c_yellow : global.COLOR_ACCENT);
    }

    draw_set_halign(fa_center);
    draw_text_transformed(_bx + _bw/2, _by + _bh + 20, (global.feverTimer > 0) ? ("FEVER MODE") : "", 2, 2, 0);

    // Overlays
    if (global.gameState == "PAUSED") {
        draw_set_color(global.COLOR_BG2); draw_set_alpha(0.85);
        draw_rectangle(0, 0, _guiW, _guiH, false);
        draw_set_alpha(1.0); draw_set_halign(fa_center); draw_set_color(c_white);
        draw_text_transformed(_guiW / 2, _guiH / 2, "PAUSED\n\nESC TO RESUME", 3, 3, 0);
    }
}

// --- Floating Payout Text ---
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
for (var i = 0; i < array_length(global.floatingTexts); i++) {
    var _ft = global.floatingTexts[i];
    draw_set_alpha(clamp(_ft.life / 60, 0, 1));
    draw_set_color(c_black);
    draw_text_transformed(_ft.x + 3, _ft.y + 3, _ft.text, _ft.scale * 2, _ft.scale * 2, 0); 
    draw_set_color(_ft.color);
    draw_text_transformed(_ft.x, _ft.y, _ft.text, _ft.scale * 2, _ft.scale * 2, 0);
}
draw_set_alpha(1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

// --- Retro Post-Processing ---
draw_set_alpha(0.08);
for(var i=0; i<_guiH; i+=6) {
    draw_set_color(c_black); draw_line_width(0, i, _guiW, i, 2);
}
draw_set_alpha(1.0);
