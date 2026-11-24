// =============================================================================
// scr_cc_input - one place for keyboard + gamepad. Call cc_input_update() once
// per step, then read global.inp.<action> (pressed this frame, with repeat for
// left/right/up/down).
// =============================================================================

function cc_input_init() {
    global.inp = { left: false, right: false, up: false, down: false, fire: false, ok: false, back: false,
                   hold: false, undo: false, restart: false, rotl: false, rotr: false, pause: false,
                   any: false, rep: {}, pad: -1, held_left: false, held_right: false };
    // test mode feeds scripted presses through this list
    global.inp_script = [];
}

function cc_pad() {
    for (var _i = 0; _i < 12; _i++) if (gamepad_is_connected(_i)) return _i;
    return -1;
}

function cc_btn_down(_keys, _pad_btns, _stick = 0) {
    for (var _i = 0; _i < array_length(_keys); _i++) if (keyboard_check(_keys[_i])) return true;
    var _p = global.inp.pad;
    if (_p >= 0) {
        for (var _i = 0; _i < array_length(_pad_btns); _i++) if (gamepad_button_check(_p, _pad_btns[_i])) return true;
        if (_stick == 1 && gamepad_axis_value(_p, gp_axislh) < -0.5) return true;
        if (_stick == 2 && gamepad_axis_value(_p, gp_axislh) > 0.5) return true;
        if (_stick == 3 && gamepad_axis_value(_p, gp_axislv) < -0.5) return true;
        if (_stick == 4 && gamepad_axis_value(_p, gp_axislv) > 0.5) return true;
    }
    return false;
}

function cc_btn_pressed(_keys, _pad_btns) {
    for (var _i = 0; _i < array_length(_keys); _i++) if (keyboard_check_pressed(_keys[_i])) return true;
    var _p = global.inp.pad;
    if (_p >= 0) {
        for (var _i = 0; _i < array_length(_pad_btns); _i++) if (gamepad_button_check_pressed(_p, _pad_btns[_i])) return true;
    }
    return false;
}

// pressed + auto-repeat after a short delay
function cc_repeat(_name, _down) {
    var _r = global.inp.rep;
    var _t = variable_struct_exists(_r, _name) ? _r[$ _name] : 0;
    _t = _down ? _t + 1 : 0;
    _r[$ _name] = _t;
    return _t == 1 || (_t > 14 && (_t - 14) mod 4 == 0);
}

function cc_input_update() {
    var _I = global.inp;
    _I.pad = cc_pad();
    _I.left  = cc_repeat("l", cc_btn_down([vk_left, ord("A")], [gp_padl], 1));
    _I.right = cc_repeat("r", cc_btn_down([vk_right, ord("D")], [gp_padr], 2));
    _I.up    = cc_repeat("u", cc_btn_down([vk_up, ord("W")], [gp_padu], 3));
    _I.down  = cc_repeat("d", cc_btn_down([vk_down, ord("S")], [gp_padd], 4));
    _I.fire    = cc_btn_pressed([vk_space, vk_up, ord("W"), vk_enter], [gp_face1]);
    _I.ok      = cc_btn_pressed([vk_space, vk_enter], [gp_face1, gp_start]);
    _I.back    = cc_btn_pressed([vk_escape, vk_backspace], [gp_face2]);
    _I.hold    = cc_btn_pressed([ord("C"), vk_shift], [gp_face3]);
    _I.undo    = cc_btn_pressed([ord("Z"), vk_backspace], [gp_face2, gp_face4]);
    _I.restart = cc_btn_pressed([ord("R")], [gp_select]);
    _I.rotl    = cc_btn_pressed([ord("Q")], [gp_shoulderl, gp_shoulderlb]);
    _I.rotr    = cc_btn_pressed([ord("E")], [gp_shoulderr, gp_shoulderrb]);
    _I.pause   = cc_btn_pressed([vk_escape], [gp_start]);
    _I.any     = keyboard_check_pressed(vk_anykey) || _I.ok || _I.back;
    if (keyboard_check_pressed(vk_f11)) window_set_fullscreen(!window_get_fullscreen());

    // scripted input for the self-test: one action name per frame
    if (array_length(global.inp_script) > 0) {
        var _a = global.inp_script[0];
        array_delete(global.inp_script, 0, 1);
        if (_a != "") { variable_struct_set(_I, _a, true); _I.any = true; }
    }
}
