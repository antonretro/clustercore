// Test harness GUI
draw_clear(make_color_rgb(6, 7, 16));
draw_set_halign(fa_left);
draw_set_valign(fa_top);

// Header
draw_set_color(c_white);
draw_text_transformed(40, 40, "CLUSTER CORE - TEST HARNESS", 3, 3, 0);

// Status line
var _status = global.__test_done ? "COMPLETE" : "RUNNING...";
var _statusCol = global.__test_done ? make_color_rgb(100, 255, 100) : make_color_rgb(255, 220, 80);
draw_set_color(_statusCol);
draw_text_transformed(40, 100, _status + "  Passed: " + string(global.__test_passed) + "  Failed: " + string(global.__test_failed) + "  Total: " + string(global.__test_total), 2, 2, 0);

// Progress bar
var _total = max(1, global.__test_total);
var _done = global.__test_passed + global.__test_failed;
var _prog = _done / _total;
draw_set_color(make_color_rgb(30, 30, 50));
draw_roundrect_ext(40, 145, 800, 165, 6, 6, false);
draw_set_color(make_color_rgb(100, 200, 100));
draw_roundrect_ext(40, 145, 40 + 760 * _prog, 165, 6, 6, false);

// Speed indicator
draw_set_color(make_color_rgb(150, 150, 180));
draw_text_transformed(860, 145, "Speed: " + string(global.__test_batch_size) + "/frame", 1.2, 1.2, 0);

// Results
var _scrollY = 185;
test_runner_draw(_scrollY);

// Footer
draw_set_alpha(0.6);
draw_set_color(make_color_rgb(255, 214, 102));
draw_set_halign(fa_center);
draw_text_transformed(960, 1040, "ESC: Return to Menu    F5: Re-run Tests    Left/Right: Adjust Speed", 1.5, 1.5, 0);
draw_set_alpha(1);
