// =============================================================================
// MATCH SYSTEM — Clean optimized version
// =============================================================================
//
// Rules:
// - 4+ connected orthogonal cluster clears.
// - 4+ horizontal / vertical line clears.
// - 4+ diagonal line clears.
// - Bomb / dead / excluded cells do not match.
// - Metal / directional blocks only match if match_cells_can_link allows it.
// - No global spill pass unless you intentionally enable it.
// =============================================================================


// -----------------------------------------------------------------------------
// MAIN ENTRY
// -----------------------------------------------------------------------------
function find_matches_in_grid(_grid, _config, _totalRows) {
    var _cols = _config.cols;

    var _clear_grid = make_bool_grid(_cols, _totalRows, false);

    add_cluster_matches(_grid, _cols, _totalRows, _clear_grid);
    add_line_matches(_grid, _cols, _totalRows, _clear_grid);
    add_diagonal_matches(_grid, _cols, _totalRows, _clear_grid);

    // Optional rule:
    // Only enable this if you WANT a matched line/cluster to pull in the full
    // connected blob of the same color.
    //
    // expand_clear_to_same_color_blobs(_grid, _cols, _totalRows, _clear_grid);

    var _matches = [];

    for (var _y = 0; _y < _totalRows; _y++) {
        for (var _x = 0; _x < _cols; _x++) {
            if (_clear_grid[_y][_x]) {
                array_push(_matches, { x: _x, y: _y });
            }
        }
    }

    return _matches;
}


// -----------------------------------------------------------------------------
// BASIC HELPERS
// -----------------------------------------------------------------------------
function make_bool_grid(_cols, _rows, _value) {
    var _grid = array_create(_rows);

    for (var _y = 0; _y < _rows; _y++) {
        _grid[_y] = array_create(_cols, _value);
    }

    return _grid;
}


function cell_exists(_grid, _cols, _rows, _x, _y) {
    if (_x < 0 || _x >= _cols) return false;
    if (_y < 0 || _y >= _rows) return false;
    return _grid[_y][_x] != undefined;
}


function cell_can_match(_cell) {
    if (_cell == undefined) return false;
    if (_cell.type == "bomb") return false;
    if (_cell.type == "dead") return false;

    // Uses your existing exclusion logic if it exists.
    return !match_cell_is_excluded(_cell);
}


function cells_can_match_axis(_a, _b, _axis, _allow_directional) {
    if (!cell_can_match(_a)) return false;
    if (!cell_can_match(_b)) return false;

    // Uses your existing color / metal / arrow logic.
    return match_cells_can_link(_a, _b, _axis, _allow_directional);
}


function mark_cell(_clear_grid, _x, _y) {
    _clear_grid[_y][_x] = true;
}


// -----------------------------------------------------------------------------
// CLUSTER MATCHES
// 4+ orthogonally connected cells.
// -----------------------------------------------------------------------------
function add_cluster_matches(_grid, _cols, _rows, _clear_grid) {
    var _visited = make_bool_grid(_cols, _rows, false);

    for (var _y = 0; _y < _rows; _y++) {
        for (var _x = 0; _x < _cols; _x++) {
            if (_visited[_y][_x]) continue;

            var _cell = _grid[_y][_x];

            if (!cell_can_match(_cell)) {
                _visited[_y][_x] = true;
                continue;
            }

            var _cluster = collect_cluster(_grid, _cols, _rows, _x, _y, _visited);

            if (array_length(_cluster) >= 4) {
                for (var i = 0; i < array_length(_cluster); i++) {
                    var _p = _cluster[i];
                    mark_cell(_clear_grid, _p.x, _p.y);
                }
            }
        }
    }
}


function collect_cluster(_grid, _cols, _rows, _startX, _startY, _visited) {
    var _cluster = [];
    var _queue = [];

    var _start = { x: _startX, y: _startY };
    array_push(_queue, _start);
    array_push(_cluster, _start);

    _visited[_startY][_startX] = true;

    var _head = 0;

    while (_head < array_length(_queue)) {
        var _current = _queue[_head++];
        var _cell = _grid[_current.y][_current.x];

        // Right
        try_add_cluster_neighbor(_grid, _cols, _rows, _visited, _queue, _cluster, _cell, _current.x + 1, _current.y, "h");

        // Left
        try_add_cluster_neighbor(_grid, _cols, _rows, _visited, _queue, _cluster, _cell, _current.x - 1, _current.y, "h");

        // Down
        try_add_cluster_neighbor(_grid, _cols, _rows, _visited, _queue, _cluster, _cell, _current.x, _current.y + 1, "v");

        // Up
        try_add_cluster_neighbor(_grid, _cols, _rows, _visited, _queue, _cluster, _cell, _current.x, _current.y - 1, "v");
    }

    return _cluster;
}


function try_add_cluster_neighbor(_grid, _cols, _rows, _visited, _queue, _cluster, _cell, _nx, _ny, _axis) {
    if (_nx < 0 || _nx >= _cols || _ny < 0 || _ny >= _rows) return;
    if (_visited[_ny][_nx]) return;

    var _neighbor = _grid[_ny][_nx];

    // false = do not allow directional metal to join random clusters unless your link function allows it.
    if (!cells_can_match_axis(_cell, _neighbor, _axis, false)) return;

    _visited[_ny][_nx] = true;

    var _node = { x: _nx, y: _ny };
    array_push(_queue, _node);
    array_push(_cluster, _node);
}


// -----------------------------------------------------------------------------
// HORIZONTAL / VERTICAL LINE MATCHES
// 4+ cells in a straight line.
// -----------------------------------------------------------------------------
function add_line_matches(_grid, _cols, _rows, _clear_grid) {
    // Horizontal
    for (var _y = 0; _y < _rows; _y++) {
        var _run_start = 0;
        var _run_count = 1;

        for (var _x = 1; _x <= _cols; _x++) {
            var _continues = false;

            if (_x < _cols) {
                var _prev = _grid[_y][_x - 1];
                var _curr = _grid[_y][_x];

                // true = directional blocks can participate if their axis allows it.
                _continues = cells_can_match_axis(_prev, _curr, "h", true);
            }

            if (_continues) {
                _run_count++;
            } else {
                if (_run_count >= 4) {
                    for (var i = 0; i < _run_count; i++) {
                        mark_cell(_clear_grid, _run_start + i, _y);
                    }
                }

                _run_start = _x;
                _run_count = 1;
            }
        }
    }

    // Vertical
    for (var _x = 0; _x < _cols; _x++) {
        var _run_start_y = 0;
        var _run_count_y = 1;

        for (var _y = 1; _y <= _rows; _y++) {
            var _continues_y = false;

            if (_y < _rows) {
                var _prev_y = _grid[_y - 1][_x];
                var _curr_y = _grid[_y][_x];

                _continues_y = cells_can_match_axis(_prev_y, _curr_y, "v", true);
            }

            if (_continues_y) {
                _run_count_y++;
            } else {
                if (_run_count_y >= 4) {
                    for (var j = 0; j < _run_count_y; j++) {
                        mark_cell(_clear_grid, _x, _run_start_y + j);
                    }
                }

                _run_start_y = _y;
                _run_count_y = 1;
            }
        }
    }
}


// -----------------------------------------------------------------------------
// DIAGONAL MATCHES
// 4+ cells in either diagonal direction.
// This version checks neighbor-to-neighbor, not every cell against the first.
// -----------------------------------------------------------------------------
function add_diagonal_matches(_grid, _cols, _rows, _clear_grid) {
    // Down-right diagonals
    for (var _startY = 0; _startY < _rows; _startY++) {
        scan_diagonal(_grid, _cols, _rows, _clear_grid, 0, _startY, 1, 1);
    }

    for (var _startX = 1; _startX < _cols; _startX++) {
        scan_diagonal(_grid, _cols, _rows, _clear_grid, _startX, 0, 1, 1);
    }

    // Up-right diagonals
    for (var _startY2 = 0; _startY2 < _rows; _startY2++) {
        scan_diagonal(_grid, _cols, _rows, _clear_grid, 0, _startY2, 1, -1);
    }

    for (var _startX2 = 1; _startX2 < _cols; _startX2++) {
        scan_diagonal(_grid, _cols, _rows, _clear_grid, _startX2, _rows - 1, 1, -1);
    }
}


function scan_diagonal(_grid, _cols, _rows, _clear_grid, _sx, _sy, _dx, _dy) {
    var _run = [];

    var _x = _sx;
    var _y = _sy;

    while (_x >= 0 && _x < _cols && _y >= 0 && _y < _rows) {
        var _cell = _grid[_y][_x];

        if (!cell_can_match(_cell)) {
            mark_diagonal_run_if_valid(_clear_grid, _run);
            _run = [];
        } else {
            if (array_length(_run) == 0) {
                array_push(_run, { x: _x, y: _y });
            } else {
                var _last = _run[array_length(_run) - 1];
                var _prev = _grid[_last.y][_last.x];

                if (cells_can_match_axis(_prev, _cell, "d", false)) {
                    array_push(_run, { x: _x, y: _y });
                } else {
                    mark_diagonal_run_if_valid(_clear_grid, _run);
                    _run = [];
                    array_push(_run, { x: _x, y: _y });
                }
            }
        }

        _x += _dx;
        _y += _dy;
    }

    mark_diagonal_run_if_valid(_clear_grid, _run);
}


function mark_diagonal_run_if_valid(_clear_grid, _run) {
    if (array_length(_run) < 4) return;

    for (var i = 0; i < array_length(_run); i++) {
        var _p = _run[i];
        mark_cell(_clear_grid, _p.x, _p.y);
    }
}


// -----------------------------------------------------------------------------
// OPTIONAL: EXPAND CLEAR INTO SAME-COLOR BLOBS
// Only use this if this is actually a game rule.
// This is safer than the old global spill pass because it still uses the same
// matching exclusion rules.
// -----------------------------------------------------------------------------
function expand_clear_to_same_color_blobs(_grid, _cols, _rows, _clear_grid) {
    var _visited = make_bool_grid(_cols, _rows, false);
    var _queue = [];

    for (var _y = 0; _y < _rows; _y++) {
        for (var _x = 0; _x < _cols; _x++) {
            if (!_clear_grid[_y][_x]) continue;

            var _cell = _grid[_y][_x];
            if (!cell_can_match(_cell)) continue;

            _visited[_y][_x] = true;
            array_push(_queue, { x: _x, y: _y, id: _cell.id });
        }
    }

    var _head = 0;

    while (_head < array_length(_queue)) {
        var _n = _queue[_head++];

        try_expand_same_color(_grid, _cols, _rows, _clear_grid, _visited, _queue, _n, _n.x + 1, _n.y, "h");
        try_expand_same_color(_grid, _cols, _rows, _clear_grid, _visited, _queue, _n, _n.x - 1, _n.y, "h");
        try_expand_same_color(_grid, _cols, _rows, _clear_grid, _visited, _queue, _n, _n.x, _n.y + 1, "v");
        try_expand_same_color(_grid, _cols, _rows, _clear_grid, _visited, _queue, _n, _n.x, _n.y - 1, "v");
    }
}


function try_expand_same_color(_grid, _cols, _rows, _clear_grid, _visited, _queue, _from, _nx, _ny, _axis) {
    if (_nx < 0 || _nx >= _cols || _ny < 0 || _ny >= _rows) return;
    if (_visited[_ny][_nx]) return;

    var _cell = _grid[_ny][_nx];
    var _from_cell = _grid[_from.y][_from.x];

    if (!cell_can_match(_cell)) return;
    if (_cell.id != _from.id) return;

    // Important: still respect your real match rules.
    if (!cells_can_match_axis(_from_cell, _cell, _axis, false)) return;

    _visited[_ny][_nx] = true;
    _clear_grid[_ny][_nx] = true;

    array_push(_queue, { x: _nx, y: _ny, id: _from.id });
}


// -----------------------------------------------------------------------------
// DEBUG
// -----------------------------------------------------------------------------
function debug_largest_cluster_size() {
    var _visited = make_bool_grid(global.TOTAL_COLS, global.TOTAL_ROWS, false);
    var _best = 0;

    for (var _y = 0; _y < global.TOTAL_ROWS; _y++) {
        for (var _x = 0; _x < global.TOTAL_COLS; _x++) {
            if (_visited[_y][_x]) continue;

            var _cell = global.grid[_y][_x];

            if (!cell_can_match(_cell)) {
                _visited[_y][_x] = true;
                continue;
            }

            var _cluster = collect_cluster(
                global.grid,
                global.TOTAL_COLS,
                global.TOTAL_ROWS,
                _x,
                _y,
                _visited
            );

            _best = max(_best, array_length(_cluster));
        }
    }

    return _best;
}