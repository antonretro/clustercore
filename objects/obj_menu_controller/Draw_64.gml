draw_clear(make_color_rgb(6, 7, 16));

var _cx    = room_width * 0.5;
var _cy    = room_height * 0.5;
var _w     = room_width;
var _h     = room_height;

draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_font(main_font);

// --- Radial rays behind logo ---
for (var _ray = 0; _ray < 24; _ray++) {
    var _ang = (_ray / 24) * 360;
    draw_set_alpha(0.04);
    draw_set_color(make_color_rgb(100, 160, 255));
    draw_line_width(_cx, 220, _cx + lengthdir_x(1200, _ang), 220 + lengthdir_y(1200, _ang), 2);
}
draw_set_alpha(1);

// --- Logo ---
var _logoW     = sprite_get_width(spr_logo);
var _logoH     = sprite_get_height(spr_logo);
var _logoScale = min(700 / _logoW, 200 / _logoH);
draw_sprite_ext(spr_logo, 0, _cx, 200, _logoScale, _logoScale, 0, c_white, 1);

// --- Subtitle ---
draw_set_color(make_color_rgb(120, 140, 180));
draw_text_transformed(_cx, 330, "JACKPOT PUZZLE MACHINE", 1.1, 1.1, 0);

// --- Divider ---
draw_set_alpha(0.2);
draw_set_color(make_color_rgb(100, 150, 255));
draw_line_width(_cx - 280, 368, _cx + 280, 368, 1);
draw_set_alpha(1);

// --- Menu Buttons ---
var _btn_w  = 500;
var _btn_h  = 68;
var _btn_x1 = _cx - _btn_w * 0.5;
var _btn_x2 = _cx + _btn_w * 0.5;
var _start_y = 400;
var _gap     = 14;

for (var i = 0; i < array_length(menu_items); i++) {
    var _y1       = _start_y + i * (_btn_h + _gap);
    var _selected = (i == menu_index);
    var _alpha_bg = _selected ? 0.22 : 0.08;
    var _col_bg   = _selected ? make_color_rgb(80, 140, 255)  : make_color_rgb(255, 255, 255);
    var _col_brd  = _selected ? make_color_rgb(100, 170, 255) : make_color_rgb(50, 60, 90);
    var _col_txt  = _selected ? make_color_rgb(255, 220, 80)  : make_color_rgb(180, 195, 220);
    var _txt_sc   = _selected ? 1.15 : 1.0;

    // Button fill
    draw_set_alpha(_alpha_bg);
    draw_set_color(_col_bg);
    draw_roundrect_ext(_btn_x1, _y1, _btn_x2, _y1 + _btn_h, 12, 12, false);

    // Button border
    draw_set_alpha(_selected ? 0.9 : 0.3);
    draw_set_color(_col_brd);
    draw_roundrect_ext(_btn_x1, _y1, _btn_x2, _y1 + _btn_h, 12, 12, true);

    // Selection indicator
    if (_selected) {
        draw_set_alpha(1);
        draw_set_color(make_color_rgb(255, 220, 80));
        draw_roundrect_ext(_btn_x1, _y1, _btn_x1 + 4, _y1 + _btn_h, 2, 2, false);
    }

    // Label
    draw_set_alpha(1);
    draw_set_color(_col_txt);
    draw_text_transformed(_cx, _y1 + _btn_h * 0.5, menu_items[i], _txt_sc, _txt_sc, 0);
}

// --- Hint text ---
var _hint_y = _start_y + array_length(menu_items) * (_btn_h + _gap) + 24;
draw_set_alpha(0.6);
draw_set_color(make_color_rgb(120, 140, 170));
draw_text_transformed(_cx, _hint_y, menu_hint[menu_index], 0.9, 0.9, 0);

// --- Controls footer ---
draw_set_alpha(0.4);
draw_set_color(make_color_rgb(255, 214, 102));
draw_text_transformed(_cx, _h - 60, "↑ ↓  Navigate     Enter / Space  Select", 0.9, 0.9, 0);

draw_set_alpha(1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
