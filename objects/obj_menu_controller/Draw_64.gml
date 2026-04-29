draw_clear(make_color_rgb(6, 7, 16));

var _cx = room_width * 0.5;
var _h  = room_height;

draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_font(main_font);

// Radial rays
for (var _ray = 0; _ray < 24; _ray++) {
    var _ang = (_ray / 24) * 360;
    draw_set_alpha(0.04); draw_set_color(make_color_rgb(100, 160, 255));
    draw_line_width(_cx, 220, _cx + lengthdir_x(1200, _ang), 220 + lengthdir_y(1200, _ang), 2);
}
draw_set_alpha(1);

// Logo
var _lW = sprite_get_width(spr_logo); var _lH = sprite_get_height(spr_logo);
draw_sprite_ext(spr_logo, 0, _cx, 200, min(700/_lW, 200/_lH), min(700/_lW, 200/_lH), 0, c_white, 1);

// Subtitle
draw_set_color(make_color_rgb(120, 140, 180));
draw_text_transformed(_cx, 330, "JACKPOT PUZZLE MACHINE", 1.1, 1.1, 0);

// Divider
draw_set_alpha(0.2); draw_set_color(make_color_rgb(100, 150, 255));
draw_line_width(_cx - 280, 368, _cx + 280, 368, 1); draw_set_alpha(1);

// ── SETTINGS SCREEN ───────────────────────────────────────────────────────────
if (in_settings) {
    draw_set_color(c_white);
    draw_text_transformed(_cx, 380, "SETTINGS", 1.8, 1.8, 0);

    var _vals = [global.settings.ghostEnabled, global.settings.shakeEnabled];
    var _sy   = 460; var _gap = 70;
    for (var i = 0; i < array_length(settings_items); i++) {
        var _sel  = (i == settings_index);
        var _col  = _sel ? make_color_rgb(255, 220, 80) : make_color_rgb(180, 195, 220);
        var _valC = _vals[i] ? make_color_rgb(100, 230, 100) : make_color_rgb(220, 80, 80);
        draw_set_alpha(1); draw_set_color(_col);
        draw_text_transformed(_cx - 80, _sy + i*_gap, settings_items[i], 1.1, 1.1, 0);
        draw_set_color(_valC);
        draw_text_transformed(_cx + 100, _sy + i*_gap, _vals[i] ? "ON" : "OFF", 1.1, 1.1, 0);
    }
    draw_set_alpha(0.5); draw_set_color(make_color_rgb(255, 214, 102));
    draw_text_transformed(_cx, _h - 60, "Space / Enter  Toggle     Esc  Back", 0.9, 0.9, 0);
    draw_set_alpha(1); draw_set_halign(fa_left); draw_set_valign(fa_top);
    exit; // skip main menu draw
}

// ── MAIN MENU ─────────────────────────────────────────────────────────────────
var _bw2 = 500; var _bh2 = 68; var _bx1 = _cx - _bw2*0.5; var _bx2 = _cx + _bw2*0.5;
var _sy2 = 400; var _gap2 = 14;
for (var i = 0; i < array_length(menu_items); i++) {
    var _y1  = _sy2 + i * (_bh2 + _gap2);
    var _sel = (i == menu_index);
    draw_set_alpha(_sel ? 0.22 : 0.08);
    draw_set_color(_sel ? make_color_rgb(80,140,255) : make_color_rgb(255,255,255));
    draw_roundrect_ext(_bx1, _y1, _bx2, _y1+_bh2, 12, 12, false);
    draw_set_alpha(_sel ? 0.9 : 0.3);
    draw_set_color(_sel ? make_color_rgb(100,170,255) : make_color_rgb(50,60,90));
    draw_roundrect_ext(_bx1, _y1, _bx2, _y1+_bh2, 12, 12, true);
    if (_sel) {
        draw_set_alpha(1); draw_set_color(make_color_rgb(255,220,80));
        draw_roundrect_ext(_bx1, _y1, _bx1+4, _y1+_bh2, 2, 2, false);
    }
    draw_set_alpha(1);
    draw_set_color(_sel ? make_color_rgb(255,220,80) : make_color_rgb(180,195,220));
    draw_text_transformed(_cx, _y1 + _bh2*0.5, menu_items[i], _sel ? 1.15 : 1.0, _sel ? 1.15 : 1.0, 0);
}

// Hint
var _hy = _sy2 + array_length(menu_items) * (_bh2 + _gap2) + 24;
draw_set_alpha(0.6); draw_set_color(make_color_rgb(120,140,170));
draw_text_transformed(_cx, _hy, menu_hint[menu_index], 0.9, 0.9, 0);

// Footer
draw_set_alpha(0.4); draw_set_color(make_color_rgb(255,214,102));
draw_text_transformed(_cx, _h - 60, "↑ ↓  Navigate     Enter / Space  Select", 0.9, 0.9, 0);

draw_set_alpha(1); draw_set_halign(fa_left); draw_set_valign(fa_top);
