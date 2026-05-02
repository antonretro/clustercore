// --- Project Settings ---
if (instance_number(obj_game_manager) > 1) {
    instance_destroy();
    exit;
}

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
global.orbitalX = floor((global.COLS - 1) / 2);
global.previewDepth = 1; // Targeting depth for the preview
global.pieceTimer = 300;
global.MAX_PIECE_TIME = 300;
global.launchCharge = 0;
global.MAX_CHARGE = 40; // ~0.6 seconds to full charge
global.comboChain = 0;
global.bestCombo = 0;
global.runShards = 0;
// Combo celebration state
combo_pop_t     = 0;   // 0→1 burst scale when label first appears
combo_pop_label = "";  // last shown label — change triggers pop

wallet_load();

// --- Story Mode Run State ---
if (!variable_global_exists("storyPlanet")) global.storyPlanet = 0;
if (!variable_global_exists("storyLevel")) global.storyLevel = 0;
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
global.storyLevelDef = undefined;
global.storyLevelSeed = 0;
global.storyObjectiveType = "clear_cores";
global.storyObjectiveValue = 0;
global.storyWavesSurvived = 0;
global.storyShardsCollected = 0;
global.storyFeverTriggered = false;
global.storyMegaClears = 0;
global.resultWin = false;
global.resultTitle = "";
global.resultSubtitle = "";
global.resultRewardShards = 0;
global.resultRewardGems = 0;
global.resultCanNext = false;
if (!variable_global_exists("sunGateKeys")) global.sunGateKeys = 0;

// --- Bonus Dwarf Planet State ---
if (!variable_global_exists("bonusPlanet")) global.bonusPlanet = 0;
global.bonusPlanets = [
    { name: "GLASS DWARF",   goal: 9000,  time: room_speed * 90,  shard_rate: 0.20, reward_shards: 18 },
    { name: "EMBER DWARF",   goal: 14000, time: room_speed * 100, shard_rate: 0.24, reward_shards: 26 },
    { name: "COBALT DWARF",  goal: 19000, time: room_speed * 110, shard_rate: 0.28, reward_shards: 34 },
    { name: "VIOLET DWARF",  goal: 26000, time: room_speed * 120, shard_rate: 0.32, reward_shards: 48 }
];
global.bonusName = "";
global.bonusScoreGoal = 0;
global.bonusTimer = 0;
global.bonusRewardShards = 0;
global.bonusComplete = false;

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
global.planetSurfaceDist = 1; // Performance cache: closest block distance to center
global.planetOuterRadius = 1; // Adaptive lane cache: farthest occupied distance from center
global.locking = false;
global.hitstop = 0;
global.jackpotFlash = 0;
global.shipRecoil = 0;
global.dasTimer = 0;
global.dasRepeatTimer = 0;
global.softDropDasTimer = 0;
global.softDropRepeatTimer = 0;
global.gp_prev_stick_x = 0;
global.gp_prev_stick_y = 0;
global.stagingRingCells = [];
global.previewData = undefined;
global.coreStabilityMax = 100;
global.coreStability = global.coreStabilityMax;
global.coreStabilityDrainBase = 0.15;
global.flashAlpha = 0;
global.restoredMap = []; // 11x11 grid of biome tile data
global.restoredTilesAlpha = 0;

// Initialize empty map
for (var _y = 0; _y < global.TOTAL_ROWS; _y++) {
    global.restoredMap[_y] = array_create(global.TOTAL_COLS, 0);
}
global.coreStabilityRecoverRate = 0.25;
global.coreUnstable = false;
global.coreRebuildTimer = 0;
global.coreRebuildColorIdx = 0;

// Load persisted high score
global.highScore = 0;
ini_open("cluster_core.ini");
global.highScore = ini_read_real("save", "high_score", 0);
ini_close();

global.turnCount = 0;
global.turnLimit = 0;
global.storyBonus = 0;
global.storyRank = "D";

// --- Visual FX Pools ---
global.particles = [];
global.floatingTexts = [];
global.flyingShards = [];
global.beams = [];
global.bg_stars = [];
global.shakeAmount = 0;
global.boardRotation = 0;
global.targetRotation = 0;

// Pre-fill Next Queue (Reduced to 1 for smarter AI response)
for (var i = 0; i < 1; i++) {
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
global.finishTimer = 0;

global.settings = {
    ghostEnabled: true,
    shakeEnabled: true,
    hintPulseEnabled: true
};

global.hint_cells = [];
global.hint_tick = 0;
global.hint_pulse_timer = 0;
global.hint_pulse_interval = room_speed * 3;

// Steam API is opt-in per build target. Keep false for local/non-Steam runs.
if (!variable_global_exists("useSteam")) global.useSteam = false;

steam_ach_init();
dialogue_init();

setup_story_planet = function() {
    var _last = array_length(global.storyPlanets) - 1;
    global.storyPlanet = clamp(global.storyPlanet, 0, _last);
    
    var _planet = global.storyPlanets[global.storyPlanet];
    global.storyName = _planet.name;
    global.storyTarget = _planet.target;
    global.storyCleared = 0;
    var _lvIdx = clamp(global.storyLevel, 0, 5);
    global.level = _planet.level + floor(_lvIdx * 0.35);
    global.storyTarget += _lvIdx * 4;
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

// --- Global drawing helpers are now in scr_draw_logic.gml ---

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
    global.turnCount = 0;
    global.hitstop = 0;
    global.previewDepth = 1;
    global.coresCleared = 0;
    global.storyWavesSurvived = 0;
    global.storyShardsCollected = 0;
    global.storyFeverTriggered = false;
    global.storyMegaClears = 0;
    global.storyComplete = false;
    global.bonusComplete = false;
    
    // Normalize board rotation and orbital side to stop unspinning from the previous level
    global.boardRotation = 0;
    global.targetRotation = 0;
    global.orbitalSide = 0;

    if (global.gameMode == "STORY") {
        setup_story_planet();
    }
    if (global.gameMode == "BONUS") {
        var _bidx = clamp(global.bonusPlanet, 0, array_length(global.bonusPlanets) - 1);
        var _bonus = global.bonusPlanets[_bidx];
        global.bonusName = _bonus.name;
        global.bonusScoreGoal = _bonus.goal;
        global.bonusTimer = _bonus.time;
        global.bonusRewardShards = _bonus.reward_shards;
        global.level = 2 + _bidx;
        global.scoreToNext = 999999;
        global.activeColors = [1, 2, 3, 4];
        if (_bidx >= 2) array_push(global.activeColors, 5);
        global.reserveColors = [6];
    }

    // Clear all visual FX from the previous run
    global.particles     = [];
    global.floatingTexts = [];
    global.flyingShards  = [];
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

    var _storyLayoutApplied = false;
    var _queueSeed = 1357911 + (global.level * 101);
    if (global.gameMode == "STORY") {
        var _lvDef = story_get_level_def(global.storyPlanet, global.storyLevel);
        _storyLayoutApplied = story_apply_level_layout(_lvDef);
        if (_storyLayoutApplied) _queueSeed = global.storyLevelSeed + 424242;
    }

    piece_rng_seed(_queueSeed);

    // Build queue after story seed/palette apply so first pieces match level palette.
    for (var i = 0; i < 1; i++) {
        array_push(global.nextQueue, generate_piece());
    }

    // --- PLANET CORE: pre-place at center so the board has an anchor from turn 1 ---
    if ((global.gameMode == "PLANET" || global.gameMode == "STORY") && !_storyLayoutApplied) {
        var _cx = floor(global.TOTAL_COLS / 2);
        var _cy = floor(global.TOTAL_ROWS / 2);
        var _coreId = global.activeColors[irandom(array_length(global.activeColors) - 1)];
        var _coreCol = get_color_from_id(_coreId);
        var _coreData = { type: "core", color: _coreCol, dir: 0, id: _coreId, core_arrow: false };
        var _coreInst = _place_block_instance(_cx, _cy, _coreData);
        global.grid[_cy][_cx] = { type: "core", color: _coreCol, dir: 0, id: _coreId, inst: _coreInst, core_arrow: false };

        // Seed 4 blocks around core (N/S = color1, E/W = color2) so the first match
        // opportunity appears within 2-3 turns — removes the dull empty-board opening.
        if (array_length(global.activeColors) >= 2) {
            var _c1   = global.activeColors[0];
            var _c2   = global.activeColors[1];
            var _col1 = get_color_from_id(_c1);
            var _col2 = get_color_from_id(_c2);
            var _seeds = [
                { dx:  0, dy: -1, cid: _c1, col: _col1 },
                { dx:  1, dy:  0, cid: _c2, col: _col2 },
                { dx:  0, dy:  1, cid: _c1, col: _col1 },
                { dx: -1, dy:  0, cid: _c2, col: _col2 },
            ];
            for (var _si = 0; _si < 4; _si++) {
                var _sx = _cx + _seeds[_si].dx;
                var _sy = _cy + _seeds[_si].dy;
                if (global.grid[_sy][_sx] == undefined) {
                    var _sd = { type: "normal", color: _seeds[_si].col, dir: 0, id: _seeds[_si].cid, core_arrow: false };
                    var _si2 = _place_block_instance(_sx, _sy, _sd);
                    global.grid[_sy][_sx] = { type: "normal", color: _seeds[_si].col,
                                              dir: 0, id: _seeds[_si].cid, inst: _si2, core_arrow: false };
                }
            }
        }
    }

    update_staging_ring_cache();
    spawn_piece();
    recalculate_planet_surface(); // Cache the initial surface depth
    global.previewData    = undefined; // force recalc on first frame
    global.tutorialTimer  = 600;       // show controls hint for 10 seconds
    global.inputDelayTimer = 10;
    global.hint_cells = [];
    global.hint_tick = 0;
    global.hint_pulse_timer = 0;
    global.softDropDasTimer = 0;
    global.softDropRepeatTimer = 0;
    global.coreStability = global.coreStabilityMax;
    global.coreUnstable = false;
    global.MAX_PIECE_TIME = 300 + global.shopTimerBonus * 30;
    global.pieceTimer = global.MAX_PIECE_TIME;
    
    // Reset Restoration State
    global.restoredTilesAlpha = 0;
    global.boardRotation = 0;
    global.shakeAmount = 0;
    for (var _ry3 = 0; _ry3 < global.TOTAL_ROWS; _ry3++) {
        global.restoredMap[_ry3] = array_create(global.TOTAL_COLS, 0);
    }

    story_try_start_level_dialogue();
};

start_game();
