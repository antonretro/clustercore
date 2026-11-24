// =============================================================================
// scr_cc_levels - campaign data (datafiles/levels.txt), worlds, save data
// =============================================================================

function cc_worlds() {
    static _w = [
        { name: "MERCURY", blurb: "First contact",       spr: spr_mercury,   col: $5c8aff, bg: $1c0f1a },
        { name: "VENUS",   blurb: "Stone rain",          spr: spr_venus,     col: $66d1ff, bg: $10161c },
        { name: "EARTH",   blurb: "Locked in",           spr: spr_earth,     col: $f0c94c, bg: $26160d },
        { name: "MARS",    blurb: "Straight lines",      spr: spr_mars,      col: $6f47ef, bg: $120c1e },
        { name: "JUPITER", blurb: "Heavy tools",         spr: spr_jupiter,   col: $59a2f4, bg: $0c121c },
        { name: "NEPTUNE", blurb: "The deep core",       spr: spr_neptune,   col: $ff8c7b, bg: $220f0c },
    ];
    return _w;
}

function cc_load_levels() {
    var _levels = [];
    var _path = "levels.txt";
    if (!file_exists(_path)) {
        show_debug_message("[CC] levels.txt missing");
        return _levels;
    }
    var _f = file_text_open_read(_path);
    var _cur = undefined;
    while (!file_text_eof(_f)) {
        var _line = string_trim(file_text_read_string(_f));
        file_text_readln(_f);
        if (_line == "" || string_starts_with(_line, "//")) continue;
        if (string_starts_with(_line, "@")) {
            _cur = { name: string_trim(string_delete(_line, 1, 1)), world: 0, core: [], queue: [], par: 0, sol: "", tip: "", rows: [] };
            array_push(_levels, _cur);
            continue;
        }
        if (_cur == undefined) continue;
        if (_line == "grid") {
            while (!file_text_eof(_f)) {
                var _row = string_trim(file_text_read_string(_f));
                file_text_readln(_f);
                if (_row == "end") break;
                array_push(_cur.rows, string_split(_row, " ", true));
            }
            continue;
        }
        var _sp = string_pos(" ", _line);
        var _key = (_sp > 0) ? string_copy(_line, 1, _sp - 1) : _line;
        var _val = (_sp > 0) ? string_trim(string_delete(_line, 1, _sp)) : "";
        switch (_key) {
            case "world": _cur.world = real(_val); break;
            case "par":   _cur.par = real(_val); break;
            case "sol":   _cur.sol = _val; break;
            case "tip":   _cur.tip = _val; break;
            case "core":
                var _t = string_split(_val, " ", true);
                for (var _i = 0; _i < array_length(_t); _i++) array_push(_cur.core, cc_color_index(_t[_i]));
                break;
            case "queue":
                var _q = string_split(_val, " ", true);
                for (var _i = 0; _i < array_length(_q); _i++) array_push(_cur.queue, cc_piece_from_token(_q[_i]));
                break;
        }
    }
    file_text_close(_f);
    return _levels;
}

// Levels of one world, as indexes into global.levels
function cc_world_levels(_w) {
    var _out = [];
    for (var _i = 0; _i < array_length(global.levels); _i++) {
        if (global.levels[_i].world == _w) array_push(_out, _i);
    }
    return _out;
}

function cc_stars_for(_lv, _shots) {
    if (_shots <= _lv.par) return 3;
    if (_shots <= _lv.par + 2) return 2;
    return 1;
}


// ── save data ────────────────────────────────────────────────────────────────
#macro CC_SAVE "clustercore_v2.ini"

function cc_save_load() {
    global.save = { stars: array_create(array_length(global.levels), 0), endless_best: 0,
                    sfx: 0.8, shake: true, flash: true, seen_tips: {} };
    ini_open(CC_SAVE);
    for (var _i = 0; _i < array_length(global.levels); _i++) {
        global.save.stars[_i] = ini_read_real("stars", global.levels[_i].name, 0);
    }
    global.save.endless_best = ini_read_real("endless", "best", 0);
    global.save.sfx   = ini_read_real("options", "sfx", 0.8);
    global.save.shake = ini_read_real("options", "shake", 1) == 1;
    global.save.flash = ini_read_real("options", "flash", 1) == 1;
    ini_close();
}

function cc_save_write() {
    ini_open(CC_SAVE);
    for (var _i = 0; _i < array_length(global.levels); _i++) {
        if (global.save.stars[_i] > 0) ini_write_real("stars", global.levels[_i].name, global.save.stars[_i]);
    }
    ini_write_real("endless", "best", global.save.endless_best);
    ini_write_real("options", "sfx", global.save.sfx);
    ini_write_real("options", "shake", global.save.shake ? 1 : 0);
    ini_write_real("options", "flash", global.save.flash ? 1 : 0);
    ini_close();
}

function cc_total_stars() {
    var _t = 0;
    for (var _i = 0; _i < array_length(global.save.stars); _i++) _t += global.save.stars[_i];
    return _t;
}

// A level is open if it is the first, or the one before it is beaten.
// A world is open if the last world has at least 4 levels beaten.
function cc_level_open(_i) {
    if (global.save.stars[_i] > 0) return true;
    var _w = global.levels[_i].world;
    if (!cc_world_open(_w)) return false;
    if (_i == 0 || global.levels[_i - 1].world != _w) return true;
    return global.save.stars[_i - 1] > 0;
}

function cc_world_open(_w) {
    if (_w == 0) return true;
    var _prev = cc_world_levels(_w - 1);
    var _beat = 0;
    for (var _i = 0; _i < array_length(_prev); _i++) if (global.save.stars[_prev[_i]] > 0) _beat++;
    return _beat >= min(4, array_length(_prev));
}
