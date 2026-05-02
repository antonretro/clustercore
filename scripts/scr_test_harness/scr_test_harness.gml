// ── Test Harness Framework ───────────────────────────────────────────────

// ── Suite/Case registration ──────────────────────────────────────────────

function test_suite_create(_name) {
    var _s = { name: _name, cases: [] };
    array_push(global.__test_suites, _s);
    return _s;
}

function test_case_create(_suite, _name, _func) {
    var _c = { name: _name, func: _func, status: "PENDING", message: "" };
    array_push(_suite.cases, _c);
    return _c;
}

// ── Assertions ────────────────────────────────────────────────────────────

function test_assert(_condition, _failMessage) {
    if (!_condition) {
        global.__test_current_case.status = "FAIL";
        global.__test_current_case.message = _failMessage;
        global.__test_failed++;
        if (global.__test_log_fp >= 0) {
            file_text_write_string(global.__test_log_fp, "[FAIL] ");
            file_text_write_string(global.__test_log_fp, string(global.__test_current_suite_name));
            file_text_write_string(global.__test_log_fp, " :: ");
            file_text_write_string(global.__test_log_fp, string(global.__test_current_case_name));
            file_text_writeln(global.__test_log_fp);
            file_text_write_string(global.__test_log_fp, "       ");
            file_text_write_string(global.__test_log_fp, _failMessage);
            file_text_writeln(global.__test_log_fp);
        }
        return false;
    }
    return true;
}

function test_assert_equal(_actual, _expected, _msg) {
    if (_actual != _expected) {
        var _fullMsg = _msg + " — expected " + string(_expected) + ", got " + string(_actual);
        test_assert(false, _fullMsg);
        return false;
    }
    return true;
}

function test_assert_array_size(_arr, _expected, _msg) {
    test_assert_equal(array_length(_arr), _expected, _msg);
}

function test_assert_grid_cell(_grid, _x, _y, _expectedType, _expectedId, _msg) {
    var _cell = _grid[_y][_x];
    if (_expectedType == "undefined") {
        test_assert(_cell == undefined, _msg + " — cell at " + string(_x) + "," + string(_y) + " should be undefined");
        return;
    }
    test_assert(_cell != undefined, _msg + " — cell at " + string(_x) + "," + string(_y) + " is undefined, expected " + _expectedType);
    if (_cell != undefined) {
        test_assert_equal(_cell.type, _expectedType, _msg + " — type mismatch at " + string(_x) + "," + string(_y));
        test_assert_equal(_cell.id, _expectedId, _msg + " — id mismatch at " + string(_x) + "," + string(_y));
    }
}

// ── Grid builders for tests ───────────────────────────────────────────────

function test_make_empty_grid(_cols, _rows) {
    var _grid = [];
    for (var _y = 0; _y < _rows; _y++) {
        _grid[_y] = array_create(_cols);
        for (var _x = 0; _x < _cols; _x++) {
            _grid[_y][_x] = undefined;
        }
    }
    return _grid;
}

function test_make_test_cell(_type, _id, _dir) {
    var _c = {
        type: _type,
        id: _id,
        dir: is_undefined(_dir) ? 0 : _dir,
        color: get_color_from_id(_id),
        shard_value: 0,
        locked_hp: 0,
        special_value: 0,
        shield_hp: 0,
        core_arrow: false,
        inst: undefined  // no instance for match/contract tests
    };
    if (_type == "asteroid") _c.shield_hp = 2;
    if (_type == "locked") _c.locked_hp = 2;
    if (_type == "multiplier") _c.special_value = 2;
    if (_type == "wild") { _c.id = 999; _c.color = c_white; }
    if (_type == "core") _c.core_arrow = false;
    if (_type == "bomb") _c.id = 888;
    if (_type == "drill") _c.id = 777;
    if (_type == "void") _c.id = 0;
    return _c;
}

function test_place_cell(_grid, _x, _y, _cell) {
    _grid[_y][_x] = _cell;
}

function test_fill_line(_grid, _x1, _y1, _x2, _y2, _cellFunc) {
    var _dx = sign(_x2 - _x1);
    var _dy = sign(_y2 - _y1);
    if (_dx == 0 && _dy == 0) {
        _grid[_y1][_x1] = _cellFunc();
        return;
    }
    var _steps = max(abs(_x2 - _x1), abs(_y2 - _y1));
    for (var _i = 0; _i <= _steps; _i++) {
        var _x = _x1 + _dx * _i;
        var _y = _y1 + _dy * _i;
        _grid[_y][_x] = _cellFunc();
    }
}

// ── State isolation ───────────────────────────────────────────────────────

function test_with_grid_sandbox(_func) {
    var _oldGrid = global.grid;
    var _oldCols = global.TOTAL_COLS;
    var _oldRows = global.TOTAL_ROWS;
    var _oldHiddenSides = global.HIDDEN_SIDES;
    var _oldHiddenRows = global.HIDDEN_ROWS;
    var _oldMode = global.gameMode;
    var _oldColors = global.activeColors;
    var _oldReserve = global.reserveColors;

    global.grid = test_make_empty_grid(11, 11);
    global.TOTAL_COLS = 11;
    global.TOTAL_ROWS = 11;
    global.HIDDEN_SIDES = 1;
    global.HIDDEN_ROWS = 1;
    global.gameMode = "PLANET";
    global.activeColors = [1, 2, 3, 4, 5, 6];
    global.reserveColors = [];

    _func();

    global.grid = _oldGrid;
    global.TOTAL_COLS = _oldCols;
    global.TOTAL_ROWS = _oldRows;
    global.HIDDEN_SIDES = _oldHiddenSides;
    global.HIDDEN_ROWS = _oldHiddenRows;
    global.gameMode = _oldMode;
    global.activeColors = _oldColors;
    global.reserveColors = _oldReserve;
}

// ── Logging ───────────────────────────────────────────────────────────────

function test_log_open() {
    var _dateStr = string_replace_all(string_replace_all(date_current_datetime(), ":", "-"), " ", "_");
    var _filename = "test_log_" + _dateStr + ".txt";
    global.__test_log_fp = file_text_open_write(_filename);
    file_text_write_string(global.__test_log_fp, "=== Cluster Core Test Harness Log ===");
    file_text_writeln(global.__test_log_fp);
    file_text_write_string(global.__test_log_fp, "Date: " + string(date_current_datetime()));
    file_text_writeln(global.__test_log_fp);
    file_text_writeln(global.__test_log_fp);
}

function test_log_write(_text) {
    if (global.__test_log_fp < 0) return;
    file_text_write_string(global.__test_log_fp, _text);
    file_text_writeln(global.__test_log_fp);
}

function test_log_close() {
    if (global.__test_log_fp >= 0) {
        file_text_close(global.__test_log_fp);
        global.__test_log_fp = -1;
    }
}

// ── Runner ────────────────────────────────────────────────────────────────

function test_runner_init() {
    global.__test_suites = [];
    global.__test_passed = 0;
    global.__test_failed = 0;
    global.__test_total = 0;
    global.__test_done = false;
    global.__test_cursor_suite = 0;
    global.__test_cursor_case = 0;
    global.__test_batch_size = 10;
    global.__test_current_suite_name = "";
    global.__test_current_case_name = "";
    global.__test_current_case = undefined;
    global.__test_log_fp = -1;

    if (variable_global_exists("COLOR_ACCENT")) global.COLOR_ACCENT = make_color_rgb(100, 150, 255);
    if (variable_global_exists("COLOR_GLOW")) global.COLOR_GLOW = make_color_rgb(255, 200, 100);
    if (variable_global_exists("COLOR_DANGER")) global.COLOR_DANGER = make_color_rgb(255, 50, 50);

    test_log_open();
}

function test_runner_register_all() {
    test_match_engine_register_tests();
    test_contracts_register_tests();
    test_level_gen_register_tests();
    test_gravity_register_tests();

    for (var _i = 0; _i < array_length(global.__test_suites); _i++) {
        global.__test_total += array_length(global.__test_suites[_i].cases);
    }
}

function test_runner_step() {
    var _remaining = global.__test_batch_size;
    var _sLen = array_length(global.__test_suites);
    var _done = true;

    while (_remaining > 0 && global.__test_cursor_suite < _sLen) {
        var _suite = global.__test_suites[global.__test_cursor_suite];
        if (global.__test_cursor_case >= array_length(_suite.cases)) {
            global.__test_cursor_suite++;
            global.__test_cursor_case = 0;
            _done = false;
            continue;
        }

        var _case = _suite.cases[global.__test_cursor_case];
        global.__test_current_suite_name = _suite.name;
        global.__test_current_case_name = _case.name;
        global.__test_current_case = _case;
        _case.status = "PASS";

        _case.func();

        if (_case.status == "PASS") {
            global.__test_passed++;
            test_log_write("[PASS] " + _suite.name + " :: " + _case.name);
        }

        global.__test_cursor_case++;
        _remaining--;
        _done = false;
    }

    if (global.__test_cursor_suite >= _sLen) {
        global.__test_done = true;
        test_log_write("");
        test_log_write("=== COMPLETE ===");
        test_log_write("Passed: " + string(global.__test_passed) + "  Failed: " + string(global.__test_failed));
        test_log_write("Total:  " + string(global.__test_total));
        test_log_close();
    }
}

function test_runner_draw(_yOffset) {
    var _gw = display_get_gui_width();
    var _y = _yOffset;
    var _lineH = 20;
    var _colW = _gw / array_length(global.__test_suites);

    if (array_length(global.__test_suites) == 0) {
        draw_set_color(c_white);
        draw_text(40, _y, "No test suites registered.");
        return;
    }

    for (var _s = 0; _s < array_length(global.__test_suites); _s++) {
        var _suite = global.__test_suites[_s];
        var _sx = 40 + _s * _colW;
        var _sy = _y;

        draw_set_color(make_color_rgb(255, 220, 100));
        draw_set_halign(fa_left);
        draw_text(_sx, _sy, string(_s + 1) + ". " + _suite.name);
        _sy += 24;

        for (var _c = 0; _c < array_length(_suite.cases); _c++) {
            var _case = _suite.cases[_c];
            if (_case.status == "PENDING") break;

            var _col = (_case.status == "FAIL") ? make_color_rgb(255, 80, 80) : make_color_rgb(100, 220, 100);
            draw_set_color(_col);
            draw_text(_sx + 8, _sy, (_case.status == "FAIL" ? "[X] " : "[v] ") + _case.name);

            if (_case.status == "FAIL" && _case.message != "") {
                draw_set_color(make_color_rgb(255, 150, 130));
                draw_text(_sx + 16, _sy + _lineH, _case.message);
                _sy += _lineH;
            }
            _sy += _lineH;
        }
        _y = max(_y, _sy);
    }
}
