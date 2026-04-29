// SFX framework — drop sound assets into project and uncomment the sfx_play() calls.
// All functions are safe to call with no audio assets present.

function sfx_play(_snd) {
    if (audio_exists(_snd)) audio_play_sound(_snd, 0, false);
}

// --- Piece movement ---
// snd_move:   short soft click (e.g. 50ms, low pitch)
function sfx_piece_move() {
    // sfx_play(snd_move);
}

// snd_rotate: snap/tick sound
function sfx_piece_rotate() {
    // sfx_play(snd_rotate);
}

// snd_blocked: short dull thud / low buzz — piece can't move deeper
function sfx_piece_blocked() {
    // sfx_play(snd_blocked);
}

// snd_lock:   thud/clunk, mid pitch, ~100ms
function sfx_piece_lock() {
    // sfx_play(snd_lock);
}

// snd_hard_drop: whoosh + thud combo
function sfx_hard_drop() {
    // sfx_play(snd_hard_drop);
}

// --- Match / clear ---
// snd_clear_1..4: rising pitched pops per combo tier
// _chain is current comboChain value
function sfx_clear(_count, _chain) {
    // var _snd = snd_clear_1;
    // if (_chain >= 2) _snd = snd_clear_2;
    // if (_chain >= 4) _snd = snd_clear_3;
    // if (_chain >= 7) _snd = snd_clear_4;
    // sfx_play(_snd);
}

// --- Special pieces ---
// snd_bomb:  explosion — deep boom, reverb tail
function sfx_bomb() {
    // sfx_play(snd_bomb);
}

// snd_drill: grinding mechanical burst
function sfx_drill() {
    // sfx_play(snd_drill);
}

// --- State transitions ---
// snd_fever: triumphant jingle / fanfare ~1s
function sfx_fever() {
    // sfx_play(snd_fever);
}

// snd_level_up: ascending chime
function sfx_level_up() {
    // sfx_play(snd_level_up);
}

// snd_game_over: descending tone / sad sting
function sfx_game_over() {
    // sfx_play(snd_game_over);
}
