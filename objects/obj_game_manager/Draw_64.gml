var _guiW = display_get_gui_width();
var _guiH = display_get_gui_height();
draw_set_font(main_font);
gpu_set_texfilter(true); // smooth for fonts — toggled to false only around pixel art sprites

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
            draw_text_transformed(floor(_x - (_len * 10 * _scale) + (i * 20 * _scale)), floor(_y + _offY), _char, _scale, _scale, 0);
        }
    }

    function draw_stat_panel(_x, _y, _w, _h, _label, _val, _scale = 2) {
        _x = floor(_x); _y = floor(_y);
        // Drop shadow
        draw_set_alpha(0.28); draw_set_color(c_black);
        draw_roundrect_ext(_x+5, _y+5, _x+_w+5, _y+_h+5, 15, 15, false);
        // Panel body with slight blue tint
        draw_set_alpha(0.18); draw_set_color(make_color_rgb(30, 40, 80));
        draw_roundrect_ext(_x, _y, _x + _w, _y + _h, 15, 15, false);
        draw_set_alpha(0.08); draw_set_color(c_white);
        draw_roundrect_ext(_x, _y, _x + _w, _y + _h, 15, 15, false);
        // Border
        var _accentCol = (global.feverTimer > 0) ? c_yellow : global.COLOR_ACCENT;
        draw_set_alpha(0.65); draw_set_color(_accentCol);
        draw_roundrect_ext(_x, _y, _x + _w, _y + _h, 15, 15, true);
        // Top highlight line
        draw_set_alpha(0.18); draw_set_color(c_white);
        draw_roundrect_ext(_x+2, _y+2, _x+_w-2, _y+14, 10, 10, false);
        // Label
        draw_set_alpha(0.7); draw_set_color(_accentCol);
        draw_text_transformed(floor(_x + 12), floor(_y + 10), _label, 1.1, 1.1, 0);
        // Value
        draw_set_alpha(1.0); draw_set_color(c_white);
        draw_text_transformed(floor(_x + 12), floor(_y + 34), _val, _scale, _scale, 0);
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
        gpu_set_texfilter(false);
        draw_sprite_ext(_hSpr, 0, _hcx, _hcy, _hScale, _hScale, 0, c_white, global.canHold ? 1.0 : 0.4);
        if (global.holdPiece.type == "metal") {
            var _hArrow = (global.holdPiece.dir == 0) ? spr_lr_arrows : spr_ud_arrows;
            draw_sprite_ext(_hArrow, 0, _hcx, _hcy, _hScale, _hScale, 0, c_white, global.canHold ? 1.0 : 0.4);
        }
        gpu_set_texfilter(true);
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

    gpu_set_texfilter(false);
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
        if (_qPiece.type == "metal") {
            var _qArrow = (_qPiece.dir == 0) ? spr_lr_arrows : spr_ud_arrows;
            draw_sprite_ext(_qArrow, 0, _qcx, _qcy, _qScale, _qScale, 0, c_white, (i == 0 ? 1.0 : 0.5));
        }
    }
    gpu_set_texfilter(true);

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
    
    if (global.gameMode == "STORY") {
        var _storyPct = clamp(global.coresCleared / max(1, global.storyTarget), 0, 1);
        var _storyY = _by2 - 54;
        draw_set_color(c_black);
        draw_set_alpha(0.55);
        draw_roundrect_ext(_bx2, _storyY, _bx2 + _bw2, _storyY + 18, 6, 6, false);
        draw_set_color(global.COLOR_GLOW);
        draw_set_alpha(1.0);
        draw_roundrect_ext(_bx2, _storyY, _bx2 + (_bw2 * _storyPct), _storyY + 18, 6, 6, false);
        draw_set_color(c_white);
        draw_text_transformed(_bx2 + _bw2 / 2, _storyY - 30, global.storyName + "  CORES: " + string(global.coresCleared) + "/" + string(global.storyTarget), 1.3, 1.3, 0);
        draw_set_alpha(1.0);
    }

    // Core status indicator for Planet/Story readability
    if (global.gameMode == "PLANET" || global.gameMode == "STORY") {
        var _hasCoreNow = false;
        for (var _cy2 = 0; _cy2 < global.TOTAL_ROWS; _cy2++) {
            for (var _cx2 = 0; _cx2 < global.TOTAL_COLS; _cx2++) {
                var _c2 = global.grid[_cy2][_cx2];
                if (_c2 != undefined && _c2.type == "core") { _hasCoreNow = true; break; }
            }
            if (_hasCoreNow) break;
        }
        draw_set_halign(fa_center);
        draw_set_alpha(0.95);
        draw_set_color(_hasCoreNow ? make_color_rgb(180, 255, 210) : global.COLOR_DANGER);
        draw_text_transformed(_bx2 + _bw2 / 2, _by2 + _bh2 + 56, _hasCoreNow ? "CORE: ACTIVE" : "CORE: REBUILDING", 1.1, 1.1, 0);
        draw_set_alpha(1.0);
    }

    // Overlays
    if (global.gameState == "PAUSED") {
        draw_set_color(c_black); draw_set_alpha(0.82);
        draw_rectangle(0, 0, _guiW, _guiH, false);
        draw_set_alpha(1.0); draw_set_halign(fa_center);

        draw_set_color(c_white);
        draw_text_transformed(_guiW / 2, 160, "PAUSED", 4.5, 4.5, 0);

        // Rules card
        var _cx = _guiW / 2;
        var _cw = 700; var _ch = 320;
        var _cy = 300;
        draw_set_alpha(0.15); draw_set_color(c_white);
        draw_roundrect_ext(_cx - _cw/2, _cy, _cx + _cw/2, _cy + _ch, 16, 16, false);
        draw_set_alpha(0.5); draw_set_color(global.COLOR_ACCENT);
        draw_roundrect_ext(_cx - _cw/2, _cy, _cx + _cw/2, _cy + _ch, 16, 16, true);

        draw_set_alpha(1.0);
        draw_set_color(c_yellow);
        draw_text_transformed(_cx, _cy + 24, "HOW TO PLAY", 1.4, 1.4, 0);
        draw_set_color(c_white);
        draw_text_transformed(_cx, _cy + 70,  "Connect 4+ same-color blocks to clear them", 1.1, 1.1, 0);
        draw_text_transformed(_cx, _cy + 110, "Arrow blocks only clear in a line of 4+ in their direction", 1.0, 1.0, 0);
        draw_text_transformed(_cx, _cy + 150, "Diagonal lines of 4 also count!", 1.0, 1.0, 0);
        draw_text_transformed(_cx, _cy + 195, "Aim at the glowing CORE to score big", 1.0, 1.0, 0);
        draw_set_color(make_color_rgb(160, 180, 255));
        draw_text_transformed(_cx, _cy + 245, "SPACE  Fire    Arrow Keys  Move    C / Shift  Hold", 1.0, 1.0, 0);
        draw_text_transformed(_cx, _cy + 278, "Q / E  Side Jump    Z / Up  Rotate    G  Ghost    S  Shake", 1.0, 1.0, 0);

        draw_set_color(make_color_rgb(180, 180, 180));
        draw_text_transformed(_cx, 680, "ESC  Resume", 1.5, 1.5, 0);
    }

    if (global.gameState == "GAMEOVER") {
        draw_set_color(c_black); draw_set_alpha(0.78);
        draw_rectangle(0, 0, _guiW, _guiH, false);
        draw_set_alpha(1.0); draw_set_halign(fa_center);
        draw_set_color(global.storyComplete ? c_yellow : global.COLOR_DANGER);
        draw_text_transformed(_guiW / 2, _guiH / 2 - 80, global.storyComplete ? "STORY CLEAR" : "GAME OVER", 5, 5, 0);
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

// --- Screen Vignette ---
// Darkens the corners/edges for a cinematic feel
var _vigSteps = 12;
for (var i = 0; i < _vigSteps; i++) {
    var _t   = i / _vigSteps;
    var _pad = _t * 420;
    draw_set_alpha((1 - _t) * 0.045);
    draw_set_color(c_black);
    draw_roundrect_ext(_pad, _pad, _guiW - _pad, _guiH - _pad, 80 + _pad * 0.5, 80 + _pad * 0.5, false);
}
draw_set_alpha(1.0);

dialogue_draw();
