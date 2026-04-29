function find_matches_in_grid(_grid, _config, _totalRows) {
    var _cols = _config.cols;
    
    var _clear_grid = array_create(_totalRows);
    for (var i = 0; i < _totalRows; i++) {
        _clear_grid[i] = array_create(_cols, false);
    }

    add_cluster_matches(_grid, _cols, _totalRows, _clear_grid);
    add_diagonal_matches(_grid, _cols, _totalRows, _clear_grid);
    expand_core_set(_grid, _cols, _totalRows, _clear_grid);

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
    return true; 
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
            
            if (array_length(_cluster) < 3) continue;

            for (var i = 0; i < array_length(_cluster); i++) {
                var _c = _cluster[i];
                var _target = _grid[_c.y][_c.x];
                
                if (_target.type == "normal") {
                    // Normal blocks clear in 3+ clusters
                    _clear_grid[_c.y][_c.x] = true;
                } else if (_target.type == "metal") {
                    // ARROWS ONLY CLEAR IF IN A LINE OF 4 (Horizontal or Vertical)
                    var _lineH = 1;
                    var _lineV = 1;
                    
                    // Check Horizontal Line in cluster
                    var _tx = _c.x - 1; while (_tx >= 0 && in_cluster(_tx, _c.y, _cluster)) { _lineH++; _tx--; }
                    _tx = _c.x + 1; while (_tx < _cols && in_cluster(_tx, _c.y, _cluster)) { _lineH++; _tx++; }
                    
                    // Check Vertical Line in cluster
                    var _ty = _c.y - 1; while (_ty >= 0 && in_cluster(_c.x, _ty, _cluster)) { _lineV++; _ty--; }
                    _ty = _c.y + 1; while (_ty < _totalRows && in_cluster(_c.x, _ty, _cluster)) { _lineV++; _ty++; }
                    
                    if (_lineH >= 4 || _lineV >= 4) {
                        _clear_grid[_c.y][_c.x] = true;
                    }
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

            if (_nx < 0 || _nx >= _cols || _ny < 0 || _ny >= _totalRows) continue;
            if (_visited[_ny][_nx]) continue;

            var _neighbor = _grid[_ny][_nx];
            if (check_cells(_cell, _neighbor, "c")) {
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
    // Normal blocks clear in 3-diagonals, Arrows only if they are part of a 4-line elsewhere
    // Keeping this simple: diagonals only clear normal blocks
    for (var _y = 0; _y < _totalRows - 2; _y++) {
        for (var _x = 0; _x < _cols - 2; _x++) {
            var _match = true;
            var _first = _grid[_y][_x];
            if (_first == undefined || _first.type != "normal") continue;

            for (var _k = 1; _k < 3; _k++) {
                var _next = _grid[_y + _k][_x + _k];
                if (!check_cells(_first, _next, "d") || _next.type != "normal") {
                    _match = false;
                    break;
                }
            }
            if (_match) {
                for (var _k = 0; _k < 3; _k++) _clear_grid[_y + _k][_x + _k] = true;
            }
        }
    }

    for (var _y = 2; _y < _totalRows; _y++) {
        for (var _x = 0; _x < _cols - 2; _x++) {
            var _match = true;
            var _first = _grid[_y][_x];
            if (_first == undefined || _first.type != "normal") continue;

            for (var _k = 1; _k < 3; _k++) {
                var _next = _grid[_y - _k][_x + _k];
                if (!check_cells(_first, _next, "d") || _next.type != "normal") {
                    _match = false;
                    break;
                }
            }
            if (_match) {
                for (var _k = 0; _k < 3; _k++) _clear_grid[_y - _k][_x + _k] = true;
            }
        }
    }
}

function expand_core_set(_grid, _cols, _totalRows, _clear_grid) {
    var _expanding = true;
    while (_expanding) {
        _expanding = false;
        for (var _y = 0; _y < _totalRows; _y++) {
            for (var _x = 0; _x < _cols; _x++) {
                if (!_clear_grid[_y][_x]) continue;

                var _coreCell = _grid[_y][_x];
                if (_coreCell == undefined) continue;

                var _dirs = [[0, 1], [0, -1], [1, 0], [-1, 0]];
                for (var i = 0; i < array_length(_dirs); i++) {
                    var _d = _dirs[i];
                    var _nx = _x + _d[0];
                    var _ny = _y + _d[1];
                    if (_nx < 0 || _nx >= _cols || _ny < 0 || _ny >= _totalRows) continue;

                    var _neighbor = _grid[_ny][_nx];
                    if (_neighbor == undefined) continue;
                    if (_neighbor.id != _coreCell.id) continue;
                    if (_neighbor.type == "dead" || _neighbor.type == "bomb") continue;
                    if (_clear_grid[_ny][_nx]) continue;
                    
                    // Only expand to normal blocks or arrows that are part of their own 4-line
                    if (_neighbor.type == "normal") {
                        _clear_grid[_ny][_nx] = true;
                        _expanding = true;
                    }
                }
            }
        }
    }
}
