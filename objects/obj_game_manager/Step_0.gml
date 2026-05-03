// =============================================================================
// obj_game_manager — Step Event
// Planet and Classic input paths are fully separated.
// =============================================================================

// --- Always-running juice systems ---
steam_ach_update();
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
if (global.chainTimer > 0) {
    global.chainTimer--;
    if (global.chainTimer == 1) settle_matches();
}
for (var i = array_length(global.particles) - 1; i >= 0; i--) {
    var _p = global.particles[i];
    _p.x += _p.vx; _p.y += _p.vy; _p.life--;
    if (_p.life <= 0) array_delete(global.particles, i, 1);
}

// Cinematic Entry Blocking
if (global.entry_timer > 0) {
    global.entry_timer--;
    exit;
}
for (var i = array_length(global.floatingTexts) - 1; i >= 0; i--) {
    var _t = global.floatingTexts[i];
    _t.y += _t.vy; _t.life--;
    if (_t.life <= 0) array_delete(global.floatingTexts, i, 1);
}
for (var i = array_length(global.flyingShards) - 1; i >= 0; i--) {
    var _fs = global.flyingShards[i];
    _fs.life++;
    var _t2 = clamp(_fs.life / max(1, _fs.maxLife), 0, 1);
    var _ease = 1 - power(1 - _t2, 3);
    _fs.x = lerp(_fs.sx, _fs.tx, _ease);
    _fs.y = lerp(_fs.sy, _fs.ty, _ease) - sin(_t2 * pi) * _fs.arc;
    if (_fs.life >= _fs.maxLife) {
        global.runShards += _fs.value;
        global.walletShards += _fs.value;
        global.storyShardsCollected += (global.gameMode == "STORY") ? _fs.value : 0;
        wallet_save();
        array_delete(global.flyingShards, i, 1);
    }
}

if (global.settings.hintPulseEnabled) {
    hint_update();
}

if (global.gameMode == "PLANET" || global.gameMode == "STORY") {
    update_core_stability();
    
    // --- Meteor Storm Update (Endless Only) ---
    if (global.gameMode == "PLANET" && global.gameState == "PLAYING") {
        global.meteorSpawnTimer--;
        if (global.meteorSpawnTimer <= 0) {
            global.meteorSpawnTimer = global.meteorRate * (0.8 + random(0.4));
            
            // Spawn meteor at edge
            var _ang = random(360);
            var _dist = 1200;
            var _mx = global.GAME_W/2 + lengthdir_x(_dist, _ang);
            var _my = global.GAME_H/2 + lengthdir_y(_dist, _ang);
            var _spd = 4 + random(4);
            
            var _mType = "asteroid";
            var _r = random(100);
            if (_r < 40) _mType = "normal";
            if (_r > 80) _mType = "dirt";
            
            array_push(global.meteors, {
                x: _mx, y: _my,
                vx: lengthdir_x(_spd, _ang + 180),
                vy: lengthdir_y(_spd, _ang + 180),
                type: _mType,
                color: irandom(5) + 1,
                rot: random(360),
                rot_spd: -2 + random(4),
                active: true
            });
        }
    }
    
    // Update meteors
    for (var i = array_length(global.meteors) - 1; i >= 0; i--) {
        var _m = global.meteors[i];
        _m.x += _m.vx; _m.y += _m.vy; _m.rot += _m.rot_spd;
        
        // ROTATION-AWARE Grid Collision Check
        // We must transform screen-space (x,y) into board-relative space by un-rotating it
        var _distToCtr = point_distance(_m.x, _m.y, global.GAME_W/2, global.GAME_H/2);
        var _angToCtr  = point_direction(global.GAME_W/2, global.GAME_H/2, _m.x, _m.y);
        var _relAng    = _angToCtr - global.boardRotation;
        
        var _boardX = global.GAME_W/2 + lengthdir_x(_distToCtr, _relAng);
        var _boardY = global.GAME_H/2 + lengthdir_y(_distToCtr, _relAng);
        
        var _bwHalf = (global.TOTAL_COLS * 16 * global.PIXEL_SCALE) / 2;
        var _bhHalf = (global.TOTAL_ROWS * 16 * global.PIXEL_SCALE) / 2;
        
        var _gx = floor((_boardX - (global.GAME_W/2 - _bwHalf)) / (16*global.PIXEL_SCALE));
        var _gy = floor((_boardY - (global.GAME_H/2 - _bhHalf)) / (16*global.PIXEL_SCALE));
        
        if (grid_in_bounds(_gx, _gy)) {
            var _occ = (global.grid[_gy][_gx] != undefined);
            if (_occ) {
                // Impact! Settle in the PREVIOUS position relative to the board
                var _prevDist = point_distance(_m.x - _m.vx, _m.y - _m.vy, global.GAME_W/2, global.GAME_H/2);
                var _prevAng  = point_direction(global.GAME_W/2, global.GAME_H/2, _m.x - _m.vx, _m.y - _m.vy) - global.boardRotation;
                var _pbX = global.GAME_W/2 + lengthdir_x(_prevDist, _prevAng);
                var _pbY = global.GAME_H/2 + lengthdir_y(_prevDist, _prevAng);
                
                var _bgx = floor((_pbX - (global.GAME_W/2 - _bwHalf)) / (16*global.PIXEL_SCALE));
                var _bgy = floor((_pbY - (global.GAME_H/2 - _bhHalf)) / (16*global.PIXEL_SCALE));
                
                if (grid_in_bounds(_bgx, _bgy) && global.grid[_bgy][_bgx] == undefined) {
                    var _newType = (_m.type == "dirt") ? "normal" : _m.type;
                    var _nInst = instance_create_layer(0, 0, "Instances", obj_block);
                    global.grid[_bgy][_bgx] = {
                        type: _newType,
                        color: get_color_from_id(_m.color),
                        id: _m.color,
                        dir: irandom(1),
                        inst: _nInst
                    };
                    with (_nInst) {
                        grid_x = _bgx; grid_y = _bgy;
                        // World position must be relative to grid center for the matrix draw
                        x = (grid_x - global.HIDDEN_SIDES) * 16;
                        y = (grid_y - global.HIDDEN_ROWS)  * 16;
                        type = _newType; color_id = _m.color;
                        if (_m.type == "dirt") sprite_index = asset_get_index("spr_dirt_block");
                        update_sprite();
                    }
                    create_particles(_m.x, _m.y, c_white);
                    sfx_piece_lock();
                }
                array_delete(global.meteors, i, 1);
            }
        }
        
        // Out of bounds cleanup
        if (_m.x < -2000 || _m.x > 4000 || _m.y < -2000 || _m.y > 4000) array_delete(global.meteors, i, 1);
    }
}

if (global.gameState == "PLAYING" && global.gameMode == "STORY") {
    var _debtDrain = 0;
    for (var _dyDebt = 0; _dyDebt < global.TOTAL_ROWS; _dyDebt++) {
        for (var _dxDebt = 0; _dxDebt < global.TOTAL_COLS; _dxDebt++) {
            var _debtCell = global.grid[_dyDebt][_dxDebt];
            if (_debtCell != undefined && _debtCell.type == "debt") _debtDrain++;
        }
    }
    if (_debtDrain > 0) {
        if (variable_global_exists("pieceTimer")) global.pieceTimer = max(0, global.pieceTimer - 0.04 * _debtDrain);
        if (variable_global_exists("coreStability")) global.coreStability = max(0, global.coreStability - 0.01 * _debtDrain);
    }
}

// --- Board rotation smooth lerp (Planet visual only) ---
var _isRotating = (abs(global.targetRotation - global.boardRotation) > 0.5);
if (global.gameState != "FINISHING_LEVEL") {
    global.boardRotation += (global.targetRotation - global.boardRotation) * 0.2;
}

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

// Fullscreen toggle
if (keyboard_check_pressed(vk_f11)) {
    window_set_fullscreen(!window_get_fullscreen());
}

if (keyboard_check_pressed(vk_f12)) {
    room_goto(room_test);
    exit;
}

// Settings hotkeys
if (keyboard_check_pressed(ord("G"))) global.settings.ghostEnabled = !global.settings.ghostEnabled;
if (keyboard_check_pressed(ord("S"))) global.settings.shakeEnabled = !global.settings.shakeEnabled;
if (keyboard_check_pressed(ord("H"))) global.settings.hintPulseEnabled = !global.settings.hintPulseEnabled;

// Game Over / Level Complete input
if (global.gameState == "PLAYING" && global.gameMode == "STORY" && global.turnLimit > 0) {
    if (global.turnCount >= global.turnLimit) {
        // Give one final check if clearing just happened
        if (!story_objective_is_met()) {
            global.gameState = "GAMEOVER";
        }
    }
}

if (global.gameState == "GAMEOVER" || global.gameState == "LEVEL_COMPLETE" || global.gameState == "FINISHING_LEVEL") {
    var _proceed = (keyboard_check_pressed(vk_space) || keyboard_check_pressed(vk_enter) || (_gp && gamepad_button_check_pressed(0, gp_face1)));
    
    if (global.gameState == "LEVEL_COMPLETE") {
        if (_proceed) start_game();
    } else if (global.gameState == "FINISHING_LEVEL") {
        if (!global.victoryRevealActive) {
            global.victoryRevealActive = true;
            var _plts = [spr_mercury, spr_venus, spr_earth, spr_mars, spr_jupiter, spr_saturn, spr_neptune];
            global.victoryPlanetSprite = _plts[irandom(array_length(_plts)-1)];
            global.victoryPlanetAlpha = 0;
            global.victoryPlanetScale = 0.2;
            global.flashAlpha = 1.0; // TRIGGER FLASH AT START
        }
        
        if (global.finishTimer > 0) {
            global.finishTimer--;
            global.victoryPlanetAlpha = min(1.0, global.victoryPlanetAlpha + 0.02);
            global.victoryPlanetScale = min(5.0, global.victoryPlanetScale + 0.08);
            global.flashAlpha = max(global.flashAlpha, 0.5);
        }
        
        // FADE IN REVEAL PLANET, FADE OUT GRID
        if (global.finishTimer < 85) {
            global.victoryPlanetAlpha = min(1.0, global.victoryPlanetAlpha + 0.04);
            global.victoryPlanetScale = min(5.0, global.victoryPlanetScale + 0.08);
            global.restoredTilesAlpha = max(0.0, global.restoredTilesAlpha - 0.05);
        }
        
        // ACCELERATING VICTORY SPIN + SHAKE + SLIDE OFF
        var _spinSpeed = (100 - global.finishTimer) * 0.35;
        global.boardRotation += _spinSpeed;
        global.shakeAmount = (100 - global.finishTimer) * 0.65;
        
        // Slide the board down to 'reveal' the planet behind it
        if (global.finishTimer < 60) {
            global.boardOffsetY = lerp(global.boardOffsetY, 1500, 0.08); 
        }
        
        // SUSTAINED EXPLOSIONS
        if (global.finishTimer % 4 == 0) {
            var _rx = random_range(global.GAME_W * 0.1, global.GAME_W * 0.9);
            var _ry = random_range(global.GAME_H * 0.1, global.GAME_H * 0.9);
            create_particles(_rx, _ry, c_white);
        }
        
        if (global.finishTimer <= 0) {
            story_advance_planet();
            global.victoryRevealActive = false;
        }
    } else {
        if (keyboard_check_pressed(ord("R")) || (_gp && gamepad_button_check_pressed(0, gp_face1))) room_goto(room_game);
        if (keyboard_check_pressed(vk_escape)  || (_gp && gamepad_button_check_pressed(0, gp_start))) room_goto(room_menu);
    }
    exit;
}
if (global.gameState == "PAUSED") {
    if (keyboard_check_pressed(ord("R"))) room_goto(room_game);
    if (keyboard_check_pressed(ord("M"))) room_goto(room_menu);
    if (keyboard_check_pressed(vk_f11)) window_set_fullscreen(!window_get_fullscreen());
    if (keyboard_check_pressed(vk_f12)) { room_goto(room_test); exit; }
    if (keyboard_check_pressed(vk_escape) || keyboard_check_pressed(ord("P")) || (_gp && gamepad_button_check_pressed(0, gp_start))) {
        global.gameState = "PLAYING";
    }
    exit;
}
if (dialogue_is_active()) { dialogue_update(); exit; }

// --- Juice & Feedback Decay ---
if (global.flashAlpha > 0) global.flashAlpha *= 0.92;
if (global.flashAlpha < 0.01) global.flashAlpha = 0;
if (global.shipRecoil > 0) global.shipRecoil *= 0.85;

// --- Gameplay ---
if (!global.locking) {
    var _isPlanet = (global.gameMode == "PLANET" || global.gameMode == "STORY");

    if (global.gameMode == "BONUS") {
        global.bonusTimer--;
        if (global.bonusTimer <= 0) {
            global.bonusTimer = 0;
            global.gameState = "GAMEOVER";
            global.bonusComplete = (global.score >= global.bonusScoreGoal);
            if (global.bonusComplete) {
                global.walletShards += global.bonusRewardShards;
                global.runShards += global.bonusRewardShards;
                wallet_save();
                create_floating_text_ext(global.GAME_W * 0.5, global.GAME_H * 0.32,
                    "DWARF PLANET CLEARED +" + string(global.bonusRewardShards) + " SHARDS",
                    make_color_rgb(120, 230, 255), 1.55);
            } else {
                create_floating_text_ext(global.GAME_W * 0.5, global.GAME_H * 0.32,
                    "DWARF PLANET FAILED", global.COLOR_DANGER, 1.55);
            }
            if (global.score > global.highScore) {
                global.highScore = global.score;
                save_high_score();
            }
            exit;
        }
    }

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
    var _downHold   = keyboard_check(vk_down) || (_gp && (_stickY > 0.5 || gamepad_button_check(0, gp_padd)));
    global.gp_prev_stick_y = _stickY;

    if (global.inputDelayTimer > 0) global.inputDelayTimer--;
    var _inputReady = (global.inputDelayTimer <= 0);
    var _fire     = _inputReady && (keyboard_check_pressed(vk_space) || (_gp && gamepad_button_check_pressed(0, gp_face1)));
    var _fireHeld = _inputReady && (keyboard_check(vk_space)         || (_gp && gamepad_button_check(0, gp_face1)));
    var _fireRel  = _inputReady && (keyboard_check_released(vk_space)|| (_gp && gamepad_button_check_released(0, gp_face1)));
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

    // ── Input Handling ───────────────────────────────────────────────────────
    var _ctrls = {
        rotL: _rotL, rotR: _rotR, moveDir: _moveDir,
        up: _up, down: _down,
        fireHeld: _fireHeld, fireRel: _fireRel
    };

    if (_isPlanet) {
        handle_planet_input(_ctrls);
    } else {
        if (_leftPress)  { move_piece(-1, 0); sfx_piece_move(); }
        if (_rightPress) { move_piece( 1, 0); sfx_piece_move(); }
        // Classic soft-drop DAS/ARR: hold down repeats after a short delay.
        if (_down) {
            move_piece(0, 1);
            global.softDropDasTimer = 0;
            global.softDropRepeatTimer = 0;
        }
        if (_downHold) {
            global.softDropDasTimer++;
            if (global.softDropDasTimer >= 30) { // ~0.5s at 60 FPS
                global.softDropRepeatTimer++;
                if (global.softDropRepeatTimer >= 2) {
                    move_piece(0, 1);
                    global.softDropRepeatTimer = 0;
                }
            }
        } else {
            global.softDropDasTimer = 0;
            global.softDropRepeatTimer = 0;
        }
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
