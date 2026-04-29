if (keyboard_check_pressed(vk_up)) {
    menu_index = (menu_index - 1 + array_length(menu_items)) mod array_length(menu_items);
}

if (keyboard_check_pressed(vk_down)) {
    menu_index = (menu_index + 1) mod array_length(menu_items);
}

if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space)) {
    switch (menu_index) {
        case 0:
            global.launch_mode = "endless";
            room_goto(room_game);
            break;
        case 1:
            global.launch_mode = "story";
            break;
        case 2:
            global.launch_mode = "lab";
            break;
        case 3:
            global.launch_mode = "challenges";
            break;
        case 4:
            global.launch_mode = "settings";
            break;
    }
}

if (mouse_check_button_pressed(mb_left)) {
    var _start_y = 320;
    var _row_h = 54;
    for (var i = 0; i < array_length(menu_items); i++) {
        var _top = _start_y + i * _row_h;
        if (mouse_y >= _top && mouse_y <= _top + 42) {
            menu_index = i;
            if (i == 0) {
                global.launch_mode = "endless";
                room_goto(room_game);
            }
        }
    }
}
