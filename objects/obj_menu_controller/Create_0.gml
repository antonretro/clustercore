display_set_gui_size(1920, 1080);

// Typography scale — H1 (titles) → H2 (headers) → H3 (labels) → H4 (body) → SMALL (hints)
global.TXT_H1    = 7.0;   // Screen/page title   e.g. "SETTINGS", "STORY CLEAR"
global.TXT_H2    = 5.0;   // Section header       e.g. "SELECT LEVEL", card labels
global.TXT_H3    = 3.5;   // Panel values/labels  e.g. score number, combo count
global.TXT_H4    = 2.5;   // Body / description   e.g. mission name, card subtitle
global.TXT_SMALL = 1.8;   // Hints / footnotes    e.g. "Arrow Keys to Move", copyright

menu_index    = 0;
in_settings   = false;
in_story_select = false;
in_bonus_select = false;
in_refabricator = false;
settings_index = 0;
settings_items = ["Ghost Piece", "Screen Shake"];

// Title screen
in_title        = true;
title_timer     = 0;
menu_enter_timer = 0; // 0→60: cards slide in on menu entry

if (!variable_global_exists("settings")) {
    global.settings = { ghostEnabled: true, shakeEnabled: true };
}
if (!variable_global_exists("gameMode")) global.gameMode = "PLANET";
if (!variable_global_exists("storyPlanet")) global.storyPlanet = 0;
if (!variable_global_exists("story_seen_scenes")) global.story_seen_scenes = {};
if (!variable_global_exists("floatingTexts")) global.floatingTexts = [];
if (!variable_global_exists("COLOR_DANGER")) global.COLOR_DANGER = make_color_rgb(255, 50, 50);

dialogue_init();
wallet_load();

// Safe defaults for unlock flags if wallet_load didn't set them
if (!variable_global_exists("endlessPlanetUnlocked"))  global.endlessPlanetUnlocked  = false;
if (!variable_global_exists("endlessClassicUnlocked")) global.endlessClassicUnlocked = false;
if (!variable_global_exists("isFirstTimeLaunch"))      global.isFirstTimeLaunch      = false;

// Build menu labels based on unlock state
var _planetLabel  = "PLANET ENDLESS"  + (global.endlessPlanetUnlocked  ? "" : "  [LOCKED]");
var _classicLabel = "CLASSIC ENDLESS" + (global.endlessClassicUnlocked ? "" : "  [LOCKED]");

menu_items = ["STORY MODE", _planetLabel, _classicLabel, "SETTINGS"];
menu_hint  = [
    "Clear a chain of corrupted planets, one objective at a time.",
    global.endlessPlanetUnlocked  ? "The Galaxy Experience: Rotating board, Core planet, and Mining gravity." : "Complete TIN MOON in Story Mode to unlock.",
    global.endlessClassicUnlocked ? "The Arcade Classic: Pure matching, No rotation, Clean grid."           : "Complete RUST GARDEN in Story Mode to unlock.",
    "Toggle gameplay options."
];

story_select_index = clamp(global.storyPlanet, 0, 4);
in_story_level_select = false;
story_level_index = 0;
story_world_level_counts = [6, 6, 6, 6, 6];
story_level_names = [
    ["Wake Signal", "First Anchor", "Tin Run", "Core Loop", "Quiet Storm", "Moon Lock"],
    ["Rust Bloom", "Broken Lane", "Iron Rain", "Garden Wall", "Dead Roots", "Red Signal"],
    ["Ante Up", "Lucky Spiral", "House Edge", "Wild Orbit", "Payout Burn", "Comet Vault"],
    ["Cold Entry", "Low Oxygen", "Last Lane", "Grave Spin", "Black Relay", "Orbit Break"],
    ["Gate Hum", "Six Color Lock", "Solar Teeth", "Final Spiral", "Sun Debt", "Core Door"]
];
story_worlds = [
    { name: "TIN MOON",     orbit: 0.22, ang: 220, size: 18, color_a: make_color_rgb(120, 205, 230), color_b: make_color_rgb(55, 85, 130),  tilt: 0.34 },
    { name: "RUST GARDEN",  orbit: 0.34, ang: 310, size: 22, color_a: make_color_rgb(230, 125, 70),  color_b: make_color_rgb(95, 45, 35),   tilt: 0.39 },
    { name: "CASINO COMET", orbit: 0.46, ang: 25,  size: 20, color_a: make_color_rgb(255, 220, 90),  color_b: make_color_rgb(75, 150, 125), tilt: 0.43 },
    { name: "DEAD ORBIT",   orbit: 0.58, ang: 105, size: 24, color_a: make_color_rgb(160, 170, 190), color_b: make_color_rgb(55, 55, 80),   tilt: 0.36 },
    { name: "CLUSTER CORE", orbit: 0.70, ang: 165, size: 28, color_a: make_color_rgb(180, 105, 255), color_b: make_color_rgb(60, 30, 110),  tilt: 0.48 }
];
story_solar_spin = 0;
bonus_select_index = 0;
bonus_planet_names = ["GLASS DWARF", "EMBER DWARF", "COBALT DWARF", "VIOLET DWARF"];
bonus_planet_goals = [9000, 14000, 19000, 26000];
bonus_planet_rewards = [18, 26, 34, 48];

gp_prev_menu_stick_y = 0;
gp_prev_menu_stick_x = 0;

// First-time player: trigger backstory intro cinematic
if (global.isFirstTimeLaunch) {
    global.isFirstTimeLaunch = false;
    in_title = false; // skip title on very first launch to show backstory immediately
    dialogue_start_scene("backstory_intro");
}
