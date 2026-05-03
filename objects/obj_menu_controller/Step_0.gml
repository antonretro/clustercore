var _gp = gamepad_is_connected(0);
var _stickY = _gp ? gamepad_axis_value(0, gp_axislv) : 0;
var _stickX = _gp ? gamepad_axis_value(0, gp_axislh) : 0;

var _up_gp = _gp && (gamepad_button_check_pressed(0, gp_padu) || (_stickY < -0.5 && gp_prev_menu_stick_y >= -0.5));
var _dn_gp = _gp && (gamepad_button_check_pressed(0, gp_padd) || (_stickY >  0.5 && gp_prev_menu_stick_y <=  0.5));
var _lf_gp = _gp && (gamepad_button_check_pressed(0, gp_padl) || (_stickX < -0.5 && gp_prev_menu_stick_x >= -0.5));
var _rt_gp = _gp && (gamepad_button_check_pressed(0, gp_padr) || (_stickX >  0.5 && gp_prev_menu_stick_x <=  0.5));

gp_prev_menu_stick_y = _stickY;
gp_prev_menu_stick_x = _stickX;
story_solar_spin += 0.35;
title_timer++;

var _confirm = keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space)
            || (_gp && (gamepad_button_check_pressed(0, gp_face1) || gamepad_button_check_pressed(0, gp_start)));
var _back = keyboard_check_pressed(vk_escape) || (_gp && gamepad_button_check_pressed(0, gp_face2));
var _leftPress = keyboard_check_pressed(vk_left) || _lf_gp;
var _rightPress = keyboard_check_pressed(vk_right) || _rt_gp;
var _upPress = keyboard_check_pressed(vk_up) || _up_gp;
var _downPress = keyboard_check_pressed(vk_down) || _dn_gp;
var _shopPress = keyboard_check_pressed(ord("S")) || keyboard_check_pressed(vk_tab)
              || (_gp && gamepad_button_check_pressed(0, gp_face3));
var _bonusPress = keyboard_check_pressed(ord("D"))
               || (_gp && gamepad_button_check_pressed(0, gp_face4));

var _sndMove = asset_get_index("snd_menu_move");
var _sndConf = asset_get_index("snd_menu_confirm");

if (keyboard_check_pressed(vk_f11)) window_set_fullscreen(!window_get_fullscreen());
if (keyboard_check_pressed(vk_f12)) { room_goto(room_test); exit; }

// ── TITLE SCREEN ─────────────────────────────────────────────────────────
if (in_title) {
    // Loading: advance the sync bar and transition to menu when done
    if (is_loading) {
        loading_timer++;
        if (loading_timer > 90) {
            in_title = false; is_loading = false; in_save_slots = false; menu_enter_timer = 0;
            global.current_save_slot = save_slot_index + 1;
            wallet_load();
        }
        exit;
    }
    if (in_name_entry) {
        // Handle text input via keyboard_string
        var _kb = keyboard_string;
        // Filter to reasonable pilot name characters
        name_entry_text = "";
        for (var _ci = 1; _ci <= string_length(_kb); _ci++) {
            var _ch = string_char_at(_kb, _ci);
            if (_ci > 16) break; // max 16 chars
            name_entry_text += _ch;
        }
        if (keyboard_check_pressed(vk_enter) && name_entry_text != "") {
            save_slots[name_entry_index].name = name_entry_text;
            in_name_entry = false;
            is_loading = true; loading_timer = 0;
            keyboard_string = "";
            if (_sndConf != -1) audio_play_sound(_sndConf, 1, false);
        }
        if (_back) {
            in_name_entry = false;
            keyboard_string = "";
        }
        exit;
    }
    if (in_save_slots) {
        if (_leftPress || _upPress) { save_slot_index = (save_slot_index - 1 + 3) mod 3; if (_sndMove != -1) audio_play_sound(_sndMove, 1, false); }
        if (_rightPress || _downPress) { save_slot_index = (save_slot_index + 1) mod 3; if (_sndMove != -1) audio_play_sound(_sndMove, 1, false); }
        if (_confirm) {
            // Check if slot has default name — if so, show name entry first
            var _defName = "PILOT_0" + string(save_slot_index + 1);
            if (save_slots[save_slot_index].name == _defName || keyboard_check_pressed(ord("X"))) {
                in_name_entry = true;
                name_entry_index = save_slot_index;
                keyboard_string = "";
                name_entry_text = "";
            } else {
                is_loading = true; loading_timer = 0;
                if (_sndConf != -1) audio_play_sound(_sndConf, 1, false);
            }
        }
        if (keyboard_check_pressed(ord("X"))) {
            // Rename: enter name entry for current slot even if already named
            in_name_entry = true;
            name_entry_index = save_slot_index;
            keyboard_string = save_slots[save_slot_index].name;
            name_entry_text = save_slots[save_slot_index].name;
        }
        if (_back) in_save_slots = false;
    } else {
        if (title_timer > 60 && (_confirm || keyboard_check_pressed(vk_anykey) || mouse_check_button_pressed(mb_left))) {
            in_save_slots = true;
            if (_sndMove != -1) audio_play_sound(_sndMove, 1, false);
        }
    }
    exit;
}

// Level transition timer
if (in_level_transition) {
    level_transition_timer++;
    if (level_transition_timer > 60) {
        in_level_transition = false;
        global.gameMode = "STORY";
        global.storyPlanet = transition_target_world;
        global.storyLevel = transition_target_level;
        room_goto(room_game);
    }
    exit;
}

// Global visual updates
menu_enter_timer = min(menu_enter_timer + 2, 60);
screen_fade = clamp(screen_fade + 0.08, 0, 1);
var _zoomTarget = in_story_level_select ? 1 : 0;
zoom_lerp += (_zoomTarget - zoom_lerp) * 0.12;

// Exit animation: when fade reaches 0, clear the pending state
if (exit_pending != "") {
    screen_fade = max(screen_fade - 0.12, 0);
    if (screen_fade <= 0.01) {
        switch (exit_pending) {
            case "refabricator": in_refabricator = false; break;
            case "story_select": in_story_select = false; break;
            case "bonus_select": in_bonus_select = false; break;
            case "settings": in_settings = false; break;
            case "inventory": in_inventory = false; break;
            case "shop": in_shop = false; break;
            case "how_to_play": in_how_to_play = false; break;
            case "achievements": in_achievements = false; break;
            case "story_level": in_story_level_select = false; break;
        }
        exit_pending = "";
    }
}

for (var i = array_length(global.floatingTexts) - 1; i >= 0; i--) {
    var _t = global.floatingTexts[i]; _t.y -= 0.5; _t.life -= 1;
    if (_t.life <= 0) array_delete(global.floatingTexts, i, 1);
}

if (dialogue_is_active()) { dialogue_update(); exit; }

// --- SUB-MENUS ---
if (in_refabricator) {
    if (_confirm) {
        if (refabricate_gem_from_shards()) create_floating_text_ext(960, 320, "GEM FABRICATED", make_color_rgb(170, 245, 255), 1.2);
        else create_floating_text_ext(960, 320, "NEED 25 SHARDS", make_color_rgb(255, 170, 120), 1.0);
    }
    if (_back || _shopPress) exit_pending = "refabricator";
    exit;
}

if (in_story_select) {
    if (_shopPress) { in_refabricator = true; exit; }

    if (!in_story_level_select && !in_bonus_select) {
        if (_leftPress) {
            story_select_index = (story_select_index - 1 + array_length(story_worlds)) mod array_length(story_worlds);
            story_level_index = 0;
            var _sid = "select_" + string(story_select_index);
            if (!variable_struct_exists(global.story_seen_scenes, _sid)) {
                var _cat = story_plot_catalog();
                if (variable_struct_exists(_cat, _sid)) dialogue_start(_sid, _cat[$ _sid]);
                global.story_seen_scenes[$ _sid] = true;
            }
            if (_sndMove != -1) audio_play_sound(_sndMove, 1, false);
        }
        if (_rightPress) {
            story_select_index = (story_select_index + 1) mod array_length(story_worlds);
            story_level_index = 0;
            var _sid = "select_" + string(story_select_index);
            if (!variable_struct_exists(global.story_seen_scenes, _sid)) {
                var _cat = story_plot_catalog();
                if (variable_struct_exists(_cat, _sid)) dialogue_start(_sid, _cat[$ _sid]);
                global.story_seen_scenes[$ _sid] = true;
            }
            if (_sndMove != -1) audio_play_sound(_sndMove, 1, false);
        }
        if (_confirm) {
            if (story_progress_is_unlocked(story_select_index, 0)) {
                in_story_level_select = true;
                if (_sndConf != -1) audio_play_sound(_sndConf, 1, false);
            } else {
                create_floating_text_ext(1920/2, 1080/2 - 100, "SYSTEM LOCKED", global.COLOR_DANGER, 1.0);
            }
        }
    } else if (in_story_level_select) {
        var _lvlCount = story_world_level_counts[story_select_index];
        var _prevIdx = story_level_index;
        if (_leftPress)  story_level_index--;
        if (_rightPress) story_level_index++;
        if (_upPress)    story_level_index -= 3;
        if (_downPress)  story_level_index += 3;
        story_level_index = (story_level_index + _lvlCount) mod _lvlCount;
        if (story_level_index != _prevIdx && _sndMove != -1) audio_play_sound(_sndMove, 1, false);

        if (_confirm) {
            if (story_progress_is_unlocked(story_select_index, story_level_index)) {
                in_level_transition = true; level_transition_timer = 0;
                transition_target_world = story_select_index;
                transition_target_level = story_level_index;
                if (_sndConf != -1) audio_play_sound(_sndConf, 1, false);
            } else {
                create_floating_text_ext(1920/2, 500, "MISSION LOCKED", global.COLOR_DANGER, 1.0);
            }
        }
    }
    if (_bonusPress) {
        in_bonus_select = true; in_story_level_select = false;
    }
    if (_back) {
        if (in_bonus_select) exit_pending = "bonus_select";
        else if (in_story_level_select) exit_pending = "story_level";
        else exit_pending = "story_select";
    }
    exit;
}

if (in_bonus_select) {
    if (_leftPress || _upPress) bonus_select_index = (bonus_select_index - 1 + array_length(bonus_planet_names)) mod array_length(bonus_planet_names);
    if (_rightPress || _downPress) bonus_select_index = (bonus_select_index + 1) mod array_length(bonus_planet_names);
    if (_confirm) {
        if (_sndConf != -1) audio_play_sound(_sndConf, 1, false);
        global.gameMode = "BONUS";
        global.bonusPlanet = bonus_select_index;
        room_goto(room_game);
    }
    if (_back) exit_pending = "bonus_select";
    exit;
}

if (in_settings) {
    if (_upPress)   settings_index = (settings_index - 1 + 2) mod 2;
    if (_downPress) settings_index = (settings_index + 1) mod 2;
    if (_confirm || _rightPress || _leftPress) {
        switch (settings_index) {
            case 0: global.settings.ghostEnabled = !global.settings.ghostEnabled; break;
            case 1: global.settings.shakeEnabled = !global.settings.shakeEnabled; break;
        }
    }
    if (_back) exit_pending = "settings";
    exit;
}

if (in_inventory)  { if (_back) exit_pending = "inventory"; exit; }
if (in_shop)       { if (_back) exit_pending = "shop"; exit; }
if (in_how_to_play){
    if (_leftPress)  how_to_page = (how_to_page - 1 + 4) mod 4;
    if (_rightPress) how_to_page = (how_to_page + 1) mod 4;
    if (_back) exit_pending = "how_to_play";
    exit;
}
if (in_achievements){ if (_back) exit_pending = "achievements"; exit; }

// --- MAIN MENU NAVIGATION (CARDS + TOOLBAR) ---
var _inToolbar = (menu_index >= 3);

if (_leftPress) {
    if (!_inToolbar) menu_index = (menu_index - 1 + 3) % 3;
    else menu_index = 3 + (menu_index - 3 - 1 + 7) % 7;
    if (_sndMove != -1) audio_play_sound(_sndMove, 1, false);
}
if (_rightPress) {
    if (!_inToolbar) menu_index = (menu_index + 1) % 3;
    else menu_index = 3 + (menu_index - 3 + 1) % 7;
    if (_sndMove != -1) audio_play_sound(_sndMove, 1, false);
}
if (_upPress && _inToolbar) {
    menu_index = clamp(floor((menu_index - 3) * (3 / 7)), 0, 2);
    if (_sndMove != -1) audio_play_sound(_sndMove, 1, false);
}
if (_downPress && !_inToolbar) {
    menu_index = 3 + floor(menu_index * (7 / 3));
    if (_sndMove != -1) audio_play_sound(_sndMove, 1, false);
}

// --- MOUSE INTERACTION (Cards/Sub-menus) ---
var _guiW = 1920; var _guiH = 1080; 
var _mx = device_mouse_x_to_gui(0);
var _my = device_mouse_y_to_gui(0);
var _mClick = mouse_check_button_pressed(mb_left);
var _cx = _guiW * 0.5;
var _cy = _guiH * 0.5;

// Back Button hit-test for sub-screens
if (!in_title && (in_settings || in_story_select || in_inventory || in_shop || in_how_to_play || in_achievements || in_refabricator)) {
    if (_mx > 20 && _mx < 180 && _my > 20 && _my < 90) {
        if (_mClick) _back = true;
    }
}

if (in_save_slots && !is_loading) {
    var _cardW = 480; var _cardH = 650; var _gap = 50;
    var _startX = _cx - (_cardW * 1.5 + _gap);
    for (var i = 0; i < 3; i++) {
        var _sx = _startX + i * (_cardW + _gap);
        var _sy = _cy - 200;
        if (_mx > _sx && _mx < _sx + _cardW && _my > _sy && _my < _sy + _cardH) {
            if (save_slot_index != i) { save_slot_index = i; if (_sndMove != -1) audio_play_sound(_sndMove, 1, false); }
            if (_mClick) _confirm = true;
        }
    }
} else if (in_settings) {
    var _startY = 360; var _panelW = 800; var _panelH = 120;
    for (var i = 0; i < 2; i++) {
        var _py = _startY + i * 170;
        if (_mx > _cx - _panelW*0.5 && _mx < _cx + _panelW*0.5 && _my > _py - _panelH*0.5 && _my < _py + _panelH*0.5) {
            if (settings_index != i) { settings_index = i; if (_sndMove != -1) audio_play_sound(_sndMove, 1, false); }
            if (_mClick) _confirm = true;
        }
    }
} else if (in_story_level_select) {
    var _lvlCount = story_world_level_counts[story_select_index];
    var _cellW = 114; var _cellH = 90; var _cellGap = 14;
    var _gridStartX = 20 + (440 - (_cellW * 3 + _cellGap * 2)) * 0.5;
    var _gridStartY = (80 + 90 + 120) + 40;
    for (var i = 0; i < _lvlCount; i++) {
        var _col = i mod 3; var _row = i div 3;
        var _cxCell = _gridStartX + _col * (_cellW + _cellGap) + _cellW * 0.5;
        var _cyCell = _gridStartY + _row * (_cellH + _cellGap) + _cellH * 0.5;
        if (_mx > _cxCell - _cellW*0.5 && _mx < _cxCell + _cellW*0.5 && _my > _cyCell - _cellH*0.5 && _my < _cyCell + _cellH*0.5) {
            if (story_level_index != i) { story_level_index = i; if (_sndMove != -1) audio_play_sound(_sndMove, 1, false); }
            if (_mClick) _confirm = true;
        }
    }
} else if (in_how_to_play) {
    var _sidebarX1 = _cx - 540 + 20; 
    var _sidebarY0 = 210 + 30;
    var _tabH = 52; var _sidebarW = 210;
    for (var i = 0; i < 4; i++) {
        var _ty = _sidebarY0 + 38 + i * (_tabH + 8);
        if (_mx > _sidebarX1 && _mx < _sidebarX1 + _sidebarW && _my > _ty && _my < _ty + _tabH) {
            if (how_to_page != i) { how_to_page = i; if (_sndMove != -1) audio_play_sound(_sndMove, 1, false); }
        }
    }
} else if (in_refabricator) {
    var _pw = 800; var _ph = 320;
    if (_mx > _cx - _pw*0.5 && _mx < _cx + _pw*0.5 && _my > _cy - _ph*0.5 && _my < _cy + _ph*0.5) {
        if (_mClick) _confirm = true;
    }
} else if (!in_story_select && !in_bonus_select && !in_level_transition && !in_title) {
    // Main Deck - Cards
    var _cardW = 380; var _cardH = 480; var _gap = 40;
    var _startX = _cx - ((_cardW * 3 + _gap * 2) * 0.5);
    var _mainY = _cy - 80 - _cardH * 0.5;
    for (var i = 0; i < 3; i++) {
        var _xx = _startX + i * (_cardW + _gap);
        if (_mx > _xx && _mx < _xx + _cardW && _my > _mainY && _my < _mainY + _cardH) {
            if (menu_index != i) { menu_index = i; if (_sndMove != -1) audio_play_sound(_sndMove, 1, false); }
            if (_mClick) _confirm = true;
        }
    }
    // Main Deck - Toolbar
    var _iconSize = 100; var _barGap = 40;
    var _totalBarW = (_iconSize * 7) + (_barGap * 6);
    var _barX = _cx - _totalBarW * 0.5;
    var _barY = _guiH - 150;
    if (_mx > _barX - 30 && _mx < _barX + _totalBarW + 30 && _my > _barY - 70 && _my < _barY + _iconSize + 30) {
        var _idxInBar = floor((_mx - (_barX - 30)) / (_totalBarW + 60) * 7);
        _idxInBar = clamp(_idxInBar, 0, 6);
        var _targetIdx = 3 + _idxInBar;
        if (menu_index != _targetIdx) { menu_index = _targetIdx; if (_sndMove != -1) audio_play_sound(_sndMove, 1, false); }
        if (_mClick) _confirm = true;
    }
}

if (_sndMove != -1 && (_upPress || _downPress || _leftPress || _rightPress)) audio_play_sound(_sndMove, 1, false);

// --- CONFIRMATION ---
if (_confirm) {
    if (in_title) {
        in_title = false; in_save_slots = true;
        if (_sndConf != -1) audio_play_sound(_sndConf, 1, false);
    } else if (in_save_slots) {
        // Load selected slot
        is_loading = true; loading_timer = 0;
        global.current_save_slot = save_slot_index + 1;
        if (_sndConf != -1) audio_play_sound(_sndConf, 1, false);
    } else {
        switch (menu_index) {
            case 0: in_story_select = true; break;
            case 1: if (global.endlessPlanetUnlocked) { global.gameMode = "PLANET"; room_goto(room_game); } else { create_floating_text_ext(_cx, _cy, "COMPLETE STORY LEVEL 1", global.COLOR_DANGER, 1); } break;
            case 2: if (global.endlessClassicUnlocked) { global.gameMode = "CLASSIC"; room_goto(room_game); } else { create_floating_text_ext(_cx, _cy, "COMPLETE STORY LEVEL 2", global.COLOR_DANGER, 1); } break;
            case 3: wallet_save(); create_floating_text_ext(_cx, _cy, "SYSTEM SYNC COMPLETE", make_color_rgb(100, 255, 150), 1.2); break;
            case 4: in_refabricator = true; break;
            case 5: in_inventory = true; break;
            case 6: in_shop = true; break;
            case 7: in_how_to_play = true; break;
            case 8: in_achievements = true; break;
            case 9: in_settings = true; break;
        }
    }
}

// --- BACK LOGIC ---
if (_back) {
    if (in_save_slots) { in_save_slots = false; in_title = true; }
    else if (in_story_select) in_story_select = false;
    else if (in_settings) in_settings = false;
    else if (in_inventory) in_inventory = false;
    else if (in_shop) in_shop = false;
    else if (in_how_to_play) in_how_to_play = false;
    else if (in_achievements) in_achievements = false;
    else if (in_refabricator) in_refabricator = false;
}
io_clear();
