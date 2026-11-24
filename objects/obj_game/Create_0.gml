/// obj_game - the only object. Boots every system and runs the scene machine.
randomize();
global.levels = cc_load_levels();
cc_save_load();
cc_input_init();
cc_fx_init();
cc_bg_init();
cc_audio_init();
global.scene = "title";
global.scene_t = 0;
global.menu_sel = 0;
global.map_world = 0;
global.map_sel = 0;
global.map_slide = 0;
global.options_return = "menu";
global.play = undefined;
global.view = { x: 600, y: 330, cs: 64, ang: 0, n: 7, sx: 0, sy: 0 };

global.test = { on: cc_test_wanted(), frame: 0, shot: "", shots: 0, endless_left: 0 };
if (global.test.on) {
    global.save.sfx = 0;
    cc_test_rules();
}
