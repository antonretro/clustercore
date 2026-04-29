// --- Project Settings ---
// --- Game State ---
if (!variable_global_exists("gameMode")) global.gameMode = "PLANET"; 
global.gameState = "PLAYING"; // Set to PLAYING when the manager is created in the game room

// --- Dynamic Grid Settings ---
// --- Dynamic Grid Settings ---
if (global.gameMode == "PLANET" || global.gameMode == "STORY") {
    global.COLS = 9;   // Playable width
    global.ROWS = 9;   // Playable height
    global.HIDDEN_SIDES = 1; // Staging ring
} else {
    global.COLS = 5;   // Classic width
    global.ROWS = 10;  // Classic height
    global.HIDDEN_SIDES = 0;
}

global.HIDDEN_ROWS = 1; // Top staging area (1 row standard)
global.TOTAL_COLS = global.COLS + (global.HIDDEN_SIDES * 2);
global.TOTAL_ROWS = global.ROWS + global.HIDDEN_ROWS + global.HIDDEN_SIDES; 
// Planet: 9 + 2 = 11x11. Classic: 10 + 0 = 10; 10 + 1 = 11.
global.PIXEL_SCALE = 5;
global.GAME_W = 1920;
global.GAME_H = 1080;
global.game_surface = -1;
display_set_gui_size(global.GAME_W, global.GAME_H);

// Crisp Pixel Rendering
gpu_set_texfilter(false);

global.score = 0;
global.level = 1;
global.levelScore = 0;
global.scoreToNext = 1500;
global.orbitalSide = 0;
global.orbitalX = floor(global.TOTAL_COLS / 2);
global.previewDepth = 1; // Targeting depth for the preview
global.pieceTimer = 300;
global.MAX_PIECE_TIME = 300;
global.launchCharge = 0;
global.MAX_CHARGE = 40; // ~0.6 seconds to full charge
global.comboChain = 0;
global.bestCombo = 0;
global.runShards = 0;

// --- Story Mode Run State ---
if (!variable_global_exists("storyPlanet")) global.storyPlanet = 0;
global.storyPlanets = [
    { name: "TIN MOON",      target: 16, level: 1, colors: 3 },
    { name: "RUST GARDEN",   target: 24, level: 2, colors: 3 },
    { name: "CASINO COMET",  target: 32, level: 3, colors: 4 },
    { name: "DEAD ORBIT",    target: 42, level: 4, colors: 4 },
    { name: "CLUSTER CORE",  target: 55, level: 5, colors: 5 }
];
global.storyName = "";
global.storyTarget = 0;
global.storyCleared = 0;
global.storyComplete = false;

// Fever/Jackpot
global.jackpotMeter = 0;
global.jackpotMax = 50;
global.feverTimer = 0;

// --- Colors ---
global.COLOR_BG = make_color_rgb(10, 10, 15);
global.COLOR_BG2 = make_color_rgb(20, 20, 35);
global.COLOR_ACCENT = make_color_rgb(100, 150, 255);
global.COLOR_GLOW = make_color_rgb(255, 200, 100);
global.COLOR_DANGER = make_color_rgb(255, 50, 50);

global.bg_colors = [
    make_color_rgb(5, 5, 15),
    make_color_rgb(15, 10, 30),
    make_color_rgb(10, 5, 20)
];

// --- Piece Pool (Randomized on Start) ---
var _allColors = [1, 2, 3, 4, 5, 6];
// Simple shuffle
for (var i = array_length(_allColors) - 1; i > 0; i--) {
    var j = irandom(i);
    var _temp = _allColors[i];
    _allColors[i] = _allColors[j];
    _allColors[j] = _temp;
}

global.activeColors = [];
global.reserveColors = [];
for (var i = 0; i < 3; i++) array_push(global.activeColors, _allColors[i]);
for (var i = 3; i < 6; i++) array_push(global.reserveColors, _allColors[i]);

global.nextQueue = [];
global.holdPiece = undefined;
global.canHold = true;

// --- Board Management ---
global.grid = array_create(global.TOTAL_ROWS);
for (var i = 0; i < global.TOTAL_ROWS; i++) {
    global.grid[i] = array_create(global.TOTAL_COLS, undefined);
}

global.activePiece = undefined;
global.activePieceID = -1;
global.locking = false;
global.hitstop = 0;
global.jackpotFlash = 0;
global.dasTimer = 0;
global.dasRepeatTimer = 0;
global.gp_prev_stick_x = 0;
global.gp_prev_stick_y = 0;
global.stagingRingCells = [];
global.previewData = undefined;

// Load persisted high score
global.highScore = 0;
ini_open("cluster_core.ini");
global.highScore = ini_read_real("save", "high_score", 0);
ini_close();

// --- Visual FX Pools ---
global.particles = [];
global.floatingTexts = [];
global.beams = [];
global.bg_stars = [];
global.shakeAmount = 0;
global.boardRotation = 0;
global.targetRotation = 0;

// Pre-fill Next Queue
for (var i = 0; i < 3; i++) {
    array_push(global.nextQueue, generate_piece());
}

// Background Star Init
for (var i = 0; i < 60; i++) {
    array_push(global.bg_stars, {
        x: random(global.GAME_W),
        y: random(global.GAME_H),
        spd: random_range(0.5, 2),
        size: random_range(1, 3)
    });
}

// --- UI Feedback Scales ---
global.ui_scales = {
    score: 1,
    level: 1,
    combo: 1,
    shards: 1,
    next: 1
};

// --- Timers & UI State ---
global.dropTimer = 0;
global.DROP_INTERVAL_START = 60;
global.LEVEL_SPEED_SCALE = 2;
global.payoutFlash = 0;

global.settings = {
    ghostEnabled: true,
    shakeEnabled: true
};

setup_story_planet = function() {
    var _last = array_length(global.storyPlanets) - 1;
    global.storyPlanet = clamp(global.storyPlanet, 0, _last);
    
    var _planet = global.storyPlanets[global.storyPlanet];
    global.storyName = _planet.name;
    global.storyTarget = _planet.target;
    global.storyCleared = 0;
    global.level = _planet.level;
    global.scoreToNext = 1200 + (global.storyPlanet * 450);
    
    while (array_length(global.activeColors) > _planet.colors && array_length(global.activeColors) > 3) {
        var _lastColorIndex = array_length(global.activeColors) - 1;
        var _movedColor = global.activeColors[_lastColorIndex];
        array_delete(global.activeColors, _lastColorIndex, 1);
        array_push(global.reserveColors, _movedColor);
    }
    while (array_length(global.activeColors) < _planet.colors && array_length(global.reserveColors) > 0) {
        array_push(global.activeColors, array_shift(global.reserveColors));
    }
};

update_staging_ring_cache = function() {
    global.stagingRingCells = [];
    // Side 0: Top (y=0)
    for (var i = 1; i <= global.COLS; i++)  array_push(global.stagingRingCells, {sx: i, sy: 0});
    // Side 1: Right (x=10)
    for (var i = 1; i <= global.ROWS; i++)  array_push(global.stagingRingCells, {sx: global.TOTAL_COLS - 1, sy: i});
    // Side 2: Bottom (y=10)
    for (var i = global.COLS; i >= 1; i--)  array_push(global.stagingRingCells, {sx: i, sy: global.TOTAL_ROWS - 1});
    // Side 3: Left (x=0)
    for (var i = global.ROWS; i >= 1; i--)  array_push(global.stagingRingCells, {sx: 0, sy: i});
};

draw_block_instance = function(_inst, _bx, _by, _scale, _alpha = -1, _altX = -1, _altY = -1) {
    var _instAlpha = (_alpha == -1) ? _inst.image_alpha : _alpha;
    var _drawX = (_altX == -1) ? (_bx + _inst.x * _scale) : (_altX - 8 * _scale);
    var _drawY = (_altY == -1) ? (_by + _inst.y * _scale) : (_altY - 8 * _scale);
    var _cx = _drawX + 8 * _scale;
    var _cy = _drawY + 8 * _scale;
    var _renderRot = -global.boardRotation + _inst.visualRotation + _inst.rotation;
    
    if (_inst.sprite_index != -1) {
        draw_sprite_ext(_inst.sprite_index, _inst.image_index, _cx, _cy,
            _scale * _inst.scale_x, _scale * _inst.scale_y, _renderRot, c_white, _instAlpha);
    }
    if (_inst.type == "metal") {
        var _arSpr = (_inst.dir == 0) ? spr_lr_arrows : spr_ud_arrows;
        // Arrows rotate WITH board (relative 0)
        draw_sprite_ext(_arSpr, 0, _cx, _cy, _scale * _inst.scale_x, _scale * _inst.scale_y, 0, c_white, _instAlpha);
    }
    if (_inst.type == "core") {
        gpu_set_blendmode(bm_add);
        var _cp2 = 0.3 + abs(sin(current_time * 0.005)) * 0.4;
        draw_sprite_ext(_inst.sprite_index, _inst.image_index, _cx, _cy, _scale*_inst.scale_x*1.4, _scale*_inst.scale_y*1.4, _renderRot, c_white, _cp2 * 0.5 * _instAlpha);
        gpu_set_blendmode(bm_normal);
        draw_set_color(c_white); draw_set_alpha((_cp2 + 0.2) * _instAlpha);
        draw_rectangle(_cx - 9*_scale, _cy - 9*_scale, _cx + 9*_scale, _cy + 9*_scale, true);
        draw_rectangle(_cx - 10*_scale, _cy-10*_scale, _cx+10*_scale, _cy+10*_scale, true);
        draw_set_alpha(1.0);
    }
};

// --- Core Flow Functions ---
start_game = function() {
    global.gameState = "PLAYING";
    global.score = 0;
    global.level = 1;
    global.levelScore = 0;
    global.comboChain = 0;
    global.runShards = 0;
    global.jackpotMeter = 0;
    global.feverTimer = 0;
    global.hitstop = 0;
    global.previewDepth = 1;
    global.coresCleared = 0;
    global.storyComplete = false;

    if (global.gameMode == "STORY") {
        setup_story_planet();
    }

    // Clear all visual FX from the previous run
    global.particles     = [];
    global.floatingTexts = [];
    global.beams         = [];
    global.shakeAmount   = 0;

    // Brute force cleanup of all blocks
    with(obj_block) instance_destroy();
    for (var _y = 0; _y < global.TOTAL_ROWS; _y++) {
        for (var _x = 0; _x < global.TOTAL_COLS; _x++) {
            global.grid[_y][_x] = undefined;
        }
    }
    
    global.nextQueue = [];
    for (var i = 0; i < 3; i++) {
        array_push(global.nextQueue, generate_piece());
    }

    // --- PLANET CORE: pre-place at center so the board has an anchor from turn 1 ---
    if (global.gameMode == "PLANET" || global.gameMode == "STORY") {
        var _cx = floor(global.TOTAL_COLS / 2);
        var _cy = floor(global.TOTAL_ROWS / 2);
        var _coreData = { type: "core", color: c_white, dir: 0, id: 0 };
        var _coreInst = _place_block_instance(_cx, _cy, _coreData);
        global.grid[_cy][_cx] = { type: "core", color: c_white, dir: 0, id: 0, inst: _coreInst };
    }

    update_staging_ring_cache();
    spawn_piece();
    global.previewData    = undefined; // force recalc on first frame
    global.inputDelayTimer = 10; // ignore fire input for first 10 frames to absorb menu keypress
};

start_game();
