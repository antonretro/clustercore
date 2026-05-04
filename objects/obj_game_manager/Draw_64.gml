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

    // Score flash when it changes
    if (global.score != ui_score_prev) {
        ui_score_prev  = global.score;
        ui_score_pulse = 1.0;
    }
    ui_score_pulse = max(0, ui_score_pulse - 0.05);
    var _scorePanelScale = global.TXT_H3 * global.ui_scales.score * (1.0 + ui_score_pulse * 0.3);
    if (ui_score_pulse > 0) {
        gpu_set_blendmode(bm_add);
        draw_set_alpha(ui_score_pulse * 0.18); draw_set_color(global.COLOR_ACCENT);
        draw_roundrect_ext(_lx, _lOff0, _lx + _pw, _lOff0 + _sH, 8, 8, false);
        gpu_set_blendmode(bm_normal);
    }
    draw_stat_panel(_lx, _lOff0, _pw, _sH,   "SCORE",    string(global.score),           _scorePanelScale);
    draw_stat_panel(_lx, _lOff1, _pw, _lH,   "LEVEL",    string(global.level),           global.TXT_H3 * global.ui_scales.level);
    draw_stat_panel(_lx, _lOff2, _pw, _hoH,  "HOLD [C]", "");
    draw_stat_panel(_lx, _lOff3, _pw, _bstH, "BEST",     "x" + string(global.bestCombo), global.TXT_H3 * global.ui_scales.combo);

    if (global.holdPiece != undefined) {
        var _hScale = 4.2;
        var _hcx = _lx + _pw * 0.5;
        var _hcy = _lOff2 + floor(_hoH * 0.5) + 10;
        var _hSpr = get_piece_sprite(global.holdPiece);
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
    var _qShowCount = min(2, array_length(global.nextQueue));
    for (var i = 0; i < _qShowCount; i++) {
        var _qPiece = global.nextQueue[i];
        var _qScale = (i == 0) ? 4.2 : 2.5;
        var _qcx = _rx + _pw * 0.5;
        var _qcy = (i == 0) ? (_rOff0 + floor(_nH * 0.38)) : (_rOff0 + floor(_nH * 0.75));
        var _qSpr = get_piece_sprite(_qPiece);
        draw_sprite_ext(_qSpr, 0, _qcx, _qcy, _qScale, _qScale, 0, c_white, (i == 0 ? 1.0 : 0.4));
        if (_qPiece.type == "metal") {
            var _qRot = (global.orbitalSide * 90) + (_qPiece.dir == 0 ? 90 : 0);
            draw_sprite_ext(spr_ud_arrows, 0, _qcx, _qcy, _qScale, _qScale, _qRot, c_white, (i == 0 ? 1.0 : 0.4));
        }
    }
    gpu_set_texfilter(false);

    // --- VERTICAL GAUGES (flanking the board) ---
    var _gaugeW  = 12;
    var _gaugePulse = 0.6 + abs(sin(current_time * 0.005)) * 0.4;

    // Level progress gauge (left of board)
    var _gx = _bx2 - 32;
    var _prog = clamp(global.levelScore / max(1, global.scoreToNext), 0, 1);
    var _gFillY  = _by2 + _bh2 * (1 - _prog);
    draw_set_color(c_black); draw_set_alpha(0.5);
    draw_roundrect_ext(_gx, _by2, _gx + _gaugeW, _by2 + _bh2, 5, 5, false);
    draw_set_color(global.COLOR_ACCENT); draw_set_alpha(0.85);
    draw_roundrect_ext(_gx, _gFillY, _gx + _gaugeW, _by2 + _bh2, 5, 5, false);
    if (_prog > 0.01) {
        gpu_set_blendmode(bm_add);
        draw_set_color(global.COLOR_ACCENT); draw_set_alpha(0.5 * _gaugePulse);
        draw_roundrect_ext(_gx - 2, _gFillY - 2, _gx + _gaugeW + 2, _gFillY + 6, 4, 4, false);
        gpu_set_blendmode(bm_normal);
    }
    draw_set_halign(fa_center); draw_set_alpha(0.55); draw_set_color(global.COLOR_ACCENT);
    draw_text_transformed(_gx + _gaugeW * 0.5, _by2 - 14, "LVL", global.TXT_SMALL, global.TXT_SMALL, 0);

    // Jackpot gauge (right of board)
    var _jx = _bx2 + _bw2 + 20;
    var _jackPct  = clamp(global.jackpotMeter / max(1, global.jackpotMax), 0, 1);
    var _jFillY   = _by2 + _bh2 * (1 - _jackPct);
    var _jCol     = (global.feverTimer > 0) ? c_yellow : global.COLOR_GLOW;
    draw_set_color(c_black); draw_set_alpha(0.5);
    draw_roundrect_ext(_jx, _by2, _jx + _gaugeW, _by2 + _bh2, 5, 5, false);
    draw_set_color(_jCol); draw_set_alpha(0.85);
    draw_roundrect_ext(_jx, _jFillY, _jx + _gaugeW, _by2 + _bh2, 5, 5, false);
    if (_jackPct > 0.01) {
        gpu_set_blendmode(bm_add);
        draw_set_color(_jCol); draw_set_alpha(0.5 * _gaugePulse);
        draw_roundrect_ext(_jx - 2, _jFillY - 2, _jx + _gaugeW + 2, _jFillY + 6, 4, 4, false);
        gpu_set_blendmode(bm_normal);
    }
    draw_set_halign(fa_center); draw_set_alpha(0.55); draw_set_color(_jCol);
    draw_text_transformed(_jx + _gaugeW * 0.5, _by2 - 14, "JAX", global.TXT_SMALL, global.TXT_SMALL, 0);
    draw_set_halign(fa_left);

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
        // Dark overlay
        draw_set_color(c_black); draw_set_alpha(0.75);
        draw_rectangle(0, 0, _guiW, _guiH, false);

        // Glassmorphism pause panel
        var _pw = 580; var _ph = 500;
        var _px1 = _guiW/2 - _pw/2; var _py1 = _guiH/2 - _ph/2;

        draw_set_alpha(0.5); draw_set_color(c_black);
        draw_roundrect_ext(_px1 + 8, _py1 + 8, _px1 + _pw + 8, _py1 + _ph + 8, 20, 20, false);

        var _pTop = make_color_rgb(20, 35, 70);
        var _pBot = make_color_rgb(8, 14, 32);
        draw_set_alpha(0.92);
        draw_rectangle_colour(_px1, _py1, _px1 + _pw, _py1 + _ph, _pTop, _pTop, _pBot, _pBot, false);

        draw_set_alpha(0.03); draw_set_color(c_white);
        for (var gx = _px1; gx < _px1 + _pw; gx += 40) draw_line(gx, _py1, gx, _py1 + _ph);
        for (var gy = _py1; gy < _py1 + _ph; gy += 40) draw_line(_px1, gy, _px1 + _pw, gy);

        draw_set_alpha(0.45); draw_set_color(make_color_rgb(140, 190, 255));
        draw_roundrect_ext(_px1, _py1, _px1 + _pw, _py1 + _ph, 20, 20, true);

        draw_set_halign(fa_center);

        // Title
        draw_set_alpha(1); draw_set_color(make_color_rgb(180, 220, 255));
        draw_text_transformed(_guiW/2, _py1 + 50, "SYSTEM PAUSED", global.TXT_H1, global.TXT_H1, 0);

        // Divider
        draw_set_alpha(0.25); draw_set_color(make_color_rgb(100, 180, 255));
        draw_line_width(_px1 + 60, _py1 + 80, _px1 + _pw - 60, _py1 + 80, 1);

        // Current score / info
        draw_set_alpha(0.7); draw_set_color(c_white);
        draw_text_transformed(_guiW/2, _py1 + 120, "SCORE: " + string(global.score), global.TXT_H2, global.TXT_H2, 0);
        if (global.gameMode == "STORY") {
            draw_set_alpha(0.5); draw_set_color(make_color_rgb(180, 210, 255));
            draw_text_transformed(_guiW/2, _py1 + 160, "SHARDS: " + string(global.walletShards) + "   GEMS: " + string(global.walletGems), global.TXT_H4, global.TXT_H4, 0);
        }

        // Controls list
        var _ctrlY = _py1 + 210;
        var _ctrls = [
            ["ESC / P", "RESUME GAME"],
            ["R", "RESTART LEVEL"],
            ["M", "RETURN TO MAIN MENU"],
            ["F11", "TOGGLE FULLSCREEN"]
        ];
        for (var c = 0; c < 4; c++) {
            var _ry = _ctrlY + c * 46;
            // Key badge
            draw_set_alpha(0.12); draw_set_color(c_white);
            draw_roundrect_ext(_px1 + 80, _ry - 4, _px1 + 220, _ry + 28, 6, 6, false);
            draw_set_alpha(0.9); draw_set_color(make_color_rgb(255, 220, 100));
            draw_set_halign(fa_center);
            draw_text_transformed(_px1 + 150, _ry + 12, _ctrls[c][0], 1.0, 1.0, 0);
            // Action
            draw_set_alpha(0.6); draw_set_color(make_color_rgb(180, 210, 240));
            draw_set_halign(fa_left);
            draw_text_transformed(_px1 + 240, _ry + 12, _ctrls[c][1], 1.0, 1.0, 0);
            draw_set_halign(fa_center);
        }

        // Controls hint at bottom
        draw_set_alpha(0.4); draw_set_color(make_color_rgb(150, 150, 150));
        draw_text_transformed(_guiW/2, _py1 + _ph - 50, "SPACE: DROP    ARROWS: MOVE    C: HOLD    Z/X: ROTATE    Q/E: ORBIT", global.TXT_SMALL, global.TXT_SMALL, 0);
    }


    // ── GAME OVER / LEVEL CLEAR PANEL ────────────────────────────────────────
    // ── FINISHING_LEVEL Cinematic Overlay ──────────────────────────────────
    if (global.gameState == "FINISHING_LEVEL") {
        var _fProg = 1.0 - (global.finishTimer / 180);
        var _fAlpha = clamp(_fProg * 2.5, 0, 1);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);

        // Main title fades in
        draw_set_alpha(_fAlpha);
        draw_set_color(global.COLOR_GLOW);
        draw_text_transformed(_guiW / 2, _guiH * 0.28, "LEVEL COMPLETE", global.TXT_H1 * 1.3, global.TXT_H1 * 1.3, 0);

        // Planet name
        var _worldNames = ["TIN MOON", "RUST GARDEN", "CASINO COMET", "DEAD ORBIT", "CLUSTER CORE"];
        var _worldName = "";
        if (global.storyPlanet >= 0 && global.storyPlanet < array_length(_worldNames)) {
            _worldName = _worldNames[global.storyPlanet];
        }
        if (_worldName != "") {
            draw_set_alpha(_fAlpha * 0.8);
            draw_set_color(make_color_rgb(180, 220, 255));
            draw_text_transformed(_guiW / 2, _guiH * 0.34, _worldName + " PURIFIED", global.TXT_H2, global.TXT_H2, 0);
        }

        // Rank preview near bottom
        if (_fProg > 0.3) {
            var _rankAlpha = clamp((_fProg - 0.3) * 3, 0, 1);
            draw_set_alpha(_rankAlpha * 0.9);
            draw_set_color(c_yellow);
            draw_text_transformed(_guiW / 2, _guiH * 0.72, "RANK: " + global.storyRank, global.TXT_H2, global.TXT_H2, 0);
        }

        draw_set_alpha(1);
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
    }

    if (global.gameState == "GAMEOVER" || global.gameState == "LEVEL_COMPLETE") {
        // FINISHING_LEVEL renders its own cinematic animation in Draw_0 — no panel here
        var _isComplete = (global.gameState == "LEVEL_COMPLETE");

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

        // ── ACTION BUTTONS ────────────────────────────────────────────────
        var _btnY = _py1 + 340;
        var _btnW = 200; var _btnH = 44; var _btnGap = 30;
        var _btnCount = 2;
        var _btnTotalW = _btnCount * _btnW + (_btnCount - 1) * _btnGap;
        var _btnStartX = _guiW / 2 - _btnTotalW / 2;

        if (_isComplete) {
            // NEXT LEVEL button
            var _bx1 = _btnStartX; var _bx2 = _bx1 + _btnW;
            draw_button_glass(_bx1, _btnY, _bx2, _btnY + _btnH,
                "NEXT LEVEL", make_color_rgb(100, 255, 150), true, true);
            // LEVEL SELECT button
            var _bx1b = _bx2 + _btnGap; var _bx2b = _bx1b + _btnW;
            draw_button_glass(_bx1b, _btnY, _bx2b, _btnY + _btnH,
                "LEVEL SELECT", make_color_rgb(140, 190, 255), true, false);
        } else {
            // RETRY button
            var _bx1 = _btnStartX; var _bx2 = _bx1 + _btnW;
            draw_button_glass(_bx1, _btnY, _bx2, _btnY + _btnH,
                "RETRY", make_color_rgb(255, 140, 100), true, true);
            // LEVEL SELECT button
            var _bx1b = _bx2 + _btnGap; var _bx2b = _bx1b + _btnW;
            draw_button_glass(_bx1b, _btnY, _bx2b, _btnY + _btnH,
                "LEVEL SELECT", make_color_rgb(140, 190, 255), true, false);
        }
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

// ── SHARED UI HELPER ──────────────────────────────────────────────────────────
function draw_button_glass(_x1, _y1, _x2, _y2, _label, _col, _isPrimary, _isLeft) {
    var _pulse = 0.12 + abs(sin(current_time * 0.004)) * 0.06;

    // Shadow
    draw_set_alpha(0.4); draw_set_color(c_black);
    draw_roundrect_ext(_x1 + 4, _y1 + 4, _x2 + 4, _y2 + 4, 10, 10, false);

    // Glass base
    var _bTop = merge_color(_col, make_color_rgb(20, 30, 60), 0.6);
    var _bBot = merge_color(_col, c_black, 0.75);
    draw_set_alpha(_isPrimary ? 0.9 : 0.6);
    draw_rectangle_colour(_x1, _y1, _x2, _y2, _bTop, _bTop, _bBot, _bBot, false);

    // Border
    draw_set_alpha(_isPrimary ? 1.0 : 0.5); draw_set_color(_col);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 10, 10, true);

    // Pulse glow on primary
    if (_isPrimary) {
        gpu_set_blendmode(bm_add);
        draw_set_alpha(_pulse); draw_set_color(_col);
        draw_roundrect_ext(_x1 - 2, _y1 - 2, _x2 + 2, _y2 + 2, 12, 12, true);
        gpu_set_blendmode(bm_normal);
    }

    // Label
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    draw_set_alpha(1); draw_set_color(c_white);
    draw_text_transformed((_x1 + _x2) / 2, (_y1 + _y2) / 2, _label, global.TXT_H3, global.TXT_H3, 0);

    // Key hint
    var _key = _isLeft ? "[SPACE]" : "[M]";
    draw_set_alpha(0.5); draw_set_color(_col);
    draw_text_transformed((_x1 + _x2) / 2, (_y1 + _y2) / 2 + 28, _key, global.TXT_SMALL, global.TXT_SMALL, 0);

    draw_set_halign(fa_left); draw_set_valign(fa_top);
}
