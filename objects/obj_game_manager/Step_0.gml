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

// Smooth Board Rotation
var _isRotating = (abs(global.targetRotation - global.boardRotation) > 0.5);
global.boardRotation += (global.targetRotation - global.boardRotation) * 0.2;

// Finalize Rotation (Snap Grid)
// Only physically transpose the grid in Classic mode (Level up)
if (global.gameMode == "CLASSIC") {
    if (!_isRotating && global.targetRotation != 0) {
        rotate_grid_90();
        global.boardRotation = 0;
        global.targetRotation = 0;
    }
}

// --- Hitstop (after juice, before input) ---
if (global.hitstop > 0) {
    global.hitstop--;
    exit;
}

var _gp = gamepad_is_connected(0); // slot 0 — first connected controller

if (keyboard_check_pressed(vk_escape) || (_gp && gamepad_button_check_pressed(0, gp_start))) {
    if (global.gameState == "PLAYING") global.gameState = "PAUSED";
    else if (global.gameState == "PAUSED") global.gameState = "PLAYING";
}

// Settings toggles (available while playing or paused)
if (keyboard_check_pressed(ord("G"))) global.settings.ghostEnabled  = !global.settings.ghostEnabled;
if (keyboard_check_pressed(ord("S"))) global.settings.shakeEnabled  = !global.settings.shakeEnabled;

if (global.gameState == "GAMEOVER") {
    if (keyboard_check_pressed(ord("R"))   || (_gp && gamepad_button_check_pressed(0, gp_face1))) room_goto(room_game);
    if (keyboard_check_pressed(vk_escape)  || (_gp && gamepad_button_check_pressed(0, gp_start))) room_goto(room_menu);
    exit;
}

if (global.gameState == "PAUSED") exit;

var _dt = 1; 

// --- Core Gameplay Logic ---
if (!global.locking) {
    var _planetRules = (global.gameMode == "PLANET" || global.gameMode == "STORY");
    
    if (_planetRules) {
        // COUNTDOWN TIMER for Planet Mode
        if (global.gameState == "PLAYING") {
            global.pieceTimer--;
            if (global.pieceTimer <= 0) {
                hard_drop_radial();
            }
        }
    } else {
        // AUTO-FALL for Classic Mode
        global.dropTimer += _dt;
        var _currentInterval = max(10, global.DROP_INTERVAL_START - ((global.level - 1) * global.LEVEL_SPEED_SCALE));
        if (global.dropTimer >= _currentInterval) {
            global.dropTimer = 0;
            move_piece(0, 1);
        }
    }

    // --- INPUT CAPTURE (keyboard + gamepad merged) ---
    // D-pad OR left stick for movement
    var _stickX     = _gp ? gamepad_axis_value(0, gp_axislh) : 0;
    var _stickY     = _gp ? gamepad_axis_value(0, gp_axislv) : 0;
    var _gp_left    = _gp && (gamepad_button_check(0, gp_padl)  || _stickX < -0.5);
    var _gp_right   = _gp && (gamepad_button_check(0, gp_padr)  || _stickX >  0.5);
    var _gp_lpPress = _gp && (gamepad_button_check_pressed(0, gp_padl) || (_stickX < -0.5 && global.gp_prev_stick_x >= -0.5));
    var _gp_rpPress = _gp && (gamepad_button_check_pressed(0, gp_padr) || (_stickX >  0.5 && global.gp_prev_stick_x <=  0.5));
    global.gp_prev_stick_x = _stickX;

    var _leftPress  = keyboard_check_pressed(vk_left)  || _gp_lpPress;
    var _rightPress = keyboard_check_pressed(vk_right) || _gp_rpPress;
    var _leftHold   = keyboard_check(vk_left)          || _gp_left;
    var _rightHold  = keyboard_check(vk_right)         || _gp_right;

    var _up    = keyboard_check_pressed(vk_up)   || (_gp && (gamepad_button_check_pressed(0, gp_padu) || (_stickY < -0.5 && global.gp_prev_stick_y >= -0.5)));
    var _down  = keyboard_check_pressed(vk_down) || (_gp && (gamepad_button_check_pressed(0, gp_padd) || (_stickY >  0.5 && global.gp_prev_stick_y <=  0.5)));
    global.gp_prev_stick_y = _stickY;

    // Fire: tap space/A = instant, hold = charge, release = fire
    var _fireHeld     = keyboard_check(vk_space)          || (_gp && gamepad_button_check(0, gp_face1));
    var _fireReleased = keyboard_check_released(vk_space) || (_gp && gamepad_button_check_released(0, gp_face1));
    var _space        = keyboard_check_pressed(vk_space)  || (_gp && gamepad_button_check_pressed(0, gp_face1));

    var _rotate = keyboard_check_pressed(ord("Z")) || keyboard_check_pressed(ord("X")) || keyboard_check_pressed(vk_up)
                || (_gp && gamepad_button_check_pressed(0, gp_face4)); // Y button
    var _hold   = keyboard_check_pressed(ord("C")) || keyboard_check_pressed(vk_lshift)
                || (_gp && gamepad_button_check_pressed(0, gp_face2)); // B button

    // Side jumps: Q/E  or  LB/RB
    var _rotL = keyboard_check_pressed(ord("Q")) || (_gp && gamepad_button_check_pressed(0, gp_shoulderl));
    var _rotR = keyboard_check_pressed(ord("E")) || (_gp && gamepad_button_check_pressed(0, gp_shoulderr));

    // --- DAS (Delayed Auto Shift) LOGIC ---
    var _moveDir = 0;
    if (_leftPress)  { _moveDir = -1; global.dasTimer = 0; }
    if (_rightPress) { _moveDir = 1;  global.dasTimer = 0; }
    
    if (_leftHold || _rightHold) {
        global.dasTimer++;
        if (global.dasTimer >= 22) { // 0.36s delay at 60fps
            global.dasRepeatTimer++;
            if (global.dasRepeatTimer >= 4) { // Fast repeat
                _moveDir = _leftHold ? -1 : 1;
                global.dasRepeatTimer = 0;
            }
        }
    } else {
        global.dasTimer = 0;
        global.dasRepeatTimer = 0;
    }

    // --- INPUT: Orbital (Planet) vs Classic ---
    if (_planetRules) {
        var _prevSide = global.orbitalSide;
        
        // Instant Side Jumps
        if (_rotL) { global.orbitalSide--; sfx_piece_move(); }
        if (_rotR) { global.orbitalSide++; sfx_piece_move(); }

        // DAS-Powered Orbital Movement
        if (_moveDir != 0) {
            global.orbitalX += _moveDir;
            
            // Wrap around corners
            if (global.orbitalX < 0) {
                global.orbitalSide--;
                global.orbitalX = global.COLS - 1;
            }
            if (global.orbitalX >= global.COLS) {
                global.orbitalSide++;
                global.orbitalX = 0;
            }
            
            // Sync Visual Rotation
            global.targetRotation = global.orbitalSide * 90;
            
            if (global.activePiece != undefined) {
                var _nx = 0; var _ny = 0;
                var _s = (global.orbitalSide % 4 + 4) % 4;
                if (_s == 0) { _nx = global.orbitalX; _ny = global.HIDDEN_ROWS; }
                if (_s == 1) { _nx = global.COLS - 1; _ny = global.HIDDEN_ROWS + global.orbitalX; }
                if (_s == 2) { _nx = (global.COLS - 1) - global.orbitalX; _ny = global.TOTAL_ROWS - 1; }
                if (_s == 3) { _nx = 0; _ny = (global.TOTAL_ROWS - 1) - global.orbitalX; }
                
                global.activePiece.grid_x = _nx;
                global.activePiece.grid_y = _ny;
                global.previewDepth = calculate_landing_depth(_nx, _ny);
                
                global.activePiece.rotation = -global.boardRotation;
            }
            sfx_piece_move();
        }
        
        // --- GUIDED SNIPER POSITIONING ---
        if (global.activePiece != undefined) {
            if (!_isRotating) {
                var _s = (global.orbitalSide % 4 + 4) % 4;
                var _nx = 0, _ny = 0;
                
                if (_s == 0) { _nx = global.orbitalX; _ny = global.HIDDEN_ROWS; }
                if (_s == 1) { _nx = global.COLS - 1; _ny = global.HIDDEN_ROWS + global.orbitalX; }
                if (_s == 2) { _nx = (global.COLS - 1) - global.orbitalX; _ny = global.TOTAL_ROWS - 1; }
                if (_s == 3) { _nx = 0; _ny = (global.TOTAL_ROWS - 1) - global.orbitalX; }
                
                global.activePiece.grid_x = _nx;
                global.activePiece.grid_y = _ny;
                global.previewDepth = calculate_landing_depth(_nx, _ny);
            
            // Visual Orientation: Counter-rotate to stay vertical on the monitor
            global.activePiece.rotation = -global.boardRotation;
            
            if (_prevSide != global.orbitalSide) sfx_piece_move();
            }
        }
        
        // --- MANUALLY MOVE THE PREVIEW (GHOST) ---
        if (_down) {
            global.previewDepth++;
            if (global.previewDepth > global.TOTAL_ROWS) global.previewDepth = global.TOTAL_ROWS;
        }
        if (_up) {
            global.previewDepth--;
            if (global.previewDepth < 1) global.previewDepth = 1;
        }
        
        // Charge while fire is held; fire on release or at max charge
        if (_fireHeld) {
            global.launchCharge = min(global.launchCharge + 1, global.MAX_CHARGE);
        }
        if (_fireReleased || global.launchCharge >= global.MAX_CHARGE) {
            hard_drop_radial();
            global.previewDepth = 1;
            global.launchCharge = 0;
        }
    } else {
        // --- CLASSIC INPUT ---
        if (_leftPress)  { move_piece(-1, 0); sfx_piece_move(); }
        if (_rightPress) { move_piece(1, 0);  sfx_piece_move(); }
        if (_down)  move_piece(0, 1);
        if (_space) hard_drop();
    }
    
    if (_rotate) { rotate_piece(); sfx_piece_rotate(); }
    if (_hold)   hold_piece();
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
