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

    return !match_cell_is_excluded(_cell);
}


function cells_can_match_axis(_a, _b, _axis, _allow_directional) {
    if (!cell_can_match(_a)) return false;
    if (!cell_can_match(_b)) return false;

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

            // 1. First ensure the cell is not undefined
            if (!cell_can_match(_cell)) {
                _visited[_y][_x] = true;
                continue;
            }

            // 2. Now it is safe to check for arrows
            var _hasArrow = (_cell.type == "metal") || (variable_struct_exists(_cell, "core_arrow") && _cell.core_arrow);
            if (_hasArrow) {
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

            // Unmark wildcards so they can bridge multiple different-colored clusters
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
    var _start = { x: _startX, y: _startY, cid: _startCell.id };
    array_push(_queue, _start);
    array_push(_cluster, _start);

    _visited[_startY][_startX] = true;

    var _head = 0;
    var _state = { colorId: _startCell.id }; 

    while (_head < array_length(_queue)) {
        var _current = _queue[_head++];
        var _cell = _grid[_current.y][_current.x];
        
        try_add_cluster_neighbor(_grid, _cols, _rows, _visited, _queue, _cluster, _cell, _current.x + 1, _current.y, "h", _state);
        try_add_cluster_neighbor(_grid, _cols, _rows, _visited, _queue, _cluster, _cell, _current.x - 1, _current.y, "h", _state);
        try_add_cluster_neighbor(_grid, _cols, _rows, _visited, _queue, _cluster, _cell, _current.x, _current.y + 1, "v", _state);
        try_add_cluster_neighbor(_grid, _cols, _rows, _visited, _queue, _cluster, _cell, _current.x, _current.y - 1, "v", _state);
    }

    return _cluster;
}


function try_add_cluster_neighbor(_grid, _cols, _rows, _visited, _queue, _cluster, _cell, _nx, _ny, _axis, _state) {
    if (_nx < 0 || _nx >= _cols || _ny < 0 || _ny >= _rows) return;
    if (_visited[_ny][_nx]) return;

    var _neighbor = _grid[_ny][_nx];
    if (_neighbor == undefined) return;

    if (_state.colorId == 999 && _neighbor.id != 999) {
        _state.colorId = _neighbor.id;
    }

    if (_state.colorId != 999) {
        if (_neighbor.id != _state.colorId && _neighbor.id != 999) return;
    }

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
        var _line = [];
        var _lineId = -1; 
        for (var _x = 0; _x < _cols; _x++) {
            var _curr = _grid[_y][_x];
            var _canJoin = false;
            if (_curr != undefined && cell_can_match(_curr)) {
                if (array_length(_line) == 0) {
                    // HARD GUARD: Block cannot even START a line if it points the wrong way
                    if (_curr.type == "metal" && !match_arrow_allows_axis(_curr, "h")) {
                        _canJoin = false;
                    } else {
                        _canJoin = true;
                        _lineId = _curr.id;
                    }
                } else {
                    var _prev = _grid[_y][_x - 1];
                    if (cells_can_match_axis(_prev, _curr, "h", true)) {
                        if (_lineId == 999) {
                            _lineId = _curr.id;
                            _canJoin = true;
                        } else if (_curr.id == 999 || _curr.id == _lineId) {
                            _canJoin = true;
                        }
                    }
                }
            }
            if (_canJoin) {
                array_push(_line, {x: _x, y: _y});
            } else {
                if (array_length(_line) >= 4) {
                    for (var i = 0; i < array_length(_line); i++) mark_cell(_clear_grid, _line[i].x, _line[i].y);
                }
                _line = [];
                if (_curr != undefined && cell_can_match(_curr)) {
                    array_push(_line, {x: _x, y: _y});
                    _lineId = _curr.id;
                } else {
                    _lineId = -1;
                }
            }
        }
        if (array_length(_line) >= 4) {
            for (var i = 0; i < array_length(_line); i++) mark_cell(_clear_grid, _line[i].x, _line[i].y);
        }
    }

    // Vertical
    for (var _x = 0; _x < _cols; _x++) {
        var _lineV = [];
        var _lineIdV = -1;
        for (var _y = 0; _y < _rows; _y++) {
            var _currV = _grid[_y][_x];
            var _canJoinV = false;
            if (_currV != undefined && cell_can_match(_currV)) {
                if (array_length(_lineV) == 0) {
                    // HARD GUARD: Block cannot even START a line if it points the wrong way
                    if (_currV.type == "metal" && !match_arrow_allows_axis(_currV, "v")) {
                        _canJoinV = false;
                    } else {
                        _canJoinV = true;
                        _lineIdV = _currV.id;
                    }
                } else {
                    var _prevV = _grid[_y - 1][_x];
                    if (cells_can_match_axis(_prevV, _currV, "v", true)) {
                        if (_lineIdV == 999) {
                            _lineIdV = _currV.id;
                            _canJoinV = true;
                        } else if (_currV.id == 999 || _currV.id == _lineIdV) {
                            _canJoinV = true;
                        }
                    }
                }
            }
            if (_canJoinV) {
                array_push(_lineV, {x: _x, y: _y});
            } else {
                if (array_length(_lineV) >= 4) {
                    for (var j = 0; j < array_length(_lineV); j++) mark_cell(_clear_grid, _lineV[j].x, _lineV[j].y);
                }
                _lineV = [];
                if (_currV != undefined && cell_can_match(_currV)) {
                    array_push(_lineV, {x: _x, y: _y});
                    _lineIdV = _currV.id;
                } else {
                    _lineIdV = -1;
                }
            }
        }
        if (array_length(_lineV) >= 4) {
            for (var j = 0; j < array_length(_lineV); j++) mark_cell(_clear_grid, _lineV[j].x, _lineV[j].y);
        }
    }
}


// -----------------------------------------------------------------------------
// DIAGONAL MATCHES
// 4+ cells in either diagonal direction.
// -----------------------------------------------------------------------------
function add_diagonal_matches(_grid, _cols, _rows, _clear_grid) {
    // Down-right
    for (var _startY = 0; _startY < _rows; _startY++) scan_diagonal(_grid, _cols, _rows, _clear_grid, 0, _startY, 1, 1);
    for (var _startX = 1; _startX < _cols; _startX++) scan_diagonal(_grid, _cols, _rows, _clear_grid, _startX, 0, 1, 1);
    // Up-right
    for (var _startY2 = 0; _startY2 < _rows; _startY2++) scan_diagonal(_grid, _cols, _rows, _clear_grid, 0, _startY2, 1, -1);
    for (var _startX2 = 1; _startX2 < _cols; _startX2++) scan_diagonal(_grid, _cols, _rows, _clear_grid, _startX2, _rows - 1, 1, -1);
}


function scan_diagonal(_grid, _cols, _rows, _clear_grid, _sx, _sy, _dx, _dy) {
    var _run = [];
    var _lineId = -1;
    var _x = _sx; var _y = _sy;

    while (_x >= 0 && _x < _cols && _y >= 0 && _y < _rows) {
        var _cell = _grid[_y][_x];
        var _canJoin = false;
        if (_cell != undefined && cell_can_match(_cell)) {
            if (array_length(_run) == 0) {
                _canJoin = true;
                _lineId = _cell.id;
            } else {
                var _last = _run[array_length(_run) - 1];
                var _prev = _grid[_last.y][_last.x];
                if (cells_can_match_axis(_prev, _cell, "d", false)) {
                    if (_lineId == 999) { _lineId = _cell.id; _canJoin = true; }
                    else if (_cell.id == 999 || _cell.id == _lineId) { _canJoin = true; }
                }
            }
        }
        if (_canJoin) {
            array_push(_run, { x: _x, y: _y });
        } else {
            mark_diagonal_run_if_valid(_clear_grid, _run);
            _run = [];
            if (_cell != undefined && cell_can_match(_cell)) {
                array_push(_run, { x: _x, y: _y });
                _lineId = _cell.id;
            } else { _lineId = -1; }
        }
        _x += _dx; _y += _dy;
    }
    mark_diagonal_run_if_valid(_clear_grid, _run);
}


function mark_diagonal_run_if_valid(_clear_grid, _run) {
    if (array_length(_run) >= 4) {
        for (var i = 0; i < array_length(_run); i++) mark_cell(_clear_grid, _run[i].x, _run[i].y);
    }
}


// -----------------------------------------------------------------------------
// OPTIONAL: EXPAND CLEAR INTO SAME-COLOR BLOBS
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
    if (!cells_can_match_axis(_from_cell, _cell, _axis, false)) return;
    _visited[_ny][_nx] = true;
    _clear_grid[_ny][_nx] = true;
    array_push(_queue, { x: _nx, y: _ny, id: _from.id });
}


function debug_largest_cluster_size() {
    var _visited = make_bool_grid(global.TOTAL_COLS, global.TOTAL_ROWS, false);
    var _best = 0;
    for (var _y = 0; _y < global.TOTAL_ROWS; _y++) {
        for (var _x = 0; _x < global.TOTAL_COLS; _x++) {
            if (_visited[_y][_x]) continue;
            var _cell = global.grid[_y][_x];
            if (!cell_can_match(_cell)) { _visited[_y][_x] = true; continue; }
            var _cluster = collect_cluster(global.grid, global.TOTAL_COLS, global.TOTAL_ROWS, _x, _y, _visited);
            _best = max(_best, array_length(_cluster));
        }
    }
    return _best;
}