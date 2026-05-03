// =============================================================================
// MATCH SYSTEM — Clean rewrite
// =============================================================================
//
// Rules (no exceptions, no edge-case leakage):
// - 3+ connected orthogonal cluster clears (normal blocks only)
// - 3+ horizontal / vertical line clears (normal blocks); 4+ if any arrow block present
// - 4+ diagonal line clears (normal blocks only)
// - Metal / arrow blocks: only clear in LINES of 4+ along their arrow axis
// - Wilds (id=999): universal color, can bridge clusters and lines
// - Excluded types (bomb/dead/drill/void/asteroid): never match
// - Cells with id <= 0: never participate in matching
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

    var _matches = [];
    for (var _y = 0; _y < _totalRows; _y++) {
        for (var _x = 0; _x < _cols; _x++) {
            if (_clear_grid[_y][_x]) array_push(_matches, { x: _x, y: _y });
        }
    }
    return _matches;
}


// -----------------------------------------------------------------------------
// GRID + CELL HELPERS
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
    return !match_cell_is_excluded(_cell);
}

function cell_has_arrow(_cell) {
    if (_cell == undefined) return false;
    // Metal blocks are always arrows. 
    // Core blocks can have arrows, but they should still match in clusters to avoid stalemates.
    if (_cell.type == "metal") return true;
    return false;
}

function mark_cell(_clear_grid, _x, _y) {
    _clear_grid[_y][_x] = true;
}


// -----------------------------------------------------------------------------
// CLUSTER MATCHES — 3+ orthogonally connected, no arrows
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

            // Arrows never participate in clusters
            if (cell_has_arrow(_cell)) {
                _visited[_y][_x] = true;
                continue;
            }

            var _cluster = collect_cluster(_grid, _cols, _rows, _x, _y, _visited);
            if (array_length(_cluster) >= 4) {
                for (var i = 0; i < array_length(_cluster); i++) {
                    mark_cell(_clear_grid, _cluster[i].x, _cluster[i].y);
                }
            }

            // Unmark wildcards so they can bridge multiple clusters
            for (var i = 0; i < array_length(_cluster); i++) {
                var _p = _cluster[i];
                if (_grid[_p.y][_p.x].id == 999) {
                    _visited[_p.y][_p.x] = false;
                }
            }
        }
    }
}

function collect_cluster(_grid, _cols, _rows, _startX, _startY, _visited) {
    var _cluster = [];
    var _queue = [];
    var _startCell = _grid[_startY][_startX];

    var _node = { x: _startX, y: _startY };
    array_push(_queue, _node);
    array_push(_cluster, _node);
    _visited[_startY][_startX] = true;

    var _head = 0;
    var _state = { colorId: _startCell.id };

    while (_head < array_length(_queue)) {
        var _cur = _queue[_head++];
        var _curCell = _grid[_cur.y][_cur.x];

        var _dirs = [[1,0,"h"], [-1,0,"h"], [0,1,"v"], [0,-1,"v"]];
        for (var d = 0; d < 4; d++) {
            try_add_cluster_neighbor(_grid, _cols, _rows, _visited, _queue, _cluster,
                                     _curCell, _cur.x + _dirs[d][0], _cur.y + _dirs[d][1],
                                     _dirs[d][2], _state);
        }
    }
    return _cluster;
}

function try_add_cluster_neighbor(_grid, _cols, _rows, _visited, _queue, _cluster,
                                   _cell, _nx, _ny, _axis, _state) {
    if (_nx < 0 || _nx >= _cols || _ny < 0 || _ny >= _rows) return;
    if (_visited[_ny][_nx]) return;

    var _nb = _grid[_ny][_nx];
    if (_nb == undefined) return;

    // Arrows are excluded from clusters entirely
    if (cell_has_arrow(_nb)) {
        _visited[_ny][_nx] = true;
        return;
    }
    if (!cell_can_match(_nb)) {
        _visited[_ny][_nx] = true;
        return;
    }

    // Color matching (wildcards bridge anything)
    // Cells with invalid IDs never participate
    if (_nb.id <= 0) { _visited[_ny][_nx] = true; return; }
    if (_state.colorId == 999 && _nb.id != 999) {
        _state.colorId = _nb.id;
    }
    if (_state.colorId != 999 && _nb.id != 999 && _nb.id != _state.colorId) {
        return;
    }

    _visited[_ny][_nx] = true;
    var _node = { x: _nx, y: _ny };
    array_push(_queue, _node);
    array_push(_cluster, _node);
}


// -----------------------------------------------------------------------------
// LINE MATCHES — 4+ in a straight horizontal or vertical line
// Arrow/metal blocks ONLY match in lines, and require 4+ total
// -----------------------------------------------------------------------------
function add_line_matches(_grid, _cols, _rows, _clear_grid) {
    // Horizontal
    for (var _y = 0; _y < _rows; _y++) {
        var _run = [];
        var _runColor = -1;
        var _runHasArrow = false;

        for (var _x = 0; _x < _cols; _x++) {
            var _cell = _grid[_y][_x];
            var _canAdd = line_cell_can_join(_grid, _cols, _rows, _run, _runColor, _runHasArrow,
                                              _cell, _x, _y, "h");

            if (_canAdd) {
                if (cell_has_arrow(_cell)) _runHasArrow = true;
                if (_runColor == -1 && _cell.id != 999) _runColor = _cell.id;
                array_push(_run, { x: _x, y: _y, hasArrow: cell_has_arrow(_cell) });
            } else {
                flush_line_run(_clear_grid, _run);
                // Start new run
                _run = [];
                _runColor = -1;
                _runHasArrow = false;
                if (_cell != undefined && cell_can_match(_cell) && _cell.id > 0) {
                    if (cell_has_arrow(_cell)) {
                        // Arrow can only START a line if its axis allows horizontal
                        if (match_arrow_allows_axis(_cell, "h")) {
                            _runHasArrow = true;
                            _runColor = _cell.id;
                            array_push(_run, { x: _x, y: _y, hasArrow: true });
                        }
                    } else {
                        _runColor = _cell.id;
                        array_push(_run, { x: _x, y: _y, hasArrow: false });
                    }
                }
            }
        }
        flush_line_run(_clear_grid, _run);
    }

    // Vertical
    for (var _x = 0; _x < _cols; _x++) {
        var _runV = [];
        var _runColorV = -1;
        var _runHasArrowV = false;

        for (var _y = 0; _y < _rows; _y++) {
            var _cellV = _grid[_y][_x];
            var _canAddV = line_cell_can_join(_grid, _cols, _rows, _runV, _runColorV, _runHasArrowV,
                                               _cellV, _x, _y, "v");

            if (_canAddV) {
                if (cell_has_arrow(_cellV)) _runHasArrowV = true;
                if (_runColorV == -1 && _cellV.id != 999) _runColorV = _cellV.id;
                array_push(_runV, { x: _x, y: _y, hasArrow: cell_has_arrow(_cellV) });
            } else {
                flush_line_run(_clear_grid, _runV);
                _runV = [];
                _runColorV = -1;
                _runHasArrowV = false;
                if (_cellV != undefined && cell_can_match(_cellV) && _cellV.id > 0) {
                    if (cell_has_arrow(_cellV)) {
                        if (match_arrow_allows_axis(_cellV, "v")) {
                            _runHasArrowV = true;
                            _runColorV = _cellV.id;
                            array_push(_runV, { x: _x, y: _y, hasArrow: true });
                        }
                    } else {
                        _runColorV = _cellV.id;
                        array_push(_runV, { x: _x, y: _y, hasArrow: false });
                    }
                }
            }
        }
        flush_line_run(_clear_grid, _runV);
    }
}

function line_cell_can_join(_grid, _cols, _rows, _run, _runColor, _runHasArrow,
                             _cell, _x, _y, _axis) {
    if (_cell == undefined) return false;
    if (!cell_can_match(_cell)) return false;
    if (_cell.id <= 0) return false;

    // Empty run: can start with anything matchable
    if (array_length(_run) == 0) {
        if (cell_has_arrow(_cell)) {
            // Arrow can only START if its axis matches
            return match_arrow_allows_axis(_cell, _axis);
        }
        return true;
    }

    // Arrow check: arrows only join lines, not clusters
    // Both cells must allow the axis
    var _prev = _run[array_length(_run) - 1];
    var _prevCell = _grid[_prev.y][_prev.x];

    if (cell_has_arrow(_prevCell) && !match_arrow_allows_axis(_prevCell, _axis)) return false;
    if (cell_has_arrow(_cell) && !match_arrow_allows_axis(_cell, _axis)) return false;

    // Color check
    if (_runColor == 999) return true; // wild leading run, anything joins
    if (_cell.id == 999) return true;  // wild always joins
    if (_cell.id == _runColor) return true;
    if (_runColor == -1 && _cell.id != 999) return true; // first non-wild sets color

    return false;
}

function flush_line_run(_clear_grid, _run) {
    var _len = array_length(_run);
    if (_len <= 0) return;

    // If run contains ANY arrow/metal block, minimum is 4
    var _minLen = 4;
    for (var i = 0; i < _len; i++) {
        if (_run[i].hasArrow) { _minLen = 4; break; }
    }

    if (_len >= _minLen) {
        for (var i = 0; i < _len; i++) {
            mark_cell(_clear_grid, _run[i].x, _run[i].y);
        }
    }
}


// -----------------------------------------------------------------------------
// DIAGONAL MATCHES — 4+ in a diagonal line, no arrows
// -----------------------------------------------------------------------------
function add_diagonal_matches(_grid, _cols, _rows, _clear_grid) {
    // Down-right diagonals
    for (var _sy = 0; _sy < _rows; _sy++) scan_diag(_grid, _cols, _rows, _clear_grid, 0, _sy, 1, 1);
    for (var _sx = 1; _sx < _cols; _sx++) scan_diag(_grid, _cols, _rows, _clear_grid, _sx, 0, 1, 1);
    // Up-right diagonals
    for (var _sy2 = 0; _sy2 < _rows; _sy2++) scan_diag(_grid, _cols, _rows, _clear_grid, 0, _sy2, 1, -1);
    for (var _sx2 = 1; _sx2 < _cols; _sx2++) scan_diag(_grid, _cols, _rows, _clear_grid, _sx2, _rows - 1, 1, -1);
}

function scan_diag(_grid, _cols, _rows, _clear_grid, _sx, _sy, _dx, _dy) {
    var _run = [];
    var _runColor = -1;
    var _x = _sx;
    var _y = _sy;

    while (_x >= 0 && _x < _cols && _y >= 0 && _y < _rows) {
        var _cell = _grid[_y][_x];
        var _ok = false;

        if (_cell != undefined && cell_can_match(_cell) && !cell_has_arrow(_cell)) {
            if (array_length(_run) == 0) {
                _ok = true;
                _runColor = _cell.id;
            } else {
                if (_runColor == 999 && _cell.id != 999) _runColor = _cell.id;
                if (_runColor == 999 || _cell.id == 999 || _cell.id == _runColor) {
                    _ok = true;
                }
            }
        }

        if (_ok) {
            array_push(_run, { x: _x, y: _y });
        } else {
            if (array_length(_run) >= 4) {
                for (var i = 0; i < array_length(_run); i++) {
                    mark_cell(_clear_grid, _run[i].x, _run[i].y);
                }
            }
            _run = [];
            _runColor = -1;
    if (_cell != undefined && cell_can_match(_cell) && !cell_has_arrow(_cell) && _cell.id > 0) {
                array_push(_run, { x: _x, y: _y });
                _runColor = _cell.id;
            }
        }
        _x += _dx;
        _y += _dy;
    }
    if (array_length(_run) >= 4) {
        for (var i = 0; i < array_length(_run); i++) {
            mark_cell(_clear_grid, _run[i].x, _run[i].y);
        }
    }
}


// -----------------------------------------------------------------------------
// OPTIONAL: SPILL CLEAR INTO SAME-COLOR ADJACENT BLOCKS
// (Only used for specialty block chaining, not default behavior)
// -----------------------------------------------------------------------------
function expand_clear_to_same_color_blobs(_grid, _cols, _rows, _clear_grid) {
    var _visited = make_bool_grid(_cols, _rows, false);
    var _queue = [];
    for (var _y = 0; _y < _rows; _y++) {
        for (var _x = 0; _x < _cols; _x++) {
            if (!_clear_grid[_y][_x]) continue;
            var _cell = _grid[_y][_x];
            if (!cell_can_match(_cell)) continue;
            if (cell_has_arrow(_cell)) continue; // never spill from arrows
            _visited[_y][_x] = true;
            array_push(_queue, { x: _x, y: _y, id: _cell.id });
        }
    }
    var _head = 0;
    while (_head < array_length(_queue)) {
        var _n = _queue[_head++];
        var _dirs = [[1,0,"h"], [-1,0,"h"], [0,1,"v"], [0,-1,"v"]];
        for (var d = 0; d < 4; d++) {
            var _nx = _n.x + _dirs[d][0];
            var _ny = _n.y + _dirs[d][1];
            if (_nx < 0 || _nx >= _cols || _ny < 0 || _ny >= _rows) continue;
            if (_visited[_ny][_nx]) continue;
            var _cell = _grid[_ny][_nx];
            if (!cell_can_match(_cell)) continue;
            if (cell_has_arrow(_cell)) continue; // never spill into arrows
            if (_cell.id != _n.id) continue;
            _visited[_ny][_nx] = true;
            _clear_grid[_ny][_nx] = true;
            array_push(_queue, { x: _nx, y: _ny, id: _n.id });
        }
    }
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
            if (!cell_can_match(_cell) || cell_has_arrow(_cell)) {
                _visited[_y][_x] = true;
                continue;
            }
            var _cluster = collect_cluster(global.grid, global.TOTAL_COLS, global.TOTAL_ROWS, _x, _y, _visited);
            _best = max(_best, array_length(_cluster));
        }
    }
    return _best;
}
