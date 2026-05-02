// ── Match Contracts Tests ────────────────────────────────────────────────

function test_contracts_register_tests() {
    var _s = test_suite_create("Match Contracts");

    // ── match_cells_share_color ──────────────────────────────────────────

    test_case_create(_s, "share_color_same_id", function() {
        var _c1 = test_make_test_cell("normal", 3, 0);
        var _c2 = test_make_test_cell("normal", 3, 0);
        test_assert(match_cells_share_color(_c1, _c2), "Same color id should share color");
    });

    test_case_create(_s, "share_color_different_id", function() {
        var _c1 = test_make_test_cell("normal", 1, 0);
        var _c2 = test_make_test_cell("normal", 2, 0);
        test_assert(!match_cells_share_color(_c1, _c2), "Different color ids should not share");
    });

    test_case_create(_s, "share_color_wildcard", function() {
        var _c1 = test_make_test_cell("normal", 4, 0);
        var _c2 = test_make_test_cell("wild", 999, 0);
        test_assert(match_cells_share_color(_c1, _c2), "Wild should share color with any normal");
    });

    test_case_create(_s, "share_color_wildcard_both", function() {
        var _c1 = test_make_test_cell("wild", 999, 0);
        var _c2 = test_make_test_cell("wild", 999, 0);
        test_assert(match_cells_share_color(_c1, _c2), "Two wilds should share color");
    });

    test_case_create(_s, "share_color_undefined_c1", function() {
        var _c2 = test_make_test_cell("normal", 1, 0);
        test_assert(!match_cells_share_color(undefined, _c2), "Undefined c1 should return false");
    });

    test_case_create(_s, "share_color_undefined_c2", function() {
        var _c1 = test_make_test_cell("normal", 1, 0);
        test_assert(!match_cells_share_color(_c1, undefined), "Undefined c2 should return false");
    });

    test_case_create(_s, "share_color_normal_and_dead", function() {
        var _c1 = test_make_test_cell("normal", 1, 0);
        var _c2 = test_make_test_cell("dead", 999, 0);
        _c2.id = 1; // dead with same color id
        test_assert(!match_cells_share_color(_c1, _c2), "Dead block should not share color");
    });

    // ── match_arrow_allows_axis ─────────────────────────────────────────

    test_case_create(_s, "arrow_allows_normal_h", function() {
        var _c = test_make_test_cell("normal", 1, 0);
        test_assert(match_arrow_allows_axis(_c, "h"), "Normal should allow horizontal");
    });

    test_case_create(_s, "arrow_allows_normal_v", function() {
        var _c = test_make_test_cell("normal", 1, 0);
        test_assert(match_arrow_allows_axis(_c, "v"), "Normal should allow vertical");
    });

    test_case_create(_s, "arrow_allows_normal_d", function() {
        var _c = test_make_test_cell("normal", 1, 0);
        test_assert(match_arrow_allows_axis(_c, "d"), "Normal should allow diagonal");
    });

    test_case_create(_s, "arrow_allows_metal_h_with_dir0", function() {
        var _c = test_make_test_cell("metal", 1, 0);
        test_assert(match_arrow_allows_axis(_c, "h"), "Metal dir=0 should allow horizontal");
    });

    test_case_create(_s, "arrow_allows_metal_v_with_dir0", function() {
        var _c = test_make_test_cell("metal", 1, 0);
        test_assert(!match_arrow_allows_axis(_c, "v"), "Metal dir=0 should NOT allow vertical");
    });

    test_case_create(_s, "arrow_allows_metal_d_with_dir0", function() {
        var _c = test_make_test_cell("metal", 1, 0);
        test_assert(!match_arrow_allows_axis(_c, "d"), "Metal dir=0 should NOT allow diagonal");
    });

    test_case_create(_s, "arrow_allows_metal_h_with_dir1", function() {
        var _c = test_make_test_cell("metal", 1, 1);
        test_assert(!match_arrow_allows_axis(_c, "h"), "Metal dir=1 should NOT allow horizontal");
    });

    test_case_create(_s, "arrow_allows_metal_v_with_dir1", function() {
        var _c = test_make_test_cell("metal", 1, 1);
        test_assert(match_arrow_allows_axis(_c, "v"), "Metal dir=1 should allow vertical");
    });

    test_case_create(_s, "arrow_allows_undefined", function() {
        test_assert(!match_arrow_allows_axis(undefined, "h"), "Undefined should not allow any axis");
    });

    test_case_create(_s, "arrow_allows_core_non_directional", function() {
        var _c = test_make_test_cell("core", 1, 0);
        _c.core_arrow = false;
        test_assert(match_arrow_allows_axis(_c, "h"), "Non-directional core should allow any axis");
    });

    test_case_create(_s, "arrow_allows_core_directional_h", function() {
        var _c = test_make_test_cell("core", 1, 0);
        _c.core_arrow = true;
        test_assert(match_arrow_allows_axis(_c, "h"), "Directional core dir=0 should allow horizontal");
    });

    test_case_create(_s, "arrow_allows_core_directional_v", function() {
        var _c = test_make_test_cell("core", 1, 0);
        _c.core_arrow = true;
        test_assert(!match_arrow_allows_axis(_c, "v"), "Directional core dir=0 should NOT allow vertical");
    });

    // ── match_cell_is_excluded ──────────────────────────────────────────

    test_case_create(_s, "is_excluded_undefined", function() {
        test_assert(match_cell_is_excluded(undefined), "Undefined cell should be excluded");
    });

    test_case_create(_s, "is_excluded_bomb", function() {
        var _c = test_make_test_cell("bomb", 888, 0);
        test_assert(match_cell_is_excluded(_c), "Bomb should be excluded");
    });

    test_case_create(_s, "is_excluded_dead", function() {
        var _c = test_make_test_cell("dead", 999, 0);
        test_assert(match_cell_is_excluded(_c), "Dead should be excluded");
    });

    test_case_create(_s, "is_excluded_drill", function() {
        var _c = test_make_test_cell("drill", 777, 0);
        test_assert(match_cell_is_excluded(_c), "Drill should be excluded");
    });

    test_case_create(_s, "is_excluded_void", function() {
        var _c = test_make_test_cell("void", 0, 0);
        test_assert(match_cell_is_excluded(_c), "Void should be excluded");
    });

    test_case_create(_s, "is_excluded_normal", function() {
        var _c = test_make_test_cell("normal", 1, 0);
        test_assert(!match_cell_is_excluded(_c), "Normal should not be excluded");
    });

    test_case_create(_s, "is_excluded_metal", function() {
        var _c = test_make_test_cell("metal", 2, 0);
        test_assert(!match_cell_is_excluded(_c), "Metal should not be excluded");
    });

    test_case_create(_s, "is_excluded_core", function() {
        var _c = test_make_test_cell("core", 3, 0);
        test_assert(!match_cell_is_excluded(_c), "Core should not be excluded");
    });

    // ── match_cells_can_link ────────────────────────────────────────────

    test_case_create(_s, "can_link_normal_pair_h", function() {
        var _c1 = test_make_test_cell("normal", 1, 0);
        var _c2 = test_make_test_cell("normal", 1, 0);
        test_assert(match_cells_can_link(_c1, _c2, "h"), "Same-color normals should link horizontally");
    });

    test_case_create(_s, "can_link_normal_pair_v", function() {
        var _c1 = test_make_test_cell("normal", 1, 0);
        var _c2 = test_make_test_cell("normal", 1, 0);
        test_assert(match_cells_can_link(_c1, _c2, "v"), "Same-color normals should link vertically");
    });

    test_case_create(_s, "can_link_normal_pair_d", function() {
        var _c1 = test_make_test_cell("normal", 1, 0);
        var _c2 = test_make_test_cell("normal", 1, 0);
        test_assert(match_cells_can_link(_c1, _c2, "d"), "Same-color normals should link diagonally");
    });

    test_case_create(_s, "can_link_diff_color", function() {
        var _c1 = test_make_test_cell("normal", 1, 0);
        var _c2 = test_make_test_cell("normal", 2, 0);
        test_assert(!match_cells_can_link(_c1, _c2, "h"), "Different colors should not link");
    });

    test_case_create(_s, "can_link_metal_wrong_axis", function() {
        var _c1 = test_make_test_cell("metal", 1, 0); // dir=0, h-only
        var _c2 = test_make_test_cell("normal", 1, 0);
        test_assert(!match_cells_can_link(_c1, _c2, "v"), "Metal dir=0 should not link vertically");
    });

    test_case_create(_s, "can_link_metal_correct_axis", function() {
        var _c1 = test_make_test_cell("metal", 1, 0);
        var _c2 = test_make_test_cell("normal", 1, 0);
        test_assert(match_cells_can_link(_c1, _c2, "h"), "Metal dir=0 should link horizontally with same color");
    });

    test_case_create(_s, "can_link_metal_cluster_nocore", function() {
        var _c1 = test_make_test_cell("metal", 1, 0);
        var _c2 = test_make_test_cell("normal", 1, 0);
        test_assert(!match_cells_can_link(_c1, _c2, "h", false), "Metal in cluster without core should not link");
    });

    test_case_create(_s, "can_link_metal_cluster_with_core", function() {
        var _c1 = test_make_test_cell("metal", 1, 0);
        var _c2 = test_make_test_cell("core", 1, 0);
        test_assert(match_cells_can_link(_c1, _c2, "h", false), "Metal linking to core in cluster should be allowed");
    });

    test_case_create(_s, "can_link_excluded_bomb", function() {
        var _c1 = test_make_test_cell("bomb", 888, 0);
        var _c2 = test_make_test_cell("normal", 1, 0);
        test_assert(!match_cells_can_link(_c1, _c2, "h"), "Bomb should not link");
    });

    test_case_create(_s, "can_link_excluded_dead_normal", function() {
        var _c1 = test_make_test_cell("dead", 999, 0);
        var _c2 = test_make_test_cell("normal", 1, 0);
        test_assert(!match_cells_can_link(_c1, _c2, "h"), "Dead should not link with normal");
    });

    test_case_create(_s, "can_link_wildcard_with_normal", function() {
        var _c1 = test_make_test_cell("wild", 999, 0);
        var _c2 = test_make_test_cell("normal", 4, 0);
        test_assert(match_cells_can_link(_c1, _c2, "h"), "Wild should link with any normal");
    });

    test_case_create(_s, "can_link_core_non_directional", function() {
        var _c1 = test_make_test_cell("core", 1, 0);
        _c1.core_arrow = false;
        var _c2 = test_make_test_cell("normal", 1, 0);
        test_assert(match_cells_can_link(_c1, _c2, "v"), "Non-directional core should link any axis");
    });

    test_case_create(_s, "can_link_core_arrow_wrong_axis", function() {
        var _c1 = test_make_test_cell("core", 1, 0); // dir=0
        _c1.core_arrow = true;
        var _c2 = test_make_test_cell("normal", 1, 0);
        test_assert(!match_cells_can_link(_c1, _c2, "v"), "Directional core dir=0 should NOT link vertically");
    });
}
