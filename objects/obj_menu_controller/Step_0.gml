// ── Settings screen ───────────────────────────────────────────────────────────
if (in_settings) {
    if (keyboard_check_pressed(vk_up))   settings_index = (settings_index - 1 + array_length(settings_items)) mod array_length(settings_items);
    if (keyboard_check_pressed(vk_down)) settings_index = (settings_index + 1) mod array_length(settings_items);

    if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space) || keyboard_check_pressed(vk_right) || keyboard_check_pressed(vk_left)) {
        switch (settings_index) {
            case 0: global.settings.ghostEnabled = !global.settings.ghostEnabled; break;
            case 1: global.settings.shakeEnabled = !global.settings.shakeEnabled; break;
        }
    }

    if (keyboard_check_pressed(vk_escape)) in_settings = false;
    exit;
}

// ── Main menu ─────────────────────────────────────────────────────────────────
if (keyboard_check_pressed(vk_up))   menu_index = (menu_index - 1 + array_length(menu_items)) mod array_length(menu_items);
if (keyboard_check_pressed(vk_down)) menu_index = (menu_index + 1) mod array_length(menu_items);

if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space)) {
    switch (menu_index) {
        case 0: global.gameMode = "STORY";   global.storyPlanet = 0; room_goto(room_game); break;
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
                case 0: global.gameMode = "STORY";   global.storyPlanet = 0; room_goto(room_game); break;
                case 1: global.gameMode = "PLANET";  room_goto(room_game); break;
                case 2: global.gameMode = "CLASSIC"; room_goto(room_game); break;
                case 3: in_settings = true; break;
            }
        }
    }
}
