var _guiW = display_get_gui_width();
var _guiH = display_get_gui_height();
draw_set_font(main_font);
gpu_set_texfilter(true);

// --- In-Game HUD ---
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

    // Board position (matches Draw_0)
    var _scale = global.PIXEL_SCALE;
    var _bw2 = global.COLS * 16 * _scale;
    var _bh2 = global.ROWS * 16 * _scale;
    var _bx2 = (_guiW - _bw2) / 2;
    var _by2 = (_guiH - _bh2) / 2;

    // --- LEFT COLUMN (dynamic heights, always fills _bh2 exactly) ---
    var _pw  = 240;
    var _lx  = _bx2 - _pw - 60;
    var _gap = 12;
    var _sH  = floor(_bh2 * 0.215);
    var _lH  = floor(_bh2 * 0.146);
    var _hoH = floor(_bh2 * 0.319);
    var _bstH = _bh2 - _sH - _lH - _hoH - _gap * 3;
    var _lOff0 = _by2;
    var _lOff1 = _lOff0 + _sH  + _gap;
    var _lOff2 = _lOff1 + _lH  + _gap;
    var _lOff3 = _lOff2 + _hoH + _gap;
    draw_stat_panel(_lx, _lOff0, _pw, _sH,   "SCORE",    string(global.score),          2.5 * global.ui_scales.score);
    draw_stat_panel(_lx, _lOff1, _pw, _lH,   "LEVEL",    string(global.level),          2   * global.ui_scales.level);
    draw_stat_panel(_lx, _lOff2, _pw, _hoH,  "HOLD [C]", "");
    draw_stat_panel(_lx, _lOff3, _pw, _bstH, "BEST",     "x" + string(global.bestCombo), 2 * global.ui_scales.combo);

    if (global.holdPiece != undefined) {
        var _hScale = 3.5;
        var _hcx = _lx + 120;
        var _hcy = _lOff2 + floor(_hoH * 0.5);
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

    // --- RIGHT COLUMN (dynamic heights, always fills _bh2 exactly) ---
    var _rx  = _bx2 + _bw2 + 60;
    var _nH  = floor(_bh2 * 0.597);
    var _shH = floor(_bh2 * 0.180);
    var _coH = _bh2 - _nH - _shH - _gap * 2;
    var _rOff0 = _by2;
    var _rOff1 = _rOff0 + _nH  + _gap;
    var _rOff2 = _rOff1 + _shH + _gap;
    draw_stat_panel(_rx, _rOff0, _pw, _nH,  "NEXT",   "");
    draw_stat_panel(_rx, _rOff1, _pw, _shH, "SHARDS", "+" + string(global.runShards),    2 * global.ui_scales.shards);
    draw_stat_panel(_rx, _rOff2, _pw, _coH, "COMBO",  "x" + string(global.comboChain),   2 * global.ui_scales.combo);

    for (var i = 0; i < array_length(global.nextQueue); i++) {
        var _qPiece = global.nextQueue[i];
        var _qScale = (i == 0) ? 3.5 : 2.2;
        var _qcx = _rx + 120;
        var _qcy = _rOff0 + floor(_nH * 0.16) + (i * floor(_nH / 3));
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

    // --- VERTICAL GAUGES (flanking the board) ---
    var _gx = _bx2 - 32;
    var _prog = clamp(global.levelScore / global.scoreToNext, 0, 1);
    draw_set_color(c_black); draw_set_alpha(0.5);
    draw_roundrect_ext(_gx, _by2, _gx + 12, _by2 + _bh2, 5, 5, false);
    draw_set_color(global.COLOR_ACCENT); draw_set_alpha(1.0);
    draw_roundrect_ext(_gx, _by2 + _bh2 * (1 - _prog), _gx + 12, _by2 + _bh2, 5, 5, false);

    var _jx = _bx2 + _bw2 + 20;
    var _jackPct = clamp(global.jackpotMeter / global.jackpotMax, 0, 1);
    draw_set_color(c_black); draw_set_alpha(0.5);
    draw_roundrect_ext(_jx, _by2, _jx + 12, _by2 + _bh2, 5, 5, false);
    draw_set_color((global.feverTimer > 0) ? c_yellow : global.COLOR_GLOW); draw_set_alpha(1.0);
    draw_roundrect_ext(_jx, _by2 + _bh2 * (1 - _jackPct), _jx + 12, _by2 + _bh2, 5, 5, false);

    // --- COMBO CELEBRATIONS ---
    if (global.comboChain >= 3) {
        var _celebration = "GOOD!";
        if (global.comboChain >= 5) _celebration = "EXCELLENT!!";
        if (global.comboChain >= 8) _celebration = "AMAZING!!!";
        if (global.comboChain >= 12) _celebration = "UNBELIEVABLE!!!!";
        draw_text_wavy(_guiW / 2, _by2 - 40, _celebration, 3, (global.feverTimer > 0) ? c_yellow : global.COLOR_ACCENT);
    }

    draw_set_halign(fa_center);
    draw_text_transformed(_bx2 + _bw2 / 2, _by2 + _bh2 + 24, (global.feverTimer > 0) ? "FEVER MODE" : "", 2, 2, 0);

    // Overlays
    if (global.gameState == "PAUSED") {
        draw_set_color(global.COLOR_BG2); draw_set_alpha(0.85);
        draw_rectangle(0, 0, _guiW, _guiH, false);
        draw_set_alpha(1.0); draw_set_halign(fa_center); draw_set_color(c_white);
        draw_text_transformed(_guiW / 2, _guiH / 2 - 40, "PAUSED", 4, 4, 0);
        draw_set_color(make_color_rgb(180, 180, 180));
        draw_text_transformed(_guiW / 2, _guiH / 2 + 40, "ESC  Resume    ESC  Menu", 1.5, 1.5, 0);
    }

    if (global.gameState == "GAMEOVER") {
        draw_set_color(c_black); draw_set_alpha(0.78);
        draw_rectangle(0, 0, _guiW, _guiH, false);
        draw_set_alpha(1.0); draw_set_halign(fa_center);
        draw_set_color(global.COLOR_DANGER);
        draw_text_transformed(_guiW / 2, _guiH / 2 - 80, "GAME OVER", 5, 5, 0);
        draw_set_color(c_white);
        draw_text_transformed(_guiW / 2, _guiH / 2 + 10,  "SCORE  " + string(global.score), 2.5, 2.5, 0);
        draw_set_color((global.score >= global.highScore) ? c_yellow : make_color_rgb(180, 200, 255));
        draw_text_transformed(_guiW / 2, _guiH / 2 + 60,  ((global.score >= global.highScore) ? "NEW BEST!  " : "BEST  ") + string(global.highScore), 2, 2, 0);
        draw_set_color(c_white);
        draw_text_transformed(_guiW / 2, _guiH / 2 + 105, "COMBO  x" + string(global.bestCombo), 1.8, 1.8, 0);
        draw_set_color(make_color_rgb(180, 180, 180));
        draw_text_transformed(_guiW / 2, _guiH / 2 + 150, "R  Play Again     ESC  Menu", 1.5, 1.5, 0);
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
    draw_set_color(c_black); draw_line_width(0, i, _guiW, i, 1);
}
draw_set_alpha(1.0);
