display_set_gui_size(1920, 1080);

menu_index    = 0;
in_settings   = false;
in_story_select = false;
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

if (!variable_global_exists("storyPlanet")) global.storyPlanet = 0;
if (!variable_global_exists("story_seen_scenes")) global.story_seen_scenes = {};
dialogue_init();

story_select_index = clamp(global.storyPlanet, 0, 4);
in_story_level_select = false;
story_level_index = 0;
story_world_level_counts = [4, 5, 5, 6, 6];
story_worlds = [
    { name: "TIN MOON", orbit: 0.22, ang: 220 },
    { name: "RUST GARDEN", orbit: 0.34, ang: 310 },
    { name: "CASINO COMET", orbit: 0.46, ang: 25 },
    { name: "DEAD ORBIT", orbit: 0.58, ang: 105 },
    { name: "CLUSTER CORE", orbit: 0.70, ang: 165 }
];

gp_prev_menu_stick_y = 0;
gp_prev_menu_stick_x = 0;
