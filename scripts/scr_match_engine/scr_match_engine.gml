// =============================================================================
// scr_match_engine_rewrite
// Cleaner deterministic match engine for Cluster Core
//
// RULES THIS ENGINE ENFORCES
// -----------------------------------------------------------------------------
// 1. A match is always 4+ cells.
// 2. Normal color blocks can match in any 4-way connected shape.
//    That means squares, blobs, L-shapes, T-shapes, zigzags, etc.
// 3. Arrow blocks are special:
//    - They do NOT count inside blob/cluster matches.
//    - They only clear when they are part of a straight horizontal or vertical
//      line of 4+ valid same-color cells.
//    - A horizontal arrow only works in horizontal lines.
//    - A vertical arrow only works in vertical lines.
// 4. Diagonal matches are optional straight-line matches of 4+ normal blocks.
//    Arrows do not count in diagonals.
// 5. Wildcards can join any color match.
// 6. Results are deterministic: same grid in = same cells out.
// =============================================================================

#macro MATCH_MIN 4
#macro WILDCARD_ID 999


// -----------------------------------------------------------------------------
// MAIN ENTRY
// Returns an array of { x, y } cells to clear.
// -----------------------------------------------------------------------------
function find_matches_in_grid(_grid, _config, _totalRows) {
    var _cols = _config.cols;
    var _rows = _totalRows;

    var _clear = match_make_bool_grid(_cols, _rows, false);

    // Normal blocks: any connected shape of 4+.
    match_add_blob_matches(_grid, _cols, _rows, _clear);

    // Arrow blocks: only valid in straight lines.
    match_add_line_matches(_grid, _cols, _rows, _clear);

    // Optional diagonal rule. Remove this call if diagonals are no longer part
    // of the game.
    match_add_diagonal_matches(_grid, _cols, _rows, _clear);

    return match_clear_grid_to_array(_clear, _cols, _rows);
}


// -----------------------------------------------------------------------------
// GAME RULE SUMMARY
// Call this from debug UI if you want the game to explain itself.
// -----------------------------------------------------------------------------
function match_get_rules_text() {
    return
        "Match 4 or more blocks of the same color. " +
        "Normal blocks can match in any connected shape: lines, blobs, L-shapes, T-shapes, and zigzags. " +
        "Arrow blocks are stricter: they only clear inside a straight line of 4 or more blocks, and the arrow must point along that line. " +
        "Wild blocks can connect to any color. " +
        "All matches clear immediately after a block locks.";
}


// =============================================================================
// BASIC HELPERS
// =============================================================================

function match_make_bool_grid(_cols, _rows, _value) {
    var _grid = array_create(_rows);
    for (var _y = 0; _y < _rows; _y++) {
        _grid[_y] = array_create(_cols, _value);
    }
    return _grid;
}

function match_in_bounds(_cols, _rows, _x, _y) {
    return (_x >= 0 && _x < _cols && _y >= 0 && _y < _rows);
}

function match_get_cell(_grid, _cols, _rows, _x, _y) {
    if (!match_in_bounds(_cols, _rows, _x, _y)) return undefined;
    return _grid[_y][_x];
}

function match_cell_can_match(_cell) {
    if (_cell == undefined) return false;
    if (!variable_struct_exists(_cell, "id") || _cell.id <= 0) return false;
    return !match_cell_is_excluded(_cell);
}

function match_cell_has_arrow(_cell) {
    if (!match_cell_can_match(_cell)) return false;

    // Support multiple possible data formats.
    if (variable_struct_exists(_cell, "is_arrow") && _cell.is_arrow) return true;
    if (variable_struct_exists(_cell, "has_arrow") && _cell.has_arrow) return true;
    if (variable_struct_exists(_cell, "arrow_axis") && _cell.arrow_axis != undefined) return true;
    if (variable_struct_exists(_cell, "arrowDir") && _cell.arrowDir != undefined) return true;

    // Your older code treated metal as arrow blocks.
    if (variable_struct_exists(_cell, "type") && _cell.type == "metal") return true;

    return false;
}

function match_arrow_allows(_cell, _axis) {
    if (!match_cell_has_arrow(_cell)) return true;

    // Call the arrow axis check from contracts.
    return match_arrow_allows_axis(_cell, _axis);

    // Fallback support for common fields.
    if (variable_struct_exists(_cell, "arrow_axis")) {
        return (_cell.arrow_axis == _axis || _cell.arrow_axis == "both");
    }

    if (variable_struct_exists(_cell, "axis")) {
        return (_cell.axis == _axis || _cell.axis == "both");
    }

    if (variable_struct_exists(_cell, "arrowDir")) {
        var _d = _cell.arrowDir;
        if (_axis == "h") return (_d == "left" || _d == "right" || _d == "h");
        if (_axis == "v") return (_d == "up" || _d == "down" || _d == "v");
    }

    // If no direction data exists, allow it rather than softlocking the board.
    return true;
}

function match_same_color_or_wild(_cell, _colorId) {
    if (!match_cell_can_match(_cell)) return false;
    if (_cell.id == WILDCARD_ID) return true;
    return (_cell.id == _colorId);
}

function match_mark(_clear, _x, _y) {
    _clear[_y][_x] = true;
}

function match_clear_grid_to_array(_clear, _cols, _rows) {
    var _out = [];
    for (var _y = 0; _y < _rows; _y++) {
        for (var _x = 0; _x < _cols; _x++) {
            if (_clear[_y][_x]) array_push(_out, { x: _x, y: _y });
        }
    }
    return _out;
}


// =============================================================================
// BLOB MATCHES
// Normal blocks match in any connected 4-way shape.
// Arrows are ignored here because arrows only clear in lines.
//
// Important wildcard choice:
// Instead of letting a wildcard pick a color during BFS, we scan once per real
// color. This avoids weird order-dependent wildcard behavior.
// =============================================================================

function match_add_blob_matches(_grid, _cols, _rows, _clear) {
    var _colors = match_collect_normal_colors(_grid, _cols, _rows);

    for (var _c = 0; _c < array_length(_colors); _c++) {
        var _colorId = _colors[_c];
        var _visited = match_make_bool_grid(_cols, _rows, false);

        for (var _y = 0; _y < _rows; _y++) {
            for (var _x = 0; _x < _cols; _x++) {
                if (_visited[_y][_x]) continue;

                var _cell = _grid[_y][_x];

                if (!match_blob_cell_valid_for_color(_cell, _colorId)) {
                    _visited[_y][_x] = true;
                    continue;
                }

                var _blob = match_collect_blob_for_color(_grid, _cols, _rows, _x, _y, _colorId, _visited);

                if (array_length(_blob) >= MATCH_MIN) {
                    for (var i = 0; i < array_length(_blob); i++) {
                        match_mark(_clear, _blob[i].x, _blob[i].y);
                    }
                }
            }
        }
    }
}

function match_collect_normal_colors(_grid, _cols, _rows) {
    var _colors = [];

    for (var _y = 0; _y < _rows; _y++) {
        for (var _x = 0; _x < _cols; _x++) {
            var _cell = _grid[_y][_x];
            if (!match_cell_can_match(_cell)) continue;
            if (match_cell_has_arrow(_cell)) continue;
            if (_cell.id == WILDCARD_ID) continue;

            var _found = false;
            for (var i = 0; i < array_length(_colors); i++) {
                if (_colors[i] == _cell.id) {
                    _found = true;
                    break;
                }
            }

            if (!_found) array_push(_colors, _cell.id);
        }
    }

    return _colors;
}

function match_blob_cell_valid_for_color(_cell, _colorId) {
    if (!match_cell_can_match(_cell)) return false;
    if (match_cell_has_arrow(_cell)) return false;
    return match_same_color_or_wild(_cell, _colorId);
}

function match_collect_blob_for_color(_grid, _cols, _rows, _sx, _sy, _colorId, _visited) {
    var _blob = [];
    var _queue = [];
    var _head = 0;

    _visited[_sy][_sx] = true;
    array_push(_queue, { x: _sx, y: _sy });
    array_push(_blob,  { x: _sx, y: _sy });

    static _dx = [ 1, -1,  0,  0 ];
    static _dy = [ 0,  0,  1, -1 ];

    while (_head < array_length(_queue)) {
        var _n = _queue[_head++];

        for (var d = 0; d < 4; d++) {
            var _nx = _n.x + _dx[d];
            var _ny = _n.y + _dy[d];

            if (!match_in_bounds(_cols, _rows, _nx, _ny)) continue;
            if (_visited[_ny][_nx]) continue;

            var _cell = _grid[_ny][_nx];
            if (!match_blob_cell_valid_for_color(_cell, _colorId)) {
                _visited[_ny][_nx] = true;
                continue;
            }

            _visited[_ny][_nx] = true;
            var _node = { x: _nx, y: _ny };
            array_push(_queue, _node);
            array_push(_blob, _node);
        }
    }

    return _blob;
}


// =============================================================================
// LINE MATCHES
// Lines are straight horizontal or vertical runs of 4+.
// Arrows are allowed only when their axis matches the line direction.
// Normal blocks and wildcards can help form the line.
// =============================================================================

function match_add_line_matches(_grid, _cols, _rows, _clear) {
    // Horizontal rows.
    for (var _y = 0; _y < _rows; _y++) {
        match_scan_line(_grid, _cols, _rows, _clear, 0, _y, 1, 0, _cols, "h");
    }

    // Vertical columns.
    for (var _x = 0; _x < _cols; _x++) {
        match_scan_line(_grid, _cols, _rows, _clear, _x, 0, 0, 1, _rows, "v");
    }
}

function match_scan_line(_grid, _cols, _rows, _clear, _sx, _sy, _dx, _dy, _length, _axis) {
    var _run = [];
    var _runColor = -1;

    for (var i = 0; i < _length; i++) {
        var _x = _sx + _dx * i;
        var _y = _sy + _dy * i;
        var _cell = _grid[_y][_x];

        if (match_line_cell_can_join(_cell, _runColor, _axis)) {
            if (_runColor == -1 && _cell.id != WILDCARD_ID) {
                _runColor = _cell.id;
            }
            array_push(_run, { x: _x, y: _y });
        } else {
            match_flush_line(_clear, _run);
            _run = [];
            _runColor = -1;

            if (match_line_cell_can_start(_cell, _axis)) {
                if (_cell.id != WILDCARD_ID) _runColor = _cell.id;
                array_push(_run, { x: _x, y: _y });
            }
        }
    }

    match_flush_line(_clear, _run);
}

function match_line_cell_can_start(_cell, _axis) {
    if (!match_cell_can_match(_cell)) return false;
    if (match_cell_has_arrow(_cell) && !match_arrow_allows(_cell, _axis)) return false;
    return true;
}

function match_line_cell_can_join(_cell, _runColor, _axis) {
    if (!match_line_cell_can_start(_cell, _axis)) return false;

    if (_runColor == -1) return true;
    if (_cell.id == WILDCARD_ID) return true;
    return (_cell.id == _runColor);
}

function match_flush_line(_clear, _run) {
    if (array_length(_run) < MATCH_MIN) return;

    for (var i = 0; i < array_length(_run); i++) {
        match_mark(_clear, _run[i].x, _run[i].y);
    }
}


// =============================================================================
// DIAGONAL MATCHES
// Optional rule: straight diagonals of 4+ normal blocks.
// Arrows are blocked from diagonals.
// =============================================================================

function match_add_diagonal_matches(_grid, _cols, _rows, _clear) {
    // Down-right.
    for (var _sy = 0; _sy < _rows; _sy++) {
        match_scan_diagonal(_grid, _cols, _rows, _clear, 0, _sy, 1, 1);
    }
    for (var _sx = 1; _sx < _cols; _sx++) {
        match_scan_diagonal(_grid, _cols, _rows, _clear, _sx, 0, 1, 1);
    }

    // Up-right.
    for (var _sy2 = 0; _sy2 < _rows; _sy2++) {
        match_scan_diagonal(_grid, _cols, _rows, _clear, 0, _sy2, 1, -1);
    }
    for (var _sx2 = 1; _sx2 < _cols; _sx2++) {
        match_scan_diagonal(_grid, _cols, _rows, _clear, _sx2, _rows - 1, 1, -1);
    }
}

function match_scan_diagonal(_grid, _cols, _rows, _clear, _sx, _sy, _dx, _dy) {
    var _run = [];
    var _runColor = -1;
    var _x = _sx;
    var _y = _sy;

    while (match_in_bounds(_cols, _rows, _x, _y)) {
        var _cell = _grid[_y][_x];

        if (match_diag_cell_can_join(_cell, _runColor)) {
            if (_runColor == -1 && _cell.id != WILDCARD_ID) {
                _runColor = _cell.id;
            }
            array_push(_run, { x: _x, y: _y });
        } else {
            match_flush_line(_clear, _run);
            _run = [];
            _runColor = -1;

            if (match_diag_cell_can_start(_cell)) {
                if (_cell.id != WILDCARD_ID) _runColor = _cell.id;
                array_push(_run, { x: _x, y: _y });
            }
        }

        _x += _dx;
        _y += _dy;
    }

    match_flush_line(_clear, _run);
}

function match_diag_cell_can_start(_cell) {
    if (!match_cell_can_match(_cell)) return false;
    if (match_cell_has_arrow(_cell)) return false;
    return true;
}

function match_diag_cell_can_join(_cell, _runColor) {
    if (!match_diag_cell_can_start(_cell)) return false;

    if (_runColor == -1) return true;
    if (_cell.id == WILDCARD_ID) return true;
    return (_cell.id == _runColor);
}


// =============================================================================
// DEBUG HELPERS
// =============================================================================

function debug_largest_blob_size() {
    var _cols = global.TOTAL_COLS;
    var _rows = global.TOTAL_ROWS;
    var _colors = match_collect_normal_colors(global.grid, _cols, _rows);
    var _best = 0;

    for (var _c = 0; _c < array_length(_colors); _c++) {
        var _colorId = _colors[_c];
        var _visited = match_make_bool_grid(_cols, _rows, false);

        for (var _y = 0; _y < _rows; _y++) {
            for (var _x = 0; _x < _cols; _x++) {
                if (_visited[_y][_x]) continue;

                var _cell = global.grid[_y][_x];
                if (!match_blob_cell_valid_for_color(_cell, _colorId)) {
                    _visited[_y][_x] = true;
                    continue;
                }

                var _blob = match_collect_blob_for_color(global.grid, _cols, _rows, _x, _y, _colorId, _visited);
                _best = max(_best, array_length(_blob));
            }
        }
    }

    return _best;
}
