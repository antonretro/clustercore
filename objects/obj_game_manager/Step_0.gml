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

// --- Menu / Non-Gameplay Navigation ---
if (global.gameState != "PLAYING" && global.gameState != "PAUSED" && global.gameState != "GAMEOVER") {
    // Bottom Nav Navigation
    if (keyboard_check_pressed(vk_left)) global.menuSelected = (global.menuSelected - 1 + array_length(global.menuOptions)) % array_length(global.menuOptions);
    if (keyboard_check_pressed(vk_right)) global.menuSelected = (global.menuSelected + 1) % array_length(global.menuOptions);
    
    // Switch Screen
    if (keyboard_check_pressed(vk_left) || keyboard_check_pressed(vk_right)) {
        switch(global.menuSelected) {
            case 0: global.gameState = "MENU"; break;
            case 1: global.gameState = "CHALLENGES"; break;
            case 2: global.gameState = "HELP"; break;
            case 3: global.gameState = "NEWS"; break;
            case 4: global.gameState = "SETTINGS"; break;
        }
    }
    
    // Action in Screens
    if (global.gameState == "MENU" && (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space))) {
        start_game();
    }
    
    // Settings adjustments
    if (global.gameState == "SETTINGS") {
        if (keyboard_check_pressed(ord("G"))) global.settings.ghostEnabled = !global.settings.ghostEnabled;
        if (keyboard_check_pressed(ord("S"))) global.settings.shakeEnabled = !global.settings.shakeEnabled;
    }
    exit;
}

if (keyboard_check_pressed(vk_escape)) {
    if (global.gameState == "PLAYING") global.gameState = "PAUSED";
    else if (global.gameState == "PAUSED") global.gameState = "PLAYING";
}

if (global.gameState == "PAUSED" || global.gameState == "GAMEOVER") exit;

var _dt = 1; 

// --- Core Gameplay Logic ---
if (!global.locking) {
    global.dropTimer += _dt;
    var _currentInterval = max(10, global.DROP_INTERVAL_START - ((global.level - 1) * global.LEVEL_SPEED_SCALE));

    if (global.dropTimer >= _currentInterval) {
        global.dropTimer = 0;
        move_piece(0, 1);
    }

    if (keyboard_check_pressed(vk_left)) move_piece(-1, 0);
    if (keyboard_check_pressed(vk_right)) move_piece(1, 0);
    if (keyboard_check_pressed(vk_down)) move_piece(0, 1);
    if (keyboard_check_pressed(vk_space)) hard_drop();
    if (keyboard_check_pressed(ord("Z")) || keyboard_check_pressed(vk_up)) rotate_piece();
    if (keyboard_check_pressed(ord("C")) || keyboard_check_pressed(vk_lshift)) hold_piece();
}

// --- Smooth Rendering Positioning ---
if (global.activePiece != undefined && instance_exists(global.activePiece)) {
    var _targetX = global.activePiece.grid_x * 16; 
    var _targetY = (global.activePiece.grid_y - global.HIDDEN_ROWS) * 16;
    global.activePiece.render_x += (_targetX - global.activePiece.render_x) * 0.2;
    global.activePiece.render_y += (_targetY - global.activePiece.render_y) * 0.2;
    global.activePiece.x = global.activePiece.render_x;
    global.activePiece.y = global.activePiece.render_y;
    global.activePiece.visible = (global.activePiece.grid_y >= global.HIDDEN_ROWS);
}

for (var _y = 0; _y < global.TOTAL_ROWS; _y++) {
    for (var _x = 0; _x < global.COLS; _x++) {
        var _cell = global.grid[_y][_x];
        if (_cell != undefined && instance_exists(_cell.inst)) {
            var _targetX = _x * 16;
            var _targetY = (_y - global.HIDDEN_ROWS) * 16;
            _cell.inst.x = _targetX;
            _cell.inst.y = _targetY;
            _cell.inst.visible = (_y >= global.HIDDEN_ROWS);
            
            // Smooth Scale
            _cell.inst.scale_x += (1.0 - _cell.inst.scale_x) * 0.15;
            _cell.inst.scale_y += (1.0 - _cell.inst.scale_y) * 0.15;
        }
    }
}

// Active Piece Scale Smoothing
if (global.activePiece != undefined && instance_exists(global.activePiece)) {
    global.activePiece.scale_x += (1.0 - global.activePiece.scale_x) * 0.15;
    global.activePiece.scale_y += (1.0 - global.activePiece.scale_y) * 0.15;
}
