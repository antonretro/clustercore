function debug_largest_cluster_size() {
    var _visited = array_create(global.TOTAL_ROWS);
    for (var i = 0; i < global.TOTAL_ROWS; i++) {
        _visited[i] = array_create(global.TOTAL_COLS, false);
    }
    var _best = 0;
    for (var _y = 0; _y < global.TOTAL_ROWS; _y++) {
        for (var _x = 0; _x < global.TOTAL_COLS; _x++) {
            if (_visited[_y][_x]) continue;
            var _cell = global.grid[_y][_x];
            if (_cell == undefined || _cell.type == "bomb" || _cell.type == "dead") continue;
            var _cluster = [];
            collect_cluster(global.grid, global.TOTAL_COLS, global.TOTAL_ROWS, _x, _y, _visited, _cluster);
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

function cells_share_match_color(_c1, _c2) {
    if (_c1 == undefined || _c2 == undefined) return false;
    return _c1.id == _c2.id;
}

function check_cells(_c1, _c2, _axis) {
    if (_c1 == undefined || _c2 == undefined) return false;
    if (_c1.type == "bomb" || _c2.type == "bomb") return false;
    if (_c1.type == "dead" || _c2.type == "dead") return false;
    if (!cells_share_match_color(_c1, _c2)) return false;
    
    if (!arrow_allows_axis(_c1, _axis)) return false;
    if (!arrow_allows_axis(_c2, _axis)) return false;
    
    // Directional (Metal) blocks are EXCLUDED from clusters and diagonals. 
    // They only match via the Line Matcher.
    if (_c1.type == "metal" || _c2.type == "metal") return false;

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
            
            // All clusters require 4+ to clear. (Normal, Asteroid, Core)
            var _required = 4;
            if (array_length(_cluster) >= _required) {
                for (var i = 0; i < array_length(_cluster); i++) {
                    var _c = _cluster[i];
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

function add_line_matches(_grid, _cols, _totalRows, _clear_grid) {
    // Horizontal Lines
    for (var _y = 0; _y < _totalRows; _y++) {
        var _count = 1;
        for (var _x = 1; _x <= _cols; _x++) {
            var _prev = (_x > 0) ? _grid[_y][_x-1] : undefined;
            var _curr = (_x < _cols) ? _grid[_y][_x] : undefined;
            
            var _isMatch = false;
            if (_curr != undefined && _prev != undefined && cells_share_match_color(_curr, _prev) && _curr.type != "bomb" && _prev.type != "bomb") {
                // Directional Check: Arrows in a horizontal line MUST be horizontal arrows
                var _prevValid = (_prev.type != "metal" || _prev.dir == 0);
                var _currValid = (_curr.type != "metal" || _curr.dir == 0);
                if (_prevValid && _currValid) _isMatch = true;
            }
            
            if (_isMatch) {
                _count++;
            } else {
                if (_count >= 4) {
                    for (var i = 0; i < _count; i++) {
                        _clear_grid[_y][_x - 1 - i] = true;
                    }
                }
                _count = 1;
            }
        }
    }
    
    // Vertical Lines
    for (var _x = 0; _x < _cols; _x++) {
        var _count = 1;
        for (var _y = 1; _y <= _totalRows; _y++) {
            var _prev = (_y > 0) ? _grid[_y-1][_x] : undefined;
            var _curr = (_y < _totalRows) ? _grid[_y][_x] : undefined;
            
            var _isMatch = false;
            if (_curr != undefined && _prev != undefined && cells_share_match_color(_curr, _prev) && _curr.type != "bomb" && _prev.type != "bomb") {
                // Directional Check: Arrows in a vertical line MUST be vertical arrows
                var _prevValid = (_prev.type != "metal" || _prev.dir == 1);
                var _currValid = (_curr.type != "metal" || _curr.dir == 1);
                if (_prevValid && _currValid) _isMatch = true;
            }
            
            if (_isMatch) {
                _count++;
            } else {
                if (_count >= 4) {
                    for (var i = 0; i < _count; i++) {
                        _clear_grid[_y - 1 - i][_x] = true;
                    }
                }
                _count = 1;
            }
        }
    }
}
