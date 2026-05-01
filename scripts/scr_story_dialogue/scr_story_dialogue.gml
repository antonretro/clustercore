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

        // ── FIRST LAUNCH BACKSTORY ──────────────────────────────────────────
        backstory_intro: [
            { speaker: "System",   text: "INITIATING FLIGHT SEQUENCE.", speed: 2 },
            { speaker: "Operator", text: "Alright, engines are live. We've got a lot of planets clogged up with debris, and it's our job to clear them out.", speed: 1 },
            { speaker: "Operator", text: "You're piloting the Refabricator. You'll fly to different planets and clear the blocks surrounding their cores.", speed: 1 },
            { speaker: "Operator", text: "The goal of Story Mode is to travel from planet to planet, clearing boards until we reach the Sun Gate.", speed: 1 },
            { speaker: "Operator", text: "Let's start at Tin Moon. It's a small board, perfect for learning the controls.", speed: 1 }
        ],

        intro_0: [
            { speaker: "Operator", text: "Welcome to Tin Moon. Your goal is simple: CLEAR ALL THE BLOCKS. The level ends when only the red Core remains.", speed: 1 },
            { speaker: "Operator", text: "Use the Arrow Keys to move, and press SPACE to fire a block from your ship. Match 4 or more of the same color to break them.", speed: 1 },
            { speaker: "Operator", text: "Lines, clusters, and diagonals all count as matches. But watch out: if the blocks stack up to the outer boundary, you lose.", speed: 1 }
        ],

        intro_0_1: [
            { speaker: "Operator", text: "You'll see a timer under the 'NEXT' box. If that runs out, the piece fires automatically. Don't take too long!", speed: 1 },
            { speaker: "Operator", text: "Also, keep an eye out for Direction Blocks. They have arrows on them and only break if you match them in the direction they point.", speed: 1 }
        ],

        intro_1: [
            { speaker: "Operator", text: "Welcome to Rust Garden. We've got new hazards here: Locked cages and Spores.", speed: 1 },
            { speaker: "Operator", text: "Locked blocks take two hits to clear. Spores are the blocks with 3 dots—when you break one, it repaints a neighbor to its color.", speed: 1 }
        ],

        intro_2: [
            { speaker: "Operator", text: "Casino Comet is next. Watch out for Multiplier blocks and Debt blocks.", speed: 1 },
            { speaker: "Operator", text: "Multipliers double your score for that match. Debt blocks drain your launch timer while they're on the board, so break them fast!", speed: 1 }
        ],

        intro_3: [
            { speaker: "Operator", text: "This is Dead Orbit. It features Gravity blocks and Void blocks.", speed: 1 },
            { speaker: "Operator", text: "Gravity blocks pull nearby pieces toward them when cleared. Void blocks can't be matched; you have to break blocks next to them to destroy them.", speed: 1 }
        ],

        intro_4: [
            { speaker: "Operator", text: "Final stop: Cluster Core. You'll encounter Prism blocks and Core Keys here.", speed: 1 },
            { speaker: "Operator", text: "Prisms change their color every time you fire. Core Keys give you bonus gems when broken. Let's finish this!", speed: 1 }
        ],

        select_0: [
            { speaker: "System", text: "MISSION 0: TIN MOON. Objective: Clear the board of all debris.", speed: 1 }
        ],

        select_1: [
            { speaker: "System", text: "MISSION 1: RUST GARDEN. Objective: Manage dead blocks and clear the board.", speed: 1 }
        ],

        select_2: [
            { speaker: "System", text: "MISSION 2: CASINO COMET. Objective: High-speed board clearance required.", speed: 1 }
        ],

        select_3: [
            { speaker: "System", text: "MISSION 3: DEAD ORBIT. Objective: Survive gravity shifts and clear the board.", speed: 1 }
        ],

        select_4: [
            { speaker: "System", text: "MISSION 4: CLUSTER CORE. Objective: Final board purification sequence.", speed: 1 }
        ],

        world_open_0: [
            { speaker: "Operator", text: "Tin Moon mission active. Goal: Clear the board to stabilize the core.", speed: 1 }
        ],

        world_open_1: [
            { speaker: "Operator", text: "Rust Garden active. Watch out for dead blocks while you clear the grid.", speed: 1 }
        ],

        world_open_2: [
            { speaker: "Operator", text: "Casino Comet active. Speed is the priority for this board clear.", speed: 1 }
        ],

        world_open_3: [
            { speaker: "Operator", text: "Dead Orbit active. Use drills to keep your lanes open for the final clear.", speed: 1 }
        ],

        world_open_4: [
            { speaker: "Operator", text: "Cluster Core active. This is the final purification. Clear it all!", speed: 1 }
        ],

        between_0: [
            { speaker: "Operator", text: "Board cleared! Tin Moon is stable. Proceeding to the next sector.", speed: 1 }
        ],

        between_1: [
            { speaker: "Operator", text: "Rust Garden purified. Great job handling those spores.", speed: 1 }
        ],

        between_2: [
            { speaker: "Operator", text: "Casino Comet cleared. Nice work on that high-speed clearance.", speed: 1 }
        ],

        between_3: [
            { speaker: "Operator", text: "Dead Orbit survived. Only the Cluster Core remains. Let's finish this.", speed: 1 }
        ],

        between_4: [
            { speaker: "Operator", text: "The board is clear. The Sun Gate is open. Let's go!", speed: 1 }
        ],

        sun_goal: [
            { speaker: "Operator", text: "Final objective reached! The Sun Gate is open. Clear the board one more time to ignite the core!", speed: 1 }
        ],

        intro_default: [
            { speaker: "Operator", text: "Mission Objective: Clear every block from the board except for the core.", speed: 1 }
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
    if (global.dialogue_active) return false;

    // Try level-specific intro first (e.g. intro_0_1), then fall back to planet intro (intro_0)
    var _sceneId = "intro_" + string(global.storyPlanet) + "_" + string(global.storyLevel);
    var _cat = story_plot_catalog();
    
    if (!variable_struct_exists(_cat, _sceneId)) {
        _sceneId = "intro_" + string(global.storyPlanet);
    }

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
    var _w = _x2 - _x1;
    var _h = _y2 - _y1;

    if (sprite_exists(spr_dialogue_box)) {
        // Nine-slice sprite — configure insets to 8px in the GameMaker sprite editor
        // Shadow
        draw_set_alpha(0.55);
        draw_sprite_stretched_ext(spr_dialogue_box, 0, _x1 + 7, _y1 + 7, _w, _h, c_black, 0.55);
        // Main box
        draw_set_alpha(1.0);
        draw_sprite_stretched_ext(spr_dialogue_box, 0, _x1, _y1, _w, _h, c_white, 1.0);
    } else {
        // Procedural fallback while sprite is being made
        draw_set_alpha(0.72);
        draw_set_color(c_black);
        draw_roundrect_ext(_x1 + 6, _y1 + 6, _x2 + 6, _y2 + 6, 18, 18, false);
        draw_set_alpha(0.92);
        draw_set_color(make_color_rgb(18, 24, 44));
        draw_roundrect_ext(_x1, _y1, _x2, _y2, 18, 18, false);
        draw_set_alpha(0.60);
        draw_set_color(make_color_rgb(110, 150, 255));
        draw_roundrect_ext(_x1, _y1, _x2, _y2, 18, 18, true);
        draw_set_alpha(0.28);
        draw_set_color(c_white);
        draw_line_width(_x1 + 22, _y1 + 42, _x2 - 22, _y1 + 42, 2);
    }

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
        _y2 - 32 * (global.TXT_SMALL / 1.8), // scale the vertical offset so it doesn't get pushed off the box
        "A / SPACE: NEXT    B / ESC: SKIP",
        global.TXT_SMALL,
        global.TXT_SMALL,
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

    // ── STORYBOARD CINEMATIC ────────────────────────────────────────────────
    if (global.dialogue_scene_id == "backstory_intro") {
        var _cW = _guiW * 0.7;
        var _cH = _guiH * 0.55;
        var _cX = _guiW * 0.5 - _cW * 0.5;
        var _cY = _guiH * 0.10;
        
        draw_set_color(make_color_rgb(10, 15, 30));
        draw_set_alpha(0.9);
        draw_roundrect_ext(_cX, _cY, _cX + _cW, _cY + _cH, 20, 20, false);
        draw_set_color(make_color_rgb(110, 150, 255));
        draw_set_alpha(0.6);
        draw_roundrect_ext(_cX, _cY, _cX + _cW, _cY + _cH, 20, 20, true);
        
        var _time = current_time * 0.001;
        var _cxCenter = _cX + _cW * 0.5;
        var _cyCenter = _cY + _cH * 0.5;
        
        // Draw starry background
        draw_set_alpha(0.5);
        draw_set_color(c_white);
        for(var _s = 0; _s < 25; _s++) {
            var _sx = _cX + ((_s * 83 + current_time * 0.1) mod _cW);
            var _sy = _cY + ((_s * 137) mod _cH);
            draw_circle(_sx, _sy, 1 + (_s mod 2), false);
        }
        
        if (global.dialogue_index <= 1) {
            // Scene 1: Rocket launching / flight
            draw_set_alpha(1.0);
            var _rocketY = _cyCenter + sin(_time * 4) * 15;
            
            // Thrust
            draw_set_color(c_orange);
            draw_circle(_cxCenter - 60 - random(15), _rocketY, 20 + random(8), false);
            draw_set_color(c_yellow);
            draw_circle(_cxCenter - 50 - random(10), _rocketY, 12 + random(5), false);
            
            // Ship body
            draw_set_color(c_white);
            draw_triangle(_cxCenter + 60, _rocketY, _cxCenter - 40, _rocketY - 25, _cxCenter - 40, _rocketY + 25, false);
            // Fins
            draw_set_color(c_red);
            draw_triangle(_cxCenter - 20, _rocketY - 15, _cxCenter - 50, _rocketY - 40, _cxCenter - 40, _rocketY, false);
            draw_triangle(_cxCenter - 20, _rocketY + 15, _cxCenter - 50, _rocketY + 40, _cxCenter - 40, _rocketY, false);
            // Window
            draw_set_color(c_aqua);
            draw_circle(_cxCenter + 10, _rocketY, 8, false);
            
        } else if (global.dialogue_index <= 3) {
            // Scene 2: Approaching debris planet
            draw_set_alpha(1.0);
            // Planet
            draw_set_color(make_color_rgb(80, 120, 200));
            draw_circle(_cxCenter + 150, _cyCenter, 90, false);
            draw_set_color(make_color_rgb(50, 80, 150));
            draw_circle(_cxCenter + 130, _cyCenter - 20, 20, false);
            
            // Debris ring
            draw_set_color(make_color_rgb(150, 100, 100));
            for(var _r = 0; _r < 24; _r++) {
                var _a = _time * 0.5 + _r;
                var _dist = 130 + sin(_r * 3) * 25;
                draw_circle(_cxCenter + 150 + cos(_a) * _dist, _cyCenter + sin(_a) * _dist, 12 + sin(_r)*4, false);
            }
            
            // Ship (scaled down)
            draw_set_color(c_orange);
            draw_circle(_cxCenter - 110 - random(8), _cyCenter, 8, false);
            draw_set_color(c_white);
            draw_triangle(_cxCenter - 50, _cyCenter, _cxCenter - 100, _cyCenter - 12, _cxCenter - 100, _cyCenter + 12, false);
            draw_set_color(c_red);
            draw_triangle(_cxCenter - 80, _cyCenter - 8, _cxCenter - 100, _cyCenter - 20, _cxCenter - 100, _cyCenter, false);
            draw_triangle(_cxCenter - 80, _cyCenter + 8, _cxCenter - 100, _cyCenter + 20, _cxCenter - 100, _cyCenter, false);
            
        } else {
            // Scene 3: Firing blocks to clear
            draw_set_alpha(1.0);
            // Planet slice
            draw_set_color(make_color_rgb(80, 120, 200));
            draw_circle(_cxCenter + 250, _cyCenter, 140, false);
            
            // Ship firing
            draw_set_color(c_orange);
            draw_circle(_cxCenter - 210 - random(12), _cyCenter, 12, false);
            draw_set_color(c_white);
            draw_triangle(_cxCenter - 100, _cyCenter, _cxCenter - 200, _cyCenter - 20, _cxCenter - 200, _cyCenter + 20, false);
            
            // Block traveling
            var _bx = _cxCenter - 80 + ((current_time * 0.6) mod 250);
            draw_set_color(c_red);
            draw_roundrect(_bx, _cyCenter - 20, _bx + 40, _cyCenter + 20, false);
            draw_set_color(make_color_rgb(255, 100, 100));
            draw_roundrect(_bx+4, _cyCenter - 16, _bx + 36, _cyCenter + 16, false);
        }
        draw_set_alpha(1.0);
    }
    // ────────────────────────────────────────────────────────────────────────

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

    // Typography scales
    var _speakerScale = global.TXT_H3;
    var _charScale = global.TXT_H4;
    var _maxWidth = _x2 - _x1 - 48;

    // Speaker
    draw_set_color(dialogue_get_speaker_color(_speaker));
    draw_text_transformed(_x1 + 24, _y1 + 16, _speaker + ":", _speakerScale, _speakerScale, 0);

    // Text (Custom Word Wrap + Per-Character Typing Animation)
    var _cx = _x1 + 24;
    var _cy = _y1 + 16 + (28 * _speakerScale);
    var _lineH = 26 * _charScale;
    
    // Fast word-wrap pre-pass
    var _words = [];
    var _currentWord = "";
    for (var i = 1; i <= string_length(_fullText); i++) {
        var _c = string_char_at(_fullText, i);
        if (_c == " " || _c == "\n") {
            if (_currentWord != "") array_push(_words, _currentWord);
            array_push(_words, _c); // push space/newline as own word
            _currentWord = "";
        } else {
            _currentWord += _c;
        }
    }
    if (_currentWord != "") array_push(_words, _currentWord);

    // Draw pass
    var _charIndex = 1;
    draw_set_color(c_white);
    
    for (var w = 0; w < array_length(_words); w++) {
        var _word = _words[w];
        if (_charIndex > global.dialogue_char_index) break;
        
        if (_word == "\n") {
            _cx = _x1 + 24;
            _cy += _lineH;
            _charIndex++;
            continue;
        }
        
        var _wordW = string_width(_word) * _charScale;
        
        // Wrap to next line if word exceeds width
        if (_word != " " && _cx + _wordW > _x1 + 24 + _maxWidth) {
            _cx = _x1 + 24;
            _cy += _lineH;
        }
        
        if (_word == " ") {
            _cx += _wordW;
            _charIndex++;
            continue;
        }
        
        // Draw individual characters with pop animation
        for (var c = 1; c <= string_length(_word); c++) {
            if (_charIndex > global.dialogue_char_index) break;
            
            var _char = string_char_at(_word, c);
            var _cw = string_width(_char) * _charScale;
            
            // Pop animation for newly revealed chars
            var _age = global.dialogue_char_index - _charIndex;
            var _popY = 0;
            var _popS = _charScale;
            if (_age < 3) {
                var _intensity = (3 - _age) / 3;
                _popY = -sin(_intensity * pi) * 4;
                _popS = _charScale * (1.0 + _intensity * 0.15);
            }
            
            // Drop shadow
            draw_set_color(make_color_rgb(10, 15, 30));
            draw_set_alpha(0.6);
            draw_text_transformed(_cx + 2, _cy + 3 + _popY, _char, _popS, _popS, 0);
            
            // Main char
            draw_set_color(c_white);
            draw_set_alpha(1.0);
            draw_text_transformed(_cx, _cy + _popY, _char, _popS, _popS, 0);
            
            _cx += _cw;
            _charIndex++;
        }
    }

    dialogue_draw_prompt(_x2, _y2);

    draw_set_alpha(1.0);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}
