// --- Configuration ---
if (room == room_game) {
    if (!variable_global_exists("launch_mode") || global.launch_mode != "endless") {
        room_goto(room_menu);
        exit;
    }
}

global.COLS = 5;
global.ROWS = 9;
global.HIDDEN_ROWS = 2;
global.TOTAL_ROWS = global.ROWS + global.HIDDEN_ROWS;
global.DROP_INTERVAL_START = 60; // Steps (assuming 60fps)
global.LEVEL_SPEED_SCALE = 5;

// --- High-Res Pixel Aesthetic ---
gpu_set_texfilter(false); // Sharp pixels for sprites
// surface_resize removed to keep HD resolution for text/UI
display_set_gui_size(room_width, room_height);

// Render at room resolution, but scale pixel art with nearest-neighbor.
global.game_surface = -1;
global.GAME_W = room_width;
global.GAME_H = room_height;
global.PIXEL_SCALE = 6;
global.CELL = 16;
gpu_set_texfilter(false); // Remove Blur globally

// --- CSS Colors & Style ---
global.COLOR_BG1 = make_color_rgb(26, 26, 46);
global.COLOR_BG2 = make_color_rgb(22, 33, 62);
global.COLOR_ACCENT = make_color_rgb(74, 144, 226);
global.COLOR_DANGER = make_color_rgb(255, 71, 87);
global.COLOR_GLOW = make_color_rgb(102, 217, 232);

// Background Gradient Colors
global.bg_colors = [
    make_color_rgb(15, 12, 41),
    make_color_rgb(48, 43, 99),
    make_color_rgb(36, 36, 62)
];
global.bg_timer = 0;

// --- State Management ---
global.grid = array_create(global.TOTAL_ROWS);
for (var i = 0; i < global.TOTAL_ROWS; i++) {
    global.grid[i] = array_create(global.COLS, undefined);
}

global.score = 0;
global.level = 1;
global.levelScore = 0;
global.scoreToNext = 1500;
global.coreShards = 0;
global.runShards = 0;
global.jackpotMeter = 0;
global.jackpotMax = 100;
global.feverTimer = 0;
global.comboChain = 0;
global.bestCombo = 0;
global.payoutFlash = 0;
global.gameOver = false;
global.paused = false;
global.activePiece = undefined;
global.activeColors = [1, 2, 3]; // Indices for colors
global.reserveColors = [4, 5, 6];

global.nextQueue = [];
for (var i = 0; i < 3; i++) array_push(global.nextQueue, generate_piece());
global.holdPiece = undefined;
global.canHold = true;

global.gameState = "MENU"; // MENU, CHALLENGES, HELP, NEWS, SETTINGS, PLAYING, PAUSED, GAMEOVER
global.menuSelected = 0;
global.menuOptions = ["Home", "Challenges", "Help", "News", "Settings"];

// --- Settings Parity ---
global.settings = {
    masterVol: 0.5,
    sfxVol: 0.8,
    musicVol: 0.3,
    ghostEnabled: true,
    shakeEnabled: true,
    beamEnabled: true,
    mouseEnabled: false,
    controlScheme: "swipe" // "swipe" or "buttons"
};

global.missions = [
    { id: 1, name: "First Steps", desc: "Clear 30 blocks.", target: 30, current: 0, completed: false },
    { id: 2, name: "Diagonal Beginner", desc: "Clear 1 diagonal line.", target: 1, current: 0, completed: false },
    { id: 3, name: "Level Up", desc: "Reach Level 3.", target: 3, current: 0, completed: false },
    { id: 4, name: "Drill Team", desc: "Use 3 Drill objects.", target: 3, current: 0, completed: false },
    { id: 5, name: "Pink Alert", desc: "Clear 2 Pink clusters.", target: 2, current: 0, completed: false },
    { id: 6, name: "Arrow Storm", desc: "Clear 3 Arrow clusters.", target: 3, current: 0, completed: false },
    { id: 7, name: "Combo Rookie", desc: "Achieve a 2x Combo.", target: 2, current: 0, completed: false },
    { id: 8, name: "Speed Run", desc: "Clear 30 blocks fast.", target: 30, current: 0, completed: false },
    { id: 9, name: "Demolition", desc: "Use 5 Bombs.", target: 5, current: 0, completed: false },
    { id: 10, name: "Survivor", desc: "Survive for 2 minutes.", target: 120, current: 0, completed: false },
    { id: 11, name: "Master Diagonal", desc: "Clear 3 diagonal lines.", target: 3, current: 0, completed: false },
    { id: 12, name: "High Climber", desc: "Reach Level 10.", target: 10, current: 0, completed: false }
];
global.currentMission = -1;

global.dropTimer = 0;
global.locking = false;
global.shakeAmount = 0;

// --- Juice Systems ---
global.particles = [];
global.bg_stars = [];
for (var i = 0; i < 50; i++) {
    array_push(global.bg_stars, {
        x: random(global.GAME_W),
        y: random(global.GAME_H),
        spd: random_range(0.1, 0.4),
        size: random_range(1, 2),
        alpha: 0.3
    });
}
// Parallax Layer 2 (Faster/Larger)
for (var i = 0; i < 20; i++) {
    array_push(global.bg_stars, {
        x: random(global.GAME_W),
        y: random(global.GAME_H),
        spd: random_range(0.5, 1.2),
        size: random_range(2, 4),
        alpha: 0.6
    });
}
global.floatingTexts = [];
global.beams = [];
global.payoutFlash = 0;

// Panel Scales for Animation
global.ui_scales = {
    score: 1.0,
    level: 1.0,
    shards: 1.0,
    combo: 1.0,
    next: 1.0
};

create_particles = function(_x, _y, _color) {
    for (var i = 0; i < 8; i++) {
        array_push(global.particles, {
            x: _x, y: _y,
            vx: random_range(-2, 2),
            vy: random_range(-2, 2),
            life: 30,
            color: _color
        });
    }
}

create_floating_text = function(_x, _y, _text) {
    array_push(global.floatingTexts, {
        x: _x, y: _y,
        text: _text,
        life: 60,
        vy: -0.5,
        color: c_white,
        scale: 1
    });
}

create_floating_text_ext = function(_x, _y, _text, _color, _scale) {
    array_push(global.floatingTexts, {
        x: _x, y: _y,
        text: _text,
        life: 70,
        vy: -0.75,
        color: _color,
        scale: _scale
    });
}

create_beam = function(_x, _y, _w, _h, _color) {
    array_push(global.beams, {
        x: _x, y: _y,
        w: _w, h: _h,
        life: 20,
        maxLife: 20,
        color: _color,
        type: "beam"
    });
}

create_impact = function(_x, _y, _w, _color) {
    array_push(global.beams, {
        x: _x, y: _y,
        w: _w, h: 2,
        life: 15,
        maxLife: 15,
        color: _color,
        type: "impact"
    });
}

// --- Functions ---
function generate_piece() {
    // Porting generation logic from game.js
    if (global.level >= 5 && random(1) < 0.10) {
        return { type: "dead", color: c_dkgray, dir: 0, id: 999 };
    }
    if (random(1) < 0.02 + (global.level * 0.005)) {
        return { type: "bomb", color: c_black, dir: 0, id: 888 };
    }
    if (global.level >= 1 && random(1) < 0.015 + (global.level * 0.0025)) {
        return { type: "drill", color: c_silver, dir: 0, id: 777 };
    }
    if (random(1) < 0.15) {
        var _colorId = global.activeColors[irandom(array_length(global.activeColors) - 1)];
        var _dir = (random(1) > 0.5 ? 1 : 0);
        return { type: "metal", color: get_color_from_id(_colorId), dir: _dir, id: _colorId };
    }
    
    var _colorId = global.activeColors[irandom(array_length(global.activeColors) - 1)];
    return { type: "normal", color: get_color_from_id(_colorId), dir: 0, id: _colorId };
}

function get_color_from_id(_id) {
    switch(_id) {
        case 1: return make_color_rgb(255, 107, 107); // Pink
        case 2: return make_color_rgb(255, 146, 43);  // Orange
        case 3: return make_color_rgb(252, 196, 25);  // Yellow
        case 4: return make_color_rgb(177, 151, 252); // Purple
        case 5: return make_color_rgb(102, 217, 232); // Cyan
        case 6: return make_color_rgb(77, 171, 247);  // Blue
        default: return c_white;
    }
}

function spawn_piece() {
    var _p = array_shift(global.nextQueue);
    array_push(global.nextQueue, generate_piece());
    
    var _spawnX = floor(global.COLS / 2); 
    
    // Create actual block instance
    var _inst = instance_create_layer(_spawnX, 0, "Instances", obj_block);
    _inst.type = _p.type;
    _inst.color = _p.color;
    _inst.dir = _p.dir;
    _inst.color_id = _p.id;
    _inst.grid_x = _spawnX;
    _inst.grid_y = 0;
    
    with(_inst) update_sprite();
    
    global.activePiece = _inst;
    global.canHold = true;
}

hold_piece = function() {
    if (!global.canHold || global.locking) return;
    
    if (global.holdPiece == undefined) {
        // First time holding
        global.holdPiece = {
            type: global.activePiece.type,
            color: global.activePiece.color,
            dir: global.activePiece.dir,
            id: global.activePiece.color_id
        };
        instance_destroy(global.activePiece);
        spawn_piece();
    } else {
        // Swap
        var _temp = {
            type: global.activePiece.type,
            color: global.activePiece.color,
            dir: global.activePiece.dir,
            id: global.activePiece.color_id
        };
        
        // Replace active with hold
        var _p = global.holdPiece;
        var _spawnX = floor(global.COLS / 2);
        
        instance_destroy(global.activePiece);
        
        var _inst = instance_create_layer(_spawnX, 0, "Instances", obj_block);
        _inst.type = _p.type;
        _inst.color = _p.color;
        _inst.dir = _p.dir;
        _inst.color_id = _p.id;
        _inst.grid_x = _spawnX;
        _inst.grid_y = 0;
        with(_inst) update_sprite();
        
        global.activePiece = _inst;
        global.holdPiece = _temp;
    }
    
    global.canHold = false;
}

start_game = function() {
    global.gameState = "PLAYING";
    global.score = 0;
    global.level = 1;
    global.levelScore = 0;
    global.scoreToNext = 1500;
    global.runShards = 0;
    global.jackpotMeter = 0;
    global.feverTimer = 0;
    global.comboChain = 0;
    global.bestCombo = 0;
    global.payoutFlash = 0;
    global.gameOver = false;
    
    // Clear grid
    for (var _y = 0; _y < global.TOTAL_ROWS; _y++) {
        for (var _x = 0; _x < global.COLS; _x++) {
            if (global.grid[_y][_x] != undefined) {
                instance_destroy(global.grid[_y][_x].inst);
                global.grid[_y][_x] = undefined;
            }
        }
    }
    
    global.nextQueue = [];
    for (var i = 0; i < 3; i++) array_push(global.nextQueue, generate_piece());
    spawn_piece();
}

award_shards = function(_points, _clearCount) {
    var _feverMult = (global.feverTimer > 0) ? 2 : 1;
    var _amount = max(1, floor((_points / 500) + (_clearCount / 4))) * _feverMult;
    global.runShards += _amount;
    global.coreShards += _amount;
    global.ui_scales.shards = 1.3;
    create_floating_text_ext(global.GAME_W * 0.5, global.GAME_H * 0.32, "+" + string(_amount) + " SHARDS", global.COLOR_GLOW, 1.35);
}

charge_jackpot = function(_clearCount) {
    global.jackpotMeter = min(global.jackpotMax, global.jackpotMeter + (_clearCount * 7) + (global.comboChain * 12));
    
    if (global.jackpotMeter >= global.jackpotMax) {
        global.jackpotMeter = 0;
        global.feverTimer = 60 * 12;
        global.payoutFlash = 45;
        global.shakeAmount = 10;
        create_floating_text_ext(global.GAME_W * 0.5, global.GAME_H * 0.24, "FEVER JACKPOT!", c_yellow, 2.2);
    }
}

update_level_progress = function() {
    while (global.levelScore >= global.scoreToNext) {
        global.levelScore -= global.scoreToNext;
        global.level++;
        global.scoreToNext = floor(global.scoreToNext * 1.45);
        global.payoutFlash = 35;
        create_floating_text_ext(global.GAME_W * 0.5, global.GAME_H * 0.30, "LEVEL " + string(global.level), global.COLOR_GLOW, 1.8);
    }
}

if (room == room_game) {
    start_game();
}

// Menu flow now lives in room_menu / obj_menu_controller.

// --- Helper Functions ---
move_piece = function(_dx, _dy) {
    if (global.activePiece == undefined) return;
    
    if (!check_collision(_dx, _dy)) {
        global.activePiece.grid_x += _dx;
        global.activePiece.grid_y += _dy;
        // Stretch on move
        global.activePiece.scale_x = 0.8;
        global.activePiece.scale_y = 1.2;
    } else if (_dy > 0) {
        lock_piece();
    }
}

check_collision = function(_dx, _dy) {
    var _nx = global.activePiece.grid_x + _dx;
    var _ny = global.activePiece.grid_y + _dy;
    
    if (_nx < 0 || _nx >= global.COLS || _ny >= global.TOTAL_ROWS) return true;
    if (global.grid[_ny][_nx] != undefined) return true;
    
    return false;
}

hard_drop = function() {
    var _startY = global.activePiece.grid_y;
    while (!check_collision(0, 1)) {
        global.activePiece.grid_y += 1;
    }
    var _endY = global.activePiece.grid_y;
    
    // Create Hard Drop Trail
    if (_endY > _startY) {
        create_beam(global.activePiece.grid_x * 16, (_startY - global.HIDDEN_ROWS) * 16, 16, (_endY - _startY) * 16, global.activePiece.color);
    }
    
    lock_piece();
}

rotate_piece = function() {
    if (global.activePiece.type == "metal") {
        global.activePiece.dir = (global.activePiece.dir == 0 ? 1 : 0);
    }
}

lock_piece = function() {
    global.locking = true;
    var _p = global.activePiece;
    var _px = _p.grid_x;
    var _py = _p.grid_y;
    
    // --- Special Ability: Drill ---
    if (_p.type == "drill") {
        var _bx_calc = (global.GAME_W - (global.COLS * 16 * global.PIXEL_SCALE)) / 2;
        var _by_calc = (global.GAME_H - (global.ROWS * 16 * global.PIXEL_SCALE)) / 2;
        var _tx = _bx_calc + (_px * 16 * global.PIXEL_SCALE) + (8 * global.PIXEL_SCALE);
        var _ty = _by_calc + ((_py - global.HIDDEN_ROWS) * 16 * global.PIXEL_SCALE);
        
        create_floating_text_ext(_tx, _ty, "DRILL PAYOUT", c_white, 1.6);
        if (global.settings.shakeEnabled) global.shakeAmount = 5;
        var _drilled = 0;
        for (var i = 0; i < global.TOTAL_ROWS; i++) {
            var _cell = global.grid[i][_px];
            if (_cell != undefined) {
                create_particles(_px * 16 + 8, i * 16 + 8, c_white);
                _cell.inst.clearing = true; // Use animation
                global.grid[i][_px] = undefined;
                _drilled++;
            }
        }
        
        // Visual Beam
        create_beam(_px * 16, 0, 16, global.TOTAL_ROWS * 16, c_white);
        
        if (_drilled > 0) {
            var _drillPoints = _drilled * 150 * ((global.feverTimer > 0) ? 2 : 1);
            global.score += _drillPoints;
            global.levelScore += _drillPoints;
            global.ui_scales.score = 1.3;
            award_shards(_drillPoints, _drilled);
            charge_jackpot(_drilled + 2);
            update_level_progress();
        }
        instance_destroy(_p);
        global.activePiece = undefined;
        apply_grid_gravity();
        alarm[0] = 10;
        return;
    }
    
    // --- Special Ability: Bomb ---
    if (_p.type == "bomb") {
        var _bx_calc = (global.GAME_W - (global.COLS * 16 * global.PIXEL_SCALE)) / 2;
        var _by_calc = (global.GAME_H - (global.ROWS * 16 * global.PIXEL_SCALE)) / 2;
        var _tx = _bx_calc + (_px * 16 * global.PIXEL_SCALE) + (8 * global.PIXEL_SCALE);
        var _ty = _by_calc + ((_py - global.HIDDEN_ROWS) * 16 * global.PIXEL_SCALE);
        
        create_floating_text(_tx, _ty, "BOOM!");
        if (global.settings.shakeEnabled) global.shakeAmount = 8;
        for (var _dy = -1; _dy <= 1; _dy++) {
            for (var _dx = -1; _dx <= 1; _dx++) {
                var _nx = _px + _dx;
                var _ny = _py + _dy;
                if (_nx >= 0 && _nx < global.COLS && _ny >= 0 && _ny < global.TOTAL_ROWS) {
                    var _cell = global.grid[_ny][_nx];
                    if (_cell != undefined) {
                        create_particles(_nx * 16 + 8, _ny * 16 + 8, c_orange);
                        _cell.inst.clearing = true; // Use animation
                        global.grid[_ny][_nx] = undefined;
                    }
                }
            }
        }
        instance_destroy(_p);
        global.activePiece = undefined;
        apply_grid_gravity();
        alarm[0] = 10;
        return;
    }

    // Squash on land
    _p.scale_x = 1.4;
    _p.scale_y = 0.7;
    
    // Impact Line Effect
    create_impact(0, (_py - global.HIDDEN_ROWS + 1) * 16, global.COLS * 16, _p.color);
    
    global.grid[_py][_px] = {
        type: _p.type,
        color: _p.color,
        dir: _p.dir,
        id: _p.color_id,
        inst: _p
    };
    
    global.activePiece = undefined;
    
    // Check for matches and settle
    if (global.settings.shakeEnabled) global.shakeAmount = 2;
    settle_matches();
}

settle_matches = function() {
    var _matches = find_matches_in_grid(global.grid, {cols: global.COLS}, global.TOTAL_ROWS);
    
    if (array_length(_matches) > 0) {
        global.comboChain++;
        global.bestCombo = max(global.bestCombo, global.comboChain);
        var _feverMult = (global.feverTimer > 0) ? 2 : 1;
        var _points = array_length(_matches) * 100 * global.comboChain * _feverMult;
        global.score += _points;
        global.levelScore += _points;
        global.ui_scales.score = 1.25;
        global.ui_scales.combo = 1.4;
        update_level_progress();
        
        var _bx_calc = (global.GAME_W - (global.COLS * 16 * global.PIXEL_SCALE)) / 2;
        var _by_calc = (global.GAME_H - (global.ROWS * 16 * global.PIXEL_SCALE)) / 2;
        var _first = _matches[0];
        var _tx = _bx_calc + (_first.x * 16 * global.PIXEL_SCALE) + (8 * global.PIXEL_SCALE);
        var _ty = _by_calc + ((_first.y - global.HIDDEN_ROWS) * 16 * global.PIXEL_SCALE);

        create_floating_text_ext(_tx, _ty, "+" + string(_points), c_yellow, 1.25 + (global.comboChain * 0.15));
        if (global.comboChain > 1) {
            create_floating_text_ext(global.GAME_W * 0.5, global.GAME_H * 0.45, "COMBO x" + string(global.comboChain), global.COLOR_GLOW, 1.5);
        }
        award_shards(_points, array_length(_matches));
        charge_jackpot(array_length(_matches));
        
        for (var i = 0; i < array_length(_matches); i++) {
            var _m = _matches[i];
            var _cell = global.grid[_m.y][_m.x];
            if (_cell != undefined) {
                create_particles(_m.x * 16 + 8, _m.y * 16 + 8, _cell.color);
                _cell.inst.clearing = true; // Use animation
                global.grid[_m.y][_m.x] = undefined;
            }
        }
        
        // Apply Gravity to grid
        apply_grid_gravity();
        
        // Recurse after a delay
        alarm[0] = 15; // Settle delay
    } else {
        global.locking = false;
        global.comboChain = 0;
        if (check_game_over()) {
            global.gameState = "GAMEOVER";
        } else {
            spawn_piece();
        }
    }
}

apply_grid_gravity = function() {
    for (var _x = 0; _x < global.COLS; _x++) {
        for (var _y = global.TOTAL_ROWS - 1; _y >= 0; _y--) {
            if (global.grid[_y][_x] == undefined) {
                for (var _yy = _y - 1; _yy >= 0; _yy--) {
                    if (global.grid[_yy][_x] != undefined) {
                        global.grid[_y][_x] = global.grid[_yy][_x];
                        global.grid[_yy][_x] = undefined;
                        
                        // Update instance position
                        var _inst = global.grid[_y][_x].inst;
                        _inst.grid_y = _y;
                        break;
                    }
                }
            }
        }
    }
}

check_game_over = function() {
    // Check if any block is in the hidden rows (death zone)
    for (var _y = 0; _y < global.HIDDEN_ROWS; _y++) {
        for (var _x = 0; _x < global.COLS; _x++) {
            if (global.grid[_y][_x] != undefined) return true;
        }
    }
    return false;
}
