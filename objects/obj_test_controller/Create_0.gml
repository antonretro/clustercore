// Bootstrap minimal global state for test harness
display_set_gui_size(1920, 1080);

if (!variable_global_exists("COLOR_ACCENT")) global.COLOR_ACCENT = make_color_rgb(100, 150, 255);
if (!variable_global_exists("COLOR_GLOW")) global.COLOR_GLOW = make_color_rgb(255, 200, 100);
if (!variable_global_exists("COLOR_DANGER")) global.COLOR_DANGER = make_color_rgb(255, 50, 50);
if (!variable_global_exists("COLOR_BG")) global.COLOR_BG = make_color_rgb(10, 10, 15);
if (!variable_global_exists("activeColors")) global.activeColors = [1, 2, 3, 4, 5, 6];
if (!variable_global_exists("reserveColors")) global.reserveColors = [];
if (!variable_global_exists("HIDDEN_SIDES")) global.HIDDEN_SIDES = 1;
if (!variable_global_exists("HIDDEN_ROWS")) global.HIDDEN_ROWS = 1;

// Ensure the color_id mapper exists so test_make_test_cell can use it
if (!variable_global_exists("activeColors")) global.activeColors = [1, 2, 3, 4, 5, 6];

// Start the test runner
test_runner_init();
test_runner_register_all();
