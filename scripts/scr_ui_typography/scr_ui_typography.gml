// =============================================================================
// scr_ui_typography — Central text scale system
// =============================================================================
//
//  Call ui_typography_init() once (e.g. in game manager Create or menu Create).
//  Then use the globals everywhere instead of hardcoded scale numbers:
//
//  global.TXT_H1    — Screen / page title     e.g. "MISSION COMPLETE", "STORY MODE"
//  global.TXT_H2    — Section headers         e.g. "SELECT LEVEL", card labels
//  global.TXT_H3    — Panel labels & values   e.g. "SCORE", combo numbers
//  global.TXT_H4    — Body / description text e.g. card subtitles, objective text
//  global.TXT_SMALL — Hints & footnotes       e.g. "Up/Down to select", copyright
//
//  These are multipliers applied to draw_text_transformed(). The base size
//  is whatever your main_font asset is set to in GameMaker (e.g. 16pt).
//  If text looks too small/big, change the font asset size — not these values.
// =============================================================================

function ui_typography_init() {
    global.TXT_H1    = 4.0;   // Large titles
    global.TXT_H2    = 3.0;   // Headers
    global.TXT_H3    = 2.2;   // Stats
    global.TXT_H4    = 2.4;   // Dialogue / Body (Larger)
    global.TXT_SMALL = 1.8;   // Prompts (Larger)
}

// Helper: draw text at a typography level with optional color + alpha pre-set
// Usage: ui_draw_text(x, y, "SCORE", global.TXT_H3, c_white)
function ui_draw_text(_x, _y, _str, _scale, _col = c_white, _alpha = 1.0) {
    draw_set_color(_col);
    draw_set_alpha(_alpha);
    draw_text_transformed(_x, _y, _str, _scale, _scale, 0);
}
