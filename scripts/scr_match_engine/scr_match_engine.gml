function debug_largest_cluster_size() {
    var _visited = array_create(global.TOTAL_ROWS);
    for (var i = 0; i < global.TOTAL_ROWS; i++) {
        _visited[i] = array_create(global.COLS, false);
    }
    var _best = 0;
    for (var _y = 0; _y < global.TOTAL_ROWS; _y++) {
        for (var _x = 0; _x < global.COLS; _x++) {
            if (_visited[_y][_x]) continue;
            var _cell = global.grid[_y][_x];
            if (_cell == undefined || _cell.type == "bomb" || _cell.type == "dead") continue;
            var _cluster = [];
            collect_cluster(global.grid, global.COLS, global.TOTAL_ROWS, _x, _y, _visited, _cluster);
            _best = max(_best, array_length(_cluster));
        }
    }
    return _best;
}

function find_matches_in_grid(_grid, _config, _totalRows) {
    var _cols = _config.cols;
    
    // In GML, we use a 2D array to mark blocks for clearing.
    var _clear_grid = array_create(_totalRows);
    for (var i = 0; i < _totalRows; i++) {
        _clear_grid[i] = array_create(_cols, false);
    }

    add_cluster_matches(_grid, _cols, _totalRows, _clear_grid);
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

function check_cells(_c1, _c2, _axis) {
    if (_c1 == undefined || _c2 == undefined) return false;
    if (_c1.type == "bomb" || _c2.type == "bomb") return false;
    if (_c1.type == "dead" || _c2.type == "dead") return false;
    if (_c1.id != _c2.id) return false;
    
    if (!arrow_allows_axis(_c1, _axis)) return false;
    if (!arrow_allows_axis(_c2, _axis)) return false;
    
    return true; 
}

function arrow_allows_axis(_cell, _axis) {
    if (_cell.type != "metal") return true;
    if (_axis == "h") return _cell.dir == 0;
    if (_axis == "v") return _cell.dir == 1;
    return false;
}

function add_cluster_matches(_grid, _cols, _totalRows, _clear_grid) {
    var _visited = array_create(_totalRows);
    for (var i = 0; i < _totalRows; i++) {
        _visited[i] = array_create(_cols, false);
    }

    for (var _y = 0; _y < _totalRows; _y++) {
        for (var _x = 0; _x < _cols; _x++) {
            if (_visited[_y][_x]) continue;

            var _cell = _grid[_y][_x];
            if (_cell == undefined || _cell.type == "bomb" || _cell.type == "dead") continue;

            var _cluster = [];
            collect_cluster(_grid, _cols, _totalRows, _x, _y, _visited, _cluster);
            
            // --- MATCH SIZE LOGIC ---
            // Normal blocks clear at 3+. Metal (arrows) require a row/cluster of 4+ to clear.
            var _hasMetal = false;
            var _to_clear_indices = [];
            for (var i = 0; i < array_length(_cluster); i++) {
                var _c = _cluster[i];
                var _target = _grid[_c.y][_c.x];
                
                if (_target.type == "metal") _hasMetal = true;
                
                if (_target.type == "normal" || _target.type == "metal" || _target.type == "asteroid" || _target.type == "core") {
                    array_push(_to_clear_indices, i);
                }
            }

            // All clusters require 4+ to clear. Metal arrows must connect along their axis.
            var _required = 4;

            if (array_length(_to_clear_indices) >= _required) {
                for (var i = 0; i < array_length(_to_clear_indices); i++) {
                    var _idx = _to_clear_indices[i];
                    var _c = _cluster[_idx];
                    _clear_grid[_c.y][_c.x] = true;
                }
            }
        }
    }
}

function collect_cluster(_grid, _cols, _totalRows, _startX, _startY, _visited, _cluster) {
    var _queue = [{ x: _startX, y: _startY }];
    _visited[_startY][_startX] = true;
    array_push(_cluster, { x: _startX, y: _startY });

    var _head = 0;
    while (_head < array_length(_queue)) {
        var _current = _queue[_head++];
        var _cell = _grid[_current.y][_current.x];
        var _dirs = [[0, 1], [0, -1], [1, 0], [-1, 0]];

        for (var i = 0; i < array_length(_dirs); i++) {
            var _d = _dirs[i];
            var _nx = _current.x + _d[0];
            var _ny = _current.y + _d[1];
            var _axis = (_d[0] != 0) ? "h" : "v";

            if (_nx < 0 || _nx >= _cols || _ny < 0 || _ny >= _totalRows) continue;
            if (_visited[_ny][_nx]) continue;

            var _neighbor = _grid[_ny][_nx];
            if (check_cells(_cell, _neighbor, _axis)) {
                _visited[_ny][_nx] = true;
                var _node = { x: _nx, y: _ny };
                array_push(_cluster, _node);
                array_push(_queue, _node);
            }
        }
    }
}

function in_cluster(_x, _y, _cluster) {
    for (var i = 0; i < array_length(_cluster); i++) {
        if (_cluster[i].x == _x && _cluster[i].y == _y) return true;
    }
    return false;
}

function add_diagonal_matches(_grid, _cols, _totalRows, _clear_grid) {
    for (var _y = 0; _y < _totalRows - 3; _y++) {
        for (var _x = 0; _x < _cols - 3; _x++) {
            var _match = true;
            var _first = _grid[_y][_x];
            if (_first == undefined || (_first.type == "bomb" || _first.type == "dead")) continue;

            for (var _k = 1; _k < 4; _k++) {
                var _next = _grid[_y + _k][_x + _k];
                if (!check_cells(_first, _next, "d") || (_next.type == "bomb" || _next.type == "dead")) {
                    _match = false;
                    break;
                }
            }
            if (_match) {
                for (var _k = 0; _k < 4; _k++) _clear_grid[_y + _k][_x + _k] = true;
            }
        }
    }

    for (var _y = 3; _y < _totalRows; _y++) {
        for (var _x = 0; _x < _cols - 3; _x++) {
            var _match = true;
            var _first = _grid[_y][_x];
            if (_first == undefined || (_first.type == "bomb" || _first.type == "dead")) continue;

            for (var _k = 1; _k < 4; _k++) {
                var _next = _grid[_y - _k][_x + _k];
                if (!check_cells(_first, _next, "d") || (_next.type == "bomb" || _next.type == "dead")) {
                    _match = false;
                    break;
                }
            }
            if (_match) {
                for (var _k = 0; _k < 4; _k++) _clear_grid[_y - _k][_x + _k] = true;
            }
        }
    }
}
