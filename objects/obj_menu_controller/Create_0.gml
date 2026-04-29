display_set_gui_size(1920, 1080);

menu_index    = 0;
in_settings   = false;
settings_index = 0;
settings_items = ["Ghost Piece", "Screen Shake"];

menu_items = ["STORY MODE", "PLANET MODE", "CLASSIC MODE", "SETTINGS"];
menu_hint  = [
    "Clear a chain of corrupted planets, one objective at a time.",
    "The Galaxy Experience: Rotating board, Core planet, and Mining gravity.",
    "The Arcade Classic: Pure matching, No rotation, Clean grid.",
    "Toggle gameplay options."
];

if (!variable_global_exists("settings")) {
    global.settings = { ghostEnabled: true, shakeEnabled: true };
}

if (!variable_global_exists("gameMode")) global.gameMode = "PLANET";
