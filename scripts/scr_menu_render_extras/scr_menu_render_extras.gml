/// @module scr_menu_render_extras
/// Settings, Achievements, Encyclopedia, Inventory, Shop, and Refabricator.

function _menu_draw_sub_screen_base(_cx, _cy, _sw, _sh, _title, _subtitle) {
    draw_set_alpha(0.92); draw_set_color(make_color_rgb(3, 6, 16)); draw_rectangle(0, 0, _sw, _sh, false);

    var _starT = current_time * 0.00008;
    for (var i = 0; i < 30; i++) {
        var _pxs = (i * 173.3 + _starT * 100) % _sw;
        var _pys = (i * 217.7 + _starT * 55) % _sh;
        draw_set_alpha(0.1 + (i % 3) * 0.1); draw_set_color(c_white);
        draw_circle(_pxs, _pys, 1 + (i % 2), false);
    }

    // Scanning grid
    draw_set_alpha(0.04); draw_set_color(make_color_rgb(100, 200, 255));
    for (var gx = 0; gx < _sw; gx += 160) draw_line(gx, 0, gx, _sh);
    for (var gy = 0; gy < _sh; gy += 160) draw_line(0, gy, _sw, gy);
    draw_set_alpha(1);

    // Back button
    var _backSprite = asset_get_index("spr_back_icon");
    if (_backSprite != -1 && sprite_exists(_backSprite)) {
        draw_set_alpha(0.6);
        draw_sprite_ext(_backSprite, 0, 50, 50, 0.55, 0.55, 0, c_white, 1);
    }
    draw_set_alpha(0.5); draw_set_color(make_color_rgb(140, 190, 255));
    draw_text_transformed(76, 48, "B - BACK", global.TXT_SMALL, global.TXT_SMALL, 0);

    draw_set_halign(fa_center); draw_set_color(c_white);
    draw_text_transformed(_cx, 120, _title, global.TXT_H1, global.TXT_H1, 0);

    if (_subtitle != "") {
        draw_set_alpha(0.4); draw_set_color(make_color_rgb(140, 200, 255));
        draw_text_transformed(_cx, _cy - 40, _subtitle, global.TXT_H4, global.TXT_H4, 0);
    }
    draw_set_alpha(1);
}

function menu_draw_settings(_cx, _cy, _sw, _sh) {
    draw_set_alpha(0.95); draw_set_color(make_color_rgb(3, 6, 16)); draw_rectangle(0, 0, _sw, _sh, false);

    // Starfield
    var _starT = current_time * 0.00008;
    for (var i = 0; i < 40; i++) {
        var _pxs = (i * 173.3 + _starT * 100) % _sw;
        var _pys = (i * 217.7 + _starT * 55) % _sh;
        draw_set_alpha(0.1 + (i % 3) * 0.1); draw_set_color(c_white);
        draw_circle(_pxs, _pys, 1 + (i % 2), false);
    }
    draw_set_alpha(1);

    // Back button
    var _backSprite = asset_get_index("spr_back_icon");
    if (_backSprite != -1 && sprite_exists(_backSprite)) {
        draw_set_alpha(0.6);
        draw_sprite_ext(_backSprite, 0, 50, 50, 0.55, 0.55, 0, c_white, 1);
    }
    draw_set_alpha(0.5); draw_set_color(make_color_rgb(140, 190, 255));
    draw_text_transformed(76, 48, "B - BACK", global.TXT_SMALL, global.TXT_SMALL, 0);

    draw_set_halign(fa_center); draw_set_color(c_white);
    draw_text_transformed(_cx, 120, "SYSTEM CONFIGURATION", global.TXT_H1, global.TXT_H1, 0);
    draw_set_alpha(0.3); draw_set_color(make_color_rgb(100, 200, 255));
    draw_rectangle(_cx - 400, 190, _cx + 400, 194, false);

    var _vals = [global.settings.ghostEnabled, global.settings.shakeEnabled];
    var _startY = 360;
    var _panelW = 800; var _panelH = 120;

    for (var i = 0; i < 2; i++) {
        var _py = _startY + i * 170;
        var _isSel = (i == settings_index);

        // Panel background
        draw_set_alpha(_isSel ? 0.22 : 0.08); draw_set_color(c_white);
        draw_roundrect_ext(_cx - _panelW * 0.5, _py - _panelH * 0.5,
                          _cx + _panelW * 0.5, _py + _panelH * 0.5, 16, 16, false);
        draw_set_alpha(_isSel ? 0.55 : 0.18);
        draw_set_color(_isSel ? make_color_rgb(140, 200, 255) : make_color_rgb(80, 100, 140));
        draw_roundrect_ext(_cx - _panelW * 0.5, _py - _panelH * 0.5,
                          _cx + _panelW * 0.5, _py + _panelH * 0.5, 16, 16, true);

        // Selection glow
        if (_isSel) {
            gpu_set_blendmode(bm_add);
            draw_set_alpha(0.08 + abs(sin(current_time * 0.004)) * 0.04);
            draw_set_color(make_color_rgb(100, 200, 255));
            draw_roundrect_ext(_cx - _panelW * 0.5 - 4, _py - _panelH * 0.5 - 4,
                               _cx + _panelW * 0.5 + 4, _py + _panelH * 0.5 + 4, 20, 20, true);
            gpu_set_blendmode(bm_normal);
        }

        draw_set_halign(fa_left); draw_set_alpha(1.0);
        draw_set_color(_isSel ? make_color_rgb(255, 220, 100) : c_white);
        draw_text_transformed(_cx - _panelW * 0.5 + 40, _py, settings_items[i], global.TXT_H2, global.TXT_H2, 0);

        // Toggle switch
        var _swX = _cx + _panelW * 0.5 - 120;
        draw_set_color(make_color_rgb(10, 15, 30)); draw_set_alpha(0.6);
        draw_roundrect_ext(_swX - 70, _py - 28, _swX + 70, _py + 28, 28, 28, false);

        if (_vals[i]) {
            draw_set_color(make_color_rgb(100, 255, 150)); draw_set_alpha(0.85);
            draw_roundrect_ext(_swX + 10, _py - 20, _swX + 62, _py + 20, 18, 18, false);
            draw_set_halign(fa_center);
            draw_text_transformed(_swX - 22, _py, "ON", global.TXT_H4, global.TXT_H4, 0);
        } else {
            draw_set_color(make_color_rgb(255, 100, 100)); draw_set_alpha(0.85);
            draw_roundrect_ext(_swX - 62, _py - 20, _swX - 10, _py + 20, 18, 18, false);
            draw_set_halign(fa_center);
            draw_text_transformed(_swX + 22, _py, "OFF", global.TXT_H4, global.TXT_H4, 0);
        }
    }

    draw_set_halign(fa_center); draw_set_color(c_white); draw_set_alpha(0.45);
    draw_text_transformed(_cx, _sh - 80, "SPACE  Toggle    B  Return", global.TXT_H4, global.TXT_H4, 0);
}

function menu_draw_inventory(_cx, _cy, _sw, _sh) {
    _menu_draw_sub_screen_base(_cx, _cy, _sw, _sh, "INVENTORY", "Pilot equipment — manage collected gear and upgrades");

    var _panelX = _cx - 450; var _panelW = 900;
    draw_ui_panel(_panelX, _cy, _panelX + _panelW, _cy + 160);

    draw_set_halign(fa_center); draw_set_alpha(0.4); draw_set_color(make_color_rgb(180, 210, 255));
    draw_text_transformed(_cx, _cy + 50, "No equipment modules installed.", global.TXT_H3, global.TXT_H3, 0);
    draw_text_transformed(_cx, _cy + 90, "Complete missions to acquire pilot upgrades.", global.TXT_SMALL, global.TXT_SMALL, 0);

    draw_set_alpha(0.5); draw_set_color(c_white);
    draw_text_transformed(_cx, _sh - 80, "B  Back", global.TXT_H4, global.TXT_H4, 0);
}

function menu_draw_shop(_cx, _cy, _sw, _sh) {
    _menu_draw_sub_screen_base(_cx, _cy, _sw, _sh, "TECH SHOP", "Spend gems on specialized core-mining technology");

    var _panelX = _cx - 450; var _panelW = 900;
    draw_ui_panel(_panelX, _cy, _panelX + _panelW, _cy + 160);

    draw_set_halign(fa_center); draw_set_alpha(0.4); draw_set_color(make_color_rgb(180, 210, 255));
    draw_text_transformed(_cx, _cy + 50, "Shop inventory loading...", global.TXT_H3, global.TXT_H3, 0);
    draw_text_transformed(_cx, _cy + 90, "GEMS: " + string(global.walletGems) + " available for upgrades.", global.TXT_SMALL, global.TXT_SMALL, 0);

    draw_set_alpha(0.5); draw_set_color(c_white);
    draw_text_transformed(_cx, _sh - 80, "B  Back", global.TXT_H4, global.TXT_H4, 0);
}

function menu_draw_how_to_play(_cx, _cy, _sw, _sh) {
    _menu_draw_sub_screen_base(_cx, _cy, _sw, _sh, "PILOT DATA NOTEBOOK", "Galactic Restoration Unit — Field Manual v2.4");

    // Main content panel
    var _panelX = _cx - 540; var _panelW = 1080;
    var _panelY = 210; var _panelH = 620;

    // Panel shadow
    draw_set_alpha(0.5); draw_set_color(c_black);
    draw_roundrect_ext(_panelX + 8, _panelY + 8, _panelX + _panelW + 8, _panelY + _panelH + 8, 20, 20, false);

    // Panel gradient
    var _pTop = make_color_rgb(14, 24, 52);
    var _pBot = make_color_rgb(6, 10, 28);
    draw_set_alpha(0.9);
    draw_rectangle_colour(_panelX, _panelY, _panelX + _panelW, _panelY + _panelH, _pTop, _pTop, _pBot, _pBot, false);

    // Grid texture
    draw_set_alpha(0.025); draw_set_color(c_white);
    for (var gx = _panelX; gx < _panelX + _panelW; gx += 40) draw_line(gx, _panelY, gx, _panelY + _panelH);
    for (var gy = _panelY; gy < _panelY + _panelH; gy += 40) draw_line(_panelX, gy, _panelX + _panelW, gy);

    // Panel border
    draw_set_alpha(0.45); draw_set_color(make_color_rgb(140, 190, 255));
    draw_roundrect_ext(_panelX, _panelY, _panelX + _panelW, _panelY + _panelH, 20, 20, true);

    // ═══ SIDEBAR ═══
    var _sidebarW = 210;
    var _sidebarX1 = _panelX + 20;
    var _sidebarY0 = _panelY + 30;

    // Sidebar divider line
    draw_set_alpha(0.15); draw_set_color(make_color_rgb(100, 180, 255));
    draw_line_width(_sidebarX1 + _sidebarW + 10, _sidebarY0, _sidebarX1 + _sidebarW + 10, _panelY + _panelH - 30, 1);

    // Sidebar title
    draw_set_halign(fa_left); draw_set_alpha(0.4); draw_set_color(make_color_rgb(140, 200, 255));
    draw_text_transformed(_sidebarX1 + 10, _sidebarY0, "TOPICS", global.TXT_H4, global.TXT_H4, 0);

    var _tabs = ["MECHANICS", "BLOCK DATA", "PLANET LOG", "ADVANCED"];
    var _tabIcons = ["[ >_]", "[ # ]", "[ O ]", "[ >>]"];
    var _tabH = 52;

    for (var i = 0; i < 4; i++) {
        var _ty = _sidebarY0 + 38 + i * (_tabH + 8);
        var _selT = (how_to_page == i);

        // Tab highlight
        if (_selT) {
            draw_set_alpha(0.18); draw_set_color(make_color_rgb(100, 220, 255));
            draw_roundrect_ext(_sidebarX1 + 4, _ty - 4, _sidebarX1 + _sidebarW - 4, _ty + _tabH + 4, 10, 10, false);

            // Selection accent bar
            draw_set_alpha(1.0); draw_set_color(make_color_rgb(100, 255, 150));
            draw_roundrect_ext(_sidebarX1 + 4, _ty + 4, _sidebarX1 + 8, _ty + _tabH - 4, 2, 2, false);
        }

        // Tab icon
        draw_set_halign(fa_left);
        draw_set_alpha(_selT ? 0.8 : 0.35);
        draw_set_color(_selT ? make_color_rgb(100, 255, 150) : make_color_rgb(160, 180, 210));
        draw_text_transformed(_sidebarX1 + 18, _ty + 14, _tabIcons[i], 1.1, 1.1, 0);

        // Tab label
        draw_set_alpha(_selT ? 1.0 : 0.5);
        draw_set_color(_selT ? c_white : make_color_rgb(160, 180, 210));
        draw_text_transformed(_sidebarX1 + 54, _ty + 14, _tabs[i], 1.0, 1.0, 0);

        // Hover pulse for selected
        if (_selT) {
            gpu_set_blendmode(bm_add);
            draw_set_alpha(0.06 + abs(sin(current_time * 0.004)) * 0.04);
            draw_set_color(make_color_rgb(100, 255, 150));
            draw_roundrect_ext(_sidebarX1 + 4, _ty - 4, _sidebarX1 + _sidebarW - 4, _ty + _tabH + 4, 10, 10, true);
            gpu_set_blendmode(bm_normal);
        }
    }

    // ═══ CONTENT AREA ═══
    var _contentX = _sidebarX1 + _sidebarW + 40;
    var _contentY = _panelY + 40;
    var _contentW = _panelW - _sidebarW - 80;

    draw_set_halign(fa_left);

    if (how_to_page == 0) { // MECHANICS
        // Section header
        draw_set_alpha(1.0); draw_set_color(make_color_rgb(255, 220, 100));
        draw_text_transformed(_contentX, _contentY, "// BASIC OPERATIONS", global.TXT_H2, global.TXT_H2, 0);

        draw_set_alpha(0.55); draw_set_color(make_color_rgb(180, 210, 240));
        draw_text_ext_transformed(_contentX, _contentY + 50,
            "The G.R.U. operates in low planetary orbit. Pieces are launched from the staging ring toward the core. Match blocks in clusters or lines to stabilize the planetary core and clear each sector.", -1, _contentW, 0.95, 0.95, 0);

        // Controls section
        draw_set_alpha(0.35); draw_set_color(make_color_rgb(100, 180, 255));
        draw_line_width(_contentX, _contentY + 140, _contentX + _contentW, _contentY + 140, 1);

        draw_set_alpha(1.0); draw_set_color(make_color_rgb(100, 220, 255));
        draw_text_transformed(_contentX, _contentY + 170, "CONTROLS", global.TXT_H3, global.TXT_H3, 0);

        var _controls = [
            ["ARROWS / LEFT STICK", "Navigate piece in staging ring"],
            ["SPACE / A BUTTON", "Launch piece toward planetary core"],
            ["Z / UP / X", "Rotate piece orientation (CW / CCW)"],
            ["C / L-BUMPER", "Hold piece for later deployment"],
            ["Q / E / L-R BUMPER", "Rotate orbital perspective"]
        ];
        for (var c = 0; c < 5; c++) {
            var _cyCtrl = _contentY + 215 + c * 46;
            // Keycap-style label
            draw_set_alpha(0.15); draw_set_color(c_white);
            draw_roundrect_ext(_contentX, _cyCtrl - 6, _contentX + 220, _cyCtrl + 26, 6, 6, false);
            draw_set_alpha(0.9); draw_set_color(make_color_rgb(200, 220, 255));
            draw_text_transformed(_contentX + 12, _cyCtrl + 10, _controls[c][0], 0.85, 0.85, 0);
            // Description
            draw_set_alpha(0.5); draw_set_color(make_color_rgb(140, 180, 220));
            draw_text_transformed(_contentX + 240, _cyCtrl + 10, _controls[c][1], 0.85, 0.85, 0);
        }

        // CORE RULES callout box
        var _boxY = _contentY + 460;
        draw_set_alpha(0.08); draw_set_color(make_color_rgb(100, 255, 150));
        draw_roundrect_ext(_contentX, _boxY, _contentX + _contentW, _boxY + 80, 10, 10, false);
        draw_set_alpha(0.25); draw_set_color(make_color_rgb(100, 255, 150));
        draw_roundrect_ext(_contentX, _boxY, _contentX + _contentW, _boxY + 80, 10, 10, true);
        draw_set_alpha(0.9); draw_set_color(make_color_rgb(100, 255, 150));
        draw_text_transformed(_contentX + 20, _boxY + 16, "CORE RULE", 1.2, 1.2, 0);
        draw_set_alpha(0.6); draw_set_color(c_white);
        draw_text_transformed(_contentX + 20, _boxY + 44, "Match 3+ blocks of the same color in a straight line OR connected cluster to clear them. Clearing multiple groups in one launch triggers combo bonuses.", 0.85, 0.85, 0);
    }
    else if (how_to_page == 1) { // BLOCK DATA
        draw_set_alpha(1.0); draw_set_color(make_color_rgb(255, 220, 100));
        draw_text_transformed(_contentX, _contentY, "// BLOCK CLASSIFICATION", global.TXT_H2, global.TXT_H2, 0);

        var _blocks = [
            { name: "CORE BLOCKS",     icon: "[O]", desc: "Standard restoration units. Clear in CLUSTERS of 3+ or LINES of 3+.",                           col: make_color_rgb(100, 255, 150), detail: "Most common block type. Appears in all mission types. No special clearing requirements." },
            { name: "ARROW METAL",     icon: "[>]", desc: "Reinforced directional blocks. Only clear in a straight LINE of 4+ along their arrow axis.", col: make_color_rgb(255, 200, 80),  detail: "Arrows indicate valid clearing direction. Line must be exactly aligned with arrow. Ignores cluster clears." },
            { name: "ASTEROIDS",       icon: "[*]", desc: "Dense mineral obstacles. Requires 2 adjacent clearing events to fully break.",                  col: c_gray,                        detail: "First clear cracks the asteroid (visual change). Second clear on an adjacent tile removes it. Persists between turns." },
            { name: "CORE GEMS",       icon: "[<>]",desc: "High-value crystal formations. Extract these for Shards used in Refabrication.",               col: make_color_rgb(255, 100, 255), detail: "Clears like a core block but also rewards +1 Shard per gem cleared. Essential for wallet economy." },
            { name: "WILD CORES",      icon: "[?]", desc: "Anomalous blocks that link with any color sequence. Universal wildcard.",                       col: c_white,                       detail: "Counts as any color for matching purposes. Cannot be the anchor of a match — must connect to at least one colored block." }
        ];

        for (var b = 0; b < 5; b++) {
            var _by = _contentY + 50 + b * 108;
            // Color swatch
            draw_set_alpha(1.0); draw_set_color(_blocks[b].col);
            draw_roundrect_ext(_contentX, _by, _contentX + 40, _by + 40, 8, 8, false);
            draw_set_alpha(0.3); draw_set_color(c_black);
            draw_roundrect_ext(_contentX, _by, _contentX + 40, _by + 40, 8, 8, true);

            // Name
            draw_set_alpha(1.0); draw_set_color(c_white);
            draw_text_transformed(_contentX + 56, _by + 4, _blocks[b].name, 1.1, 1.1, 0);
            // Description
            draw_set_alpha(0.55); draw_set_color(make_color_rgb(180, 210, 240));
            draw_text_transformed(_contentX + 56, _by + 26, _blocks[b].desc, 0.82, 0.82, 0);
            // Detail line
            draw_set_alpha(0.35); draw_set_color(make_color_rgb(140, 180, 220));
            draw_text_transformed(_contentX + 56, _by + 48, _blocks[b].detail, 0.75, 0.75, 0);

            // Separator
            if (b < 4) {
                draw_set_alpha(0.08); draw_set_color(make_color_rgb(100, 180, 255));
                draw_line_width(_contentX + 20, _by + 90, _contentX + _contentW - 20, _by + 90, 1);
            }
        }
    }
    else if (how_to_page == 2) { // PLANET LOG
        draw_set_alpha(1.0); draw_set_color(make_color_rgb(255, 220, 100));
        draw_text_transformed(_contentX, _contentY, "// SOLAR SYSTEM SURVEY", global.TXT_H2, global.TXT_H2, 0);

        draw_set_alpha(0.55); draw_set_color(make_color_rgb(180, 210, 240));
        draw_text_ext_transformed(_contentX, _contentY + 45,
            "Each world in the system presents unique gravitational conditions and threat profiles. Planetary data is updated in real-time as restoration progresses.", -1, _contentW, 0.9, 0.9, 0);

        var _planets = [
            { name: "MERCURY",   threat: "MINIMAL",  grav: "0.38G",  temp: "430C", note: "Low gravity training zone. High orbital velocity. Ideal for new pilots mastering basic piece placement and rotation timing." },
            { name: "MARS",      threat: "MODERATE", grav: "0.38G",  temp: "-63C",  note: "Abandoned industrial complexes. Static defense grids create blocked columns. Requires strategic hold-piece usage." },
            { name: "VENUS",     threat: "ELEVATED", grav: "0.91G",  temp: "462C",  note: "Dense atmosphere creates high block density. Acidic corrosion may randomly damage unprotected blocks." },
            { name: "SATURN",    threat: "HIGH",     grav: "1.07G",  temp: "-178C", note: "Ring debris introduces junk blocks at high frequency. Multi-ring orbital lanes require perspective rotation." },
            { name: "JUPITER",   threat: "CRITICAL", grav: "2.53G",  temp: "-145C", note: "Extreme gravity accelerates piece descent. Color-locked gates and solar teeth. Only elite pilots survive." }
        ];

        for (var p = 0; p < 5; p++) {
            var _pyP = _contentY + 130 + p * 95;
            // Planet row background
            draw_set_alpha(0.04); draw_set_color(c_white);
            draw_roundrect_ext(_contentX, _pyP - 4, _contentX + _contentW, _pyP + 76, 8, 8, false);

            // Planet icon placeholder
            draw_set_alpha(1.0);
            var _pCol = make_color_rgb(100 + p * 30, 180 - p * 20, 255 - p * 25);
            draw_circle_color(_contentX + 22, _pyP + 36, 18, _pCol, merge_color(_pCol, c_black, 0.6), false);

            // Planet name + threat badge
            draw_set_alpha(1.0); draw_set_color(c_white);
            draw_text_transformed(_contentX + 56, _pyP + 8, _planets[p].name, 1.15, 1.15, 0);

            // Threat badge
            var _threatCols = [make_color_rgb(100,255,150), make_color_rgb(255,220,80), make_color_rgb(255,180,60), make_color_rgb(255,120,80), make_color_rgb(255,60,60)];
            draw_set_alpha(0.8); draw_set_color(_threatCols[p]);
            draw_text_transformed(_contentX + 170, _pyP + 8, _planets[p].threat, 0.75, 0.75, 0);

            // Stats: gravity + temp
            draw_set_alpha(0.4); draw_set_color(make_color_rgb(140, 200, 255));
            draw_text_transformed(_contentX + 56, _pyP + 32, "Gravity: " + _planets[p].grav + "    Surface: " + _planets[p].temp, 0.75, 0.75, 0);

            // Flavor note
            draw_set_alpha(0.5); draw_set_color(make_color_rgb(160, 190, 220));
            draw_text_ext_transformed(_contentX + 56, _pyP + 52, _planets[p].note, -1, _contentW - 80, 0.72, 0.72, 0);
        }
    }
    else { // ADVANCED
        draw_set_alpha(1.0); draw_set_color(make_color_rgb(255, 220, 100));
        draw_text_transformed(_contentX, _contentY, "// ADVANCED PROTOCOLS", global.TXT_H2, global.TXT_H2, 0);

        // COMBO SYSTEM
        var _secY = _contentY + 55;
        draw_set_alpha(0.15); draw_set_color(c_white);
        draw_roundrect_ext(_contentX, _secY, _contentX + _contentW, _secY + 150, 10, 10, false);

        draw_set_alpha(1.0); draw_set_color(make_color_rgb(100, 255, 180));
        draw_text_transformed(_contentX + 20, _secY + 16, "COMBO SYSTEM", global.TXT_H3, global.TXT_H3, 0);
        draw_set_alpha(0.55); draw_set_color(make_color_rgb(180, 210, 240));
        draw_text_ext_transformed(_contentX + 20, _secY + 52,
            "Each additional match group cleared in a single launch increases the combo multiplier. A x2 combo doubles shard rewards; x3 triples them. Chain reactions from cascading clears also count toward the multiplier. Mastering combos is the fastest path to Gem accumulation.",
            -1, _contentW - 40, 0.88, 0.88, 0);

        // REFABRICATION
        _secY += 170;
        draw_set_alpha(0.15); draw_set_color(c_white);
        draw_roundrect_ext(_contentX, _secY, _contentX + _contentW, _secY + 130, 10, 10, false);

        draw_set_alpha(1.0); draw_set_color(make_color_rgb(180, 200, 255));
        draw_text_transformed(_contentX + 20, _secY + 16, "REFABRICATION", global.TXT_H3, global.TXT_H3, 0);
        draw_set_alpha(0.55); draw_set_color(make_color_rgb(180, 210, 240));
        draw_text_ext_transformed(_contentX + 20, _secY + 52,
            "Visit the Refabricator (accessible from the Main Deck or Story Map) to condense 25 Shards into 1 Core Gem. Gems unlock permanent upgrades and specialty equipment in the Tech Shop. Shards are earned by clearing blocks, with bonus shards from gems and combos.",
            -1, _contentW - 40, 0.88, 0.88, 0);

        // ORBITAL DRIFT
        _secY += 150;
        draw_set_alpha(0.15); draw_set_color(c_white);
        draw_roundrect_ext(_contentX, _secY, _contentX + _contentW, _secY + 130, 10, 10, false);

        draw_set_alpha(1.0); draw_set_color(make_color_rgb(255, 210, 140));
        draw_text_transformed(_contentX + 20, _secY + 16, "ORBITAL PERSPECTIVE", global.TXT_H3, global.TXT_H3, 0);
        draw_set_alpha(0.55); draw_set_color(make_color_rgb(180, 210, 240));
        draw_text_ext_transformed(_contentX + 20, _secY + 52,
            "Rotating the orbital perspective (Q/E or shoulder buttons) reveals new match lanes and hidden opportunities. Some blocks may only be reachable from specific angles. Skilled pilots constantly shift perspective to find optimal placements.",
            -1, _contentW - 40, 0.88, 0.88, 0);
    }

    // Bottom hint bar
    draw_set_halign(fa_center); draw_set_alpha(0.5); draw_set_color(make_color_rgb(255, 214, 102));
    draw_text_transformed(_cx, _sh - 80, "[L/R] CHANGE TOPIC    [B] CLOSE NOTEBOOK", global.TXT_H4, global.TXT_H4, 0);
}

function menu_draw_achievements(_cx, _cy, _sw, _sh) {
    _menu_draw_sub_screen_base(_cx, _cy, _sw, _sh, "ACHIEVEMENTS", "");

    // Achievement list panel
    var _px = _cx - 520; var _pw = 1040;
    var _py = 210;
    var _ph = 70 * 10 + 20;

    draw_set_alpha(0.55); draw_set_color(c_black);
    draw_roundrect_ext(_px + 6, _py + 6, _px + _pw + 6, _py + _ph + 6, 16, 16, false);

    var _pTop = make_color_rgb(14, 24, 52);
    var _pBot = make_color_rgb(6, 10, 26);
    draw_set_alpha(0.85);
    draw_rectangle_colour(_px, _py, _px + _pw, _py + _ph, _pTop, _pTop, _pBot, _pBot, false);

    draw_set_alpha(0.025); draw_set_color(c_white);
    for (var gx = _px; gx < _px + _pw; gx += 40) draw_line(gx, _py, gx, _py + _ph);
    for (var gy = _py; gy < _py + _ph; gy += 40) draw_line(_px, gy, _px + _pw, gy);

    draw_set_alpha(0.4); draw_set_color(make_color_rgb(140, 190, 255));
    draw_roundrect_ext(_px, _py, _px + _pw, _py + _ph, 16, 16, true);

    // Items
    var _count = min(10, array_length(global.achievements));
    for (var i = 0; i < _count; i++) {
        var _ach = global.achievements[i];
        var _ay = _py + 20 + i * 70;

        // Row background
        draw_set_alpha(_ach.unlocked ? 0.1 : 0.04); draw_set_color(c_white);
        draw_roundrect_ext(_px + 20, _ay - 22, _px + _pw - 20, _ay + 38, 8, 8, false);

        // Status icon
        var _achIcon = asset_get_index("spr_achievements_icon");
        if (_achIcon != -1 && sprite_exists(_achIcon)) {
            draw_set_alpha(_ach.unlocked ? 1.0 : 0.3);
            draw_sprite_ext(_achIcon, 0, _px + 52, _ay + 8, 1.3, 1.3, 0,
                           _ach.unlocked ? c_white : c_gray, 1);
        } else {
            draw_set_alpha(_ach.unlocked ? 0.8 : 0.3);
            draw_set_color(_ach.unlocked ? make_color_rgb(100, 255, 150) : make_color_rgb(80, 80, 80));
            draw_circle(_px + 52, _ay + 8, 16, false);
        }

        // Name
        draw_set_halign(fa_left); draw_set_alpha(1);
        draw_set_color(_ach.unlocked ? c_white : c_gray);
        draw_text_transformed(_px + 90, _ay - 2, _ach.name, global.TXT_H4, global.TXT_H4, 0);

        // Description
        draw_set_alpha(_ach.unlocked ? 0.45 : 0.25);
        draw_set_color(_ach.unlocked ? make_color_rgb(180, 210, 255) : c_gray);
        draw_text_transformed(_px + 90, _ay + 22, _ach.desc, global.TXT_SMALL, global.TXT_SMALL, 0);

        // Status label
        draw_set_halign(fa_right);
        draw_set_alpha(_ach.unlocked ? 0.8 : 0.4);
        draw_set_color(_ach.unlocked ? make_color_rgb(100, 255, 150) : make_color_rgb(255, 100, 100));
        draw_text_transformed(_px + _pw - 50, _ay + 8,
                             _ach.unlocked ? "UNLOCKED" : "LOCKED", global.TXT_SMALL, global.TXT_SMALL, 0);
    }

    draw_set_halign(fa_center); draw_set_alpha(0.45); draw_set_color(c_white);
    draw_text_transformed(_cx, _sh - 60, "B  Back", global.TXT_H4, global.TXT_H4, 0);
}

function menu_draw_refabricator(_cx, _cy, _sw, _sh) {
    draw_set_alpha(0.92); draw_set_color(make_color_rgb(3, 6, 16)); draw_rectangle(0, 0, _sw, _sh, false);

    // Starfield
    var _starT = current_time * 0.00008;
    for (var i = 0; i < 40; i++) {
        var _pxs = (i * 173.3 + _starT * 100) % _sw;
        var _pys = (i * 217.7 + _starT * 55) % _sh;
        draw_set_alpha(0.1 + (i % 3) * 0.1); draw_set_color(c_white);
        draw_circle(_pxs, _pys, 1 + (i % 2), false);
    }
    draw_set_alpha(1);

    // Back button
    var _backSprite = asset_get_index("spr_back_icon");
    if (_backSprite != -1 && sprite_exists(_backSprite)) {
        draw_set_alpha(0.6);
        draw_sprite_ext(_backSprite, 0, 50, 50, 0.55, 0.55, 0, c_white, 1);
    }
    draw_set_alpha(0.5); draw_set_color(make_color_rgb(140, 190, 255));
    draw_text_transformed(76, 48, "B - BACK", global.TXT_SMALL, global.TXT_SMALL, 0);

    draw_set_halign(fa_center); draw_set_color(make_color_rgb(180, 240, 255));
    draw_text_transformed(_cx, 120, "REFABRICATOR", global.TXT_H1, global.TXT_H1, 0);

    // Glassmorphism panel
    var _pw = 800; var _ph = 320;
    var _px1 = _cx - _pw * 0.5;
    var _py1 = _cy - _ph * 0.5 - 20;

    draw_set_alpha(0.5); draw_set_color(c_black);
    draw_roundrect_ext(_px1 + 8, _py1 + 8, _px1 + _pw + 8, _py1 + _ph + 8, 20, 20, false);

    var _pTop = make_color_rgb(18, 30, 60);
    var _pBot = make_color_rgb(8, 14, 32);
    draw_set_alpha(0.88);
    draw_rectangle_colour(_px1, _py1, _px1 + _pw, _py1 + _ph, _pTop, _pTop, _pBot, _pBot, false);

    draw_set_alpha(0.03); draw_set_color(c_white);
    for (var gx = _px1; gx < _px1 + _pw; gx += 40) draw_line(gx, _py1, gx, _py1 + _ph);
    for (var gy = _py1; gy < _py1 + _ph; gy += 40) draw_line(_px1, gy, _px1 + _pw, gy);

    draw_set_alpha(0.45); draw_set_color(make_color_rgb(140, 190, 255));
    draw_roundrect_ext(_px1, _py1, _px1 + _pw, _py1 + _ph, 20, 20, true);

    // Ship sprite in refabricator
    var _shipSprite = asset_get_index("spr_refabricator_ship");
    if (_shipSprite != -1 && sprite_exists(_shipSprite)) {
        var _s = 2.5;
        var _sx = _cx + 140;
        var _sy = _py1 + 80 + sin(current_time * 0.002) * 12;
        draw_set_alpha(0.9);
        draw_sprite_ext(_shipSprite, 0, _sx, _sy, _s, _s, current_time * 0.0003, c_white, 1);
    }

    // Text
    draw_set_halign(fa_center); draw_set_color(c_white);
    draw_text_transformed(_cx, _py1 + 60, "Condense planetary debris into pure Core Gems.", global.TXT_H3, global.TXT_H3, 0);

    draw_set_color(make_color_rgb(255, 214, 102));
    draw_text_transformed(_cx, _py1 + 130, "25 SHARDS = 1 GEM", global.TXT_H1, global.TXT_H1, 0);

    // Shard and gem icons
    var _gs = asset_get_index("spr_gemshard");
    if (_gs != -1 && sprite_exists(_gs)) draw_sprite_ext(_gs, 0, _cx - 160, _py1 + 200, 3.5, 3.5, 0, c_white, 1);
    var _gm = asset_get_index("spr_gem");
    if (_gm != -1 && sprite_exists(_gm)) draw_sprite_ext(_gm, 0, _cx + 160, _py1 + 200, 3.5, 3.5, 0, c_white, 1);

    draw_set_color(make_color_rgb(255, 220, 90));
    draw_text_transformed(_cx, _py1 + 260, "SHARDS " + string(global.walletShards) + "     GEMS " + string(global.walletGems), global.TXT_H2, global.TXT_H2, 0);

    // Action prompt
    draw_set_alpha(0.5); draw_set_color(make_color_rgb(255, 214, 102));
    draw_text_transformed(_cx, _sh - 80, "A  Refabricate     B  Back", global.TXT_H4, global.TXT_H4, 0);
}
