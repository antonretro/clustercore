// =============================================================================
// scr_cc_audio - every sound is synthesised at boot (no audio files needed)
// =============================================================================

#macro CC_RATE 22050

// _fn(t, i) returns a sample in -1..1 for time t (seconds); i is the sample index
function cc_synth(_secs, _fn, _vol = 0.6) {
    var _len = floor(_secs * CC_RATE);
    var _buf = buffer_create(_len * 2, buffer_fixed, 2);
    for (var _i = 0; _i < _len; _i++) {
        var _t = _i / CC_RATE;
        var _s = clamp(_fn(_t, _i) * _vol, -1, 1);
        // tiny fade in/out so nothing clicks
        _s *= min(1, _i / 40, (_len - _i) / 80);
        buffer_write(_buf, buffer_s16, round(_s * 32000));
    }
    return audio_create_buffer_sound(_buf, buffer_s16, CC_RATE, 0, _len * 2, audio_mono);
}

function cc_sq(_ph)  { return (frac(_ph) < 0.5) ? 1 : -1; }
function cc_tri(_ph) { var _f = frac(_ph); return (_f < 0.5) ? (_f * 4 - 1) : (3 - _f * 4); }
function cc_sin(_ph) { return sin(_ph * 2 * pi); }
function cc_env(_t, _decay) { return exp(-_t * _decay); }

function cc_audio_init() {
    random_set_seed(4242);
    global.snd = {};
    var _S = global.snd;

    _S.tick = cc_synth(0.035, function(_t) { return cc_sq(_t * 1400) * cc_env(_t, 90) * 0.5; }, 0.35);
    _S.turn = cc_synth(0.22, function(_t) {
        var _f = 220 + 500 * (_t / 0.22);
        return (random_range(-1, 1) * 0.5 + cc_tri(_t * _f) * 0.5) * sin(pi * _t / 0.22);
    }, 0.35);
    _S.fire = cc_synth(0.11, function(_t) { return cc_sq(_t * (380 + _t * 5200)) * cc_env(_t, 22); }, 0.32);
    _S.land = cc_synth(0.12, function(_t) { return cc_sin(_t * (160 - _t * 500)) * cc_env(_t, 30) + random_range(-0.3, 0.3) * cc_env(_t, 80); }, 0.75);
    _S.pop = cc_synth(0.35, function(_t) {
        var _f = 660;
        return (cc_sin(_t * _f) + cc_sin(_t * _f * 2) * 0.35 + cc_sin(_t * _f * 3.01) * 0.15) * cc_env(_t, 11);
    }, 0.45);
    _S.core = cc_synth(0.9, function(_t) {
        var _boom = cc_sin(_t * (90 - _t * 40)) * cc_env(_t, 5);
        var _chord = (cc_sin(_t * 523) + cc_sin(_t * 659) + cc_sin(_t * 784)) * 0.22 * cc_env(_t, 4) * min(1, _t * 30);
        return _boom + _chord + random_range(-0.4, 0.4) * cc_env(_t, 25);
    }, 0.7);
    _S.win = cc_synth(1.3, function(_t) {
        var _notes = [523.25, 659.25, 783.99, 1046.5, 1318.5];
        var _k = min(floor(_t / 0.11), 4);
        var _lt = _t - _k * 0.11;
        var _f = _notes[_k];
        return (cc_sq(_t * _f) * 0.35 + cc_sin(_t * _f * 0.5) * 0.5) * cc_env(_lt, (_k == 4) ? 3 : 9);
    }, 0.45);
    _S.bomb = cc_synth(0.55, function(_t) {
        return random_range(-1, 1) * cc_env(_t, 7) + cc_sin(_t * (70 - _t * 50)) * cc_env(_t, 6);
    }, 0.6);
    _S.drill = cc_synth(0.4, function(_t) {
        var _f = 110 + 40 * sin(_t * 90);
        return (frac(_t * _f) * 2 - 1) * 0.7 * (1 - _t / 0.4) + random_range(-0.3, 0.3) * (1 - _t / 0.4);
    }, 0.45);
    _S.undo = cc_synth(0.14, function(_t) { return cc_tri(_t * (900 - _t * 3000)) * cc_env(_t, 18); }, 0.35);
    _S.fail = cc_synth(0.6, function(_t) { return cc_sq(_t * (300 - _t * 260)) * cc_env(_t, 4); }, 0.3);
    _S.hold = cc_synth(0.12, function(_t) { return cc_tri(_t * (600 + _t * 2500)) * cc_env(_t, 20); }, 0.35);
    _S.select = cc_synth(0.07, function(_t) { return cc_sq(_t * 880) * cc_env(_t, 40); }, 0.25);
    _S.confirm = cc_synth(0.22, function(_t) {
        var _f = (_t < 0.07) ? 660 : 990;
        return cc_sq(_t * _f) * cc_env(_t, 12);
    }, 0.3);
    _S.blocked = cc_synth(0.12, function(_t) { return cc_sq(_t * 140) * cc_env(_t, 20); }, 0.3);
    _S.star = cc_synth(0.4, function(_t) { return (cc_sin(_t * 1568) + cc_sin(_t * 2093) * 0.5) * cc_env(_t, 9); }, 0.35);

    // ambient music bed: slow detuned pad (loops)
    _S.pad = cc_synth(8.0, function(_t) {
        var _chords = [[130.81, 196.0, 261.63], [110.0, 164.81, 220.0], [87.31, 130.81, 174.61], [98.0, 146.83, 196.0]];
        var _k = floor(_t / 2) mod 4;
        var _c = _chords[_k];
        var _lt = _t - floor(_t / 2) * 2;
        var _e = min(1, _lt * 2) * min(1, (2 - _lt) * 2);
        var _s = 0;
        for (var _i = 0; _i < 3; _i++) _s += cc_tri(_t * _c[_i]) * 0.5 + cc_sin(_t * _c[_i] * 1.003) * 0.5;
        return _s * 0.18 * (0.6 + 0.4 * _e);
    }, 0.5);
    random_set_seed(current_time);
}

function cc_sfx(_name, _pitch = 1, _gain = 1) {
    if (!variable_struct_exists(global.snd, _name)) return;
    var _v = global.save.sfx;
    if (_v <= 0) return;
    var _h = audio_play_sound(global.snd[$ _name], 1, false, _v * _gain, 0, _pitch);
}

function cc_music_update() {
    if (!variable_global_exists("music_inst")) global.music_inst = -1;
    var _want = global.save.sfx > 0;
    if (_want && (global.music_inst < 0 || !audio_is_playing(global.music_inst))) {
        global.music_inst = audio_play_sound(global.snd.pad, 0, true, global.save.sfx * 0.55);
    }
    if (global.music_inst >= 0) audio_sound_gain(global.music_inst, global.save.sfx * 0.55, 200);
}
