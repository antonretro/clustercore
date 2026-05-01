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

// ── TITLE SCREEN ─────────────────────────────────────────────────────────
if (in_title) {
    if (title_timer > 60 && (_confirm || keyboard_check_pressed(vk_anykey) || mouse_check_button_pressed(mb_left))) {
        in_title = false;
        menu_enter_timer = 0;
    }
    exit;
}
menu_enter_timer = min(menu_enter_timer + 2, 60);

for (var i = array_length(global.floatingTexts) - 1; i >= 0; i--) {
    var _t = global.floatingTexts[i];
    _t.y -= 0.5; _t.life -= 1;
    if (_t.life <= 0) array_delete(global.floatingTexts, i, 1);
}
// ─────────────────────────────────────────────────────────────────────────

if (dialogue_is_active()) {
    dialogue_update();
    exit;
}

if (in_refabricator) {
    if (_confirm) {
        if (refabricate_gem_from_shards()) {
            create_floating_text_ext(960, 320, "GEM FABRICATED", make_color_rgb(170, 245, 255), 1.2);
        } else {
            create_floating_text_ext(960, 320, "NEED 25 SHARDS", make_color_rgb(255, 170, 120), 1.0);
        }
    }
    if (_back || _shopPress) in_refabricator = false;
    exit;
}

if (in_bonus_select) {
    if (_leftPress || _upPress) bonus_select_index = (bonus_select_index - 1 + array_length(bonus_planet_names)) mod array_length(bonus_planet_names);
    if (_rightPress || _downPress) bonus_select_index = (bonus_select_index + 1) mod array_length(bonus_planet_names);
    if (_confirm) {
        global.gameMode = "BONUS";
        global.bonusPlanet = bonus_select_index;
        room_goto(room_game);
    }
    if (_back) in_bonus_select = false;
    exit;
}

// Story solar system select
if (in_story_select) {
    if (_shopPress) {
        in_refabricator = true;
        exit;
    }
    if (_bonusPress) {
        in_bonus_select = true;
        in_story_level_select = false;
        exit;
    }
    if (!in_story_level_select) {
        if (_leftPress)  story_select_index = (story_select_index - 1 + array_length(story_worlds)) mod array_length(story_worlds);
        if (_rightPress) story_select_index = (story_select_index + 1) mod array_length(story_worlds);

        if (_leftPress || _rightPress) {
            var _sid = "select_" + string(story_select_index);
            if (!variable_struct_exists(global.story_seen_scenes, _sid)) {
                var _cat = story_plot_catalog();
                if (variable_struct_exists(_cat, _sid)) dialogue_start(_sid, _cat[$ _sid]);
                global.story_seen_scenes[$ _sid] = true;
            }
            story_level_index = 0;
        }

        if (_confirm) {
            if (story_progress_is_unlocked(story_select_index, 0)) {
                in_story_level_select = true;
                var _sidL = "world_open_" + string(story_select_index);
                if (!variable_struct_exists(global.story_seen_scenes, _sidL)) {
                    var _catL = story_plot_catalog();
                    if (variable_struct_exists(_catL, _sidL)) dialogue_start(_sidL, _catL[$ _sidL]);
                    global.story_seen_scenes[$ _sidL] = true;
                }
            } else {
                var _sw = display_get_gui_width() * 0.5;
                var _sh = display_get_gui_height() * 0.5;
                create_floating_text_ext(_sw, _sh - 100, "SYSTEM LOCKED", global.COLOR_DANGER, 1.0);
            }
        }
    } else {
        var _lvlCount = story_world_level_counts[story_select_index];
        if (_upPress) story_level_index = (story_level_index - 1 + _lvlCount) mod _lvlCount;
        if (_downPress) story_level_index = (story_level_index + 1) mod _lvlCount;

        if (_confirm) {
            if (story_progress_is_unlocked(story_select_index, story_level_index)) {
                global.gameMode = "STORY";
                global.storyPlanet = story_select_index;
                global.storyLevel = story_level_index;
                room_goto(room_game);
            } else {
                var _w2 = display_get_gui_width() * 0.5;
                create_floating_text_ext(_w2, 500, "MISSION LOCKED", global.COLOR_DANGER, 1.0);
            }
        }
    }

    if (_back) {
        if (in_story_level_select) in_story_level_select = false;
        else in_story_select = false;
    }
    exit;
}

// Settings screen
if (in_settings) {
    if (_upPress)   settings_index = (settings_index - 1 + array_length(settings_items)) mod array_length(settings_items);
    if (_downPress) settings_index = (settings_index + 1) mod array_length(settings_items);

    if (_confirm || _rightPress || _leftPress) {
        switch (settings_index) {
            case 0: global.settings.ghostEnabled = !global.settings.ghostEnabled; break;
            case 1: global.settings.shakeEnabled = !global.settings.shakeEnabled; break;
        }
    }

    if (_back) in_settings = false;
    exit;
}

// Main menu — 2x2 card grid navigation
// Layout: [0=Story] [1=Planet]  (top row)
//         [2=Classic][3=Settings] (bottom row)
if (_leftPress) {
    if (menu_index == 1) menu_index = 0;
    else if (menu_index == 3) menu_index = 2;
}
if (_rightPress) {
    if (menu_index == 0) menu_index = 1;
    else if (menu_index == 2) menu_index = 3;
}
if (_upPress   && menu_index >= 2) menu_index -= 2;
if (_downPress && menu_index <  2) menu_index += 2;

if (_confirm) {
    switch (menu_index) {
        case 0:
            in_story_select = true;
            var _sid0 = "select_" + string(story_select_index);
            if (!variable_struct_exists(global.story_seen_scenes, _sid0)) {
                var _cat0 = story_plot_catalog();
                if (variable_struct_exists(_cat0, _sid0)) dialogue_start(_sid0, _cat0[$ _sid0]);
                global.story_seen_scenes[$ _sid0] = true;
            }
            break;
        case 1: global.gameMode = "PLANET";  room_goto(room_game); break;
        case 2: global.gameMode = "CLASSIC"; room_goto(room_game); break;
        case 3: in_settings = true; break;
    }
}

// Mouse click support
if (mouse_check_button_pressed(mb_left)) {
    var _sy = 400; var _rh = 82;
    for (var i = 0; i < array_length(menu_items); i++) {
        if (mouse_y >= _sy + i * _rh && mouse_y <= _sy + i * _rh + 68) {
            menu_index = i;
            switch (i) {
                case 0:
                    in_story_select = true;
                    var _sidMouse = "select_" + string(story_select_index);
                    if (!variable_struct_exists(global.story_seen_scenes, _sidMouse)) {
                        var _catMouse = story_plot_catalog();
                        if (variable_struct_exists(_catMouse, _sidMouse)) dialogue_start(_sidMouse, _catMouse[$ _sidMouse]);
                        global.story_seen_scenes[$ _sidMouse] = true;
                    }
                    break;
                case 1: global.gameMode = "PLANET"; room_goto(room_game); break;
                case 2: global.gameMode = "CLASSIC"; room_goto(room_game); break;
                case 3: in_settings = true; break;
            }
        }
    }
}
