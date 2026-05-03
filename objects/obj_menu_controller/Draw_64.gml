/// @description Draw_64 — Main menu dispatcher
/// All rendering delegated to scr_menu_render functions.

var _sw = display_get_gui_width();
var _sh = display_get_gui_height();
var _cx = _sw * 0.5;
var _cy = _sh * 0.5;

draw_set_halign(fa_center);
draw_set_valign(fa_middle);
var _fnt = asset_get_index("main_font");
if (_fnt != -1) draw_set_font(_fnt);
gpu_set_texfilter(false);

// ═══ BACKGROUND ═══
menu_draw_background(_cx, _cy, _sw, _sh);

// ═══ TITLE SCREEN ═══
if (in_title) {
    menu_draw_title(_cx, _cy, _sw, _sh);
    // Transition fade overlay
    if (screen_fade < 1) { draw_set_alpha(1 - screen_fade); draw_set_color(c_black); draw_rectangle(0, 0, _sw, _sh, false); }
    draw_set_alpha(1); draw_set_halign(fa_left); draw_set_valign(fa_top);
    exit;
}

// ═══ LEVEL TRANSITION ═══
if (in_level_transition) {
    menu_draw_level_transition(_cx, _cy, _sw, _sh);
    // Transition fade overlay
    if (screen_fade < 1) { draw_set_alpha(1 - screen_fade); draw_set_color(c_black); draw_rectangle(0, 0, _sw, _sh, false); }
    draw_set_alpha(1); draw_set_halign(fa_left); draw_set_valign(fa_top);
    exit;
}

// ═══ SUB-SCREENS ═══
if (in_refabricator) {
    menu_draw_refabricator(_cx, _cy, _sw, _sh);
    // Transition fade overlay
    if (screen_fade < 1) { draw_set_alpha(1 - screen_fade); draw_set_color(c_black); draw_rectangle(0, 0, _sw, _sh, false); }
    draw_set_alpha(1); draw_set_halign(fa_left); draw_set_valign(fa_top);
    exit;
}

if (in_settings) {
    menu_draw_settings(_cx, _cy, _sw, _sh);
    // Transition fade overlay
    if (screen_fade < 1) { draw_set_alpha(1 - screen_fade); draw_set_color(c_black); draw_rectangle(0, 0, _sw, _sh, false); }
    draw_set_alpha(1); draw_set_halign(fa_left); draw_set_valign(fa_top);
    exit;
}

if (in_story_select && !in_bonus_select) {
    menu_draw_story_select(_cx, _cy, _sw, _sh);
    dialogue_draw();
    // Transition fade overlay
    if (screen_fade < 1) { draw_set_alpha(1 - screen_fade); draw_set_color(c_black); draw_rectangle(0, 0, _sw, _sh, false); }
    draw_set_alpha(1); draw_set_halign(fa_left); draw_set_valign(fa_top);
    exit;
}

if (in_bonus_select) {
    menu_draw_bonus_select(_cx, _cy, _sw, _sh);
    // Transition fade overlay
    if (screen_fade < 1) { draw_set_alpha(1 - screen_fade); draw_set_color(c_black); draw_rectangle(0, 0, _sw, _sh, false); }
    draw_set_alpha(1); draw_set_halign(fa_left); draw_set_valign(fa_top);
    exit;
}

if (in_inventory) {
    menu_draw_inventory(_cx, _cy, _sw, _sh);
    // Transition fade overlay
    if (screen_fade < 1) { draw_set_alpha(1 - screen_fade); draw_set_color(c_black); draw_rectangle(0, 0, _sw, _sh, false); }
    draw_set_alpha(1); draw_set_halign(fa_left); draw_set_valign(fa_top);
    exit;
}

if (in_shop) {
    menu_draw_shop(_cx, _cy, _sw, _sh);
    // Transition fade overlay
    if (screen_fade < 1) { draw_set_alpha(1 - screen_fade); draw_set_color(c_black); draw_rectangle(0, 0, _sw, _sh, false); }
    draw_set_alpha(1); draw_set_halign(fa_left); draw_set_valign(fa_top);
    exit;
}

if (in_how_to_play) {
    menu_draw_how_to_play(_cx, _cy, _sw, _sh);
    // Transition fade overlay
    if (screen_fade < 1) { draw_set_alpha(1 - screen_fade); draw_set_color(c_black); draw_rectangle(0, 0, _sw, _sh, false); }
    draw_set_alpha(1); draw_set_halign(fa_left); draw_set_valign(fa_top);
    exit;
}

if (in_achievements) {
    menu_draw_achievements(_cx, _cy, _sw, _sh);
    // Transition fade overlay
    if (screen_fade < 1) { draw_set_alpha(1 - screen_fade); draw_set_color(c_black); draw_rectangle(0, 0, _sw, _sh, false); }
    draw_set_alpha(1); draw_set_halign(fa_left); draw_set_valign(fa_top);
    exit;
}

// ═══ MAIN MENU DECK ═══
menu_draw_main_deck(_cx, _cy, _sw, _sh);

// Floating texts
menu_draw_floating_texts();

// Dialogue (backstory plays over the menu)
dialogue_draw();

// Transition fade overlay
if (screen_fade < 1) { draw_set_alpha(1 - screen_fade); draw_set_color(c_black); draw_rectangle(0, 0, _sw, _sh, false); }

draw_set_alpha(1); draw_set_halign(fa_left); draw_set_valign(fa_top);
