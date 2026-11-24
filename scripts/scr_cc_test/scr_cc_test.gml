// =============================================================================
// scr_cc_test - self-test, run with:  ClusterCore.exe --autotest
// 1. replays every level's stored solution in the real rules: must win at par
// 2. drives the menus and a few levels by fake input, saving screenshots
// Results are printed as [TEST] lines; the game closes itself when done.
// =============================================================================

function cc_test_wanted() {
    for (var _i = 0; _i < parameter_count(); _i++) if (parameter_string(_i) == "--autotest") return true;
    return false;
}

function cc_test_rules() {
    var _pass = 0, _fail = 0;
    for (var _i = 0; _i < array_length(global.levels); _i++) {
        var _lv = global.levels[_i];
        var _st = cc_state_from_level(_lv);
        // start board must be settled with nothing to clear
        var _probe = cc_state_copy(_st);
        var _ph = [];
        cc_resolve(_probe, _ph);
        if (array_length(_ph) > 0) { show_debug_message("[TEST] FAIL level " + string(_i) + " " + _lv.name + ": start board not settled"); _fail++; continue; }
        if (_lv.sol == "") { show_debug_message("[TEST] FAIL level " + string(_i) + " " + _lv.name + ": no solution stored"); _fail++; continue; }
        var _won = cc_play_solution(_st, _lv.sol);
        if (_won && _st.shots == _lv.par) _pass++;
        else { _fail++; show_debug_message("[TEST] FAIL level " + string(_i) + " " + _lv.name + ": won=" + string(_won) + " shots=" + string(_st.shots) + " par=" + string(_lv.par)); }
    }
    show_debug_message("[TEST] rules: " + string(_pass) + " levels solved at par, " + string(_fail) + " failed, of " + string(array_length(global.levels)));
}

// Scripted tour. Each entry: [frame, action]  where action is an input name,
// "shot:<file>" to save a screenshot, or "do:<thing>".
function cc_test_script() {
    return [
        [40,  "shot:01_title"],
        [50,  "ok"],
        [90,  "shot:02_menu"],
        [95,  "ok"],
        [140, "shot:03_map"],
        [145, "ok"],
        [190, "shot:04_level1"],
        [195, "left"],
        [200, "left"],
        [210, "shot:05_aim"],
        [215, "do:solve_step"],
        [222, "shot:06_flight"],
        [260, "do:solve_step"],
        [275, "shot:07_pop"],
        [380, "shot:08_win"],
        [390, "do:level:3"],
        [420, "rotl"],
        [445, "shot:09_turned"],
        [450, "do:solve_step"],
        [462, "shot:10_chain_a"],
        [480, "shot:10_chain_b"],
        [520, "do:level_world:2"],
        [560, "shot:11_world3"],
        [565, "do:level_world:3"],
        [600, "shot:12_world4"],
        [605, "do:level_world:5"],
        [640, "shot:13_world6"],
        [645, "pause"],
        [660, "shot:14_pause"],
        [665, "pause"],
        [670, "do:endless"],
        [700, "shot:15_endless"],
        [705, "do:endless_shots"],
        [900, "shot:16_endless_later"],
        [905, "do:map_world:2"],
        [930, "shot:17_map_earth"],
        [935, "do:options"],
        [960, "shot:18_options"],
        [980, "do:quit"],
    ];
}

function cc_test_step() {
    var _T = global.test;
    _T.frame++;
    var _sc = cc_test_script();
    for (var _i = 0; _i < array_length(_sc); _i++) {
        if (_sc[_i][0] != _T.frame) continue;
        var _a = _sc[_i][1];
        if (string_starts_with(_a, "shot:")) { _T.shot = string_delete(_a, 1, 5); continue; }
        if (string_starts_with(_a, "do:")) { cc_test_do(string_delete(_a, 1, 3)); continue; }
        array_push(global.inp_script, _a);
    }
    if (_T.endless_left > 0 && global.scene == "play" && !global.play.busy && global.play.result == "") {
        _T.endless_left--;
        // aim at a random lane that can take a shot
        var _P = global.play;
        repeat (20) { _P.side = irandom(3); _P.lane = irandom(_P.st.n - 1); if (cc_can_fire(_P.st, _P.side, _P.lane)) break; }
        _P.ang_to = _P.side * 90; _P.ang = _P.ang_to;
        cc_play_fire();
    }
}

function cc_test_do(_what) {
    var _p = string_split(_what, ":");
    switch (_p[0]) {
        case "solve_step":
            var _P = global.play;
            var _m = _P.sol[array_length(_P.moves)];
            if (_m == "H") { cc_hold(_P.st); array_push(_P.moves, "H"); _m = _P.sol[array_length(_P.moves)]; }
            var _q = string_split(_m, ",");
            _P.side = real(_q[0]); _P.lane = real(_q[1]);
            _P.ang_to = _P.side * 90; _P.ang = _P.ang_to;
            cc_play_fire();
            break;
        case "level":
            cc_play_start_level(real(_p[1])); cc_goto("play");
            break;
        case "level_world":
            var _wl = cc_world_levels(real(_p[1]));
            if (array_length(_wl) > 0) { cc_play_start_level(_wl[min(2, array_length(_wl) - 1)]); cc_goto("play"); }
            break;
        case "endless": cc_play_start_endless(); cc_goto("play"); break;
        case "endless_shots": global.test.endless_left = 14; break;
        case "map_world": global.map_world = real(_p[1]); global.map_sel = 1; cc_goto("map"); break;
        case "options": global.options_return = "menu"; cc_goto("options"); break;
        case "quit":
            show_debug_message("[TEST] tour finished, " + string(global.test.shots) + " screenshots");
            game_end();
            break;
    }
}

// call from Post Draw
function cc_test_post_draw() {
    var _T = global.test;
    if (_T.shot == "") return;
    surface_save(application_surface, "shots/" + _T.shot + ".png");
    _T.shots++;
    _T.shot = "";
}
