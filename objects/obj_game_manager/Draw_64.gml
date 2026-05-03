var _guiW = display_get_gui_width();
var _guiH = display_get_gui_height();
draw_set_font(main_font);
gpu_set_texfilter(false); // pixel font — keep crisp, no smoothing

// --- In-Game HUD ---
if (global.gameState == "PLAYING" || global.gameState == "PAUSED" || global.gameState == "GAMEOVER") {
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    
    // ── JUICED WAVY TEXT ─────────────────────────────────────────────────────
    // Per-character: drop shadow, rotation, scale pulse, glow, rainbow at 8+
    function draw_text_wavy(_x, _y, _text, _scale, _col) {
        var _len = string_length(_text);
        if (_len <= 0) return;
        var _t = current_time * 0.004;

        // Measure total width for centering
        var _totalW = 0;
        for (var _mi = 1; _mi <= _len; _mi++) {
            _totalW += string_width(string_char_at(_text, _mi)) * _scale;
        }
        var _curX = _x - _totalW * 0.5;

        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);

        for (var i = 1; i <= _len; i++) {
            var _char = string_char_at(_text, i);
            var _charW = string_width(_char) * _scale;
            var _charCX = _curX + _charW * 0.5;

            if (_char == " ") { _curX += _charW; continue; }

            var _phase = _t + i * 0.55;

            // Wave offsets — bigger at high combos
            var _wAmp  = 10 + min(global.comboChain, 12) * 1.5;
            var _offY  = sin(_phase * 1.3)  * _wAmp;
            var _offX  = cos(_phase * 0.9)  * (2 + global.comboChain * 0.3);
            var _rot   = sin(_phase * 0.75) * (4 + global.comboChain * 0.4);
            var _sc2   = _scale * (1.0 + abs(sin(_phase * 1.9)) * 0.13);

            var _cx4 = _charCX + _offX;
            var _cy4 = _y + _offY;

            // Color: rainbow at 8+, accent otherwise
            var _charCol = _col;
            if (global.comboChain >= 8) {
                var _hue = frac((_t * 0.4 + i * 0.11));
                var _hr = 128 + 127 * sin(_hue * 2 * pi);
                var _hg = 128 + 127 * sin(_hue * 2 * pi + 2.094);
                var _hb = 128 + 127 * sin(_hue * 2 * pi + 4.189);
                _charCol = make_color_rgb(_hr, _hg, _hb);
            }

            // 1. Drop shadow
            draw_set_color(make_color_rgb(5, 2, 20));
            draw_set_alpha(0.75);
            draw_text_transformed(_cx4 + 4, _cy4 + 5, _char, _sc2, _sc2, _rot);

            // 2. Glow bloom (additive) at 5+
            if (global.comboChain >= 5) {
                gpu_set_blendmode(bm_add);
                draw_set_color(_charCol);
                draw_set_alpha(0.22 + abs(sin(_phase * 2.1)) * 0.18);
                draw_text_transformed(_cx4, _cy4, _char, _sc2 * 1.18, _sc2 * 1.18, _rot);
                gpu_set_blendmode(bm_normal);
            }

            // 3. Main character
            draw_set_color(_charCol);
            draw_set_alpha(1.0);
            draw_text_transformed(_cx4, _cy4, _char, _sc2, _sc2, _rot);

            _curX += _charW;
        }

        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        draw_set_alpha(1.0);
    }
    // ─────────────────────────────────────────────────────────────────────────

    function draw_stat_panel(_x, _y, _w, _h, _label, _val, _scale = 2) {
        _x = floor(_x); _y = floor(_y);
        var _accentCol = (global.feverTimer > 0) ? c_yellow : global.COLOR_ACCENT;
        var _gradTop   = make_color_rgb(45, 60, 110); // Lighter blue top
        var _gradBot   = make_color_rgb(15, 20, 45);  // Deep navy bottom
        var _edgeCol   = make_color_rgb(140, 180, 255); // Frosted highlight

        // ── Pixelated Shadow (Chunky offset) ─────────────────────────────────
        draw_set_alpha(0.6);
        draw_set_color(c_black);
        draw_roundrect_ext(_x + 6, _y + 6, _x + _w + 6, _y + _h + 6, 8, 8, false);

        // ── Vertical Gradient Background ─────────────────────────────────────
        draw_set_alpha(0.8);
        draw_rectangle_colour(_x, _y, _x + _w, _y + _h, _gradTop, _gradTop, _gradBot, _gradBot, false);

        // ── Frosted Outline ──────────────────────────────────────────────────
        draw_set_alpha(0.4);
        draw_set_color(_edgeCol);
        draw_roundrect_ext(_x, _y, _x + _w, _y + _h, 8, 8, true);
        
        // Pixel-style highlight line
        draw_set_alpha(0.15);
        draw_set_color(c_white);
        draw_line_width(_x + 4, _y + 4, _x + _w - 4, _y + 4, 2);

        // ── Text Content ──────────────────────────────────────────────────────
        draw_set_halign(fa_center); draw_set_valign(fa_top);
        draw_set_alpha(0.75); draw_set_color(_accentCol);
        draw_text_transformed(floor(_x + _w * 0.5), floor(_y + 10), _label, global.TXT_SMALL, global.TXT_SMALL, 0);
        
        draw_set_halign(fa_center); draw_set_valign(fa_middle);
        draw_set_alpha(1.0); draw_set_color(c_white);
        draw_text_transformed(floor(_x + _w * 0.5), floor(_y + _h * 0.6), _val, _scale, _scale, 0);
        draw_set_valign(fa_top);
        draw_set_alpha(1.0);
    }

    // Board position (matches Draw_0)
    var _scale = global.PIXEL_SCALE;
    var _bw2 = global.COLS * 16 * _scale;
    var _bh2 = global.ROWS * 16 * _scale;
    var _bx2 = (_guiW - _bw2) / 2;
    var _entryY = (global.entry_timer * global.entry_timer) * 0.25;
    var _by2 = (_guiH - _bh2) / 2 + _entryY;

    // --- LEFT COLUMN (dynamic heights, always fills _bh2 exactly) ---
    var _pw  = 260; // Widened for better sprite visibility
    var _lx  = _bx2 - _pw - 40;
    var _gap = 12;
    var _sH  = floor(_bh2 * 0.215);
    var _lH  = floor(_bh2 * 0.146);
    var _hoH = floor(_bh2 * 0.319);
    var _bstH = _bh2 - _sH - _lH - _hoH - _gap * 3;
    var _lOff0 = _by2;
    var _lOff1 = _lOff0 + _sH  + _gap;
    var _lOff2 = _lOff1 + _lH  + _gap;
    var _lOff3 = _lOff2 + _hoH + _gap;
    draw_stat_panel(_lx, _lOff0, _pw, _sH,   "SCORE",    string(global.score),           global.TXT_H3 * global.ui_scales.score);
    draw_stat_panel(_lx, _lOff1, _pw, _lH,   "LEVEL",    string(global.level),           global.TXT_H3 * global.ui_scales.level);
    draw_stat_panel(_lx, _lOff2, _pw, _hoH,  "HOLD [C]", "");
    draw_stat_panel(_lx, _lOff3, _pw, _bstH, "BEST",     "x" + string(global.bestCombo), global.TXT_H3 * global.ui_scales.combo);

    if (global.holdPiece != undefined) {
        var _hScale = 4.2; // Upscaled from 3.5
        var _hcx = _lx + _pw * 0.5;
        var _hcy = _lOff2 + floor(_hoH * 0.5) + 10;
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
        if (global.holdPiece.type == "super_bomb") _hSpr = asset_get_index("spr_super_bomb");
        if (global.holdPiece.type == "drill") _hSpr = spr_drill;
        if (global.holdPiece.type == "dead") _hSpr = spr_deadmetal;
        gpu_set_texfilter(false);
        draw_sprite_ext(_hSpr, 0, _hcx, _hcy, _hScale, _hScale, 0, c_white, global.canHold ? 1.0 : 0.4);
        if (global.holdPiece.type == "metal") {
            var _hRot = (global.orbitalSide * 90) + (global.holdPiece.dir == 0 ? 90 : 0);
            draw_sprite_ext(spr_ud_arrows, 0, _hcx, _hcy, _hScale, _hScale, _hRot, c_white, global.canHold ? 1.0 : 0.4);
        }
        gpu_set_texfilter(false);
    }

    // --- RIGHT COLUMN (dynamic heights, always fills _bh2 exactly) ---
    var _rx  = _bx2 + _bw2 + 40;
    var _hasObj = (global.gameMode == "STORY" || global.gameMode == "BONUS");
    var _objH = _hasObj ? floor(_bh2 * 0.197) : 0;
    var _nH  = floor(_bh2 * 0.400) + (_hasObj ? 0 : floor(_bh2 * 0.197) + _gap);
    var _shH = floor(_bh2 * 0.180);
    var _coH = _bh2 - _nH - _objH - _shH - _gap * (_hasObj ? 3 : 2);
    
    var _rOff0 = _by2;
    var _rOffObj = _rOff0 + _nH + _gap;
    var _rOff1 = _hasObj ? _rOffObj + _objH + _gap : _rOff0 + _nH + _gap;
    var _rOff2 = _rOff1 + _shH + _gap;

    global.shardCounterX = _rx + _pw * 0.5;
    global.shardCounterY = _rOff1 + _shH * 0.5;

    draw_stat_panel(_rx, _rOff0, _pw, _nH,  "NEXT",   "");
    
    if (_hasObj) {
        var _objLbl = "GOAL";
        var _objVal = "";
        
        if (global.gameMode == "STORY") {
            var _storyCur = global.coresCleared;
            var _storyGoal = max(1, global.storyTarget);
            _objLbl = "CORES";
            
            if (global.storyObjectiveType == "score") {
                _storyCur = global.score;
                _storyGoal = max(1, global.storyObjectiveValue);
                _objLbl = "SCORE GOAL";
            } else if (global.storyObjectiveType == "survive_waves") {
                _storyCur = global.storyWavesSurvived;
                _storyGoal = max(1, global.storyObjectiveValue);
                _objLbl = "WAVES";
            } else if (global.storyObjectiveType == "collect_shards") {
                _storyCur = global.storyShardsCollected;
                _storyGoal = max(1, global.storyObjectiveValue);
                _objLbl = "SHARDS GOAL";
            } else if (global.storyObjectiveType == "clear_board") {
                _storyCur = max(0, instance_number(obj_block) - 1);
                _objLbl = "DEBRIS";
            }
            
            if (global.storyObjectiveType == "clear_board") _objVal = string(_storyCur);
            else _objVal = string(_storyCur) + " / " + string(_storyGoal);
            
            if (variable_global_exists("turnLimit") && global.turnLimit > 0) {
                var _turnsLeft = max(0, global.turnLimit - global.turnCount);
                _objVal += "\n" + string(_turnsLeft) + " TURNS";
            }
        } else if (global.gameMode == "BONUS") {
            _objLbl = "GOAL " + string(global.bonusScoreGoal);
            _objVal = string(ceil(global.bonusTimer / room_speed)) + " SEC";
        }
        
        draw_stat_panel(_rx, _rOffObj, _pw, _objH, _objLbl, _objVal, global.TXT_H3 * (string_pos("\n", _objVal) > 0 ? 0.70 : 1.0));
    }

    draw_stat_panel(_rx, _rOff1, _pw, _shH, "SHARDS", string(global.walletShards),              global.TXT_H3);
    draw_stat_panel(_rx, _rOff2, _pw, _coH, "CLUSTER COMBO",  "x" + string(global.comboChain),          global.TXT_H3 * global.ui_scales.combo);
    draw_sprite_ext(spr_gemshard, 0, _rx + 42, global.shardCounterY + 8, 1.7, 1.7, 0, c_white, 1);

    gpu_set_texfilter(false);
    for (var i = 0; i < array_length(global.nextQueue); i++) {
        var _qPiece = global.nextQueue[i];
        var _qScale = (i == 0) ? 4.2 : 2.5; // Upscaled from 3.5 / 2.2
        var _qcx = _rx + _pw * 0.5;
        var _qcy = _rOff0 + floor(_nH * 0.5) + (i == 0 ? 10 : 60);
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
        if (_qPiece.type == "super_bomb") _qSpr = asset_get_index("spr_super_bomb");
        if (_qPiece.type == "drill") _qSpr = spr_drill;
        if (_qPiece.type == "dead") _qSpr = spr_deadmetal;
        draw_sprite_ext(_qSpr, 0, _qcx, _qcy, _qScale, _qScale, 0, c_white, (i == 0 ? 1.0 : 0.4));
        if (_qPiece.type == "metal") {
            var _qRot = (global.orbitalSide * 90) + (_qPiece.dir == 0 ? 90 : 0);
            draw_sprite_ext(spr_ud_arrows, 0, _qcx, _qcy, _qScale, _qScale, _qRot, c_white, (i == 0 ? 1.0 : 0.4));
        }
    }
    gpu_set_texfilter(false);

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

        // Determine tier
        var _celebration = "NICE!";
        var _celebCol    = global.COLOR_ACCENT;
        var _celebBase   = global.TXT_H1;

        if (global.comboChain >= 5) {
            _celebration = "GREAT!!";
            _celebCol    = make_color_rgb(100, 255, 160);
            _celebBase   = global.TXT_H1 * 1.1;
        }
        if (global.comboChain >= 8) {
            _celebration = "AMAZING!!!";
            _celebCol    = make_color_rgb(255, 200, 60);
            _celebBase   = global.TXT_H1 * 1.25;
        }
        if (global.comboChain >= 12) {
            _celebration = "INSANE!!!!";
            _celebCol    = make_color_rgb(255, 100, 240);
            _celebBase   = global.TXT_H1 * 1.45;
        }
        if (global.comboChain >= 16) {
            _celebration = "LEGENDARY!!!!!";
            _celebCol    = make_color_rgb(255, 230, 80);
            _celebBase   = global.TXT_H1 * 1.7;
        }
        if (global.comboChain >= 20) {
            _celebration = "\u22c6 UNREAL \u22c6";
            _celebCol    = c_white;
            _celebBase   = global.TXT_H1 * 2.0;
        }
        if (global.feverTimer > 0) {
            _celebCol  = c_yellow;
            _celebBase *= 1.12;
        }

        // Pop-in burst: detect label change
        if (_celebration != combo_pop_label) {
            combo_pop_label = _celebration;
            combo_pop_t = 0;
        }
        combo_pop_t = min(combo_pop_t + 0.06, 1.0);

        // Ease-out elastic pop scale
        var _popEase = 1 - power(1 - combo_pop_t, 3);
        var _popBounce = 1.0 + (1.0 - _popEase) * 0.6; // starts 1.6x, settles to 1.0
        var _celebScale = _celebBase * _popBounce;

        draw_text_wavy(_guiW * 0.5, _by2 - 58, _celebration, _celebScale, _celebCol);

        // Combo chain counter badge below the word
        var _badgeAlpha = _popEase;
        draw_set_halign(fa_center);
        draw_set_alpha(_badgeAlpha * 0.9);
        draw_set_color(_celebCol);
        draw_text_transformed(_guiW * 0.5, _by2 - 8, string(global.comboChain) + "x COMBO", global.TXT_H3, global.TXT_H3, 0);
    } else {
        combo_pop_t = 0;
        combo_pop_label = "";
    }

    draw_set_halign(fa_center);
    var _feverLabel = (global.feverTimer > 0) ? "CLUSTER FEVER" : "";
    draw_text_wavy(_bx2 + _bw2 / 2, _by2 + _bh2 + 26, _feverLabel, global.TXT_H3, c_yellow);
    
    // Overlays
    if (global.gameState == "PAUSED") {
        draw_set_color(c_black); draw_set_alpha(0.85);
        draw_rectangle(0, 0, _guiW, _guiH, false);
        draw_set_alpha(1.0); draw_set_halign(fa_center);
        
        draw_set_color(c_white);
        draw_text_transformed(_guiW/2, _guiH/2 - 120, "PAUSED", global.TXT_H1, global.TXT_H1, 0);
        
        draw_set_color(make_color_rgb(180, 200, 255));
        draw_text_transformed(_guiW/2, _guiH/2 - 20, "ESC / P - Resume", global.TXT_H2, global.TXT_H2, 0);
        draw_text_transformed(_guiW/2, _guiH/2 + 20, "R - Restart Level", global.TXT_H2, global.TXT_H2, 0);
        draw_text_transformed(_guiW/2, _guiH/2 + 60, "F11 - Toggle Fullscreen", global.TXT_H2, global.TXT_H2, 0);
        draw_text_transformed(_guiW/2, _guiH/2 + 100, "M - Return to Main Menu", global.TXT_H2, global.TXT_H2, 0);
        
        draw_set_color(make_color_rgb(150, 150, 150));
        draw_text_transformed(_guiW/2, _guiH/2 + 200, "HOW TO PLAY", global.TXT_H3, global.TXT_H3, 0);
        draw_text_transformed(_guiW/2, _guiH/2 + 230, "Space: Drop | Arrows: Move | C: Hold", global.TXT_SMALL, global.TXT_SMALL, 0);
        draw_text_transformed(_guiW/2, _guiH/2 + 260, "Q/E: Orbital Side | Z/Up: Rotate", global.TXT_SMALL, global.TXT_SMALL, 0);
    }


    // ── GAME OVER / LEVEL CLEAR PANEL ────────────────────────────────────────
    if (global.gameState == "GAMEOVER" || global.gameState == "FINISHING_LEVEL" || global.gameState == "LEVEL_COMPLETE") {
        var _isComplete = (global.gameState == "FINISHING_LEVEL" || global.gameState == "LEVEL_COMPLETE");

        // --- Central Glass Panel ---
        var _pw = 660;
        var _ph = 420;
        var _px1 = _guiW / 2 - _pw / 2;
        var _py1 = _guiH / 2 - _ph / 2;
        var _px2 = _px1 + _pw;
        var _py2 = _py1 + _ph;

        // Shadow
        draw_set_alpha(0.55);
        draw_set_color(c_black);
        draw_roundrect_ext(_px1 + 10, _py1 + 10, _px2 + 10, _py2 + 10, 20, 20, false);

        // Glassmorphism background
        var _cTop = make_color_rgb(20, 32, 62);
        var _cBot = make_color_rgb(8, 12, 30);
        draw_set_alpha(0.93);
        draw_rectangle_colour(_px1, _py1, _px2, _py2, _cTop, _cTop, _cBot, _cBot, false);

        // Grid texture
        draw_set_alpha(0.025); draw_set_color(c_white);
        for (var gx = _px1; gx < _px2; gx += 44) draw_line(gx, _py1, gx, _py2);
        for (var gy = _py1; gy < _py2; gy += 44) draw_line(_px1, gy, _px2, gy);

        // Panel border
        draw_set_alpha(0.45);
        draw_set_color(make_color_rgb(140, 190, 255));
        draw_roundrect_ext(_px1, _py1, _px2, _py2, 20, 20, true);

        // Inner glow
        gpu_set_blendmode(bm_add);
        draw_set_alpha(0.1); draw_set_color(make_color_rgb(100, 200, 255));
        draw_roundrect_ext(_px1 + 3, _py1 + 3, _px2 - 3, _py2 - 3, 18, 18, true);
        gpu_set_blendmode(bm_normal);

        draw_set_alpha(1.0);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);

        // Title bar
        var _title = _isComplete ? "MISSION COMPLETE" : "SIGNAL LOST";
        var _titleCol = _isComplete ? make_color_rgb(100, 255, 150) : make_color_rgb(255, 80, 80);

        // Title background strip
        draw_set_alpha(0.12);
        draw_set_color(_isComplete ? make_color_rgb(80, 255, 120) : make_color_rgb(255, 60, 60));
        draw_roundrect_ext(_px1 + 20, _py1 - 30, _px2 - 20, _py1 + 130, 14, 14, false);

        draw_set_color(_titleCol);
        draw_text_transformed(_guiW / 2, _py1 + 55, _title, global.TXT_H1, global.TXT_H1, 0);

        // Divider
        draw_set_alpha(0.2); draw_set_color(make_color_rgb(140, 190, 255));
        draw_line_width(_px1 + 80, _py1 + 100, _px2 - 80, _py1 + 100, 1);

        // Score
        draw_set_color(c_white);
        draw_text_transformed(_guiW / 2, _py1 + 145, "FINAL SCORE: " + string(global.score), global.TXT_H2, global.TXT_H2, 0);

        if (_isComplete) {
            // Turn bonus
            draw_set_color(c_yellow);
            draw_text_transformed(_guiW / 2, _py1 + 200, "TURN BONUS: +" + string(global.storyBonus), global.TXT_H3, global.TXT_H3, 0);

            // Rank display with background glow
            var _rankCol = c_white;
            var _rankGlow = c_white;
            switch(global.storyRank) {
                case "S": _rankCol = make_color_rgb(255, 220, 50);  _rankGlow = make_color_rgb(255, 200, 0);   break;
                case "A": _rankCol = make_color_rgb(100, 255, 150); _rankGlow = make_color_rgb(80, 220, 100);  break;
                case "B": _rankCol = make_color_rgb(150, 220, 255); _rankGlow = make_color_rgb(100, 180, 255); break;
                case "C": _rankCol = make_color_rgb(255, 200, 100); _rankGlow = make_color_rgb(255, 160, 50);  break;
                default:  _rankCol = make_color_rgb(200, 200, 200); _rankGlow = make_color_rgb(150, 150, 150); break;
            }

            // Rank glow
            gpu_set_blendmode(bm_add);
            draw_set_alpha(0.18 + abs(sin(current_time * 0.004)) * 0.06);
            draw_set_color(_rankGlow);
            draw_circle(_guiW / 2, _py1 + 290, 45, false);
            gpu_set_blendmode(bm_normal);

            // Rank text
            draw_set_alpha(1.0);
            draw_set_color(_rankCol);
            draw_text_transformed(_guiW / 2, _py1 + 260, "RANK: " + global.storyRank, global.TXT_H1, global.TXT_H1, 0);

            // Shard reward for story mode
            if (global.runShards > 0) {
                draw_set_alpha(0.7); draw_set_color(make_color_rgb(180, 230, 255));
                draw_text_transformed(_guiW / 2, _py1 + 310, "+" + string(global.runShards) + " SHARDS COLLECTED", global.TXT_H4, global.TXT_H4, 0);
            }
        } else {
            // Game over stats
            draw_set_color(make_color_rgb(180, 200, 255));
            draw_text_transformed(_guiW / 2, _py1 + 200, "BEST: " + string(global.highScore), global.TXT_H2, global.TXT_H2, 0);
            draw_set_color(c_white);
            draw_text_transformed(_guiW / 2, _py1 + 250, "COMBO: x" + string(global.bestCombo), global.TXT_H3, global.TXT_H3, 0);
        }

        // Action prompts
        draw_set_color(make_color_rgb(255, 214, 102));
        var _promptY = _py2 - 30;
        var _prompt = _isComplete ? "SPACE  Continue     ESC  Menu" : "R  Retry     ESC  Menu";
        draw_text_transformed(_guiW / 2, _promptY, _prompt, global.TXT_H3, global.TXT_H3, 0);
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
