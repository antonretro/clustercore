// =============================================================================
// scr_cc_rules - the whole game's rules as pure data. No drawing, no instances.
// Mirrors tools/ccsim.py exactly (the solver that checks every level).
//
// A board cell is one integer:  type | colour<<3 | axis<<6 | cage<<7 | id<<8
// so a board is a plain array and undo is array_copy.
// =============================================================================

#macro CC_EMPTY  0
#macro CC_NORMAL 1
#macro CC_ARROW  2
#macro CC_STONE  3
#macro CC_WALL   4
#macro CC_CORE   5

#macro CC_BOMB   10
#macro CC_DRILL  11
#macro CC_PAINT  12

#macro CC_MATCH  3

function cc_t(_v)    { return _v & 7; }
function cc_col(_v)  { return (_v >> 3) & 7; }
function cc_ax(_v)   { return (_v >> 6) & 1; }
function cc_cage(_v) { return (_v >> 7) & 1; }
function cc_id(_v)   { return _v >> 8; }
function cc_make(_t, _col, _ax, _cage, _id) { return _t | (_col << 3) | (_ax << 6) | (_cage << 7) | (_id << 8); }
function cc_strip(_v) { return _v & 255; }      // without the id, for comparing boards

function cc_colored(_v) { var _t = _v & 7; return _t == CC_NORMAL || _t == CC_ARROW; }
function cc_movable(_v) { var _t = _v & 7; return (_t == CC_NORMAL || _t == CC_ARROW || _t == CC_STONE) && !cc_cage(_v); }


// ── state ────────────────────────────────────────────────────────────────────
function cc_state_new(_n) {
    var _g = array_create(_n * _n, 0);
    return { n: _n, g: _g, seq: [], hp: 0, queue: [], hold: -1, shots: 0, won: false, next_id: 1 };
}

function cc_state_copy(_s) {
    var _c = cc_state_new(_s.n);
    array_copy(_c.g, 0, _s.g, 0, array_length(_s.g));
    _c.seq = _s.seq;
    _c.hp = _s.hp;
    _c.queue = [];
    array_copy(_c.queue, 0, _s.queue, 0, array_length(_s.queue));
    _c.hold = _s.hold;
    _c.shots = _s.shots;
    _c.won = _s.won;
    _c.next_id = _s.next_id;
    return _c;
}

function cc_get(_s, _x, _y)     { return _s.g[_y * _s.n + _x]; }
function cc_set(_s, _x, _y, _v) { _s.g[@ _y * _s.n + _x] = _v; }
function cc_in(_s, _x, _y)      { return _x >= 0 && _y >= 0 && _x < _s.n && _y < _s.n; }

function cc_new_cell(_s, _t, _col, _ax, _cage) {
    var _v = cc_make(_t, _col, _ax, _cage, _s.next_id);
    _s.next_id++;
    return _v;
}

function cc_core_color(_s) {
    return (_s.hp < array_length(_s.seq)) ? _s.seq[_s.hp] : -1;
}

function cc_piece(_s) {
    return (array_length(_s.queue) > 0) ? _s.queue[0] : -1;
}


// ── sides and lanes ──────────────────────────────────────────────────────────
// The player always stands at the bottom of the screen. Side s means the board
// is turned s quarter-turns; lane = column from the left as the player sees it.
function cc_view_to_board(_n, _side, _x, _y) {
    repeat (((_side mod 4) + 4) mod 4) {
        var _t = _x;
        _x = _n - 1 - _y;
        _y = _t;
    }
    return [_x, _y];
}

function cc_side_dir(_side) {
    var _dx = 0, _dy = -1;
    repeat (((_side mod 4) + 4) mod 4) {
        var _t = _dx;
        _dx = -_dy;
        _dy = _t;
    }
    return [_dx, _dy];
}


// ── actions ──────────────────────────────────────────────────────────────────
function cc_hold(_s) {
    if (_s.hold < 0) {
        if (array_length(_s.queue) == 0) return false;
        _s.hold = _s.queue[0];
        array_delete(_s.queue, 0, 1);
    } else if (array_length(_s.queue) > 0) {
        var _t = _s.queue[0];
        _s.queue[@ 0] = _s.hold;
        _s.hold = _t;
    } else {
        array_push(_s.queue, _s.hold);
        _s.hold = -1;
    }
    return true;
}

function cc_can_fire(_s, _side, _lane) {
    if (_s.won || array_length(_s.queue) == 0) return false;
    if (_s.queue[0] == CC_DRILL) return true;
    var _e = cc_view_to_board(_s.n, _side, _lane, _s.n - 1);
    return cc_get(_s, _e[0], _e[1]) == CC_EMPTY;
}

// Where a normal shot would land (board coords) or undefined.
function cc_landing(_s, _side, _lane) {
    if (!cc_can_fire(_s, _side, _lane)) return undefined;
    var _n = _s.n, _c = _n div 2;
    var _d = cc_side_dir(_side);
    var _p = cc_view_to_board(_n, _side, _lane, _n - 1);
    var _x = _p[0], _y = _p[1], _k = _n - 1;
    while (_k > _c) {
        if (cc_get(_s, _x + _d[0], _y + _d[1]) != CC_EMPTY) break;
        _x += _d[0]; _y += _d[1]; _k--;
    }
    return [_x, _y, _k];
}

// Fires the current piece. Returns an array of phases for the animator:
//   { kind, g (board after), ... }  kinds: shot, drill, bomb, fall, pop, core, win
function cc_fire(_s, _side, _lane) {
    var _n = _s.n, _c = _n div 2;
    var _piece = _s.queue[0];
    var _l = (_piece == CC_DRILL) ? undefined : cc_landing(_s, _side, _lane);
    array_delete(_s.queue, 0, 1);
    _s.shots++;

    var _phases = [];
    var _d = cc_side_dir(_side);
    var _start = cc_view_to_board(_n, _side, _lane, _n - 1);

    if (_piece == CC_DRILL) {
        var _hits = [];
        for (var _k = _n - 1; _k >= _c; _k--) {
            var _b = cc_view_to_board(_n, _side, _lane, _k);
            var _v = cc_get(_s, _b[0], _b[1]);
            if (_v == CC_EMPTY) continue;
            var _t = cc_t(_v);
            if (_t == CC_WALL || _t == CC_CORE) break;
            array_push(_hits, { x: _b[0], y: _b[1], v: _v });
            cc_set(_s, _b[0], _b[1], CC_EMPTY);
            if (array_length(_hits) >= 3) break;
        }
        var _end = cc_view_to_board(_n, _side, _lane, _c);
        array_push(_phases, { kind: "drill", g: cc_snap(_s), sx: _start[0], sy: _start[1], ex: _end[0], ey: _end[1], cells: _hits, piece: _piece });
    } else {
        var _x = _l[0], _y = _l[1], _k = _l[2];
        var _hit = CC_EMPTY;
        if (_k > _c) _hit = cc_get(_s, _x + _d[0], _y + _d[1]);

        if (_piece == CC_BOMB) {
            var _gone = [];
            for (var _yy = _y - 1; _yy <= _y + 1; _yy++) {
                for (var _xx = _x - 1; _xx <= _x + 1; _xx++) {
                    if (!cc_in(_s, _xx, _yy)) continue;
                    var _v = cc_get(_s, _xx, _yy);
                    if (_v == CC_EMPTY) continue;
                    var _t = cc_t(_v);
                    if (_t == CC_WALL || _t == CC_CORE) continue;
                    array_push(_gone, { x: _xx, y: _yy, v: _v });
                    cc_set(_s, _xx, _yy, CC_EMPTY);
                }
            }
            array_push(_phases, { kind: "bomb", g: cc_snap(_s), sx: _start[0], sy: _start[1], ex: _x, ey: _y, cells: _gone, piece: _piece });
        } else {
            var _cell;
            if (_piece == CC_PAINT) {
                if (cc_colored(_hit)) _cell = cc_new_cell(_s, CC_NORMAL, cc_col(_hit), 0, 0);
                else if (cc_t(_hit) == CC_CORE && cc_core_color(_s) >= 0) _cell = cc_new_cell(_s, CC_NORMAL, cc_core_color(_s), 0, 0);
                else _cell = cc_new_cell(_s, CC_STONE, 0, 0, 0);
            } else {
                _cell = cc_new_cell(_s, CC_NORMAL, _piece, 0, 0);
            }
            cc_set(_s, _x, _y, _cell);
            array_push(_phases, { kind: "shot", g: cc_snap(_s), sx: _start[0], sy: _start[1], ex: _x, ey: _y, id: cc_id(_cell), piece: _piece });
        }
    }
    cc_resolve(_s, _phases);
    return _phases;
}

function cc_snap(_s) {
    var _g = array_create(array_length(_s.g));
    array_copy(_g, 0, _s.g, 0, array_length(_s.g));
    return _g;
}


// ── gravity: everything falls one step towards the core per sweep ────────────
function cc_order(_n) {
    static _cache = {};
    var _key = string(_n);
    if (variable_struct_exists(_cache, _key)) return _cache[$ _key];
    var _c = _n div 2;
    var _list = [];
    for (var _y = 0; _y < _n; _y++)
        for (var _x = 0; _x < _n; _x++)
            array_push(_list, [_x, _y, (abs(_x - _c) + abs(_y - _c)) * 10000 + _y * 100 + _x]);
    array_sort(_list, function(_a, _b) { return _a[2] - _b[2]; });
    _cache[$ _key] = _list;
    return _list;
}

function cc_gravity_sweep(_s) {
    var _n = _s.n, _c = _n div 2;
    var _order = cc_order(_n);
    var _moved = false;
    for (var _i = 0; _i < array_length(_order); _i++) {
        var _x = _order[_i][0], _y = _order[_i][1];
        var _v = cc_get(_s, _x, _y);
        if (_v == CC_EMPTY || !cc_movable(_v)) continue;
        var _dx = _x - _c, _dy = _y - _c;
        var _tx = _x, _ty = _y;
        if (abs(_dy) >= abs(_dx)) _ty -= sign(_dy); else _tx -= sign(_dx);
        if (cc_get(_s, _tx, _ty) == CC_EMPTY) {
            cc_set(_s, _tx, _ty, _v);
            cc_set(_s, _x, _y, CC_EMPTY);
            _moved = true;
        }
    }
    return _moved;
}


// ── matching ─────────────────────────────────────────────────────────────────
// Returns an array of board indexes to clear.
function cc_find_clears(_s) {
    var _n = _s.n, _g = _s.g, _N = _n * _n;
    var _mark = array_create(_N, false);
    var _seen = array_create(_N, false);
    var _out = [];

    // colour groups (normal blocks, caged or not)
    for (var _i = 0; _i < _N; _i++) {
        var _v = _g[_i];
        if (_seen[_i] || cc_t(_v) != CC_NORMAL) continue;
        var _col = cc_col(_v);
        var _stack = [_i], _grp = [];
        _seen[_i] = true;
        while (array_length(_stack) > 0) {
            var _p = array_pop(_stack);
            array_push(_grp, _p);
            var _px = _p mod _n, _py = _p div _n;
            for (var _d = 0; _d < 4; _d++) {
                var _qx = _px + ((_d == 0) - (_d == 1));
                var _qy = _py + ((_d == 2) - (_d == 3));
                if (_qx < 0 || _qy < 0 || _qx >= _n || _qy >= _n) continue;
                var _q = _qy * _n + _qx;
                if (_seen[_q]) continue;
                var _w = _g[_q];
                if (cc_t(_w) == CC_NORMAL && cc_col(_w) == _col) {
                    _seen[_q] = true;
                    array_push(_stack, _q);
                }
            }
        }
        if (array_length(_grp) >= CC_MATCH) {
            for (var _j = 0; _j < array_length(_grp); _j++) _mark[_grp[_j]] = true;
        }
    }

    // arrows: a straight line of 3+ along the arrow
    for (var _i = 0; _i < _N; _i++) {
        var _v = _g[_i];
        if (cc_t(_v) != CC_ARROW) continue;
        var _x = _i mod _n, _y = _i div _n, _col = cc_col(_v);
        var _ddx = (cc_ax(_v) == 0), _ddy = (cc_ax(_v) == 1);
        var _run = [_i];
        for (var _sg = -1; _sg <= 1; _sg += 2) {
            var _px = _x + _ddx * _sg, _py = _y + _ddy * _sg;
            while (_px >= 0 && _py >= 0 && _px < _n && _py < _n) {
                var _w = _g[_py * _n + _px];
                if (!cc_colored(_w) || cc_col(_w) != _col) break;
                array_push(_run, _py * _n + _px);
                _px += _ddx * _sg; _py += _ddy * _sg;
            }
        }
        if (array_length(_run) >= CC_MATCH) {
            for (var _j = 0; _j < array_length(_run); _j++) _mark[_run[_j]] = true;
        }
    }

    for (var _i = 0; _i < _N; _i++) if (_mark[_i]) array_push(_out, _i);
    return _out;
}


// ── resolve: gravity -> clear -> repeat ──────────────────────────────────────
function cc_resolve(_s, _phases) {
    var _n = _s.n, _c = _n div 2;
    var _chain = 0;
    while (true) {
        while (cc_gravity_sweep(_s)) {
            array_push(_phases, { kind: "fall", g: cc_snap(_s) });
        }
        var _clear = cc_find_clears(_s);
        if (array_length(_clear) == 0) return;

        _chain++;
        var _cc = cc_core_color(_s);
        var _hit = false;
        var _cells = [];
        for (var _j = 0; _j < array_length(_clear); _j++) {
            var _i = _clear[_j];
            var _v = _s.g[_i];
            var _x = _i mod _n, _y = _i div _n;
            array_push(_cells, { x: _x, y: _y, v: _v, freed: cc_cage(_v) });
            if (cc_cage(_v)) _s.g[@ _i] = _v & ~128;
            else _s.g[@ _i] = CC_EMPTY;
            if (abs(_x - _c) + abs(_y - _c) == 1 && cc_col(_v) == _cc) _hit = true;
        }
        var _coreThere = (cc_t(cc_get(_s, _c, _c)) == CC_CORE);
        var _pop = { kind: "pop", g: cc_snap(_s), cells: _cells, chain: _chain, core_hit: false, core_from: _cc };
        array_push(_phases, _pop);

        if (_hit && _coreThere) {
            _s.hp++;
            _pop.core_hit = true;
            if (_s.hp >= array_length(_s.seq)) {
                cc_set(_s, _c, _c, CC_EMPTY);
                _s.won = true;
                array_push(_phases, { kind: "win", g: cc_snap(_s) });
                return;
            }
            array_push(_phases, { kind: "core", g: cc_snap(_s), color: cc_core_color(_s) });
        }
    }
}


// ── level -> state ───────────────────────────────────────────────────────────
function cc_state_from_level(_lv) {
    var _n = array_length(_lv.rows);
    var _s = cc_state_new(_n);
    for (var _y = 0; _y < _n; _y++) {
        var _row = _lv.rows[_y];
        for (var _x = 0; _x < _n; _x++) {
            cc_set(_s, _x, _y, cc_cell_from_token(_s, _row[_x]));
        }
    }
    _s.seq = _lv.core;
    _s.queue = [];
    array_copy(_s.queue, 0, _lv.queue, 0, array_length(_lv.queue));
    return _s;
}

function cc_cell_from_token(_s, _tok) {
    if (_tok == ".") return CC_EMPTY;
    if (_tok == "#") return cc_new_cell(_s, CC_WALL, 0, 0, 0);
    if (_tok == "*") return cc_new_cell(_s, CC_STONE, 0, 0, 0);
    if (_tok == "C") return cc_new_cell(_s, CC_CORE, 0, 0, 0);
    var _ch = string_char_at(_tok, 1);
    var _col = cc_color_index(string_lower(_ch));
    if (_col < 0) return CC_EMPTY;
    var _cage = (_ch != string_lower(_ch));
    if (string_length(_tok) > 1) {
        var _a = string_char_at(_tok, 2);
        if (_a == "-") return cc_new_cell(_s, CC_ARROW, _col, 0, _cage);
        if (_a == "|") return cc_new_cell(_s, CC_ARROW, _col, 1, _cage);
    }
    return cc_new_cell(_s, CC_NORMAL, _col, 0, _cage);
}

function cc_color_index(_ch) {
    var _p = string_pos(_ch, "poygbr");
    return _p - 1;
}

function cc_piece_from_token(_tok) {
    if (_tok == "!") return CC_BOMB;
    if (_tok == "^") return CC_DRILL;
    if (_tok == "?") return CC_PAINT;
    return cc_color_index(_tok);
}

// Runs a solution string like "0,3 H 1,2" on a state; returns true if it wins.
function cc_play_solution(_s, _sol) {
    var _moves = string_split(_sol, " ", true);
    for (var _i = 0; _i < array_length(_moves); _i++) {
        var _m = _moves[_i];
        if (_m == "H") { cc_hold(_s); continue; }
        var _p = string_split(_m, ",");
        var _side = real(_p[0]), _lane = real(_p[1]);
        if (!cc_can_fire(_s, _side, _lane)) return false;
        cc_fire(_s, _side, _lane);
    }
    return _s.won;
}
