// --- Juice System Updates (Always Run) ---
// Update BG Stars (Fever Warp)
var _isFever = (global.feverTimer > 0);
for (var i = 0; i < array_length(global.bg_stars); i++) {
    var _s = global.bg_stars[i];
    var _warpSpd = _isFever ? (_s.spd * 15) : _s.spd;
    _s.y += _warpSpd;
    if (_s.y > global.GAME_H) _s.y = -10;
}

// Smooth UI Scales
global.ui_scales.score += (1.0 - global.ui_scales.score) * 0.1;
global.ui_scales.level += (1.0 - global.ui_scales.level) * 0.1;
global.ui_scales.shards += (1.0 - global.ui_scales.shards) * 0.1;
global.ui_scales.combo += (1.0 - global.ui_scales.combo) * 0.1;
global.ui_scales.next += (1.0 - global.ui_scales.next) * 0.1;

// Update Beams
for (var i = array_length(global.beams) - 1; i >= 0; i--) {
    var _b = global.beams[i];
    _b.life--;
    if (_b.life <= 0) array_delete(global.beams, i, 1);
}

// Update Payout Flash
if (global.payoutFlash > 0) global.payoutFlash--;
if (global.jackpotFlash > 0) global.jackpotFlash--;

// Update Fever Timer
if (global.feverTimer > 0) global.feverTimer--;

// Update Particles
for (var i = array_length(global.particles) - 1; i >= 0; i--) {
    var _p = global.particles[i];
    _p.x += _p.vx;
    _p.y += _p.vy;
    _p.life--;
    if (_p.life <= 0) array_delete(global.particles, i, 1);
}

// Update Floating Text
for (var i = array_length(global.floatingTexts) - 1; i >= 0; i--) {
    var _t = global.floatingTexts[i];
    _t.y += _t.vy;
    _t.life--;
    if (_t.life <= 0) array_delete(global.floatingTexts, i, 1);
}

// --- Hitstop (after juice, before input) ---
if (global.hitstop > 0) {
    global.hitstop--;
    exit;
}

if (keyboard_check_pressed(vk_escape)) {
    if (global.gameState == "PLAYING") global.gameState = "PAUSED";
    else if (global.gameState == "PAUSED") global.gameState = "PLAYING";
}

// Settings toggles (available while playing or paused)
if (keyboard_check_pressed(ord("G"))) global.settings.ghostEnabled  = !global.settings.ghostEnabled;
if (keyboard_check_pressed(ord("S"))) global.settings.shakeEnabled  = !global.settings.shakeEnabled;

if (global.gameState == "GAMEOVER") {
    if (keyboard_check_pressed(ord("R"))) room_goto(room_game);
    if (keyboard_check_pressed(vk_escape)) room_goto(room_menu);
    exit;
}

if (global.gameState == "PAUSED") exit;

var _dt = 1; 

// --- Core Gameplay Logic ---
if (!global.locking) {
    global.dropTimer += _dt;
    var _currentInterval = max(10, global.DROP_INTERVAL_START - ((global.level - 1) * global.LEVEL_SPEED_SCALE));

    if (global.dropTimer >= _currentInterval) {
        global.dropTimer = 0;
        move_piece(0, 1);
    }

    if (keyboard_check_pressed(vk_left))  { move_piece(-1, 0); sfx_piece_move(); }
    if (keyboard_check_pressed(vk_right)) { move_piece(1, 0);  sfx_piece_move(); }
    if (keyboard_check_pressed(vk_down))  move_piece(0, 1);
    if (keyboard_check_pressed(vk_space)) hard_drop();
    if (keyboard_check_pressed(ord("Z")) || keyboard_check_pressed(vk_up)) { rotate_piece(); sfx_piece_rotate(); }
    if (keyboard_check_pressed(ord("C")) || keyboard_check_pressed(vk_lshift)) hold_piece();
}

// Recovery from squash/stretch
if (global.activePiece != undefined && instance_exists(global.activePiece)) {
    global.activePiece.visible = (global.activePiece.grid_y >= global.HIDDEN_ROWS);
}

for (var _y = 0; _y < global.TOTAL_ROWS; _y++) {
    for (var _x = 0; _x < global.COLS; _x++) {
        var _cell = global.grid[_y][_x];
        if (_cell != undefined && instance_exists(_cell.inst)) {
            _cell.inst.visible = (_y >= global.HIDDEN_ROWS);
        }
    }
}
