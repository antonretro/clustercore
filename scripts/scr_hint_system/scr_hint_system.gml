// =============================================================================
// scr_hint_system - actionable near-match hint pulses (Candy Crush style)
// =============================================================================

function hint_is_matchable_cell(_cell) {
    if (_cell == undefined) return false;
    if (_cell.type == "bomb" || _cell.type == "dead") return false;
    return true;
}

function hint_line_is_id(_x, _y, _cols, _rows, _colorId) {
    if (_x < 0 || _x >= _cols || _y < 0 || _y >= _rows) return false;
    var _c = global.grid[_y][_x];
    return (hint_is_matchable_cell(_c) && _c.id == _colorId);
}

function hint_line_is_empty(_x, _y, _cols, _rows) {
    if (_x < 0 || _x >= _cols || _y < 0 || _y >= _rows) return false;
    return (global.grid[_y][_x] == undefined);
}

function hint_find_actionable_triple_for_color(_colorId) {
    var _rows = global.TOTAL_ROWS;
    var _cols = global.TOTAL_COLS;
    var _visited = array_create(_rows);
    for (var _y = 0; _y < _rows; _y++) _visited[_y] = array_create(_cols, false);

    var _best = [];
    var _bestDist = 99999;
    var _cx = floor(global.TOTAL_COLS / 2);
    var _cy = floor(global.TOTAL_ROWS / 2);
    var _dirs = [[1,0],[-1,0],[0,1],[0,-1]];

    // Priority 1: strict line patterns that are one move from 4.
    // 111_ / _111 and 11_1 / 1_11 (both horizontal and vertical)
    var _lineBest = [];
    var _lineBestDist = 99999;

    // Horizontal windows of length 4
    for (var _y0 = 0; _y0 < _rows; _y0++) {
        for (var _x0 = 0; _x0 <= _cols - 4; _x0++) {
            var _m0 = hint_line_is_id(_x0, _y0, _cols, _rows, _colorId);
            var _m1 = hint_line_is_id(_x0 + 1, _y0, _cols, _rows, _colorId);
            var _m2 = hint_line_is_id(_x0 + 2, _y0, _cols, _rows, _colorId);
            var _m3 = hint_line_is_id(_x0 + 3, _y0, _cols, _rows, _colorId);
            var _e0 = hint_line_is_empty(_x0, _y0, _cols, _rows);
            var _e1 = hint_line_is_empty(_x0 + 1, _y0, _cols, _rows);
            var _e2 = hint_line_is_empty(_x0 + 2, _y0, _cols, _rows);
            var _e3 = hint_line_is_empty(_x0 + 3, _y0, _cols, _rows);

            if (_m0 && _m1 && _m2 && _e3) {
                var _mx0 = (_x0 + (_x0 + 1) + (_x0 + 2)) / 3.0;
                var _my0 = _y0;
                var _d0 = abs(_mx0 - _cx) + abs(_my0 - _cy);
                if (_d0 < _lineBestDist) { _lineBestDist = _d0; _lineBest = [{x:_x0,y:_y0},{x:_x0+1,y:_y0},{x:_x0+2,y:_y0}]; }
            } // 111_
            if (_e0 && _m1 && _m2 && _m3) {
                var _mx1 = ((_x0 + 1) + (_x0 + 2) + (_x0 + 3)) / 3.0;
                var _my1 = _y0;
                var _d1 = abs(_mx1 - _cx) + abs(_my1 - _cy);
                if (_d1 < _lineBestDist) { _lineBestDist = _d1; _lineBest = [{x:_x0+1,y:_y0},{x:_x0+2,y:_y0},{x:_x0+3,y:_y0}]; }
            } // _111
            if (_m0 && _m1 && _e2 && _m3) {
                var _mx2 = (_x0 + (_x0 + 1) + (_x0 + 3)) / 3.0;
                var _my2 = _y0;
                var _d2 = abs(_mx2 - _cx) + abs(_my2 - _cy);
                if (_d2 < _lineBestDist) { _lineBestDist = _d2; _lineBest = [{x:_x0,y:_y0},{x:_x0+1,y:_y0},{x:_x0+3,y:_y0}]; }
            } // 11_1
            if (_m0 && _e1 && _m2 && _m3) {
                var _mx3 = (_x0 + (_x0 + 2) + (_x0 + 3)) / 3.0;
                var _my3 = _y0;
                var _d3 = abs(_mx3 - _cx) + abs(_my3 - _cy);
                if (_d3 < _lineBestDist) { _lineBestDist = _d3; _lineBest = [{x:_x0,y:_y0},{x:_x0+2,y:_y0},{x:_x0+3,y:_y0}]; }
            } // 1_11
        }
    }

    // Vertical windows of length 4
    for (var _xv = 0; _xv < _cols; _xv++) {
        for (var _yv = 0; _yv <= _rows - 4; _yv++) {
            var _vm0 = hint_line_is_id(_xv, _yv, _cols, _rows, _colorId);
            var _vm1 = hint_line_is_id(_xv, _yv + 1, _cols, _rows, _colorId);
            var _vm2 = hint_line_is_id(_xv, _yv + 2, _cols, _rows, _colorId);
            var _vm3 = hint_line_is_id(_xv, _yv + 3, _cols, _rows, _colorId);
            var _ve0 = hint_line_is_empty(_xv, _yv, _cols, _rows);
            var _ve1 = hint_line_is_empty(_xv, _yv + 1, _cols, _rows);
            var _ve2 = hint_line_is_empty(_xv, _yv + 2, _cols, _rows);
            var _ve3 = hint_line_is_empty(_xv, _yv + 3, _cols, _rows);

            if (_vm0 && _vm1 && _vm2 && _ve3) {
                var _vmx0 = _xv;
                var _vmy0 = (_yv + (_yv + 1) + (_yv + 2)) / 3.0;
                var _vd0 = abs(_vmx0 - _cx) + abs(_vmy0 - _cy);
                if (_vd0 < _lineBestDist) { _lineBestDist = _vd0; _lineBest = [{x:_xv,y:_yv},{x:_xv,y:_yv+1},{x:_xv,y:_yv+2}]; }
            } // 111_
            if (_ve0 && _vm1 && _vm2 && _vm3) {
                var _vmx1 = _xv;
                var _vmy1 = ((_yv + 1) + (_yv + 2) + (_yv + 3)) / 3.0;
                var _vd1 = abs(_vmx1 - _cx) + abs(_vmy1 - _cy);
                if (_vd1 < _lineBestDist) { _lineBestDist = _vd1; _lineBest = [{x:_xv,y:_yv+1},{x:_xv,y:_yv+2},{x:_xv,y:_yv+3}]; }
            } // _111
            if (_vm0 && _vm1 && _ve2 && _vm3) {
                var _vmx2 = _xv;
                var _vmy2 = (_yv + (_yv + 1) + (_yv + 3)) / 3.0;
                var _vd2 = abs(_vmx2 - _cx) + abs(_vmy2 - _cy);
                if (_vd2 < _lineBestDist) { _lineBestDist = _vd2; _lineBest = [{x:_xv,y:_yv},{x:_xv,y:_yv+1},{x:_xv,y:_yv+3}]; }
            } // 11_1
            if (_vm0 && _ve1 && _vm2 && _vm3) {
                var _vmx3 = _xv;
                var _vmy3 = (_yv + (_yv + 2) + (_yv + 3)) / 3.0;
                var _vd3 = abs(_vmx3 - _cx) + abs(_vmy3 - _cy);
                if (_vd3 < _lineBestDist) { _lineBestDist = _vd3; _lineBest = [{x:_xv,y:_yv},{x:_xv,y:_yv+2},{x:_xv,y:_yv+3}]; }
            } // 1_11
        }
    }

    if (array_length(_lineBest) > 0) return _lineBest;

    for (var _sy = 0; _sy < _rows; _sy++) {
        for (var _sx = 0; _sx < _cols; _sx++) {
            if (_visited[_sy][_sx]) continue;
            var _start = global.grid[_sy][_sx];
            if (!hint_is_matchable_cell(_start) || _start.id != _colorId) continue;

            var _cluster = [];
            var _queue = [{x: _sx, y: _sy}];
            _visited[_sy][_sx] = true;
            var _head = 0;

            while (_head < array_length(_queue)) {
                var _node = _queue[_head++];
                array_push(_cluster, _node);
                for (var _di = 0; _di < 4; _di++) {
                    var _nx = _node.x + _dirs[_di][0];
                    var _ny = _node.y + _dirs[_di][1];
                    if (_nx < 0 || _nx >= _cols || _ny < 0 || _ny >= _rows) continue;
                    if (_visited[_ny][_nx]) continue;
                    var _ncell = global.grid[_ny][_nx];
                    if (hint_is_matchable_cell(_ncell) && _ncell.id == _colorId) {
                        _visited[_ny][_nx] = true;
                        array_push(_queue, {x: _nx, y: _ny});
                    }
                }
            }

            if (array_length(_cluster) != 3) continue;

            var _hasCompleter = false;
            for (var _ci = 0; _ci < 3; _ci++) {
                var _c = _cluster[_ci];
                for (var _di2 = 0; _di2 < 4; _di2++) {
                    var _ex = _c.x + _dirs[_di2][0];
                    var _ey = _c.y + _dirs[_di2][1];
                    if (_ex < 0 || _ex >= _cols || _ey < 0 || _ey >= _rows) continue;
                    if (global.grid[_ey][_ex] == undefined) { _hasCompleter = true; break; }
                }
                if (_hasCompleter) break;
            }
            if (!_hasCompleter) continue;

            var _mx = (_cluster[0].x + _cluster[1].x + _cluster[2].x) / 3.0;
            var _my = (_cluster[0].y + _cluster[1].y + _cluster[2].y) / 3.0;
            var _dist = abs(_mx - _cx) + abs(_my - _cy);
            if (_dist < _bestDist) {
                _bestDist = _dist;
                _best = _cluster;
            }
        }
    }

    return _best;
}

function hint_update() {
    if (!variable_global_exists("hint_cells")) global.hint_cells = [];
    if (!variable_global_exists("hint_tick")) global.hint_tick = 0;
    if (!variable_global_exists("hint_pulse_timer")) global.hint_pulse_timer = 0;
    if (!variable_global_exists("hint_pulse_interval")) global.hint_pulse_interval = room_speed * 3;

    if (global.hint_pulse_timer > 0) global.hint_pulse_timer--;
    global.hint_tick++;

    if (global.gameState != "PLAYING" || global.locking || global.activePiece == undefined) {
        global.hint_cells = [];
        return;
    }

    if (global.activePiece.type == "bomb" || global.activePiece.type == "drill" || global.activePiece.type == "dead") {
        global.hint_cells = [];
        return;
    }

    var _cid = global.activePiece.color_id;
    if (_cid <= 0) {
        global.hint_cells = [];
        return;
    }

    if (global.hint_tick >= global.hint_pulse_interval) {
        global.hint_tick = 0;
        global.hint_cells = hint_find_actionable_triple_for_color(_cid);
        if (array_length(global.hint_cells) > 0) {
            global.hint_pulse_timer = 30;
        }
    }
}

function hint_draw_overlay(_bx, _by, _cellSize, _scale) {
    if (!variable_global_exists("hint_pulse_timer")) return;
    if (!variable_global_exists("hint_cells")) return;
    if (global.hint_pulse_timer <= 0) return;
    if (array_length(global.hint_cells) <= 0) return;

    var _pulse = 0.25 + abs(sin(current_time * 0.02)) * 0.55;
    gpu_set_blendmode(bm_add);
    draw_set_color(make_color_rgb(200, 255, 180));
    draw_set_alpha(_pulse * (global.hint_pulse_timer / 30.0));

    for (var i = 0; i < array_length(global.hint_cells); i++) {
        var _h = global.hint_cells[i];
        var _x1 = _bx + (_h.x - global.HIDDEN_SIDES) * _cellSize;
        var _y1 = _by + (_h.y - global.HIDDEN_ROWS) * _cellSize;
        draw_rectangle(_x1 + 2 * _scale, _y1 + 2 * _scale, _x1 + _cellSize - 2 * _scale, _y1 + _cellSize - 2 * _scale, true);
    }

    draw_set_alpha(1.0);
    gpu_set_blendmode(bm_normal);
}
