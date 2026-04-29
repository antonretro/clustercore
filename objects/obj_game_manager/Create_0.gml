// --- Project Settings ---
// --- Game State ---
if (!variable_global_exists("gameMode")) global.gameMode = "PLANET"; 
global.gameState = "PLAYING"; // Set to PLAYING when the manager is created in the game room

// --- Dynamic Grid Settings ---
if (global.gameMode == "PLANET" || global.gameMode == "STORY") {
    global.COLS = 7;
    global.ROWS = 7;
} else {
    global.COLS = 5;
    global.ROWS = 9;
}

global.HIDDEN_ROWS = 2;
global.TOTAL_ROWS = global.ROWS + global.HIDDEN_ROWS;
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
global.orbitalX = floor(global.COLS / 2);
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
    global.grid[i] = array_create(global.COLS, undefined);
}

global.activePiece = undefined;
global.locking = false;
global.hitstop = 0;
global.jackpotFlash = 0;
global.dasTimer = 0;
global.dasRepeatTimer = 0;
global.gp_prev_stick_x = 0;
global.gp_prev_stick_y = 0;

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

    // Brute force cleanup of all blocks
    with(obj_block) instance_destroy();
    for (var _y = 0; _y < global.TOTAL_ROWS; _y++) {
        for (var _x = 0; _x < global.COLS; _x++) {
            global.grid[_y][_x] = undefined;
        }
    }
    
    global.nextQueue = [];
    for (var i = 0; i < 3; i++) {
        array_push(global.nextQueue, generate_piece());
    }
    
    spawn_piece();
    
    // --- PLANET CORE INITIALIZATION ---
    // Core is no longer spawned automatically. The first block to land in the center becomes the core.
};

start_game();
