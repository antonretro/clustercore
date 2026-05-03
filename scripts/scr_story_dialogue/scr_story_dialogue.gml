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

        backstory_intro: [
            { speaker: "Operator", text: "Welcome aboard. Your job is to clear blocks from each planet.", speed: 1 },
            { speaker: "Operator", text: "Match 4 or more blocks of the same color to clear them. Clear every block to finish the level.", speed: 1 },
            { speaker: "Operator", text: "Travel from planet to planet and clear them all. Let's start at Tin Moon.", speed: 1 }
        ],

        intro_0: [
            { speaker: "Operator", text: "Your job is to clear the board. Match 4 or more blocks of the same color.", speed: 1 },
            { speaker: "Operator", text: "Arrow keys move. Space launches. Try it now.", speed: 1 },
            { speaker: "Operator", text: "If blocks reach the outer ring you lose. Keep the board clean.", speed: 1 }
        ],

        intro_0_1: [
            { speaker: "Operator", text: "Good. A few more things.", speed: 1 },
            { speaker: "Operator", text: "Q and E (or L and R) rotate the board. C holds a piece for later.", speed: 1 },
            { speaker: "Operator", text: "Arrow blocks only clear in the direction they point. Match 4 or more in a line.", speed: 1 }
        ],

        intro_0_3: [
            { speaker: "Operator", text: "Press C to hold your current piece. Press again to swap it back.", speed: 1 },
            { speaker: "Operator", text: "Use hold when a piece doesn't fit. Save it for a better spot.", speed: 1 }
        ],

        intro_0_6: [
            { speaker: "Operator", text: "Arrow blocks only clear in a straight line of 4 or more.", speed: 1 },
            { speaker: "Operator", text: "They must match the arrow direction. They won't clear in clusters.", speed: 1 }
        ],

        intro_1: [
            { speaker: "Operator", text: "Rust Garden. Locked cages and spore blocks ahead.", speed: 1 },
            { speaker: "Operator", text: "Locked cages take two clears to destroy.", speed: 1 },
            { speaker: "Operator", text: "Spores repaint a neighbor when cleared. Use them to set up matches.", speed: 1 }
        ],

        intro_1_2: [
            { speaker: "Operator", text: "Locked cages need two hits. First hit cracks them. Second clears them.", speed: 1 },
            { speaker: "Operator", text: "Clear cages early. A cracked cage blocks your matches.", speed: 1 }
        ],

        intro_1_4: [
            { speaker: "Operator", text: "Spores have 3 dots. When cleared they recolor a nearby block.", speed: 1 },
            { speaker: "Operator", text: "Use spores to create new matches. But they might ruin a setup too.", speed: 1 }
        ],

        intro_1_6: [
            { speaker: "Operator", text: "Locked cages and spores together. Clear cages first.", speed: 1 },
            { speaker: "Operator", text: "Then use spores to set up bigger combos.", speed: 1 }
        ],

        intro_2: [
            { speaker: "Operator", text: "Casino Comet. Multiplier and debt blocks ahead.", speed: 1 },
            { speaker: "Operator", text: "Multipliers double your score. Debt blocks drain your timer.", speed: 1 },
            { speaker: "Operator", text: "Clear debt blocks fast. Save multipliers for big matches.", speed: 1 }
        ],

        intro_2_2: [
            { speaker: "Operator", text: "Multipliers double your score for that match. Two multipliers make x4.", speed: 1 },
            { speaker: "Operator", text: "Save them for large clears to max your score.", speed: 1 }
        ],

        intro_2_4: [
            { speaker: "Operator", text: "Debt blocks speed up your timer. Clear them first.", speed: 1 },
            { speaker: "Operator", text: "Even a small match removes them. Don't let them stack up.", speed: 1 }
        ],

        intro_2_7: [
            { speaker: "Operator", text: "Everything is active. Clear debt first, then set up multipliers.", speed: 1 }
        ],

        intro_3: [
            { speaker: "Operator", text: "Dead Orbit. Gravity and void blocks ahead.", speed: 1 },
            { speaker: "Operator", text: "Gravity blocks pull nearby blocks toward them when cleared.", speed: 1 },
            { speaker: "Operator", text: "Void blocks can't be matched. Clear blocks next to them to remove them.", speed: 1 }
        ],

        intro_3_2: [
            { speaker: "Operator", text: "Gravity blocks pull everything one cell toward them when cleared.", speed: 1 },
            { speaker: "Operator", text: "This can set off chain reactions. Think before you clear one.", speed: 1 }
        ],

        intro_3_4: [
            { speaker: "Operator", text: "Void blocks cannot be matched. Clear next to them twice to break them.", speed: 1 },
            { speaker: "Operator", text: "Plan your clears around voids. Use them as walls if needed.", speed: 1 }
        ],

        intro_3_7: [
            { speaker: "Operator", text: "Gravity and voids together. Use gravity clears to position blocks around voids.", speed: 1 }
        ],

        intro_4: [
            { speaker: "Operator", text: "Cluster Core. Prism blocks and core keys ahead.", speed: 1 },
            { speaker: "Operator", text: "Prisms change color every time you launch. Time your shots.", speed: 1 },
            { speaker: "Operator", text: "Core keys give bonus gems when cleared.", speed: 1 },
            { speaker: "Operator", text: "Last planet. Give it everything.", speed: 1 }
        ],

        intro_4_2: [
            { speaker: "Operator", text: "Prisms shift color every launch. Watch them closely.", speed: 1 },
            { speaker: "Operator", text: "Fire when the prism matches your setup. Wait if it's wrong.", speed: 1 }
        ],

        intro_4_4: [
            { speaker: "Operator", text: "Core keys give 3 bonus gems each. Prioritize them in your matches.", speed: 1 }
        ],

        intro_4_7: [
            { speaker: "Operator", text: "All mechanics active. Prisms first, keys second, arrows third.", speed: 1 }
        ],

        select_0: [
            { speaker: "System", text: "Tin Moon. 3 levels. No special blocks.", speed: 1 }
        ],

        select_1: [
            { speaker: "System", text: "Rust Garden. 4 levels. Locked cages and spores.", speed: 1 }
        ],

        select_2: [
            { speaker: "System", text: "Casino Comet. 4 levels. Multipliers and debt blocks.", speed: 1 }
        ],

        select_3: [
            { speaker: "System", text: "Dead Orbit. 4 levels. Gravity and void blocks.", speed: 1 }
        ],

        select_4: [
            { speaker: "System", text: "Cluster Core. 5 levels. Prisms and core keys.", speed: 1 }
        ],

        world_open_0: [
            { speaker: "Operator", text: "Tin Moon open. 3 missions. Clear them all.", speed: 1 }
        ],

        world_open_1: [
            { speaker: "Operator", text: "Rust Garden open. 4 missions. Watch for locked cages.", speed: 1 }
        ],

        world_open_2: [
            { speaker: "Operator", text: "Casino Comet open. 4 missions. Don't let debt stack up.", speed: 1 }
        ],

        world_open_3: [
            { speaker: "Operator", text: "Dead Orbit open. 4 missions. Gravity is tricky.", speed: 1 }
        ],

        world_open_4: [
            { speaker: "Operator", text: "Cluster Core open. 5 missions. Last planet.", speed: 1 }
        ],

        between_0: [
            { speaker: "Operator", text: "Tin Moon clear. On to Rust Garden.", speed: 1 }
        ],

        between_1: [
            { speaker: "Operator", text: "Rust Garden clear. Casino Comet next.", speed: 1 }
        ],

        between_2: [
            { speaker: "Operator", text: "Casino Comet clear. Dead Orbit ahead.", speed: 1 }
        ],

        between_3: [
            { speaker: "Operator", text: "Dead Orbit clear. Cluster Core is the last one.", speed: 1 }
        ],

        between_4: [
            { speaker: "Operator", text: "All planets clear. Sun Gate is open.", speed: 1 }
        ],

        sun_goal: [
            { speaker: "Operator", text: "Sun Gate is open. Clear this board to finish.", speed: 1 }
        ],

        intro_default: [
            { speaker: "Operator", text: "Clear the board. Match 3 or more of the same color.", speed: 1 }
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

    var _text = "";
    if (variable_struct_exists(_line, "text")) {
        _text = _line.text;
    } else {
        return "";
    }

    // Substitute pilot name if player has set a custom one
    var _pilotName = "";
    if (instance_exists(obj_menu_controller)) {
        var _slotIdx = clamp(global.current_save_slot - 1, 0, 2);
        _pilotName = obj_menu_controller.save_slots[_slotIdx].name;
        var _defName = "PILOT_0" + string(_slotIdx + 1);
        if (_pilotName == _defName || _pilotName == "") _pilotName = "";
    }
    if (_pilotName != "") {
        _text = string_replace_all(_text, "Pilot", _pilotName);
    }

    return _text;
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

    // Auto-advance disabled per user request to prevent dialogue skipping ahead
    global.dialogue_auto_timer = 0;

    if (dialogue_input_advance_pressed()) {
        global.dialogue_auto_timer = 0;
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

    var _gradTop   = make_color_rgb(45, 60, 110);
    var _gradBot   = make_color_rgb(15, 20, 45);
    var _edgeCol   = make_color_rgb(140, 180, 255);

    // Sprite-based dialogue box background
    var _dlgSpr = asset_get_index("spr_dialogue_box");
    var _hasSprite = (_dlgSpr != -1 && sprite_exists(_dlgSpr));

    // Shadow
    draw_set_alpha(_hasSprite ? 0.4 : 0.6);
    draw_set_color(c_black);
    draw_roundrect_ext(_x1 + 6, _y1 + 6, _x2 + 6, _y2 + 6, 12, 12, false);

    if (_hasSprite) {
        draw_set_alpha(0.82);
        draw_sprite_stretched_ext(_dlgSpr, 0, _x1, _y1, _w, _h, c_white, 1.0);
    } else {
        draw_set_alpha(0.85);
        draw_rectangle_colour(_x1, _y1, _x2, _y2, _gradTop, _gradTop, _gradBot, _gradBot, false);
    }

    // Frosted Outline
    draw_set_alpha(0.35);
    draw_set_color(_edgeCol);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 12, 12, true);

    // Speaker Accent Bar
    var _speaker = global.dialogue_speaker;
    var _accent  = dialogue_get_speaker_color(_speaker);
    draw_set_alpha(0.8);
    draw_set_color(_accent);
    draw_rectangle(_x1 + 18, _y1 + 16, _x1 + 22, _y1 + 16 + (24 * global.TXT_H3), false);

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
    var _boxH = clamp(_guiH * 0.28, 180, 260); // Increased height to prevent overflow

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
    var _charScale = global.TXT_H4 * 1.1; // Larger multiplier for dialogue readability
    // Speaker
    draw_set_color(dialogue_get_speaker_color(_speaker));
    draw_text_transformed(_x1 + 40, _y1 + 20, _speaker + ":", _speakerScale, _speakerScale, 0);

    // Text (Custom Word Wrap + Per-Character Typing Animation)
    var _cx = _x1 + 40;
    var _cy = _y1 + 20 + (24 * _speakerScale); // Reduced offset from 34 to 24
    var _lineH = 26 * _charScale;
    
    // Fast word-wrap pre-pass
    var _maxWidth = _x2 - _x1 - 80;
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
            _cx = _x1 + 40;
            _cy += _lineH;
            _charIndex++;
            continue;
        }
        
        var _wordW = string_width(_word) * _charScale;
        
        // Wrap to next line if word exceeds width
        if (_word != " " && _cx + _wordW > _x1 + 40 + _maxWidth) {
            _cx = _x1 + 40;
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
