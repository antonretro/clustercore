draw_clear(make_color_rgb(6, 7, 16));

var _cx = room_width * 0.5;
var _h  = room_height;

draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_font(main_font);
gpu_set_texfilter(false); // pixel font — no smoothing

// ── Nine-slice UI helpers ──────────────────────────────────────────────────
// draw_ui_panel(x1,y1,x2,y2)  — large panel, uses spr_ui_panel
// draw_ui_button(x1,y1,x2,y2, selected) — menu button, uses spr_ui_button
// Both fall back to procedural roundrects if sprites not yet created.

draw_ui_panel = function(_x1, _y1, _x2, _y2, _alpha = 1.0) {
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
};

draw_ui_button = function(_x1, _y1, _x2, _y2, _selected = false) {
    var _w = _x2 - _x1; var _h2 = _y2 - _y1;
    if (sprite_exists(spr_ui_button)) {
        var _tint = _selected ? make_color_rgb(180, 210, 255) : c_white;
        draw_set_alpha(_selected ? 0.30 : 0.10);
        draw_sprite_stretched_ext(spr_ui_button, 0, _x1, _y1, _w, _h2, _tint, _selected ? 0.30 : 0.10);
        draw_set_alpha(1.0);
        draw_sprite_stretched_ext(spr_ui_button, 0, _x1, _y1, _w, _h2, _tint, 1.0);
        if (_selected) {
            // Accent bar on left edge
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
};
// ──────────────────────────────────────────────────────────────────────────

// Radial rays
for (var _ray = 0; _ray < 24; _ray++) {
    var _ang = (_ray / 24) * 360;
    draw_set_alpha(0.04); draw_set_color(make_color_rgb(100, 160, 255));
    draw_line_width(_cx, 220, _cx + lengthdir_x(1200, _ang), 220 + lengthdir_y(1200, _ang), 2);
}
draw_set_alpha(1);

// ── TITLE SCREEN ─────────────────────────────────────────────────────────
if (in_title) {
    var _lW = sprite_get_width(spr_logo); var _lH = sprite_get_height(spr_logo);
    var _logoScale = min(860/_lW, 240/_lH);
    var _logoFloat = sin(current_time * 0.0018) * 14;

    // Glow behind logo
    gpu_set_blendmode(bm_add);
    draw_set_alpha(0.12 + abs(sin(current_time * 0.002)) * 0.08);
    draw_set_color(make_color_rgb(80, 140, 255));
    draw_ellipse(_cx - 320, 310 + _logoFloat - 60, _cx + 320, 310 + _logoFloat + 60, false);
    gpu_set_blendmode(bm_normal);

    draw_set_alpha(1);
    draw_sprite_ext(spr_logo, 0, _cx, 310 + _logoFloat, _logoScale, _logoScale, 0, c_white, 1);

    // Press Start — blink after 60 frames
    var _blink = (floor(current_time / 380) mod 2) == 0;
    if (title_timer > 60 && _blink) {
        draw_set_color(c_white);
        draw_set_alpha(0.95);
        draw_text_transformed(_cx, 560, "PRESS  START", 2, 2, 0);
    } else if (title_timer <= 60) {
        // Fade in hint
        draw_set_alpha(min(title_timer / 60.0, 1.0) * 0.4);
        draw_set_color(c_white);
        draw_text_transformed(_cx, 560, "PRESS  START", 2, 2, 0);
    }

    // Copyright
    draw_set_alpha(0.45);
    draw_set_color(make_color_rgb(130, 150, 190));
    draw_text_transformed(_cx, _h - 70, "© 2025  ANTON RETRO  —  ALL RIGHTS RESERVED", 1, 1, 0);

    // Version tag
    draw_set_alpha(0.28);
    draw_text_transformed(_cx, _h - 40, "CLUSTER CORE  v1.0", 0.85, 0.85, 0);

    draw_set_alpha(1);
    draw_set_halign(fa_left); draw_set_valign(fa_top);
    exit;
}
// ─────────────────────────────────────────────────────────────────────────

// Logo (shown on all non-title screens)
var _lW = sprite_get_width(spr_logo); var _lH = sprite_get_height(spr_logo);
draw_sprite_ext(spr_logo, 0, _cx, 200, min(700/_lW, 200/_lH), min(700/_lW, 200/_lH), 0, c_white, 1);

// Subtitle
draw_set_color(make_color_rgb(120, 140, 180));
draw_text_transformed(_cx, 330, "JACKPOT PUZZLE MACHINE", 1.1, 1.1, 0);

// Divider
draw_set_alpha(0.2); draw_set_color(make_color_rgb(100, 150, 255));
draw_line_width(_cx - 280, 368, _cx + 280, 368, 1); draw_set_alpha(1);

if (in_refabricator) {
    draw_set_color(c_white);
    draw_text_transformed(_cx, 380, "REFABRICATOR SHIP", global.TXT_H1, global.TXT_H1, 0);
    draw_ui_panel(_cx - 310, 450, _cx + 310, 730);
    draw_set_alpha(1);
    draw_sprite_ext(spr_gemshard, 0, _cx - 140, 535, 4, 4, 0, c_white, 1);
    draw_sprite_ext(spr_gem, 0, _cx + 140, 535, 4, 4, 0, c_white, 1);
    draw_set_color(make_color_rgb(200, 230, 255));
    draw_text_transformed(_cx, 610, "25 SHARDS  ->  1 GEM", global.TXT_H3, global.TXT_H3, 0);
    draw_set_color(make_color_rgb(255, 220, 90));
    draw_text_transformed(_cx, 665, "SHARDS " + string(global.walletShards) + "     GEMS " + string(global.walletGems), global.TXT_H4, global.TXT_H4, 0);
    draw_set_alpha(0.5); draw_set_color(make_color_rgb(255,214,102));
    draw_text_transformed(_cx, _h - 60, "A / Enter  Refabricate     B / Esc  Back", global.TXT_SMALL, global.TXT_SMALL, 0);
    draw_set_alpha(1); draw_set_halign(fa_left); draw_set_valign(fa_top);
    exit;
}

if (in_story_select && !in_bonus_select) {
    draw_set_color(c_white);
    draw_text_transformed(_cx, 365, "STORY: SOLAR SYSTEM", global.TXT_H1, global.TXT_H1, 0);

    var _sunX = _cx;
    var _sunY = 620;
    var _sunPulse = 0.65 + abs(sin(current_time * 0.003)) * 0.25;

    for (var _st = 0; _st < 56; _st++) {
        var _sxStar = ((_st * 347 + floor(current_time * 0.006)) mod 1840) + 40;
        var _syStar = ((_st * 191) mod 600) + 390;
        draw_set_alpha(0.08 + ((_st mod 5) * 0.035));
        draw_set_color(make_color_rgb(170, 205, 255));
        draw_circle(_sxStar, _syStar, 1 + (_st mod 2), false);
    }
    draw_set_alpha(1);

    for (var _orb = array_length(story_worlds) - 1; _orb >= 0; _orb--) {
        var _rxOrb = 130 + _orb * 84;
        var _ryOrb = _rxOrb * story_worlds[_orb].tilt;
        draw_set_alpha(0.10 + (_orb * 0.015));
        draw_set_color(make_color_rgb(110, 160, 255));
        draw_ellipse(_sunX - _rxOrb, _sunY - _ryOrb, _sunX + _rxOrb, _sunY + _ryOrb, true);
    }

    gpu_set_blendmode(bm_add);
    draw_set_alpha(_sunPulse);
    draw_set_color(make_color_rgb(255, 215, 100));
    draw_circle_color(_sunX, _sunY, 56, c_yellow, make_color_rgb(255, 120, 40), false);
    draw_set_alpha(0.18);
    draw_circle_color(_sunX, _sunY, 150, make_color_rgb(255, 190, 80), c_black, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
    draw_set_color(make_color_rgb(255, 235, 150));
    draw_text_transformed(_sunX, _sunY, "SUN GATE", global.TXT_SMALL, global.TXT_SMALL, 0);

    draw_set_alpha(0.9);
    draw_set_color(make_color_rgb(95, 190, 255));
    draw_triangle(_sunX - 520, _sunY - 90, _sunX - 470, _sunY - 108, _sunX - 470, _sunY - 72, false);
    draw_set_color(make_color_rgb(180, 240, 255));
    draw_text_transformed(_sunX - 500, _sunY - 135, "REFABRICATOR", global.TXT_SMALL, global.TXT_SMALL, 0);

    draw_set_alpha(0.9);
    draw_set_color(make_color_rgb(115, 220, 255));
    for (var _dw = 0; _dw < array_length(bonus_planet_names); _dw++) {
        var _dwAng = (_dw / array_length(bonus_planet_names)) * 360 - story_solar_spin * 1.6;
        var _dwX = _sunX + 520 + lengthdir_x(70, _dwAng);
        var _dwY = _sunY - 94 + lengthdir_y(28, _dwAng);
        draw_circle_color(_dwX, _dwY, 8 + (_dw mod 2) * 3, make_color_rgb(115, 220, 255), make_color_rgb(35, 65, 120), false);
    }
    draw_set_color(make_color_rgb(180, 240, 255));
    draw_text_transformed(_sunX + 520, _sunY - 135, "DWARF ROUTES", global.TXT_SMALL, global.TXT_SMALL, 0);

    for (var _pass = 0; _pass < 2; _pass++) {
        for (var i = 0; i < array_length(story_worlds); i++) {
            var _w = story_worlds[i];
            var _rx = 130 + i * 84;
            var _ry = _rx * _w.tilt;
            var _ang = _w.ang + story_solar_spin * (0.55 + i * 0.08);
            var _depth = (lengthdir_y(1, _ang) + 1) * 0.5;
            var _front = (_depth >= 0.5);
            if ((_pass == 0 && _front) || (_pass == 1 && !_front)) continue;

            var _px = _sunX + lengthdir_x(_rx, _ang);
            var _py = _sunY + lengthdir_y(_ry, _ang);
            var _sel = (i == story_select_index);
            var _scaleP = 0.72 + (_depth * 0.58);
            if (_sel) _scaleP += in_story_level_select ? 0.34 : 0.18;
            var _rad = _w.size * _scaleP;

            draw_set_alpha(0.20 + _depth * 0.18);
            draw_set_color(c_black);
            draw_ellipse(_px - _rad * 1.15, _py + _rad * 0.78, _px + _rad * 1.15, _py + _rad * 1.18, false);

            if (_sel) {
                gpu_set_blendmode(bm_add);
                draw_set_alpha(0.42 + _depth * 0.2);
                draw_set_color(make_color_rgb(255, 230, 120));
                draw_circle(_px, _py, _rad + 18, true);
                gpu_set_blendmode(bm_normal);
            }

            var _unlocked = story_progress_is_unlocked(i, 0);
            draw_set_alpha(_sel ? 1.0 : 0.74);
            var _pColA = _unlocked ? _w.color_a : merge_color(_w.color_a, c_black, 0.7);
            var _pColB = _unlocked ? _w.color_b : merge_color(_w.color_b, c_black, 0.7);
            draw_circle_color(_px, _py, _rad, _pColA, _pColB, false);

            if (!_unlocked) {
                draw_set_color(c_white); draw_set_alpha(0.6);
                draw_text_transformed(_px, _py, "LOCKED", 0.5 * _scaleP, 0.5 * _scaleP, 0);
            }

            draw_set_alpha(0.38);
            draw_set_color(c_black);
            draw_circle(_px - _rad * 0.28, _py + _rad * 0.08, _rad * 0.82, false);

            draw_set_alpha(_sel ? 0.92 : 0.52);
            draw_set_color(_unlocked ? make_color_rgb(235, 250, 255) : c_gray);
            draw_circle(_px + _rad * 0.30, _py - _rad * 0.34, max(2, _rad * 0.18), false);

            if (i == 2 || i == 4) {
                draw_set_alpha(_sel ? 0.70 : 0.36);
                draw_set_color(i == 2 ? make_color_rgb(255, 230, 120) : make_color_rgb(185, 150, 255));
                draw_ellipse(_px - _rad * 1.65, _py - _rad * 0.36, _px + _rad * 1.65, _py + _rad * 0.36, true);
            }

            draw_set_alpha(_sel ? 1.0 : 0.62);
            draw_set_color(_sel ? c_white : make_color_rgb(180, 195, 220));
            draw_text_transformed(_px, _py - _rad - 22, _w.name, _sel ? 0.88 : 0.68, _sel ? 0.88 : 0.68, 0);
        }
    }

    var _lvlCountLbl = story_world_level_counts[story_select_index];
    var _missionName = story_level_names[story_select_index][story_level_index];
    var _def = story_get_level_def(story_select_index, story_level_index);
    var _objText = "OBJECTIVE PENDING";
    if (_def != undefined && variable_struct_exists(_def, "objective")) {
        if (_def.objective.type == "clear_cores") _objText = "CLEAR " + string(_def.objective.value) + " CORES";
        if (_def.objective.type == "score") _objText = "SCORE " + string(_def.objective.value);
        if (_def.objective.type == "survive_waves") _objText = "SURVIVE " + string(_def.objective.value) + " WAVES";
        if (_def.objective.type == "collect_shards") _objText = "COLLECT " + string(_def.objective.value) + " SHARDS";
    }

    if (in_story_level_select) {
        var _pw = 360;
        var _ph = 430;
        var _pxPanel = _cx + 420;
        var _pyPanel = 450;
        draw_ui_panel(_pxPanel, _pyPanel, _pxPanel + _pw, _pyPanel + _ph);
        draw_set_alpha(1.0); draw_set_color(c_white);
        draw_text_transformed(_pxPanel + _pw * 0.5, _pyPanel + 34, "SELECT LEVEL", global.TXT_H2, global.TXT_H2, 0);

        var _lvlCount = story_world_level_counts[story_select_index];
        for (var _li = 0; _li < _lvlCount; _li++) {
            var _yy = _pyPanel + 80 + _li * 54;
            var _unlockedL = story_progress_is_unlocked(story_select_index, _li);
            var _selL = (_li == story_level_index);
            draw_set_alpha(_selL ? 0.32 : 0.12);
            draw_set_color(_selL ? make_color_rgb(110, 220, 255) : c_white);
            if (!_unlockedL) draw_set_color(c_dkgray);
            draw_roundrect_ext(_pxPanel + 24, _yy - 18, _pxPanel + _pw - 24, _yy + 18, 8, 8, false);
            
            draw_set_alpha(1.0); 
            var _txtCol = _selL ? make_color_rgb(255, 225, 120) : make_color_rgb(190, 205, 235);
            if (!_unlockedL) _txtCol = c_gray;
            draw_set_color(_txtCol);
            
            var _lvlName = _unlockedL ? story_level_names[story_select_index][_li] : "LOCKED";
            draw_text_transformed(_pxPanel + _pw * 0.5, _yy, string(_li + 1) + "  " + _lvlName, _selL ? global.TXT_H4 : global.TXT_SMALL, _selL ? global.TXT_H4 : global.TXT_SMALL, 0);
        }
    }

    draw_ui_panel(_cx - 360, 826, _cx + 360, 912);
    draw_set_alpha(1);
    draw_set_color(make_color_rgb(255, 220, 90));
    draw_text_transformed(_cx, 850, story_worlds[story_select_index].name + "   " + string(_lvlCountLbl) + " MISSIONS", global.TXT_H3, global.TXT_H3, 0);
    draw_set_color(c_white);
    draw_text_transformed(_cx, 884, "MISSION " + string(story_level_index + 1) + ": " + _missionName + "     " + _objText, global.TXT_H4, global.TXT_H4, 0);

    draw_set_alpha(0.45); draw_set_color(make_color_rgb(255,214,102));
    if (in_story_level_select) {
        draw_text_transformed(_cx, _h - 60, "Up/Down Select Level   A Start Level   D / Y Dwarf Routes   S / X Shop   B Back", global.TXT_SMALL, global.TXT_SMALL, 0);
    } else {
        draw_text_transformed(_cx, _h - 60, "Left/Right Select Planet   A Open Levels   D / Y Dwarf Routes   S / X Shop   B Back", global.TXT_SMALL, global.TXT_SMALL, 0);
    }

    dialogue_draw();
    draw_set_alpha(1); draw_set_halign(fa_left); draw_set_valign(fa_top);
    exit;
}

if (in_refabricator) {
    draw_set_color(c_black); draw_set_alpha(0.8);
    draw_rectangle(0, 0, _w, _h, false);
    draw_set_alpha(1.0);
    
    draw_ui_panel(_cx - 400, _cy - 200, _cx + 400, _cy + 200);
    
    draw_set_color(make_color_rgb(180, 240, 255));
    draw_text_transformed(_cx, _cy - 120, "REFABRICATOR", global.TXT_H1, global.TXT_H1, 0);
    
    draw_set_color(c_white);
    draw_text_transformed(_cx, _cy - 30, "Condense planetary debris into pure Core Gems.", global.TXT_H4, global.TXT_H4, 0);
    
    draw_set_color(make_color_rgb(255, 214, 102));
    draw_text_transformed(_cx, _cy + 40, "25 SHARDS = 1 GEM", global.TXT_H2, global.TXT_H2, 0);
    
    draw_set_color(make_color_rgb(180, 195, 220));
    draw_text_transformed(_cx, _cy + 130, "A / ENTER: Fabricate Gem     B / ESC: Back", global.TXT_SMALL, global.TXT_SMALL, 0);
    
    draw_set_halign(fa_left); draw_set_valign(fa_top);
    exit;
}

if (in_bonus_select) {
    draw_set_color(c_white);
    draw_text_transformed(_cx, 380, "STORY: DWARF ROUTES", global.TXT_H1, global.TXT_H1, 0);

    var _baseY = 585;
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

    draw_ui_panel(_cx - 350, 800, _cx + 350, 900);
    draw_set_alpha(1);
    draw_set_color(make_color_rgb(255, 220, 90));
    draw_text_transformed(_cx, 828, bonus_planet_names[bonus_select_index], global.TXT_H2, global.TXT_H2, 0);
    draw_set_color(c_white);
    draw_text_transformed(_cx, 866, "90-120 SEC SCORE ATTACK     GOAL " + string(bonus_planet_goals[bonus_select_index]) + "     REWARD +" + string(bonus_planet_rewards[bonus_select_index]) + " SHARDS", global.TXT_H4, global.TXT_H4, 0);
    draw_set_alpha(0.45); draw_set_color(make_color_rgb(255,214,102));
    draw_text_transformed(_cx, _h - 60, "Left/Right Select Dwarf Route   A Start Bonus Mission   B Back To Solar System", global.TXT_SMALL, global.TXT_SMALL, 0);
    draw_set_alpha(1); draw_set_halign(fa_left); draw_set_valign(fa_top);
    exit;
}

// SETTINGS SCREEN
if (in_settings) {
    draw_set_color(c_white);
    draw_text_transformed(_cx, 380, "SETTINGS", global.TXT_H1, global.TXT_H1, 0);

    var _vals = [global.settings.ghostEnabled, global.settings.shakeEnabled];
    var _sy   = 460; var _gap = 70;
    for (var i = 0; i < array_length(settings_items); i++) {
        var _sel  = (i == settings_index);
        var _col  = _sel ? make_color_rgb(255, 220, 80) : make_color_rgb(180, 195, 220);
        var _valC = _vals[i] ? make_color_rgb(100, 230, 100) : make_color_rgb(220, 80, 80);
        draw_set_alpha(1); draw_set_color(_col);
        draw_text_transformed(_cx - 80, _sy + i*_gap, settings_items[i], global.TXT_H3, global.TXT_H3, 0);
        draw_set_color(_valC);
        draw_text_transformed(_cx + 100, _sy + i*_gap, _vals[i] ? "ON" : "OFF", global.TXT_H3, global.TXT_H3, 0);
    }
    draw_set_alpha(0.5); draw_set_color(make_color_rgb(255, 214, 102));
    draw_text_transformed(_cx, _h - 60, "Enter / Space / A  Toggle     Esc / B  Back", global.TXT_SMALL, global.TXT_SMALL, 0);
    draw_set_alpha(1); draw_set_halign(fa_left); draw_set_valign(fa_top);
    exit;
}

// ── MAIN MENU — 2×2 CARD GRID ─────────────────────────────────────────────
var _cardW   = 420;
var _cardH   = 310;
var _cardGap = 28;
var _gridW   = _cardW * 2 + _cardGap;
var _gridH   = _cardH * 2 + _cardGap;
var _gridX   = _cx - _gridW * 0.5;
var _gridY   = 390;

// Card definitions: [label, sublabel, locked]
var _cards = [
    { label: "STORY MODE",      sub: "Clear the corrupted solar system.",         locked: false },
    { label: "PLANET ENDLESS",  sub: global.endlessPlanetUnlocked  ? "Rotating board, Core planet." : "Complete TIN MOON to unlock.", locked: !global.endlessPlanetUnlocked },
    { label: "CLASSIC ENDLESS", sub: global.endlessClassicUnlocked ? "Pure matching. No rotation."  : "Complete RUST GARDEN to unlock.", locked: !global.endlessClassicUnlocked },
    { label: "SETTINGS",        sub: "Ghost piece, screen shake.",                locked: false }
];

for (var _ci = 0; _ci < 4; _ci++) {
    var _col  = _ci mod 2;
    var _row  = _ci div 2;
    var _cx2  = _gridX + _col * (_cardW + _cardGap);
    var _cy2  = _gridY + _row * (_cardH + _cardGap);
    var _sel  = (_ci == menu_index);
    var _card = _cards[_ci];

    // Slide-in from below (staggered per card)
    var _slideT = clamp((menu_enter_timer - _ci * 6) / 40.0, 0, 1);
    _slideT = 1 - power(1 - _slideT, 3); // ease-out cubic
    var _slideY  = lerp(120, 0, _slideT);
    var _cardAlpha = _slideT;
    _cy2 += _slideY;

    // Selection pulse scale
    var _pulse = _sel ? (1.0 + abs(sin(current_time * 0.004)) * 0.025) : 1.0;
    var _cxC   = _cx2 + _cardW * 0.5; // card center x
    var _cyC   = _cy2 + _cardH * 0.5; // card center y
    var _cW2   = _cardW  * _pulse;
    var _cH2   = _cardH  * _pulse;
    var _cx2a  = _cxC - _cW2 * 0.5; var _cy2a = _cyC - _cH2 * 0.5;
    var _cx2b  = _cxC + _cW2 * 0.5; var _cy2b = _cyC + _cH2 * 0.5;

    // Card glow (selected only)
    if (_sel) {
        gpu_set_blendmode(bm_add);
        draw_set_alpha(_cardAlpha * 0.18);
        draw_set_color(make_color_rgb(100, 180, 255));
        draw_roundrect_ext(_cx2a - 12, _cy2a - 12, _cx2b + 12, _cy2b + 12, 20, 20, false);
        gpu_set_blendmode(bm_normal);
    }

    // Card background
    draw_set_alpha(_cardAlpha * (_sel ? 0.95 : 0.75));
    if (sprite_exists(spr_ui_panel)) {
        draw_sprite_stretched_ext(spr_ui_panel, 0, _cx2a, _cy2a, _cW2, _cH2,
            _sel ? make_color_rgb(160, 200, 255) : c_white, _cardAlpha * (_sel ? 0.95 : 0.75));
    } else {
        draw_set_color(_sel ? make_color_rgb(22, 34, 70) : make_color_rgb(14, 20, 44));
        draw_roundrect_ext(_cx2a, _cy2a, _cx2b, _cy2b, 16, 16, false);
        draw_set_alpha(_cardAlpha * (_sel ? 0.9 : 0.4));
        draw_set_color(_sel ? make_color_rgb(120, 180, 255) : make_color_rgb(70, 90, 140));
        draw_roundrect_ext(_cx2a, _cy2a, _cx2b, _cy2b, 16, 16, true);
    }

    // Icon area (top 170px of card)
    var _iconCX = _cxC;
    var _iconCY = _cy2a + 100;
    var _iconR  = 54;
    draw_set_alpha(_cardAlpha);

    if (_card.locked) {
        // Padlock icon
        draw_set_color(make_color_rgb(100, 110, 140));
        draw_rectangle(_iconCX - 20, _iconCY - 10, _iconCX + 20, _iconCY + 22, false);
        draw_set_color(make_color_rgb(70, 80, 110));
        draw_ellipse(_iconCX - 16, _iconCY - 36, _iconCX + 16, _iconCY - 4, true);
        draw_set_alpha(_cardAlpha * 0.9);
        draw_set_color(make_color_rgb(180, 190, 220));
        draw_ellipse(_iconCX - 14, _iconCY - 34, _iconCX + 14, _iconCY - 6, true);
        draw_set_color(make_color_rgb(60, 70, 100));
        draw_circle(_iconCX, _iconCY + 6, 6, false);
    } else if (_ci == 0) {
        // Globe — Story Mode
        var _gRot = current_time * 0.0004;
        draw_set_color(_sel ? make_color_rgb(80, 180, 255) : make_color_rgb(60, 130, 210));
        draw_circle(_iconCX, _iconCY, _iconR, false);
        draw_set_color(_sel ? make_color_rgb(30, 80, 160) : make_color_rgb(20, 50, 120));
        draw_ellipse(_iconCX - _iconR, _iconCY - 16, _iconCX + _iconR, _iconCY + 16, true);
        draw_ellipse(_iconCX - _iconR * 0.6, _iconCY - 28, _iconCX + _iconR * 0.6, _iconCY + 28, true);
        // Rotating longitude line
        draw_set_color(make_color_rgb(150, 220, 255));
        draw_set_alpha(_cardAlpha * 0.6);
        draw_ellipse(_iconCX + cos(_gRot) * _iconR * 0.5 - _iconR * 0.3, _iconCY - _iconR,
                     _iconCX + cos(_gRot) * _iconR * 0.5 + _iconR * 0.3, _iconCY + _iconR, true);
        // Continent blobs
        draw_set_alpha(_cardAlpha * 0.75);
        draw_set_color(make_color_rgb(80, 200, 120));
        draw_circle(_iconCX - 18 + cos(_gRot * 0.7) * 10, _iconCY - 10, 14, false);
        draw_circle(_iconCX + 22 + sin(_gRot * 0.5) * 8,  _iconCY + 12, 9,  false);
    } else if (_ci == 1) {
        // Planet + Ring — Planet Endless
        var _pRot = current_time * 0.0006;
        draw_set_color(_sel ? make_color_rgb(180, 120, 255) : make_color_rgb(120, 70, 200));
        draw_circle(_iconCX, _iconCY, _iconR * 0.72, false);
        // Ring
        draw_set_color(_sel ? make_color_rgb(220, 180, 255) : make_color_rgb(160, 120, 220));
        draw_set_alpha(_cardAlpha * 0.65);
        draw_ellipse(_iconCX - _iconR, _iconCY - 14,
                     _iconCX + _iconR, _iconCY + 14, true);
        draw_set_alpha(_cardAlpha * 0.35);
        draw_ellipse(_iconCX - _iconR * 0.76, _iconCY - 11,
                     _iconCX + _iconR * 0.76, _iconCY + 11, true);
        // Planet surface spot
        draw_set_alpha(_cardAlpha * 0.5);
        draw_set_color(make_color_rgb(255, 200, 120));
        draw_circle(_iconCX + 16, _iconCY - 14, 10, false);
    } else if (_ci == 2) {
        // 3×3 Color Grid — Classic Endless
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
    } else if (_ci == 3) {
        // Gear — Settings
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

    // Divider line between icon and text
    draw_set_alpha(_cardAlpha * 0.25);
    draw_set_color(c_white);
    draw_line_width(_cx2a + 20, _cy2a + 172, _cx2b - 20, _cy2a + 172, 1);

    // Card label
    draw_set_alpha(_cardAlpha);
    draw_set_color(_card.locked ? make_color_rgb(90, 100, 130) : (_sel ? make_color_rgb(255, 225, 100) : c_white));
    draw_text_transformed(_cxC, _cy2a + 200, _card.label, _sel ? 1.8 : 1.6, _sel ? 1.8 : 1.6, 0);

    // Card subtitle
    draw_set_alpha(_cardAlpha * 0.65);
    draw_set_color(_card.locked ? make_color_rgb(90, 100, 130) : make_color_rgb(160, 175, 210));
    draw_text_transformed(_cxC, _cy2a + 252, _card.sub, 1.0, 1.0, 0);
}

// Wallet display
draw_set_alpha(0.80);
draw_set_color(make_color_rgb(180, 230, 255));
draw_set_halign(fa_right);
draw_text_transformed(_cx + _gridW * 0.5, _gridY - 36, "SHARDS " + string(global.walletShards) + "   GEMS " + string(global.walletGems), global.TXT_SMALL, global.TXT_SMALL, 0);
draw_set_halign(fa_center);

// Footer
draw_set_alpha(0.38); draw_set_color(make_color_rgb(255, 214, 102));
draw_text_transformed(_cx, _h - 60, "Arrow Keys / Stick  Move     Enter / A  Select", global.TXT_SMALL, global.TXT_SMALL, 0);

// Floating Texts
for (var i = 0; i < array_length(global.floatingTexts); i++) {
    var _ft = global.floatingTexts[i];
    draw_set_alpha(_ft.life / 90);
    draw_set_color(_ft.color);
    draw_text_transformed(_ft.x, _ft.y, _ft.text, _ft.scale, _ft.scale, 0);
}

// Dialogue (backstory plays over the menu)
dialogue_draw();

draw_set_alpha(1); draw_set_halign(fa_left); draw_set_valign(fa_top);
// ──────────────────────────────────────────────────────────────────────────
