// =============================================================================
// scr_planet_input — Planet surface caching, preview path, and orbital input
// =============================================================================

// recalculate_planet_surface — Caches the shallowest block distance for performance
// ─────────────────────────────────────────────────────────────────────────────
function recalculate_planet_surface() {
    cleanup_grid_ghost_cells();
    var _cx = floor(global.TOTAL_COLS / 2);
    var _cy = floor(global.TOTAL_ROWS / 2);
    var _minDist = _cx;
    var _maxDist = 1;
    for (var _sy = global.HIDDEN_ROWS; _sy < global.TOTAL_ROWS - global.HIDDEN_ROWS; _sy++) {
        for (var _sx = global.HIDDEN_SIDES; _sx < global.TOTAL_COLS - global.HIDDEN_SIDES; _sx++) {
            if (global.grid[_sy][_sx] != undefined) {
                var _d = max(abs(_sx - _cx), abs(_sy - _cy));
                if (_d < _minDist) _minDist = _d;
                if (_d > _maxDist) _maxDist = _d;
            }
        }
    }
    global.planetSurfaceDist = max(_minDist, 1);
    global.planetOuterRadius = max(_maxDist, 1);
}

// ─────────────────────────────────────────────────────────────────────────────
// calculate_planet_preview_path — Traces the path from spawn to landing
// Returns: { path: [{gx, gy}], target: {gx, gy}, depth: int }
// ─────────────────────────────────────────────────────────────────────────────
function calculate_planet_preview_path(_inst) {
    if (_inst == undefined) return undefined;
    cleanup_grid_ghost_cells();

    var _tx  = _inst.grid_x;
    var _ty  = _inst.grid_y;
    var _cx  = floor(global.TOTAL_COLS / 2);
    var _cy  = floor(global.TOTAL_ROWS / 2);
    var _centerCell = global.grid[_cy][_cx];
    var _centerOccupied = (_centerCell != undefined
        && _centerCell.inst != undefined
        && instance_exists(_centerCell.inst)
        && (!variable_instance_exists(_centerCell.inst, "clearing") || !_centerCell.inst.clearing));
    var _s   = ((global.orbitalSide % 4) + 4) % 4;
    var _isHeavy     = (global.launchCharge >= global.MAX_CHARGE);
    var _isDrill     = (_inst.type == "drill");
    var _penetration = (_inst.type == "drill") ? 3 : 0;
    var _path  = [];
    var _depth = 0;

    // Pure radial direction — straight inward from spawn cell (spoke of a wheel)
    var _ddx = 0, _ddy = 0;
    if (_s == 0) _ddy =  1;   // top    → drop down
    if (_s == 1) _ddx = -1;   // right  → drop left
    if (_s == 2) _ddy = -1;   // bottom → drop up
    if (_s == 3) _ddx =  1;   // left   → drop right

    // Use cached surface distance for performance
    var _surfaceDist = global.planetSurfaceDist;

    for (var i = 0; i < global.TOTAL_ROWS + global.TOTAL_COLS; i++) {

        var _nx = _tx + _ddx;
        var _ny = _ty + _ddy;
        if (_nx < 0 || _nx >= global.TOTAL_COLS || _ny < 0 || _ny >= global.TOTAL_ROWS) break;

        // Surface cap: don't tunnel through a truly occupied center.
        // If center is empty, allow path to reach it (no invisible center wall).
        if (!_isDrill && !_isHeavy) {
            var _distToCenter = max(abs(_nx - _cx), abs(_ny - _cy));
            if (_centerOccupied && _distToCenter < _surfaceDist) break;
        }

        if (global.grid[_ny][_nx] != undefined) {
            var _target = global.grid[_ny][_nx];
            if (_isHeavy || (_penetration > 0 && _target.type != "core"
            && _target.type != "dead" && _target.type != "bomb")) {
                if (_isHeavy) _isHeavy = false; else _penetration--;
                var _hx = _nx + _ddx;
                var _hy = _ny + _ddy;
                if (_hx >= 0 && _hx < global.TOTAL_COLS && _hy >= 0 && _hy < global.TOTAL_ROWS
                && global.grid[_hy][_hx] == undefined) {
                    _tx = _nx; _ty = _ny; _depth++;
                    array_push(_path, {gx: _tx, gy: _ty});
                    continue;
                }
            }
            break;
        }
        _tx = _nx; _ty = _ny; _depth++;
        array_push(_path, {gx: _tx, gy: _ty});
    }

    // ── PRE-CALCULATE MATCH HIGHLIGHT (Performance Optimization) ──
    var _hlList = [];
    var _isMatchRdy = false;
    if (_tx >= 0 && _tx < global.TOTAL_COLS && _ty >= 0 && _ty < global.TOTAL_ROWS) {
        var _hlVis = [];
        for (var _vy = 0; _vy < global.TOTAL_ROWS; _vy++) _hlVis[_vy] = array_create(global.TOTAL_COLS, false);
        _hlVis[_ty][_tx] = true;
        var _nbDirs = [[-1,0],[1,0],[0,-1],[0,1]];
        var _hlQueue = [];

        // Initial neighbors
        for (var _nd = 0; _nd < 4; _nd++) {
            var _nnx = _tx + _nbDirs[_nd][0], _nny = _ty + _nbDirs[_nd][1];
            if (_nnx >= 0 && _nnx < global.TOTAL_COLS && _nny >= 0 && _nny < global.TOTAL_ROWS) {
                var _nc = global.grid[_nny][_nnx];
                if (_nc != undefined && _nc.id == _inst.color_id && match_cell_can_match(_nc)) {
                    _hlVis[_nny][_nnx] = true;
                    array_push(_hlList, {x: _nnx, y: _nny});
                    array_push(_hlQueue, {x: _nnx, y: _nny});
                }
            }
        }

        // BFS with head pointer for O(N) performance
        var _head = 0;
        while (_head < array_length(_hlQueue)) {
            var _curr = _hlQueue[_head++];
            for (var _nd = 0; _nd < 4; _nd++) {
                var _nnx = _curr.x + _nbDirs[_nd][0], _nny = _curr.y + _nbDirs[_nd][1];
                if (_nnx >= 0 && _nnx < global.TOTAL_COLS && _nny >= 0 && _nny < global.TOTAL_ROWS) {
                    var _nc = global.grid[_nny][_nnx];
                    if (_nc != undefined && _nc.id == _inst.color_id && !_hlVis[_nny][_nnx] && match_cell_can_match(_nc)) {
                        _hlVis[_nny][_nnx] = true;
                        array_push(_hlList, {x: _nnx, y: _nny});
                        array_push(_hlQueue, {x: _nnx, y: _nny});
                    }
                }
            }
        }
        // Match occurs if 3+ neighbors share color (making 4 including self)
        _isMatchRdy = (array_length(_hlList) >= 3);
    }

    return { path: _path, target: {gx: _tx, gy: _ty}, depth: _depth, hlList: _hlList, isMatchRdy: _isMatchRdy };
}

// ─────────────────────────────────────────────────────────────────────────────
// handle_planet_input — Processes all orbital movement and firing
// ─────────────────────────────────────────────────────────────────────────────
function handle_planet_input(_controls) {
    var _ap = global.activePiece;
    if (_ap == undefined || global.locking) return;

    var _prevSide = global.orbitalSide;
    var _lane    = get_orbital_lane_bounds(global.orbitalX);
    var _laneMin = _lane.min;
    var _laneMax = _lane.max;
    global.orbitalX = clamp(global.orbitalX, _laneMin, _laneMax);

    // Side rotation
    if (_controls.rotL) { global.orbitalSide--; global.targetRotation = global.orbitalSide * 90; sfx_piece_move(); }
    if (_controls.rotR) { global.orbitalSide++; global.targetRotation = global.orbitalSide * 90; sfx_piece_move(); }

    // Orbital movement
    if (_controls.moveDir != 0) {
        global.orbitalX += _controls.moveDir;
        if (global.orbitalX < _laneMin) { global.orbitalSide--; global.orbitalX = _laneMax; }
        if (global.orbitalX > _laneMax) { global.orbitalSide++; global.orbitalX = _laneMin; }
        global.targetRotation = global.orbitalSide * 90;
        sfx_piece_move();
    }

    // Re-clamp after side changes (Q/E or wrap) so bounds stay adaptive per side.
    _lane = get_orbital_lane_bounds(global.orbitalX);
    _laneMin = _lane.min;
    _laneMax = _lane.max;
    global.orbitalX = clamp(global.orbitalX, _laneMin, _laneMax);

    // Update position and path
    var _pos = get_orbital_pos(global.orbitalSide, global.orbitalX);
    var _posChanged = (_ap.grid_x != _pos.x || _ap.grid_y != _pos.y);
    _ap.grid_x = _pos.x; _ap.grid_y = _pos.y;
    _ap.x = (_pos.x - global.HIDDEN_SIDES) * 16;
    _ap.y = (_pos.y - global.HIDDEN_ROWS) * 16;

    if (_posChanged || global.previewData == undefined) {
        global.previewData = calculate_planet_preview_path(_ap);
        global.previewDepth = (global.previewData != undefined) ? global.previewData.depth : 1;
    }

    // Preview depth is now fully automatic from path solver.
    // Manual up/down placement nudging removed.

    _ap.rotation = 0;
    if (_prevSide != global.orbitalSide) sfx_piece_move();

    // Charging and firing
    if (_controls.fireHeld) global.launchCharge = min(global.launchCharge + 1, global.MAX_CHARGE);
    if (_controls.fireRel || global.launchCharge >= global.MAX_CHARGE) {
        hard_drop_radial();
    }
}
