// =============================================================================
// scr_cc_play - the play screen: aim, fire, animate phases, undo, win/fail,
// campaign levels and Endless mode.
// =============================================================================

function cc_play_start_level(_li) {
    var _lv = global.levels[_li];
    var _st = cc_state_from_level(_lv);
    cc_play_begin("campaign", _st);
    var _P = global.play;
    _P.li = _li;
    _P.lv = _lv;
    _P.sol = string_split(_lv.sol, " ", true);
    _P.tip_t = 0;
}

function cc_play_start_endless() {
    var _n = 9, _c = 4;
    var _st = cc_state_new(_n);
    var _cols = [0, 1, 2, 3, 4, 5];
    array_shuffle_ext(_cols);
    array_resize(_cols, 4);
    _st.seq = [_cols[irandom(3)]];
    cc_set(_st, _c, _c, cc_new_cell(_st, CC_CORE, 0, 0, 0));
    // starting blob: random blocks that settle without matching
    var _placed = 0, _guard = 0;
    while (_placed < 12 && _guard < 400) {
        _guard++;
        var _x = _c + irandom_range(-2, 2), _y = _c + irandom_range(-2, 2);
        if (cc_get(_st, _x, _y) != CC_EMPTY) continue;
        var _save = cc_state_copy(_st);
        cc_set(_st, _x, _y, cc_new_cell(_st, CC_NORMAL, _cols[irandom(3)], 0, 0));
        while (cc_gravity_sweep(_st)) {}
        if (array_length(cc_find_clears(_st)) > 0) { _st = _save; continue; }
        _placed++;
    }
    _st.queue = [];
    cc_play_begin("endless", _st);
    var _P = global.play;
    _P.endless = { score: 0, cores: 0, cols: _cols, shots: 0, best_chain: 0, show_score: 0 };
    _P.lv = { name: "ENDLESS ORBIT", world: 5, tip: "Break cores, survive. Every 3rd shot a meteor hits!", par: 0 };
    cc_endless_refill();
    _P.tip_t = 0;
}

function cc_play_begin(_mode, _st) {
    global.play = {
        mode: _mode, li: -1, lv: undefined, st: _st, start: cc_state_copy(_st), undo: [],
        side: 0, lane: _st.n div 2, ang: 0, ang_to: 0,
        phases: [], pi: 0, pt: 0, pdur: 1, prev: cc_snap(_st), disp_hp: _st.hp, anim_dir: [0, -1],
        land_id: -1, land_t: 99, busy: false,
        result: "", result_t: 0, stars: 0, sel: 0,
        preview: undefined, preview_key: "",
        moves: [], sol: [], hint: undefined, hint_t: 0,
        tip_t: 0, paused: false, pause_sel: 0, endless: undefined, t: 0,
        fails: 0
    };
    var _n = _st.n;
    global.view = { x: 600, y: 330, cs: (_n <= 7) ? 64 : 48, ang: 0, n: _n, sx: 0, sy: 0 };
}

function cc_endless_refill() {
    var _P = global.play, _E = _P.endless;
    while (array_length(_P.st.queue) < 4) {
        var _r = random(1);
        var _p = _E.cols[irandom(3)];
        if (_E.shots > 6) {
            if (_r < 0.04) _p = CC_BOMB;
            else if (_r < 0.07) _p = CC_DRILL;
            else if (_r < 0.10) _p = CC_PAINT;
        }
        array_push(_P.st.queue, _p);
    }
}

function cc_play_restart() {
    var _P = global.play;
    if (_P.mode == "endless") { cc_play_start_endless(); return; }
    array_push(_P.undo, cc_state_copy(_P.st));
    _P.st = cc_state_copy(_P.start);
    _P.moves = [];
    cc_play_after_change();
    cc_sfx("undo", 0.8);
}

function cc_play_undo() {
    var _P = global.play;
    if (array_length(_P.undo) == 0) { cc_sfx("blocked"); return; }
    _P.st = array_pop(_P.undo);
    if (array_length(_P.moves) > 0) array_pop(_P.moves);
    cc_play_after_change();
    cc_sfx("undo");
}

function cc_play_after_change() {
    var _P = global.play;
    _P.phases = []; _P.pi = 0; _P.busy = false;
    _P.prev = cc_snap(_P.st);
    _P.disp_hp = _P.st.hp;
    _P.result = "";
    _P.preview_key = "";
    _P.hint = undefined;
}


// ── step ─────────────────────────────────────────────────────────────────────
function cc_play_step() {
    var _P = global.play, _I = global.inp, _st = _P.st;
    _P.t++;
    _P.tip_t++;
    _P.land_t++;
    _P.hint_t++;

    // board turn tween
    _P.ang = lerp(_P.ang, _P.ang_to, 0.2);
    if (abs(_P.ang - _P.ang_to) < 0.05) _P.ang = _P.ang_to;
    global.view.ang = _P.ang;

    if (_P.paused) { cc_pause_step(); return; }
    if (_I.pause) { _P.paused = true; _P.pause_sel = 0; cc_sfx("select"); return; }

    // animation
    if (_P.busy) {
        if (global.fx.hitstop > 0) { global.fx.hitstop--; return; }
        var _fast = keyboard_check(vk_space) && _P.pi > 0;
        _P.pt += _fast ? 2 : 1;
        if (_P.pt >= _P.pdur) {
            cc_phase_end(_P.phases[_P.pi]);
            _P.pi++;
            if (_P.pi >= array_length(_P.phases)) {
                _P.busy = false;
                cc_play_settled();
            } else {
                cc_phase_begin(_P.phases[_P.pi]);
            }
        }
    }

    // result screens
    if (_P.result == "win" || _P.result == "over") { _P.result_t++; cc_result_step(); return; }

    // undo / restart work any time (even mid-animation)
    if (_I.undo && _P.mode == "campaign") { cc_play_undo(); return; }
    if (_I.restart) { cc_play_restart(); return; }
    if (keyboard_check_pressed(ord("H")) && _P.mode == "campaign") cc_play_hint();

    if (_P.busy) return;
    if (_P.result == "fail") _P.result_t++;

    var _n = _st.n;
    // aim: walk off the end of a side to swing the planet round
    if (_I.left) {
        if (_P.lane > 0) { _P.lane--; cc_sfx("tick"); }
        else { _P.side = (_P.side + 1) mod 4; _P.lane = _n - 1; _P.ang_to += 90; cc_sfx("turn"); }
    }
    if (_I.right) {
        if (_P.lane < _n - 1) { _P.lane++; cc_sfx("tick"); }
        else { _P.side = (_P.side + 3) mod 4; _P.lane = 0; _P.ang_to -= 90; cc_sfx("turn"); }
    }
    if (_I.rotl) { _P.side = (_P.side + 1) mod 4; _P.ang_to += 90; cc_sfx("turn"); }
    if (_I.rotr) { _P.side = (_P.side + 3) mod 4; _P.ang_to -= 90; cc_sfx("turn"); }

    if (_I.hold) {
        var _before = cc_state_copy(_st);
        if (cc_hold(_st)) {
            array_push(_P.undo, _before);
            array_push(_P.moves, "H");
            cc_sfx("hold");
            _P.preview_key = "";
            if (_P.result == "fail") _P.result = "";
        }
    }

    if (_I.fire) {
        if (abs(_P.ang - _P.ang_to) > 20) {
            // still turning: ignore so you never fire down the wrong lane
        } else if (cc_can_fire(_st, _P.side, _P.lane)) {
            cc_play_fire();
        } else {
            cc_sfx("blocked");
            cc_shake(3);
        }
    }
}

function cc_play_fire() {
    var _P = global.play, _st = _P.st;
    array_push(_P.undo, cc_state_copy(_st));
    if (array_length(_P.undo) > 200) array_delete(_P.undo, 0, 1);
    array_push(_P.moves, string(_P.side) + "," + string(_P.lane));
    _P.anim_dir = cc_side_dir(_P.side);

    var _phases = cc_fire(_st, _P.side, _P.lane);
    for (var _i = 0; _i < array_length(_phases); _i++) _phases[_i].dir = _P.anim_dir;

    if (_P.mode == "endless") {
        var _E = _P.endless;
        _E.shots++;
        cc_endless_after_shot(_phases);
        cc_endless_refill();
    }

    _P.phases = _phases;
    _P.pi = 0;
    _P.busy = true;
    _P.hint = undefined;
    _P.preview_key = "";
    cc_phase_begin(_phases[0]);
}

function cc_endless_after_shot(_phases) {
    var _P = global.play, _st = _P.st, _E = _P.endless;
    var _c = _st.n div 2;
    cc_endless_core_reborn(_phases);
    // every third shot a meteor slams in from a random side
    if (_E.shots mod 3 == 0) {
        var _tries = 0;
        while (_tries < 40) {
            _tries++;
            var _sd = irandom(3), _ln = irandom(_st.n - 1);
            array_insert(_st.queue, 0, _E.cols[irandom(3)]);
            if (!cc_can_fire(_st, _sd, _ln)) { array_delete(_st.queue, 0, 1); continue; }
            var _more = cc_fire(_st, _sd, _ln);
            _st.shots--;
            _more[0].meteor = true;
            var _d = cc_side_dir(_sd);
            for (var _i = 0; _i < array_length(_more); _i++) { _more[_i].dir = _d; array_push(_phases, _more[_i]); }
            cc_endless_core_reborn(_phases);
            break;
        }
    }
}

function cc_endless_core_reborn(_phases) {
    var _P = global.play, _st = _P.st, _E = _P.endless;
    if (!_st.won) return;
    var _c = _st.n div 2;
    _E.cores++;
    var _layers = 1 + min(3, _E.cores div 3);
    _E.score += 300 * array_length(_st.seq);
    var _seq = [];
    repeat (_layers) array_push(_seq, _E.cols[irandom(3)]);
    _st.seq = _seq;
    _st.hp = 0;
    _st.won = false;
    cc_set(_st, _c, _c, cc_new_cell(_st, CC_CORE, 0, 0, 0));
    array_push(_phases, { kind: "reborn", g: cc_snap(_st), color: _seq[0] });
}

function cc_endless_lost() {
    var _st = global.play.st, _n = _st.n, _c = _n div 2;
    for (var _y = 0; _y < _n; _y++) for (var _x = 0; _x < _n; _x++) {
        if (max(abs(_x - _c), abs(_y - _c)) < _c) continue;
        var _v = cc_get(_st, _x, _y);
        if (_v != CC_EMPTY && cc_t(_v) != CC_WALL) return true;
    }
    return false;
}

// called when every phase of a shot has played
function cc_play_settled() {
    var _P = global.play, _st = _P.st;
    _P.disp_hp = _st.hp;
    if (_P.mode == "endless") {
        if (cc_endless_lost()) {
            _P.result = "over"; _P.result_t = 0; _P.sel = 0;
            var _E = _P.endless;
            if (_E.score > global.save.endless_best) { global.save.endless_best = _E.score; cc_save_write(); _E.new_best = true; }
            cc_sfx("fail"); cc_shake(12);
        }
        return;
    }
    if (_st.won) {
        _P.result = "win"; _P.result_t = 0; _P.sel = 0;
        _P.stars = cc_stars_for(_P.lv, _st.shots);
        if (_P.stars > global.save.stars[_P.li]) { global.save.stars[_P.li] = _P.stars; cc_save_write(); }
        return;
    }
    if (array_length(_st.queue) == 0 && _st.hold < 0) {
        _P.result = "fail"; _P.result_t = 0; _P.fails++;
        cc_sfx("fail");
    }
}

function cc_play_hint() {
    var _P = global.play;
    var _ok = array_length(_P.moves) <= array_length(_P.sol);
    for (var _i = 0; _ok && _i < array_length(_P.moves); _i++) if (_P.moves[_i] != _P.sol[_i]) _ok = false;
    _P.hint_t = 0;
    if (!_ok) { _P.hint = { kind: "off" }; return; }
    if (array_length(_P.moves) >= array_length(_P.sol)) return;
    var _m = _P.sol[array_length(_P.moves)];
    if (_m == "H") { _P.hint = { kind: "hold" }; return; }
    var _p = string_split(_m, ",");
    _P.hint = { kind: "shot", side: real(_p[0]), lane: real(_p[1]) };
    cc_sfx("star", 0.8, 0.6);
}


// ── phases ───────────────────────────────────────────────────────────────────
function cc_phase_begin(_ph) {
    var _P = global.play;
    _P.pt = 0;
    var _n = _P.st.n;
    switch (_ph.kind) {
        case "shot":
            var _dist = abs(_ph.ex - _ph.sx) + abs(_ph.ey - _ph.sy) + 1;
            _P.pdur = 4 + _dist * 2.5;
            cc_sfx("fire", random_range(0.95, 1.05));
            if (variable_struct_exists(_ph, "meteor")) { cc_sfx("turn", 0.6); _P.pdur += 10; }
            break;
        case "bomb":  _P.pdur = 4 + (abs(_ph.ex - _ph.sx) + abs(_ph.ey - _ph.sy) + 1) * 2.5 + 16; cc_sfx("fire", 0.8); break;
        case "drill": _P.pdur = 10 + _n * 3; cc_sfx("drill"); break;
        case "fall":  _P.pdur = 4; break;
        case "pop":
            _P.pdur = max(14, 24 - _ph.chain * 2);
            cc_sfx("pop", 1 + 0.12 * (_ph.chain - 1));
            cc_hitstop(2 + min(_ph.chain, 4));
            var _sum = 0;
            for (var _i = 0; _i < array_length(_ph.cells); _i++) {
                var _c = _ph.cells[_i];
                var _p = cc_to_screen(_c.x, _c.y);
                if (_c.freed) {
                    cc_burst(_p[0], _p[1], $c0b0b0, 6, 5, 2, 30);
                } else {
                    cc_burst(_p[0], _p[1], cc_color_hex(cc_col(_c.v)), 9, 7, 0, 36);
                    cc_burst(_p[0], _p[1], c_white, 3, 4, 1, 18);
                }
                _sum += 1;
            }
            var _mid = cc_to_screen(_ph.cells[0].x, _ph.cells[0].y);
            if (_ph.chain >= 2) cc_float_text(_mid[0], _mid[1] - 30, "CHAIN x" + string(_ph.chain), cc_color_hex(cc_col(_ph.cells[0].v)), 2.2 + 0.3 * _ph.chain, 70);
            cc_shake(2 + _ph.chain * 1.5);
            if (_P.mode == "endless") {
                var _gain = _sum * 10 * _ph.chain;
                _P.endless.score += _gain;
                _P.endless.best_chain = max(_P.endless.best_chain, _ph.chain);
                cc_float_text(_mid[0], _mid[1], "+" + string(_gain), c_white, 1.6, 45);
            }
            if (_ph.core_hit) {
                var _cp = cc_to_screen((_n - 1) / 2, (_n - 1) / 2);
                var _col = cc_color_hex(_ph.core_from);
                cc_sfx("core", 1, 0.9);
                cc_shake(11); cc_flash(0.45, _col); cc_hitstop(7);
                cc_ring(_cp[0], _cp[1], _col, 10, 220, 34, 10);
                cc_ring(_cp[0], _cp[1], c_white, 10, 140, 22, 4);
                cc_burst(_cp[0], _cp[1], _col, 26, 11, 2, 50);
                global.fx.zoom = 0.06;
            }
            break;
        case "core":   _P.pdur = 16; break;
        case "reborn":
            _P.pdur = 30;
            var _cp2 = cc_to_screen((_n - 1) / 2, (_n - 1) / 2);
            cc_ring(_cp2[0], _cp2[1], cc_color_hex(_ph.color), 200, 10, 30, 6);
            cc_float_text(_cp2[0], _cp2[1] - 60, "NEW CORE", c_white, 2.4, 70);
            cc_sfx("confirm", 0.7);
            break;
        case "win":
            _P.pdur = 80;
            var _cp3 = cc_to_screen((_n - 1) / 2, (_n - 1) / 2);
            cc_sfx("win");
            cc_shake(18); cc_flash(0.8, c_white); cc_hitstop(10);
            for (var _k = 0; _k < 6; _k++) cc_burst(_cp3[0], _cp3[1], cc_color_hex(_k), 14, 14, 2, 70);
            cc_ring(_cp3[0], _cp3[1], c_white, 10, 520, 50, 14);
            cc_ring(_cp3[0], _cp3[1], $3ad9ff, 10, 340, 40, 8);
            global.fx.zoom = 0.12;
            break;
    }
}

function cc_phase_end(_ph) {
    var _P = global.play;
    _P.prev = _ph.g;
    switch (_ph.kind) {
        case "shot":
            _P.land_id = _ph.id; _P.land_t = 0;
            cc_sfx("land", random_range(0.9, 1.1));
            cc_shake(2.5);
            var _p = cc_to_screen(_ph.ex, _ph.ey);
            cc_burst(_p[0], _p[1], cc_piece_color(_ph.piece), 6, 4, 1, 20);
            break;
        case "bomb":
            var _b = cc_to_screen(_ph.ex, _ph.ey);
            cc_sfx("bomb"); cc_shake(14); cc_flash(0.5, $3a8aff); cc_hitstop(6);
            cc_ring(_b[0], _b[1], $3a8aff, 10, 180, 30, 10);
            cc_burst(_b[0], _b[1], $3ab0ff, 30, 12, 0, 45);
            for (var _i = 0; _i < array_length(_ph.cells); _i++) {
                var _q = cc_to_screen(_ph.cells[_i].x, _ph.cells[_i].y);
                cc_burst(_q[0], _q[1], $998a8a, 6, 6, 2, 40);
            }
            break;
        case "pop":
            if (_ph.core_hit) _P.disp_hp++;
            break;
        case "core":
            var _cp = cc_to_screen((_P.st.n - 1) / 2, (_P.st.n - 1) / 2);
            cc_ring(_cp[0], _cp[1], cc_color_hex(_ph.color), 120, 20, 20, 6);
            break;
        case "reborn":
            _P.disp_hp = 0;
            break;
    }
}


// ── drawing ──────────────────────────────────────────────────────────────────
function cc_play_draw() {
    var _P = global.play, _st = _P.st, _V = global.view;
    var _n = _st.n, _c = _n div 2, _cs = _V.cs;
    var _wi = (_P.lv != undefined) ? clamp(_P.lv.world, 0, 5) : 0;
    var _W = cc_worlds()[_wi];
    cc_draw_bg(_W.bg, _W.spr, _P.t);

    // shake + punch zoom
    var _sh = global.fx.shake;
    _V.sx = random_range(-_sh, _sh);
    _V.sy = random_range(-_sh, _sh);
    var _cs0 = _cs;
    _V.cs = _cs * (1 + global.fx.zoom);
    var _sc = _V.cs / 16;
    var _ang = _V.ang;

    // planet glow + plate
    var _ctr = cc_to_screen(_c, _c);
    gpu_set_blendmode(bm_add);
    draw_set_alpha(0.12);
    draw_set_color(_W.col);
    draw_circle(_ctr[0], _ctr[1], _V.cs * _n * 0.78, false);
    draw_set_alpha(0.08);
    draw_circle(_ctr[0], _ctr[1], _V.cs * _n * 0.62, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
    for (var _y = 0; _y < _n; _y++) for (var _x = 0; _x < _n; _x++) {
        var _p = cc_to_screen(_x, _y);
        var _ring = max(abs(_x - _c), abs(_y - _c));
        var _col = merge_color($30141a, _W.col, 0.05 + 0.05 * ((_ring + 1) mod 2));
        if (_P.mode == "endless" && _ring == _c) _col = merge_color($180f2a, $5020ff, 0.15 + 0.1 * sin(current_time / 200));
        cc_tile(_p[0], _p[1], _V.cs * 0.47, _ang, _col);
    }

    // which lane the hint points at
    if (_P.hint != undefined && _P.hint.kind == "shot" && !_P.busy) {
        var _e = cc_view_to_board(_n, _P.hint.side, _P.hint.lane, _n - 1);
        var _d = cc_side_dir(_P.hint.side);
        var _hp = cc_to_screen(_e[0] - _d[0] * 1.1, _e[1] - _d[1] * 1.1);
        var _k = 0.6 + 0.4 * sin(_P.hint_t / 5);
        draw_set_alpha(_k); draw_set_color($3ad9ff);
        draw_circle(_hp[0], _hp[1], 12 + 4 * _k, false);
        draw_set_alpha(1);
    }

    // preview (where the shot will land + what it clears)
    if (!_P.busy && _P.result == "") cc_draw_preview(_sc, _ang);

    cc_draw_board(_sc, _ang);

    _V.cs = _cs0;
    cc_draw_launcher();
    cc_draw_hud();
}

// a rounded dark tile, rotated with the board
function cc_tile(_x, _y, _h, _ang, _col) {
    var _pts = [[-_h, -_h], [_h, -_h], [_h, _h], [-_h, _h]];
    var _co = dcos(_ang), _si = dsin(_ang);
    draw_set_color(_col);
    draw_primitive_begin(pr_trianglefan);
    for (var _i = 0; _i < 4; _i++) {
        var _px = _pts[_i][0], _py = _pts[_i][1];
        draw_vertex(_x + _px * _co + _py * _si, _y - _px * _si + _py * _co);
    }
    draw_primitive_end();
}

function cc_draw_board(_sc, _ang) {
    var _P = global.play, _st = _P.st;
    var _n = _st.n, _N = _n * _n;
    var _A = _P.prev;
    var _ph = (_P.busy && _P.pi < array_length(_P.phases)) ? _P.phases[_P.pi] : undefined;
    var _B = (_ph != undefined) ? _ph.g : _A;
    var _t = (_ph != undefined) ? clamp(_P.pt / _P.pdur, 0, 1) : 1;
    var _coreHp = _P.disp_hp;
    var _coreCol = (_coreHp < array_length(_st.seq)) ? _st.seq[_coreHp] : -1;
    var _layers = array_length(_st.seq) - _coreHp;

    // id -> index in A
    var _from = {};
    for (var _i = 0; _i < _N; _i++) if (_A[_i] != CC_EMPTY) _from[$ string(cc_id(_A[_i]))] = _i;
    var _inB = {};

    for (var _i = 0; _i < _N; _i++) {
        var _v = _B[_i];
        if (_v == CC_EMPTY) continue;
        var _key = string(cc_id(_v));
        _inB[$ _key] = true;
        var _bx = _i mod _n, _by = _i div _n;
        var _gx = _bx, _gy = _by, _scale = _sc, _alpha = 1, _white = 0;

        if (variable_struct_exists(_from, _key)) {
            var _j = _from[$ _key];
            var _k = (_ph != undefined && _ph.kind == "fall") ? ease_in_quad(_t) : ease_out_cubic(_t);
            _gx = lerp(_j mod _n, _bx, _k);
            _gy = lerp(_j div _n, _by, _k);
            // a cage just broke open
            if (cc_cage(_A[_j]) && !cc_cage(_v)) {
                var _p = cc_to_screen(_gx, _gy);
                cc_draw_cell(_v, _p[0], _p[1], _scale, _ang);
                cc_spr(spr_locked_cage, 0, _p[0], _p[1], _sc * (1 + _t * 0.6), _ang + _t * 30, c_white, 1 - _t);
                continue;
            }
        } else if (_ph != undefined && (_ph.kind == "shot") && cc_id(_v) == _ph.id) {
            // the shot flying in from outside the board
            var _d = _ph.dir;
            var _ox = _ph.sx - _d[0] * 1.5, _oy = _ph.sy - _d[1] * 1.5;
            var _k2 = ease_in_quad(_t);
            _gx = lerp(_ox, _bx, _k2);
            _gy = lerp(_oy, _by, _k2);
            // trail
            for (var _s = 1; _s <= 4; _s++) {
                var _tt = max(0, _k2 - _s * 0.06);
                var _q = cc_to_screen(lerp(_ox, _bx, _tt), lerp(_oy, _by, _tt));
                cc_draw_piece(_ph.piece, _q[0], _q[1], _sc * (1 - _s * 0.12), _ang, 0.35 - _s * 0.07);
            }
        } else {
            _scale = _sc * ease_out_back(_t);
        }

        // landing squash
        if (cc_id(_v) == _P.land_id && _P.land_t < 12) {
            _scale *= 1 + 0.18 * sin(_P.land_t / 12 * pi) ;
        }
        // level intro: blocks pop in from the core outwards
        var _cx = (_n - 1) / 2;
        var _dist = abs(_bx - _cx) + abs(_by - _cx);
        if (_P.t < 60) _scale *= ease_out_back(clamp((_P.t - _dist * 4) / 16, 0, 1));
        // core broken: the rest of the planet blasts outwards
        if (_ph != undefined && _ph.kind == "win") {
            var _k = ease_in_quad(clamp((_t - 0.15) / 0.85, 0, 1));
            var _ox = _gx - _cx, _oy = _gy - _cx;
            var _len = max(0.5, point_distance(0, 0, _ox, _oy));
            _gx += _ox / _len * _k * _n * 0.9;
            _gy += _oy / _len * _k * _n * 0.9;
            _alpha = 1 - _k;
            _scale *= 1 + _k * 0.5;
        }
        var _p = cc_to_screen(_gx, _gy);
        cc_draw_cell(_v, _p[0], _p[1], _scale, _ang, _alpha, _white, _coreCol, _layers);
    }

    // cells leaving the board this phase (popped, drilled, bombed, core breaking)
    if (_ph != undefined) {
        for (var _i = 0; _i < _N; _i++) {
            var _v = _A[_i];
            if (_v == CC_EMPTY || variable_struct_exists(_inB, string(cc_id(_v)))) continue;
            var _p = cc_to_screen(_i mod _n, _i div _n);
            if (_ph.kind == "pop") {
                var _wk = clamp(_t / 0.35, 0, 1);
                var _gone = clamp((_t - 0.35) / 0.65, 0, 1);
                cc_draw_cell(_v, _p[0], _p[1], _sc * (1 + 0.25 * _wk) * (1 - ease_in_quad(_gone)), _ang + _gone * 90, 1, _wk, _coreCol, _layers);
            } else if (_ph.kind == "drill" || _ph.kind == "bomb") {
                cc_draw_cell(_v, _p[0], _p[1], _sc * (1 - _t), _ang + _t * 180, 1 - _t, 0.6);
            } else if (_ph.kind == "win") {
                var _k = clamp(_t * 3, 0, 1);
                cc_draw_cell(_v, _p[0], _p[1], _sc * (1 + _k * 2), _ang, 1 - _k, 1, _coreCol, 1);
            }
        }
        // drill / bomb in flight
        if (_ph.kind == "drill" || _ph.kind == "bomb") {
            var _d = _ph.dir;
            var _ox = _ph.sx - _d[0] * 1.5, _oy = _ph.sy - _d[1] * 1.5;
            var _travel = (_ph.kind == "bomb") ? clamp(_t / 0.6, 0, 1) : _t;
            if (_ph.kind == "drill" || _travel < 1) {
                var _q = cc_to_screen(lerp(_ox, _ph.ex, ease_in_quad(_travel)), lerp(_oy, _ph.ey, ease_in_quad(_travel)));
                cc_draw_piece(_ph.piece, _q[0], _q[1], _sc * 1.1, _ang + ((_ph.kind == "drill") ? _P.t * 0 : _P.t * 8), 1);
                if (_ph.kind == "drill") cc_burst(_q[0], _q[1], $e0d6d0, 1, 3, 1, 14);
            }
        }
    }
}

function cc_draw_preview(_sc, _ang) {
    var _P = global.play, _st = _P.st;
    var _n = _st.n;
    var _piece = cc_piece(_st);
    if (_piece < 0) return;
    var _key = string(_P.side) + ":" + string(_P.lane) + ":" + string(_piece) + ":" + string(array_length(_P.undo)) + ":" + string(_st.hold);
    if (_key != _P.preview_key) {
        _P.preview_key = _key;
        _P.preview = undefined;
        if (cc_can_fire(_st, _P.side, _P.lane)) {
            var _sim = cc_state_copy(_st);
            var _ph = cc_fire(_sim, _P.side, _P.lane);
            var _land = (_piece == CC_DRILL) ? undefined : cc_landing(_st, _P.side, _P.lane);
            var _clears = [];
            for (var _i = 0; _i < array_length(_ph); _i++) if (_ph[_i].kind == "pop") { _clears = _ph[_i].cells; break; }
            var _hits = 0;
            for (var _i = 0; _i < array_length(_ph); _i++) if (_ph[_i].kind == "pop" && _ph[_i].core_hit) _hits++;
            _P.preview = { land: _land, clears: _clears, core: _hits, win: _sim.won, drill: _ph[0] };
        }
    }
    var _d = cc_side_dir(_P.side);
    var _e = cc_view_to_board(_n, _P.side, _P.lane, _n - 1);
    var _blink = 0.55 + 0.25 * sin(current_time / 140);

    if (_P.preview == undefined) {
        // blocked lane: red cross over the entry cell
        var _p = cc_to_screen(_e[0], _e[1]);
        draw_set_color($5533ff); draw_set_alpha(_blink);
        draw_line_width(_p[0] - 14, _p[1] - 14, _p[0] + 14, _p[1] + 14, 5);
        draw_line_width(_p[0] + 14, _p[1] - 14, _p[0] - 14, _p[1] + 14, 5);
        draw_set_alpha(1);
        return;
    }
    // dotted aim line
    var _endx, _endy;
    if (_P.preview.land != undefined) { _endx = _P.preview.land[0]; _endy = _P.preview.land[1]; }
    else { _endx = _P.preview.drill.ex; _endy = _P.preview.drill.ey; }
    var _steps = abs(_endx - _e[0]) + abs(_endy - _e[1]) + 1;
    var _ox = _e[0] - _d[0], _oy = _e[1] - _d[1];
    for (var _s = 0; _s < _steps * 3; _s++) {
        var _k = _s / (_steps * 3);
        var _q = cc_to_screen(lerp(_ox, _endx, _k), lerp(_oy, _endy, _k));
        var _ph2 = ((_s + current_time / 60) mod 3) < 1.2;
        if (_ph2) { draw_set_color(cc_piece_color(_piece)); draw_set_alpha(0.7); draw_circle(_q[0], _q[1], 3, false); }
    }
    draw_set_alpha(1);
    // will-clear outlines
    for (var _i = 0; _i < array_length(_P.preview.clears); _i++) {
        var _c = _P.preview.clears[_i];
        var _p = cc_to_screen(_c.x, _c.y);
        cc_tile_outline(_p[0], _p[1], global.view.cs * 0.52, _ang, c_white, _blink);
    }
    // ghost block
    if (_P.preview.land != undefined) {
        var _p = cc_to_screen(_P.preview.land[0], _P.preview.land[1]);
        cc_draw_piece(_piece, _p[0], _p[1], _sc * 0.9, _ang, 0.45 + 0.15 * sin(current_time / 140));
        cc_tile_outline(_p[0], _p[1], global.view.cs * 0.5, _ang, cc_piece_color(_piece), 0.9);
    }
}

function cc_tile_outline(_x, _y, _h, _ang, _col, _alpha) {
    var _co = dcos(_ang), _si = dsin(_ang);
    var _pts = [[-_h, -_h], [_h, -_h], [_h, _h], [-_h, _h]];
    draw_set_color(_col); draw_set_alpha(_alpha);
    for (var _i = 0; _i < 4; _i++) {
        var _a = _pts[_i], _b = _pts[(_i + 1) mod 4];
        draw_line_width(_x + _a[0] * _co + _a[1] * _si, _y - _a[0] * _si + _a[1] * _co,
                        _x + _b[0] * _co + _b[1] * _si, _y - _b[0] * _si + _b[1] * _co, 3);
    }
    draw_set_alpha(1);
}

function cc_draw_launcher() {
    var _P = global.play, _V = global.view, _st = _P.st;
    if (_P.result == "win" || _P.result == "over") return;
    var _n = _st.n, _c = (_n - 1) / 2;
    var _x = _V.x + (_P.lane - _c) * _V.cs;
    var _y = _V.y + (_c + 1) * _V.cs + 26;
    var _bob = sin(_P.t / 14) * 3;
    var _can = cc_can_fire(_st, _P.side, _P.lane);
    cc_spr(spr_refabricator_ship, (_P.t div 6) mod 2, _x, _y + _bob, 3, 180, _can ? c_white : $9080ff, 1);
    cc_draw_piece(cc_piece(_st), _x, _y - 34 + _bob, 2.6, 0, 1);
}

function cc_draw_hud() {
    var _P = global.play, _st = _P.st;
    var _W = cc_worlds()[clamp(_P.lv.world, 0, 5)];
    // ── left: level + shots + core ──
    cc_panel(28, 28, 270, 300, _W.col);
    if (_P.mode == "campaign") {
        var _wl = cc_world_levels(_P.lv.world);
        var _num = 1;
        for (var _i = 0; _i < array_length(_wl); _i++) if (_wl[_i] == _P.li) _num = _i + 1;
        cc_text(48, 44, _W.name + "  " + string(_num) + "/" + string(array_length(_wl)), 1.6, _W.col);
        cc_text(48, 72, string_upper(_P.lv.name), 2.2, c_white);
        cc_text(48, 120, "SHOTS", 1.6, $d89fa9);
        cc_text(270, 112, string(_st.shots), 3, c_white, 1, fa_right);
        cc_text(48, 160, "PAR", 1.6, $d89fa9);
        cc_text(270, 152, string(_P.lv.par), 3, $3ad9ff, 1, fa_right);
        var _now = cc_stars_for(_P.lv, _st.won ? _st.shots : _st.shots + 1);
        for (var _s = 0; _s < 3; _s++) cc_draw_star(70 + _s * 40, 214, 14, _s < _now);
    } else {
        var _E = _P.endless;
        _E.show_score = lerp(_E.show_score, _E.score, 0.2);
        cc_text(48, 44, "ENDLESS ORBIT", 1.6, _W.col);
        cc_text(48, 76, "SCORE", 1.6, $d89fa9);
        cc_text(270, 104, string(round(_E.show_score)), 3.2, c_white, 1, fa_right);
        cc_text(48, 156, "CORES " + string(_E.cores), 1.8, c_white);
        cc_text(48, 186, "BEST " + string(global.save.endless_best), 1.6, $3ad9ff);
        var _left = 3 - (_E.shots mod 3);
        cc_text(48, 214, "METEOR IN " + string(_left), 1.5, (_left == 1) ? $8060ff : $d89fa9);
    }
    // core layers
    cc_text(48, 250, "CORE", 1.6, $d89fa9);
    for (var _i = 0; _i < array_length(_st.seq); _i++) {
        var _done = _i < _P.disp_hp;
        var _x = 60 + _i * 44, _y = 296;
        var _cur = (_i == _P.disp_hp);
        cc_draw_core(_x, _y, _cur ? 2.6 + 0.2 * sin(current_time / 150) : 2.1, _done ? 0.25 : 1, _st.seq[_i], 1);
        if (_done) { draw_set_color(c_white); draw_line_width(_x - 14, _y - 14, _x + 14, _y + 14, 3); }
    }

    // ── right: queue + hold ──
    var _qx = 1000;
    cc_panel(_qx, 28, 250, 380, $fc5d6d);
    cc_text(_qx + 20, 44, "NEXT", 1.8, $d89fa9);
    var _q = _st.queue;
    var _cnt = array_length(_q);
    if (_cnt == 0) cc_text(_qx + 125, 120, "EMPTY", 2, $8060ff, 1, fa_center, fa_middle);
    for (var _i = 0; _i < min(_cnt, 6); _i++) {
        var _y = 110 + _i * 44 + ((_i > 0) ? 20 : 0);
        var _s = (_i == 0) ? 4 : 2.4;
        var _x = (_i == 0) ? _qx + 70 : _qx + 50 + ((_i - 1) mod 4) * 0;
        if (_i == 0) {
            cc_draw_piece(_q[0], _qx + 70, 110, 4, 0, 1);
        } else {
            cc_draw_piece(_q[_i], _qx + 60, 130 + _i * 40, 2.4, 0, 1 - _i * 0.1);
        }
    }
    if (_cnt > 6) cc_text(_qx + 60, 375, "+" + string(_cnt - 6), 1.6, $d89fa9, 1, fa_center);
    // hold
    cc_text(_qx + 140, 44, "HOLD", 1.8, $d89fa9);
    draw_set_color($50202a);
    draw_roundrect_ext(_qx + 140, 76, _qx + 230, 160, 12, 12, true);
    if (_st.hold >= 0) cc_draw_piece(_st.hold, _qx + 185, 118, 3.4, 0, 1);
    cc_text(_qx + 185, 172, "[C]", 1.4, $a0666f, 1, fa_center);

    // ── controls ──
    var _pad = global.inp.pad >= 0;
    var _ctl = _pad ? "D-PAD aim   A fire   X hold   B undo   SELECT restart   LB/RB turn"
                    : "ARROWS aim   SPACE fire   C hold   Z undo   R restart   Q/E turn   H hint";
    if (_P.mode == "endless") _ctl = _pad ? "D-PAD aim   A fire   X hold   LB/RB turn" : "ARROWS aim   SPACE fire   C hold   Q/E turn   R restart";
    cc_text(640, 700, _ctl, 1.3, $c0868f, 0.9, fa_center, fa_bottom, false);

    // tip banner
    if (_P.lv.tip != "" && _P.result == "") {
        var _a = clamp(_P.tip_t / 20, 0, 1);
        cc_panel(330, 20, 640, 44, $702f3a, 0.75 * _a);
        cc_text(650, 42, _P.lv.tip, 1.4, c_white, _a, fa_center, fa_middle, false);
    }
    // hint messages
    if (_P.hint != undefined && _P.hint_t < 240) {
        var _msg = "";
        if (_P.hint.kind == "off") _msg = "You've drifted from the solution - undo (Z) a few shots";
        if (_P.hint.kind == "hold") _msg = "Hint: hold this block (C)";
        if (_P.hint.kind == "shot") _msg = "Hint: fire at the glowing marker";
        cc_text(600, 612, _msg, 1.6, $3ad9ff, 1, fa_center, fa_middle);
    }

    // out of blocks
    if (_P.result == "fail") {
        var _a = clamp(_P.result_t / 15, 0, 1);
        cc_panel(400, 250, 400, 150, $6040ff, 0.92 * _a);
        cc_text(600, 290, "OUT OF BLOCKS", 3, $8060ff, _a, fa_center, fa_middle);
        cc_text(600, 340, "Z  undo        R  restart", 1.8, c_white, _a, fa_center, fa_middle);
        if (_P.fails >= 2) cc_text(600, 372, "Stuck? Press H for a hint", 1.4, $3ad9ff, _a, fa_center, fa_middle);
    }

    // level name card
    if (_P.t < 100) {
        var _k = (_P.t < 15) ? ease_out_back(_P.t / 15) : 1;
        var _a = (_P.t > 70) ? 1 - (_P.t - 70) / 30 : 1;
        var _title = (_P.mode == "endless") ? "ENDLESS ORBIT" : string_upper(_P.lv.name);
        cc_text(600, 330, _title, 4.2 * _k, c_white, _a, fa_center, fa_middle);
    }
    if (_P.result == "win" || _P.result == "over") cc_result_draw();
    if (_P.paused) cc_pause_draw();
}


// ── win / game over panel ────────────────────────────────────────────────────
function cc_result_step() {
    var _P = global.play, _I = global.inp;
    if (_P.result_t < 30) return;
    var _opts = cc_result_options();
    if (_I.left || _I.up)  { _P.sel = (_P.sel + array_length(_opts) - 1) mod array_length(_opts); cc_sfx("select"); }
    if (_I.right || _I.down) { _P.sel = (_P.sel + 1) mod array_length(_opts); cc_sfx("select"); }
    // stars ding in one by one
    if (_P.result == "win") for (var _s = 0; _s < _P.stars; _s++) if (_P.result_t == 40 + _s * 14) {
        cc_sfx("star", 1 + _s * 0.12);
        cc_burst(560 + _s * 80, 300, $3ad9ff, 16, 8, 2, 40);
    }
    if (_I.restart) { cc_play_restart_full(); return; }
    if (_I.ok) {
        cc_sfx("confirm");
        var _o = _opts[_P.sel];
        if (_o == "NEXT") {
            var _nx = _P.li + 1;
            if (_nx < array_length(global.levels) && cc_level_open(_nx)) cc_play_start_level(_nx);
            else cc_goto_map(_P.li);
        } else if (_o == "RETRY") cc_play_restart_full();
        else if (_o == "MAP") cc_goto_map(_P.li);
        else if (_o == "MENU") cc_goto("menu");
    }
    if (_I.back) { if (_P.mode == "endless") cc_goto("menu"); else cc_goto_map(_P.li); }
}

function cc_play_restart_full() {
    var _P = global.play;
    if (_P.mode == "endless") cc_play_start_endless(); else cc_play_start_level(_P.li);
}

function cc_result_options() {
    return (global.play.mode == "endless") ? ["RETRY", "MENU"] : ["NEXT", "RETRY", "MAP"];
}

function cc_result_draw() {
    var _P = global.play;
    var _a = clamp((_P.result_t - 10) / 20, 0, 1);
    if (_a <= 0) return;
    draw_set_alpha(0.55 * _a); draw_set_color(c_black); draw_rectangle(0, 0, 1280, 720, false); draw_set_alpha(1);
    var _y0 = 170 + (1 - ease_out_back(_a)) * 80;
    cc_panel(380, _y0, 520, 360, $3ad9ff, 0.95 * _a);
    if (_P.result == "win") {
        cc_text(640, _y0 + 50, "CORE BROKEN!", 4, $3ad9ff, _a, fa_center, fa_middle);
        for (var _s = 0; _s < 3; _s++) {
            var _t = _P.result_t - (40 + _s * 14);
            var _on = _s < _P.stars && _t >= 0;
            var _k = _on ? ease_out_elastic(clamp(_t / 20, 0, 1)) : 1;
            cc_draw_star(560 + _s * 80, _y0 + 130, 30 * _k, _on);
        }
        cc_text(640, _y0 + 195, "SHOTS " + string(_P.st.shots) + "   PAR " + string(_P.lv.par), 2, c_white, _a, fa_center, fa_middle);
        var _msg = (_P.stars == 3) ? "PERFECT!" : ((_P.stars == 2) ? "Close - can you match par?" : "Try fewer shots for more stars");
        cc_text(640, _y0 + 228, _msg, 1.5, $d89fa9, _a, fa_center, fa_middle);
    } else {
        var _E = _P.endless;
        cc_text(640, _y0 + 50, "PLANET OVERLOAD", 3.6, $8060ff, _a, fa_center, fa_middle);
        cc_text(640, _y0 + 120, string(_E.score), 5, c_white, _a, fa_center, fa_middle);
        cc_text(640, _y0 + 175, "CORES " + string(_E.cores) + "   BEST CHAIN x" + string(_E.best_chain), 1.8, $d89fa9, _a, fa_center, fa_middle);
        if (variable_struct_exists(_E, "new_best")) cc_text(640, _y0 + 212, "NEW BEST!", 2.2, $3ad9ff, _a * (0.6 + 0.4 * sin(current_time / 100)), fa_center, fa_middle);
    }
    var _opts = cc_result_options();
    var _cnt = array_length(_opts);
    for (var _i = 0; _i < _cnt; _i++) {
        cc_button(640 + (_i - (_cnt - 1) / 2) * 160, _y0 + 300, 140, 50, _opts[_i], _P.sel == _i, $fc5d6d);
    }
}


// ── pause ────────────────────────────────────────────────────────────────────
function cc_pause_options() {
    return (global.play.mode == "endless") ? ["RESUME", "RESTART", "OPTIONS", "MENU"] : ["RESUME", "HINT", "RESTART", "OPTIONS", "MAP"];
}

function cc_pause_step() {
    var _P = global.play, _I = global.inp;
    var _opts = cc_pause_options();
    var _n = array_length(_opts);
    if (_I.up)   { _P.pause_sel = (_P.pause_sel + _n - 1) mod _n; cc_sfx("select"); }
    if (_I.down) { _P.pause_sel = (_P.pause_sel + 1) mod _n; cc_sfx("select"); }
    if (_I.pause || _I.back) { _P.paused = false; cc_sfx("select"); return; }
    if (_I.ok) {
        cc_sfx("confirm");
        var _o = _opts[_P.pause_sel];
        _P.paused = false;
        switch (_o) {
            case "HINT": cc_play_hint(); break;
            case "RESTART": cc_play_restart_full(); break;
            case "OPTIONS": global.options_return = "play"; cc_goto("options", false); break;
            case "MAP": cc_goto_map(_P.li); break;
            case "MENU": cc_goto("menu"); break;
        }
    }
}

function cc_pause_draw() {
    var _P = global.play;
    draw_set_alpha(0.6); draw_set_color(c_black); draw_rectangle(0, 0, 1280, 720, false); draw_set_alpha(1);
    var _opts = cc_pause_options();
    cc_panel(480, 150, 320, 110 + array_length(_opts) * 62, $fc5d6d, 0.95);
    cc_text(640, 195, "PAUSED", 3.4, c_white, 1, fa_center, fa_middle);
    for (var _i = 0; _i < array_length(_opts); _i++) cc_button(640, 260 + _i * 62, 240, 48, _opts[_i], _P.pause_sel == _i);
}
