// =============================================================================
// scr_story_dialogue - Story plot + Paintra-style dialogue box
// =============================================================================

function story_plot_catalog() {
    return {
        intro_0: [
            { speaker: "Operator", text: "Tin Moon reactor shell online. Keep it stable and follow the core pulse." },
            { speaker: "Core", text: "I am dormant, not dead. Feed me clean chains and I will wake." }
        ],
        intro_1: [
            { speaker: "Operator", text: "Rust Garden is clogged with dead flow. Precision first, greed second." },
            { speaker: "Core", text: "Pressure creates shape. Shape creates power." }
        ],
        intro_2: [
            { speaker: "Operator", text: "Casino Comet signal is noisy. Big payouts, bigger mistakes." },
            { speaker: "Core", text: "Risk is a language. Speak it fluently." }
        ],
        intro_3: [
            { speaker: "Operator", text: "Dead Orbit is hostile. Preserve lanes and save your outs." },
            { speaker: "Core", text: "Survival is just controlled collapse." }
        ],
        intro_4: [
            { speaker: "Operator", text: "Cluster Core perimeter reached. This is where pilots usually break." },
            { speaker: "Core", text: "Then break differently. Evolve." }
        ],
        select_0: [
            { speaker: "System", text: "Tin Moon route: low turbulence. Good for synchronization calibration." }
        ],
        select_1: [
            { speaker: "System", text: "Rust Garden route: resource drag and unstable debris patterns." }
        ],
        select_2: [
            { speaker: "System", text: "Casino Comet route: volatile payouts with high miss penalties." }
        ],
        select_3: [
            { speaker: "System", text: "Dead Orbit route: hostile lanes. Survival priority is elevated." }
        ],
        select_4: [
            { speaker: "System", text: "Cluster Core route: direct resonance chamber approach." }
        ],
        world_open_0: [
            { speaker: "Operator", text: "Tin Moon mission set. Four stabilizer levels queued." }
        ],
        world_open_1: [
            { speaker: "Operator", text: "Rust Garden loaded. Keep your lanes clean and tight." }
        ],
        world_open_2: [
            { speaker: "Operator", text: "Casino Comet armed. High reward, low forgiveness." }
        ],
        world_open_3: [
            { speaker: "Operator", text: "Dead Orbit online. Survival discipline required." }
        ],
        world_open_4: [
            { speaker: "Operator", text: "Cluster Core channel open. This world tests everything." }
        ],
        between_0: [
            { speaker: "Operator", text: "Tin Moon stabilized. Next orbital lane opening now." }
        ],
        between_1: [
            { speaker: "Operator", text: "Rust Garden secured. The core signal is getting louder." }
        ],
        between_2: [
            { speaker: "Operator", text: "Casino Comet cleared. Profit curve spiking into danger." }
        ],
        between_3: [
            { speaker: "Operator", text: "Dead Orbit survived. One final approach remains." }
        ],
        between_4: [
            { speaker: "Core", text: "All loops complete. Set course for the Sun gate." }
        ],
        intro_default: [
            { speaker: "Core", text: "Maintain flow. Build the chain. Reach the sun." }
        ],
        sun_goal: [
            { speaker: "Operator", text: "All planetary loops converged. Solar gate opening." },
            { speaker: "Core", text: "One final ignition. Feed the sun and become more than an operator." }
        ]
    };
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
    if (!variable_global_exists("story_seen_scenes")) global.story_seen_scenes = {};
}

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
    if (!variable_global_exists("story_seen_scenes")) global.story_seen_scenes = {};
}

function dialogue_is_active() {
    return variable_global_exists("dialogue_active") && global.dialogue_active;
}

function dialogue_start(_scene_id, _lines, _onFinish = "") {
    dialogue_ensure_globals();
    if (_lines == undefined || array_length(_lines) <= 0) return false;
    global.dialogue_active = true;
    global.dialogue_scene_id = _scene_id;
    global.dialogue_lines = _lines;
    global.dialogue_index = 0;
    global.dialogue_char_index = 0;
    global.dialogue_char_timer = 0;
    global.dialogue_on_finish = _onFinish;
    var _first = global.dialogue_lines[0];
    global.dialogue_speaker = variable_struct_exists(_first, "speaker") ? _first.speaker : "System";
    return true;
}

function dialogue_finish() {
    dialogue_ensure_globals();
    var _callback = global.dialogue_on_finish;
    global.dialogue_active = false;
    global.dialogue_on_finish = "";
    if (_callback == "start_game") {
        with (obj_game_manager) start_game();
    }
}

function story_get_scene_id_for_planet(_planetIndex) {
    return "intro_" + string(_planetIndex);
}

function story_try_start_level_dialogue() {
    if (global.gameMode != "STORY") return;
    if (!variable_global_exists("story_seen_scenes")) global.story_seen_scenes = {};
    var _sceneId = story_get_scene_id_for_planet(global.storyPlanet);
    if (!variable_struct_exists(global.story_seen_scenes, _sceneId)) {
        var _cat = story_plot_catalog();
        var _lines = variable_struct_exists(_cat, _sceneId) ? _cat[$ _sceneId] : _cat.intro_default;
        dialogue_start(_sceneId, _lines);
        global.story_seen_scenes[$ _sceneId] = true;
    }
}

function story_start_between_level_dialogue(_planetIndex) {
    var _cat = story_plot_catalog();
    var _sceneId = "between_" + string(_planetIndex);
    if (variable_struct_exists(_cat, _sceneId)) {
        dialogue_start(_sceneId, _cat[$ _sceneId]);
    }
}

function dialogue_update() {
    if (!dialogue_is_active()) return;
    dialogue_ensure_globals();
    if (array_length(global.dialogue_lines) <= 0) { dialogue_finish(); return; }

    var _gp = gamepad_is_connected(0);
    var _advance = keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space)
                || keyboard_check_pressed(ord("Z"))
                || (_gp && gamepad_button_check_pressed(0, gp_face1));
    var _skip = keyboard_check_pressed(vk_escape) || (_gp && gamepad_button_check_pressed(0, gp_face2));

    if (_skip) {
        dialogue_finish();
        return;
    }

    var _line = global.dialogue_lines[global.dialogue_index];
    var _text = _line.text;
    var _len = string_length(_text);
    var _speed = global.dialogue_char_speed;
    if (variable_struct_exists(_line, "speed")) _speed = max(1, _line.speed);

    global.dialogue_char_timer++;
    if (global.dialogue_char_timer >= _speed && global.dialogue_char_index < _len) {
        global.dialogue_char_timer = 0;
        global.dialogue_char_index++;
    }

    if (_advance) {
        if (global.dialogue_char_index < _len) {
            global.dialogue_char_index = _len;
        } else {
            global.dialogue_index++;
            if (global.dialogue_index >= array_length(global.dialogue_lines)) {
                dialogue_finish();
                return;
            }
            global.dialogue_char_index = 0;
            global.dialogue_char_timer = 0;
            var _next = global.dialogue_lines[global.dialogue_index];
            global.dialogue_speaker = variable_struct_exists(_next, "speaker") ? _next.speaker : "System";
        }
    }
}

function dialogue_draw() {
    if (!dialogue_is_active()) return;
    dialogue_ensure_globals();

    var _guiW = display_get_gui_width();
    var _guiH = display_get_gui_height();
    var _margin = max(32, _guiW * 0.08);
    var _boxH = clamp(_guiH * 0.24, 150, 210);
    var _x1 = _margin;
    var _x2 = _guiW - _margin;
    var _y2 = _guiH - max(32, _guiH * 0.06);
    var _y1 = _y2 - _boxH;

    draw_set_alpha(0.78);
    draw_set_color(c_black);
    draw_roundrect_ext(_x1 + 6, _y1 + 6, _x2 + 6, _y2 + 6, 18, 18, false);
    draw_set_alpha(0.90);
    draw_set_color(make_color_rgb(18, 24, 44));
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 18, 18, false);
    draw_set_alpha(0.55);
    draw_set_color(make_color_rgb(110, 150, 255));
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 18, 18, true);

    var _line = global.dialogue_lines[global.dialogue_index];
    var _text = string_copy(_line.text, 1, global.dialogue_char_index);
    var _speaker = variable_struct_exists(_line, "speaker") ? _line.speaker : "System";

    draw_set_alpha(1.0);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(make_color_rgb(255, 220, 90));
    draw_text_transformed(_x1 + 24, _y1 + 18, _speaker + ":", 1.1, 1.1, 0);
    draw_set_color(c_white);
    draw_text_ext_transformed(_x1 + 24, _y1 + 54, _text, 28, (_x2 - _x1 - 48), 1.0, 1.0, 0);

    var _blink = (floor(current_time / 250) mod 2) == 0;
    draw_set_color(make_color_rgb(180, 200, 255));
    if (_blink) draw_text_transformed(_x2 - 230, _y2 - 30, "A/SPACE NEXT  B/ESC SKIP", 0.8, 0.8, 0);
    draw_set_alpha(1.0);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}
