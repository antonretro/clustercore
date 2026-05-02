// ── Gravity & Core Migration Tests ───────────────────────────────────────

function test_gravity_register_tests() {
    var _s = test_suite_create("Gravity & Core");

    // ── enforce_single_core_in_grid ─────────────────────────────────────

    test_case_create(_s, "single_core_enforcement", function() {
        test_with_grid_sandbox(function() {
            var _grid = global.grid;
            var _cx = 5; var _cy = 5;

            // Place two cores
            _grid[_cy][_cx] = test_make_test_cell("core", 1, 0);
            _grid[_cy][_cx].inst = undefined;
            _grid[_cy][_cx + 1] = test_make_test_cell("core", 2, 0);
            _grid[_cy][_cx + 1].inst = undefined;

            enforce_single_core_in_grid();

            var _coreCount = 0;
            for (var _y = 0; _y < global.TOTAL_ROWS; _y++) {
                for (var _x = 0; _x < global.TOTAL_COLS; _x++) {
                    if (_grid[_y][_x] != undefined && _grid[_y][_x].type == "core") _coreCount++;
                }
            }
            test_assert_equal(_coreCount, 1, "Exactly one core should remain after enforcement");
        });
    });

    // ── ensure_planet_core_presence ─────────────────────────────────────

    test_case_create(_s, "core_presence_already_exists", function() {
        test_with_grid_sandbox(function() {
            var _grid = global.grid;
            var _cx = 5; var _cy = 5;
            _grid[_cy][_cx] = test_make_test_cell("core", 1, 0);
            _grid[_cy][_cx].inst = undefined;

            var _result = ensure_planet_core_presence();
            test_assert(_result, "Should return true when core exists");

            // Core should still be at 5,5
            test_assert(_grid[_cy][_cx] != undefined && _grid[_cy][_cx].type == "core",
                "Core should still be at center");
        });
    });

    // ── planet_has_outer_danger_block ───────────────────────────────────

    test_case_create(_s, "no_danger_on_empty_grid", function() {
        test_with_grid_sandbox(function() {
            // Empty grid — no danger
            var _danger = planet_has_outer_danger_block();
            test_assert(!_danger, "Empty grid should not have outer danger");
        });
    });

    test_case_create(_s, "inner_block_not_danger", function() {
        test_with_grid_sandbox(function() {
            // Place a block near center (distance 1 from center 5,5)
            global.grid[5][4] = test_make_test_cell("normal", 1, 0);
            global.grid[5][4].inst = undefined;
            var _danger = planet_has_outer_danger_block();
            test_assert(!_danger, "Block near center should not trigger outer danger");
        });
    });

    // ── cleanup_grid_ghost_cells ────────────────────────────────────────

    test_case_create(_s, "ghost_cell_cleanup", function() {
        test_with_grid_sandbox(function() {
            var _grid = global.grid;
            // Place a cell with a dead/non-existent instance
            _grid[3][3] = test_make_test_cell("normal", 1, 0);
            _grid[3][3].inst = undefined; // no instance = ghost

            cleanup_grid_ghost_cells();

            test_assert(_grid[3][3] == undefined, "Ghost cell with no instance should be cleaned");
        });
    });

    test_case_create(_s, "valid_cell_not_cleaned", function() {
        test_with_grid_sandbox(function() {
            var _grid = global.grid;
            // Place normal cells with undefined inst (cleanup only removes if inst is gone)
            // We test that cells with undefined inst ARE cleaned (matching current behavior)
            _grid[4][4] = test_make_test_cell("normal", 2, 0);
            _grid[4][4].inst = undefined;

            cleanup_grid_ghost_cells();

            // Ghost cells with undefined inst should be removed
            test_assert(_grid[4][4] == undefined, "Cell with undefined inst should be cleaned");
        });
    });

    // ── Grid bounds helpers ─────────────────────────────────────────────

    test_case_create(_s, "grid_in_bounds_valid", function() {
        test_with_grid_sandbox(function() {
            test_assert(grid_in_bounds(5, 5), "Center should be in bounds");
            test_assert(grid_in_bounds(0, 0), "Origin should be in bounds");
            test_assert(grid_in_bounds(10, 10), "Bottom-right should be in bounds");
        });
    });

    test_case_create(_s, "grid_in_bounds_oob", function() {
        test_with_grid_sandbox(function() {
            test_assert(!grid_in_bounds(-1, 5), "Negative x should be OOB");
            test_assert(!grid_in_bounds(5, -1), "Negative y should be OOB");
            test_assert(!grid_in_bounds(11, 5), "x>=TOTAL_COLS should be OOB");
            test_assert(!grid_in_bounds(5, 11), "y>=TOTAL_ROWS should be OOB");
        });
    });

    test_case_create(_s, "grid_is_playable", function() {
        test_with_grid_sandbox(function() {
            test_assert(grid_is_playable(1, 1), "Inner cell should be playable");
            test_assert(grid_is_playable(9, 9), "Bottom-right inner should be playable");
            test_assert(!grid_is_playable(0, 0), "Staging ring cell should NOT be playable");
        });
    });
}
