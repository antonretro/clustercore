// =============================================================================
// scr_story_dialogue — Story plot + dialogue box
// =============================================================================
//
// Features:
// - Safe globals without wiping active dialogue
// - Typewriter text
// - Advance / skip input
// - Optional finish callback
// - Per-line speed support
// - Responsive GUI box
// - Story scene catalogue
// =============================================================================


// =============================================================================
// STORY CATALOGUE
// =============================================================================

function story_plot_catalog() {
    return {
        intro_0: [
            { speaker: "Operator", text: "Tin Moon is quiet. Good. Quiet means the board is still listening.", speed: 1 },
            { speaker: "Core", text: "Place four. Break one. Wake me slowly.", speed: 2 }
        ],

        intro_1: [
            { speaker: "Operator", text: "Rust Garden is clogged with dead blocks. Do not build pretty. Build exits.", speed: 1 },
            { speaker: "Core", text: "Rot spreads where players panic.", speed: 2 }
        ],

        intro_2: [
            { speaker: "Operator", text: "Casino Comet pays well if you stop chasing every shiny setup.", speed: 1 },
            { speaker: "Core", text: "Greed is useful. Until it starts steering.", speed: 2 }
        ],

        intro_3: [
            { speaker: "Operator", text: "Dead Orbit gives you fewer safe lanes. Every bad drop becomes part of the planet.", speed: 1 },
            { speaker: "Core", text: "Survive first. Score later.", speed: 2 }
        ],

        intro_4: [
            { speaker: "Operator", text: "Cluster Core is not a planet. It is the lock around the sun gate.", speed: 1 },
            { speaker: "Core", text: "Break me enough times and I will open.", speed: 2 }
        ],

        select_0: [
            { speaker: "System", text: "Tin Moon route selected. Stable lanes. Low pressure. Good for learning core breaks.", speed: 1 }
        ],

        select_1: [
            { speaker: "System", text: "Rust Garden route selected. Dead blocks will clog bad plans fast.", speed: 1 }
        ],

        select_2: [
            { speaker: "System", text: "Casino Comet route selected. Bigger clears. Bigger punishment for sloppy drops.", speed: 1 }
        ],

        select_3: [
            { speaker: "System", text: "Dead Orbit route selected. Lane control is now survival, not style.", speed: 1 }
        ],

        select_4: [
            { speaker: "System", text: "Cluster Core route selected. Final resonance chamber unlocked.", speed: 1 }
        ],

        world_open_0: [
            { speaker: "Operator", text: "Tin Moon mission set. Four stabilizer levels queued.", speed: 1 }
        ],

        world_open_1: [
            { speaker: "Operator", text: "Rust Garden loaded. Keep your lanes clean before the dead flow spreads.", speed: 1 }
        ],

        world_open_2: [
            { speaker: "Operator", text: "Casino Comet armed. The board will tempt you. Do not let it steer.", speed: 1 }
        ],

        world_open_3: [
            { speaker: "Operator", text: "Dead Orbit online. Save your outs. A filled lane is a warning, not decoration.", speed: 1 }
        ],

        world_open_4: [
            { speaker: "Operator", text: "Cluster Core channel open. This one checks everything you learned.", speed: 1 }
        ],

        between_0: [
            { speaker: "Operator", text: "Tin Moon stabilized. The next orbital lane is opening.", speed: 1 },
            { speaker: "Core", text: "Again. Cleaner this time.", speed: 2 }
        ],

        between_1: [
            { speaker: "Operator", text: "Rust Garden secured. Less debris, louder signal.", speed: 1 },
            { speaker: "Core", text: "The rot moved. So did I.", speed: 2 }
        ],

        between_2: [
            { speaker: "Operator", text: "Casino Comet cleared. Profit curve spiked, but the core survived it.", speed: 1 },
            { speaker: "Core", text: "Risk fed me. Barely.", speed: 2 }
        ],

        between_3: [
            { speaker: "Operator", text: "Dead Orbit survived. One final approach remains.", speed: 1 },
            { speaker: "Core", text: "No more practice loops.", speed: 2 }
        ],

        between_4: [
            { speaker: "Core", text: "All loops complete. Set course for the Sun Gate.", speed: 2 }
        ],

        sun_goal: [
            { speaker: "Operator", text: "All planetary loops converged. Solar gate opening.", speed: 1 },
            { speaker: "Core", text: "One final ignition. Feed the sun and become more than an operator.", speed: 2 }
        ],

        intro_default: [
            { speaker: "Core", text: "Maintain flow. Build the chain. Reach the sun.", speed: 2 }
        ]
    };
}


// =============================================================================
// GLOBAL SETUP
// =============================================================================

function dialogue_ensure_globals() {
    if (!variable_global_exists("dialogue_active")) global.dialogue_active = false;
    if (!variable_global_exists("dialogue_lines")) global.dialogue_lines = [];
    if (!variable_global_exists("dialogue_index")) global.dialogue_index = 0;
    if (!variable_global_exists("dialogue_char_index")) global.dialogue_char_index = 0;
    if (!variable_global_exists("dialogue_char_timer")) global.dialogue_char_timer = 0;
    if (!variable_global_exists("dialogue_char_speed")) global.dialogue_char_speed = 1;
    if (!variable_global_exists("dialogue_scene_id")) global.dialogue_scene_id = "";
    if (!variable_global_exists("dialogue_speaker")) global.dialogue_speaker = "";
    if (!variable_global_exists("dialogue_on_finish")) global.dialogue_on_finish = "";
    if (!variable_global_exists("dialogue_block_game_input")) global.dialogue_block_game_input = true;

    if (!variable_global_exists("story_seen_scenes")) global.story_seen_scenes = {};
}


function dialogue_init() {
    global.dialogue_active = false;
    global.dialogue_lines = [];
    global.dialogue_index = 0;
    global.dialogue_char_index = 0;
    global.dialogue_char_timer = 0;
    global.dialogue_char_speed = 1;
    global.dialogue_scene_id = "";
    global.dialogue_speaker = "";
    global.dialogue_on_finish = "";
    global.dialogue_block_game_input = true;

    if (!variable_global_exists("story_seen_scenes")) {
        global.story_seen_scenes = {};
    }
}


function dialogue_is_active() {
    dialogue_ensure_globals();
    return global.dialogue_active;
}


// =============================================================================
// SCENE LOOKUP
// =============================================================================

function story_get_scene_id_for_planet(_planetIndex) {
    return "intro_" + string(_planetIndex);
}


function story_get_lines(_sceneId) {
    var _cat = story_plot_catalog();

    if (variable_struct_exists(_cat, _sceneId)) {
        return _cat[$ _sceneId];
    }

    return _cat.intro_default;
}


// =============================================================================
// START / FINISH
// =============================================================================

function dialogue_start(_scene_id, _lines, _onFinish = "") {
    dialogue_ensure_globals();

    if (_lines == undefined) return false;
    if (array_length(_lines) <= 0) return false;

    global.dialogue_active = true;
    global.dialogue_scene_id = _scene_id;
    global.dialogue_lines = _lines;
    global.dialogue_index = 0;
    global.dialogue_char_index = 0;
    global.dialogue_char_timer = 0;
    global.dialogue_on_finish = _onFinish;

    var _first = global.dialogue_lines[0];

    if (variable_struct_exists(_first, "speaker")) {
        global.dialogue_speaker = _first.speaker;
    } else {
        global.dialogue_speaker = "System";
    }

    return true;
}


function dialogue_start_scene(_sceneId, _onFinish = "") {
    var _lines = story_get_lines(_sceneId);
    return dialogue_start(_sceneId, _lines, _onFinish);
}


function dialogue_finish() {
    dialogue_ensure_globals();

    var _callback = global.dialogue_on_finish;

    global.dialogue_active = false;
    global.dialogue_lines = [];
    global.dialogue_index = 0;
    global.dialogue_char_index = 0;
    global.dialogue_char_timer = 0;
    global.dialogue_scene_id = "";
    global.dialogue_speaker = "";
    global.dialogue_on_finish = "";

    if (_callback == "start_game") {
        with (obj_game_manager) {
            start_game();
        }
        return;
    }

    if (_callback == "advance_story_planet") {
        story_advance_planet();
        return;
    }

    if (_callback == "open_sun_goal") {
        dialogue_start_scene("sun_goal");
        return;
    }
}


function dialogue_cancel() {
    dialogue_ensure_globals();

    global.dialogue_active = false;
    global.dialogue_lines = [];
    global.dialogue_index = 0;
    global.dialogue_char_index = 0;
    global.dialogue_char_timer = 0;
    global.dialogue_scene_id = "";
    global.dialogue_speaker = "";
    global.dialogue_on_finish = "";
}


// =============================================================================
// STORY HELPERS
// =============================================================================

function story_try_start_level_dialogue() {
    dialogue_ensure_globals();

    if (global.gameMode != "STORY") return false;

    var _sceneId = story_get_scene_id_for_planet(global.storyPlanet);

    if (variable_struct_exists(global.story_seen_scenes, _sceneId)) {
        return false;
    }

    var _started = dialogue_start_scene(_sceneId);

    if (_started) {
        global.story_seen_scenes[$ _sceneId] = true;
    }

    return _started;
}


function story_start_between_level_dialogue(_planetIndex) {
    dialogue_ensure_globals();

    var _sceneId = "between_" + string(_planetIndex);
    var _cat = story_plot_catalog();

    if (!variable_struct_exists(_cat, _sceneId)) {
        return false;
    }

    return dialogue_start_scene(_sceneId);
}


function story_start_world_open_dialogue(_worldIndex) {
    var _sceneId = "world_open_" + string(_worldIndex);
    return dialogue_start_scene(_sceneId);
}


function story_start_select_dialogue(_worldIndex) {
    var _sceneId = "select_" + string(_worldIndex);
    return dialogue_start_scene(_sceneId);
}


// =============================================================================
// INPUT
// =============================================================================

function dialogue_input_advance_pressed() {
    var _gp = gamepad_is_connected(0);

    if (keyboard_check_pressed(vk_enter)) return true;
    if (keyboard_check_pressed(vk_space)) return true;
    if (keyboard_check_pressed(ord("Z"))) return true;
    if (_gp && gamepad_button_check_pressed(0, gp_face1)) return true;

    return false;
}


function dialogue_input_skip_pressed() {
    var _gp = gamepad_is_connected(0);

    if (keyboard_check_pressed(vk_escape)) return true;
    if (keyboard_check_pressed(ord("X"))) return true;
    if (_gp && gamepad_button_check_pressed(0, gp_face2)) return true;

    return false;
}


// =============================================================================
// UPDATE
// =============================================================================

function dialogue_get_current_line() {
    dialogue_ensure_globals();

    if (array_length(global.dialogue_lines) <= 0) return undefined;
    if (global.dialogue_index < 0) return undefined;
    if (global.dialogue_index >= array_length(global.dialogue_lines)) return undefined;

    return global.dialogue_lines[global.dialogue_index];
}


function dialogue_get_line_text(_line) {
    if (_line == undefined) return "";

    if (variable_struct_exists(_line, "text")) {
        return _line.text;
    }

    return "";
}


function dialogue_get_line_speaker(_line) {
    if (_line == undefined) return "System";

    if (variable_struct_exists(_line, "speaker")) {
        return _line.speaker;
    }

    return "System";
}


function dialogue_get_line_speed(_line) {
    if (_line != undefined && variable_struct_exists(_line, "speed")) {
        return max(1, _line.speed);
    }

    return max(1, global.dialogue_char_speed);
}


function dialogue_go_to_next_line() {
    global.dialogue_index++;

    if (global.dialogue_index >= array_length(global.dialogue_lines)) {
        dialogue_finish();
        return;
    }

    var _line = global.dialogue_lines[global.dialogue_index];

    global.dialogue_char_index = 0;
    global.dialogue_char_timer = 0;
    global.dialogue_speaker = dialogue_get_line_speaker(_line);
}


function dialogue_update() {
    dialogue_ensure_globals();

    if (!global.dialogue_active) return;

    if (array_length(global.dialogue_lines) <= 0) {
        dialogue_finish();
        return;
    }

    var _line = dialogue_get_current_line();

    if (_line == undefined) {
        dialogue_finish();
        return;
    }

    var _text = dialogue_get_line_text(_line);
    var _len = string_length(_text);

    if (dialogue_input_skip_pressed()) {
        dialogue_cancel();
        return;
    }

    var _speed = dialogue_get_line_speed(_line);

    global.dialogue_char_timer++;

    if (global.dialogue_char_timer >= _speed && global.dialogue_char_index < _len) {
        global.dialogue_char_timer = 0;
        global.dialogue_char_index++;
    }

    if (dialogue_input_advance_pressed()) {
        if (global.dialogue_char_index < _len) {
            global.dialogue_char_index = _len;
        } else {
            dialogue_go_to_next_line();
        }
    }
}


// =============================================================================
// DRAW HELPERS
// =============================================================================

function dialogue_get_speaker_color(_speaker) {
    if (_speaker == "Core") return make_color_rgb(255, 220, 90);
    if (_speaker == "Operator") return make_color_rgb(120, 190, 255);
    if (_speaker == "System") return make_color_rgb(180, 220, 255);

    return c_white;
}


function dialogue_draw_box(_x1, _y1, _x2, _y2) {
    // Shadow
    draw_set_alpha(0.72);
    draw_set_color(c_black);
    draw_roundrect_ext(_x1 + 6, _y1 + 6, _x2 + 6, _y2 + 6, 18, 18, false);

    // Main fill
    draw_set_alpha(0.92);
    draw_set_color(make_color_rgb(18, 24, 44));
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 18, 18, false);

    // Border
    draw_set_alpha(0.60);
    draw_set_color(make_color_rgb(110, 150, 255));
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 18, 18, true);

    // Inner top line
    draw_set_alpha(0.28);
    draw_set_color(c_white);
    draw_line_width(_x1 + 22, _y1 + 42, _x2 - 22, _y1 + 42, 2);

    draw_set_alpha(1.0);
}


function dialogue_draw_prompt(_x2, _y2) {
    var _blink = (floor(current_time / 250) mod 2) == 0;
    if (!_blink) return;

    draw_set_color(make_color_rgb(180, 200, 255));
    draw_set_alpha(0.9);
    draw_set_halign(fa_right);
    draw_set_valign(fa_top);

    draw_text_transformed(
        _x2 - 22,
        _y2 - 32,
        "A / SPACE: NEXT    B / ESC: SKIP",
        0.75,
        0.75,
        0
    );

    draw_set_alpha(1.0);
    draw_set_halign(fa_left);
}


function dialogue_draw() {
    dialogue_ensure_globals();

    if (!global.dialogue_active) return;

    var _line = dialogue_get_current_line();

    if (_line == undefined) return;

    var _fullText = dialogue_get_line_text(_line);
    var _speaker = dialogue_get_line_speaker(_line);
    var _shownText = string_copy(_fullText, 1, global.dialogue_char_index);

    var _guiW = display_get_gui_width();
    var _guiH = display_get_gui_height();

    var _margin = max(32, _guiW * 0.08);
    var _boxH = clamp(_guiH * 0.25, 150, 220);

    var _x1 = _margin;
    var _x2 = _guiW - _margin;
    var _y2 = _guiH - max(30, _guiH * 0.055);
    var _y1 = _y2 - _boxH;

    dialogue_draw_box(_x1, _y1, _x2, _y2);

    draw_set_alpha(1.0);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    // Speaker
    draw_set_color(dialogue_get_speaker_color(_speaker));
    draw_text_transformed(
        _x1 + 24,
        _y1 + 16,
        _speaker + ":",
        1.05,
        1.05,
        0
    );

    // Text
    draw_set_color(c_white);

    draw_text_ext_transformed(
        _x1 + 24,
        _y1 + 58,
        _shownText,
        28,
        _x2 - _x1 - 48,
        1.0,
        1.0,
        0
    );

    dialogue_draw_prompt(_x2, _y2);

    draw_set_alpha(1.0);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}