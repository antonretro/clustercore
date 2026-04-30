// --- SFX Stubs ---
// Uncomment sfx_play() lines once sound assets are added to the project.
function juice_sfx_play_legacy(_snd) { if (audio_exists(_snd)) audio_play_sound(_snd, 0, false); }
function juice_sfx_piece_move_legacy()           { /* juice_sfx_play_legacy(snd_move);      */ }
function juice_sfx_piece_rotate_legacy()         { /* juice_sfx_play_legacy(snd_rotate);    */ }
function juice_sfx_piece_lock_legacy()           { /* juice_sfx_play_legacy(snd_lock);      */ }
function juice_sfx_hard_drop_legacy()            { /* juice_sfx_play_legacy(snd_hard_drop); */ }
function juice_sfx_bomb_legacy()                 { /* juice_sfx_play_legacy(snd_bomb);      */ }
function juice_sfx_drill_legacy()                { /* juice_sfx_play_legacy(snd_drill);     */ }
function juice_sfx_fever_legacy()                { /* juice_sfx_play_legacy(snd_fever);     */ }
function juice_sfx_level_up_legacy()             { /* juice_sfx_play_legacy(snd_level_up);  */ }
function juice_sfx_game_over_legacy()            { /* juice_sfx_play_legacy(snd_game_over); */ }
function juice_sfx_piece_blocked_legacy()        { /* juice_sfx_play_legacy(snd_blocked);   */ }
function juice_sfx_clear_legacy(_count, _chain) {
    // var _snd = snd_clear_1;
    // if (_chain >= 2) _snd = snd_clear_2;
    // if (_chain >= 4) _snd = snd_clear_3;
    // if (_chain >= 7) _snd = snd_clear_4;
    // sfx_play(_snd);
}

function save_high_score() {
    ini_open("cluster_core.ini");
    ini_write_real("save", "high_score", global.highScore);
    ini_close();
}

function create_trail_particles(_x, _y, _color) {
    for (var i = 0; i < 3; i++) {
        array_push(global.particles, {
            x: _x, y: _y,
            vx: random_range(-1.5, 1.5),
            vy: random_range(-1, 1),
            life: 12,
            color: _color
        });
    }
}

function create_particles(_x, _y, _color) {
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

function create_floating_text(_x, _y, _text) {
    array_push(global.floatingTexts, {
        x: _x, y: _y,
        text: _text,
        life: 60,
        vy: -0.5,
        color: c_white,
        scale: 1
    });
}

function create_floating_text_ext(_x, _y, _text, _color, _scale) {
    array_push(global.floatingTexts, {
        x: _x, y: _y,
        text: _text,
        life: 70,
        vy: -0.75,
        color: _color,
        scale: _scale
    });
}

function create_beam(_x, _y, _w, _h, _color) {
    array_push(global.beams, {
        x: _x, y: _y,
        w: _w, h: _h,
        life: 20,
        maxLife: 20,
        color: _color,
        type: "beam"
    });
}

function create_impact(_x, _y, _w, _color) {
    array_push(global.beams, {
        x: _x, y: _y,
        w: _w, h: 2,
        life: 15,
        maxLife: 15,
        color: _color,
        type: "impact"
    });
}

function award_shards(_points, _count) {
    var _shardGain = floor(_count * 0.5) + (global.feverTimer > 0 ? 2 : 0);
    global.runShards += _shardGain;
    global.ui_scales.shards = 1.3;
}

function charge_jackpot(_amount) {
    global.jackpotMeter += _amount;
    if (global.jackpotMeter >= global.jackpotMax) {
        global.jackpotMeter = 0;
        global.feverTimer = 600;
        global.hitstop = 8;
        global.jackpotFlash = 45;
        if (global.settings.shakeEnabled) global.shakeAmount = 10;

        // Rainbow explosion across every grid cell
        for (var _py = global.HIDDEN_ROWS; _py < global.TOTAL_ROWS; _py++) {
            for (var _px = 0; _px < global.COLS; _px++) {
                var _hue = irandom(255);
                create_particles(_px * 16 + 8, (_py - global.HIDDEN_ROWS) * 16 + 8, make_color_hsv(_hue, 220, 255));
            }
        }

        create_floating_text_ext(global.GAME_W * 0.5, global.GAME_H * 0.4, "FEVER MODE!", c_yellow, 2);
        sfx_fever();
        steam_ach_unlock("ACH_FEVER");
    }
}

function update_level_progress() {
    if (global.levelScore >= global.scoreToNext) {
        global.level++;
        global.levelScore -= global.scoreToNext;
        global.scoreToNext = floor(global.scoreToNext * 1.5);
        global.ui_scales.level = 1.5;
        sfx_level_up();
        create_floating_text_ext(global.GAME_W * 0.5, global.GAME_H * 0.3, "LEVEL UP!", global.COLOR_ACCENT, 2);
        
        // Add a new color to active pool every 3 levels
        if (global.level % 3 == 0 && array_length(global.reserveColors) > 0) {
            array_push(global.activeColors, array_shift(global.reserveColors));
        }
    }
}

// =============================================================================
// Steam Achievements Helper
// =============================================================================

function steam_ach_catalog() {
    // Keep API names exactly matched to Steamworks "API Name" fields.
    return [
        { id: "ACH_FIRST_DROP",      name: "First Drop",        desc: "Place your first block." },
        { id: "ACH_CORE_BREAKER",    name: "Core Breaker",      desc: "Clear your first core." },
        { id: "ACH_CHAIN_3",         name: "Chain Reaction",    desc: "Reach a 3x combo chain." },
        { id: "ACH_FEVER",           name: "Overclocked",       desc: "Enter FEVER mode." },
        { id: "ACH_STORY_WORLD_1",   name: "Tin Moon Cleared",  desc: "Complete the first world." },
        { id: "ACH_SCORE_100K",      name: "Six Figures",       desc: "Reach 100,000 score in one run." }
    ];
}

function steam_ach_is_ready() {
    if (!variable_global_exists("useSteam") || !global.useSteam) return false;
    if (!steam_initialised()) return false;
    return steam_stats_ready();
}

function steam_ach_init() {
    global.steam_ach_queue = [];
    global.steam_ach_cache = {};
    global.steam_ach_warned_unavailable = false;

    var _cat = steam_ach_catalog();
    for (var i = 0; i < array_length(_cat); i++) {
        var _id = _cat[i].id;
        global.steam_ach_cache[$ _id] = false;
        if (steam_ach_is_ready()) {
            global.steam_ach_cache[$ _id] = steam_get_achievement(_id);
        }
    }

    if (steam_ach_is_ready() || (variable_global_exists("useSteam") && global.useSteam)) {
        steam_request_stats();
    }
}

function steam_ach_unlock(_id) {
    // Safe no-op if Steam API is unavailable in this build.
    if (!variable_global_exists("useSteam") || !global.useSteam) return;
    if (!variable_global_exists("steam_ach_queue")) global.steam_ach_queue = [];
    array_push(global.steam_ach_queue, _id);
}

function steam_ach_update() {
    if (!variable_global_exists("steam_ach_queue")) global.steam_ach_queue = [];
    if (!variable_global_exists("steam_ach_cache")) global.steam_ach_cache = {};
    if (!steam_ach_is_ready()) {
        if (!global.steam_ach_warned_unavailable) {
            show_debug_message("[STEAM] Achievements unavailable (Steam not ready yet).");
            global.steam_ach_warned_unavailable = true;
        }
        return;
    }
    while (array_length(global.steam_ach_queue) > 0) {
        var _id = global.steam_ach_queue[0];
        array_delete(global.steam_ach_queue, 0, 1);

        var _already = false;
        if (variable_struct_exists(global.steam_ach_cache, _id)) _already = global.steam_ach_cache[$ _id];
        else _already = steam_get_achievement(_id);

        if (_already) continue;
        steam_set_achievement(_id);
        global.steam_ach_cache[$ _id] = true;
    }

    steam_store_stats();
}
