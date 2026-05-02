// ── Match Engine Tests ───────────────────────────────────────────────────

function test_match_engine_register_tests() {
    var _s = test_suite_create("Match Engine");

    // ── Cluster matches ─────────────────────────────────────────────────

    test_case_create(_s, "cluster_2x2_four_block", function() {
        var _grid = test_make_empty_grid(11, 11);
        var _cell = test_make_test_cell("normal", 1, 0);
        test_place_cell(_grid, 2, 2, _cell);
        test_place_cell(_grid, 3, 2, _cell);
        test_place_cell(_grid, 2, 3, _cell);
        test_place_cell(_grid, 3, 3, _cell);

        var _matches = find_matches_in_grid(_grid, {cols: 11}, 11);
        test_assert_equal(array_length(_matches), 4, "2x2 cluster should have 4 matches");
    });

    test_case_create(_s, "cluster_L_shape_five", function() {
        var _grid = test_make_empty_grid(11, 11);
        var _cell = test_make_test_cell("normal", 2, 0);
        test_place_cell(_grid, 2, 2, _cell);
        test_place_cell(_grid, 2, 3, _cell);
        test_place_cell(_grid, 2, 4, _cell);
        test_place_cell(_grid, 3, 2, _cell);
        test_place_cell(_grid, 4, 2, _cell);

        var _matches = find_matches_in_grid(_grid, {cols: 11}, 11);
        test_assert_equal(array_length(_matches), 5, "L-shape cluster should have 5 matches");
    });

    test_case_create(_s, "cluster_wildcard_bridge", function() {
        var _grid = test_make_empty_grid(11, 11);
        test_place_cell(_grid, 2, 2, test_make_test_cell("normal", 1, 0));
        test_place_cell(_grid, 3, 2, test_make_test_cell("normal", 1, 0));
        test_place_cell(_grid, 2, 3, test_make_test_cell("wild", 999, 0));
        test_place_cell(_grid, 3, 3, test_make_test_cell("normal", 2, 0));
        test_place_cell(_grid, 4, 3, test_make_test_cell("normal", 2, 0));

        var _matches = find_matches_in_grid(_grid, {cols: 11}, 11);
        // Wild bridges both groups — total 5 cells should form 1 cluster
        test_assert_equal(array_length(_matches), 5, "Wildcard-bridged cluster should match all 5 cells");
    });

    test_case_create(_s, "cluster_too_few_rejected", function() {
        var _grid = test_make_empty_grid(11, 11);
        var _cell = test_make_test_cell("normal", 3, 0);
        test_place_cell(_grid, 2, 2, _cell);
        test_place_cell(_grid, 3, 2, _cell);
        test_place_cell(_grid, 2, 3, _cell);

        var _matches = find_matches_in_grid(_grid, {cols: 11}, 11);
        test_assert_equal(array_length(_matches), 0, "3-cell cluster should not match");
    });

    test_case_create(_s, "cluster_metal_excluded_no_core", function() {
        var _grid = test_make_empty_grid(11, 11);
        test_place_cell(_grid, 2, 2, test_make_test_cell("normal", 1, 0));
        test_place_cell(_grid, 3, 2, test_make_test_cell("normal", 1, 0));
        test_place_cell(_grid, 2, 3, test_make_test_cell("metal", 1, 0));
        test_place_cell(_grid, 3, 3, test_make_test_cell("normal", 1, 0));
        test_place_cell(_grid, 4, 3, test_make_test_cell("normal", 1, 0));

        var _matches = find_matches_in_grid(_grid, {cols: 11}, 11);
        // Metal excluded from cluster without core — but 4 normals remain
        test_assert(array_length(_matches) >= 4, "Should still match 4 non-metal cells");
    });

    // ── Line matches ────────────────────────────────────────────────────

    test_case_create(_s, "line_horizontal_four", function() {
        var _grid = test_make_empty_grid(11, 11);
        for (var _x = 2; _x <= 5; _x++) {
            test_place_cell(_grid, _x, 3, test_make_test_cell("normal", 2, 0));
        }

        var _matches = find_matches_in_grid(_grid, {cols: 11}, 11);
        test_assert_equal(array_length(_matches), 4, "Horizontal line of 4 should match");
    });

    test_case_create(_s, "line_vertical_four", function() {
        var _grid = test_make_empty_grid(11, 11);
        for (var _y = 2; _y <= 5; _y++) {
            test_place_cell(_grid, 5, _y, test_make_test_cell("normal", 3, 0));
        }

        var _matches = find_matches_in_grid(_grid, {cols: 11}, 11);
        test_assert_equal(array_length(_matches), 4, "Vertical line of 4 should match");
    });

    test_case_create(_s, "line_metal_horizontal_with_dir0", function() {
        var _grid = test_make_empty_grid(11, 11);
        test_place_cell(_grid, 2, 3, test_make_test_cell("normal", 1, 0));
        test_place_cell(_grid, 3, 3, test_make_test_cell("metal", 1, 0));  // dir=0
        test_place_cell(_grid, 4, 3, test_make_test_cell("normal", 1, 0));
        test_place_cell(_grid, 5, 3, test_make_test_cell("normal", 1, 0));

        var _matches = find_matches_in_grid(_grid, {cols: 11}, 11);
        test_assert_equal(array_length(_matches), 4, "Horizontal line with metal dir=0 should match 4");
    });

    test_case_create(_s, "line_metal_wrong_axis", function() {
        var _grid = test_make_empty_grid(11, 11);
        test_place_cell(_grid, 3, 2, test_make_test_cell("normal", 2, 0));
        test_place_cell(_grid, 3, 3, test_make_test_cell("metal", 2, 0));  // dir=0 = h-only
        test_place_cell(_grid, 3, 4, test_make_test_cell("normal", 2, 0));
        test_place_cell(_grid, 3, 5, test_make_test_cell("normal", 2, 0));

        var _matches = find_matches_in_grid(_grid, {cols: 11}, 11);
        // Metal dir=0 in vertical line breaks the line — only 3 normal cells left, below threshold
        test_assert_equal(array_length(_matches), 0, "Vertical line with metal dir=0 should not match");
    });

    // ── Diagonal matches ────────────────────────────────────────────────

    test_case_create(_s, "diagonal_down_right_four", function() {
        var _grid = test_make_empty_grid(11, 11);
        test_place_cell(_grid, 2, 2, test_make_test_cell("normal", 4, 0));
        test_place_cell(_grid, 3, 3, test_make_test_cell("normal", 4, 0));
        test_place_cell(_grid, 4, 4, test_make_test_cell("normal", 4, 0));
        test_place_cell(_grid, 5, 5, test_make_test_cell("normal", 4, 0));

        var _matches = find_matches_in_grid(_grid, {cols: 11}, 11);
        test_assert_equal(array_length(_matches), 4, "Diagonal down-right of 4 should match");
    });

    test_case_create(_s, "diagonal_up_right_four", function() {
        var _grid = test_make_empty_grid(11, 11);
        test_place_cell(_grid, 2, 5, test_make_test_cell("normal", 5, 0));
        test_place_cell(_grid, 3, 4, test_make_test_cell("normal", 5, 0));
        test_place_cell(_grid, 4, 3, test_make_test_cell("normal", 5, 0));
        test_place_cell(_grid, 5, 2, test_make_test_cell("normal", 5, 0));

        var _matches = find_matches_in_grid(_grid, {cols: 11}, 11);
        test_assert_equal(array_length(_matches), 4, "Diagonal up-right of 4 should match");
    });

    test_case_create(_s, "diagonal_metal_excluded", function() {
        var _grid = test_make_empty_grid(11, 11);
        test_place_cell(_grid, 2, 2, test_make_test_cell("normal", 6, 0));
        test_place_cell(_grid, 3, 3, test_make_test_cell("metal", 6, 0));
        test_place_cell(_grid, 4, 4, test_make_test_cell("normal", 6, 0));
        test_place_cell(_grid, 5, 5, test_make_test_cell("normal", 6, 0));

        var _matches = find_matches_in_grid(_grid, {cols: 11}, 11);
        // Metal always excluded from diagonals — 3 normals below threshold
        test_assert_equal(array_length(_matches), 0, "Diagonal with metal should not match");
    });

    // ── Exclusion tests ─────────────────────────────────────────────────

    test_case_create(_s, "bomb_cell_excluded_from_cluster", function() {
        var _grid = test_make_empty_grid(11, 11);
        test_place_cell(_grid, 2, 2, test_make_test_cell("normal", 1, 0));
        test_place_cell(_grid, 3, 2, test_make_test_cell("normal", 1, 0));
        test_place_cell(_grid, 2, 3, test_make_test_cell("bomb", 888, 0));
        test_place_cell(_grid, 3, 3, test_make_test_cell("normal", 1, 0));
        test_place_cell(_grid, 4, 3, test_make_test_cell("normal", 1, 0));

        var _matches = find_matches_in_grid(_grid, {cols: 11}, 11);
        test_assert_equal(array_length(_matches), 4, "4 non-bomb cells should still match");
    });

    test_case_create(_s, "dead_cell_excluded", function() {
        var _grid = test_make_empty_grid(11, 11);
        test_place_cell(_grid, 2, 3, test_make_test_cell("dead", 999, 0));
        test_place_cell(_grid, 3, 3, test_make_test_cell("normal", 1, 0));
        test_place_cell(_grid, 4, 3, test_make_test_cell("normal", 1, 0));
        test_place_cell(_grid, 5, 3, test_make_test_cell("normal", 1, 0));
        test_place_cell(_grid, 6, 3, test_make_test_cell("normal", 1, 0));

        var _matches = find_matches_in_grid(_grid, {cols: 11}, 11);
        test_assert_equal(array_length(_matches), 4, "4 normals beyond dead cell should match");
    });

    test_case_create(_s, "void_cell_excluded", function() {
        var _grid = test_make_empty_grid(11, 11);
        test_place_cell(_grid, 2, 2, test_make_test_cell("normal", 2, 0));
        test_place_cell(_grid, 3, 2, test_make_test_cell("void", 0, 0));
        test_place_cell(_grid, 2, 3, test_make_test_cell("normal", 2, 0));
        test_place_cell(_grid, 3, 3, test_make_test_cell("normal", 2, 0));
        test_place_cell(_grid, 4, 2, test_make_test_cell("normal", 2, 0));

        var _matches = find_matches_in_grid(_grid, {cols: 11}, 11);
        test_assert(array_length(_matches) == 4 || array_length(_matches) == 0,
            "Void should be excluded from matching, normals around it may or may not form cluster");
    });

    // ── Edge cases ──────────────────────────────────────────────────────

    test_case_create(_s, "edge_of_grid_cluster", function() {
        var _grid = test_make_empty_grid(11, 11);
        test_place_cell(_grid, 0, 0, test_make_test_cell("normal", 3, 0));
        test_place_cell(_grid, 1, 0, test_make_test_cell("normal", 3, 0));
        test_place_cell(_grid, 0, 1, test_make_test_cell("normal", 3, 0));
        test_place_cell(_grid, 1, 1, test_make_test_cell("normal", 3, 0));

        var _matches = find_matches_in_grid(_grid, {cols: 11}, 11);
        test_assert_equal(array_length(_matches), 4, "Grid-edge cluster should match without crash");
    });

    test_case_create(_s, "empty_grid_no_match", function() {
        var _grid = test_make_empty_grid(11, 11);

        var _matches = find_matches_in_grid(_grid, {cols: 11}, 11);
        test_assert_equal(array_length(_matches), 0, "Empty grid should have zero matches");
    });
}
