// --- Project Settings ---
global.COLS = 5;
global.ROWS = 9;
global.HIDDEN_ROWS = 2;
global.TOTAL_ROWS = global.ROWS + global.HIDDEN_ROWS;
global.PIXEL_SCALE = 5;
global.GAME_W = 1920;
global.GAME_H = 1080;
global.game_surface = -1;
display_set_gui_size(global.GAME_W, global.GAME_H);

// Crisp Pixel Rendering
gpu_set_texfilter(false);

// --- Game State ---
global.gameState = "PLAYING"; // PLAYING, PAUSED, GAMEOVER
global.score = 0;
global.level = 1;
global.levelScore = 0;
global.scoreToNext = 1500;
global.comboChain = 0;
global.bestCombo = 0;
global.runShards = 0;

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

// --- Piece Pool ---
global.activeColors = [1, 2, 3]; 
global.reserveColors = [4, 5, 6];
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

    // Clear grid
    for (var _y = 0; _y < global.TOTAL_ROWS; _y++) {
        for (var _x = 0; _x < global.COLS; _x++) {
            if (global.grid[_y][_x] != undefined) {
                instance_destroy(global.grid[_y][_x].inst);
                global.grid[_y][_x] = undefined;
            }
        }
    }
    
    spawn_piece();
}

start_game();
