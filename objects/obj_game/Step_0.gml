cc_input_update();
if (global.test.on) cc_test_step();
global.scene_t++;
cc_fx_update();
cc_music_update();
switch (global.scene) {
    case "title":   cc_title_step(); break;
    case "menu":    cc_menu_step(); break;
    case "map":     cc_map_step(); break;
    case "options": cc_options_step(); break;
    case "play":    cc_play_step(); break;
}
