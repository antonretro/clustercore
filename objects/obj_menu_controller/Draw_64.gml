draw_clear(make_color_rgb(8, 10, 18));

var _cx = room_width * 0.5;
var _title_y = 150;

draw_set_halign(fa_center);
draw_set_valign(fa_middle);

for (var _ray = 0; _ray < 18; _ray++) {
    var _ang = (_ray / 18) * 360;
    draw_set_alpha(0.08);
    draw_set_color(make_color_rgb(255, 214, 102));
    draw_line_width(_cx, _title_y + 40, _cx + lengthdir_x(900, _ang), _title_y + 40 + lengthdir_y(900, _ang), 4);
}
draw_set_alpha(1);

draw_set_color(make_color_rgb(255, 214, 102));
draw_text_transformed(_cx + 4, _title_y + 4, "CLUSTER CORE", 1.5, 1.5, 0);
draw_set_color(make_color_rgb(102, 217, 232));
draw_text_transformed(_cx, _title_y, "CLUSTER CORE", 1.5, 1.5, 0);

draw_set_color(c_white);
draw_text_transformed(_cx, _title_y + 96, "JACKPOT PUZZLE MACHINE", 1, 1, 0);

var _panel_w = 620;
var _panel_x1 = _cx - _panel_w * 0.5;
var _panel_x2 = _cx + _panel_w * 0.5;
var _start_y = 350;
var _row_h = 64;

for (var i = 0; i < array_length(menu_items); i++) {
    var _y1 = _start_y + i * _row_h;
    var _selected = (i == menu_index);

    draw_set_alpha(_selected ? 0.98 : 0.42);
    draw_set_color(_selected ? make_color_rgb(74, 144, 226) : make_color_rgb(35, 42, 58));
    draw_roundrect_ext(_panel_x1, _y1, _panel_x2, _y1 + 50, 8, 8, false);
    draw_set_alpha(1);
    draw_set_color(_selected ? make_color_rgb(255, 214, 102) : make_color_rgb(80, 92, 120));
    draw_roundrect_ext(_panel_x1, _y1, _panel_x2, _y1 + 50, 8, 8, true);

    draw_set_color(c_white);
    draw_text_transformed(_cx, _y1 + 25, menu_items[i], _selected ? 1.05 : 1, _selected ? 1.05 : 1, 0);
}

draw_set_color(make_color_rgb(170, 180, 196));
draw_text(_cx, _start_y + array_length(menu_items) * _row_h + 38, menu_hint[menu_index]);
draw_set_color(make_color_rgb(255, 214, 102));
draw_text(_cx, room_height - 86, "Up/Down to choose  |  Enter/Space to select");

draw_set_halign(fa_left);
draw_set_valign(fa_top);
