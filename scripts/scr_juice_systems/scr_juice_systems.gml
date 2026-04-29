// --- SFX Stubs ---
// Uncomment sfx_play() lines once sound assets are added to the project.
function sfx_play(_snd) { if (audio_exists(_snd)) audio_play_sound(_snd, 0, false); }
function sfx_piece_move()           { /* sfx_play(snd_move);      */ }
function sfx_piece_rotate()         { /* sfx_play(snd_rotate);    */ }
function sfx_piece_lock()           { /* sfx_play(snd_lock);      */ }
function sfx_hard_drop()            { /* sfx_play(snd_hard_drop); */ }
function sfx_bomb()                 { /* sfx_play(snd_bomb);      */ }
function sfx_drill()                { /* sfx_play(snd_drill);     */ }
function sfx_fever()                { /* sfx_play(snd_fever);     */ }
function sfx_level_up()             { /* sfx_play(snd_level_up);  */ }
function sfx_game_over()            { /* sfx_play(snd_game_over); */ }
function sfx_piece_blocked()        { /* sfx_play(snd_blocked);   */ }
function sfx_clear(_count, _chain) {
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
