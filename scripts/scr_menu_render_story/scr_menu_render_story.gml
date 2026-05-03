/// @module scr_menu_render_story
/// Story Mode and Galaxy/Planet selection screens.

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

    // Dwarf Routes cluster
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

    // Planets (two-pass depth sort)
    for (var _pass = 0; _pass < 2; _pass++) {
        for (var i = 0; i < array_length(story_worlds); i++) {
            var _w = story_worlds[i];
            var _rx = 130 + i * 84;
            var _ry = _rx * _w.tilt;
            var _ang = _w.ang + story_solar_spin * (0.55 + i * 0.08);
            var _depth = (lengthdir_y(1, _ang) + 1) * 0.5;
            var _front = (_depth >= 0.5);
            if ((_pass == 0 && _front) || (_pass == 1 && !_front)) continue;

            var _orbPX = _sunX + lengthdir_x(_rx * _zoomScale, _ang);
            var _orbPY = _sunY + lengthdir_y(_ry * _zoomScale, _ang);
            var _sel = (i == story_select_index);

            // Selected planet moves to focus; others fan out to prevent clumping
            var _focusX = _spaceCX + 100;
            var _focusY = _cy + 20;

            var _spreadAngle = (i - story_select_index) * 55 + 90;
            var _spreadDist = 180 + abs(i - story_select_index) * 70;
            var _spreadX = _focusX + lengthdir_x(_spreadDist, _spreadAngle);
            var _spreadY = _focusY + lengthdir_y(_spreadDist * 0.4, _spreadAngle);

            var _px = lerp(_orbPX, _spreadX, zoom_lerp);
            var _py = lerp(_orbPY, _spreadY, zoom_lerp);

            var _scaleP = 0.72 + (_depth * 0.58);
            if (_sel) _scaleP += 0.22 + zoom_lerp * 0.55;
            var _rad = _w.size * _scaleP * _zoomScale * (1.0 + zoom_lerp * 0.5);
            // Non-selected planets fade out much more during zoom
            var _alphaMul = _sel ? 1.0 : max(0.08, 1.0 - zoom_lerp * 1.15);

            // Shadow
            draw_set_alpha((0.20 + _depth * 0.18) * _alphaMul); draw_set_color(c_black);
            draw_ellipse(_px - _rad * 1.15, _py + _rad * 0.78, _px + _rad * 1.15, _py + _rad * 1.18, false);

            var _unlocked = story_progress_is_unlocked(i, 0);
            draw_planet(_px, _py, _rad, _w, _unlocked, _sel, true);

            // Special rings
            if (i == 2 || i == 4) {
                draw_set_alpha((_sel ? 0.70 : 0.36) * _alphaMul);
                draw_set_color(i == 2 ? make_color_rgb(255, 230, 120) : make_color_rgb(185, 150, 255));
                draw_ellipse(_px - _rad * 1.65 * _zoomScale, _py - _rad * 0.36 * _zoomScale,
                             _px + _rad * 1.65 * _zoomScale, _py + _rad * 0.36 * _zoomScale, true);
            }

            // Moon sprites
            var _moonSprite = -1;
            switch(i) {
                case 2: _moonSprite = asset_get_index("spr_earthmoon"); break;
                case 4: _moonSprite = asset_get_index("spr_jupitermoon"); break;
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
                    var _ss = (_rad * 2.6) / sprite_get_width(_spo);
                    draw_set_alpha(0.55 * _alphaMul);
                    draw_sprite_ext(_spo, 0, _px, _py, _ss, _ss, story_solar_spin * 0.3, c_white, 1);
                }
            }
        }
    }

    // Wallet bar
    draw_set_halign(fa_right);
    draw_set_alpha(0.55); draw_set_color(make_color_rgb(180, 230, 255));
    draw_text_transformed(_sw - 40, _sh - 30, "SHARDS " + string(global.walletShards) + "   GEMS " + string(global.walletGems), global.TXT_SMALL, global.TXT_SMALL, 0);
}

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
