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
    _menu_draw_sub_screen_base(_cx, _cy, _sw, _sh, "PILOT DATA NOTEBOOK", "Analyzing Galactic Restoration Unit (G.R.U.) Protocols...");

    var _panelX = _cx - 540; var _panelW = 1080;
    var _panelY = 200; var _panelH = 640;
    draw_ui_panel(_panelX, _panelY, _panelX + _panelW, _panelY + _panelH);

    // Sidebar Tabs
    var _tabs = ["MECHANICS", "BLOCK DATA", "PLANET LOG", "ADVANCED"];
    var _tabW = 220;
    for (var i = 0; i < 4; i++) {
        var _tx = _panelX + 30 + i * (_tabW + 10);
        var _ty = _panelY - 45;
        var _selT = (how_to_page == i);
        draw_set_alpha(_selT ? 1.0 : 0.4);
        draw_set_color(_selT ? make_color_rgb(100, 255, 150) : c_white);
        draw_roundrect_ext(_tx, _ty, _tx + _tabW, _ty + 40, 10, 10, false);
        draw_set_color(c_black); draw_set_halign(fa_center);
        draw_text_transformed(_tx + _tabW * 0.5, _ty + 20, _tabs[i], 0.8, 0.8, 0);
    }

    // Content Area
    var _contentX = _panelX + 40;
    var _contentY = _panelY + 50;
    draw_set_halign(fa_left); draw_set_color(c_white);

    if (how_to_page == 0) { // MECHANICS
        draw_text_transformed(_contentX, _contentY, "BASIC OPERATIONS", 1.5, 1.5, 0);
        draw_set_alpha(0.6);
        draw_text_transformed(_contentX, _contentY + 40, "The G.R.U. operates in an orbital plane. Pieces are launched from the staging ring\ntoward the planet's core. Your goal is to stabilize the core by matching blocks.", 0.9, 0.9, 0);
        
        var _controls = [
            "ARROWS / STICK : Move Piece in Staging Ring",
            "SPACE / A BUTTON : Launch Piece Toward Core",
            "Z / UP / X : Rotate Piece Orientation",
            "C / L-BUMPER : Hold Piece for Later Use",
            "Q/E / L-R BUMPER : Rotate Orbital Perspective"
        ];
        for (var c = 0; c < 5; c++) {
            draw_set_alpha(0.8); draw_set_color(make_color_rgb(140, 200, 255));
            draw_text_transformed(_contentX + 20, _contentY + 140 + c * 40, ">> " + _controls[c], 1.0, 1.0, 0);
        }
    } 
    else if (how_to_page == 1) { // BLOCK DATA
        draw_text_transformed(_contentX, _contentY, "BLOCK CLASSIFICATION", 1.5, 1.5, 0);
        
        var _blocks = [
            { name: "CORE BLOCKS", desc: "Standard restoration units. Clear in CLUSTERS of 3+ or LINES of 3+.", col: make_color_rgb(100, 255, 150) },
            { name: "ARROW METAL", desc: "Reinforced blocks. Only clear in a straight LINE of 4+ along their axis.", col: make_color_rgb(255, 200, 80) },
            { name: "ASTEROIDS", desc: "Dense mineral obstacles. Requires 2 adjacent clears to break.", col: c_gray },
            { name: "CORE GEMS", desc: "High-value shards. Extract these to fill your wallet for Refabrication.", col: make_color_rgb(255, 100, 255) },
            { name: "WILD CORE", desc: "Anomalous blocks that link with any color sequence.", col: c_white }
        ];
        for (var b = 0; b < 5; b++) {
            var _by = _contentY + 60 + b * 100;
            draw_set_alpha(1); draw_set_color(_blocks[b].col);
            draw_rectangle(_contentX, _by, _contentX + 16, _by + 16, false);
            draw_text_transformed(_contentX + 30, _by + 8, _blocks[b].name, 1.1, 1.1, 0);
            draw_set_alpha(0.6); draw_set_color(c_white);
            draw_text_transformed(_contentX + 30, _by + 34, _blocks[b].desc, 0.85, 0.85, 0);
        }
    }
    else if (how_to_page == 2) { // PLANET LOG
        draw_text_transformed(_contentX, _contentY, "SOLAR SYSTEM DATA", 1.5, 1.5, 0);
        var _planets = [
            "MERCURY: Low gravity, high speed. Excellent for training.",
            "MARS: Industrial decay. Watch out for static defense grids.",
            "VENUS/EARTH: High block density. Requires precise placement.",
            "SATURN: Dense ring debris. High frequency of junk blocks.",
            "JUPITER: Extreme gravity. Color-locked gates and solar teeth."
        ];
        for (var p = 0; p < 5; p++) {
            draw_set_alpha(0.8); draw_set_color(make_color_rgb(180, 210, 255));
            draw_text_transformed(_contentX + 20, _contentY + 60 + p * 80, _planets[p], 1.0, 1.0, 0);
        }
    }
    else { // ADVANCED
        draw_text_transformed(_contentX, _contentY, "ADVANCED PROTOCOLS", 1.5, 1.5, 0);
        draw_set_alpha(0.6);
        draw_text_transformed(_contentX, _contentY + 60, "COMBO SYSTEM: Clearing multiple groups in one launch grants Gem bonuses.\n\nREFABRICATION: Visit the Refabricator to condense Shards into Core Gems.\n\nORBITAL DRIFT: Rotating the perspective (Q/E) is vital to find new lanes.", 1.1, 1.1, 0);
    }

    draw_set_halign(fa_center); draw_set_alpha(0.5); draw_set_color(make_color_rgb(255, 214, 102));
    draw_text_transformed(_cx, _sh - 80, "[L/R] CHANGE PAGE    [B] EXIT DATA LOG", global.TXT_H4, global.TXT_H4, 0);
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
