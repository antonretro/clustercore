// =============================================================================
// obj_game_manager — Step Event
// Planet and Classic input paths are fully separated.
// =============================================================================

// --- Always-running juice systems ---
var _isFever = (global.feverTimer > 0);
for (var i = 0; i < array_length(global.bg_stars); i++) {
    var _s = global.bg_stars[i];
    _s.y += _isFever ? (_s.spd * 15) : _s.spd;
    if (_s.y > global.GAME_H) _s.y = -10;
}
global.ui_scales.score  += (1.0 - global.ui_scales.score)  * 0.1;
global.ui_scales.level  += (1.0 - global.ui_scales.level)  * 0.1;
global.ui_scales.shards += (1.0 - global.ui_scales.shards) * 0.1;
global.ui_scales.combo  += (1.0 - global.ui_scales.combo)  * 0.1;
global.ui_scales.next   += (1.0 - global.ui_scales.next)   * 0.1;
for (var i = array_length(global.beams) - 1; i >= 0; i--) {
    global.beams[i].life--;
    if (global.beams[i].life <= 0) array_delete(global.beams, i, 1);
}
if (global.payoutFlash  > 0) global.payoutFlash--;
if (global.jackpotFlash > 0) global.jackpotFlash--;
if (global.feverTimer   > 0) global.feverTimer--;
for (var i = array_length(global.particles) - 1; i >= 0; i--) {
    var _p = global.particles[i];
    _p.x += _p.vx; _p.y += _p.vy; _p.life--;
    if (_p.life <= 0) array_delete(global.particles, i, 1);
}
for (var i = array_length(global.floatingTexts) - 1; i >= 0; i--) {
    var _t = global.floatingTexts[i];
    _t.y += _t.vy; _t.life--;
    if (_t.life <= 0) array_delete(global.floatingTexts, i, 1);
}

// --- Board rotation smooth lerp (Planet visual only) ---
var _isRotating = (abs(global.targetRotation - global.boardRotation) > 0.5);
global.boardRotation += (global.targetRotation - global.boardRotation) * 0.2;

// Classic: physically transpose grid once rotation animation completes
if (global.gameMode == "CLASSIC") {
    if (!_isRotating && global.targetRotation != 0) {
        rotate_grid_90();
        global.boardRotation  = 0;
        global.targetRotation = 0;
    }
}

// --- Hitstop ---
if (global.hitstop > 0) { global.hitstop--; exit; }

var _gp = gamepad_is_connected(0);

// Pause / Escape
if (keyboard_check_pressed(vk_escape) || (_gp && gamepad_button_check_pressed(0, gp_start))) {
    if (global.gameState == "PLAYING") global.gameState = "PAUSED";
    else if (global.gameState == "PAUSED") global.gameState = "PLAYING";
}

// Settings hotkeys
if (keyboard_check_pressed(ord("G"))) global.settings.ghostEnabled = !global.settings.ghostEnabled;
if (keyboard_check_pressed(ord("S"))) global.settings.shakeEnabled = !global.settings.shakeEnabled;

// Game Over input
if (global.gameState == "GAMEOVER") {
    if (keyboard_check_pressed(ord("R")) || (_gp && gamepad_button_check_pressed(0, gp_face1))) room_goto(room_game);
    if (keyboard_check_pressed(vk_escape)  || (_gp && gamepad_button_check_pressed(0, gp_start))) room_goto(room_menu);
    exit;
}
if (global.gameState == "PAUSED") exit;

// --- Gameplay ---
if (!global.locking) {
    var _isPlanet = (global.gameMode == "PLANET" || global.gameMode == "STORY");

    // ── PLANET / STORY ────────────────────────────────────────────────────────
    if (_isPlanet) {
        // Countdown timer — auto-fires when time expires
        if (global.gameState == "PLAYING") {
            global.pieceTimer--;
            if (global.pieceTimer <= 0) {
                hard_drop_radial();
            }
        }
    // ── CLASSIC ───────────────────────────────────────────────────────────────
    } else {
        var _interval = max(10, global.DROP_INTERVAL_START - ((global.level - 1) * global.LEVEL_SPEED_SCALE));
        global.dropTimer++;
        if (global.dropTimer >= _interval) { global.dropTimer = 0; move_piece(0, 1); }
    }

    // --- Shared input capture ---
    var _stickX = _gp ? gamepad_axis_value(0, gp_axislh) : 0;
    var _stickY = _gp ? gamepad_axis_value(0, gp_axislv) : 0;
    var _gp_l   = _gp && (gamepad_button_check(0, gp_padl) || _stickX < -0.5);
    var _gp_r   = _gp && (gamepad_button_check(0, gp_padr) || _stickX >  0.5);
    var _gp_lp  = _gp && (gamepad_button_check_pressed(0, gp_padl) || (_stickX < -0.5 && global.gp_prev_stick_x >= -0.5));
    var _gp_rp  = _gp && (gamepad_button_check_pressed(0, gp_padr) || (_stickX >  0.5 && global.gp_prev_stick_x <=  0.5));
    global.gp_prev_stick_x = _stickX;

    var _leftPress  = keyboard_check_pressed(vk_left)  || _gp_lp;
    var _rightPress = keyboard_check_pressed(vk_right) || _gp_rp;
    var _leftHold   = keyboard_check(vk_left)  || _gp_l;
    var _rightHold  = keyboard_check(vk_right) || _gp_r;
    var _up         = keyboard_check_pressed(vk_up)   || (_gp && (gamepad_button_check_pressed(0, gp_padu) || (_stickY < -0.5 && global.gp_prev_stick_y >= -0.5)));
    var _down       = keyboard_check_pressed(vk_down) || (_gp && (gamepad_button_check_pressed(0, gp_padd) || (_stickY >  0.5 && global.gp_prev_stick_y <=  0.5)));
    global.gp_prev_stick_y = _stickY;

    if (global.inputDelayTimer > 0) global.inputDelayTimer--;
    var _inputReady = (global.inputDelayTimer <= 0);
    var _fire     = _inputReady && (keyboard_check_pressed(vk_space) || (_gp && gamepad_button_check_pressed(0, gp_face1)));
    var _fireHeld = _inputReady && (keyboard_check(vk_space)         || (_gp && gamepad_button_check(0, gp_face1)));
    var _fireRel  = _inputReady && (keyboard_check_released(vk_space)|| (_gp && gamepad_button_check_released(0, gp_face1)));
    // vk_up rotates in Classic (standard Tetris). In Planet it adjusts depth — handled below.
    var _hold     = keyboard_check_pressed(ord("C")) || keyboard_check_pressed(vk_lshift)
                 || (_gp && gamepad_button_check_pressed(0, gp_face2));
    var _rotL     = keyboard_check_pressed(ord("Q")) || (_gp && gamepad_button_check_pressed(0, gp_shoulderl));
    var _rotR     = keyboard_check_pressed(ord("E")) || (_gp && gamepad_button_check_pressed(0, gp_shoulderr));

    // DAS
    var _moveDir = 0;
    if (_leftPress)  { _moveDir = -1; global.dasTimer = 0; }
    if (_rightPress) { _moveDir =  1; global.dasTimer = 0; }
    if (_leftHold || _rightHold) {
        global.dasTimer++;
        if (global.dasTimer >= 22) {
            global.dasRepeatTimer++;
            if (global.dasRepeatTimer >= 4) { _moveDir = _leftHold ? -1 : 1; global.dasRepeatTimer = 0; }
        }
    } else { global.dasTimer = 0; global.dasRepeatTimer = 0; }

    // ── PLANET input ──────────────────────────────────────────────────────────
    if (_isPlanet) {
        var _prevSide = global.orbitalSide;

        // Side jump (Q/E or shoulder buttons)
        if (_rotL) { global.orbitalSide--; global.targetRotation = global.orbitalSide * 90; sfx_piece_move(); }
        if (_rotR) { global.orbitalSide++; global.targetRotation = global.orbitalSide * 90; sfx_piece_move(); }

        // Orbital movement with wrap
        if (_moveDir != 0) {
            global.orbitalX += _moveDir;
            if (global.orbitalX < 0)              { global.orbitalSide--; global.orbitalX = global.COLS - 1; }
            if (global.orbitalX >= global.COLS)    { global.orbitalSide++; global.orbitalX = 0; }
            global.targetRotation = global.orbitalSide * 90;
            sfx_piece_move();
        }

        // Update active piece grid position and ghost depth
        if (global.activePiece != undefined) {
            var _pos = get_orbital_pos(global.orbitalSide, global.orbitalX);
            var _posChanged = (global.activePiece.grid_x != _pos.x || global.activePiece.grid_y != _pos.y);
            global.activePiece.grid_x = _pos.x;
            global.activePiece.grid_y = _pos.y;
            // Sync world pixel position so the sprite follows the ring
            global.activePiece.x = (_pos.x - global.HIDDEN_SIDES) * 16;
            global.activePiece.y = (_pos.y - global.HIDDEN_ROWS)  * 16;
            var _maxDepth = max(1, calculate_landing_depth(_pos.x, _pos.y));
            // Reset to max depth on new position; clamp if nudging
            if (_posChanged) global.previewDepth = _maxDepth;
            else             global.previewDepth = clamp(global.previewDepth, 1, _maxDepth);

            // Default to max depth; up/down lets player choose shallower — never floats
            global.previewDepth = clamp(global.previewDepth, 1, _maxDepth);
            if (_down && global.previewDepth < _maxDepth) { global.previewDepth++; sfx_piece_move(); }
            if (_up   && global.previewDepth > 1)         { global.previewDepth--; sfx_piece_move(); }

            // Drills always face inward
            if (global.activePiece.type == "drill") {
                var _s = ((global.orbitalSide % 4) + 4) % 4;
                if (_s == 0) { global.activePiece.dir = 1; global.activePiece.visualRotation =   0; }
                if (_s == 1) { global.activePiece.dir = 0; global.activePiece.visualRotation = 270; }
                if (_s == 2) { global.activePiece.dir = 1; global.activePiece.visualRotation = 180; }
                if (_s == 3) { global.activePiece.dir = 0; global.activePiece.visualRotation =  90; }
                global.activePiece.rotation = 0;
            } else {
                global.activePiece.rotation = -global.boardRotation;
            }
            if (_prevSide != global.orbitalSide) sfx_piece_move();
        }

        // Charge + fire
        if (_fireHeld) global.launchCharge = min(global.launchCharge + 1, global.MAX_CHARGE);
        if (_fireRel || global.launchCharge >= global.MAX_CHARGE) {
            hard_drop_radial();
        }

    // ── CLASSIC input ─────────────────────────────────────────────────────────
    } else {
        if (_leftPress)  { move_piece(-1, 0); sfx_piece_move(); }
        if (_rightPress) { move_piece( 1, 0); sfx_piece_move(); }
        if (_down)  move_piece(0, 1);
        if (_fire)  hard_drop();
    }

    if (_hold) hold_piece();
}

// Visibility: hide blocks still in the hidden top row (but always show active piece)
if (global.activePiece != undefined && instance_exists(global.activePiece)) {
    global.activePiece.visible = true;
}
for (var _y = 0; _y < global.TOTAL_ROWS; _y++) {
    for (var _x = 0; _x < global.TOTAL_COLS; _x++) {
        var _cell = global.grid[_y][_x];
        if (_cell != undefined && instance_exists(_cell.inst)) {
            _cell.inst.visible = (_y >= global.HIDDEN_ROWS);
        }
    }
}
