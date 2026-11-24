gpu_set_colorwriteenable(true, true, true, false);
switch (global.scene) {
    case "title":   cc_title_draw(); break;
    case "menu":    cc_menu_draw(); break;
    case "map":     cc_map_draw(); break;
    case "options": cc_options_draw(); break;
    case "play":    cc_play_draw(); break;
}
cc_fx_draw();
cc_draw_scanlines();
var _F = global.fx;
if (_F.flash > 0) {
    gpu_set_blendmode(bm_add);
    draw_set_alpha(_F.flash * 0.6);
    draw_set_color(_F.flash_col);
    draw_rectangle(0, 0, 1280, 720, false);
    draw_set_alpha(1);
    gpu_set_blendmode(bm_normal);
}
