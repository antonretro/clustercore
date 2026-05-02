// ── Level Generation Tests ───────────────────────────────────────────────

function test_level_gen_register_tests() {
    var _s = test_suite_create("Level Generation");

    // ── Catalog structure ───────────────────────────────────────────────

    test_case_create(_s, "catalog_has_30_levels", function() {
        var _cat = story_level_catalog();
        test_assert_equal(array_length(_cat), 30, "Catalog should have exactly 30 levels (5 worlds x 6)");
    });

    test_case_create(_s, "all_defs_have_required_fields", function() {
        var _cat = story_level_catalog();
        for (var i = 0; i < array_length(_cat); i++) {
            var _def = _cat[i];
            test_assert(variable_struct_exists(_def, "world_id"), "Level " + string(i) + " missing world_id");
            test_assert(variable_struct_exists(_def, "level_id"), "Level " + string(i) + " missing level_id");
            test_assert(variable_struct_exists(_def, "seed"), "Level " + string(i) + " missing seed");
            test_assert(variable_struct_exists(_def, "palette_count"), "Level " + string(i) + " missing palette_count");
            test_assert(variable_struct_exists(_def, "objective"), "Level " + string(i) + " missing objective");
        }
    });

    test_case_create(_s, "def_lookup_matches", function() {
        var _def = story_get_level_def(2, 3);
        test_assert(_def != undefined, "Should find world=2 level=3");
        test_assert_equal(_def.world_id, 2, "World ID should be 2");
        test_assert_equal(_def.level_id, 3, "Level ID should be 3");
    });

    test_case_create(_s, "def_lookup_missing", function() {
        var _def = story_get_level_def(99, 99);
        test_assert(_def == undefined, "Non-existent level should return undefined");
    });

    test_case_create(_s, "all_level_seeds_unique", function() {
        var _cat = story_level_catalog();
        var _seeds = {};
        for (var i = 0; i < array_length(_cat); i++) {
            var _sd = string(_cat[i].seed);
            test_assert(!variable_struct_exists(_seeds, _sd), "Duplicate seed found: " + _sd);
            _seeds[$ _sd] = true;
        }
    });

    // ── World/level distribution ────────────────────────────────────────

    test_case_create(_s, "world_ids_0_to_4", function() {
        var _cat = story_level_catalog();
        var _worlds = [0, 0, 0, 0, 0];
        for (var i = 0; i < array_length(_cat); i++) {
            _worlds[_cat[i].world_id]++;
        }
        for (var w = 0; w < 5; w++) {
            test_assert_equal(_worlds[w], 6, "World " + string(w) + " should have 6 levels");
        }
    });

    test_case_create(_s, "world_0_has_turn_limits", function() {
        var _cat = story_level_catalog();
        for (var i = 0; i < array_length(_cat); i++) {
            if (_cat[i].world_id == 0 && _cat[i].level_id <= 4) {
                test_assert(variable_struct_exists(_cat[i], "turn_limit"),
                    "Tin Moon level " + string(_cat[i].level_id) + " should have turn_limit");
            }
        }
    });

    test_case_create(_s, "world_0_level_5_clear_cores", function() {
        var _def = story_get_level_def(0, 5);
        test_assert(_def.objective.type == "clear_cores", "World 0 level 5 should be clear_cores");
        test_assert_equal(_def.objective.value, 6, "World 0 level 5 should clear 6 cores");
    });

    test_case_create(_s, "world_2_level_5_clear_cores_12", function() {
        var _def = story_get_level_def(2, 5);
        test_assert(_def.objective.type == "clear_cores", "World 2 level 5 should be clear_cores");
        test_assert_equal(_def.objective.value, 12, "World 2 level 5 should clear 12 cores");
    });

    test_case_create(_s, "world_4_level_5_clear_cores_20", function() {
        var _def = story_get_level_def(4, 5);
        test_assert(_def.objective.type == "clear_cores", "World 4 level 5 should be clear_cores");
        test_assert_equal(_def.objective.value, 20, "World 4 level 5 should clear 20 cores");
    });

    // ── Palette application ────────────────────────────────────────────

    test_case_create(_s, "palette_count_3", function() {
        var _oldColors = global.activeColors;
        var _oldReserve = global.reserveColors;

        var _def = { palette_count: 3 };
        story_apply_level_palette(_def, 42);
        test_assert_equal(array_length(global.activeColors), 3, "palette_count=3 should give 3 active colors");

        global.activeColors = _oldColors;
        global.reserveColors = _oldReserve;
    });

    test_case_create(_s, "palette_count_4", function() {
        var _oldColors = global.activeColors;
        var _oldReserve = global.reserveColors;

        var _def = { palette_count: 4 };
        story_apply_level_palette(_def, 42);
        test_assert_equal(array_length(global.activeColors), 4, "palette_count=4 should give 4 active colors");

        global.activeColors = _oldColors;
        global.reserveColors = _oldReserve;
    });

    test_case_create(_s, "palette_count_5", function() {
        var _oldColors = global.activeColors;
        var _oldReserve = global.reserveColors;

        var _def = { palette_count: 5 };
        story_apply_level_palette(_def, 42);
        test_assert_equal(array_length(global.activeColors), 5, "palette_count=5 should give 5 active colors");

        global.activeColors = _oldColors;
        global.reserveColors = _oldReserve;
    });

    test_case_create(_s, "full_palette_flag", function() {
        var _oldColors = global.activeColors;
        var _oldReserve = global.reserveColors;

        var _def = { palette_count: 3, full_palette: true };
        story_apply_level_palette(_def, 42);
        test_assert_equal(array_length(global.activeColors), 6, "full_palette=true should give 6 active colors");

        global.activeColors = _oldColors;
        global.reserveColors = _oldReserve;
    });

    test_case_create(_s, "seed_determinism", function() {
        var _oldColors = global.activeColors;
        var _oldReserve = global.reserveColors;

        story_apply_level_palette({ palette_count: 3 }, 100);
        var _colors1 = [];
        for (var c = 0; c < array_length(global.activeColors); c++) _colors1[c] = global.activeColors[c];

        story_apply_level_palette({ palette_count: 3 }, 100);
        var _colors2 = [];
        for (var c = 0; c < array_length(global.activeColors); c++) _colors2[c] = global.activeColors[c];

        test_assert_equal(array_length(_colors1), array_length(_colors2), "Same seed should give same count");
        for (var d = 0; d < array_length(_colors1); d++) {
            test_assert_equal(_colors1[d], _colors2[d], "Same seed should give same colors at index " + string(d));
        }

        global.activeColors = _oldColors;
        global.reserveColors = _oldReserve;
    });

    // ── Piece RNG ───────────────────────────────────────────────────────

    test_case_create(_s, "piece_rng_deterministic", function() {
        piece_rng_seed(42);
        var _seq1 = [];
        for (var i = 0; i < 5; i++) {
            _seq1[i] = piece_rng_next_unit();
        }

        piece_rng_seed(42);
        var _seq2 = [];
        for (var i = 0; i < 5; i++) {
            _seq2[i] = piece_rng_next_unit();
        }

        for (var j = 0; j < 5; j++) {
            test_assert(abs(_seq1[j] - _seq2[j]) < 0.0001,
                "Same seed should produce same sequence at index " + string(j));
        }
    });

    test_case_create(_s, "piece_rng_different_seeds", function() {
        piece_rng_seed(1);
        var _s1 = piece_rng_next_unit();
        piece_rng_seed(2);
        var _s2 = piece_rng_next_unit();
        test_assert(abs(_s1 - _s2) > 0.0001, "Different seeds should produce different values");
    });

    // ── make_piece_data ─────────────────────────────────────────────────

    test_case_create(_s, "make_piece_data_normal", function() {
        var _p = make_piece_data("normal", 3, 0);
        test_assert(_p != undefined, "Should return a struct");
        test_assert_equal(_p.type, "normal", "Type should be normal");
        test_assert_equal(_p.id, 3, "ID should be 3");
        test_assert_equal(_p.dir, 0, "Dir should be 0");
    });

    test_case_create(_s, "make_piece_data_wild", function() {
        var _p = make_piece_data("wild", 999, 0);
        test_assert_equal(_p.type, "wild", "Type should be wild");
        test_assert_equal(_p.id, 999, "Wild should have id 999");
        test_assert_equal(_p.color, c_white, "Wild should be white");
    });

    test_case_create(_s, "make_piece_data_asteroid", function() {
        var _p = make_piece_data("asteroid", 1, 0);
        test_assert(variable_struct_exists(_p, "shield_hp"), "Asteroid should have shield_hp");
        test_assert_equal(_p.shield_hp, 2, "Asteroid should have 2 shield HP");
    });

    test_case_create(_s, "make_piece_data_locked", function() {
        var _p = make_piece_data("locked", 1, 0);
        test_assert(variable_struct_exists(_p, "locked_hp"), "Locked should have locked_hp");
        test_assert_equal(_p.locked_hp, 2, "Locked should have 2 HP");
    });

    test_case_create(_s, "make_piece_data_multiplier", function() {
        var _p = make_piece_data("multiplier", 1, 0);
        test_assert(variable_struct_exists(_p, "special_value"), "Multiplier should have special_value");
        test_assert_equal(_p.special_value, 2, "Multiplier should have special_value=2");
    });

    test_case_create(_s, "make_piece_data_metal", function() {
        var _p = make_piece_data("metal", 2, 0);
        test_assert_equal(_p.type, "metal", "Type should be metal");
        test_assert_equal(_p.dir, 0, "Dir should default to 0");
    });

    test_case_create(_s, "make_piece_data_metal_dir1", function() {
        var _p = make_piece_data("metal", 2, 1);
        test_assert_equal(_p.dir, 1, "Dir should be 1 when specified");
    });

    // ── get_color_from_id ───────────────────────────────────────────────

    test_case_create(_s, "get_color_from_id_range", function() {
        for (var i = 1; i <= 6; i++) {
            var _col = get_color_from_id(i);
            test_assert(_col != 0 && _col != undefined, "get_color_from_id(" + string(i) + ") should return valid color");
        }
    });
}
