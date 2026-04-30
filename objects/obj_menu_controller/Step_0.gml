var _gp = gamepad_is_connected(0);
var _stickY = _gp ? gamepad_axis_value(0, gp_axislv) : 0;
var _stickX = _gp ? gamepad_axis_value(0, gp_axislh) : 0;

var _up_gp = _gp && (gamepad_button_check_pressed(0, gp_padu) || (_stickY < -0.5 && gp_prev_menu_stick_y >= -0.5));
var _dn_gp = _gp && (gamepad_button_check_pressed(0, gp_padd) || (_stickY >  0.5 && gp_prev_menu_stick_y <=  0.5));
var _lf_gp = _gp && (gamepad_button_check_pressed(0, gp_padl) || (_stickX < -0.5 && gp_prev_menu_stick_x >= -0.5));
var _rt_gp = _gp && (gamepad_button_check_pressed(0, gp_padr) || (_stickX >  0.5 && gp_prev_menu_stick_x <=  0.5));

gp_prev_menu_stick_y = _stickY;
gp_prev_menu_stick_x = _stickX;

var _confirm = keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space)
            || (_gp && (gamepad_button_check_pressed(0, gp_face1) || gamepad_button_check_pressed(0, gp_start)));
var _back = keyboard_check_pressed(vk_escape) || (_gp && gamepad_button_check_pressed(0, gp_face2));
var _leftPress = keyboard_check_pressed(vk_left) || _lf_gp;
var _rightPress = keyboard_check_pressed(vk_right) || _rt_gp;
var _upPress = keyboard_check_pressed(vk_up) || _up_gp;
var _downPress = keyboard_check_pressed(vk_down) || _dn_gp;

if (dialogue_is_active()) {
    dialogue_update();
    exit;
}

// Story solar system select
if (in_story_select) {
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
            in_story_level_select = true;
            var _sidL = "world_open_" + string(story_select_index);
            if (!variable_struct_exists(global.story_seen_scenes, _sidL)) {
                var _catL = story_plot_catalog();
                if (variable_struct_exists(_catL, _sidL)) dialogue_start(_sidL, _catL[$ _sidL]);
                global.story_seen_scenes[$ _sidL] = true;
            }
        }
    } else {
        var _lvlCount = story_world_level_counts[story_select_index];
        if (_upPress) story_level_index = (story_level_index - 1 + _lvlCount) mod _lvlCount;
        if (_downPress) story_level_index = (story_level_index + 1) mod _lvlCount;

        if (_confirm) {
            global.gameMode = "STORY";
            global.storyPlanet = story_select_index;
            global.storyLevel = story_level_index;
            room_goto(room_game);
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

// Main menu
if (_upPress)   menu_index = (menu_index - 1 + array_length(menu_items)) mod array_length(menu_items);
if (_downPress) menu_index = (menu_index + 1) mod array_length(menu_items);

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
                case 0: in_story_select = true; break;
                case 1: global.gameMode = "PLANET"; room_goto(room_game); break;
                case 2: global.gameMode = "CLASSIC"; room_goto(room_game); break;
                case 3: in_settings = true; break;
            }
        }
    }
}
